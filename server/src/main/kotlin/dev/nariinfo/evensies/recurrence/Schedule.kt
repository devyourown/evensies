package dev.nariinfo.evensies.recurrence

import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.temporal.ChronoUnit

/** Date rules of a repeating series (docs/API.md "Recurring expenses"; shared/recurrence-cases.json, app domain/recurrence.dart). */
object Schedule {
    /**
     * Occurrence [n] (0 = [startDate]), always computed from [startDate] so a clamped month end never sticks
     * (Jan 31 → Feb 28 → Mar 31); `plusMonths`/`plusYears` clamp to the month's last day.
     */
    fun occurrenceDate(frequency: String, startDate: LocalDate, n: Int): LocalDate = when (frequency) {
        "weekly" -> startDate.plusDays(7L * n)
        "biweekly" -> startDate.plusDays(14L * n)
        "monthly" -> startDate.plusMonths(n.toLong())
        "yearly" -> startDate.plusYears(n.toLong())
        else -> throw IllegalArgumentException("Unknown frequency $frequency")
    }

    /** The smallest n >= [minN] whose occurrence is on or after [date], with that date. */
    fun firstOnOrAfter(frequency: String, startDate: LocalDate, date: LocalDate, minN: Int = 1): Pair<Int, LocalDate> {
        // Whole units between never overshoot (start + k units <= date), so counting up from there finds the first one.
        val units = when (frequency) {
            "weekly" -> ChronoUnit.WEEKS.between(startDate, date)
            "biweekly" -> ChronoUnit.WEEKS.between(startDate, date) / 2
            "monthly" -> ChronoUnit.MONTHS.between(startDate, date)
            else -> ChronoUnit.YEARS.between(startDate, date)
        }
        var n = maxOf(minN.toLong(), units).toInt()
        while (occurrenceDate(frequency, startDate, n) < date) n++
        return n to occurrenceDate(frequency, startDate, n)
    }

    /** 09:00 on [date] in [timeZone] (IANA name or offset); a time in a DST gap moves forward, per [ZonedDateTime]. */
    fun dueAt(date: LocalDate, timeZone: String): Instant = ZonedDateTime.of(date, LocalTime.of(9, 0), ZoneId.of(timeZone)).toInstant()
}
