package dev.nariinfo.evensies.money

import dev.nariinfo.evensies.sync.ExpenseDto
import dev.nariinfo.evensies.sync.GroupState

/**
 * Balances per currency bucket (docs/API.md "통화별 잔액"): [byCurrency] currency → memberId → balance (positive =
 * gets back); the default currency always, another one only while someone's balance in it isn't zero. [lines] and
 * [payments] are what each bucket was computed from (pairwise debts reuse them).
 */
data class BalanceResult(
    val currency: String,
    val byCurrency: Map<String, Map<String, Long>>,
    val lines: Map<String, List<ExpenseLine>>,
    val payments: Map<String, List<PaymentLine>>,
    val members: List<String>,
)

/** Kotlin port of the app's `balancesOf` / `groupTransfers` (app/lib/domain/balances.dart); checked by shared/overview-cases.json. */
object Balances {
    fun ofGroup(s: GroupState): BalanceResult {
        val d = s.defaultCurrency ?: ""
        val expensesBy = LinkedHashMap<String, MutableList<ExpenseDto>>().apply { put(d, mutableListOf()) }
        for (e in s.expenses.values.filter { !it.deleted }) {
            // Rule 1: in D as it is. Rules 2–3: a foreign expense converts only with a rate > 0, else stays in its currency.
            val c = if (e.currency == d) e else convert(e, d)
            expensesBy.getOrPut(c?.currency ?: e.currency) { mutableListOf() } += c ?: e
        }
        val paymentsBy = LinkedHashMap<String, MutableList<PaymentLine>>()
        for (p in s.payments.values.filter { !it.deleted }) paymentsBy.getOrPut(p.currency) { mutableListOf() } += PaymentLine(p.fromMember, p.toMember, p.amount)
        val ids = s.members.keys.toList()
        val byCurrency = LinkedHashMap<String, Map<String, Long>>()
        val lines = HashMap<String, List<ExpenseLine>>()
        for (cur in expensesBy.keys + paymentsBy.keys) {
            val all = expensesBy[cur].orEmpty().map { e ->
                ExpenseLine(e.payers.associate { it.memberId to it.amount }, e.amount, e.shares.associate { it.memberId to it.amount }, e.refund)
            }
            val b = Settlement.balances(ids, all, paymentsBy[cur].orEmpty())
            if (cur != d && b.values.all { it == 0L }) continue // rule 5
            byCurrency[cur] = b
            lines[cur] = all
        }
        return BalanceResult(d, byCurrency, lines, paymentsBy, ids)
    }

    /** What Settle up shows per bucket: fewest payments, or debts as they arose when the group turned simplifying off. */
    fun transfers(r: BalanceResult, simplify: Boolean): Map<String, List<Transfer>> = r.byCurrency.mapValues { (cur, b) ->
        if (simplify) Settlement.simplify(b) else Settlement.pairwiseDebts(r.members, r.lines[cur].orEmpty(), r.payments[cur].orEmpty())
    }

    /**
     * Shares and payers each through Fx.convertExpense (their totals are the same); null when there is no usable rate
     * or the conversion refuses (FxException) or is a stub again (NotImplementedError), like Dart `tryFx`.
     */
    private fun convert(e: ExpenseDto, d: String): ExpenseDto? {
        val rate = e.fxRateToDefault?.takeIf { it > 0 } ?: return null
        return try {
            fun run(parts: Map<String, Long>) = Fx.convertExpense(e.amount, parts, Money.decimals[e.currency] ?: 2, Money.decimals[d] ?: 2, rate)
            val shares = run(e.shares.associate { it.memberId to it.amount })
            val payers = run(e.payers.associate { it.memberId to it.amount })
            e.copy(
                amount = shares.amount, currency = d, fxRateToDefault = null,
                shares = e.shares.map { it.copy(amount = shares.parts[it.memberId] ?: 0) },
                payers = e.payers.map { it.copy(amount = payers.parts[it.memberId] ?: 0) },
            )
        } catch (_: NotImplementedError) {
            null
        } catch (_: FxException) {
            null
        }
    }
}
