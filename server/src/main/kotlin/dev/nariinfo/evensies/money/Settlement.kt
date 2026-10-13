package dev.nariinfo.evensies.money

import kotlin.math.abs
import kotlin.math.min

/**
 * [payers]: memberId → amount paid (a refund: amount received), [shares]: memberId → amount owed (a refund: split back
 * to); both sum to [amount]. A [refund] reverses an expense's effect on balances.
 */
data class ExpenseLine(val payers: Map<String, Long>, val amount: Long, val shares: Map<String, Long>, val refund: Boolean = false) {
    constructor(paidBy: String, amount: Long, shares: Map<String, Long>) : this(mapOf(paidBy to amount), amount, shares)
}
data class PaymentLine(val from: String, val to: String, val amount: Long)
data class Transfer(val from: String, val to: String, val amount: Long)

object Settlement {
    /**
     * Balance per member. Tests: shared/settlement-cases.json (SettlementTest).
     *
     * balance = what I paid (Σ expense.amount paid by me) − what I owe (Σ shares[me])
     *         + payments sent (from == me) − payments received (to == me)
     * Every member is in the result (0 with no activity). An id that appears in shares but not in members is assumed
     * not to exist.
     * Invariant: the values sum to 0.
     *
     * Phase 3 (port of the Dart computeBalances, app/lib/domain/settlement.dart):
     * per line sign = refund ? −1 : +1, balance[m] += sign × payers[m], balance[m] −= sign × shares[m].
     */
    fun balances(members: List<String>, expenses: List<ExpenseLine>, payments: List<PaymentLine>): Map<String, Long> {
        val result = LinkedHashMap<String, Long>()
        for (member in members) result[member] = 0L
        for (expense in expenses) {
            val sign = if (expense.refund) -1 else 1
            for ((member, paid) in expense.payers) result[member] = result.getValue(member) + sign * paid
            for ((member, share) in expense.shares) result[member] = result.getValue(member) - sign * share
        }
        // A payment is an expense paid by `from` and owed entirely by `to`.
        for (payment in payments) {
            result[payment.from] = result.getValue(payment.from) + payment.amount
            result[payment.to] = result.getValue(payment.to) - payment.amount
        }
        return result
    }

    /**
     * Debt simplification (greedy).
     *
     * 1. Sort positives (creditors) and negatives (debtors) each by absolute value, largest first; on a tie, memberId
     *    ascending.
     * 2. Pair the largest creditor c with the largest debtor d: Transfer(from=d, to=c) of min(c.amount, |d.amount|).
     * 3. Drop whichever reached 0 (both if both did) and repeat from 1. Members with a 0 balance are left out from the
     *    start.
     * Result order = creation order.
     * Invariants: transfers.size <= members − 1, applying every transfer brings every balance to 0, deterministic.
     */
    fun simplify(balances: Map<String, Long>): List<Transfer> {
        val result = ArrayList<Transfer>()
        val creditors = ArrayList<Pair<String, Long>>()
        val debtors = ArrayList<Pair<String, Long>>()
        for ((member, amount) in balances) {
            if (amount < 0) debtors += member to amount
            else if (amount > 0) creditors += member to amount
        }
        // Largest absolute amount first; ties by member id ascending. Same rule for both lists.
        val largestFirst = compareByDescending<Pair<String, Long>> { abs(it.second) }.thenBy { it.first }
        while (debtors.isNotEmpty() && creditors.isNotEmpty()) {
            debtors.sortWith(largestFirst)
            creditors.sortWith(largestFirst)
            val (debtor, debt) = debtors.removeAt(0)
            val (creditor, credit) = creditors.removeAt(0)
            val amount = min(-debt, credit)
            if (debt + amount != 0L) debtors += debtor to debt + amount
            if (credit - amount != 0L) creditors += creditor to credit - amount
            result += Transfer(from = debtor, to = creditor, amount = amount)
        }
        return result
    }

    /**
     * Debts as they arose, for groups with "simplify debts" off (port of Dart pairwiseDebts; settlement-cases
     * `expectedPairwise`). Each expense line and each payment is settled on its own with simplify(balances(...)); the
     * transfers are summed per (from, to) and netted per pair of people. Zero pairs are dropped; sorted by from, then to.
     */
    fun pairwiseDebts(members: List<String>, lines: List<ExpenseLine>, payments: List<PaymentLine>): List<Transfer> {
        val net = LinkedHashMap<Pair<String, String>, Long>() // (lo, hi) → what lo owes hi (negative: hi owes lo)
        fun add(t: Transfer) {
            val lo = t.from < t.to
            val key = if (lo) t.from to t.to else t.to to t.from
            net[key] = (net[key] ?: 0L) + if (lo) t.amount else -t.amount
        }
        for (l in lines) simplify(balances(members, listOf(l), emptyList())).forEach(::add)
        for (p in payments) simplify(balances(members, emptyList(), listOf(p))).forEach(::add)
        return net.filterValues { it != 0L }
            .map { (k, v) -> if (v > 0) Transfer(k.first, k.second, v) else Transfer(k.second, k.first, -v) }
            .sortedWith(compareBy<Transfer> { it.from }.thenBy { it.to })
    }
}
