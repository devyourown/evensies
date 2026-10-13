package dev.nariinfo.evensies.money

import java.math.BigInteger

enum class SplitMode { EQUAL, EXACT, PERCENT, SHARES, ADJUSTMENT }

/** code: SUM_MISMATCH | NEGATIVE_AMOUNT | NO_MEMBERS | INVALID_INPUT | NEGATIVE_SHARE */
class SplitException(val code: String) : RuntimeException(code)

object Split {
    /**
     * Split calculation. Tests: shared/split-cases.json (SplitTest).
     *
     * Input
     *  - amount: an integer in minor units (EUR 1234 = €12.34). Negative → SplitException("NEGATIVE_AMOUNT").
     *  - members: member ids. Empty → SplitException("NO_MEMBERS"). May be unsorted.
     *  - mode:
     *      EQUAL   → input ignored. amount / n each; the remainder r = amount % n adds 1 each
     *                to the first r members in ascending memberId order.
     *      EXACT   → input[memberId] = the fixed amount (integer). A sum other than amount → SplitException("SUM_MISMATCH").
     *      PERCENT → input[memberId] = a percentage. Weight w = round(pct × 10^6), W = Σ w. |W − 10^8| >= 1000 (±0.001%)
     *                → "SUM_MISMATCH". Each share = amount × w / W (BigInteger); the leftover goes 1 each to members
     *                with percent > 0 in ascending memberId order.
     * Output: memberId → amount for every member. Always sums to amount.
     * Invariants: deterministic (same input → same output), sum == amount, every share >= 0.
     *
     * Phase 3 (port of the Dart computeSplit, app/lib/domain/split.dart):
     *  - PERCENT: leftover minor units go only to members whose percent is > 0 (a 0% member always gets 0).
     *  - SHARES: input = share counts (>= 0, fractional, missing = 0); negative/NaN/infinite → "INVALID_INPUT".
     *    w = round(count * 100), W = Σ w; W == 0 → "NO_MEMBERS". share = amount * w / W (integer math);
     *    leftover +1 each to members with w > 0, memberId ascending.
     *  - ADJUSTMENT: input = minor-unit adjustments (may be negative, missing = 0); not whole/NaN/infinite →
     *    "INVALID_INPUT". base = amount − Σ adj; base < 0 → "NEGATIVE_SHARE". Split base like EQUAL, then add each
     *    adj; any result < 0 → "NEGATIVE_SHARE".
     *  - SHARES/ADJUSTMENT ignore input keys not in members.
     */
    fun compute(amount: Long, mode: SplitMode, members: List<String>, input: Map<String, Double>?): Map<String, Long> {
        if (amount < 0) throw SplitException("NEGATIVE_AMOUNT")
        if (members.isEmpty()) throw SplitException("NO_MEMBERS")
        val sorted = members.sorted()
        val result = LinkedHashMap<String, Long>()
        when (mode) {
            SplitMode.EQUAL -> {
                val quotient = amount / members.size
                val remainder = amount % members.size
                for (member in sorted) result[member] = quotient
                giveRemainder(result, sorted, remainder)
            }
            SplitMode.EXACT -> {
                for (member in sorted) result[member] = input?.get(member)?.toLong() ?: 0L
                if (result.values.sum() != amount) throw SplitException("SUM_MISMATCH")
            }
            SplitMode.PERCENT -> {
                // Integer weights (percent × 10^6) divided by their real total, so a total within the ±0.001%
                // tolerance but above 100 can't push the shares past the amount (port of the Dart fix).
                val weights = sorted.associateWith { Math.round((input?.get(it) ?: 0.0) * 1_000_000).toBigInteger() }
                val total = weights.values.fold(BigInteger.ZERO, BigInteger::add)
                if ((total - BigInteger.valueOf(100_000_000)).abs() >= BigInteger.valueOf(1000)) throw SplitException("SUM_MISMATCH")
                for (member in sorted) result[member] = (amount.toBigInteger() * weights.getValue(member) / total).toLong()
                giveRemainder(result, sorted.filter { (input?.get(it) ?: 0.0) > 0 }, amount - result.values.sum())
            }
            SplitMode.SHARES -> {
                val weights = sorted.associateWith { member ->
                    val count = input?.get(member) ?: 0.0
                    if (count.isNaN() || count.isInfinite() || count < 0) throw SplitException("INVALID_INPUT")
                    Math.round(count * 100)
                }
                val total = weights.values.sum()
                if (total == 0L) throw SplitException("NO_MEMBERS")
                for (member in sorted) result[member] = amount * weights.getValue(member) / total
                giveRemainder(result, sorted.filter { weights.getValue(it) > 0 }, amount - result.values.sum())
            }
            SplitMode.ADJUSTMENT -> {
                val adjustments = sorted.associateWith { member ->
                    val adj = input?.get(member) ?: 0.0
                    if (adj.isNaN() || adj.isInfinite() || adj != Math.rint(adj)) throw SplitException("INVALID_INPUT")
                    adj.toLong()
                }
                val base = amount - adjustments.values.sum()
                if (base < 0) throw SplitException("NEGATIVE_SHARE")
                for (member in sorted) result[member] = base / members.size
                giveRemainder(result, sorted, base % members.size)
                for (member in sorted) {
                    result[member] = result.getValue(member) + adjustments.getValue(member)
                    if (result.getValue(member) < 0) throw SplitException("NEGATIVE_SHARE")
                }
            }
        }
        return result
    }

    /** Adds 1 to the first [k] members of [sorted] (member ids ascending). Same rule as the Dart equal split. */
    private fun giveRemainder(result: MutableMap<String, Long>, sorted: List<String>, k: Long) {
        sorted.forEachIndexed { index, member -> if (index < k) result[member] = result.getValue(member) + 1 }
    }
}
