package dev.nariinfo.evensies

import dev.nariinfo.evensies.email.DigestBuilder
import org.junit.jupiter.api.Test
import java.time.Instant
import kotlin.test.assertEquals

/** When the next email summary is due (docs/API.md "요약 메일"): UTC, strictly after the last one. */
class NextDueTest {
    private fun due(last: String, mode: String) = DigestBuilder.nextDue(Instant.parse(last), mode).toString()

    @Test
    fun daily() {
        assertEquals("2026-11-02T17:00:00Z", due("2026-11-02T09:00:00Z", "daily"))
        assertEquals("2026-11-03T17:00:00Z", due("2026-11-02T17:00:00Z", "daily"), "exactly at 17:00 → tomorrow")
        assertEquals("2026-11-03T17:00:00Z", due("2026-11-02T18:30:00Z", "daily"))
        assertEquals("2027-01-01T17:00:00Z", due("2026-12-31T23:59:00Z", "daily"))
    }

    @Test
    fun weeklyOnMondays() {
        assertEquals("2026-11-02T17:00:00Z", due("2026-11-02T08:00:00Z", "weekly"), "Monday morning → that Monday")
        assertEquals("2026-11-09T17:00:00Z", due("2026-11-02T17:00:00Z", "weekly"))
        assertEquals("2026-11-09T17:00:00Z", due("2026-11-04T12:00:00Z", "weekly"), "Wednesday → next Monday")
        assertEquals("2026-11-02T17:00:00Z", due("2026-11-01T23:00:00Z", "weekly"), "Sunday night → the next day")
    }

    @Test
    fun monthlyOnTheFirstIncludingMonthEnds() {
        assertEquals("2026-12-01T09:00:00Z", due("2026-11-01T09:00:00Z", "monthly"))
        assertEquals("2026-11-01T09:00:00Z", due("2026-11-01T08:59:00Z", "monthly"))
        assertEquals("2026-02-01T09:00:00Z", due("2026-01-31T10:00:00Z", "monthly"), "a month end → the next day's 09:00")
        assertEquals("2026-03-01T09:00:00Z", due("2026-02-28T23:00:00Z", "monthly"))
        assertEquals("2027-01-01T09:00:00Z", due("2026-12-15T00:00:00Z", "monthly"), "year end")
    }
}
