package dev.nariinfo.evensies

import dev.nariinfo.evensies.sync.EventApplier
import dev.nariinfo.evensies.sync.GroupState
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Phase 6 event changes over real HTTP: comments on payments, `expense.deleted.movedTo`, `fromMember == toMember`,
 * payments in any currency (docs/API.md "이벤트 종류와 payload", "송금 기록·편집", "지출 옮기기").
 */
class PaymentCommentsAndMovesTest : IntegrationTestBase() {
    @Autowired
    private lateinit var capture: CapturingPushSender

    private class Setup(val id: String, val anna: String, val ben: String, val a: String, val b: String, val payment: String, val annaDevice: String)

    private fun setup(): Setup {
        val t = UUID.randomUUID().toString().take(6)
        val anna = login("Pc-anna-$t")
        val ben = login("Pc-ben-$t")
        val annaDevice = device(anna)
        // only comments are visible for Anna, so the first comment push isn't held back by a batch window
        check(http.put("/me/notifications", mapOf("expenses" to false, "comments" to true, "members" to false), anna).status == 200)
        val group = createGroup(anna)
        val id = group["id"].asString()
        val a = group["myMemberId"].asString()
        val b = join(ben, group, "Ben")
        val p = UUID.randomUUID().toString()
        check(push(ben, id, payment(p, b, a, 500)).status == 200)
        return Setup(id, anna, ben, a, b, p, annaDevice)
    }

    private fun payment(id: String, from: String, to: String, amount: Long, currency: String = "EUR") = event(
        "payment.created", mapOf("paymentId" to id, "fromMember" to from, "toMember" to to, "amount" to amount, "currency" to currency, "date" to "2026-10-11"),
    )

    private fun comment(author: String, vararg target: Pair<String, Any?>, commentId: String = UUID.randomUUID().toString(), text: String = "Thanks") =
        event("comment.added", mapOf("commentId" to commentId, "authorMemberId" to author, "text" to text, "createdAt" to "2026-10-11T09:00:00Z") + target)

    private fun assertStatus(status: Int, code: String?, res: Http.Resp) {
        assertEquals(status, res.status, res.text)
        if (code != null) assertEquals(code, res.code(), res.text)
    }

    @Test
    fun commentsOnPayments() {
        val s = setup()
        val c = UUID.randomUUID().toString()
        assertStatus(200, null, push(s.anna, s.id, comment(s.a, "paymentId" to s.payment, "expenseId" to null, commentId = c, text = "Got it, thanks!")))
        val stored = snapshot(s.ben, s.id)["comments"].values().single()
        assertEquals(SharedJson.canon(mapOf("id" to c, "expenseId" to null, "paymentId" to s.payment, "authorMemberId" to s.a,
            "text" to "Got it, thanks!", "createdAt" to "2026-10-11T09:00:00Z", "deleted" to false)), SharedJson.canon(stored))

        val item = http.get("/groups/${s.id}/activity", s.ben).body["items"][0]
        assertEquals(listOf("comment_added", s.payment, s.b, s.a, "500", "EUR", "Got it, thanks!"),
            listOf("kind", "paymentId", "fromMember", "toMember", "amount", "currency", "text").map { item[it].asString() })
        assertTrue(item["expenseId"].isNull && item["description"].isNull && item["status"].isNull, "$item")
        // the snapshot matches a replay of the pulled log
        val state = http.get("/groups/${s.id}/events?after=0", s.ben).body["events"].values()
            .fold(GroupState()) { st, e -> EventApplier.apply(st, e["type"].asString(), e["payload"]) }
        assertEquals(SharedJson.canon(state.comments.values), SharedJson.canon(snapshot(s.ben, s.id)["comments"]))

        // Ben's comment on the same payment reaches Anna with the payment sentence
        assertStatus(200, null, push(s.ben, s.id, comment(s.b, "paymentId" to s.payment, text = "Any time")))
        awaitUntil("Anna's comment push") { capture.to(s.annaDevice).any { it.body?.contains("Any time") == true } }
        assertEquals("Ben commented on a payment of €5.00 from Ben to you: Any time", capture.to(s.annaDevice).last { it.body != null }.body)

        // a deleted payment still takes comments; the author deletes theirs and the text leaves the log
        assertStatus(200, null, push(s.ben, s.id, event("payment.deleted", mapOf("paymentId" to s.payment))))
        assertStatus(200, null, push(s.anna, s.id, comment(s.a, "paymentId" to s.payment, text = "Undone?")))
        assertStatus(403, "FORBIDDEN", push(s.ben, s.id, event("comment.deleted", mapOf("commentId" to c))))
        assertStatus(200, null, push(s.anna, s.id, event("comment.deleted", mapOf("commentId" to c))))
        val texts = http.get("/groups/${s.id}/events?after=0", s.ben).body["events"].values()
            .filter { it["type"].asString() == "comment.added" }.map { it["payload"]["text"].asString() }
        assertEquals(listOf("", "Any time", "Undone?"), texts)
    }

    @Test
    fun commentTargetValidation() {
        val s = setup()
        val x = UUID.randomUUID().toString()
        assertStatus(200, null, push(s.anna, s.id, expenseCreated(s.a, 1000, mapOf(s.a to 500, s.b to 500), expenseId = x)))
        fun bad(vararg target: Pair<String, Any?>) = assertStatus(400, "VALIDATION", push(s.anna, s.id, comment(s.a, *target)))
        bad()
        bad("expenseId" to null, "paymentId" to null)
        bad("expenseId" to x, "paymentId" to s.payment)
        bad("paymentId" to UUID.randomUUID().toString())
        bad("paymentId" to "p1")
        bad("paymentId" to 12)
        bad("paymentId" to x) // an expense id is not a payment
        bad("expenseId" to s.payment)
        // another group's payment (IDOR): unknown here
        val other = setup()
        bad("paymentId" to other.payment)
        assertStatus(200, null, push(s.anna, s.id, comment(s.a, "expenseId" to x, "paymentId" to null)))
        assertStatus(403, "FORBIDDEN", push(s.anna, s.id, comment(s.b, "paymentId" to s.payment)))
        assertEquals(0, snapshot(other.anna, other.id)["comments"].size())
    }

    @Test
    fun paymentsNeedTwoPeopleAndMayUseAnyCurrency() {
        val s = setup()
        assertStatus(400, "VALIDATION", push(s.ben, s.id, payment(UUID.randomUUID().toString(), s.b, s.b, 100)))
        assertStatus(200, null, push(s.ben, s.id, payment(UUID.randomUUID().toString(), s.b, s.a, 3000, currency = "JPY")))
        assertStatus(400, "UNKNOWN_CURRENCY", push(s.ben, s.id, payment(UUID.randomUUID().toString(), s.b, s.a, 3000, currency = "XXX")))
        assertEquals(setOf("EUR", "JPY"), snapshot(s.anna, s.id)["payments"].values().map { it["currency"].asString() }.toSet())
    }

    @Test
    fun movedExpensesDeleteLikeAnyDelete() {
        val s = setup()
        val x = UUID.randomUUID().toString()
        assertStatus(200, null, push(s.anna, s.id, expenseCreated(s.a, 3000, mapOf(s.a to 1500, s.b to 1500), expenseId = x)))
        fun deleted(movedTo: Any?) = event("expense.deleted", mapOf("expenseId" to x, "movedTo" to movedTo))
        for (bad in listOf<Any>("g2", 5, mapOf("groupId" to "g2", "expenseId" to UUID.randomUUID().toString()),
            mapOf("groupId" to UUID.randomUUID().toString()), mapOf("groupId" to UUID.randomUUID().toString(), "expenseId" to null), listOf(1))) {
            assertStatus(400, "VALIDATION", push(s.anna, s.id, deleted(bad)))
        }
        val target = mapOf("groupId" to UUID.randomUUID().toString(), "expenseId" to UUID.randomUUID().toString(), "extra" to 1)
        assertStatus(200, null, push(s.anna, s.id, deleted(target)))
        assertEquals(true, snapshot(s.anna, s.id)["expenses"].values().single()["deleted"].asBoolean())
        val pulled = http.get("/groups/${s.id}/events?after=0", s.ben).body["events"].values().last()
        assertEquals(SharedJson.canon(target), SharedJson.canon(pulled["payload"]["movedTo"]), "the payload is stored as sent")
        val item = http.get("/groups/${s.id}/activity", s.ben).body["items"][0]
        assertEquals(listOf("expense_moved", x, "Dinner", "3000", "-1500"),
            listOf("kind", "expenseId", "description", "amount", "myDelta").map { item[it].asString() })

        // A restore queued offline before the move synced: accepted, but ignored (rule 13) and hidden in the feed.
        assertStatus(200, null, push(s.anna, s.id, event("expense.restored", mapOf("expenseId" to x))))
        fun expense(id: String) = snapshot(s.anna, s.id)["expenses"].values().single { it["id"].asString() == id }
        assertEquals(listOf(true, true), listOf("deleted", "moved").map { expense(x)[it].asBoolean() })
        assertEquals("expense_moved", http.get("/groups/${s.id}/activity", s.ben).body["items"][0]["kind"].asString())

        // a null movedTo is a plain delete, and that one restores
        val y = UUID.randomUUID().toString()
        assertStatus(200, null, push(s.anna, s.id, expenseCreated(s.a, 1000, mapOf(s.a to 500, s.b to 500), expenseId = y)))
        assertStatus(200, null, push(s.anna, s.id, event("expense.deleted", mapOf("expenseId" to y, "movedTo" to null))))
        assertEquals(listOf(true, false), listOf("deleted", "moved").map { expense(y)[it].asBoolean() })
        assertEquals("expense_deleted", http.get("/groups/${s.id}/activity", s.ben).body["items"][0]["kind"].asString())
        assertStatus(200, null, push(s.anna, s.id, event("expense.restored", mapOf("expenseId" to y))))
        assertEquals(false, expense(y)["deleted"].asBoolean())
        assertEquals("group", http.get("/groups/${s.id}", s.anna).body["kind"].asString())
    }

    /**
     * The app's move retry (docs/API.md "지출 옮기기"): the first try's `expense.created` again (same clientId, deduped)
     * plus an `expense.updated` with all of today's values. Landed first try → the edit made in between arrives; lost
     * first try → the create lands and the update changes nothing (hidden in Activity).
     */
    @Test
    fun moveRetryBringsEditsMadeBetweenTries() {
        val s = setup()
        fun created(x: String, clientId: String, description: String) =
            expenseCreated(s.a, 3000, mapOf(s.a to 1500, s.b to 1500), expenseId = x, description = description).let { it + ("clientId" to clientId) }
        fun allValues(c: Map<String, Any?>): Map<String, Any?> {
            @Suppress("UNCHECKED_CAST") val p = c["payload"] as Map<String, Any?>
            return event("expense.updated", mapOf("expenseId" to p["expenseId"], "fields" to p - "expenseId"))
        }
        val landed = UUID.randomUUID().toString()
        val first = UUID.randomUUID().toString()
        assertStatus(200, null, push(s.anna, s.id, created(landed, first, "Taxi"))) // stored, answer lost
        val retry = created(landed, first, "Cab")
        val res = push(s.anna, s.id, retry, allValues(retry))
        assertStatus(200, null, res)
        val seqs = res.body["results"].values().map { it["seq"].asLong() }
        assertEquals(seqs[0] + 1, seqs[1], "the create is the stored one, the update is new")
        assertEquals("Cab", snapshot(s.anna, s.id)["expenses"].values().single { it["id"].asString() == landed }["description"].asString())

        val lost = UUID.randomUUID().toString()
        val again = created(lost, UUID.randomUUID().toString(), "Bus")
        assertStatus(200, null, push(s.anna, s.id, again, allValues(again)))
        assertEquals(listOf("expense_added" to lost, "expense_updated" to landed, "expense_added" to landed),
            http.get("/groups/${s.id}/activity", s.ben).body["items"].values().take(3).map { it["kind"].asString() to it["expenseId"].asString() })
    }
}
