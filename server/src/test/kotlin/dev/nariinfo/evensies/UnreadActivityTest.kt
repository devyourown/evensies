package dev.nariinfo.evensies

import dev.nariinfo.evensies.sync.EventRepository
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.transaction.PlatformTransactionManager
import org.springframework.transaction.support.TransactionTemplate
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** GET /activity/unread, POST /activity/seen and the push badge (docs/API.md "Unread activity"). */
class UnreadActivityTest : IntegrationTestBase() {
    @Autowired
    private lateinit var capture: CapturingPushSender

    @Autowired
    private lateinit var jdbc: JdbcClient

    @Autowired
    private lateinit var txManager: PlatformTransactionManager

    private fun tag() = UUID.randomUUID().toString().take(6)

    private fun unread(token: String) = http.get("/activity/unread", token).body

    private fun seen(token: String, body: Map<String, Any?>) = http.post("/activity/seen", body, token)

    private fun comment(expenseId: String, author: String, commentId: String = UUID.randomUUID().toString()) = event(
        "comment.added", mapOf("commentId" to commentId, "expenseId" to expenseId, "authorMemberId" to author, "text" to "Hi",
            "createdAt" to "2026-10-11T09:00:00Z"),
    )

    @Test
    fun countsOthersNewItemsAndMarksThemSeen() {
        val t = tag()
        val anna = login("Un-anna-$t")
        val ben = login("Un-ben-$t")
        val annaDevice = device(anna)
        check(http.put("/me/notifications", mapOf("expenses" to true, "comments" to true, "members" to false), anna).status == 200)
        val group = createGroup(anna)
        val id = group["id"].asString()
        val a = group["myMemberId"].asString()
        assertEquals(0, unread(anna)["total"].asInt(), "my own events never count")
        val b = join(ben, group, "Ben")
        assertEquals(0, unread(ben)["total"].asInt(), "nothing from before I joined")
        assertEquals(SharedJson.canon(mapOf("total" to 1, "groups" to mapOf(id to 1))), SharedJson.canon(unread(anna)))

        val x = UUID.randomUUID().toString()
        assertEquals(200, push(ben, id, expenseCreated(b, 1000, mapOf(a to 500, b to 500), expenseId = x)).status)
        // the visible push carries Anna's unread total (the join had no visible push, it still counts)
        awaitUntil("Anna's expense push") { capture.to(annaDevice).any { it.body != null } }
        assertEquals(2, capture.to(annaDevice).single { it.body != null }.badge)
        assertEquals(null, capture.to(annaDevice).first { it.body == null }.badge, "no badge on data-only messages")

        // hidden events don't count: a no-op, and a comment that was deleted since
        val c = UUID.randomUUID().toString()
        assertEquals(200, push(ben, id, expenseUpdated(x, "description" to "Dinner"), comment(x, b, c), comment(x, b)).status)
        assertEquals(200, push(ben, id, event("comment.deleted", mapOf("commentId" to c))).status)
        val items = http.get("/groups/$id/activity", anna).body["items"].values().toList()
        assertEquals(3, unread(anna)["total"].asInt())

        // marking: up to an item, never down, never ahead of what exists
        val expenseFeedId = items.single { it["kind"].asString() == "expense_added" }["feedId"].asLong()
        assertEquals(1, seen(anna, mapOf("feedId" to expenseFeedId, "groupId" to id)).body["total"].asInt())
        assertEquals(1, seen(anna, mapOf("feedId" to 0, "groupId" to id)).body["total"].asInt())
        assertEquals(SharedJson.canon(mapOf("total" to 0, "groups" to emptyMap<String, Int>())),
            SharedJson.canon(seen(anna, mapOf("feedId" to 9_000_000_000_000_000L)).body))
        assertEquals(200, push(ben, id, expenseCreated(b, 300, mapOf(a to 300))).status)
        assertEquals(1, unread(anna)["total"].asInt(), "a huge feedId can't mark future items")

        // validation and permissions
        for (bad in listOf(mapOf("feedId" to -1), mapOf("feedId" to "1"), mapOf("feedId" to 1.5), emptyMap(), mapOf("feedId" to 1, "groupId" to "x"),
            mapOf("feedId" to 1, "groupId" to 5))) {
            assertEquals(400 to "VALIDATION", seen(anna, bad).let { it.status to it.code() }, "$bad")
        }
        assertEquals(404, seen(anna, mapOf("feedId" to 1, "groupId" to UUID.randomUUID().toString())).status)
        val stranger = login("Un-stranger-$t")
        assertEquals(403, seen(stranger, mapOf("feedId" to 1, "groupId" to id)).status)
        assertEquals(0, unread(stranger)["total"].asInt())
        assertEquals(401, http.get("/activity/unread").status)
    }

    @Test
    fun severalGroupsAndClaimedPlaceholders() {
        val t = tag()
        val anna = login("Un-anna-$t")
        val dan = login("Un-dan-$t")
        val g1 = createGroup(anna, "One")
        val g2 = createGroup(anna, "Two")
        val a1 = g1["myMemberId"].asString()
        val placeholder = UUID.randomUUID().toString()
        // history about Dan from before he claims his placeholder counts for him
        assertEquals(200, push(anna, g1["id"].asString(), memberAdded("Dan", placeholder), expenseCreated(a1, 1000, mapOf(a1 to 500, placeholder to 500))).status)
        assertEquals(200, http.post("/invites/${g1["inviteCode"].asString()}/join", mapOf("memberId" to placeholder), dan).status)
        val d2 = join(dan, g2, "Dan")
        assertEquals(200, push(anna, g2["id"].asString(), expenseCreated(g2["myMemberId"].asString(), 600, mapOf(d2 to 600))).status)
        assertEquals(SharedJson.canon(mapOf("total" to 3, "groups" to mapOf(g1["id"].asString() to 2, g2["id"].asString() to 1))),
            SharedJson.canon(unread(dan)))
        // without groupId: every group
        val newest = http.get("/activity", dan).body["items"][0]["feedId"].asLong()
        assertEquals(0, seen(dan, mapOf("feedId" to newest)).body["total"].asInt())
        // a friend group's hidden seq 1–2 never count; its friend_added does
        val code = http.get("/me/friend-code", dan).body["friendCode"].asString()
        assertEquals(200, http.post("/friends", mapOf("id" to UUID.randomUUID().toString(), "defaultCurrency" to "EUR", "code" to code), anna).status)
        assertEquals(1, unread(dan)["total"].asInt())

        // account deletion drops the marks
        val danId = UUID.fromString(myId(dan))
        assertEquals(204, http.delete("/me", dan).status)
        assertEquals(0L, jdbc.sql("SELECT count(*) FROM activity_seen WHERE user_id = :u").param("u", danId).query(Long::class.java).single())
    }

    /** The count reads each group's events past its mark (events_group_feed_id), never the whole feed backwards. */
    @Test
    fun unreadReadsEachGroupPastItsMark() {
        val anna = login("Un-anna-${tag()}")
        createGroup(anna)
        val plan = TransactionTemplate(txManager).execute {
            jdbc.sql("SET LOCAL enable_seqscan = off").update() // tiny test tables would otherwise be scanned whole
            jdbc.sql("EXPLAIN " + EventRepository.UNREAD_SQL).param("u", UUID.fromString(myId(anna))).param("limit", 500)
                .query(String::class.java).list().joinToString("\n")
        }!!
        assertTrue(plan.contains(" events_group_feed_id") && !plan.contains(" events_feed_id"), plan) // "using …" or "on …"
    }
}
