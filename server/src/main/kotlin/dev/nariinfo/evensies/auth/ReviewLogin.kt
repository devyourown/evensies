package dev.nariinfo.evensies.auth

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.common.RateLimiter
import dev.nariinfo.evensies.config.AppProperties
import jakarta.servlet.http.HttpServletRequest
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RestController
import tools.jackson.databind.ObjectMapper
import java.net.InetAddress
import java.security.MessageDigest

/**
 * Store review sign-in (docs/API.md "Review sign-in"): one username and password from the environment, for app reviewers
 * who won't use their own Apple or Google account. POST answers 404 (like an unknown endpoint) unless [AppProperties.Auth.reviewLogin].
 */
@RestController
class ReviewLoginController(private val auth: AuthService, private val mapper: ObjectMapper, props: AppProperties) {
    private val enabled = props.auth.reviewLogin
    private val username = props.auth.reviewUsername.trim() // a stray space in .env would otherwise lock everyone out
    private val usernameHash = sha256(username)
    private val passwordHash = sha256(props.auth.reviewPassword)
    private val perIpMinute = RateLimiter(capacity = 10.0, refillPerSecond = 10.0 / 60)
    private val perIpHour = RateLimiter(capacity = 20.0, refillPerSecond = 20.0 / 3600)
    private val overall = RateLimiter(capacity = 100.0, refillPerSecond = 100.0 / 3600)

    init {
        if (username.isNotBlank() && !enabled) {
            LoggerFactory.getLogger(javaClass).warn(
                "EVENSIES_REVIEW_LOGIN_USERNAME is set but EVENSIES_REVIEW_LOGIN_PASSWORD has fewer than {} characters: review sign-in stays off",
                AppProperties.Auth.REVIEW_PASSWORD_MIN,
            )
        }
    }

    /** The body is read only after the off check and the limits, and at most [MAX_BODY] bytes of it. */
    @PostMapping("/auth/review")
    fun review(request: HttpServletRequest): AuthResponse {
        if (!enabled) throw ApiException(HttpStatus.NOT_FOUND, "NOT_FOUND", "No such endpoint")
        // JSON only: a cross-site form post (text/plain, no CORS preflight) must not use up the limits.
        if (request.contentType?.lowercase()?.startsWith("application/json") != true) throw ApiException.badRequest("VALIDATION", "Send JSON")
        // A blocked IP doesn't touch the shared bucket; the hourly per-IP cap keeps one IP to 20 % of it.
        val ip = ipKey(request.remoteAddr)
        if (!perIpMinute.tryConsume(ip) || !perIpHour.tryConsume(ip) || !overall.tryConsume(Unit)) {
            throw ApiException.tooManyRequests("Too many attempts, try again later")
        }
        val json = runCatching { mapper.readTree(request.inputStream.readNBytes(MAX_BODY)) }.getOrNull()
        fun text(key: String): String =
            json?.get(key)?.takeIf { it.isString }?.asString() ?: throw ApiException.badRequest("VALIDATION", "$key must be a string")
        // Constant time: equal-length digests, and both are compared before deciding.
        val usernameOk = MessageDigest.isEqual(sha256(text("username").trim()), usernameHash)
        val passwordOk = MessageDigest.isEqual(sha256(text("password")), passwordHash)
        if (!(usernameOk and passwordOk)) throw ApiException.unauthorized("Wrong username or password")
        return auth.login("review", "review:$username", "")
    }

    private fun sha256(s: String): ByteArray = MessageDigest.getInstance("SHA-256").digest(s.toByteArray())

    /** IPv6 clients by their /64 (one site's whole range), IPv4 as is. remoteAddr is a numeric literal: no DNS lookup. */
    private fun ipKey(addr: String): Any =
        if (':' in addr) runCatching { InetAddress.getByName(addr).address.copyOf(8).toList() }.getOrDefault(addr) else addr

    private companion object {
        const val MAX_BODY = 4096
    }
}
