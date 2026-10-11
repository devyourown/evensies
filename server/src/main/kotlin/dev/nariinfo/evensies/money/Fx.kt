package dev.nariinfo.evensies.money

import java.math.BigDecimal
import java.math.RoundingMode

/** code: BAD_RATE | NEGATIVE_AMOUNT | SUM_MISMATCH */
class FxException(val code: String) : RuntimeException(code)

data class ConvertedExpense(val amount: Long, val parts: Map<String, Long>)

/**
 * Currency conversion (docs/API.md "환산 규칙"; tests: shared/fx-cases.json, FxCasesTest). Port of Hyojun's
 * app/lib/domain/fx.dart.
 * Port note: R = `BigDecimal(rate.toString())`. JDK 19+ `Double.toString` is shortest round-trip, so R is the same
 * decimal number as Dart's `rate.toString()` (`7.0E-7` here, `7e-7` there).
 */
object Fx {
    /**
     * Converts a signed [amount] in minor units. [rate] = major units of the target per 1 major unit of the source;
     * not finite or <= 0 → FxException("BAD_RATE"). Exact value = amount × R × 10^(toDecimals − fromDecimals), computed
     * without double multiplication (100 × 0.285 must give 29, not 28), rounded to the nearest integer with exact halves
     * away from zero, so convertAmount(−x) == −convertAmount(x).
     */
    fun convertAmount(amount: Long, fromDecimals: Int, toDecimals: Int, rate: Double): Long {
        checkRate(rate)
        // HALF_UP rounds exact halves away from zero, for negative amounts too.
        return exactValue(amount, fromDecimals, toDecimals, rate).setScale(0, RoundingMode.HALF_UP).longValueExact()
    }

    /**
     * Converts an expense total and its [parts] (shares, or separately the payer amounts) so the parts add up to the
     * total. Checks in order: BAD_RATE; amount or any part < 0 → NEGATIVE_AMOUNT; Σ parts != amount → SUM_MISMATCH.
     * total = convertAmount(amount); each part = its exact value rounded down; the leftover (0..parts.size) goes +1 to
     * the parts with the largest dropped fraction, ties by memberId ascending, never to a part of 0. Same keys as [parts].
     */
    fun convertExpense(amount: Long, parts: Map<String, Long>, fromDecimals: Int, toDecimals: Int, rate: Double): ConvertedExpense {
        checkRate(rate)
        if (amount < 0 || parts.values.any { it < 0 }) throw FxException("NEGATIVE_AMOUNT")
        if (parts.values.sum() != amount) throw FxException("SUM_MISMATCH")
        val total = convertAmount(amount, fromDecimals, toDecimals, rate)
        val exact = parts.mapValues { (_, part) -> exactValue(part, fromDecimals, toDecimals, rate) }
        val converted = exact.mapValues { (_, value) -> value.setScale(0, RoundingMode.FLOOR).longValueExact() }.toMutableMap()
        val dropped = exact.mapValues { (member, value) -> value - converted.getValue(member).toBigDecimal() }
        val leftover = total - converted.values.sum()
        parts.keys.filter { parts.getValue(it) > 0 }
            .sortedWith(compareByDescending<String> { dropped.getValue(it) }.thenBy { it })
            .take(leftover.toInt())
            .forEach { converted[it] = converted.getValue(it) + 1 }
        return ConvertedExpense(total, converted)
    }

    private fun checkRate(rate: Double) {
        if (!rate.isFinite() || rate <= 0) throw FxException("BAD_RATE")
    }

    private fun exactValue(amount: Long, fromDecimals: Int, toDecimals: Int, rate: Double): BigDecimal =
        BigDecimal(amount).multiply(BigDecimal(rate.toString())).movePointRight(toDecimals - fromDecimals)
}
