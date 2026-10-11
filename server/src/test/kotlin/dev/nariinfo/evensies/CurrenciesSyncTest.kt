package dev.nariinfo.evensies

import org.junit.jupiter.api.Test
import tools.jackson.databind.JsonNode
import tools.jackson.databind.util.RawValue
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Phase 4 over real HTTP (docs/API.md "통화 환산"): the 155-code list, fxRateToDefault stored exactly as sent (0 kept,
 * null clears, a missing key keeps), and the Convert push (one expense.updated per unconverted expense).
 */
class CurrenciesSyncTest : IntegrationTestBase() {
    private fun uuid() = UUID.randomUUID().toString()

    private fun expense(token: String, groupId: String, id: String): JsonNode =
        snapshot(token, groupId)["expenses"].values().first { it["id"].asString() == id }

    private fun rate(token: String, groupId: String, id: String): JsonNode = expense(token, groupId, id)["fxRateToDefault"]

    @Test
    fun theNewCodesAreAcceptedAndCodesAreCaseSensitive() {
        val token = login("Cur-codes")
        val group = createGroup(token, currency = "OMR")
        assertEquals("OMR", group["defaultCurrency"].asString())
        val id = group["id"].asString()
        val me = group["myMemberId"].asString()
        val x = uuid()
        val ok = push(token, id, expenseCreated(me, 1500, mapOf(me to 1500), expenseId = x, currency = "XOF", extra = mapOf("fxRateToDefault" to 0.000588)))
        assertEquals(200, ok.status, ok.text)
        assertEquals("XOF", expense(token, id, x)["currency"].asString())
        assertEquals(200, push(token, id, expenseUpdated(x, "currency" to "ZAR", "fxRateToDefault" to 0.0214)).status)

        for (code in listOf("xof", "XAU", "CNH", "XDR", "Zar")) {
            assertEquals("UNKNOWN_CURRENCY", push(token, id, expenseCreated(me, 10, mapOf(me to 10), currency = code)).code(), code)
            assertEquals("UNKNOWN_CURRENCY", push(token, id, expenseUpdated(x, "currency" to code)).code(), code)
        }
        val cnh = http.post("/groups", mapOf("id" to uuid(), "name" to "Bad", "defaultCurrency" to "CNH", "memberId" to uuid(), "memberName" to "Me"), token)
        assertEquals("UNKNOWN_CURRENCY", cnh.code())
    }

    @Test
    fun theRateIsStoredAsSent() {
        val token = login("Cur-rate")
        val group = createGroup(token)
        val id = group["id"].asString()
        val me = group["myMemberId"].asString()
        val x = uuid()
        assertEquals(200, push(token, id, expenseCreated(me, 1000, mapOf(me to 1000), expenseId = x, currency = "JPY",
            extra = mapOf("fxRateToDefault" to 0.00616))).status)
        assertEquals(0.00616, rate(token, id, x).asDouble())

        assertEquals(200, push(token, id, expenseUpdated(x, "fxRateToDefault" to 0)).status, "0 is accepted (older clients)")
        assertTrue(rate(token, id, x).isNumber, "0 is stored as 0, not cleared")
        assertEquals(0.0, rate(token, id, x).asDouble())

        assertEquals(200, push(token, id, expenseUpdated(x, "currency" to "JPY", "fxRateToDefault" to 0.0056)).status)
        assertEquals(200, push(token, id, expenseUpdated(x, "description" to "Ramen")).status)
        assertEquals(0.0056, rate(token, id, x).asDouble(), "an update without the key keeps the rate")

        assertEquals(200, push(token, id, expenseUpdated(x, "currency" to "EUR", "fxRateToDefault" to null)).status)
        val back = expense(token, id, x)
        assertEquals("EUR", back["currency"].asString())
        assertTrue(back["fxRateToDefault"].isNull, "switching back to the group currency sends null, which clears")

        val seq = snapshot(token, id)["latestSeq"].asLong()
        val negative = push(token, id, expenseUpdated(x, "fxRateToDefault" to -0.1))
        assertEquals(400, negative.status)
        assertEquals("VALIDATION", negative.code())
        assertEquals(seq, snapshot(token, id)["latestSeq"].asLong(), "nothing stored")

        // an event from before Phase 4 clients (no fxRateToDefault key at all) reads as null
        val legacy = uuid()
        val res = push(token, id, event("expense.created", mapOf("expenseId" to legacy, "description" to "Old", "amount" to 500,
            "currency" to "JPY", "paidBy" to me, "date" to "2026-10-01", "shares" to lines(mapOf(me to 500)))))
        assertEquals(200, res.status, res.text)
        assertTrue(rate(token, id, legacy).isNull)
    }

    /**
     * `1e999` parses as a Double Infinity that passes `isNumber` but is stored as the string "Infinity", which stops
     * the Dart applier and snapshot parser for the whole group. Rejected in created and updated events alike, also when
     * the update targets an unknown expense (stored and ignored otherwise).
     */
    @Test
    fun aNonFiniteRateIsRejected() {
        val token = login("Cur-inf")
        val group = createGroup(token)
        val id = group["id"].asString()
        val me = group["myMemberId"].asString()
        val x = uuid()
        assertEquals(200, push(token, id, expenseCreated(me, 1000, mapOf(me to 1000), expenseId = x, currency = "JPY")).status)
        val seq = snapshot(token, id)["latestSeq"].asLong()
        for (raw in listOf("1e999", "-1e400")) {
            val rate = RawValue(raw)
            for (e in listOf(
                expenseCreated(me, 1000, mapOf(me to 1000), currency = "JPY", extra = mapOf("fxRateToDefault" to rate)),
                expenseUpdated(x, "fxRateToDefault" to rate),
                expenseUpdated(uuid(), "fxRateToDefault" to rate),
            )) {
                val res = push(token, id, e)
                assertEquals(400, res.status, "$raw: ${res.text}")
                assertEquals("VALIDATION", res.code(), raw)
            }
        }
        assertEquals(seq, snapshot(token, id)["latestSeq"].asLong(), "nothing stored")
        assertTrue(rate(token, id, x).isNull)
    }

    /**
     * Convert = one push of `expense.updated {fxRateToDefault}` per unconverted expense. A retry with the same clientIds
     * stores nothing new; outsiders get 403, and an update aimed at another group's expense id only lands (ignored) in
     * the sender's own group.
     */
    @Test
    fun convertIsOnePushIdempotentAndScopedToTheGroup() {
        val anna = login("Cur-anna")
        val ben = login("Cur-ben")
        val carla = login("Cur-carla")
        val group = createGroup(anna)
        val id = group["id"].asString()
        val a = group["myMemberId"].asString()
        val b = join(ben, group, "Ben")
        val ids = List(4) { uuid() }
        assertEquals(200, push(anna, id, *ids.mapIndexed { i, x ->
            expenseCreated(a, 1000, mapOf(a to 500, b to 500), expenseId = x, currency = "JPY", extra = mapOf("fxRateToDefault" to if (i == 0) 0 else null))
        }.toTypedArray()).status)
        val before = snapshot(anna, id)["latestSeq"].asLong()

        val convert = ids.map { expenseUpdated(it, "fxRateToDefault" to 0.00563349) }.toTypedArray()
        val res = push(anna, id, *convert)
        assertEquals(200, res.status, res.text)
        assertEquals(before + 4, res.body["latestSeq"].asLong())
        assertEquals(before + 4, push(anna, id, *convert).body["latestSeq"].asLong(), "the retry is idempotent")
        for (x in ids) assertEquals(0.00563349, rate(ben, id, x).asDouble(), "Ben pulls the same rates")

        val outsider = push(carla, id, expenseUpdated(ids[0], "fxRateToDefault" to 9.9))
        assertEquals(403, outsider.status)
        assertEquals(403, http.get("/groups/$id/snapshot", carla).status)
        val own = createGroup(carla)["id"].asString()
        assertEquals(200, push(carla, own, expenseUpdated(ids[0], "fxRateToDefault" to 9.9)).status, "unknown target: stored, ignored")
        assertEquals(0.00563349, rate(anna, id, ids[0]).asDouble(), "Anna's expense is untouched")
        assertEquals(0, snapshot(carla, own)["expenses"].size())
    }
}
