package dev.nariinfo.evensies.email

import dev.nariinfo.evensies.auth.AuthResponse
import dev.nariinfo.evensies.auth.AuthService
import dev.nariinfo.evensies.auth.UserDto
import dev.nariinfo.evensies.auth.UserRepository
import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.common.RateLimiter
import dev.nariinfo.evensies.config.AppProperties
import dev.nariinfo.evensies.config.userId
import jakarta.servlet.http.HttpServletRequest
import org.springframework.dao.DuplicateKeyException
import org.springframework.http.HttpStatus
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.security.core.Authentication
import org.springframework.stereotype.Service
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController
import java.security.SecureRandom
import java.time.Clock
import java.time.Duration
import java.time.ZoneOffset
import java.util.UUID

data class EmailRequest(val email: String? = null)
data class EmailCodeRequest(val email: String? = null, val code: String? = null)

/**
 * Sign in with an emailed code and the account address (docs/API.md "이메일 로그인", "계정 이메일"). There are no
 * passwords. A code: 6 digits from SecureRandom, 10 minutes, 5 attempts, single use; a new one replaces the old.
 */
@Service
class EmailAccounts(
    private val mailer: Mailer,
    private val tokens: EmailTokens,
    private val users: UserRepository,
    private val auth: AuthService,
    private val jdbc: JdbcClient,
    private val clock: Clock,
    props: AppProperties,
) {
    private val random = SecureRandom()
    private val perIp = props.email.authRatePerMinute.let { RateLimiter(capacity = it, refillPerSecond = it / 60) }

    /** Sign-in by client IP; a signed-in account's change requests by its id (an IP may be shared). */
    fun throttle(key: Any) {
        if (!perIp.tryConsume(key)) throw ApiException.tooManyRequests("Too many attempts, try again in a minute")
    }

    /** POST /auth/email/start: 204 whether or not an account has the address; in the language of the account that has it. */
    fun startLogin(raw: String?) {
        mailer.requireEnabled()
        val email = address(raw)
        val holder = users.findActiveByEmail(email)
        sendCode(email, "login", null, holder?.id, holder?.language)
    }

    /** POST /auth/email/verify: the active account with the address, else a new one (empty name, so the app asks for it). */
    fun verifyLogin(raw: String?, code: String?): AuthResponse {
        val email = address(raw)
        consume(email, "login", null, code)
        val user = users.findActiveByEmail(email) ?: users.findOrCreate("email", email, "").let { u ->
            if (u.email != null) u else try { users.setEmail(u.id, email) } catch (_: DuplicateKeyException) { codeInvalid() }
        }
        mailer.unsuppress(email)
        return auth.session(user)
    }

    /** POST /me/email: a code to the new address; whether another account holds it shows only at verify. */
    fun startChange(userId: UUID, raw: String?) {
        val user = auth.user(userId)
        mailer.requireEnabled()
        sendCode(address(raw), "change", userId, userId, user.language)
    }

    fun verifyChange(userId: UUID, raw: String?, code: String?): UserDto {
        auth.user(userId)
        val email = address(raw)
        consume(email, "change", userId, code)
        if (users.findActiveByEmail(email)?.let { it.id != userId } == true) taken()
        val user = try { users.setEmail(userId, email) } catch (_: DuplicateKeyException) { taken() }
        mailer.unsuppress(email)
        return auth.dto(user)
    }

    /** 409 EMAIL_REQUIRED for an account that signs in with its address only. */
    fun remove(userId: UUID) {
        val user = auth.user(userId)
        if (user.provider == "email") throw ApiException(HttpStatus.CONFLICT, "EMAIL_REQUIRED", "This address is how you sign in")
        users.setEmail(userId, null)
    }

    /**
     * [userId]: who asked (a change; null for a sign-in); [charged]: the `email_log` account. Codes skip suppression and
     * the daily budget, so they are capped per address and, for a change, per account (any addresses).
     */
    private fun sendCode(email: String, purpose: String, userId: UUID?, charged: UUID?, language: String?) {
        val kind = if (purpose == "login") "login_code" else "change_code"
        if (mailer.count(Mailer.CODES, Duration.ofHours(1), toHash = EmailAddress.hash(email)) >= CODES_PER_HOUR ||
            (userId != null && mailer.count(setOf(kind), Duration.ofHours(1), userId = userId) >= CODES_PER_HOUR)
        ) {
            throw ApiException.tooManyRequests("Too many codes, try again later")
        }
        val code = "%06d".format(random.nextInt(1_000_000))
        jdbc.sql(
            """
            INSERT INTO email_codes (email, purpose, user_id, code_hash, expires_at, attempts) VALUES (:e, :p, :u, :h, :exp, 0)
            ON CONFLICT (email, purpose) DO UPDATE SET user_id = EXCLUDED.user_id, code_hash = EXCLUDED.code_hash,
              expires_at = EXCLUDED.expires_at, attempts = 0
            """
        ).param("e", email).param("p", purpose).param("u", userId).param("h", tokens.codeHash(email, code))
            .param("exp", clock.instant().plus(CODE_TTL).atOffset(ZoneOffset.UTC)).update()
        val lang = language ?: "en"
        mailer.send(kind, email, charged, if (purpose == "login") EmailTemplates.loginCode(lang, code) else EmailTemplates.changeCode(lang, code))
    }

    /**
     * Every check counts as an attempt (committed even when it fails, so no transaction around it); the 6th is dead
     * whatever it says. A match deletes the row, so only one concurrent check of the same code wins.
     */
    private fun consume(email: String, purpose: String, userId: UUID?, code: String?) {
        if (code == null || !CODE.matches(code)) throw ApiException.badRequest("VALIDATION", "code must be 6 digits")
        val now = clock.instant().atOffset(ZoneOffset.UTC)
        val row = jdbc.sql(
            """
            UPDATE email_codes SET attempts = attempts + 1
            WHERE email = :e AND purpose = :p AND expires_at > :now AND attempts < $MAX_ATTEMPTS RETURNING code_hash, user_id
            """
        ).param("e", email).param("p", purpose).param("now", now)
            .query { rs, _ -> rs.getString("code_hash") to rs.getObject("user_id", UUID::class.java) }.optional().orElse(null) ?: codeInvalid()
        if (row.second != userId || !tokens.codeMatches(row.first, email, code)) codeInvalid()
        val won = jdbc.sql("DELETE FROM email_codes WHERE email = :e AND purpose = :p AND code_hash = :h")
            .param("e", email).param("p", purpose).param("h", row.first).update()
        if (won == 0) codeInvalid()
    }

    private fun address(raw: String?): String =
        EmailAddress.normalize(raw) ?: throw ApiException.badRequest("VALIDATION", "That isn't an email address we can send to")

    private fun codeInvalid(): Nothing = throw ApiException.badRequest("CODE_INVALID", "That code is wrong or has expired")

    private fun taken(): Nothing = throw ApiException(HttpStatus.CONFLICT, "EMAIL_TAKEN", "Another account uses this address")

    companion object {
        val CODE_TTL: Duration = Duration.ofMinutes(10)
        const val MAX_ATTEMPTS = 5
        const val CODES_PER_HOUR = 5
        private val CODE = Regex("^\\d{6}$")
    }
}

@RestController
class EmailAccountController(private val accounts: EmailAccounts) {
    @PostMapping("/auth/email/start")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun start(@RequestBody req: EmailRequest, request: HttpServletRequest) {
        accounts.throttle(request.remoteAddr)
        accounts.startLogin(req.email)
    }

    @PostMapping("/auth/email/verify")
    fun verify(@RequestBody req: EmailCodeRequest, request: HttpServletRequest): AuthResponse {
        accounts.throttle(request.remoteAddr)
        return accounts.verifyLogin(req.email, req.code)
    }

    @PostMapping("/me/email")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun change(auth: Authentication, @RequestBody req: EmailRequest) {
        accounts.throttle(auth.userId)
        accounts.startChange(auth.userId, req.email)
    }

    @PostMapping("/me/email/verify")
    fun verifyChange(auth: Authentication, @RequestBody req: EmailCodeRequest): UserDto = accounts.verifyChange(auth.userId, req.email, req.code)

    @DeleteMapping("/me/email")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun remove(auth: Authentication) = accounts.remove(auth.userId)
}
