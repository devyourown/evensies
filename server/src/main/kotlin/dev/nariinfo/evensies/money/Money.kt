package dev.nariinfo.evensies.money

import tools.jackson.databind.json.JsonMapper
import java.math.BigDecimal
import java.util.Locale

/** Currency decimal places and symbols, loaded from resources/currencies.json (a copy of shared/currencies.json). */
object Money {
    private val json = Money::class.java.getResourceAsStream("/currencies.json")!!.use { JsonMapper.shared().readTree(it) }
    val decimals: Map<String, Int> = json.get("decimals").properties().associate { (k, v) -> k to v.asInt() }
    val symbols: Map<String, String> = json.get("symbols").properties().associate { (k, v) -> k to v.asString() }

    fun isKnown(currency: String) = currency in decimals

    /** "12.34" EUR -> 1234; "1234" KRW -> 1234. Throws ArithmeticException on sub-unit input. */
    fun toMinor(amount: BigDecimal, currency: String): Long =
        amount.movePointRight(decimals.getValue(currency)).longValueExact()

    fun format(minor: Long, currency: String): String =
        BigDecimal.valueOf(minor).movePointLeft(decimals.getValue(currency)).toPlainString()

    /** Activity/push display, same as the app's formatMoney: 1234567 KWD -> "din1,234.567", 15000 KRW -> "₩15,000". */
    fun display(minor: Long, currency: String): String {
        val d = decimals[currency] ?: 2
        return (symbols[currency] ?: currency) + String.format(Locale.US, "%,.${d}f", BigDecimal.valueOf(minor).movePointLeft(d))
    }
}
