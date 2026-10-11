package dev.nariinfo.evensies

import dev.nariinfo.evensies.sync.EventApplier
import dev.nariinfo.evensies.sync.GroupState
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import java.util.UUID
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import javax.sql.DataSource
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class EventSyncTest : IntegrationTestBase() {
    @Autowired
    private lateinit var dataSource: DataSource

    @Autowired
    private lateinit var jdbc: JdbcClient

    /**
     * The batch is validated under the group row lock: two pushes that are each valid against the state before both
     * (a payers edit, and a Phase 2 client's amount edit) can't both be stored and leave payers ≠ amount. The test holds
     * the lock until both requests wait for it, so validating before the lock would let both through.
     */
    @Test
    fun concurrentPushesAreValidatedUnderTheGroupLock() {
        val token = login("Sync-lock")
        val group = createGroup(token)
        val id = group["id"].asString()
        val me = group["myMemberId"].asString()
        val ben = UUID.randomUUID().toString()
        val x = UUID.randomUUID().toString()
        assertEquals(200, push(token, id, memberAdded("Ben", ben), expenseCreated(me, 1000, mapOf(me to 500, ben to 500), expenseId = x)).status)

        val pool = Executors.newFixedThreadPool(2)
        val results = dataSource.connection.use { lock ->
            lock.autoCommit = false
            lock.prepareStatement("SELECT id FROM groups WHERE id = ? FOR UPDATE").apply { setObject(1, UUID.fromString(id)) }.executeQuery()
            val pushes = listOf(
                expenseUpdated(x, "payers" to lines(mapOf(me to 600, ben to 400))),
                expenseUpdated(x, "amount" to 2000, "shares" to lines(mapOf(me to 1000, ben to 1000))),
            ).map { e -> pool.submit<Http.Resp> { push(token, id, e) } }
            val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(10)
            while (jdbc.sql("SELECT count(*) FROM pg_stat_activity WHERE wait_event_type = 'Lock' AND query ILIKE '%FOR UPDATE%'")
                    .query(Int::class.java).single() < 2) {
                check(System.nanoTime() < deadline) { "the pushes never waited for the lock" }
                Thread.sleep(20)
            }
            lock.commit()
            pushes.map { it.get(10, TimeUnit.SECONDS) }
        }
        pool.shutdown()
        assertEquals(listOf(200, 400), results.map { it.status }.sorted(), results.joinToString { it.text })
        assertEquals("PAYERS_SUM_MISMATCH", results.first { it.status == 400 }.code())
        val e = snapshot(token, id)["expenses"].values().first { it["id"].asString() == x }
        assertEquals(e["amount"].asLong(), e["payers"].values().sumOf { it["amount"].asLong() })
    }

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

    /**
     * Phase 3 round trip: the server rewrites a stale `paidBy` to the primary payer in the stored (pulled) payload, the
     * snapshot carries payers/refund/split and the group settings, a legacy-shape expense reads back with one payer, and
     * replaying the pulled log gives the snapshot.
     */
    @Test
    fun payersRefundSplitAndGroupSettingsRoundTrip() {
        val token = login("Sync3")
        val group = createGroup(token)
        assertEquals(true, group["simplifyDebts"].asBoolean(), "POST /groups returns the default settings")
        assertTrue(group["defaultSplit"].isNull)
        val id = group["id"].asString()
        val me = group["myMemberId"].asString()
        val ben = UUID.randomUUID().toString()
        val hotel = UUID.randomUUID().toString()
        val legacy = UUID.randomUUID().toString()
        val refund = UUID.randomUUID().toString()
        val shares = mapOf("mode" to "shares", "input" to mapOf(me to 2, ben to 1.5))
        val batch = arrayOf(
            memberAdded("Ben", ben),
            expenseCreated(me, 3000, mapOf(me to 1715, ben to 1285), expenseId = hotel, description = "Hotel",
                extra = mapOf("payers" to lines(mapOf(me to 1000, ben to 2000)), "refund" to false, "split" to shares)), // paidBy stale
            expenseCreated(ben, 800, mapOf(me to 400, ben to 400), expenseId = legacy, description = "Taxi"),        // Phase 2 shape
            expenseCreated(me, 600, mapOf(me to 300, ben to 300), expenseId = refund, description = "Refund",
                extra = mapOf("payers" to lines(mapOf(me to 600)), "refund" to true, "split" to mapOf("mode" to "equal"))),
            expenseUpdated(refund, "payers" to lines(mapOf(ben to 600))),                                            // no paidBy sent
            event("group.updated", mapOf("simplifyDebts" to false, "defaultSplit" to shares)),
        )
        val res = push(token, id, *batch)
        assertEquals(200, res.status, res.text)
        assertEquals(res.body, push(token, id, *batch).body, "idempotent retry")

        val pulled = http.get("/groups/$id/events?after=2", token).body["events"].values().toList()
        assertEquals(ben, pulled[1]["payload"]["paidBy"].asString(), "rewritten to the primary payer")
        assertEquals(ben, pulled[4]["payload"]["fields"]["paidBy"].asString(), "added to fields")
        assertEquals(ben, pulled[2]["payload"]["paidBy"].asString(), "legacy payload stored as sent")
        assertTrue(!pulled[2]["payload"].has("payers"))

        val snap = snapshot(token, id)
        val byId = snap["expenses"].values().associateBy { it["id"].asString() }
        val h = byId.getValue(hotel)
        assertEquals(SharedJson.canon(lines(mapOf(me to 1000, ben to 2000))), SharedJson.canon(h["payers"]), "payers keep the order sent")
        assertEquals(ben, h["paidBy"].asString())
        assertEquals(SharedJson.canon(shares), SharedJson.canon(h["split"]))
        assertEquals(false, h["refund"].asBoolean())
        val t = byId.getValue(legacy)
        assertEquals(SharedJson.canon(lines(mapOf(ben to 800))), SharedJson.canon(t["payers"]))
        assertEquals(false, t["refund"].asBoolean())
        assertTrue(t["split"].isNull)
        val r = byId.getValue(refund)
        assertEquals(true, r["refund"].asBoolean())
        assertEquals(ben, r["paidBy"].asString())
        assertEquals(false, snap["group"]["simplifyDebts"].asBoolean())
        assertEquals(SharedJson.canon(shares), SharedJson.canon(snap["group"]["defaultSplit"]))
        assertEquals(SharedJson.canon(snap["group"]), SharedJson.canon(http.get("/groups/$id", token).body))

        var state = GroupState()
        for (e in http.get("/groups/$id/events?after=0", token).body["events"]) state = EventApplier.apply(state, e["type"].asString(), e["payload"])
        assertEquals(SharedJson.canon(state.expenses), SharedJson.canon(byId), "snapshot rows are ordered by created_at, id")
        assertEquals(false, state.simplifyDebts)
        assertEquals(SharedJson.canon(state.defaultSplit), SharedJson.canon(snap["group"]["defaultSplit"]))

        // the joiner gets the settings too, and clearing works
        val cara = login("Sync3-cara")
        val joined = http.post("/invites/${group["inviteCode"].asString()}/join", mapOf("newMemberId" to UUID.randomUUID().toString(), "name" to "Cara"), cara)
        assertEquals(false, joined.body["simplifyDebts"].asBoolean())
        assertEquals(200, push(cara, id, event("group.updated", mapOf("defaultSplit" to null))).status)
        assertTrue(http.get("/groups/$id", token).body["defaultSplit"].isNull)
        assertEquals(false, http.get("/groups/$id", token).body["simplifyDebts"].asBoolean(), "absent key kept")
    }

    /** An event naming another group's expense is not this group's target (rule 4): stored, ignored, the other group untouched. */
    @Test
    fun payersCannotReachIntoAnotherGroup() {
        val token = login("Sync3-idor")
        val mine = createGroup(token)
        val theirsOwner = login("Sync3-idor-owner")
        val theirs = createGroup(theirsOwner)
        val theirMember = theirs["myMemberId"].asString()
        val x = UUID.randomUUID().toString()
        assertEquals(200, push(theirsOwner, theirs["id"].asString(), expenseCreated(theirMember, 500, mapOf(theirMember to 500), expenseId = x)).status)
        val before = snapshot(theirsOwner, theirs["id"].asString())

        val me = mine["myMemberId"].asString()
        val res = push(token, mine["id"].asString(), expenseUpdated(x, "amount" to 9000, "payers" to lines(mapOf(me to 9000)), "refund" to true,
            "shares" to lines(mapOf(me to 9000)), "split" to mapOf("mode" to "equal")))
        assertEquals(200, res.status, res.text)
        assertEquals(SharedJson.canon(before), SharedJson.canon(snapshot(theirsOwner, theirs["id"].asString())))
        assertEquals(403, push(token, theirs["id"].asString(), event("group.updated", mapOf("simplifyDebts" to false))).status, "non-member")
        assertEquals(0, snapshot(token, mine["id"].asString())["expenses"].size())
    }
}
