package dev.nariinfo.evensies

import dev.nariinfo.evensies.fx.FxService
import dev.nariinfo.evensies.push.NotificationPrefs
import dev.nariinfo.evensies.recurrence.RecurrenceScheduler
import dev.nariinfo.evensies.recurrence.Schedule
import dev.nariinfo.evensies.sync.EventValidator
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import tools.jackson.databind.JsonNode
import java.time.Instant
import java.time.LocalDate
import java.time.OffsetDateTime
import java.time.ZoneOffset
import java.util.UUID
import java.util.concurrent.Callable
import java.util.concurrent.Executors
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Repeating expenses over real HTTP (docs/API.md "반복 지출", "반복 지출 검증", 적용 규칙 15·16): the `recurrence.*` events,
 * the scheduler ([RecurrenceScheduler.runDue] called with chosen instants; series dates are in 2031 or later so the real
 * tick never reaches them), activity and push. Every test stops all series afterwards so a later `runDue` sees only its own.
 */
class RecurrenceTest : IntegrationTestBase() {
    @Autowired
    private lateinit var scheduler: RecurrenceScheduler

    @Autowired
    private lateinit var jdbc: JdbcClient

    @Autowired
    private lateinit var capture: CapturingPushSender

    @Autowired
    private lateinit var fxService: FxService

    @BeforeEach
    @AfterEach
    fun stopAllSeries() {
        jdbc.sql("UPDATE recurrences SET deleted_at = now() WHERE deleted_at IS NULL").update()
    }

    /** Anna's group with Ben ([a], [b] their members). */
    private class Setup(val id: String, val anna: String, val ben: String, val a: String, val b: String)

    private fun tag() = UUID.randomUUID().toString().take(6)

    private fun setup(currency: String = "EUR"): Setup {
        val t = tag()
        val anna = login("Rec-anna-$t")
        val ben = login("Rec-ben-$t")
        val group = createGroup(anna, currency = currency)
        return Setup(group["id"].asString(), anna, ben, group["myMemberId"].asString(), join(ben, group, "Ben"))
    }

    private fun uuid() = UUID.randomUUID().toString()

    /** Rent paid by [a], split equally with [b]: the template the app sends (an `expense.created` payload without the four keys). */
    private fun rent(a: String, b: String, amount: Long = 120000, extra: Map<String, Any?> = emptyMap()) = mapOf(
        "description" to "Rent", "amount" to amount, "currency" to "EUR", "fxRateToDefault" to null, "paidBy" to a,
        "payers" to lines(mapOf(a to amount)), "refund" to false, "split" to mapOf("mode" to "equal"), "category" to "home.rent",
        "notes" to null, "shares" to lines(mapOf(a to amount / 2, b to amount - amount / 2)),
    ) + extra

    private fun at(type: String, payload: Map<String, Any?>, createdAt: Instant) =
        mapOf("clientId" to uuid(), "type" to type, "payload" to payload, "createdAt" to createdAt.toString())

    private fun seriesCreated(
        r: String, template: Map<String, Any?>, startDate: String, frequency: String = "monthly", timeZone: String = "+02:00",
        createdAt: Instant = Instant.now(),
    ) = at(
        "recurrence.created",
        mapOf("recurrenceId" to r, "frequency" to frequency, "startDate" to startDate, "timeZone" to timeZone, "template" to template),
        createdAt,
    )

    private fun seriesUpdated(r: String, fields: Map<String, Any?>) = event("recurrence.updated", mapOf("recurrenceId" to r, "fields" to fields))

    private fun seriesDeleted(r: String) = event("recurrence.deleted", mapOf("recurrenceId" to r))

    /** The series' first expense (occurrence 0), as the app saves it. */
    private fun firstOf(r: String?, template: Map<String, Any?>, date: String, x: String = uuid(), occurrence: Any? = 0) =
        event("expense.created", template + mapOf("expenseId" to x, "date" to date, "recurrenceId" to r, "occurrence" to occurrence))

    private fun ok(res: Http.Resp): Http.Resp = res.also { assertEquals(200, it.status, it.text) }

    private fun assertError(status: Int, code: String, res: Http.Resp) {
        assertEquals(status, res.status, res.text)
        assertEquals(code, res.code(), res.text)
    }

    private fun pulled(token: String, groupId: String): List<JsonNode> = http.get("/groups/$groupId/events?after=0", token).body["events"].values().toList()

    /** Repeats Evensies added to series [r], in seq order. */
    private fun repeats(token: String, groupId: String, r: String) = pulled(token, groupId).filter {
        it["type"].asString() == "expense.created" && it["actorUserId"].isNull && it["payload"]["recurrenceId"]?.asString() == r
    }

    private fun latestSeq(token: String, groupId: String) = http.get("/groups/$groupId/events?after=0", token).body["latestSeq"].asLong()

    private class Row(val n: Int, val dueAt: Instant, val stopped: Boolean, val createdBy: String?, val groupId: String)

    private fun row(r: String): Row? = jdbc.sql("SELECT * FROM recurrences WHERE id = :id").param("id", UUID.fromString(r)).query { rs, _ ->
        Row(
            rs.getInt("next_occurrence"), rs.getObject("next_due_at", OffsetDateTime::class.java).toInstant(), rs.getObject("deleted_at") != null,
            rs.getString("created_by"), rs.getString("group_id"),
        )
    }.optional().orElse(null)

    private fun expenseColumns(x: String): Triple<String?, Int?, String?> = jdbc.sql("SELECT recurrence_id, occurrence, created_by FROM expenses WHERE id = :id")
        .param("id", UUID.fromString(x)).query { rs, _ -> Triple(rs.getString("recurrence_id"), rs.getObject("occurrence", Int::class.javaObjectType), rs.getString("created_by")) }
        .single()

    private fun derivedId(r: String, n: Int) = scheduler.derivedId(UUID.fromString(r), n).toString()

    private fun recurrences(token: String, groupId: String) = snapshot(token, groupId)["recurrences"].values().associateBy { it["id"].asString() }

    private fun expenses(token: String, groupId: String) = snapshot(token, groupId)["expenses"].values().associateBy { it["id"].asString() }

    private fun feed(token: String, groupId: String) = http.get("/groups/$groupId/activity", token).body["items"].values().toList()

    @Test
    fun aSeriesAndItsFirstExpenseAreStoredWithTheSchedule() {
        val s = setup()
        val r = uuid()
        val x0 = uuid()
        val template = rent(s.a, s.b)
        val batch = arrayOf(seriesCreated(r, template, "2031-01-31"), firstOf(r, template, "2031-01-31", x0))
        val first = ok(push(s.anna, s.id, *batch)).body
        // a retry with the same clientIds stores nothing and answers the same seqs
        assertEquals(SharedJson.canon(first), SharedJson.canon(ok(push(s.anna, s.id, *batch)).body))

        // snapshot: the series as sent, no scheduler columns; the expense carries its series and number
        val series = recurrences(s.ben, s.id).getValue(r)
        assertEquals(setOf("id", "frequency", "startDate", "timeZone", "template", "deleted", "remindDaysBefore"), series.propertyNames().toSet())
        assertTrue(series["remindDaysBefore"].isNull, "Phase 10: no reminder unless the series asks for one")
        assertEquals("monthly", series["frequency"].asString())
        assertEquals("2031-01-31", series["startDate"].asString())
        assertEquals("+02:00", series["timeZone"].asString())
        assertFalse(series["deleted"].asBoolean())
        assertEquals(SharedJson.canon(template), SharedJson.canon(series["template"]))
        val x = expenses(s.ben, s.id).getValue(x0)
        assertEquals(r, x["recurrenceId"].asString())
        assertEquals(0, x["occurrence"].asInt())
        assertEquals(Triple(r, 0, myId(s.anna)), expenseColumns(x0))

        // the first repeat is the next one on or after the creation day: 28 Feb (clamped) at 09:00 +02:00
        val row = row(r)!!
        assertEquals(1, row.n)
        assertEquals(Instant.parse("2031-02-28T07:00:00Z"), row.dueAt)
        assertEquals(myId(s.anna), row.createdBy)
        assertFalse(row.stopped)

        // pulled unchanged; Ben's feed has both, the expense with its series
        val events = pulled(s.ben, s.id).takeLast(2)
        assertEquals(listOf("recurrence.created", "expense.created"), events.map { it["type"].asString() })
        assertEquals(SharedJson.canon(template), SharedJson.canon(events[0]["payload"]["template"]))
        val items = feed(s.ben, s.id)
        assertEquals(listOf("expense_added", "recurrence_created"), items.take(2).map { it["kind"].asString() })
        assertEquals(r, items[0]["recurrenceId"].asString())
        assertTrue(items[0]["frequency"].isNull)
        assertEquals("monthly", items[1]["frequency"].asString())
        assertEquals(r, items[1]["recurrenceId"].asString())
        assertEquals(120000, items[1]["amount"].asLong())
        assertTrue(items[1]["myDelta"].isNull)

        // a second create with the same id (new clientId) keeps the first series
        ok(push(s.anna, s.id, seriesCreated(r, rent(s.a, s.b, amount = 99000), "2031-05-05", frequency = "weekly")))
        assertEquals(SharedJson.canon(template), SharedJson.canon(recurrences(s.anna, s.id).getValue(r)["template"]))
        assertEquals("monthly", recurrences(s.anna, s.id).getValue(r)["frequency"].asString())
        assertEquals(Instant.parse("2031-02-28T07:00:00Z"), row(r)!!.dueAt)
        assertEquals("recurrence_created", feed(s.ben, s.id)[1]["kind"].asString(), "the repeated create is hidden (rule 1)")
    }

    @Test
    fun aRepeatIsAddedAtNineLocalByEvensies() {
        val s = setup()
        val r = uuid()
        val template = rent(s.a, s.b)
        ok(push(s.anna, s.id, seriesCreated(r, template, "2031-03-03", timeZone = "Europe/Rome"), firstOf(r, template, "2031-03-03")))
        val due = Instant.parse("2031-04-03T07:00:00Z") // 09:00 in Rome, summer time
        assertEquals(due, row(r)!!.dueAt)
        val seq = latestSeq(s.anna, s.id)
        val annaUnread = http.get("/activity/unread", s.anna).body["total"].asInt()

        assertEquals(0, scheduler.runDue(due.minusSeconds(60)))
        assertEquals(seq, latestSeq(s.anna, s.id))

        assertEquals(1, scheduler.runDue(due))
        val repeat = repeats(s.ben, s.id, r).single()
        val id = derivedId(r, 1)
        assertEquals(id, repeat["clientId"].asString())
        assertEquals(id, repeat["payload"]["expenseId"].asString())
        assertEquals(due, Instant.parse(repeat["createdAt"].asString()))
        val p = repeat["payload"]
        assertEquals("2031-04-03", p["date"].asString())
        assertEquals(1, p["occurrence"].asInt())
        for (k in template.keys) assertEquals(SharedJson.canon(template[k]), SharedJson.canon(p[k]), k)

        val x = expenses(s.ben, s.id).getValue(id)
        assertEquals(r, x["recurrenceId"].asString())
        assertEquals(1, x["occurrence"].asInt())
        assertEquals("2031-04-03", x["date"].asString())
        assertEquals(Triple(r, 1, null), expenseColumns(id), "created_by is NULL for Evensies")
        assertTrue(
            jdbc.sql("SELECT actor_user_id IS NULL FROM events WHERE group_id = :g AND client_id = :c").param("g", UUID.fromString(s.id))
                .param("c", UUID.fromString(id)).query(Boolean::class.java).single(),
            "actor_user_id is NULL",
        )
        assertEquals(2, row(r)!!.n)
        assertEquals(Instant.parse("2031-05-03T07:00:00Z"), row(r)!!.dueAt)

        // the feed: added by Evensies (no actor), with the series' frequency; it counts as unread for the creator too
        val item = feed(s.ben, s.id)[0]
        assertEquals("expense_repeated", item["kind"].asString())
        assertTrue(item["actorMemberId"].isNull)
        assertEquals("monthly", item["frequency"].asString())
        assertEquals(r, item["recurrenceId"].asString())
        assertEquals(-60000, item["myDelta"].asLong())
        assertEquals(annaUnread + 1, http.get("/activity/unread", s.anna).body["total"].asInt())
    }

    @Test
    fun eachRepeatIsStoredOnceAcrossRetriesAndConcurrentRuns() {
        val s = setup()
        val r = uuid()
        ok(push(s.anna, s.id, seriesCreated(r, rent(s.a, s.b), "2031-05-05", frequency = "weekly", timeZone = "+00:00")))
        val second = Instant.parse("2031-05-19T09:00:00Z")

        val pool = Executors.newFixedThreadPool(2)
        val runs = pool.invokeAll(List(2) { Callable { scheduler.runDue(second) } }).map { it.get() }
        pool.shutdown()
        assertEquals(2, runs.sum(), "two repeats between both runs")
        assertEquals(listOf(1, 2), repeats(s.anna, s.id, r).map { it["payload"]["occurrence"].asInt() })
        assertEquals(0, scheduler.runDue(second))

        // a row that did not advance (as if its update were lost) meets the derived clientId: nothing new, it moves on
        jdbc.sql("UPDATE recurrences SET next_occurrence = 2, next_due_at = :due WHERE id = :id")
            .param("due", second.atOffset(ZoneOffset.UTC)).param("id", UUID.fromString(r)).update()
        val seq = latestSeq(s.anna, s.id)
        assertEquals(0, scheduler.runDue(second))
        assertEquals(seq, latestSeq(s.anna, s.id))
        assertEquals(3, row(r)!!.n)
        assertEquals(2, repeats(s.anna, s.id, r).size)
    }

    @Test
    fun missedRepeatsAreCaughtUpInOrder() {
        val s = setup()
        val r = uuid()
        ok(push(s.anna, s.id, seriesCreated(r, rent(s.a, s.b), "2031-06-02", frequency = "weekly", timeZone = "+00:00")))
        assertEquals(3, scheduler.runDue(Instant.parse("2031-06-23T09:00:00Z")))
        val got = repeats(s.anna, s.id, r)
        assertEquals(listOf(1, 2, 3), got.map { it["payload"]["occurrence"].asInt() })
        assertEquals(listOf("2031-06-09", "2031-06-16", "2031-06-23"), got.map { it["payload"]["date"].asString() })
        assertEquals(got.map { it["seq"].asLong() }.sorted(), got.map { it["seq"].asLong() })
        assertEquals(4, row(r)!!.n)
    }

    @Test
    fun monthlyFromThe31stClampsAndComesBack() {
        val s = setup()
        val r = uuid()
        ok(push(s.anna, s.id, seriesCreated(r, rent(s.a, s.b), "2031-01-31", timeZone = "+00:00")))
        assertEquals(2, scheduler.runDue(Instant.parse("2031-03-31T09:00:00Z")))
        assertEquals(listOf("2031-02-28", "2031-03-31"), repeats(s.anna, s.id, r).map { it["payload"]["date"].asString() })
    }

    @Test
    fun theEasternmostZonePostsFirstOnTheSameDate() {
        val s = setup()
        val east = uuid()
        val west = uuid()
        ok(push(s.anna, s.id, seriesCreated(east, rent(s.a, s.b), "2031-02-03", timeZone = "+13:00"), seriesCreated(west, rent(s.a, s.b), "2031-02-03", timeZone = "-10:00")))
        assertEquals(Instant.parse("2031-03-02T20:00:00Z"), row(east)!!.dueAt)
        assertEquals(Instant.parse("2031-03-03T19:00:00Z"), row(west)!!.dueAt)
        assertEquals(1, scheduler.runDue(Instant.parse("2031-03-03T00:00:00Z")))
        assertEquals(1, repeats(s.anna, s.id, east).size)
        assertEquals(0, repeats(s.anna, s.id, west).size)
        assertEquals(1, scheduler.runDue(Instant.parse("2031-03-03T19:00:00Z")))
        assertEquals("2031-03-03", repeats(s.anna, s.id, west).single()["payload"]["date"].asString())
    }

    @Test
    fun aTemplateEditChangesLaterRepeatsOnly() {
        val s = setup()
        val r = uuid()
        val x0 = uuid()
        val template = rent(s.a, s.b)
        ok(push(s.anna, s.id, seriesCreated(r, template, "2031-07-10", timeZone = "+00:00"), firstOf(r, template, "2031-07-10", x0)))
        assertEquals(1, scheduler.runDue(Instant.parse("2031-08-10T09:00:00Z")))

        // Ben edits the future: all six money fields, as the app sends them
        val money = mapOf(
            "amount" to 130000L, "paidBy" to s.a, "payers" to lines(mapOf(s.a to 130000L)), "refund" to false,
            "split" to mapOf("mode" to "equal"), "shares" to lines(mapOf(s.a to 65000L, s.b to 65000L)),
        )
        ok(push(s.ben, s.id, seriesUpdated(r, money)))
        assertEquals(130000, recurrences(s.anna, s.id).getValue(r)["template"]["amount"].asLong())
        assertEquals(1, scheduler.runDue(Instant.parse("2031-09-10T09:00:00Z")))

        val amounts = repeats(s.anna, s.id, r).map { it["payload"]["amount"].asLong() }
        assertEquals(listOf(120000L, 130000L), amounts)
        val all = expenses(s.anna, s.id)
        assertEquals(120000, all.getValue(x0)["amount"].asLong(), "the first expense is untouched")
        assertEquals(120000, all.getValue(derivedId(r, 1))["amount"].asLong(), "an added repeat is untouched")
        assertEquals(130000, all.getValue(derivedId(r, 2))["amount"].asLong())

        // Anna's feed: Ben changed future “Rent”, the change listed like an expense edit
        val item = feed(s.anna, s.id).first { it["kind"].asString() == "recurrence_updated" }
        assertEquals(s.b, item["actorMemberId"].asString())
        assertEquals(listOf("amount", "shares"), item["changes"].values().map { it["field"].asString() })
        assertEquals(120000, item["changes"][0]["from"].asLong())
        assertEquals(130000, item["amount"].asLong())

        // the merge is key by key without rule 10: an amount alone leaves the payers behind
        assertError(400, "PAYERS_SUM_MISMATCH", push(s.ben, s.id, seriesUpdated(r, mapOf("amount" to 140000L))))
        // a change with no expense field (here the same values again) is hidden
        val before = feed(s.anna, s.id).size
        ok(push(s.ben, s.id, seriesUpdated(r, mapOf("description" to "Rent"))))
        assertEquals(before, feed(s.anna, s.id).size)
    }

    @Test
    fun aStoppedSeriesAddsNothingAndIgnoresLaterEvents() {
        val s = setup()
        val r = uuid()
        val template = rent(s.a, s.b)
        ok(push(s.anna, s.id, seriesCreated(r, template, "2031-08-01", timeZone = "+00:00")))
        ok(push(s.ben, s.id, seriesDeleted(r)))
        assertTrue(recurrences(s.anna, s.id).getValue(r)["deleted"].asBoolean())
        assertTrue(row(r)!!.stopped)
        assertEquals(0, scheduler.runDue(Instant.parse("2031-12-01T09:00:00Z")))
        assertEquals(0, repeats(s.anna, s.id, r).size)
        val feedSize = feed(s.anna, s.id).size
        assertEquals("recurrence_deleted", feed(s.anna, s.id)[0]["kind"].asString())

        // accepted and ignored: an update (even one that would fail as an expense), a second stop, a re-create
        ok(push(s.ben, s.id, seriesUpdated(r, mapOf("description" to "Rent + parking"))))
        ok(push(s.ben, s.id, seriesUpdated(r, mapOf("amount" to 1L))))
        ok(push(s.ben, s.id, seriesDeleted(r)))
        ok(push(s.anna, s.id, seriesCreated(r, template, "2031-08-01")))
        val series = recurrences(s.anna, s.id).getValue(r)
        assertEquals(SharedJson.canon(template), SharedJson.canon(series["template"]))
        assertTrue(series["deleted"].asBoolean(), "there is no restore")
        assertTrue(row(r)!!.stopped)
        assertEquals(feedSize, feed(s.anna, s.id).size, "no-ops are hidden")

        // an unknown series: stop and update are accepted and ignored too (rule 4)
        ok(push(s.ben, s.id, seriesDeleted(uuid()), seriesUpdated(uuid(), mapOf("description" to "x"))))
        assertEquals(1, recurrences(s.anna, s.id).size)
    }

    @Test
    fun offlineSeriesCatchUpWithinThirtyDays() {
        val s = setup()
        val today = LocalDate.now(ZoneOffset.UTC)
        val now = Instant.now()

        // made 3 days ago, synced now: the repeat due 2 days ago is added on the next run
        val recent = uuid()
        ok(push(s.anna, s.id, seriesCreated(recent, rent(s.a, s.b), today.minusDays(9).toString(), frequency = "weekly", timeZone = "+00:00", createdAt = now.minusSeconds(3 * 86400))))
        // made 200 days ago: only the last 30 days count, so it can't add a burst
        val old = uuid()
        val start = today.minusDays(200)
        ok(push(s.anna, s.id, seriesCreated(old, rent(s.a, s.b), start.toString(), frequency = "weekly", timeZone = "+00:00", createdAt = now.minusSeconds(200 * 86400))))

        scheduler.runDue(Instant.now()) // the real tick may have added some already: each repeat is stored once either way
        val got = repeats(s.anna, s.id, recent)
        assertEquals(listOf(1), got.map { it["payload"]["occurrence"].asInt() })
        assertEquals(today.minusDays(2).toString(), got.single()["payload"]["date"].asString())

        val (first, firstDate) = Schedule.firstOnOrAfter("weekly", start, today.minusDays(30))
        val caught = repeats(s.anna, s.id, old).map { it["payload"]["occurrence"].asInt() }
        assertEquals(first, caught.first())
        assertEquals((first until first + caught.size).toList(), caught, "in order, none skipped")
        assertTrue(firstDate >= today.minusDays(30) && caught.size in 4..5, "$firstDate, ${caught.size} repeats")
        assertTrue(row(old)!!.dueAt > Instant.now())
    }

    @Test
    fun validationRejectsTheWholeBatch() {
        val s = setup()
        val good = rent(s.a, s.b)
        fun created(vararg over: Pair<String, Any?>) = event(
            "recurrence.created",
            mapOf("recurrenceId" to uuid(), "frequency" to "monthly", "startDate" to "2031-01-01", "timeZone" to "+01:00", "template" to good) + over,
        )
        fun bad(code: String, vararg events: Map<String, Any?>) = assertError(if (code == "LIMIT_EXCEEDED") 409 else 400, code, push(s.anna, s.id, *events))

        // shape of recurrence.created
        bad("VALIDATION", created("recurrenceId" to "not-a-uuid"))
        bad("VALIDATION", created("recurrenceId" to uuid().uppercase()))
        bad("VALIDATION", created("frequency" to "daily"))
        bad("VALIDATION", created("frequency" to null))
        bad("VALIDATION", created("startDate" to "2031-02-30"))
        bad("VALIDATION", created("startDate" to "+10000-01-01"))
        bad("VALIDATION", created("startDate" to 20310101))
        bad("VALIDATION", created("timeZone" to "Mars/Olympus"))
        bad("VALIDATION", created("timeZone" to ""))
        bad("VALIDATION", created("timeZone" to "+01:00" + " ".repeat(60)))
        bad("VALIDATION", created("timeZone" to 1))
        bad("VALIDATION", created("template" to "Rent"))
        bad("VALIDATION", created("template" to null))
        for (k in EventValidator.SCHEDULE_KEYS) bad("VALIDATION", created("template" to good + (k to "x")))
        // the template must pass as an expense
        bad("SUM_MISMATCH", created("template" to good + ("shares" to lines(mapOf(s.a to 1L)))))
        bad("PAYERS_SUM_MISMATCH", created("template" to good + ("payers" to lines(mapOf(s.a to 1L)))))
        bad("NEGATIVE_AMOUNT", created("template" to good + ("payers" to lines(mapOf(s.a to 130000L, s.b to -10000L)))))
        bad("UNKNOWN_MEMBER", created("template" to good + ("shares" to lines(mapOf(s.a to 60000L, uuid() to 60000L)))))
        bad("UNKNOWN_CURRENCY", created("template" to good + ("currency" to "XXX")))
        bad("VALIDATION", created("template" to good - "amount"))
        bad("VALIDATION", created("template" to good + ("description" to " ")))
        bad("VALIDATION", created("template" to good + ("description" to "x".repeat(201))))
        bad("VALIDATION", created("template" to good + ("deleted" to true)))
        bad("VALIDATION", created("template" to good + ("split" to mapOf("mode" to "itemized"))))
        // updates: types always, the merged template only for a live series
        val r = uuid()
        ok(push(s.anna, s.id, seriesCreated(r, good, "2031-01-01")))
        bad("VALIDATION", event("recurrence.updated", mapOf("recurrenceId" to r, "fields" to "x")))
        bad("VALIDATION", event("recurrence.updated", mapOf("recurrenceId" to "R1", "fields" to emptyMap<String, Any>())))
        for (k in EventValidator.SCHEDULE_KEYS) bad("VALIDATION", seriesUpdated(r, mapOf(k to "x")))
        bad("VALIDATION", seriesUpdated(uuid(), mapOf("amount" to "12"))) // types are checked for an unknown series too
        bad("SUM_MISMATCH", seriesUpdated(r, mapOf("shares" to lines(mapOf(s.a to 1L)))))
        bad("VALIDATION", event("recurrence.deleted", mapOf("recurrenceId" to 7)))
        // series fields on expenses
        bad("VALIDATION", firstOf(r, good, "2031-01-01", occurrence = null))
        bad("VALIDATION", firstOf(null, good, "2031-01-01", occurrence = 0))
        bad("VALIDATION", firstOf(r, good, "2031-01-01", occurrence = 1)) // only Evensies adds later repeats
        bad("VALIDATION", firstOf(r, good, "2031-01-01", occurrence = -1))
        bad("VALIDATION", firstOf(r, good, "2031-01-01", occurrence = 0.5))
        bad("VALIDATION", firstOf(r, good, "2031-01-01", occurrence = "0"))
        bad("VALIDATION", firstOf(r, good, "2031-01-01", occurrence = 2147483648L))
        val x = uuid()
        ok(push(s.anna, s.id, firstOf(r, good, "2031-01-01", x)))
        bad("VALIDATION", expenseUpdated(x, "recurrenceId" to r)) // the two keys travel together
        bad("VALIDATION", expenseUpdated(x, "occurrence" to 0))
        bad("VALIDATION", expenseUpdated(x, "recurrenceId" to r, "occurrence" to null))

        // a failing event rejects the whole batch: nothing of it is stored
        val seq = latestSeq(s.anna, s.id)
        val r2 = uuid()
        bad("SUM_MISMATCH", seriesCreated(r2, good, "2031-01-01"), firstOf(r2, good, "2031-01-01"), created("template" to good + ("shares" to lines(mapOf(s.a to 1L)))))
        assertEquals(seq, latestSeq(s.anna, s.id))
        assertNull(row(r2))
        assertEquals(setOf(r), recurrences(s.anna, s.id).keys)
    }

    /** Old payloads (before Phase 8) read as no series; an old client's edit keeps the tag. */
    @Test
    fun oldEventsAndOldClientsKeepWorking() {
        val s = setup()
        val legacy = uuid()
        ok(push(s.anna, s.id, expenseCreated(s.a, 3000, mapOf(s.a to 1500, s.b to 1500), expenseId = legacy)))
        val x = expenses(s.anna, s.id).getValue(legacy)
        assertTrue(x["recurrenceId"].isNull && x["occurrence"].isNull)
        assertEquals(Triple(null, null, myId(s.anna)), expenseColumns(legacy))

        val r = uuid()
        val x0 = uuid()
        ok(push(s.anna, s.id, seriesCreated(r, rent(s.a, s.b), "2031-01-01"), firstOf(r, rent(s.a, s.b), "2031-01-01", x0)))
        ok(push(s.ben, s.id, expenseUpdated(x0, "description" to "Rent (Jan)")))
        assertEquals(r, expenses(s.anna, s.id).getValue(x0)["recurrenceId"].asString())
        assertEquals(Triple(r, 0, myId(s.anna)), expenseColumns(x0))
        // snapshot and pull of the legacy expense are unchanged otherwise
        assertFalse(pulled(s.anna, s.id).first { it["payload"]["expenseId"]?.asString() == legacy }["payload"].has("recurrenceId"))
    }

    @Test
    fun seriesFieldsOnExpensesAreNormalizedAndPersisted() {
        val s = setup()
        val r1 = uuid()
        val x0 = uuid()
        val template = rent(s.a, s.b)
        ok(push(s.anna, s.id, seriesCreated(r1, template, "2031-01-05", frequency = "weekly"), firstOf(r1, template, "2031-01-05", x0)))

        // an unknown series (e.g. rejected earlier while offline) is dropped from the stored and pulled payload: no 400
        val lost = uuid()
        ok(push(s.anna, s.id, firstOf(uuid(), template, "2031-01-06", lost)))
        assertEquals(Triple(null, null, myId(s.anna)), expenseColumns(lost))
        val pulledLost = pulled(s.ben, s.id).last()["payload"]
        assertFalse(pulledLost.has("recurrenceId") || pulledLost.has("occurrence"), pulledLost.toString())
        ok(push(s.anna, s.id, expenseUpdated(x0, "recurrenceId" to uuid(), "occurrence" to 0)))
        assertEquals(Triple(r1, 0, myId(s.anna)), expenseColumns(x0), "an unknown retag keeps the current series")

        // a stopped series is fine on an expense
        ok(push(s.anna, s.id, seriesDeleted(r1)))
        val late = uuid()
        ok(push(s.ben, s.id, firstOf(r1, template, "2031-01-07", late)))
        assertEquals(r1, expenseColumns(late).first)

        // a schedule change: a new series, then the expense moves to it; the retag alone is hidden in the feed
        val r2 = uuid()
        ok(push(s.anna, s.id, seriesCreated(r2, template, "2031-01-12", frequency = "biweekly")))
        val feedBefore = feed(s.ben, s.id).size
        ok(push(s.anna, s.id, expenseUpdated(x0, "recurrenceId" to r2, "occurrence" to 0)))
        assertEquals(Triple(r2, 0, myId(s.anna)), expenseColumns(x0))
        assertEquals(r2, expenses(s.ben, s.id).getValue(x0)["recurrenceId"].asString())
        assertEquals(feedBefore, feed(s.ben, s.id).size, "hiding rule 7")
        // with a real change it shows, tagged with the new series
        ok(push(s.anna, s.id, expenseUpdated(x0, "date" to "2031-01-12")))
        assertEquals(r2, feed(s.ben, s.id)[0]["recurrenceId"].asString())
        // detached: both null
        ok(push(s.anna, s.id, expenseUpdated(x0, "recurrenceId" to null, "occurrence" to null)))
        assertEquals(Triple(null, null, myId(s.anna)), expenseColumns(x0))
        // a deleted expense ignores a retag (rule 3)
        ok(push(s.anna, s.id, event("expense.deleted", mapOf("expenseId" to late)), expenseUpdated(late, "recurrenceId" to r2, "occurrence" to 0)))
        assertEquals(r1, expenseColumns(late).first)
    }

    @Test
    fun membersOnlyAndIdsStayInTheirGroup() {
        val s = setup()
        val r = uuid()
        val template = rent(s.a, s.b)
        ok(push(s.anna, s.id, seriesCreated(r, template, "2031-01-01")))

        // a stranger: 403 for push, pull and snapshot; an unknown group 404
        val stranger = login("Rec-stranger-${tag()}")
        assertError(403, "FORBIDDEN", push(stranger, s.id, seriesDeleted(r)))
        assertError(403, "FORBIDDEN", push(stranger, s.id, seriesCreated(uuid(), template, "2031-01-01")))
        assertError(403, "FORBIDDEN", http.get("/groups/${s.id}/snapshot", stranger))
        assertError(403, "FORBIDDEN", http.get("/groups/${s.id}/events?after=0", stranger))
        assertError(404, "NOT_FOUND", push(s.anna, uuid(), seriesCreated(uuid(), template, "2031-01-01")))
        assertFalse(row(r)!!.stopped)

        // Anna's other group can't take, edit, stop or tag with this group's series
        val other = createGroup(s.anna, name = "Other")
        val o = other["id"].asString()
        val me = other["myMemberId"].asString()
        val own = mapOf(
            "description" to "Gym", "amount" to 4000L, "currency" to "EUR", "fxRateToDefault" to null, "paidBy" to me,
            "category" to null, "shares" to lines(mapOf(me to 4000L)),
        )
        assertError(400, "VALIDATION", push(s.anna, o, seriesCreated(r, own, "2031-01-01")))
        assertEquals(s.id, row(r)!!.groupId)
        assertEquals(0, recurrences(s.anna, o).size)
        ok(push(s.anna, o, seriesUpdated(r, mapOf("description" to "Hijacked")), seriesDeleted(r)))
        assertEquals("Rent", recurrences(s.anna, s.id).getValue(r)["template"]["description"].asString())
        assertFalse(row(r)!!.stopped)
        val x = uuid()
        ok(push(s.anna, o, firstOf(r, own, "2031-01-01", x)))
        assertEquals(Triple(null, null, myId(s.anna)), expenseColumns(x), "another group's series is dropped like an unknown one")
        assertEquals(0, scheduler.runDue(Instant.parse("2030-01-01T00:00:00Z")))
    }

    @Test
    fun atMostOneHundredLiveSeriesPerGroup() {
        val s = setup()
        val ids = List(EventValidator.MAX_RECURRENCES) { uuid() }
        ok(push(s.anna, s.id, *ids.map { seriesCreated(it, rent(s.a, s.b), "2031-01-01") }.toTypedArray()))
        assertError(409, "LIMIT_EXCEEDED", push(s.anna, s.id, seriesCreated(uuid(), rent(s.a, s.b), "2031-01-01")))
        ok(push(s.anna, s.id, seriesCreated(ids[0], rent(s.a, s.b), "2031-01-01"))) // a known id is not a new series
        ok(push(s.anna, s.id, seriesDeleted(ids[0])))
        ok(push(s.anna, s.id, seriesCreated(uuid(), rent(s.a, s.b), "2031-01-01")))
        assertEquals(EventValidator.MAX_RECURRENCES + 1, recurrences(s.anna, s.id).size)
    }

    @Test
    fun exportsCarryTheSeries() {
        val s = setup()
        val r = uuid()
        val x0 = uuid()
        ok(push(s.anna, s.id, seriesCreated(r, rent(s.a, s.b), "2031-01-01"), firstOf(r, rent(s.a, s.b), "2031-01-01", x0)))
        val json = http.get("/groups/${s.id}/export?format=json", s.ben)
        assertEquals(200, json.status)
        assertEquals(r, json.body["recurrences"][0]["id"].asString())
        assertEquals("monthly", json.body["recurrences"][0]["frequency"].asString())
        val x = json.body["expenses"].values().first { it["id"].asString() == x0 }
        assertEquals(r, x["recurrenceId"].asString())
        assertEquals(0, x["occurrence"].asInt())
        val csv = http.get("/groups/${s.id}/export?format=csv", s.ben)
        assertEquals(200, csv.status)
        assertTrue(csv.text.startsWith("\"date\",\"description\",\"category\",\"amount\",\"currency\",\"fxRateToDefault\",\"paidBy\","), csv.text)
        assertTrue(csv.text.contains("\"2031-01-01\",\"Rent\",\"Rent\",\"1200.00\",\"EUR\",\"\",\"Me\",\"600.00\",\"600.00\""), csv.text)
    }

    @Test
    fun aRepeatIsPushedToEveryoneIncludingTheCreator() {
        val s = setup()
        val annaDevice = device(s.anna)
        val benDevice = device(s.ben)
        val r = uuid()
        val template = rent(s.a, s.b)
        ok(push(s.anna, s.id, seriesCreated(r, template, "2031-02-10", timeZone = "+00:00"), firstOf(r, template, "2031-02-10")))
        awaitUntil("Ben's push about the new series") { capture.to(benDevice).any { it.body != null } }
        assertEquals("Anna added “Rent” · €1,200.00 · you owe €600.00".replace("Anna", "Me"), capture.to(benDevice).first { it.body != null }.body)
        assertTrue(capture.to(annaDevice).isEmpty(), "her own change")

        assertEquals(1, scheduler.runDue(Instant.parse("2031-03-10T09:00:00Z")))
        awaitUntil("Anna's push about the repeat") { capture.to(annaDevice).any { it.body != null } }
        assertEquals("“Rent” · €1,200.00 was added (repeats monthly) · you lent €600.00", capture.to(annaDevice).first { it.body != null }.body)
        awaitUntil("Ben's push about the repeat") { capture.to(benDevice).count { it.body != null } >= 2 }
        assertEquals("“Rent” · €1,200.00 was added (repeats monthly) · you owe €600.00", capture.to(benDevice).last { it.body != null }.body)
        assertEquals("sync", capture.to(annaDevice).last().data["type"])

        // series changes and repeats are in the expenses push category
        for (kind in listOf("recurrence_created", "recurrence_updated", "recurrence_deleted", "expense_repeated")) {
            assertFalse(NotificationPrefs(expenses = false).allows(kind), kind)
            assertTrue(NotificationPrefs(comments = false, members = false).allows(kind), kind)
        }
    }

    @Test
    fun aForeignTemplateGetsTheRateOfItsDay() {
        jdbc.sql("DELETE FROM fx_days").update()
        FxStub.reset()
        fxService.failedAt.clear()
        val s = setup()
        fun yen(rate: Any?) = rent(s.a, s.b, amount = 10000, extra = mapOf("currency" to "JPY", "fxRateToDefault" to rate))
        val withRate = uuid()
        val notConverted = uuid()
        val noRate = uuid()
        ok(
            push(
                s.anna, s.id, seriesCreated(withRate, yen(0.006), "2031-04-01", timeZone = "+00:00"),
                seriesCreated(notConverted, yen(0), "2031-04-01", timeZone = "+00:00"), seriesCreated(noRate, yen(null), "2031-04-01", timeZone = "+00:00"),
            )
        )
        assertEquals(3, scheduler.runDue(Instant.parse("2031-05-01T09:00:00Z")))
        // a future day is asked as today; the stub's JPY is 177.51 per EUR
        assertEquals(0.00563349, repeats(s.anna, s.id, withRate).single()["payload"]["fxRateToDefault"].asDouble())
        assertEquals(0.0, repeats(s.anna, s.id, notConverted).single()["payload"]["fxRateToDefault"].asDouble())
        assertTrue(repeats(s.anna, s.id, noRate).single()["payload"]["fxRateToDefault"].isNull)
        assertEquals(0.006, recurrences(s.anna, s.id).getValue(withRate)["template"]["fxRateToDefault"].asDouble(), "the template keeps its rate")

        // no rates available: the template's rate is kept
        jdbc.sql("DELETE FROM fx_days").update()
        fxService.failedAt.clear()
        FxStub.respond = { 500 to "" }
        try {
            assertEquals(3, scheduler.runDue(Instant.parse("2031-06-01T09:00:00Z")))
            assertEquals(0.006, repeats(s.anna, s.id, withRate).last()["payload"]["fxRateToDefault"].asDouble())
        } finally {
            FxStub.reset()
            fxService.failedAt.clear()
        }
    }

    @Test
    fun aFailingRepeatIsRetriedInAnHour() {
        val s = setup()
        val r = uuid()
        ok(push(s.anna, s.id, seriesCreated(r, rent(s.a, s.b), "2031-09-01", timeZone = "+00:00")))
        val good = jdbc.sql("SELECT template::text FROM recurrences WHERE id = :id").param("id", UUID.fromString(r)).query(String::class.java).single()
        // only a bug can make a stored template invalid; simulate one
        jdbc.sql("UPDATE recurrences SET template = '{\"description\": \"Rent\"}' WHERE id = :id").param("id", UUID.fromString(r)).update()
        val due = Instant.parse("2031-10-01T09:00:00Z")
        assertEquals(0, scheduler.runDue(due))
        assertEquals(1, row(r)!!.n)
        assertEquals(due.plusSeconds(3600), row(r)!!.dueAt)
        assertEquals(0, repeats(s.anna, s.id, r).size)

        jdbc.sql("UPDATE recurrences SET template = CAST(:t AS jsonb) WHERE id = :id").param("t", good).param("id", UUID.fromString(r)).update()
        assertEquals(0, scheduler.runDue(due.plusSeconds(1800)))
        assertEquals(1, scheduler.runDue(due.plusSeconds(3600)))
        assertEquals("2031-10-01", repeats(s.anna, s.id, r).single()["payload"]["date"].asString())
    }

    @Test
    fun aStaleRetryNeverPushesBackARepeatAnotherInstanceAdded() {
        val s = setup()
        val r = uuid()
        ok(push(s.anna, s.id, seriesCreated(r, rent(s.a, s.b), "2031-11-03", frequency = "weekly", timeZone = "+00:00")))
        val first = Instant.parse("2031-11-10T09:00:00Z")
        // instance B adds repeat 1 and schedules repeat 2 for next week
        assertEquals(1, scheduler.runDue(first))
        val next = Instant.parse("2031-11-17T09:00:00Z")
        assertEquals(next, row(r)!!.dueAt)
        // instance A, which read repeat 1 before B advanced, fails (lock timeout) and retries what it saw
        scheduler.retryLater(UUID.fromString(r), 1, first)
        assertEquals(2, row(r)!!.n)
        assertEquals(next, row(r)!!.dueAt, "repeat 2 stays on its date")
        assertEquals(0, scheduler.runDue(first.plusSeconds(3600)))
    }

    @Test
    fun nobodyCanTakeAFutureRepeatsIdFirst() {
        val s = setup()
        val r = uuid()
        ok(push(s.anna, s.id, seriesCreated(r, rent(s.a, s.b), "2031-12-01", timeZone = "+00:00")))
        // the id a series id alone would give: a former member keeps the series id from an old snapshot
        val guess = UUID.nameUUIDFromBytes("evensies:recurrence:$r:1".toByteArray()).toString()
        val other = setup()
        ok(push(other.anna, other.id, event("expense.created", rent(other.a, other.b) + mapOf("expenseId" to guess, "date" to "2031-12-01"))))
        ok(push(s.ben, s.id, event("expense.created", rent(s.a, s.b) + mapOf("expenseId" to uuid(), "date" to "2031-12-01"), clientId = guess)))

        assertEquals(1, scheduler.runDue(Instant.parse("2032-01-01T09:00:00Z")))
        val repeat = repeats(s.anna, s.id, r).single()
        assertEquals(derivedId(r, 1), repeat["payload"]["expenseId"].asString())
        assertTrue(derivedId(r, 1) != guess)
        assertEquals(2, row(r)!!.n)
    }

    @Test
    fun friendGroupsRepeatToo() {
        val anna = login("Rec-friend-${tag()}")
        val friend = http.post("/friends", mapOf("id" to uuid(), "defaultCurrency" to "EUR", "name" to "Ben"), anna).body
        val id = friend["id"].asString()
        val a = friend["myMemberId"].asString()
        val b = snapshot(anna, id)["members"].values().map { it["id"].asString() }.first { it != a }
        val r = uuid()
        ok(push(anna, id, seriesCreated(r, rent(a, b), "2031-02-01", frequency = "yearly", timeZone = "+00:00")))
        assertEquals(1, scheduler.runDue(Instant.parse("2032-02-01T09:00:00Z")))
        val repeat = repeats(anna, id, r).single()["payload"]
        assertEquals("2032-02-01", repeat["date"].asString())
        val item = feed(anna, id)[0]
        assertEquals("expense_repeated", item["kind"].asString())
        assertEquals("yearly", item["frequency"].asString())
        assertNotNull(expenses(anna, id)[derivedId(r, 1)])
    }
}
