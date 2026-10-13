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
        // a non-canonical form of an existing id misses it in the state but would overwrite its row (no LWW, no delete-wins)
        assertEquals("VALIDATION", push(token, id, expenseCreated(me, 300, mapOf(me to 300), expenseId = x.uppercase())).code())
        assertEquals("VALIDATION", push(token, id, event("expense.deleted", mapOf("expenseId" to "1-1-1-1-1"))).code())
        assertEquals(3, snapshot(token, id)["latestSeq"].asLong())
    }

    @Test
    fun cannotLinkSomeoneElse() {
        val token = login("Val3")
        val id = createGroup(token)["id"].asString()
        val res = push(token, id, memberAdded("Imposter", userId = UUID.randomUUID().toString()))
        assertEquals(403, res.status)
    }

    /** The Dart applier casts payload values, so every type Kotlin would coerce is rejected up front (docs/API.md rule 9). */
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
            created("date" to "+10000-01-01"), updated("date" to "+10000-01-01"), payment("date" to "+10000-01-01"),
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

    /** Phase 3 (docs/API.md "Payer, split and group settings validation"): one assertion per code, the whole batch is refused, nothing stored. */
    @Test
    fun payersSplitAndGroupSettingsAreValidated() {
        val token = login("Val6")
        val group = createGroup(token)
        val id = group["id"].asString()
        val me = group["myMemberId"].asString()
        val ben = UUID.randomUUID().toString()
        val removed = UUID.randomUUID().toString()
        val x = UUID.randomUUID().toString()
        val gone = UUID.randomUUID().toString()
        assertEquals(200, push(token, id, memberAdded("Ben", ben), memberAdded("Old", removed),
            event("member.removed", mapOf("memberId" to removed)),
            expenseCreated(me, 1000, mapOf(me to 500, ben to 500), expenseId = x),
            expenseCreated(me, 100, mapOf(me to 100), expenseId = gone), event("expense.deleted", mapOf("expenseId" to gone))).status)
        val foreign = createGroup(token, "Other")["myMemberId"].asString() // cross-group ids are unknown members here
        val seq = snapshot(token, id)["latestSeq"].asLong()

        fun created(vararg kv: Pair<String, Any?>) = expenseCreated(me, 1000, mapOf(me to 500, ben to 500), extra = mapOf(*kv))
        fun updated(vararg kv: Pair<String, Any?>) = expenseUpdated(x, *kv)
        fun settings(vararg kv: Pair<String, Any?>) = event("group.updated", mapOf(*kv))
        fun split(mode: String, input: Map<String, Any?>?) = mapOf("mode" to mode, "input" to input)
        val bad = listOf(
            "PAYERS_SUM_MISMATCH" to created("payers" to lines(mapOf(me to 600, ben to 300))),
            "PAYERS_SUM_MISMATCH" to updated("payers" to lines(mapOf(me to 999))),
            "UNKNOWN_MEMBER" to created("payers" to lines(mapOf(me to 500, foreign to 500))),
            "UNKNOWN_MEMBER" to created("split" to split("shares", mapOf(me to 1, foreign to 1))),
            "UNKNOWN_MEMBER" to settings("defaultSplit" to split("shares", mapOf(foreign to 1))),
            "NEGATIVE_AMOUNT" to created("payers" to lines(mapOf(me to 1100, ben to -100))),
            "SUM_MISMATCH" to settings("defaultSplit" to split("percent", mapOf(me to 60, ben to 50))),
            "VALIDATION" to created("payers" to emptyList<Any>()),
            "VALIDATION" to created("payers" to "me"),
            "VALIDATION" to created("payers" to listOf(mapOf("memberId" to me, "amount" to 1000.5))),
            "VALIDATION" to created("payers" to listOf(mapOf("memberId" to 5, "amount" to 1000))),
            "VALIDATION" to created("payers" to listOf(mapOf("memberId" to me, "amount" to 500), mapOf("memberId" to me, "amount" to 500))),
            "VALIDATION" to updated("payers" to emptyList<Any>()),
            "VALIDATION" to created("refund" to "yes"),
            "VALIDATION" to updated("refund" to 1),
            "VALIDATION" to created("split" to "equal"),
            "VALIDATION" to created("split" to split("exact", mapOf(me to 500))),
            "VALIDATION" to created("split" to split("itemized", mapOf(me to 500))),
            "VALIDATION" to created("split" to split("equal", mapOf(me to 1))),
            "VALIDATION" to created("split" to mapOf("mode" to "percent")),
            "VALIDATION" to created("split" to split("percent", null)),
            "VALIDATION" to created("split" to split("shares", mapOf(me to "1"))),
            "VALIDATION" to created("split" to split("percent", mapOf(me to -10, ben to 110))),
            "VALIDATION" to created("split" to split("shares", mapOf(me to -1))),
            "VALIDATION" to created("split" to split("adjustment", mapOf(me to 10.5))),
            "VALIDATION" to updated("split" to listOf("equal")),
            "VALIDATION" to settings("defaultSplit" to split("equal", null)),
            "VALIDATION" to settings("defaultSplit" to split("adjustment", mapOf(me to 100))),
            "VALIDATION" to settings("defaultSplit" to split("shares", mapOf(me to 0, ben to 0))),
            "VALIDATION" to settings("defaultSplit" to "shares"),
            "VALIDATION" to settings("simplifyDebts" to null),
            "VALIDATION" to settings("simplifyDebts" to "false"),
            // an update of a deleted expense is ignored (rule 3), so only the types are checked
            "VALIDATION" to expenseUpdated(gone, "payers" to "me"),
        )
        for ((code, e) in bad) {
            val res = push(token, id, memberAdded("Batch mate"), e)
            assertEquals(400 to code, res.status to res.code(), "${e["payload"]}: ${res.text}")
        }
        assertEquals(seq, snapshot(token, id)["latestSeq"].asLong(), "nothing stored")

        // what passes: null payers/refund are ignored, Dart's 1000.0 is a whole adjustment, a removed member is a member,
        // percent within 0.001 of 100, unknown keys in a split, and a deleted expense's payers that don't add up
        val ok = push(token, id,
            created("payers" to null, "refund" to null, "split" to null),
            created("split" to split("adjustment", mapOf(me to 1000.0, ben to -1000))),
            created("split" to mapOf("mode" to "shares", "input" to mapOf(me to 1.5, removed to 0), "note" to "kept")),
            created("payers" to lines(mapOf(me to 500, removed to 500))),
            updated("payers" to null, "refund" to null),
            settings("defaultSplit" to split("percent", mapOf(me to 33.3333, ben to 33.3333, removed to 33.3333))),
            settings("defaultSplit" to null, "simplifyDebts" to false),
            expenseUpdated(gone, "payers" to lines(mapOf(me to 1)), "amount" to 5),
        )
        assertEquals(200, ok.status, ok.text)
        val kept = snapshot(token, id)["expenses"].values().first { it["split"]?.get("note") != null }
        assertEquals("kept", kept["split"]["note"].asString())
    }

    /**
     * Phase 2 clients don't know payers: their amount-and-shares edit still works on a single-payer expense (the payer
     * follows, rule 10c) but can't silently break a multi-payer one (rule 10d → PAYERS_SUM_MISMATCH).
     */
    @Test
    fun legacyAmountUpdates() {
        val token = login("Val7")
        val group = createGroup(token)
        val id = group["id"].asString()
        val me = group["myMemberId"].asString()
        val ben = UUID.randomUUID().toString()
        val single = UUID.randomUUID().toString()
        val multi = UUID.randomUUID().toString()
        assertEquals(200, push(token, id, memberAdded("Ben", ben),
            expenseCreated(me, 1000, mapOf(me to 500, ben to 500), expenseId = single),
            expenseCreated(me, 1000, mapOf(me to 500, ben to 500), expenseId = multi, extra = mapOf("payers" to lines(mapOf(me to 600, ben to 400))))).status)

        assertEquals(200, push(token, id, expenseUpdated(single, "amount" to 2000, "shares" to lines(mapOf(me to 1000, ben to 1000)))).status)
        val s = snapshot(token, id)["expenses"].values().first { it["id"].asString() == single }
        assertEquals(SharedJson.canon(lines(mapOf(me to 2000))), SharedJson.canon(s["payers"]))

        for (fields in listOf(arrayOf("amount" to 2000), arrayOf("amount" to 2000, "shares" to lines(mapOf(me to 1000, ben to 1000))))) {
            val res = push(token, id, expenseUpdated(multi, *fields))
            assertEquals(400 to "PAYERS_SUM_MISMATCH", res.status to res.code(), res.text)
        }
        // a legacy paidBy edit collapses the payers to one (rule 10b), and the app's full money update passes
        assertEquals(200, push(token, id, expenseUpdated(multi, "paidBy" to ben, "amount" to 1000)).status)
        assertEquals(200, push(token, id, expenseUpdated(multi, "amount" to 2000, "paidBy" to me, "payers" to lines(mapOf(me to 1200, ben to 800)),
            "shares" to lines(mapOf(me to 1000, ben to 1000)), "split" to null, "refund" to false)).status)
        val m = snapshot(token, id)["expenses"].values().first { it["id"].asString() == multi }
        assertEquals(SharedJson.canon(lines(mapOf(me to 1200, ben to 800))), SharedJson.canon(m["payers"]))
        assertEquals(me, m["paidBy"].asString())
    }

    /**
     * Amounts are capped (docs/API.md "Event types and payloads: amount cap"), so Σ payers or Σ shares can't wrap around in Long arithmetic and
     * match the amount; group and member names are at most 100 UTF-16 units, in events and POST /groups.
     */
    @Test
    fun amountsAndNamesAreBounded() {
        val token = login("Val9")
        val group = createGroup(token)
        val id = group["id"].asString()
        val me = group["myMemberId"].asString()
        val ben = UUID.randomUUID().toString()
        val cara = UUID.randomUUID().toString()
        assertEquals(200, push(token, id, memberAdded("Ben", ben), memberAdded("Cara", cara)).status)
        val seq = snapshot(token, id)["latestSeq"].asLong()
        val max = Long.MAX_VALUE
        val cap = 10_000_000_000_000L
        for (e in listOf(
            expenseCreated(me, 1000, mapOf(me to 1000), extra = mapOf("payers" to lines(mapOf(me to max, ben to max, cara to 1002)))),
            expenseCreated(me, 1000, mapOf(me to max, ben to max, cara to 1002)),
            expenseCreated(me, cap + 1, mapOf(me to cap + 1)),
            event("payment.created", mapOf("paymentId" to UUID.randomUUID().toString(), "fromMember" to me, "toMember" to ben,
                "amount" to cap + 1, "currency" to "EUR", "date" to "2026-10-11")),
            event("group.updated", mapOf("name" to "x".repeat(101))),
            memberAdded("x".repeat(101)),
        )) {
            val res = push(token, id, e)
            assertEquals(400 to "VALIDATION", res.status to res.code(), "${e["payload"]}: ${res.text}")
        }
        assertEquals(seq, snapshot(token, id)["latestSeq"].asLong(), "nothing stored")
        assertEquals(200, push(token, id, expenseCreated(me, cap, mapOf(me to cap)), event("group.updated", mapOf("name" to "x".repeat(100)))).status)
        assertEquals(200, push(token, id, memberAdded("😀".repeat(50))).status, "100 UTF-16 units")

        val longId = UUID.randomUUID().toString()
        val long = http.post("/groups", mapOf("id" to longId, "name" to "x".repeat(101), "defaultCurrency" to "EUR",
            "memberId" to UUID.randomUUID().toString(), "memberName" to "Me"), token)
        assertEquals(400 to "VALIDATION", long.status to long.code(), long.text)
        assertEquals(404, http.get("/groups/$longId", token).status, "the group row is rolled back")
        val longMember = http.post("/groups", mapOf("id" to longId, "name" to "Trip", "defaultCurrency" to "EUR",
            "memberId" to UUID.randomUUID().toString(), "memberName" to "x".repeat(101)), token)
        assertEquals(400 to "VALIDATION", longMember.status to longMember.code(), longMember.text)
    }

    /** Rule 12: a late currency change is stored with 200 but not applied; other keys in the event still are. */
    @Test
    fun defaultCurrencyLocksAfterTheFirstExpenseOrPayment() {
        val token = login("Val8")
        val group = createGroup(token)
        val id = group["id"].asString()
        val me = group["myMemberId"].asString()
        assertEquals(200, push(token, id, event("group.updated", mapOf("defaultCurrency" to "USD"))).status)
        assertEquals("USD", http.get("/groups/$id", token).body["defaultCurrency"].asString(), "no expenses yet: applies")
        assertEquals("UNKNOWN_CURRENCY", push(token, id, event("group.updated", mapOf("defaultCurrency" to "XXX"))).code())

        val x = UUID.randomUUID().toString()
        assertEquals(200, push(token, id, expenseCreated(me, 100, mapOf(me to 100), expenseId = x, currency = "USD"),
            event("expense.deleted", mapOf("expenseId" to x))).status)
        val res = push(token, id, event("group.updated", mapOf("name" to "Japan", "defaultCurrency" to "JPY", "simplifyDebts" to false)))
        assertEquals(200, res.status, res.text)
        val snap = snapshot(token, id)
        assertEquals("USD", snap["group"]["defaultCurrency"].asString(), "a deleted expense still locks it")
        assertEquals("Japan", snap["group"]["name"].asString())
        assertEquals(false, snap["group"]["simplifyDebts"].asBoolean())
        val stored = http.get("/groups/$id/events?after=0", token).body["events"].values().last()
        assertEquals("JPY", stored["payload"]["defaultCurrency"].asString(), "the event is stored as sent")
    }
}
