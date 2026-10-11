package dev.nariinfo.evensies

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

    /** The Dart applier casts payload values, so every type Kotlin would coerce is rejected up front (docs/API.md 적용 규칙 9). */
    @Test
    fun wrongJsonTypesAreRejected() {
        val token = login("Val4")
        val group = createGroup(token)
        val id = group["id"].asString()
        val me = group["myMemberId"].asString()
        val x = UUID.randomUUID().toString()
        val p = UUID.randomUUID().toString()
        assertEquals(200, push(token, id, expenseCreated(me, 100, mapOf(me to 100), expenseId = x)).status)
        val seq = snapshot(token, id)["latestSeq"].asLong()
        fun createdPayload(vararg kv: Pair<String, Any?>) = mapOf(
            "expenseId" to UUID.randomUUID().toString(), "description" to "Taxi", "amount" to 100, "currency" to "EUR",
            "fxRateToDefault" to null, "paidBy" to me, "date" to "2026-10-10", "category" to null,
            "shares" to listOf(mapOf("memberId" to me, "amount" to 100)),
        ) + kv
        fun created(vararg kv: Pair<String, Any?>) = event("expense.created", createdPayload(*kv))
        fun updated(vararg kv: Pair<String, Any?>) = event("expense.updated", mapOf("expenseId" to x, "fields" to mapOf(*kv)))
        fun payment(vararg kv: Pair<String, Any?>) = event("payment.created", mapOf("paymentId" to p, "fromMember" to me,
            "toMember" to me, "amount" to 100, "currency" to "EUR", "date" to "2026-10-11") + kv)
        val comment = mapOf("commentId" to UUID.randomUUID().toString(), "expenseId" to x, "authorMemberId" to me, "text" to "Hi",
            "createdAt" to "2026-10-11T09:00:00Z")
        val bad = listOf(
            created("category" to 5), created("description" to 123), created("currency" to 5), created("paidBy" to 5),
            created("date" to 20261010), created("amount" to "100", "shares" to emptyList<Any>()), created("amount" to 100.5),
            created("amount" to null, "shares" to emptyList<Any>()), created("shares" to null),
            event("expense.created", createdPayload("shares" to emptyList<Any>()) - "amount"), event("expense.created", createdPayload() - "shares"),
            created("fxRateToDefault" to "1.2"), created("shares" to "all"), created("shares" to listOf("me")),
            created("shares" to listOf(mapOf("memberId" to 5, "amount" to 100))),
            created("shares" to listOf(mapOf("memberId" to me, "amount" to "100"))),
            created("shares" to listOf(mapOf("memberId" to me))),
            created("deleted" to true), created("deleted" to "no"), created("description" to "x".repeat(201)),
            updated("category" to 5), updated("description" to 123), updated("fxRateToDefault" to "1.2"), updated("amount" to "100"),
            updated("paidBy" to 5), updated("date" to 20261010), updated("currency" to true), updated("description" to "x".repeat(201)),
            updated("amount" to 100.5), updated("shares" to listOf(mapOf("memberId" to me, "amount" to null))),
            payment("amount" to 100.5), payment("deleted" to true),
            event("comment.added", comment + ("deleted" to true)),
            event("member.added", mapOf("memberId" to UUID.randomUUID().toString(), "name" to 5, "userId" to null)),
            event("group.updated", mapOf("name" to 5)),
        )
        for (e in bad) {
            val res = push(token, id, e)
            assertEquals(400 to "VALIDATION", res.status to res.code(), "${e["payload"]}: ${res.text}")
        }
        assertEquals(seq, snapshot(token, id)["latestSeq"].asLong(), "nothing stored")

        // null keeps (or, for category/fxRateToDefault/notes, clears) the value; the limits themselves pass
        assertEquals(200, push(token, id,
            updated("description" to null, "amount" to null, "category" to null, "fxRateToDefault" to null, "shares" to null),
            updated("description" to "x".repeat(200)),
            created("description" to "😀".repeat(100), "deleted" to false, "fxRateToDefault" to 1),
        ).status)
        val after = snapshot(token, id)["expenses"].values().first { it["id"].asString() == x }
        assertEquals("x".repeat(200), after["description"].asString())
        assertEquals(100, after["amount"].asLong())
    }

    /**
     * One active member per user (docs/API.md `member.linked`): otherwise one event lets a member re-link someone else's
     * member to themselves, then write and delete comments and confirm payments in their name and lock them out.
     */
    @Test
    fun aMemberCannotTakeOverAnotherMember() {
        val anna = login("Val5-anna")
        val mallory = login("Val5-mallory")
        val group = createGroup(anna)
        val id = group["id"].asString()
        val annaMember = group["myMemberId"].asString()
        val malloryMember = join(mallory, group, "Mallory")
        val malloryId = myId(mallory)
        val placeholder = UUID.randomUUID().toString()
        assertEquals(200, push(anna, id, memberAdded("Dario", memberId = placeholder)).status)
        val seq = snapshot(anna, id)["latestSeq"].asLong()

        fun linked(memberId: String) = event("member.linked", mapOf("memberId" to memberId, "userId" to malloryId))
        val comment = event("comment.added", mapOf("commentId" to UUID.randomUUID().toString(), "expenseId" to UUID.randomUUID().toString(),
            "authorMemberId" to annaMember, "text" to "I owe Mallory", "createdAt" to "2026-10-11T09:00:00Z"))
        for (attempt in listOf(
            listOf(linked(annaMember), comment),         // someone else's member
            listOf(linked(placeholder)),                 // a second member for a user who already has one
            listOf(memberAdded("Mallory 2", userId = malloryId)),
        )) {
            val res = push(mallory, id, *attempt.toTypedArray())
            assertEquals(400 to "MEMBER_TAKEN", res.status to res.code(), res.text)
        }
        assertEquals(seq, snapshot(anna, id)["latestSeq"].asLong(), "nothing stored")
        assertEquals(annaMember, http.get("/groups/$id", anna).body["myMemberId"].asString(), "Anna keeps her member")
        assertEquals(malloryMember, http.get("/groups/$id", mallory).body["myMemberId"].asString())

        // the join flow still links a free placeholder for a user who is not in the group yet
        val dario = login("Val5-dario")
        val res = http.post("/invites/${group["inviteCode"].asString()}/join", mapOf("memberId" to placeholder), dario)
        assertEquals(200, res.status, res.text)
        assertEquals(placeholder, res.body["myMemberId"].asString())
    }
}
