package dev.nariinfo.evensies

import dev.nariinfo.evensies.email.EmailJobs
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The reminder email before a repeating bill posts (docs/API.md "반복 지출 알림", 적용 규칙 18): `remindDaysBefore` on the
 * series events, and [EmailJobs.recurringReminders] once per occurrence for each involved member with an address.
 */
class RecurringReminderTest : IntegrationTestBase() {
    @Autowired
    private lateinit var jdbc: JdbcClient

    @Autowired
    private lateinit var jobs: EmailJobs

    private fun tag() = UUID.randomUUID().toString().take(6)

    private fun assertError(status: Int, code: String, res: Http.Resp) {
        assertEquals(status, res.status, res.text)
        assertEquals(code, res.code(), res.text)
    }

    private fun template(payer: String, shares: Map<String, Long>) = mapOf(
        "description" to "Rent", "amount" to shares.values.sum(), "currency" to "EUR", "fxRateToDefault" to null, "paidBy" to payer,
        "category" to null, "shares" to lines(shares),
    )

    private fun created(r: String, template: Map<String, Any?>, remind: Any?, keyPresent: Boolean = true) = event(
        "recurrence.created",
        mapOf("recurrenceId" to r, "frequency" to "monthly", "startDate" to LocalDate.now(ZoneOffset.UTC).toString(), "timeZone" to "UTC", "template" to template) +
            (if (keyPresent) mapOf("remindDaysBefore" to remind) else emptyMap()),
    )

    /** The next repeat posts in [days] days (occurrence [n]). */
    private fun nextIn(r: String, days: Long, n: Int = 1) {
        jdbc.sql("UPDATE recurrences SET next_occurrence = :n, next_due_at = now() + make_interval(days => :d) WHERE id = :id")
            .param("n", n).param("d", days.toInt()).param("id", UUID.fromString(r)).update()
    }

    private fun run() = jobs.recurringReminders(Instant.now(), force = false)

    private fun stop(token: String, groupId: String, r: String) = assertEquals(200, push(token, groupId, event("recurrence.deleted", mapOf("recurrenceId" to r))).status)

    private class Setup(val anna: String, val annaEmail: String, val ben: String, val benEmail: String, val dan: String, val danEmail: String,
                        val id: String, val a: String, val b: String, val c: String, val d: String)

    /** Anna (creator, payer), Ben and Cara (no address) share the rent; Dan has an address but isn't on it. */
    private fun setup(): Setup {
        val (anna, annaEmail) = emailUser("Anna")
        val (ben, benEmail) = emailUser("Ben")
        val (dan, danEmail) = emailUser("Dan")
        val cara = login("Rr-cara-${tag()}")
        val group = createGroup(anna, name = "Flat")
        val id = group["id"].asString()
        return Setup(anna, annaEmail, ben, benEmail, dan, danEmail, id, group["myMemberId"].asString(), join(ben, group, "Ben"), join(cara, group, "Cara"), join(dan, group, "Dan"))
    }

    private fun reminders(email: String) = mail.to(email).filter { "will be added on" in it.subject }

    @Test
    fun threeDaysBeforeEmailsEachInvolvedMemberOncePerOccurrence() {
        val s = setup()
        val r = UUID.randomUUID().toString()
        assertEquals(200, push(s.anna, s.id, created(r, template(s.a, mapOf(s.a to 30000, s.b to 30000, s.c to 30000)), 3)).status)
        assertEquals(3, snapshot(s.anna, s.id)["recurrences"].single()["remindDaysBefore"].asInt())
        nextIn(r, 5)
        run()
        assertEquals(0, reminders(s.benEmail).size, "not yet: 5 days ahead")
        nextIn(r, 2)
        run()
        run()
        val ben = reminders(s.benEmail).single()
        assertEquals(1, reminders(s.annaEmail).size, "the payer is on it too")
        assertEquals(0, reminders(s.danEmail).size, "not on the expense")
        val date = java.time.format.DateTimeFormatter.ofLocalizedDate(java.time.format.FormatStyle.MEDIUM).withLocale(java.util.Locale.ENGLISH)
            .format(LocalDate.now(ZoneOffset.UTC).plusMonths(1))
        assertEquals("“Rent” (€900.00) will be added on $date", ben.subject)
        assertTrue("Hi Ben,\n\n“Rent” in Flat repeats monthly and will be added on $date. Your share: €300.00." in ben.text, ben.text)
        assertTrue("You get this because Anna turned on reminders for this repeating expense." in ben.text, ben.text)
        val anna = reminders(s.annaEmail).single().text
        assertTrue("You get this because you turned on reminders for this repeating expense." in anna, "the creator reads about themselves: $anna")
        assertTrue(ben.header("List-Unsubscribe")!!.startsWith("<http://localhost:8080/email/unsubscribe?t="))

        nextIn(r, 2, n = 2) // the scheduler posted occurrence 1: the next one gets its own reminder
        run()
        assertEquals(2, reminders(s.benEmail).size)

        stop(s.anna, s.id, r)
        nextIn(r, 2, n = 3)
        run()
        assertEquals(2, reminders(s.benEmail).size, "none after a stop")
    }

    private fun remindedOccurrence(r: String) =
        jdbc.sql("SELECT reminded_occurrence FROM recurrences WHERE id = :id").param("id", UUID.fromString(r)).query(Int::class.java).single()

    @AfterEach
    fun reset() {
        mail.down = false
        mail.reject.clear()
    }

    @Test
    fun aFailedSendIsRetriedNextRunWithoutRepeatingTheOnesThatWentOut() {
        val s = setup()
        val r = UUID.randomUUID().toString()
        assertEquals(200, push(s.anna, s.id, created(r, template(s.a, mapOf(s.a to 1000, s.b to 1000)), 3)).status)
        nextIn(r, 2)
        mail.down = true
        run()
        assertEquals(0, remindedOccurrence(r), "the relay was down: the occurrence stays open")
        mail.down = false
        mail.reject += s.benEmail
        run()
        assertEquals(1, reminders(s.annaEmail).size)
        assertEquals(0, remindedOccurrence(r), "Ben's address was rejected (now suppressed): retried next run")
        run()
        assertEquals(1, reminders(s.annaEmail).size, "Anna already got it")
        assertEquals(0, reminders(s.benEmail).size)
        assertEquals(1, remindedOccurrence(r), "suppressed counts as done")
        run()
        assertEquals(1, reminders(s.annaEmail).size)
        stop(s.anna, s.id, r)
    }

    @Test
    fun noneForADeletedGroupSummariesOffABlockedCreatorOrNoReminder() {
        val s = setup()
        val r = UUID.randomUUID().toString()
        val off = UUID.randomUUID().toString()
        assertEquals(200, push(s.anna, s.id, created(r, template(s.a, mapOf(s.a to 1000, s.b to 1000, s.d to 1000)), 7)).status)
        assertEquals(200, push(s.anna, s.id, created(off, template(s.a, mapOf(s.a to 1000, s.b to 1000)), null, keyPresent = false)).status)
        assertEquals(200, http.put("/me/notifications", mapOf("expenses" to true, "comments" to true, "members" to true, "emailDigest" to "off"), s.ben).status)
        assertEquals(204, http.put("/me/blocks/${myId(s.anna)}", null, s.dan).status)
        nextIn(r, 1)
        nextIn(off, 1)
        run()
        assertEquals(1, reminders(s.annaEmail).size, "only Anna: Ben turned summaries off, Dan blocked the creator, the other series has no reminder")
        assertEquals(0, reminders(s.benEmail).size + reminders(s.danEmail).size)

        val r2 = UUID.randomUUID().toString()
        assertEquals(200, push(s.anna, s.id, created(r2, template(s.a, mapOf(s.a to 1000)), 1)).status)
        assertEquals(200, push(s.anna, s.id, event("group.deleted", emptyMap())).status)
        nextIn(r2, 1)
        run()
        assertEquals(1, reminders(s.annaEmail).size, "none for a deleted group")
        stop(s.anna, s.id, r)
        stop(s.anna, s.id, off)
        stop(s.anna, s.id, r2)
    }

    @Test
    fun remindDaysBeforeOnTheSeriesEvents() {
        val (anna, _) = emailUser("Val")
        val group = createGroup(anna)
        val id = group["id"].asString()
        val a = group["myMemberId"].asString()
        val t = template(a, mapOf(a to 1000))
        for (bad in listOf(0, 8, "3", 2.5, true)) assertError(400, "VALIDATION", push(anna, id, created(UUID.randomUUID().toString(), t, bad)))
        val r = UUID.randomUUID().toString()
        assertEquals(200, push(anna, id, created(r, t, null)).status, "null = none")
        fun remind() = snapshot(anna, id)["recurrences"].values().single { it["id"].asString() == r }["remindDaysBefore"]
        assertTrue(remind().isNull)
        // fields stays required: the Dart applier reads it unconditionally, so a fieldless update would wedge every app's sync.
        assertError(400, "VALIDATION", push(anna, id, event("recurrence.updated", mapOf("recurrenceId" to r, "remindDaysBefore" to 3))))
        assertError(400, "VALIDATION", push(anna, id, event("recurrence.updated", mapOf("recurrenceId" to r, "fields" to null, "remindDaysBefore" to 3))))
        assertEquals(200, push(anna, id, event("recurrence.updated", mapOf("recurrenceId" to r, "fields" to emptyMap<String, Any>(), "remindDaysBefore" to 3))).status)
        assertEquals(3, remind().asInt())
        assertEquals(200, push(anna, id, event("recurrence.updated", mapOf("recurrenceId" to r, "fields" to mapOf("description" to "Rent 2")))).status)
        assertEquals(3, remind().asInt(), "missing keeps it")
        assertEquals(200, push(anna, id, event("recurrence.updated", mapOf("recurrenceId" to r, "fields" to emptyMap<String, Any>(), "remindDaysBefore" to null))).status)
        assertTrue(remind().isNull, "null clears")
        assertError(400, "VALIDATION", push(anna, id, event("recurrence.updated", mapOf("recurrenceId" to r, "remindDaysBefore" to 9))))
        assertError(400, "VALIDATION", push(anna, id, event("recurrence.updated", mapOf("recurrenceId" to r))))
        // An old app's series (no key) has none; the pulled event is stored as sent.
        val old = UUID.randomUUID().toString()
        assertEquals(200, push(anna, id, created(old, t, null, keyPresent = false)).status)
        assertTrue(snapshot(anna, id)["recurrences"].values().single { it["id"].asString() == old }["remindDaysBefore"].isNull)
        stop(anna, id, r)
        stop(anna, id, old)
    }
}
