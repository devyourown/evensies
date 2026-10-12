package dev.nariinfo.evensies.payment

import com.fasterxml.jackson.annotation.JsonInclude
import dev.nariinfo.evensies.common.ApiException
import java.math.BigInteger

/** A way to get paid (docs/API.md "결제 수단"). Fields a type does not use are dropped on save. */
@JsonInclude(JsonInclude.Include.NON_NULL)
data class PaymentMethod(
    val type: String? = null,
    val value: String? = null,
    val holder: String? = null,
    val bank: String? = null,
    val bic: String? = null,
)

object PaymentMethods {
    const val MAX_TOTAL = 8
    private val multi = mapOf("iban" to 3, "kr_bank" to 3)
    private val username = Regex("[A-Za-z0-9._-]{1,40}")
    private val ibanShape = Regex("[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}")
    private val krAccount = Regex("[0-9-]+")
    /** Phase 10: a UPI ID (VPA), e.g. `anna@okicici`; Paytm users have one too. */
    private val upi = Regex("^[A-Za-z0-9._-]{2,256}@[A-Za-z][A-Za-z0-9]{1,63}$")
    val types = setOf("paypal", "revolut", "venmo", "wise", "kakaopay", "iban", "kr_bank", "upi")

    /** Validates the full list and returns it normalized (trimmed, IBAN upper case without spaces). 400 VALIDATION otherwise. */
    fun validate(list: List<PaymentMethod>): List<PaymentMethod> {
        if (list.size > MAX_TOTAL) bad("at most $MAX_TOTAL payment methods")
        val out = list.mapIndexed { i, m -> normalize("[$i]", m) }
        for ((type, n) in out.groupingBy { it.type!! }.eachCount()) {
            val max = multi[type] ?: 1
            if (n > max) bad("type: at most $max $type method${if (max > 1) "s" else ""}")
        }
        return out
    }

    private fun normalize(at: String, m: PaymentMethod): PaymentMethod {
        val type = m.type?.trim()
        if (type !in types) bad("$at.type must be one of ${types.joinToString()}")
        val value = m.value?.trim().orEmpty()
        return when (type) {
            "paypal", "revolut", "venmo" -> {
                if (!username.matches(value)) bad("$at.value must be a username of 1-40 letters, digits, '.', '_' or '-'")
                PaymentMethod(type, value)
            }
            "wise" -> PaymentMethod(type, link(at, value, "https://wise.com/"))
            "kakaopay" -> PaymentMethod(type, link(at, value, "https://qr.kakaopay.com/"))
            "iban" -> {
                val iban = value.replace(" ", "").uppercase()
                if (!isValidIban(iban)) bad("$at.value is not a valid IBAN")
                val bic = m.bic?.trim()?.takeIf { it.isNotEmpty() }
                if (bic != null && bic.length != 8 && bic.length != 11) bad("$at.bic must be 8 or 11 characters")
                PaymentMethod(type, iban, holder = text(at, "holder", m.holder, 70), bic = bic)
            }
            "upi" -> {
                if (!upi.matches(value)) bad("$at.value must be a UPI ID like name@bank")
                PaymentMethod(type, value, holder = m.holder?.trim()?.takeIf { it.isNotEmpty() }?.let { text(at, "holder", it, 70) })
            }
            else -> { // kr_bank
                val digits = value.count { it.isDigit() }
                if (!krAccount.matches(value) || digits !in 8..20) bad("$at.value must be 8-20 digits (hyphens allowed)")
                PaymentMethod(type, value, holder = text(at, "holder", m.holder, 70), bank = text(at, "bank", m.bank, 30))
            }
        }
    }

    private fun link(at: String, value: String, prefix: String): String {
        if (!value.startsWith(prefix) || value.length > 200) bad("$at.value must start with $prefix and be at most 200 characters")
        return value
    }

    private fun text(at: String, field: String, v: String?, max: Int): String {
        val t = v?.trim().orEmpty()
        if (t.length !in 1..max) bad("$at.$field is required (1-$max characters)")
        return t
    }

    /** ISO 13616 mod-97: move the first 4 chars to the end, letters to 10..35, the number mod 97 must be 1. */
    fun isValidIban(iban: String): Boolean {
        if (!ibanShape.matches(iban)) return false
        val digits = (iban.substring(4) + iban.take(4)).map { if (it.isDigit()) "$it" else "${it - 'A' + 10}" }.joinToString("")
        return BigInteger(digits).mod(BigInteger.valueOf(97)) == BigInteger.ONE
    }

    private fun bad(message: String): Nothing = throw ApiException.badRequest("VALIDATION", message)
}
