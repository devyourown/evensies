package dev.nariinfo.tally

import org.junit.jupiter.api.Test
import java.util.UUID
import kotlin.test.assertEquals

class EventValidationTest : IntegrationTestBase() {
    @Test
    fun foreignMemberIdIsRejectedAndNothingStored() {
        val token = login("Val1")
        val group = createGroup(token)
        val id = group["id"].asString()
        val me = group["myMemberId"].asString()
        val other = createGroup(token, "Other")["myMemberId"].asString()
        // first event is valid, second refers to a member of another group: whole batch rejected
        val res = push(token, id, memberAdded("Ok"), expenseCreated(me, 100, mapOf(other to 100)))
        assertEquals(400, res.status)
        assertEquals("UNKNOWN_MEMBER", res.code())
        assertEquals(2, http.get("/groups/$id/events?after=0", token).body["latestSeq"].asLong())
        assertEquals(1, snapshot(token, id)["members"].size())
    }

    @Test
    fun sumMismatchNegativeCurrencyAndType() {
        val token = login("Val2")
        val group = createGroup(token)
        val id = group["id"].asString()
        val me = group["myMemberId"].asString()
        val mismatch = push(token, id, expenseCreated(me, 1000, mapOf(me to 999)))
        assertEquals(400, mismatch.status)
        assertEquals("SUM_MISMATCH", mismatch.code())
        assertEquals("NEGATIVE_AMOUNT", push(token, id, expenseCreated(me, -1, mapOf(me to -1))).code())
        assertEquals("UNKNOWN_CURRENCY", push(token, id, expenseCreated(me, 10, mapOf(me to 10), currency = "XXX")).code())
        assertEquals("UNKNOWN_TYPE", push(token, id, event("expense.exploded", mapOf("expenseId" to UUID.randomUUID().toString()))).code())
        assertEquals("VALIDATION", push(token, id, expenseCreated("not-a-uuid", 10, mapOf(me to 10)).let {
            event("expense.created", mapOf("expenseId" to "nope", "description" to "x", "amount" to 10, "currency" to "EUR",
                "paidBy" to me, "date" to "2026-10-10", "shares" to listOf(mapOf("memberId" to me, "amount" to 10))))
        }).code())
        assertEquals(400, http.post("/groups/$id/events", "[{\"clientId\":\"x\"}]", token).status)
        // update that would break the sum is rejected too
        val x = UUID.randomUUID().toString()
        push(token, id, expenseCreated(me, 100, mapOf(me to 100), expenseId = x))
        val badUpdate = push(token, id, event("expense.updated", mapOf("expenseId" to x, "fields" to mapOf("amount" to 200))))
        assertEquals("SUM_MISMATCH", badUpdate.code())
        assertEquals(3, snapshot(token, id)["latestSeq"].asLong())
    }

    @Test
    fun cannotLinkSomeoneElse() {
        val token = login("Val3")
        val id = createGroup(token)["id"].asString()
        val res = push(token, id, memberAdded("Imposter", userId = UUID.randomUUID().toString()))
        assertEquals(403, res.status)
    }
}
