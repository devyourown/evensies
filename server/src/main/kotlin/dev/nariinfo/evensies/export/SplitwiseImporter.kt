package dev.nariinfo.evensies.export

import com.opencsv.CSVReader
import dev.nariinfo.evensies.activity.clip
import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.money.Money
import dev.nariinfo.evensies.sync.EventService
import dev.nariinfo.evensies.sync.EventValidator
import dev.nariinfo.evensies.sync.GroupStateStore
import dev.nariinfo.evensies.sync.IncomingEvent
import dev.nariinfo.evensies.sync.PushResult
import org.springframework.stereotype.Service
import tools.jackson.databind.ObjectMapper
import java.io.InputStreamReader
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.util.UUID

data class ImportResult(val imported: Int, val latestSeq: Long)

/**
 * Splitwise CSV: `Date,Description,Category,Cost,Currency,<name>,...` where each name column is that
 * person's net for the row (paid − owed). Everyone with a positive net pays that net; the largest net (tie: lowest
 * member id) also pays the slack `Cost − Σ positive nets` and owes `Cost − Σ what the others owe` (the slack when the
 * nets add up to 0, and the shares still sum to Cost when they don't); everybody else owes −net. A negative slack or
 * owed amount is 400 IMPORT_FAILED. Unknown names become placeholder members. Everything goes through the normal push path.
 */
@Service
class SplitwiseImporter(
    private val events: EventService,
    private val stateStore: GroupStateStore,
    private val mapper: ObjectMapper,
) {
    fun import(groupId: UUID, userId: UUID, csv: ByteArray): ImportResult {
        val rows = CSVReader(InputStreamReader(csv.inputStream(), Charsets.UTF_8)).use { it.readAll() }
        val header = rows.firstOrNull()?.map(String::trim) ?: bad("Empty file")
        val cost = header.indexOf("Cost"); val currency = header.indexOf("Currency")
        val date = header.indexOf("Date"); val desc = header.indexOf("Description")
        if (listOf(date, desc, cost, currency).any { it < 0 }) bad("Expected columns Date, Description, Cost, Currency")
        val nameColumns = (currency + 1 until header.size).filter { header[it].isNotEmpty() }

        val state = stateStore.load(groupId)
        val memberIdByName = state.members.values.filter { !it.removed }.associate { it.name.lowercase() to it.id }.toMutableMap()
        val out = ArrayList<IncomingEvent>()
        for (col in nameColumns) {
            val name = header[col]
            if (name.lowercase() !in memberIdByName) {
                val id = UUID.randomUUID().toString()
                memberIdByName[name.lowercase()] = id
                out += event("member.added", mapOf("memberId" to id, "name" to name, "userId" to null))
            }
        }

        var imported = 0
        for ((i, row) in rows.drop(1).withIndex()) {
            val line = i + 2
            if (row.all { it.isBlank() } || row.getOrNull(desc)?.trim() == "Total balance") continue
            if (row.size < header.size) bad("Line $line: expected ${header.size} columns")
            val cur = row[currency].trim()
            if (!Money.isKnown(cur)) throw ApiException.badRequest("UNKNOWN_CURRENCY", "Line $line: unknown currency $cur")
            val amount = minor(row[cost], cur, line)
            val nets = nameColumns.map { memberIdByName.getValue(header[it].lowercase()) to minor(row[it], cur, line) }
            val payer = nets.maxWith(compareBy<Pair<String, Long>> { it.second }.thenByDescending { it.first })
            val slack = amount - nets.sumOf { maxOf(0L, it.second) }
            if (slack < 0) bad("Line $line: the people who paid add up to more than the cost")
            val payers = nets.map { (id, net) -> id to maxOf(0L, net) + if (id == payer.first) slack else 0 }
            val others = nets.filter { it.first != payer.first }.map { it.first to maxOf(0L, -it.second) }
            val payerShare = amount - others.sumOf { it.second }
            if (payerShare < 0) bad("Line $line: cannot derive shares")
            fun lines(l: List<Pair<String, Long>>) = l.filter { it.second > 0 }.map { mapOf("memberId" to it.first, "amount" to it.second) }
            out += event(
                "expense.created", mapOf(
                    "expenseId" to UUID.randomUUID().toString(),
                    "description" to row[desc].trim().ifEmpty { "Imported" }.clip(EventValidator.MAX_DESCRIPTION),
                    "amount" to amount, "currency" to cur, "fxRateToDefault" to null,
                    "paidBy" to payer.first, "date" to parseDate(row[date], line),
                    "category" to row.getOrNull(header.indexOf("Category"))?.trim()?.ifEmpty { null },
                    "shares" to lines(others + (payer.first to payerShare)),
                ) + (lines(payers).takeIf { it.size > 1 }?.let { mapOf("payers" to it) } ?: emptyMap())
            )
            imported++
        }
        val result: PushResult = events.pushValidated(groupId, userId, out)
        return ImportResult(imported, result.latestSeq)
    }

    private fun minor(raw: String, currency: String, line: Int): Long = try {
        Money.toMinor(BigDecimal(raw.trim().ifEmpty { "0" }), currency)
    } catch (_: Exception) {
        bad("Line $line: bad amount '$raw'")
    }

    private fun parseDate(raw: String, line: Int): String = try {
        LocalDate.parse(raw.trim()).toString()
    } catch (_: Exception) {
        bad("Line $line: bad date '$raw' (expected YYYY-MM-DD)")
    }

    private fun event(type: String, payload: Map<String, Any?>) =
        IncomingEvent(UUID.randomUUID(), type, mapper.valueToTree(payload), Instant.now())

    private fun bad(message: String): Nothing = throw ApiException.badRequest("IMPORT_FAILED", message)
}
