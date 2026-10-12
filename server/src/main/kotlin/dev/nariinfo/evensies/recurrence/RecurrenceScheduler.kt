package dev.nariinfo.evensies.recurrence

import dev.nariinfo.evensies.config.AppProperties
import dev.nariinfo.evensies.fx.FxRates
import dev.nariinfo.evensies.fx.FxService
import dev.nariinfo.evensies.group.GroupRepository
import dev.nariinfo.evensies.push.PushNotifier
import dev.nariinfo.evensies.sync.Event
import dev.nariinfo.evensies.sync.EventService
import dev.nariinfo.evensies.sync.IncomingEvent
import dev.nariinfo.evensies.sync.double
import dev.nariinfo.evensies.sync.text
import org.slf4j.LoggerFactory
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Component
import org.springframework.transaction.PlatformTransactionManager
import org.springframework.transaction.support.TransactionTemplate
import tools.jackson.databind.ObjectMapper
import tools.jackson.databind.node.ObjectNode
import java.time.Duration
import java.time.Instant
import java.time.LocalDate
import java.time.OffsetDateTime
import java.time.ZoneOffset
import java.util.UUID
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

/**
 * Adds the repeats of every series as they fall due (docs/API.md "반복 지출"): each one is an ordinary `expense.created`
 * by Evensies (null actor) with a derived id, so a crash, a retry or a second instance stores it once.
 */
@Component
class RecurrenceScheduler(
    private val jdbc: JdbcClient,
    private val groups: GroupRepository,
    private val events: EventService,
    private val fx: FxService,
    private val notifier: PushNotifier,
    private val mapper: ObjectMapper,
    props: AppProperties,
    txManager: PlatformTransactionManager,
) {
    private val log = LoggerFactory.getLogger(javaClass)
    private val tx = TransactionTemplate(txManager)
    private val idKey = SecretKeySpec(props.jwtSecret.toByteArray(Charsets.UTF_8), "HmacSHA256")

    private class Row(
        val id: UUID, val groupId: UUID, val frequency: String, val startDate: LocalDate, val timeZone: String,
        val template: ObjectNode, val deleted: Boolean, val n: Int, val dueAt: Instant,
    )

    @Scheduled(fixedDelay = 60_000)
    fun tick() {
        runDue(Instant.now())
    }

    /** Adds every repeat due at [now] (downtime is caught up in order); returns how many were stored. */
    fun runDue(now: Instant): Int {
        val due = jdbc.sql("SELECT id FROM recurrences WHERE deleted_at IS NULL AND next_due_at <= :now ORDER BY next_due_at LIMIT 200")
            .param("now", now.atOffset(ZoneOffset.UTC)).query(UUID::class.java).list().filterNotNull()
        var stored = 0
        for (id in due) {
            while (true) stored += postNext(id, now) ?: break
        }
        return stored
    }

    /**
     * The series' next repeat in one transaction: lock the group (pushes take the same lock, so a concurrent stop or
     * edit is always seen), re-read the row, push, advance. Null when the row is done for now (stopped, not due, already
     * advanced by another instance, or failed — then it is retried in an hour); else the number of events stored (0 when
     * the derived clientId was already stored).
     * ponytail: one full state load per repeat (inside the push); batch per group if catch-ups get large.
     */
    private fun postNext(id: UUID, now: Instant): Int? {
        val seen = find(id)?.takeIf { !it.deleted && it.dueAt <= now } ?: return null
        val date = Schedule.occurrenceDate(seen.frequency, seen.startDate, seen.n)
        // Outside the group lock: asking the rate source can take seconds.
        val rates = if (needsRate(seen)) fx.rates(date) else null
        val stored: List<Event> = try {
            tx.execute {
                val group = groups.lockForUpdate(seen.groupId) ?: return@execute null
                val r = find(id)?.takeIf { !it.deleted && it.dueAt <= now && it.n == seen.n } ?: return@execute null
                val oid = derivedId(id, r.n)
                val payload = r.template.deepCopy().put("expenseId", oid.toString()).put("date", date.toString())
                    .put("recurrenceId", id.toString()).put("occurrence", r.n)
                refreshRate(payload, group.defaultCurrency, rates)
                val stored = events.pushAsEvensies(r.groupId, listOf(IncomingEvent(oid, "expense.created", payload, r.dueAt)))
                val next = Schedule.occurrenceDate(r.frequency, r.startDate, r.n + 1)
                jdbc.sql("UPDATE recurrences SET next_occurrence = :n, next_due_at = :due WHERE id = :id")
                    .param("n", r.n + 1).param("due", Schedule.dueAt(next, r.timeZone).atOffset(ZoneOffset.UTC)).param("id", id).update()
                stored
            }
        } catch (e: Exception) {
            // A bug or a database hiccup (lock timeout, lost connection): the template was checked as an expense when stored.
            log.warn("Repeat {} of series {} failed, retrying in an hour: {}", seen.n, id, e.toString())
            retryLater(id, seen.n, now)
            null
        } ?: return null
        if (stored.isNotEmpty()) notifier.notify(seen.groupId, null, stored)
        return stored.size
    }

    /**
     * Pushes repeat [n] of series [id] back by [RETRY]; a no-op once the row has moved past [n] (another instance added
     * it meanwhile and set the next due time, which must stay).
     */
    internal fun retryLater(id: UUID, n: Int, now: Instant) {
        jdbc.sql("UPDATE recurrences SET next_due_at = :due WHERE id = :id AND next_occurrence = :n")
            .param("due", (now + RETRY).atOffset(ZoneOffset.UTC)).param("id", id).param("n", n).update()
    }

    /**
     * Repeat [n]'s clientId and expenseId: deterministic, but keyed with the server secret, so nobody who knows the series
     * id (a former member included) can take a future repeat's id first in another group or as a clientId.
     */
    internal fun derivedId(id: UUID, n: Int): UUID {
        val mac = Mac.getInstance("HmacSHA256").apply { init(idKey) } // not thread-safe: one per call
        return UUID.nameUUIDFromBytes(mac.doFinal("evensies:recurrence:$id:$n".toByteArray(Charsets.UTF_8)))
    }

    /** A foreign template with a rate (not null, not 0 = "Not converted") gets the day's rate, like a new expense in the app. */
    private fun needsRate(r: Row): Boolean {
        val currency = r.template.text("currency")
        return (r.template.double("fxRateToDefault") ?: 0.0) > 0 && currency != groups.find(r.groupId)?.defaultCurrency
    }

    private fun refreshRate(payload: ObjectNode, groupCurrency: String, rates: FxRates?) {
        val currency = payload.text("currency") ?: return
        if (rates == null || currency == groupCurrency || (payload.double("fxRateToDefault") ?: 0.0) <= 0) return
        FxService.crossRate(rates.rates, currency, groupCurrency)?.let { payload.put("fxRateToDefault", it) }
    }

    private fun find(id: UUID): Row? = jdbc.sql("SELECT * FROM recurrences WHERE id = :id").param("id", id).query { rs, _ ->
        Row(
            id = id,
            groupId = rs.getObject("group_id", UUID::class.java),
            frequency = rs.getString("frequency"),
            startDate = rs.getObject("start_date", LocalDate::class.java),
            timeZone = rs.getString("time_zone"),
            template = mapper.readTree(rs.getString("template")) as ObjectNode,
            deleted = rs.getObject("deleted_at") != null,
            n = rs.getInt("next_occurrence"),
            dueAt = rs.getObject("next_due_at", OffsetDateTime::class.java).toInstant(),
        )
    }.optional().orElse(null)

    companion object {
        val RETRY: Duration = Duration.ofHours(1)
    }
}
