package dev.nariinfo.evensies.money

import tools.jackson.databind.json.JsonMapper
import java.math.BigDecimal

/** Currency decimal places, loaded from resources/currencies.json (a copy of shared/currencies.json). */
object Money {
    val decimals: Map<String, Int> = Money::class.java.getResourceAsStream("/currencies.json")!!.use { stream ->
        val node = JsonMapper.shared().readTree(stream).get("decimals")
        node.properties().associate { (k, v) -> k to v.asInt() }
    }

    fun isKnown(currency: String) = currency in decimals

    /** "12.34" EUR -> 1234; "1234" KRW -> 1234. Throws ArithmeticException on sub-unit input. */
    fun toMinor(amount: BigDecimal, currency: String): Long =
        amount.movePointRight(decimals.getValue(currency)).longValueExact()

    fun format(minor: Long, currency: String): String =
        BigDecimal.valueOf(minor).movePointLeft(decimals.getValue(currency)).toPlainString()
}
