package dev.nariinfo.evensies

import dev.nariinfo.evensies.fx.FxService
import dev.nariinfo.evensies.recurrence.Schedule
import org.junit.jupiter.api.DynamicTest
import org.junit.jupiter.api.DynamicTest.dynamicTest
import org.junit.jupiter.api.TestFactory
import java.time.Instant
import java.time.LocalDate
import kotlin.test.assertEquals

/** shared/recurrence-cases.json against recurrence/Schedule.kt and FxService.crossRate (same file as the app's recurrence_test.dart). */
class ScheduleTest {
    @TestFactory
    fun sharedRecurrenceCases(): List<DynamicTest> = SharedJson.load("recurrence-cases.json")["cases"].values().map { c ->
        dynamicTest(c["name"].asString()) {
            fun date(k: String) = LocalDate.parse(c[k].asString())
            when (val kind = c["kind"].asString()) {
                "dates" -> assertEquals(
                    c["dates"].values().map { it.asString() },
                    c["dates"].values().indices.map { n -> Schedule.occurrenceDate(c["frequency"].asString(), date("startDate"), n).toString() },
                )
                "next" -> assertEquals(
                    c["n"].asInt() to date("date"),
                    Schedule.firstOnOrAfter(c["frequency"].asString(), date("startDate"), date("onOrAfter"), c["minN"]?.asInt() ?: 1),
                )
                "dueAt" -> assertEquals(Instant.parse(c["dueAt"].asString()), Schedule.dueAt(date("date"), c["timeZone"].asString()))
                "crossRate" -> assertEquals(
                    c["rate"].takeUnless { it.isNull }?.asDouble(),
                    FxService.crossRate(c["perEur"].properties().associate { (k, v) -> k to v.asDouble() }, c["from"].asString(), c["to"].asString()),
                )
                else -> error("unknown kind $kind")
            }
        }
    }
}
