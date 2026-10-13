package dev.nariinfo.evensies

import dev.nariinfo.evensies.email.EmailAddress
import dev.nariinfo.evensies.email.EmailJobs
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import java.time.Instant
import java.time.OffsetDateTime
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The hourly digest (docs/API.md "Summary emails") on the real database: who gets it and when ([EmailJobs.digests] called
 * directly), what it says, and when the window moves. Every candidate in the shared database is processed, so each test
 * only looks at its own addresses.
 */
class DigestJobTest : IntegrationTestBase() {
    @Autowired
    private lateinit var jdbc: JdbcClient

    @Autowired
    private lateinit var jobs: EmailJobs

    @Autowired
    private lateinit var capture: CapturingPushSender

    @AfterEach
    fun reset() {
        mail.down = false
        capture.enabled = true
    }

    private fun tag() = UUID.randomUUID().toString().take(6)

    private fun prefs(token: String) = http.get("/me/notifications", token).body

    private fun setPrefs(token: String, digest: String, push: Boolean = true) =
        http.put("/me/notifications", mapOf("expenses" to push, "comments" to push, "members" to push, "emailDigest" to digest), token)

    /** The summary clock: when the last one went out and the window's start. */
    private fun clock(userId: String): Pair<OffsetDateTime?, Long> =
        jdbc.sql("SELECT last_digest_at, last_digest_feed_id FROM notification_prefs WHERE user_id = :u").param("u", UUID.fromString(userId))
            .query { rs, _ -> rs.getObject("last_digest_at", OffsetDateTime::class.java) to rs.getLong("last_digest_feed_id") }.single()

    /** The last summary went out two days ago: a daily one is due. */
    private fun makeDue(userId: String) {
        jdbc.sql("UPDATE notification_prefs SET last_digest_at = now() - interval '2 days' WHERE user_id = :u").param("u", UUID.fromString(userId)).update()
    }

    private fun run() = jobs.digests(Instant.now(), force = false)

    private class Setup(val anna: String, val email: String, val annaId: String, val ben: String, val id: String, val a: String, val b: String)

    /** Anna (with an address, clock started) and Ben in "Rome trip". */
    private fun setup(): Setup {
        val (anna, email) = emailUser("Anna")
        val ben = login("Dg-ben-${tag()}")
        val group = createGroup(anna, name = "Rome trip")
        val id = group["id"].asString()
        val b = join(ben, group, "Ben")
        run() // the first run starts Anna's clock without sending
        assertTrue(mail.to(email).none { "update" in it.subject })
        return Setup(anna, email, myId(anna), ben, id, group["myMemberId"].asString(), b)
    }

    private fun digests(email: String) = mail.to(email).filter { "update" in it.subject || "summary" in it.subject }

    @Test
    fun autoIsDailyWithoutAPushCapableDeviceAndMonthlyWithOne() {
        val (anna, _) = emailUser("Auto")
        assertEquals("auto" to "daily", prefs(anna).let { it["emailDigest"].asString() to it["emailDigestEffective"].asString() })
        assertEquals(setOf("expenses", "comments", "members", "reminders", "emailDigest", "emailDigestEffective"), prefs(anna).propertyNames().toSet())
        val deviceId = UUID.randomUUID().toString()
        assertEquals(204, http.post("/devices", mapOf("deviceId" to deviceId, "fcmToken" to "tok-${UUID.randomUUID()}"), anna).status)
        assertEquals("monthly", prefs(anna)["emailDigestEffective"].asString())
        capture.enabled = false
        assertEquals("daily", prefs(anna)["emailDigestEffective"].asString(), "FCM off: nothing can show")
        capture.enabled = true
        assertEquals(200, setPrefs(anna, "auto", push = false).status)
        assertEquals("daily", prefs(anna)["emailDigestEffective"].asString(), "all three push switches off")
        assertEquals(200, setPrefs(anna, "auto").status)
        assertEquals(204, http.post("/devices", mapOf("deviceId" to deviceId, "fcmToken" to "tok-${UUID.randomUUID()}", "notificationsAllowed" to false), anna).status)
        assertEquals("daily", prefs(anna)["emailDigestEffective"].asString(), "the OS doesn't let it show notifications")
        jdbc.sql("UPDATE devices SET notifications_allowed = true, last_seen_at = now() - interval '61 days' WHERE id = :d").param("d", deviceId).update()
        assertEquals("daily", prefs(anna)["emailDigestEffective"].asString(), "not seen for 60 days")

        assertEquals("weekly", setPrefs(anna, "weekly").body["emailDigestEffective"].asString())
        assertEquals("off", setPrefs(anna, "off").body["emailDigestEffective"].asString())
        assertEquals("off", prefs(login("Dg-noemail-${tag()}"))["emailDigestEffective"].asString(), "no address")
        assertEquals(400, setPrefs(anna, "hourly").status)
        assertEquals(400, http.put("/me/notifications", mapOf("expenses" to true, "comments" to true, "members" to true, "emailDigest" to null), anna).status)
        assertEquals("off", http.put("/me/notifications", mapOf("expenses" to true, "comments" to true, "members" to true), anna).body["emailDigest"].asString(),
            "missing = unchanged (older apps)")
    }

    @Test
    fun aDailyDigestSaysWhatOthersDidWithBalancesAndTheWindowMoves() {
        val s = setup()
        assertEquals(200, push(s.ben, s.id, expenseCreated(s.b, 3000, mapOf(s.a to 1500, s.b to 1500))).status)
        assertEquals(200, push(s.anna, s.id, expenseCreated(s.a, 500, mapOf(s.a to 250, s.b to 250), description = "Mine")).status)
        run()
        assertEquals(0, digests(s.email).size, "not due yet")
        makeDue(s.annaId)
        run()
        val d = digests(s.email).single()
        assertEquals("1 update in Rome trip", d.subject)
        assertTrue(d.text.startsWith("Hi Anna,\n\nRome trip\n• Ben added “Dinner” · €30.00 · you owe €15.00\n\nYour balances\n• Rome trip: you owe €12.50\n"), d.text)
        assertTrue("You get this daily because notifications are off on your devices." in d.text)
        assertTrue("Mine" !in d.text, "the recipient's own changes are left out")
        assertTrue(d.header("List-Unsubscribe")!!.startsWith("<http://localhost:8080/email/unsubscribe?t="))
        val (at, feed) = clock(s.annaId)
        assertTrue(at!!.toInstant() > Instant.now().minusSeconds(60))
        assertTrue(feed > 0)

        makeDue(s.annaId)
        run()
        assertEquals(1, digests(s.email).size, "the window moved: nothing new to say")
        assertTrue(clock(s.annaId).first!!.toInstant() > Instant.now().minusSeconds(60), "the clock moves on nothing to say too")
    }

    @Test
    fun aFailedSendKeepsTheWindowAndASuppressedAddressGetsNothing() {
        val s = setup()
        assertEquals(200, push(s.ben, s.id, expenseCreated(s.b, 1000, mapOf(s.a to 500, s.b to 500), description = "Taxi")).status)
        makeDue(s.annaId)
        val before = clock(s.annaId)
        mail.down = true
        run()
        assertEquals(before, clock(s.annaId), "no advance on a failed send")
        mail.down = false
        run()
        assertTrue("Taxi" in digests(s.email).single().text)

        jdbc.sql("INSERT INTO email_suppressions (email_hash, reason) VALUES (:h, 'bounce')").param("h", EmailAddress.hash(s.email)).update()
        assertEquals(200, push(s.ben, s.id, expenseCreated(s.b, 1000, mapOf(s.a to 500, s.b to 500), description = "Bus")).status)
        makeDue(s.annaId)
        run()
        assertEquals(1, digests(s.email).size)
        assertEquals("off", prefs(s.anna)["emailDigestEffective"].asString())
    }

    @Test
    fun aDeletedGroupGivesOnlyItsDeleteLineAndABlockedActorNone() {
        val s = setup()
        assertEquals(200, push(s.ben, s.id, expenseCreated(s.b, 1000, mapOf(s.a to 500, s.b to 500), description = "Hidden")).status)
        assertEquals(200, push(s.ben, s.id, event("group.deleted", emptyMap())).status)
        makeDue(s.annaId)
        run()
        val d = digests(s.email).single()
        assertTrue("• Ben deleted the group “Rome trip”" in d.text && "Hidden" !in d.text && "Your balances" !in d.text, d.text)

        val ben2 = login("Dg-ben2-${tag()}")
        val g2 = createGroup(s.anna, name = "Flat")
        val b2 = join(ben2, g2, "Ben2")
        assertEquals(204, http.put("/me/blocks/${myId(ben2)}", null, s.anna).status)
        run()
        assertEquals(200, push(ben2, g2["id"].asString(), expenseCreated(b2, 1000, mapOf(g2["myMemberId"].asString() to 500, b2 to 500), description = "Blocked")).status)
        makeDue(s.annaId)
        run()
        assertTrue(digests(s.email).none { "Blocked" in it.text }, "a blocked actor's lines are left out")
    }

    @Test
    fun aMonthlyChoiceWaitsForTheFirstAndChangingTheChoiceRestartsTheClock() {
        val s = setup()
        assertEquals(200, setPrefs(s.anna, "monthly").status)
        assertTrue(clock(s.annaId).first!!.toInstant() > Instant.now().minusSeconds(60), "a changed choice restarts the clock")
        assertEquals(200, push(s.ben, s.id, expenseCreated(s.b, 1000, mapOf(s.a to 500, s.b to 500))).status)
        makeDue(s.annaId) // two days ago: the next 1st hasn't come (unless today is the 1st or 2nd)
        val today = java.time.LocalDate.now(java.time.ZoneOffset.UTC).dayOfMonth
        run()
        if (today > 2) assertEquals(0, digests(s.email).size)
        jdbc.sql("UPDATE notification_prefs SET last_digest_at = now() - interval '40 days' WHERE user_id = :u").param("u", UUID.fromString(s.annaId)).update()
        run()
        val d = digests(s.email).single()
        assertTrue(d.subject.startsWith("Your Evensies summary for "), d.subject)
        assertTrue("You get this monthly summary because you chose it in Settings → Notifications." in d.text)
    }
}
