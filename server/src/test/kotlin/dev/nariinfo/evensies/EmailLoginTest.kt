package dev.nariinfo.evensies

import dev.nariinfo.evensies.auth.AuthService
import dev.nariinfo.evensies.email.EmailAddress
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import java.time.Duration
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Sign in with an emailed code (docs/API.md "Email sign-in") over real HTTP; mail goes to [CapturingMailSender]. */
class EmailLoginTest : IntegrationTestBase() {
    @Autowired
    private lateinit var jdbc: JdbcClient

    @Autowired
    private lateinit var auth: AuthService

    @AfterEach
    fun reset() {
        testClock.offset = Duration.ZERO
        mail.reject.clear()
        mail.down = false
    }

    private fun start(email: String) = http.post("/auth/email/start", mapOf("email" to email))
    private fun verify(email: String, code: String) = http.post("/auth/email/verify", mapOf("email" to email, "code" to code))

    private fun assertError(status: Int, code: String, res: Http.Resp) {
        assertEquals(status, res.status, res.text)
        assertEquals(code, res.code(), res.text)
    }

    @Test
    fun roundTripAndTheSameAddressIsTheSameUser() {
        val email = address("Login")
        assertEquals(204, start("  ${email.uppercase()} ").status, "trimmed and lower-cased")
        val sent = mail.to(email).single()
        assertEquals("${mail.code(email)} is your Evensies code", sent.subject)
        assertTrue(sent.message.contentType.startsWith("text/plain") && "UTF-8" in sent.message.contentType.uppercase(), sent.message.contentType)
        assertEquals("auto-generated", sent.header("Auto-Submitted"))
        assertNull(sent.header("List-Unsubscribe"), "codes carry no unsubscribe")
        val first = verify(email, mail.code(email))
        assertEquals(200, first.status, first.text)
        assertEquals(email, first.body["user"]["email"].asString())
        assertEquals("", first.body["user"]["displayName"].asString(), "a new account has no name, so the app asks for it")
        assertFalse(first.body["user"]["emailBounced"].asBoolean())
        assertEquals(200, http.get("/me", first.body["accessToken"].asString()).status)

        assertEquals(204, start(email).status)
        val again = verify(email, mail.code(email))
        assertEquals(first.body["user"]["id"], again.body["user"]["id"])
        assertError(400, "CODE_INVALID", verify(email, mail.code(email))) // single use
    }

    @Test
    fun knownAndUnknownAddressesBothGet204AndNoPlainCodeIsStored() {
        val (_, known) = emailUser("Known")
        val unknown = address("Unknown")
        assertEquals(204, start(known).status)
        assertEquals(204, start(unknown).status)
        val code = mail.code(unknown)
        val hash = jdbc.sql("SELECT code_hash FROM email_codes WHERE email = :e AND purpose = 'login'").param("e", unknown).query(String::class.java).single()
        assertFalse(code in hash, "only the HMAC is stored")
        assertEquals(64, hash.length)
        val logged = jdbc.sql("SELECT count(*) FROM email_log WHERE to_hash = :h AND kind = 'login_code'").param("h", EmailAddress.hash(unknown)).query(Int::class.java).single()
        assertEquals(1, logged, "the log holds the hashed address")
        assertEquals(0, jdbc.sql("SELECT count(*) FROM email_log WHERE to_hash = :e").param("e", unknown).query(Int::class.java).single())
    }

    @Test
    fun fiveWrongCodesKillTheCodeAndAnExpiredOneFails() {
        val email = address("Wrong")
        start(email)
        val right = mail.code(email)
        val wrong = if (right == "000000") "111111" else "000000"
        repeat(5) { assertError(400, "CODE_INVALID", verify(email, wrong)) }
        assertError(400, "CODE_INVALID", verify(email, right))

        val other = address("Expired")
        start(other)
        testClock.offset = Duration.ofMinutes(11)
        assertError(400, "CODE_INVALID", verify(other, mail.code(other)))
        testClock.offset = Duration.ZERO

        val replaced = address("Replaced")
        start(replaced)
        val old = mail.code(replaced)
        start(replaced)
        if (old != mail.code(replaced)) assertError(400, "CODE_INVALID", verify(replaced, old))
        assertEquals(200, verify(replaced, mail.code(replaced)).status, "a new code replaces the old one")
    }

    @Test
    fun theSixthCodeInAnHourIs429() {
        val email = address("Many")
        repeat(5) { assertEquals(204, start(email).status) }
        assertError(429, "RATE_LIMITED", start(email))
        testClock.offset = Duration.ofMinutes(61)
        assertEquals(204, start(email).status, "the hour rolls")
    }

    @Test
    fun validation() {
        for (bad in listOf("", "no-at-sign", "a@b", "a b@example.test", "a@exa_mple.test", "x".repeat(250) + "@e.test")) {
            assertError(400, "VALIDATION", start(bad))
        }
        assertError(400, "VALIDATION", http.post("/auth/email/start", mapOf<String, Any>()))
        val email = address("Fmt")
        start(email)
        for (bad in listOf("12345", "1234567", "abcdef", "12 456")) assertError(400, "VALIDATION", verify(email, bad))
    }

    @Test
    fun aRejectedAddressIsSuppressedAndAnOutageIs503() {
        val email = address("Bounce")
        mail.reject += email
        assertError(400, "EMAIL_REJECTED", start(email))
        val reason = jdbc.sql("SELECT reason FROM email_suppressions WHERE email_hash = :h").param("h", EmailAddress.hash(email)).query(String::class.java).single()
        assertEquals("bounce", reason)
        mail.reject.clear()
        assertEquals(204, start(email).status, "codes skip the suppression")
        assertEquals(200, verify(email, mail.code(email)).status)
        assertEquals(0, jdbc.sql("SELECT count(*) FROM email_suppressions WHERE email_hash = :h").param("h", EmailAddress.hash(email)).query(Int::class.java).single(),
            "a successful verify deletes the suppression")

        mail.down = true
        assertError(503, "EMAIL_UNAVAILABLE", start(address("Down")))
    }

    @Test
    fun aKoreanAccountGetsItsCodeInKorean() {
        val (token, email) = emailUser("Ko")
        assertEquals(200, http.patch("/me", mapOf("language" to "ko"), token).status)
        start(email)
        assertEquals("Evensies 코드: ${mail.code(email)}", mail.to(email).last().subject)
        assertTrue(mail.to(email).last().text.startsWith("로그인 코드: "))
    }

    /** A verified Apple/Google address lands email sign-ins in that account; accounts are never merged. */
    @Test
    fun aVerifiedGoogleAddressIsTheSameAccount() {
        val email = address("Gina")
        val google = auth.login("google", "sub-${UUID.randomUUID()}", "Gina", email)
        assertEquals(email, google.user.email)
        start(email)
        assertEquals(google.user.id.toString(), verify(email, mail.code(email)).body["user"]["id"].asString())

        // A second Google account with the same address doesn't take it.
        val other = auth.login("google", "sub-${UUID.randomUUID()}", "Gina 2", email)
        assertNull(other.user.email)
        assertNotEquals(google.user.id, other.user.id)
        // No address, nothing stored.
        assertNull(auth.login("google", "sub-${UUID.randomUUID()}", "Nobody", null).user.email)
    }

    @Test
    fun aDeletedEmailAccountSigningInAgainIsReactivatedWithoutItsOldName() {
        val (token, email) = emailUser("Again")
        val id = myId(token)
        assertEquals(204, http.delete("/me", token).status)
        start(email)
        val back = verify(email, mail.code(email))
        assertEquals(id, back.body["user"]["id"].asString())
        assertEquals(email, back.body["user"]["email"].asString())
        assertEquals("", back.body["user"]["displayName"].asString())
    }

    @Test
    fun infoSaysEmailSignInIsOnAndTheDevJobRuns() {
        val info = http.get("/info").body
        assertTrue(info["emailLogin"].asBoolean())
        assertFalse(info["appleLogin"].asBoolean(), "no Apple ids in this test server")
        assertFalse(info["googleLogin"].asBoolean())
        assertEquals("help@evensies.test", info["supportEmail"].asString())
        assertEquals(401, http.post("/dev/jobs/email", null).status)
        assertEquals(204, http.post("/dev/jobs/email", null, login("Dev-job")).status)
    }
}
