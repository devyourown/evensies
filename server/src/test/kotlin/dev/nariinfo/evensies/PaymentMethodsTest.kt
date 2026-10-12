package dev.nariinfo.evensies

import org.junit.jupiter.api.Test
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class PaymentMethodsTest : IntegrationTestBase() {
    private fun put(token: String, vararg methods: Map<String, Any?>) = http.put("/me/payment-methods", methods.toList(), token)

    private fun assertInvalid(token: String, method: Map<String, Any?>, field: String) {
        val res = put(token, method)
        assertEquals(400, res.status, "$method should be rejected: ${res.text}")
        assertEquals("VALIDATION", res.code())
        assertTrue(res.body["message"].asString().contains(field), "message names $field: ${res.text}")
    }

    @Test
    fun roundTripAndNormalization() {
        val t = login("Pm-roundtrip")
        assertEquals(0, http.get("/me/payment-methods", t).body.size())
        val res = put(
            t,
            mapOf("type" to "paypal", "value" to "anna.b"),
            mapOf("type" to "iban", "value" to "de89 3704 0044 0532 0130 00", "holder" to "Anna B", "bic" to "COBADEFFXXX"),
            mapOf("type" to "kr_bank", "value" to "110-123-456789", "bank" to "신한", "holder" to "김안나"),
        )
        assertEquals(200, res.status, res.text)
        val got = http.get("/me/payment-methods", t).body
        assertEquals(SharedJson.canon(res.body), SharedJson.canon(got))
        assertEquals(3, got.size())
        assertEquals("DE89370400440532013000", got[1]["value"].asString())
        assertTrue(!got[0].has("holder"), "absent optional fields are omitted")
        // full replace
        assertEquals(200, put(t, mapOf("type" to "venmo", "value" to "anna")).status)
        assertEquals(listOf("venmo"), http.get("/me/payment-methods", t).body.values().map { it["type"].asString() })
        assertEquals(200, http.put("/me/payment-methods", emptyList<Any>(), t).status)
        assertEquals(0, http.get("/me/payment-methods", t).body.size())
    }

    @Test
    fun eachTypeValidAndInvalid() {
        val t = login("Pm-types")
        val valid = listOf(
            mapOf("type" to "paypal", "value" to "anna_b-1.x"),
            mapOf("type" to "revolut", "value" to "annab"),
            mapOf("type" to "venmo", "value" to "Anna-B"),
            mapOf("type" to "wise", "value" to "https://wise.com/pay/me/annab"),
            mapOf("type" to "kakaopay", "value" to "https://qr.kakaopay.com/Ej8abc123"),
            mapOf("type" to "iban", "value" to "DE89370400440532013000", "holder" to "Anna"),
            mapOf("type" to "kr_bank", "value" to "12345678", "bank" to "KB", "holder" to "Anna"),
        )
        for (m in valid) assertEquals(200, put(t, m).status, "$m should be valid")
        assertEquals(200, put(t, *valid.toTypedArray()).status)

        assertInvalid(t, mapOf("type" to "bitcoin", "value" to "x"), "type")
        assertInvalid(t, mapOf("value" to "x"), "type")
        assertInvalid(t, mapOf("type" to "paypal", "value" to "anna b"), "value")
        assertInvalid(t, mapOf("type" to "revolut", "value" to "a".repeat(41)), "value")
        assertInvalid(t, mapOf("type" to "venmo", "value" to ""), "value")
        assertInvalid(t, mapOf("type" to "wise", "value" to "https://evil.com/wise.com/"), "value")
        assertInvalid(t, mapOf("type" to "wise", "value" to "https://wise.com/" + "a".repeat(200)), "value")
        assertInvalid(t, mapOf("type" to "kakaopay", "value" to "https://kakaopay.com/x"), "value")
        assertInvalid(t, mapOf("type" to "iban", "value" to "DE89370400440532013001", "holder" to "Anna"), "value")
        assertInvalid(t, mapOf("type" to "iban", "value" to "DE89370400440532013000"), "holder")
        assertInvalid(t, mapOf("type" to "iban", "value" to "DE89370400440532013000", "holder" to "A".repeat(71)), "holder")
        assertInvalid(t, mapOf("type" to "iban", "value" to "DE89370400440532013000", "holder" to "Anna", "bic" to "COBADEF"), "bic")
        assertInvalid(t, mapOf("type" to "kr_bank", "value" to "1234-567", "bank" to "KB", "holder" to "Anna"), "value")
        assertInvalid(t, mapOf("type" to "kr_bank", "value" to "1".repeat(21), "bank" to "KB", "holder" to "Anna"), "value")
        assertInvalid(t, mapOf("type" to "kr_bank", "value" to "1234 5678", "bank" to "KB", "holder" to "Anna"), "value")
        assertInvalid(t, mapOf("type" to "kr_bank", "value" to "12345678", "holder" to "Anna"), "bank")
        assertInvalid(t, mapOf("type" to "kr_bank", "value" to "12345678", "bank" to "KB"), "holder")
        // a failed PUT leaves the stored list alone
        assertEquals(7, http.get("/me/payment-methods", t).body.size())
    }

    @Test
    fun limits() {
        val t = login("Pm-limits")
        fun iban() = mapOf("type" to "iban", "value" to "DE89370400440532013000", "holder" to "Anna")
        fun kr() = mapOf("type" to "kr_bank", "value" to "12345678", "bank" to "KB", "holder" to "Anna")
        val paypal = mapOf("type" to "paypal", "value" to "anna")
        val venmo = mapOf("type" to "venmo", "value" to "anna")
        assertEquals(200, put(t, iban(), iban(), iban(), kr(), kr(), kr(), paypal, venmo).status) // 8 total
        assertEquals("VALIDATION", put(t, iban(), iban(), iban(), kr(), kr(), kr(), paypal, venmo, mapOf("type" to "revolut", "value" to "a")).code())
        assertEquals("VALIDATION", put(t, iban(), iban(), iban(), iban()).code())
        assertEquals("VALIDATION", put(t, kr(), kr(), kr(), kr()).code())
        assertEquals("VALIDATION", put(t, paypal, paypal).code())
    }

    @Test
    fun visibility() {
        val anna = login("Pm-vis-anna")
        val ben = login("Pm-vis-ben")
        val carl = login("Pm-vis-carl")
        val stranger = login("Pm-vis-stranger")
        for (t in listOf(anna, ben, carl, stranger)) assertEquals(200, put(t, mapOf("type" to "paypal", "value" to "x")).status)
        val group = createGroup(anna)
        val id = group["id"].asString()
        val annaMember = group["myMemberId"].asString()
        val code = group["inviteCode"].asString()
        val benMember = UUID.randomUUID().toString()
        val carlMember = UUID.randomUUID().toString()
        http.post("/invites/$code/join", mapOf("newMemberId" to benMember, "name" to "Ben"), ben)
        http.post("/invites/$code/join", mapOf("newMemberId" to carlMember, "name" to "Carl"), carl)
        assertEquals(200, push(anna, id, memberAdded("Placeholder")).status)
        assertEquals(200, push(anna, id, event("member.removed", mapOf("memberId" to carlMember))).status)

        val res = http.get("/groups/$id/payment-methods", ben)
        assertEquals(200, res.status, res.text)
        assertEquals(setOf(annaMember, benMember), res.body.propertyNames().toSet())
        assertEquals("paypal", res.body[annaMember][0]["type"].asString())

        assertEquals(403, http.get("/groups/$id/payment-methods", stranger).status)

        // account deletion removes the methods
        assertEquals(204, http.delete("/me", ben).status)
        assertEquals(setOf(annaMember), http.get("/groups/$id/payment-methods", anna).body.propertyNames().toSet())
    }

    /** Phase 10: UPI (India; Paytm users have one too), one per user, `holder` optional. */
    @Test
    fun upi() {
        val t = login("Pm-upi-${UUID.randomUUID().toString().take(6)}")
        val ok = put(t, mapOf("type" to "upi", "value" to " anna.b-1@okicici ", "holder" to " Anna B "))
        assertEquals(200, ok.status, ok.text)
        assertEquals("anna.b-1@okicici", ok.body[0]["value"].asString())
        assertEquals("Anna B", ok.body[0]["holder"].asString())
        assertEquals(200, put(t, mapOf("type" to "upi", "value" to "9876543210@paytm")).status)
        assertTrue(!http.get("/me/payment-methods", t).body[0].has("holder"), "holder is optional")
        for (bad in listOf("anna", "a@okicici", "anna@", "anna@1bank", "anna@ok icici", "an na@okicici", "anna@o", "anna@okicici@x")) {
            assertInvalid(t, mapOf("type" to "upi", "value" to bad), "UPI")
        }
        assertInvalid(t, mapOf("type" to "upi", "value" to "anna@okicici", "holder" to "x".repeat(71)), "holder")
        val two = put(t, mapOf("type" to "upi", "value" to "anna@okicici"), mapOf("type" to "upi", "value" to "anna@okaxis"))
        assertEquals(400 to "VALIDATION", two.status to two.code(), "one UPI ID per user")
    }
}
