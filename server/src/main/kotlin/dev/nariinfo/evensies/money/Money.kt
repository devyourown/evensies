package dev.nariinfo.evensies.money

import tools.jackson.databind.json.JsonMapper
import dev.nariinfo.evensies.common.Strings
import java.math.BigDecimal
import java.math.BigInteger

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

    /**
     * M(x), docs/API.md "Money notation": |minor| grouped by 3 with [lang]'s `group`, its `decimal` and the fraction; the symbol
     * is [lang]'s `money.symbols`, else currencies.json's, else the ISO code; `{s}{n}` puts U+00A0 after a symbol ending
     * in a Latin letter (`CHF 12.50`); a negative gets a leading U+2212. 1234567 KWD en → "KWD 1,234.567", de EUR 123456 →
     * "1.234,56 €".
     */
    fun display(minor: Long, currency: String, lang: String = "en"): String {
        val l = Strings.lang(lang)
        val d = decimals[currency] ?: 2
        val digits = BigInteger.valueOf(minor).abs().toString().padStart(d + 1, '0')
        val whole = digits.dropLast(d).reversed().chunked(3).map(String::reversed).reversed().joinToString(Strings.get(l, "money", "group")!!)
        val n = if (d == 0) whole else whole + Strings.get(l, "money", "decimal") + digits.takeLast(d)
        val pattern = Strings.get(l, "money", "pattern")!!
        val s = Strings.map(l, "money", "symbols")[currency] ?: symbols[currency] ?: currency
        val gap = if (pattern == "{s}{n}" && s.lastOrNull()?.let(::latin) == true) "\u00a0" else ""
        return (if (minor < 0) "\u2212" else "") + Strings.fill(pattern, mapOf("s" to s + gap, "n" to n))
    }

    /** A–Z, a–z and U+00C0–U+024F except × and ÷. */
    private fun latin(c: Char) = c in 'A'..'Z' || c in 'a'..'z' || (c in '\u00c0'..'\u024f' && c != '\u00d7' && c != '\u00f7')
}
