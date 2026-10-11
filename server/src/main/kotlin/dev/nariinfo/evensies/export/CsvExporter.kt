package dev.nariinfo.evensies.export

import com.opencsv.CSVWriter
import dev.nariinfo.evensies.money.Money
import dev.nariinfo.evensies.sync.GroupState
import java.io.StringWriter
import java.math.BigDecimal

object CsvExporter {
    /**
     * date,description,category,amount,currency,fxRateToDefault,paidBy,<one column per member name> — amounts in major
     * units of the expense currency. category is the label of a key (`Entertainment - Other` for `*.other`), `General`
     * for null/blank, legacy text as stored. User text cells go through [text] (CSV injection).
     * fxRateToDefault is the stored rate as a plain decimal (`0.0000007`), empty when null. paidBy is the payer's name,
     * or `Anna 60.00; Ben 40.00` (payers order) for several; refund rows have negative amount and shares.
     */
    fun export(state: GroupState): String {
        val members = state.members.values.toList()
        fun name(id: String) = state.members[id]?.name ?: id
        val out = StringWriter()
        CSVWriter(out).use { csv ->
            csv.writeNext((listOf("date", "description", "category", "amount", "currency", "fxRateToDefault", "paidBy") + members.map { text(it.name) }).toTypedArray())
            for (e in state.expenses.values.filter { !it.deleted }) {
                val sign = if (e.refund) -1 else 1
                val shares = e.shares.associate { it.memberId to it.amount }
                val paidBy = e.payers.singleOrNull()?.let { name(it.memberId) }
                    ?: e.payers.joinToString("; ") { "${name(it.memberId)} ${Money.format(it.amount, e.currency)}" }
                val rate = e.fxRateToDefault?.let { BigDecimal.valueOf(it).stripTrailingZeros().toPlainString() } ?: ""
                val category = Categories.label(e.category) ?: e.category?.takeIf { it.isNotBlank() } ?: "General"
                val row = listOf(e.date, text(e.description), text(category), Money.format(sign * e.amount, e.currency), e.currency, rate, text(paidBy)) +
                    members.map { m -> shares[m.id]?.let { Money.format(sign * it, e.currency) } ?: "" }
                csv.writeNext(row.toTypedArray())
            }
        }
        return out.toString()
    }

    /** OWASP CSV injection: text a spreadsheet would run as a formula gets a leading `'`. Not for amounts (`-60.00`). */
    private fun text(s: String) = if (s.isNotEmpty() && s[0] in "=+-@\t\r") "'$s" else s
}
