package dev.nariinfo.evensies.export

import com.opencsv.CSVWriter
import dev.nariinfo.evensies.money.Money
import dev.nariinfo.evensies.sync.GroupState
import java.io.StringWriter

object CsvExporter {
    /** date,description,amount,currency,paidBy,<one column per member name> — amounts in major units. */
    fun export(state: GroupState): String {
        val members = state.members.values.toList()
        val out = StringWriter()
        CSVWriter(out).use { csv ->
            csv.writeNext((listOf("date", "description", "amount", "currency", "paidBy") + members.map { it.name }).toTypedArray())
            for (e in state.expenses.values.filter { !it.deleted }) {
                val shares = e.shares.associate { it.memberId to it.amount }
                val row = listOf(
                    e.date, e.description, Money.format(e.amount, e.currency), e.currency,
                    state.members[e.paidBy]?.name ?: e.paidBy,
                ) + members.map { m -> shares[m.id]?.let { Money.format(it, e.currency) } ?: "" }
                csv.writeNext(row.toTypedArray())
            }
        }
        return out.toString()
    }
}
