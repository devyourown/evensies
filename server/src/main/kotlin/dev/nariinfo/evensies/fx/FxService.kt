package dev.nariinfo.evensies.fx

import dev.nariinfo.evensies.config.AppProperties
import dev.nariinfo.evensies.money.Money
import org.slf4j.LoggerFactory
import org.springframework.http.client.SimpleClientHttpRequestFactory
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.stereotype.Service
import org.springframework.web.client.RestClient
import tools.jackson.databind.ObjectMapper
import java.time.Duration
import java.time.Instant
import java.time.LocalDate
import java.time.OffsetDateTime
import java.time.ZoneOffset
import java.util.concurrent.ConcurrentHashMap

/** Units of each currency per 1 EUR (`EUR` = 1); [date] is the latest per-quote date in [rates]. */
data class FxRates(val date: LocalDate, val rates: Map<String, Double>)

/**
 * Daily EUR-based rates from the source at `evensies.fx.url` (Frankfurter v2 shape), cached one row per asked day in
 * `fx_days` (docs/API.md "환율"). This is the only reader of that table; Phase 8's scheduler reuses [rates].
 */
@Service
class FxService(private val jdbc: JdbcClient, private val mapper: ObjectMapper, props: AppProperties) {
    private val log = LoggerFactory.getLogger(javaClass)
    private val url = props.fx.url.trim().trimEnd('/')
    private val client = RestClient.builder()
        .requestFactory(SimpleClientHttpRequestFactory().apply { setConnectTimeout(TIMEOUT); setReadTimeout(TIMEOUT) })
        .build()

    private class Row(val rates: FxRates, val fetchedAt: Instant)

    /**
     * Day → when asking the source for it last failed. That day is not asked again for [RETRY_AFTER], so an outage
     * (or a day the source has no data for, e.g. before 1999) costs one blocked request thread per day, not one per call.
     */
    internal val failedAt = ConcurrentHashMap<LocalDate, Instant>()

    /**
     * Rates for [day] (a future day means today, UTC), or null when automatic rates are off or none are available.
     * The cached row is used as is when it is final (fetched once [day]'s next day had ended) or recent (under 6 h old).
     * Otherwise the source is asked (unless it failed for [day] under [RETRY_AFTER] ago); when that fails the cached
     * row is used even if stale. Never another day's row.
     */
    fun rates(day: LocalDate): FxRates? {
        if (url.isEmpty()) return null
        val d = minOf(day, LocalDate.now(ZoneOffset.UTC))
        val now = Instant.now()
        val cached = find(d)
        if (cached != null && (cached.fetchedAt >= d.plusDays(2).atStartOfDay(ZoneOffset.UTC).toInstant() || cached.fetchedAt > now - FRESH)) {
            return cached.rates
        }
        if (failedAt[d]?.let { it > now - RETRY_AFTER } == true) return cached?.rates
        val fresh = fetch(d)
        if (fresh == null) {
            failedAt.entries.removeIf { it.value <= now - RETRY_AFTER }
            failedAt[d] = now
            return cached?.rates
        }
        jdbc.sql(
            """
            INSERT INTO fx_days (day, rates, rate_date, fetched_at) VALUES (:day, CAST(:rates AS jsonb), :rateDate, :at)
            ON CONFLICT (day) DO UPDATE SET rates = EXCLUDED.rates, rate_date = EXCLUDED.rate_date, fetched_at = EXCLUDED.fetched_at
            """
        ).param("day", d).param("rates", mapper.writeValueAsString(fresh.rates)).param("rateDate", fresh.date)
            .param("at", now.atOffset(ZoneOffset.UTC)).update()
        return fresh
    }

    private fun find(day: LocalDate): Row? = jdbc.sql("SELECT rates, rate_date, fetched_at FROM fx_days WHERE day = :day")
        .param("day", day).query { rs, _ ->
            val rates = mapper.readTree(rs.getString("rates")).properties().associate { (k, v) -> k to v.asDouble() }
            Row(FxRates(rs.getObject("rate_date", LocalDate::class.java), rates), rs.getObject("fetched_at", OffsetDateTime::class.java).toInstant())
        }.optional().orElse(null)

    /**
     * `GET {url}/rates?base=EUR&date=` → `[{date, base, quote, rate}]`. Keeps listed non-EUR quotes with a positive
     * rate and adds `EUR: 1`; null on any failure (connection, timeout, non-200, bad JSON) or when nothing is kept
     * (the source answers `[]` for days it has no data for).
     */
    private fun fetch(day: LocalDate): FxRates? = try {
        val body = client.get().uri("$url/rates?base=EUR&date=$day")
            .exchange { _, res -> if (res.statusCode.value() == 200) res.body.readAllBytes().decodeToString() else null }
        val items = body?.let(mapper::readTree)?.takeIf { it.isArray }?.values().orEmpty()
            .filter { item ->
                val quote = item.get("quote")?.takeIf { it.isString }?.asString()
                val rate = item.get("rate")?.takeIf { it.isNumber }?.asDouble()
                item.get("base")?.asString() == "EUR" && quote != null && quote != "EUR" && Money.isKnown(quote) &&
                    rate != null && rate > 0 && rate.isFinite()
            }
        if (items.isEmpty()) null else FxRates(
            items.maxOf { LocalDate.parse(it.get("date").asString()) },
            mapOf("EUR" to 1.0) + items.associate { it.get("quote").asString() to it.get("rate").asDouble() },
        )
    } catch (e: Exception) {
        log.warn("Exchange rates for {} unavailable: {}", day, e.toString())
        null
    }

    companion object {
        private val TIMEOUT: Duration = Duration.ofSeconds(5)
        private val FRESH: Duration = Duration.ofHours(6)
        internal val RETRY_AFTER: Duration = Duration.ofMinutes(5)
    }
}
