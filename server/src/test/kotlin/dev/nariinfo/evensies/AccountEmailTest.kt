package dev.nariinfo.evensies

import dev.nariinfo.evensies.auth.AuthService
import dev.nariinfo.evensies.email.EmailAccounts
import dev.nariinfo.evensies.email.EmailAddress
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** The account address (docs/API.md "계정 이메일"): add, change by code, remove; never shown to other members. */
class AccountEmailTest : IntegrationTestBase() {
    @Autowired
    private lateinit var jdbc: JdbcClient

    @Autowired
    private lateinit var auth: AuthService

    @AfterEach
    fun reset() = mail.reject.clear()

    private fun assertError(status: Int, code: String, res: Http.Resp) {
        assertEquals(status, res.status, res.text)
        assertEquals(code, res.code(), res.text)
    }

    private fun change(token: String, email: String): Http.Resp {
        assertEquals(204, http.post("/me/email", mapOf("email" to email), token).status)
        return http.post("/me/email/verify", mapOf("email" to email, "code" to mail.code(email)), token)
    }

    @Test
    fun addChangeAndRemoveWithCodes() {
        val token = login("Acc-${java.util.UUID.randomUUID().toString().take(6)}")
        assertTrue(http.get("/me", token).body["email"].isNull)
        assertEquals(setOf("id", "displayName", "homeCurrency", "language", "email", "emailBounced"), http.get("/me", token).body.propertyNames().toSet())
        val first = address("First")
        val added = change(token, first)
        assertEquals(200, added.status, added.text)
        assertEquals(first, added.body["email"].asString())
        assertEquals("${mail.code(first)} is your Evensies code", mail.to(first).last().subject)
        assertTrue(mail.to(first).last().text.startsWith("Enter "))

        val second = address("Second")
        assertEquals(second, change(token, second).body["email"].asString())
        assertEquals(second, http.get("/me", token).body["email"].asString())

        assertEquals(204, http.delete("/me/email", token).status, "an Apple/Google/dev account may remove it")
        assertTrue(http.get("/me", token).body["email"].isNull)
    }

    @Test
    fun aWrongOrForeignCodeIsInvalid() {
        val anna = login("Acc-anna-${java.util.UUID.randomUUID().toString().take(6)}")
        val ben = login("Acc-ben-${java.util.UUID.randomUUID().toString().take(6)}")
        val email = address("Mine")
        assertEquals(204, http.post("/me/email", mapOf("email" to email), anna).status)
        assertError(400, "CODE_INVALID", http.post("/me/email/verify", mapOf("email" to email, "code" to mail.code(email)), ben))
        assertError(400, "CODE_INVALID", http.post("/auth/email/verify", mapOf("email" to email, "code" to mail.code(email))), )
        assertError(400, "VALIDATION", http.post("/me/email", mapOf("email" to "nope"), anna))
        assertEquals(401, http.post("/me/email", mapOf("email" to email)).status)
    }

    @Test
    fun anAddressAnotherAccountHoldsIsTaken() {
        val (_, taken) = emailUser("Holder")
        val token = login("Acc-taker-${java.util.UUID.randomUUID().toString().take(6)}")
        assertError(409, "EMAIL_TAKEN", change(token, taken))
        assertTrue(http.get("/me", token).body["email"].isNull)
    }

    @Test
    fun anEmailOnlyAccountMustKeepAnAddressAndTheOldOneNoLongerSignsIn() {
        val (token, old) = emailUser("Only")
        assertError(409, "EMAIL_REQUIRED", http.delete("/me/email", token))
        val id = myId(token)
        val new = address("Moved")
        assertEquals(200, change(token, new).status)
        assertEquals(204, http.post("/auth/email/start", mapOf("email" to new)).status)
        assertEquals(id, http.post("/auth/email/verify", mapOf("email" to new, "code" to mail.code(new))).body["user"]["id"].asString())
        assertEquals(204, http.post("/auth/email/start", mapOf("email" to old)).status)
        val other = http.post("/auth/email/verify", mapOf("email" to old, "code" to mail.code(old))).body["user"]["id"].asString()
        assertTrue(other != id, "the old address is a new account now")
    }

    @Test
    fun bouncedUntilVerifiedAgain() {
        val (token, email) = emailUser("Bouncy")
        assertFalse(http.get("/me", token).body["emailBounced"].asBoolean())
        jdbc.sql("INSERT INTO email_suppressions (email_hash, reason) VALUES (:h, 'bounce')").param("h", EmailAddress.hash(email)).update()
        assertTrue(http.get("/me", token).body["emailBounced"].asBoolean())
        assertEquals(200, change(token, email).status, "verifying the same address again")
        assertFalse(http.get("/me", token).body["emailBounced"].asBoolean(), "verify clears the suppression")
    }

    @Test
    fun aRemovedAddressStaysRemovedAtTheNextAppleOrGoogleSignIn() {
        val email = address("Gone")
        val subject = "sub-${java.util.UUID.randomUUID()}"
        val first = auth.login("google", subject, "Gina", email)
        assertEquals(email, first.user.email)
        assertEquals(204, http.delete("/me/email", first.accessToken).status)
        assertNull(auth.login("google", subject, "Gina", email).user.email, "the id-token address isn't adopted again")
        assertTrue(http.get("/me", first.accessToken).body["email"].isNull)
        assertEquals(email, change(first.accessToken, email).body["email"].asString(), "adding it back by code still works")
    }

    @Test
    fun anAddressADeletedEmailAccountUsedIsFree() {
        val (gone, x) = emailUser("Left")
        assertEquals(204, http.delete("/me", gone).status)
        val (token, _) = emailUser("Mover")
        val id = myId(token)
        val res = change(token, x)
        assertEquals(200, res.status, res.text)
        assertEquals(x, res.body["email"].asString())
        assertEquals(204, http.post("/auth/email/start", mapOf("email" to x)).status)
        assertEquals(id, http.post("/auth/email/verify", mapOf("email" to x, "code" to mail.code(x))).body["user"]["id"].asString())
    }

    @Test
    fun changeCodesAreCappedPerAccount() {
        val token = login("Acc-spam-${java.util.UUID.randomUUID().toString().take(6)}")
        repeat(EmailAccounts.CODES_PER_HOUR) { assertEquals(204, http.post("/me/email", mapOf("email" to address("Spam$it")), token).status) }
        val next = address("Spam")
        assertError(429, "RATE_LIMITED", http.post("/me/email", mapOf("email" to next), token))
        assertTrue(mail.to(next).isEmpty(), "different addresses each time, still capped")
    }

    @Test
    fun anAddressJavaMailCantParseIsAValidationError() {
        val token = login("Acc-odd-${java.util.UUID.randomUUID().toString().take(6)}")
        for (odd in listOf("a,b@example.test", "a\"b@example.test")) {
            assertError(400, "VALIDATION", http.post("/me/email", mapOf("email" to odd), token))
            assertError(400, "VALIDATION", http.post("/auth/email/start", mapOf("email" to odd)))
            assertEquals(0, jdbc.sql("SELECT count(*) FROM email_log WHERE to_hash = :h").param("h", EmailAddress.hash(odd)).query(Int::class.java).single(), "not logged")
        }
    }

    @Test
    fun otherMembersNeverSeeTheAddress() {
        val (anna, email) = emailUser("Visible")
        val group = createGroup(anna)
        val ben = login("Acc-viewer-${java.util.UUID.randomUUID().toString().take(6)}")
        join(ben, group, "Ben")
        val id = group["id"].asString()
        for (text in listOf(
            http.get("/groups/$id/snapshot", ben).text, http.get("/groups/$id", ben).text, http.get("/groups", ben).text,
            http.get("/invites/${group["inviteCode"].asString()}").text, http.get("/groups/$id/activity", ben).text,
            http.get("/groups/$id/events?after=0", ben).text,
        )) assertFalse(email in text, text)
    }
}
