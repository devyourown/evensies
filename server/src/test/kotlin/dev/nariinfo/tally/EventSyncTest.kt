package dev.nariinfo.tally

import dev.nariinfo.tally.sync.EventApplier
import dev.nariinfo.tally.sync.GroupState
import org.junit.jupiter.api.Test
import java.util.UUID
import kotlin.test.assertEquals

class EventSyncTest : IntegrationTestBase() {
    @Test
    fun pushAssignsSeqsPullReturnsThemAndSnapshotMatchesAppliedState() {
        val token = login("Sync")
        val group = createGroup(token)
        val id = group["id"].asString()
        val me = group["myMemberId"].asString()
        val ben = UUID.randomUUID().toString()
        val events = arrayOf(
            memberAdded("Ben", ben),
            expenseCreated(paidBy = me, amount = 1000, shares = mapOf(me to 500, ben to 500)),
            event("payment.created", mapOf("paymentId" to UUID.randomUUID().toString(), "fromMember" to ben, "toMember" to me,
                "amount" to 200, "currency" to "EUR", "date" to "2026-10-11")),
        )
        val res = push(token, id, *events)
        assertEquals(200, res.status, res.text)
        assertEquals(listOf(3L, 4L, 5L), res.body["results"].values().map { it["seq"].asLong() })
        assertEquals(events.map { it["clientId"] }, res.body["results"].values().map { it["clientId"].asString() })
        assertEquals(5, res.body["latestSeq"].asLong())

        val all = http.get("/groups/$id/events?after=0", token).body
        assertEquals((1L..5L).toList(), all["events"].values().map { it["seq"].asLong() })
        assertEquals(5, all["latestSeq"].asLong())
        assertEquals(listOf(4L, 5L), http.get("/groups/$id/events?after=3", token).body["events"].values().map { it["seq"].asLong() })
        assertEquals(2, http.get("/groups/$id/events?after=0&limit=2", token).body["events"].size())

        var state = GroupState()
        for (e in all["events"]) state = EventApplier.apply(state, e["type"].asString(), e["payload"])
        val snap = snapshot(token, id)
        assertEquals(SharedJson.canon(state.members.values), SharedJson.canon(snap["members"]))
        assertEquals(SharedJson.canon(state.expenses.values), SharedJson.canon(snap["expenses"]))
        assertEquals(SharedJson.canon(state.payments.values), SharedJson.canon(snap["payments"]))
        assertEquals(5, snap["latestSeq"].asLong())
        assertEquals("Trip", snap["group"]["name"].asString())

        val export = http.get("/groups/$id/export?format=json", token).body
        assertEquals(SharedJson.canon(snap), SharedJson.canon(export))
    }

    @Test
    fun fieldLevelMergeAndDeleteWins() {
        val token = login("Merge")
        val group = createGroup(token)
        val id = group["id"].asString()
        val me = group["myMemberId"].asString()
        val x = UUID.randomUUID().toString()
        push(token, id, expenseCreated(me, 1000, mapOf(me to 1000), expenseId = x))
        // two offline edits of different fields, pushed in sequence: both survive
        push(token, id, event("expense.updated", mapOf("expenseId" to x, "fields" to mapOf("description" to "Lunch"))))
        push(token, id, event("expense.updated", mapOf("expenseId" to x, "fields" to mapOf("amount" to 1500, "shares" to listOf(mapOf("memberId" to me, "amount" to 1500))))))
        var e = snapshot(token, id)["expenses"][0]
        assertEquals("Lunch", e["description"].asString())
        assertEquals(1500, e["amount"].asLong())
        // delete beats a later update
        push(token, id, event("expense.deleted", mapOf("expenseId" to x)))
        push(token, id, event("expense.updated", mapOf("expenseId" to x, "fields" to mapOf("description" to "Zombie"))))
        e = snapshot(token, id)["expenses"][0]
        assertEquals(true, e["deleted"].asBoolean())
        assertEquals("Lunch", e["description"].asString())
    }

    @Test
    fun duplicatePushReturnsSameSeq() {
        val token = login("Dup")
        val group = createGroup(token)
        val id = group["id"].asString()
        val me = group["myMemberId"].asString()
        val batch = arrayOf(expenseCreated(me, 700, mapOf(me to 700)), memberAdded("Ben"))
        val first = push(token, id, *batch)
        val second = push(token, id, *batch)
        assertEquals(200, second.status, second.text)
        assertEquals(first.body["results"], second.body["results"])
        assertEquals(first.body["latestSeq"], second.body["latestSeq"])
        val snap = snapshot(token, id)
        assertEquals(1, snap["expenses"].size())
        assertEquals(2, snap["members"].size())
        assertEquals(4, http.get("/groups/$id/events?after=0", token).body["events"].size())
    }
}
