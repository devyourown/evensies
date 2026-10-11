package dev.nariinfo.evensies.fx

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.common.RateLimiter
import dev.nariinfo.evensies.config.userId
import org.springframework.http.HttpStatus
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.time.LocalDate
import java.time.ZoneOffset
import java.time.format.DateTimeParseException

data class FxTable(val date: String, val base: String, val rates: Map<String, Double>)

@RestController
class FxController(private val fx: FxService) {
    // A miss can cost a call to the rate source, so requests are capped per user (cache hits count too).
    private val limiter = RateLimiter(capacity = 30.0, refillPerSecond = 0.5)

    /** docs/API.md "환율": [date] is optional; a future one means today (UTC). */
    @GetMapping("/fx")
    fun table(authentication: Authentication, @RequestParam(required = false) date: String?): FxTable {
        if (!limiter.tryConsume(authentication.userId)) throw ApiException.tooManyRequests("Too many exchange-rate requests, try again in a minute")
        val day = if (date.isNullOrEmpty()) LocalDate.now(ZoneOffset.UTC) else parse(date)
        val r = fx.rates(day) ?: throw ApiException(HttpStatus.SERVICE_UNAVAILABLE, "FX_UNAVAILABLE", "No exchange rates available right now")
        return FxTable(r.date.toString(), "EUR", r.rates)
    }

    private fun parse(date: String): LocalDate {
        val bad = ApiException.badRequest("VALIDATION", "date must be a real day as YYYY-MM-DD")
        if (!DATE.matches(date)) throw bad
        return try { LocalDate.parse(date) } catch (_: DateTimeParseException) { throw bad }
    }

    private companion object {
        val DATE = Regex("""\d{4}-\d{2}-\d{2}""")
    }
}
