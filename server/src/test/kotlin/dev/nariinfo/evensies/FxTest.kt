package dev.nariinfo.evensies

import dev.nariinfo.evensies.config.AppProperties
import dev.nariinfo.evensies.fx.FxService
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import java.time.Instant
import java.time.LocalDate
import java.time.OffsetDateTime
import java.time.ZoneOffset
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** GET /fx and its `fx_days` cache (docs/API.md "Exchange rates") against [FxStub] as the rate source. */
class FxTest : IntegrationTestBase() {
    @Autowired
    private lateinit var jdbc: JdbcClient

    @Autowired
    private lateinit var fxService: FxService

    private val today get() = LocalDate.now(ZoneOffset.UTC)
    private val past = LocalDate.parse("2024-03-15")

    /** What the stub's table becomes: listed codes only, EUR forced to 1, the 0 rate dropped. */
    private fun kept(usd: Double = 1.1217) = SharedJson.canon(mapOf("EUR" to 1.0, "USD" to usd, "JPY" to 177.51, "KWD" to 0.34691))

    private fun fx(token: String, date: String? = null) = http.get(if (date == null) "/fx" else "/fx?date=$date", token)

    private fun insertRow(day: LocalDate, usd: Double, fetchedAt: OffsetDateTime) {
        jdbc.sql("INSERT INTO fx_days (day, rates, rate_date, fetched_at) VALUES (:d, CAST(:r AS jsonb), :d, :at)")
            .param("d", day).param("r", """{"EUR": 1, "USD": $usd}""").param("at", fetchedAt).update()
    }

    private fun rowCount(day: LocalDate) = jdbc.sql("SELECT count(*) FROM fx_days WHERE day = :d").param("d", day).query(Long::class.java).single()

    @BeforeEach
    fun clean() {
        FxStub.reset()
        jdbc.sql("DELETE FROM fx_days").update()
        fxService.failedAt.clear()
    }

    @Test
    fun aPastDayIsFetchedOnceAndStored() {
        val token = login("Fx-past")
        val res = fx(token, past.toString())
        assertEquals(200, res.status, res.text)
        assertEquals("2024-03-15", res.body["date"].asString(), "the latest per-quote date (JPY is a day older)")
        assertEquals("EUR", res.body["base"].asString())
        assertEquals(kept(), SharedJson.canon(res.body["rates"]), "XAU, CNH and the 0 rate are dropped; EUR is 1")
        assertEquals(listOf("2024-03-15"), FxStub.requests)
        assertEquals(1, rowCount(past))

        // final: fetched after the day's next day ended, so it is never asked again, however old the row gets
        jdbc.sql("UPDATE fx_days SET fetched_at = fetched_at - interval '7 hours'").update()
        FxStub.respond = { 500 to "" }
        val again = fx(token, past.toString())
        assertEquals(200, again.status)
        assertEquals(SharedJson.canon(res.body), SharedJson.canon(again.body))
        assertEquals(1, FxStub.requests.size)
    }

    @Test
    fun todayRefreshesAfterSixHoursAndAFutureDateMeansToday() {
        val token = login("Fx-today")
        val first = fx(token)
        assertEquals(200, first.status, first.text)
        assertEquals(today.toString(), first.body["date"].asString())
        assertEquals(kept(), SharedJson.canon(first.body["rates"]))
        assertEquals(listOf(today.toString()), FxStub.requests, "no date asks the source for today")

        FxStub.respond = { 200 to FxStub.table(it, usd = 1.2) }
        assertEquals(kept(), SharedJson.canon(fx(token).body["rates"]), "recent: served from the cache")
        assertEquals(kept(), SharedJson.canon(fx(token, "2999-01-01").body["rates"]), "a future date is today")
        assertEquals(today.toString(), fx(token, today.plusDays(1).toString()).body["date"].asString())
        assertEquals(1, FxStub.requests.size)

        jdbc.sql("UPDATE fx_days SET fetched_at = fetched_at - interval '7 hours' WHERE day = :d").param("d", today).update()
        assertEquals(kept(usd = 1.2), SharedJson.canon(fx(token).body["rates"]), "older than 6 h: asked again and replaced")
        assertEquals(2, FxStub.requests.size)
        assertEquals(kept(usd = 1.2), SharedJson.canon(fx(token).body["rates"]))
        assertEquals(2, FxStub.requests.size, "the replaced row is recent again")
        assertEquals(1, rowCount(today))
    }

    /** "Final" = fetched at or after D + 2 days 00:00 UTC; a row fetched on D itself may hold the day before's quotes. */
    @Test
    fun aRowFetchedBeforeTheDayEndedIsNotFinal() {
        val token = login("Fx-final")
        val early = today.minusDays(3)
        insertRow(early, 1.05, early.atTime(12, 0).atOffset(ZoneOffset.UTC))
        assertEquals(kept(), SharedJson.canon(fx(token, early.toString()).body["rates"]), "fetched on the day, 6 h old: asked again")
        assertEquals(listOf(early.toString()), FxStub.requests)

        val done = today.minusDays(4)
        insertRow(done, 1.05, done.plusDays(2).atStartOfDay().atOffset(ZoneOffset.UTC))
        assertEquals(SharedJson.canon(mapOf("EUR" to 1.0, "USD" to 1.05)), SharedJson.canon(fx(token, done.toString()).body["rates"]))
        assertEquals(1, FxStub.requests.size, "fetched exactly at D + 2 days: final")
    }

    @Test
    fun aFailingSourceFallsBackToTheStaleRowOfThatDayOnly() {
        val token = login("Fx-down")
        val day = today.minusDays(5)
        insertRow(day, 1.05, day.atTime(9, 0).atOffset(ZoneOffset.UTC))
        val stale = SharedJson.canon(mapOf("EUR" to 1.0, "USD" to 1.05))
        val failures = listOf(500 to "", 200 to "not json", 200 to "[]", 200 to """{"rates":{"USD":1.1}}""",
            200 to """[{"date":"$day","base":"EUR","quote":"XAU","rate":0.0003}]""", 404 to FxStub.table(day.toString()))
        for (failure in failures) {
            FxStub.respond = { failure }
            val res = fx(token, day.toString())
            assertEquals(200, res.status, "$failure: ${res.text}")
            assertEquals(stale, SharedJson.canon(res.body["rates"]), "$failure")
            assertEquals(day.toString(), res.body["date"].asString())
            fxService.failedAt.clear() // past the retry wait
        }
        assertEquals(failures.size, FxStub.requests.size, "a stale row is asked again once the wait is over")

        // nothing cached for that day: 503, even though another day's row exists, and nothing is stored
        FxStub.respond = { 500 to "" }
        val none = fx(token, day.minusDays(1).toString())
        assertEquals(503, none.status, none.text)
        assertEquals("FX_UNAVAILABLE", none.code())
        assertEquals(0, rowCount(day.minusDays(1)))

        // the source answers [] for days before 1999
        FxStub.reset()
        FxStub.respond = { 200 to "[]" }
        assertEquals("FX_UNAVAILABLE", fx(token, "1990-01-01").code())
    }

    /** A failed day is not asked again for 5 minutes (stale row or 503 meanwhile); other days still are. */
    @Test
    fun aFailedDayWaitsFiveMinutesBeforeAskingAgain() {
        val token = login("Fx-wait")
        val day = today.minusDays(8)
        insertRow(day, 1.05, day.atTime(9, 0).atOffset(ZoneOffset.UTC))
        val stale = SharedJson.canon(mapOf("EUR" to 1.0, "USD" to 1.05))
        val empty = today.minusDays(9)
        FxStub.respond = { 500 to "" }
        repeat(3) {
            assertEquals(stale, SharedJson.canon(fx(token, day.toString()).body["rates"]))
            assertEquals("FX_UNAVAILABLE", fx(token, empty.toString()).code())
            assertEquals("FX_UNAVAILABLE", fx(token, "1990-01-01").code())
        }
        assertEquals(listOf(day.toString(), empty.toString(), "1990-01-01"), FxStub.requests, "each failed day asked once")

        FxStub.reset()
        assertEquals(kept(), SharedJson.canon(fx(token, past.toString()).body["rates"]), "another day is still asked")
        assertEquals(stale, SharedJson.canon(fx(token, day.toString()).body["rates"]), "the source is back, but the wait is not over")
        assertEquals(listOf(past.toString()), FxStub.requests)

        fxService.failedAt[day] = Instant.now() - FxService.RETRY_AFTER
        assertEquals(kept(), SharedJson.canon(fx(token, day.toString()).body["rates"]), "5 minutes later: asked again and replaced")
        assertEquals(listOf(past.toString(), day.toString()), FxStub.requests)
    }

    @Test
    fun aSlowSourceTimesOutAfterFiveSeconds() {
        val token = login("Fx-slow")
        val day = today.minusDays(6)
        insertRow(day, 1.05, day.atTime(9, 0).atOffset(ZoneOffset.UTC))
        FxStub.delayMillis = 7000
        val started = System.currentTimeMillis()
        val res = fx(token, day.toString())
        val took = System.currentTimeMillis() - started
        assertEquals(200, res.status, res.text)
        assertEquals(SharedJson.canon(mapOf("EUR" to 1.0, "USD" to 1.05)), SharedJson.canon(res.body["rates"]))
        assertTrue(took in 4500..6900, "read timeout is 5 s, took $took ms")
    }

    @Test
    fun anEmptyUrlTurnsRatesOffWithoutReadingTheCache() {
        insertRow(today, 1.05, OffsetDateTime.now(ZoneOffset.UTC))
        for (url in listOf("", "  ")) {
            val off = FxService(jdbc, mapper, AppProperties(fx = AppProperties.Fx(url = url)))
            assertNull(off.rates(today), "a fresh cached row is not used either")
        }
        assertEquals(emptyList(), FxStub.requests)
    }

    @Test
    fun badDatesNoTokenAndTheRateLimit() {
        val token = login("Fx-limit")
        for (bad in listOf("2026-13-01", "2026-02-30", "20261010", "2026-1-5", "yesterday", "-0001-01-01")) {
            val res = fx(token, bad)
            assertEquals(400, res.status, "$bad: ${res.text}")
            assertEquals("VALIDATION", res.code(), bad)
        }
        assertEquals(401, http.get("/fx").status)
        assertEquals("UNAUTHORIZED", http.get("/fx?date=$past").code())
        assertEquals(emptyList(), FxStub.requests)

        // 30 per user, refilled at 0.5 per second; bad requests and cache hits count too
        val responses = ArrayList<Http.Resp>()
        while (responses.size < 40 && responses.none { it.status == 429 }) responses += fx(token, past.toString())
        assertEquals(List(24) { 200 }, responses.take(24).map { it.status }, "6 tokens went to the bad dates")
        assertEquals("RATE_LIMITED", responses.last().code(), responses.map { it.status }.toString())
        assertEquals(200, fx(login("Fx-other"), past.toString()).status, "the limit is per user")
        assertEquals(1, FxStub.requests.size)
    }
}
