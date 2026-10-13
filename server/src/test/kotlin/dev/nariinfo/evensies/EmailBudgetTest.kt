package dev.nariinfo.evensies

import dev.nariinfo.evensies.auth.AuthService
import dev.nariinfo.evensies.email.EmailAddress
import dev.nariinfo.evensies.email.EmailJobs
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.test.context.TestPropertySource
import java.time.Instant
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * `EVENSIES_EMAIL_DAILY_LIMIT` and the per-IP sign-in limit (docs/API.md "Daily budget and rate limits"), in their own server so the counts are
 * this class's alone: digests and recurring reminders stop at 80%, invites at 100% (429), codes always go.
 */
@TestPropertySource(properties = ["evensies.email.daily-limit=10", "evensies.email.auth-rate-per-minute=3"])
class EmailBudgetTest : IntegrationTestBase() {
    @Autowired
    private lateinit var jdbc: JdbcClient

    @Autowired
    private lateinit var jobs: EmailJobs

    @Autowired
    private lateinit var auth: AuthService

    private fun fill(rows: Int) = repeat(rows) {
        jdbc.sql("INSERT INTO email_log (kind, to_hash) VALUES ('digest', :h)").param("h", EmailAddress.hash("filler-$it@example.test")).update()
    }

    private fun used() = jdbc.sql("SELECT count(*) FROM email_log WHERE sent_at > now() - interval '1 day'").query(Int::class.java).single()

    @Test
    fun theDailyBudget() {
        // Accounts with addresses, made without the (rate-limited) sign-in endpoints.
        val annaEmail = address("Anna")
        val anna = auth.login("google", "sub-${UUID.randomUUID()}", "Anna", annaEmail)
        val annaToken = anna.accessToken
        val ben = login("Bud-ben")
        val group = createGroup(annaToken)
        val id = group["id"].asString()
        val b = join(ben, group, "Ben")
        jobs.digests(Instant.now(), force = false) // starts Anna's clock
        assertEquals(200, push(ben, id, expenseCreated(b, 1000, mapOf(group["myMemberId"].asString() to 500, b to 500))).status)
        jdbc.sql("UPDATE notification_prefs SET last_digest_at = now() - interval '2 days' WHERE user_id = :u").param("u", anna.user.id).update()
        val window = jdbc.sql("SELECT last_digest_feed_id FROM notification_prefs WHERE user_id = :u").param("u", anna.user.id).query(Long::class.java).single()

        fill(8 - used())
        jobs.digests(Instant.now(), force = false)
        assertTrue(mail.to(annaEmail).isEmpty(), "digests stop at 80%")
        assertEquals(window, jdbc.sql("SELECT last_digest_feed_id FROM notification_prefs WHERE user_id = :u").param("u", anna.user.id).query(Long::class.java).single(),
            "the window stays for the next run")

        // Invites still go up to 100%.
        val cara = UUID.randomUUID().toString()
        val dan = UUID.randomUUID().toString()
        assertEquals(200, push(annaToken, id, memberAdded("Cara", cara), memberAdded("Dan", dan)).status)
        assertEquals(204, http.post("/groups/$id/members/$cara/invite-email", mapOf("email" to address("Cara")), annaToken).status)
        fill(10 - used())
        val full = http.post("/groups/$id/members/$dan/invite-email", mapOf("email" to address("Dan")), annaToken)
        assertEquals(429, full.status, full.text)
        assertTrue("share the link instead" in full.text)

        // Codes always go.
        val change = address("Change")
        assertEquals(204, http.post("/me/email", mapOf("email" to change), annaToken).status)
        assertEquals(1, mail.to(change).size)
    }

    @Test
    fun signInIsLimitedPerIp() {
        repeat(3) { assertEquals(204, http.post("/auth/email/start", mapOf("email" to address("Ip$it"))).status) }
        assertEquals(429, http.post("/auth/email/start", mapOf("email" to address("Ip4"))).status)
        assertEquals(429, http.post("/auth/email/verify", mapOf("email" to address("Ip5"), "code" to "123456")).status, "verify shares the bucket")
    }
}
