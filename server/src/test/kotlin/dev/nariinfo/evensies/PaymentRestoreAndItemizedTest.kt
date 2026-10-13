package dev.nariinfo.evensies

import org.junit.jupiter.api.Test
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Phase 7 event changes over real HTTP besides receipts: `payment.restored` and `payment.deleted.replacedBy` (rule
 * 7, parity #110) and SplitSpec mode `itemized` (docs/API.md "SplitSpec", "Payer, split and group settings validation").
 */
class PaymentRestoreAndItemizedTest : IntegrationTestBase() {
    /** Anna's group with Ben and Carla. */
    private class Setup(val id: String, val anna: String, val ben: String, val carla: String, val a: String, val b: String, val c: String)

    private fun setup(): Setup {
        val t = UUID.randomUUID().toString().take(6)
        val anna = login("Pr-anna-$t")
        val ben = login("Pr-ben-$t")
        val carla = login("Pr-carla-$t")
        val group = createGroup(anna)
        val id = group["id"].asString()
        return Setup(id, anna, ben, carla, group["myMemberId"].asString(), join(ben, group, "Ben"), join(carla, group, "Carla"))
    }

    private fun payment(id: String, from: String, to: String, status: String = "sent") = event(
        "payment.created", mapOf("paymentId" to id, "fromMember" to from, "toMember" to to, "amount" to 1500, "currency" to "EUR", "date" to "2026-10-11", "status" to status),
    )

    private fun deleted(id: String, vararg extra: Pair<String, Any?>) = event("payment.deleted", mapOf("paymentId" to id) + extra)

    private fun restored(id: Any?) = event("payment.restored", mapOf("paymentId" to id))

    private fun stored(token: String, groupId: String, id: String) = snapshot(token, groupId)["payments"].values().first { it["id"].asString() == id }

    private fun assertStatus(status: Int, code: String?, res: Http.Resp) {
        assertEquals(status, res.status, res.text)
        if (code != null) assertEquals(code, res.code(), res.text)
    }

    @Test
    fun restoreAPayment() {
        val s = setup()
        val p = UUID.randomUUID().toString()
        assertStatus(200, null, push(s.ben, s.id, payment(p, s.b, s.a)))
        assertFalse(stored(s.anna, s.id, p)["replaced"].asBoolean(), "replaced defaults to false")

        // the payer deletes and restores: back with its status (still waiting for Anna)
        assertStatus(200, null, push(s.ben, s.id, deleted(p)))
        assertStatus(200, null, push(s.ben, s.id, restored(p)))
        assertEquals(listOf(false, "sent", false), stored(s.anna, s.id, p).let { listOf(it["deleted"].asBoolean(), it["status"].asString(), it["replaced"].asBoolean()) })
        // the receiver too; Carla (neither side, not the creator) may neither delete nor restore
        assertStatus(200, null, push(s.anna, s.id, deleted(p)))
        assertStatus(403, "FORBIDDEN", push(s.carla, s.id, restored(p)))
        assertStatus(200, null, push(s.anna, s.id, restored(p)))
        assertStatus(403, "FORBIDDEN", push(s.carla, s.id, deleted(p)))
        assertStatus(403, "FORBIDDEN", push(s.carla, s.id, restored(p))) // even a no-op restore of a live payment
        // the creator of a payment between two others may restore it
        val q = UUID.randomUUID().toString()
        assertStatus(200, null, push(s.carla, s.id, payment(q, s.b, s.a, status = "confirmed")))
        assertStatus(200, null, push(s.anna, s.id, deleted(q)))
        assertStatus(200, null, push(s.carla, s.id, restored(q)))
        assertFalse(stored(s.anna, s.id, q)["deleted"].asBoolean())

        // unknown or live payments: stored, nothing changes (rule 4 / no-op); shapes are checked
        val seq = snapshot(s.anna, s.id)["latestSeq"].asLong()
        assertStatus(200, null, push(s.anna, s.id, restored(UUID.randomUUID().toString()), restored(p)))
        assertEquals(seq + 2, snapshot(s.anna, s.id)["latestSeq"].asLong())
        assertStatus(400, "VALIDATION", push(s.anna, s.id, restored("p1")))
        assertStatus(400, "VALIDATION", push(s.anna, s.id, restored(null)))

        // feed: the restore is an item, the no-ops are hidden
        val items = http.get("/groups/${s.id}/activity", s.ben).body["items"].values().toList()
        assertEquals(listOf("payment_restored", "payment_deleted", "payment_added", "payment_restored", "payment_deleted"), items.map { it["kind"].asString() }.take(5))
        assertEquals(listOf(q, s.b, s.a, "1500", "EUR", "confirmed", s.c), listOf("paymentId", "fromMember", "toMember", "amount", "currency", "status", "actorMemberId").map { items[0][it].asString() })
        // the same restore pushed again (same clientId) is a duplicate
        val again = restored(q)
        assertStatus(200, null, push(s.carla, s.id, deleted(q, "replacedBy" to null)))
        val first = push(s.carla, s.id, again)
        assertEquals(first.body["results"][0]["seq"], push(s.carla, s.id, again).body["results"][0]["seq"])
    }

    @Test
    fun anEditedPaymentStaysDeleted() {
        val s = setup()
        val p = UUID.randomUUID().toString()
        val p2 = UUID.randomUUID().toString()
        assertStatus(200, null, push(s.ben, s.id, payment(p, s.b, s.a)))
        for (bad in listOf<Any>("p2", 5, mapOf("id" to p2), true)) assertStatus(400, "VALIDATION", push(s.ben, s.id, deleted(p, "replacedBy" to bad)))
        // the edit: delete with replacedBy + the new payment, in one push
        assertStatus(200, null, push(s.ben, s.id, deleted(p, "replacedBy" to p2), payment(p2, s.b, s.a)))
        assertEquals(listOf(true, true), stored(s.anna, s.id, p).let { listOf(it["deleted"].asBoolean(), it["replaced"].asBoolean()) })
        // an offline restore of the old one is accepted and ignored, also after a plain delete; hidden in the feed
        val seq = snapshot(s.anna, s.id)["latestSeq"].asLong()
        assertStatus(200, null, push(s.anna, s.id, restored(p), deleted(p), restored(p)))
        assertEquals(seq + 3, snapshot(s.anna, s.id)["latestSeq"].asLong())
        assertEquals(listOf(true, true), stored(s.anna, s.id, p).let { listOf(it["deleted"].asBoolean(), it["replaced"].asBoolean()) })
        val kinds = http.get("/groups/${s.id}/activity", s.anna).body["items"].values().map { it["kind"].asString() }
        assertFalse("payment_restored" in kinds, "$kinds")
        assertTrue("payment_edited" in kinds && "payment_deleted" !in kinds, "$kinds") // the edit reads as one, not as a delete
        // replacedBy names a payment the server doesn't look up
        val q = UUID.randomUUID().toString()
        assertStatus(200, null, push(s.ben, s.id, payment(q, s.b, s.a), deleted(q, "replacedBy" to UUID.randomUUID().toString())))
        assertTrue(stored(s.anna, s.id, q)["replaced"].asBoolean())
    }

    private fun bill(vararg lines: Map<String, Any?>, tax: Any? = 0, tip: Any? = 0, discount: Any? = 0) =
        mapOf("lines" to lines.toList(), "tax" to tax, "tip" to tip, "discount" to discount)

    private fun line(name: Any?, amount: Any?, vararg memberIds: Any?) = mapOf("name" to name, "amount" to amount, "memberIds" to memberIds.toList())

    @Test
    fun itemizedSplits() {
        val s = setup()
        val x = UUID.randomUUID().toString()
        val good = mapOf(
            "mode" to "itemized",
            "bill" to bill(line("Burger", 1450, s.a), line("Fries to share", 700, s.a, s.b) + ("note" to "kept"), tip = 300) + ("currency" to "kept too"),
        )
        val created = expenseCreated(s.a, 2450, mapOf(s.a to 1950, s.b to 500), expenseId = x, extra = mapOf("split" to good))
        assertStatus(200, null, push(s.anna, s.id, created))
        fun split() = snapshot(s.ben, s.id)["expenses"].values().first { it["id"].asString() == x }["split"]
        assertEquals(SharedJson.canon(good), SharedJson.canon(split()), "stored as sent, other keys included")
        val pulled = http.get("/groups/${s.id}/events?after=0", s.ben).body["events"].values().last()["payload"]["split"]
        assertEquals(SharedJson.canon(good), SharedJson.canon(pulled))
        // a description edit keeps it; missing or null tax/tip/discount, a removed member and zero amounts are fine
        assertStatus(200, null, push(s.anna, s.id, expenseUpdated(x, "description" to "Dinner at Mario's")))
        assertEquals(SharedJson.canon(good), SharedJson.canon(split()))
        assertStatus(200, null, push(s.carla, s.id, event("member.removed", mapOf("memberId" to s.c))))
        val loose = mapOf("mode" to "itemized", "bill" to mapOf("lines" to listOf(line("  Water ", 0, s.c), line("Wine", 2450, s.a, s.b)), "tax" to null))
        assertStatus(200, null, push(s.anna, s.id, expenseUpdated(x, "split" to loose)))
        assertEquals(SharedJson.canon(loose), SharedJson.canon(split()))
        // another mode ignores a bill like any other key
        assertStatus(200, null, push(s.anna, s.id, expenseCreated(s.a, 100, mapOf(s.a to 100), extra = mapOf("split" to mapOf("mode" to "equal", "bill" to 5)))))

        fun spec(b: Any?, vararg extra: Pair<String, Any?>) = mapOf("mode" to "itemized", "bill" to b) + extra
        val foreign = UUID.randomUUID().toString()
        val bad = listOf(
            "VALIDATION" to spec(bill(line("Burger", 1450, s.a)), "input" to mapOf(s.a to 1)),
            "VALIDATION" to mapOf("mode" to "itemized"),
            "VALIDATION" to spec(null),
            "VALIDATION" to spec("bill"),
            "VALIDATION" to spec(mapOf("tax" to 0)),
            "VALIDATION" to spec(bill()),
            "VALIDATION" to spec(mapOf("lines" to "Burger")),
            "VALIDATION" to spec(bill(*Array(201) { line("Item $it", 10, s.a) })),
            "VALIDATION" to spec(mapOf("lines" to listOf("Burger"))),
            "VALIDATION" to spec(bill(line("", 1450, s.a))),
            "VALIDATION" to spec(bill(line("   ", 1450, s.a))),
            "VALIDATION" to spec(bill(line("x".repeat(101), 1450, s.a))),
            "VALIDATION" to spec(bill(line(5, 1450, s.a))),
            "VALIDATION" to spec(bill(line(null, 1450, s.a))),
            "VALIDATION" to spec(bill(line("Burger", -1, s.a))),
            "VALIDATION" to spec(bill(line("Burger", 14.5, s.a))),
            "VALIDATION" to spec(bill(line("Burger", "1450", s.a))),
            "VALIDATION" to spec(bill(line("Burger", null, s.a))),
            "VALIDATION" to spec(bill(line("Burger", 10_000_000_000_001L, s.a))),
            "VALIDATION" to spec(bill(line("Burger", 1450))),
            "VALIDATION" to spec(bill(line("Burger", 1450, s.a, s.a))),
            "VALIDATION" to spec(bill(line("Burger", 1450, 5))),
            "VALIDATION" to spec(mapOf("lines" to listOf(mapOf("name" to "Burger", "amount" to 1450, "memberIds" to s.a)))),
            "VALIDATION" to spec(bill(line("Burger", 1450, s.a), tax = -1)),
            "VALIDATION" to spec(bill(line("Burger", 1450, s.a), tip = 1.5)),
            "VALIDATION" to spec(bill(line("Burger", 1450, s.a), discount = "0")),
            "VALIDATION" to spec(bill(line("Burger", 1450, s.a), tax = 10_000_000_000_001L)),
            "UNKNOWN_MEMBER" to spec(bill(line("Burger", 1450, s.a, foreign))),
            "UNKNOWN_MEMBER" to spec(bill(line("Burger", 1450, "m1"))),
        )
        val seq = snapshot(s.anna, s.id)["latestSeq"].asLong()
        for ((code, spec) in bad) {
            for (e in listOf(expenseCreated(s.a, 1450, mapOf(s.a to 1450), extra = mapOf("split" to spec)), expenseUpdated(x, "split" to spec))) {
                val res = push(s.anna, s.id, e)
                assertEquals(400 to code, res.status to res.code(), "$spec: ${res.text}")
            }
        }
        // not a group default
        assertStatus(400, "VALIDATION", push(s.anna, s.id, event("group.updated", mapOf("defaultSplit" to good))))
        assertEquals(seq, snapshot(s.anna, s.id)["latestSeq"].asLong(), "nothing stored")

        // an old client's shares edit (no split key) clears it (rule 10)
        assertStatus(200, null, push(s.anna, s.id, expenseUpdated(x, "shares" to lines(mapOf(s.a to 1225, s.b to 1225)))))
        assertTrue(split().isNull)
    }
}
