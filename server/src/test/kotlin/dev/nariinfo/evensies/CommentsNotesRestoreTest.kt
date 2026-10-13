package dev.nariinfo.evensies

import dev.nariinfo.evensies.sync.EventApplier
import dev.nariinfo.evensies.sync.GroupState
import org.junit.jupiter.api.Test
import tools.jackson.databind.JsonNode
import java.util.UUID
import kotlin.test.assertEquals

/** Phase 2 events over real HTTP: comment.*, expense.restored, notes (docs/API.md "Event types and payloads"). */
class CommentsNotesRestoreTest : IntegrationTestBase() {
    private class Setup(val id: String, val anna: String, val ben: String, val annaMember: String, val benMember: String, val expense: String)

    private fun setup(tag: String): Setup {
        val anna = login("Cn-anna-$tag")
        val ben = login("Cn-ben-$tag")
        val group = createGroup(anna)
        val id = group["id"].asString()
        val annaMember = group["myMemberId"].asString()
        val benMember = join(ben, group, "Ben")
        val x = UUID.randomUUID().toString()
        check(push(anna, id, expenseCreated(annaMember, 2000, mapOf(annaMember to 1000, benMember to 1000), expenseId = x)).status == 200)
        return Setup(id, anna, ben, annaMember, benMember, x)
    }

    private fun comment(
        commentId: String, expenseId: String, author: String, text: Any? = "Is breakfast included?",
        createdAt: Any? = "2026-10-11T09:00:00Z",
    ) = event(
        "comment.added",
        mapOf("commentId" to commentId, "expenseId" to expenseId, "authorMemberId" to author, "text" to text, "createdAt" to createdAt),
    )

    private fun deleteComment(commentId: String) = event("comment.deleted", mapOf("commentId" to commentId))

    private fun comments(token: String, groupId: String): List<JsonNode> = snapshot(token, groupId)["comments"].values().toList()

    private fun expense(token: String, groupId: String, expenseId: String): JsonNode =
        snapshot(token, groupId)["expenses"].values().first { it["id"].asString() == expenseId }

    private fun create(paidBy: String, expenseId: String, extra: Map<String, Any?>) = event(
        "expense.created", mapOf(
            "expenseId" to expenseId, "description" to "Taxi", "amount" to 900, "currency" to "EUR", "fxRateToDefault" to null,
            "paidBy" to paidBy, "date" to "2026-10-10", "category" to null, "shares" to listOf(mapOf("memberId" to paidBy, "amount" to 900)),
        ) + extra
    )

    private fun update(expenseId: String, fields: Map<String, Any?>) = event("expense.updated", mapOf("expenseId" to expenseId, "fields" to fields))

    private fun assertStatus(status: Int, code: String?, res: Http.Resp) {
        assertEquals(status, res.status, res.text)
        if (code != null) assertEquals(code, res.code(), res.text)
    }

    @Test
    fun onlyTheAuthorWritesAndDeletesTheirComment() {
        val s = setup("perm")
        val c1 = UUID.randomUUID().toString()
        assertStatus(200, null, push(s.ben, s.id, comment(c1, s.expense, s.benMember)))
        assertEquals(
            listOf(mapOf("id" to c1, "expenseId" to s.expense, "paymentId" to null, "authorMemberId" to s.benMember, "text" to "Is breakfast included?",
                "createdAt" to "2026-10-11T09:00:00Z", "deleted" to false)).let(SharedJson::canon),
            SharedJson.canon(comments(s.anna, s.id)),
        )

        // writing as someone else, or from outside the group
        assertStatus(403, "FORBIDDEN", push(s.ben, s.id, comment(UUID.randomUUID().toString(), s.expense, s.annaMember)))
        assertStatus(403, "FORBIDDEN", push(s.ben, s.id, comment(UUID.randomUUID().toString(), s.expense, UUID.randomUUID().toString())))
        val stranger = login("Cn-stranger")
        assertStatus(403, "FORBIDDEN", push(stranger, s.id, comment(UUID.randomUUID().toString(), s.expense, s.benMember)))

        // only the author deletes; the comment stays as a tombstone without its text, also in the log and the export
        assertStatus(403, "FORBIDDEN", push(s.anna, s.id, deleteComment(c1)))
        assertStatus(403, "FORBIDDEN", push(stranger, s.id, deleteComment(c1)))
        assertStatus(200, null, push(s.ben, s.id, deleteComment(c1)))
        assertEquals(true, comments(s.anna, s.id).single()["deleted"].asBoolean())
        assertEquals("", comments(s.anna, s.id).single()["text"].asString())
        val added = http.get("/groups/${s.id}/events?after=0", s.anna).body["events"].values().single { it["type"].asString() == "comment.added" }
        assertEquals("", added["payload"]["text"].asString())
        assertEquals(c1, added["payload"]["commentId"].asString())
        val export = http.get("/groups/${s.id}/export?format=json", s.anna)
        assertEquals(200, export.status)
        assertEquals(false, "breakfast" in export.text, export.text)

        // unknown comment: accepted and ignored; a re-used (tombstoned) id is ignored too
        assertStatus(200, null, push(s.anna, s.id, deleteComment(UUID.randomUUID().toString())))
        assertStatus(200, null, push(s.anna, s.id, comment(c1, s.expense, s.annaMember, text = "Overwrite")))
        val only = comments(s.anna, s.id).single()
        assertEquals(s.benMember, only["authorMemberId"].asString())
        assertEquals("", only["text"].asString())
        assertEquals(true, only["deleted"].asBoolean())
    }

    /** Offline, a comment can be written and deleted before the first push: its text is never stored. */
    @Test
    fun aCommentAddedAndDeletedInOnePushLeavesNoText() {
        val s = setup("same-push")
        val c = UUID.randomUUID().toString()
        val other = UUID.randomUUID().toString()
        assertStatus(200, null, push(s.ben, s.id, comment(c, s.expense, s.benMember, text = "secret"), comment(other, s.expense, s.benMember, text = "keep"), deleteComment(c)))
        val texts = http.get("/groups/${s.id}/events?after=0", s.anna).body["events"].values()
            .filter { it["type"].asString() == "comment.added" }.associate { it["payload"]["commentId"].asString() to it["payload"]["text"].asString() }
        assertEquals(mapOf(c to "", other to "keep"), texts)
        assertEquals(mapOf(c to "", other to "keep"), comments(s.anna, s.id).associate { it["id"].asString() to it["text"].asString() })
    }

    @Test
    fun commentValidation() {
        val s = setup("val")
        fun bad(res: Http.Resp) = assertStatus(400, "VALIDATION", res)
        fun id() = UUID.randomUUID().toString()
        bad(push(s.ben, s.id, comment(id(), UUID.randomUUID().toString(), s.benMember)))  // unknown expense
        bad(push(s.ben, s.id, comment(id(), s.expense, s.benMember, text = "   ")))
        bad(push(s.ben, s.id, comment(id(), s.expense, s.benMember, text = "")))
        bad(push(s.ben, s.id, comment(id(), s.expense, s.benMember, text = null)))
        bad(push(s.ben, s.id, comment(id(), s.expense, s.benMember, text = 42)))
        bad(push(s.ben, s.id, comment(id(), s.expense, s.benMember, text = "x".repeat(1001))))
        bad(push(s.ben, s.id, comment(id(), s.expense, s.benMember, createdAt = "yesterday")))
        bad(push(s.ben, s.id, comment(id(), s.expense, s.benMember, createdAt = "2026-10-11")))
        bad(push(s.ben, s.id, comment(id(), s.expense, s.benMember, createdAt = null)))
        bad(push(s.ben, s.id, comment("c1", s.expense, s.benMember)))
        bad(push(s.ben, s.id, deleteComment("c1")))
        // a bad event rejects the whole batch
        val good = id()
        bad(push(s.ben, s.id, comment(good, s.expense, s.benMember), comment(id(), s.expense, s.benMember, text = "")))
        assertEquals(emptyList(), comments(s.anna, s.id))

        assertStatus(200, null, push(s.ben, s.id, comment(good, s.expense, s.benMember, text = "x".repeat(1000))))
        // a deleted expense can still be commented on
        assertStatus(200, null, push(s.anna, s.id, event("expense.deleted", mapOf("expenseId" to s.expense))))
        assertStatus(200, null, push(s.anna, s.id, comment(id(), s.expense, s.annaMember, text = "Why deleted?")))
        assertEquals(2, comments(s.anna, s.id).size)
    }

    @Test
    fun retriedCommentIsStoredOnce() {
        val s = setup("retry")
        val e = comment(UUID.randomUUID().toString(), s.expense, s.benMember)
        val first = push(s.ben, s.id, e).body["results"][0]["seq"].asLong()
        assertEquals(first, push(s.ben, s.id, e).body["results"][0]["seq"].asLong())
        assertEquals(1, comments(s.anna, s.id).size)
    }

    @Test
    fun idsFromAnotherGroupAreRejectedOrIgnored() {
        val a = setup("idor")
        // Anna's second group B, with an expense, a comment and a deleted expense; Ben is not in B
        val b = createGroup(a.anna, name = "Other")
        val bId = b["id"].asString()
        val annaInB = b["myMemberId"].asString()
        val xb = UUID.randomUUID().toString()
        val xbDeleted = UUID.randomUUID().toString()
        val cb = UUID.randomUUID().toString()
        assertStatus(200, null, push(a.anna, bId,
            expenseCreated(annaInB, 500, mapOf(annaInB to 500), expenseId = xb),
            expenseCreated(annaInB, 700, mapOf(annaInB to 700), expenseId = xbDeleted),
            event("expense.deleted", mapOf("expenseId" to xbDeleted)),
            comment(cb, xb, annaInB, text = "Original"),
        ))
        val bBefore = snapshot(a.anna, bId)

        // through group A: B's expense is unknown, so commenting is rejected
        assertStatus(400, "VALIDATION", push(a.anna, a.id, comment(UUID.randomUUID().toString(), xb, a.annaMember)))
        // B's member is not Anna's member in A
        assertStatus(403, "FORBIDDEN", push(a.anna, a.id, comment(UUID.randomUUID().toString(), a.expense, annaInB)))
        // B's comment and B's deleted expense are unknown targets in A: accepted, ignored, B untouched
        assertStatus(200, null, push(a.anna, a.id, deleteComment(cb)))
        assertStatus(200, null, push(a.anna, a.id, event("expense.restored", mapOf("expenseId" to xbDeleted))))
        // re-using B's comment id in A is rejected
        assertStatus(400, "VALIDATION", push(a.anna, a.id, comment(cb, a.expense, a.annaMember, text = "Hijack")))
        assertEquals(SharedJson.canon(bBefore), SharedJson.canon(snapshot(a.anna, bId)))
        assertEquals(listOf(a.expense), snapshot(a.anna, a.id)["expenses"].values().map { it["id"].asString() })
        // and Ben, who is not in B, cannot push there at all
        assertStatus(403, "FORBIDDEN", push(a.ben, bId, deleteComment(cb)))
        assertStatus(403, "FORBIDDEN", push(a.ben, bId, event("expense.restored", mapOf("expenseId" to xbDeleted))))
    }

    @Test
    fun entityIdsOfAnotherGroupCannotBeTakenOver() {
        val b = setup("takeover")      // Anna's group with Ben, an expense and (below) a payment
        val p = UUID.randomUUID().toString()
        assertStatus(200, null, push(b.ben, b.id, event("payment.created", mapOf("paymentId" to p, "fromMember" to b.benMember,
            "toMember" to b.annaMember, "amount" to 500, "currency" to "EUR", "date" to "2026-10-11"))))
        val bBefore = snapshot(b.anna, b.id)
        // Mallory, never in that group, re-uses its ids inside her own group
        val mallory = login("Cn-mallory")
        val own = createGroup(mallory)
        val ownId = own["id"].asString()
        val me = own["myMemberId"].asString()
        val malloryId = myId(mallory)
        assertStatus(400, "VALIDATION", push(mallory, ownId, memberAdded("Ben", memberId = b.benMember)))
        // with her own userId it is refused even earlier: she already has a member in her group
        assertStatus(400, "MEMBER_TAKEN", push(mallory, ownId, memberAdded("Ben", memberId = b.benMember, userId = malloryId)))
        assertStatus(400, "VALIDATION", push(mallory, ownId, expenseCreated(me, 1, mapOf(me to 1), expenseId = b.expense)))
        assertStatus(400, "VALIDATION", push(mallory, ownId, event("payment.created", mapOf("paymentId" to p, "fromMember" to me,
            "toMember" to me, "amount" to 1, "currency" to "EUR", "date" to "2026-10-11"))))
        assertEquals(403, http.get("/groups/${b.id}", mallory).status)
        assertEquals(SharedJson.canon(bBefore), SharedJson.canon(snapshot(b.anna, b.id)))
        assertEquals(2, snapshot(mallory, ownId)["latestSeq"].asLong(), "rejected batches store nothing")
    }

    @Test
    fun notesAreStoredUpdatedClearedAndLimited() {
        val s = setup("notes")
        fun id() = UUID.randomUUID().toString()
        val x = id()
        assertStatus(200, null, push(s.anna, s.id, create(s.annaMember, x, mapOf("notes" to "Table 12"))))
        assertEquals("Table 12", expense(s.ben, s.id, x)["notes"].asString())
        // the old shape without the key (setup used it) means null
        assertEquals(true, expense(s.ben, s.id, s.expense)["notes"].isNull)

        assertStatus(200, null, push(s.anna, s.id, update(x, mapOf("notes" to "Airport"))))
        assertEquals("Airport", expense(s.ben, s.id, x)["notes"].asString())
        assertStatus(200, null, push(s.anna, s.id, update(x, mapOf("description" to "Taxi home"))))
        assertEquals("Airport", expense(s.ben, s.id, x)["notes"].asString(), "an update without notes keeps them")
        assertStatus(200, null, push(s.anna, s.id, update(x, mapOf("notes" to null))))
        assertEquals(true, expense(s.ben, s.id, x)["notes"].isNull)

        // length is UTF-16 units: 250 emoji = 500 units
        assertStatus(200, null, push(s.anna, s.id, create(s.annaMember, id(), mapOf("notes" to "x".repeat(500)))))
        assertStatus(200, null, push(s.anna, s.id, create(s.annaMember, id(), mapOf("notes" to "😀".repeat(250)))))
        assertStatus(400, "VALIDATION", push(s.anna, s.id, create(s.annaMember, id(), mapOf("notes" to "😀".repeat(250) + "x"))))
        assertStatus(400, "VALIDATION", push(s.anna, s.id, create(s.annaMember, id(), mapOf("notes" to "x".repeat(501)))))
        assertStatus(400, "VALIDATION", push(s.anna, s.id, create(s.annaMember, id(), mapOf("notes" to 12))))
        assertStatus(400, "VALIDATION", push(s.anna, s.id, update(x, mapOf("notes" to "x".repeat(501)))))
        assertStatus(400, "VALIDATION", push(s.anna, s.id, update(x, mapOf("notes" to listOf("a")))))
    }

    @Test
    fun restoreBringsADeletedExpenseBack() {
        val s = setup("restore")
        val x = s.expense
        assertStatus(200, null, push(s.anna, s.id, event("expense.deleted", mapOf("expenseId" to x))))
        // an update while deleted is ignored and stays lost after the restore
        assertStatus(200, null, push(s.anna, s.id, update(x, mapOf("amount" to 3000,
            "shares" to listOf(mapOf("memberId" to s.annaMember, "amount" to 1500), mapOf("memberId" to s.benMember, "amount" to 1500))))))
        assertEquals(true, expense(s.anna, s.id, x)["deleted"].asBoolean())

        // any member may restore, not only the one who deleted
        assertStatus(200, null, push(s.ben, s.id, event("expense.restored", mapOf("expenseId" to x))))
        val restored = expense(s.anna, s.id, x)
        assertEquals(false, restored["deleted"].asBoolean())
        assertEquals(2000, restored["amount"].asLong())

        // restoring a live or unknown expense changes nothing
        assertStatus(200, null, push(s.ben, s.id, event("expense.restored", mapOf("expenseId" to x))))
        assertStatus(200, null, push(s.ben, s.id, event("expense.restored", mapOf("expenseId" to UUID.randomUUID().toString()))))
        assertStatus(400, "VALIDATION", push(s.ben, s.id, event("expense.restored", mapOf("expenseId" to "x1"))))
        assertStatus(403, "FORBIDDEN", push(login("Cn-stranger-restore"), s.id, event("expense.restored", mapOf("expenseId" to x))))
        assertEquals(false, expense(s.anna, s.id, x)["deleted"].asBoolean())

        // delete again after restore: the later event wins
        assertStatus(200, null, push(s.ben, s.id, event("expense.deleted", mapOf("expenseId" to x))))
        assertEquals(true, expense(s.anna, s.id, x)["deleted"].asBoolean())
    }

    @Test
    fun snapshotMatchesReplayOfThePulledLog() {
        val s = setup("replay")
        val c = UUID.randomUUID().toString()
        val x = UUID.randomUUID().toString()
        push(s.anna, s.id, create(s.annaMember, x, mapOf("notes" to "Receipt in the car")))
        push(s.ben, s.id, comment(c, x, s.benMember), comment(UUID.randomUUID().toString(), x, s.benMember, text = "Second", createdAt = "2026-10-11T09:05:00Z"))
        push(s.ben, s.id, deleteComment(c))
        push(s.anna, s.id, event("expense.deleted", mapOf("expenseId" to x)), event("expense.restored", mapOf("expenseId" to x)))

        var state = GroupState()
        for (e in http.get("/groups/${s.id}/events?after=0", s.anna).body["events"]) {
            assertEquals(false, e.has("meta"), "pull never carries the server-internal meta")
            state = EventApplier.apply(state, e["type"].asString(), e["payload"])
        }
        val snap = snapshot(s.anna, s.id)
        assertEquals(SharedJson.canon(state.expenses.values), SharedJson.canon(snap["expenses"]))
        assertEquals(SharedJson.canon(state.comments.values), SharedJson.canon(snap["comments"]))
        assertEquals(SharedJson.canon(snap), SharedJson.canon(http.get("/groups/${s.id}/export?format=json", s.anna).body))
    }
}
