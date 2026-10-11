package dev.nariinfo.evensies

import dev.nariinfo.evensies.activity.ActivityBackfill
import dev.nariinfo.evensies.activity.ActivityItem
import dev.nariinfo.evensies.activity.ActivityText
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.DefaultApplicationArguments
import org.springframework.jdbc.core.simple.JdbcClient
import tools.jackson.databind.JsonNode
import tools.jackson.module.kotlin.jacksonObjectMapper
import java.time.Instant
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** GET /groups/{id}/activity and GET /activity (docs/API.md "피드"), plus the startup backfill of old events. */
class ActivityFeedTest : IntegrationTestBase() {
    @Autowired
    private lateinit var jdbc: JdbcClient

    @Autowired
    private lateinit var backfill: ActivityBackfill

    private val kotlinMapper = jacksonObjectMapper()

    private val itemKeys = setOf(
        "groupId", "feedId", "seq", "kind", "createdAt", "actorMemberId", "memberId", "expenseId", "commentId", "paymentId",
        "name", "description", "amount", "currency", "fromMember", "toMember", "status", "myDelta", "refund", "text", "changes",
    )

    private class Setup(val id: String, val anna: String, val ben: String, val annaMember: String, val benMember: String, val carla: String, val x: String)

    private fun at(minute: Int) = "2026-10-11T08:%02d:00Z".format(minute)

    private fun timed(e: Map<String, Any?>, minute: Int) = e + ("createdAt" to at(minute))

    /** The creator's member is called "Me" (createGroup). One of everything: seq 3 Ben joins … seq 13 Anna confirms Ben's payment (see kinds below). */
    private fun setup(tag: String): Setup {
        val anna = login("Af-anna-$tag")
        val ben = login("Af-ben-$tag")
        val group = createGroup(anna, name = "Rome")
        val id = group["id"].asString()
        val a = group["myMemberId"].asString()
        val b = join(ben, group, "Ben")                                                               // 3
        val carla = UUID.randomUUID().toString()
        val x = UUID.randomUUID().toString()
        val p = UUID.randomUUID().toString()
        val c1 = UUID.randomUUID().toString()
        val c2 = UUID.randomUUID().toString()
        check(push(anna, id,
            timed(memberAdded("Carla", carla), 4),                                                  // 4
            timed(expenseCreated(a, 3000, mapOf(a to 1000, b to 1000, carla to 1000), expenseId = x), 5), // 5
            timed(event("expense.updated", mapOf("expenseId" to x, "fields" to mapOf("description" to "Dinner"))), 6), // 6 no-op
        ).status == 200)
        check(push(ben, id,
            timed(event("expense.updated", mapOf("expenseId" to x, "fields" to mapOf("amount" to 3300,
                "shares" to listOf(mapOf("memberId" to a, "amount" to 1100), mapOf("memberId" to b, "amount" to 1100),
                    mapOf("memberId" to carla, "amount" to 1100))))), 7),                           // 7
            timed(event("comment.added", mapOf("commentId" to c1, "expenseId" to x, "authorMemberId" to b, "text" to "Great pasta",
                "createdAt" to at(8))), 8),                                                         // 8
            timed(event("comment.added", mapOf("commentId" to c2, "expenseId" to x, "authorMemberId" to b, "text" to "Oops",
                "createdAt" to at(9))), 9),                                                         // 9
            timed(event("comment.deleted", mapOf("commentId" to c2)), 10),                          // 10 hidden
        ).status == 200)
        check(push(anna, id, timed(event("expense.deleted", mapOf("expenseId" to x)), 11)).status == 200) // 11
        check(push(ben, id,
            timed(event("expense.restored", mapOf("expenseId" to x)), 12),                          // 12
            timed(event("payment.created", mapOf("paymentId" to p, "fromMember" to b, "toMember" to a, "amount" to 1100,
                "currency" to "EUR", "date" to "2026-10-11", "status" to "sent")), 13),            // 13
        ).status == 200)
        check(push(anna, id, timed(event("payment.confirmed", mapOf("paymentId" to p)), 14)).status == 200) // 14
        return Setup(id, anna, ben, a, b, carla, x)
    }

    private fun feed(token: String, path: String): Http.Resp = http.get(path, token).also { check(it.status == 200) { it.text } }

    private fun items(token: String, groupId: String): List<JsonNode> = feed(token, "/groups/$groupId/activity").body["items"].values().toList()

    private fun names(token: String, groupId: String) =
        snapshot(token, groupId)["members"].values().associate { it["id"].asString() to it["name"].asString() }

    private fun texts(token: String, groupId: String, me: String): List<String> {
        val names = names(token, groupId)
        return items(token, groupId).map { ActivityText.sentence(kotlinMapper.treeToValue(it, ActivityItem::class.java), names, me) }
    }

    @Test
    fun groupFeedIsStructuredNewestFirstAndPerViewer() {
        val start = Instant.now().minusSeconds(60) // margin: the database container's clock may drift from the JVM's
        val s = setup("main")
        val page = feed(s.ben, "/groups/${s.id}/activity").body
        assertTrue(page["nextBefore"].isNull)
        val items = page["items"].values().toList()
        // hidden: seq 2 (creator's member.added), 6 (no-op update), 10 (comment.deleted) and 9 (the comment seq 10 deleted)
        assertEquals(listOf(14L, 13, 12, 11, 8, 7, 5, 4, 3, 1), items.map { it["seq"].asLong() })
        assertEquals(
            listOf("payment_confirmed", "payment_added", "expense_restored", "expense_deleted", "comment_added",
                "expense_updated", "expense_added", "member_added", "member_joined", "group_created"),
            items.map { it["kind"].asString() },
        )
        for (it in items) {
            assertEquals(itemKeys, it.propertyNames().toSet(), "fixed key set")
            assertEquals(s.id, it["groupId"].asString())
        }
        val feedIds = items.map { it["feedId"].asLong() }
        assertEquals(feedIds.sortedDescending(), feedIds)
        val bySeq = items.associateBy { it["seq"].asLong() }
        // the time is when the server stored the event, not the client's createdAt (08:04–08:14 here), so it follows list order
        val times = items.map { Instant.parse(it["createdAt"].asString()) }
        val end = Instant.now().plusSeconds(60)
        assertTrue(times.all { it.isAfter(start) && it.isBefore(end) }, "$times")
        assertEquals(times.sortedDescending(), times)
        assertEquals(s.annaMember, bySeq.getValue(1)["actorMemberId"].asString(), "group.created resolves to the creator added at seq 2")
        assertEquals(s.benMember, bySeq.getValue(3)["memberId"].asString())
        assertEquals(s.carla, bySeq.getValue(4)["memberId"].asString())
        assertEquals(
            SharedJson.canon(listOf(mapOf("field" to "amount", "from" to 3000, "to" to 3300),
                mapOf("field" to "shares", "from" to null, "to" to null))), // rule 10 moved the single payer too, not listed
            SharedJson.canon(bySeq.getValue(7)["changes"]),
        )
        assertEquals(s.x, bySeq.getValue(8)["expenseId"].asString())
        assertEquals("Dinner", bySeq.getValue(8)["description"].asString())
        assertEquals("Great pasta", bySeq.getValue(8)["text"].asString())
        assertEquals("sent", bySeq.getValue(13)["status"].asString())
        assertEquals("confirmed", bySeq.getValue(14)["status"].asString())
        assertTrue(bySeq.getValue(14)["myDelta"].isNull && bySeq.getValue(14)["expenseId"].isNull, "unused keys are null")

        assertEquals(
            listOf(
                "Me confirmed receiving €11.00 from you",
                "You paid Me €11.00 · waiting for Me to confirm",
                "You restored “Dinner”",
                "Me deleted “Dinner”",
                "You commented on “Dinner”: Great pasta",
                "You changed “Dinner”: €30.00 → €33.00",
                "Me added “Dinner” · €30.00 · you owe €10.00",
                "Me added Carla",
                "You joined",
                "Me created the group “Rome”",
            ),
            texts(s.ben, s.id, s.benMember),
        )
        // myDelta is per viewer: Anna paid, Ben owes
        assertEquals(-1000, bySeq.getValue(5)["myDelta"].asLong())
        assertEquals(2000, items(s.anna, s.id).first { it["seq"].asLong() == 5L }["myDelta"].asLong())
        assertEquals("You added “Dinner” · €30.00 · you lent €20.00", texts(s.anna, s.id, s.annaMember)[6])
    }

    @Test
    fun pagesFollowNextBeforeUntilNull() {
        val s = setup("pages")
        val all = items(s.ben, s.id).map { it["seq"].asLong() }
        val seen = mutableListOf<Long>()
        var before: Long? = null
        var pages = 0
        do {
            val page = feed(s.ben, "/groups/${s.id}/activity?limit=3" + (before?.let { "&before=$it" } ?: "")).body
            assertTrue(page["items"].size() <= 3)
            seen += page["items"].values().map { it["seq"].asLong() }
            before = page["nextBefore"].takeUnless { it.isNull }?.asLong()
            pages++
        } while (before != null)
        assertEquals(all, seen)
        assertTrue(pages >= 5, "14 events in pages of 3")

        // a page can be short (or empty) because hidden events are skipped, and still not be the end
        val short = feed(s.ben, "/groups/${s.id}/activity?before=11&limit=1").body
        assertEquals(0, short["items"].size(), "seq 10 is comment.deleted")
        assertEquals(10, short["nextBefore"].asLong())
        val last = feed(s.ben, "/groups/${s.id}/activity?before=3").body
        assertEquals(listOf(1L), last["items"].values().map { it["seq"].asLong() })
        assertTrue(last["nextBefore"].isNull)

        // limit is clamped to 1..100
        assertEquals(1, feed(s.ben, "/groups/${s.id}/activity?limit=0").body["items"].size())
        assertEquals(all.size, feed(s.ben, "/groups/${s.id}/activity?limit=1000").body["items"].size())
        for (q in listOf("limit=abc", "before=abc")) {
            val bad = http.get("/groups/${s.id}/activity?$q", s.ben)
            assertEquals(400, bad.status)
            assertEquals("VALIDATION", bad.code())
            assertEquals(400, http.get("/activity?$q", s.ben).status)
        }
    }

    @Test
    fun groupFeedNeedsMembership() {
        val s = setup("auth")
        val stranger = login("Af-stranger")
        assertEquals(403, http.get("/groups/${s.id}/activity", stranger).status)
        assertEquals(404, http.get("/groups/${UUID.randomUUID()}/activity", stranger).status)
        assertEquals(401, http.get("/groups/${s.id}/activity").status)
        assertEquals(401, http.get("/activity").status)
        val none = feed(stranger, "/activity").body
        assertEquals(0, none["items"].size())
        assertTrue(none["nextBefore"].isNull)
    }

    @Test
    fun overallFeedCoversOnlyGroupsTheCallerIsStillIn() {
        val s = setup("all")
        val other = createGroup(s.anna, name = "Milan")
        val otherId = other["id"].asString()
        val benInOther = join(s.ben, other, "Ben")
        push(s.anna, otherId, expenseCreated(other["myMemberId"].asString(), 1000, mapOf(benInOther to 1000), description = "Train"))

        val both = feed(s.ben, "/activity").body["items"].values().toList()
        assertEquals(setOf(s.id, otherId), both.map { it["groupId"].asString() }.toSet())
        val feedIds = both.map { it["feedId"].asLong() }
        assertEquals(feedIds.sortedDescending(), feedIds)
        assertTrue(both.none { it["groupId"].asString() == s.id && it["seq"].asLong() == 9L }, "the deleted comment is hidden here too")
        val train = both.first { it["description"]?.asString() == "Train" }
        assertEquals(-1000, train["myDelta"].asLong(), "myDelta uses the caller's member in that group")

        // paging by feedId gives the same list
        val seen = mutableListOf<Long>()
        var before: Long? = null
        do {
            val page = feed(s.ben, "/activity?limit=4" + (before?.let { "&before=$it" } ?: "")).body
            seen += page["items"].values().map { it["feedId"].asLong() }
            before = page["nextBefore"].takeUnless { it.isNull }?.asLong()
        } while (before != null)
        assertEquals(feedIds, seen)

        // removed from Milan: its events leave Ben's overall feed and its group feed is forbidden
        assertEquals(200, push(s.anna, otherId, event("member.removed", mapOf("memberId" to benInOther))).status)
        val after = feed(s.ben, "/activity").body["items"].values().toList()
        assertEquals(setOf(s.id), after.map { it["groupId"].asString() }.toSet())
        assertEquals(403, http.get("/groups/$otherId/activity", s.ben).status)
        // Anna still sees both groups, including Ben's removal
        val anna = feed(s.anna, "/activity").body["items"].values().toList()
        assertEquals("member_removed", anna.first()["kind"].asString())
        assertEquals(otherId, anna.first()["groupId"].asString())
    }

    @Test
    fun backfillRebuildsTheFeedOfOldEvents() {
        val s = setup("backfill")
        val beforeBen = feed(s.ben, "/groups/${s.id}/activity").body
        val beforeAnna = feed(s.anna, "/groups/${s.id}/activity").body

        // simulate events stored before V4
        jdbc.sql("UPDATE events SET meta = NULL WHERE group_id = :g").param("g", UUID.fromString(s.id)).update()
        assertEquals(0, feed(s.ben, "/groups/${s.id}/activity").body["items"].size(), "rows without meta are skipped")

        backfill.run(DefaultApplicationArguments())
        val missing = jdbc.sql("SELECT count(*) FROM events WHERE group_id = :g AND meta IS NULL")
            .param("g", UUID.fromString(s.id)).query(Long::class.java).single()
        assertEquals(0L, missing)
        assertEquals(SharedJson.canon(beforeBen), SharedJson.canon(feed(s.ben, "/groups/${s.id}/activity").body))
        assertEquals(SharedJson.canon(beforeAnna), SharedJson.canon(feed(s.anna, "/groups/${s.id}/activity").body))
        assertEquals(10, beforeBen["items"].size())
    }

    /**
     * Phase 3 kinds over HTTP: settings changes, a currency change ignored by rule 12 (hidden), several payers, refund
     * and split-only edits, member_left; then meta stored before Phase 3 (no payers/refund/split keys) and the backfill
     * give the same feed.
     */
    @Test
    fun splittingPowerFeed() {
        val anna = login("Af3-anna")
        val ben = login("Af3-ben")
        val group = createGroup(anna, name = "Rome")
        val id = group["id"].asString()
        val a = group["myMemberId"].asString()
        val b = join(ben, group, "Ben")
        val hotel = UUID.randomUUID().toString()
        val taxi = UUID.randomUUID().toString()
        check(push(anna, id,
            event("group.updated", mapOf("simplifyDebts" to false)),
            event("group.updated", mapOf("defaultSplit" to mapOf("mode" to "shares", "input" to mapOf(a to 2, b to 1)))),
            expenseCreated(a, 3000, mapOf(a to 1500, b to 1500), expenseId = hotel, description = "Hotel",
                extra = mapOf("payers" to lines(mapOf(a to 1000, b to 2000)))),
            event("group.updated", mapOf("defaultCurrency" to "USD")),
            expenseUpdated(hotel, "refund" to true),
            expenseUpdated(hotel, "split" to mapOf("mode" to "equal")),
            expenseCreated(b, 800, mapOf(a to 400, b to 400), expenseId = taxi, description = "Taxi"),
            expenseUpdated(taxi, "amount" to 1000, "shares" to lines(mapOf(a to 500, b to 500))),
        ).status == 200)
        val refundItem = items(ben, id).first { it["changes"].any { c -> c["field"].asString() == "refund" } }
        assertEquals(-500, refundItem["myDelta"].asLong(), "Ben received 2000 of the refund and gets 1500 back: −(2000 − 1500)")
        check(push(ben, id, event("member.removed", mapOf("memberId" to b))).status == 200)

        val expected = listOf(
            "Ben left the group",
            "You changed “Taxi”: €8.00 → €10.00",
            "You added “Taxi” · €8.00 · you owe €4.00",
            "You changed “Hotel”: split",
            "You changed “Hotel”: refund on",
            "You added “Hotel” · €30.00 · you owe €5.00",
            "You changed the group: default split",
            "You changed the group: simplify debts off",
            "Ben joined",
            "You created the group “Rome”",
        )
        assertEquals(expected, texts(anna, id, a))
        val feed = feed(anna, "/groups/$id/activity").body
        assertEquals(500, feed["items"][4]["myDelta"].asLong(), "Anna: −(1000 − 1500)")
        assertEquals(SharedJson.canon(mapOf("field" to "simplifyDebts", "from" to true, "to" to false)), SharedJson.canon(feed["items"][7]["changes"][0]))

        // meta written before Phase 3 has no payers/refund/split/settings keys: the defaults read it the same way
        jdbc.sql(
            """
            UPDATE events SET meta = meta #- '{expense,payers}' #- '{expense,refund}' #- '{expense,split}'
              #- '{expenseBefore,payers}' #- '{expenseBefore,refund}' #- '{expenseBefore,split}'
              #- '{group,simplifyDebts}' #- '{group,defaultSplit}' #- '{groupBefore,simplifyDebts}' #- '{groupBefore,defaultSplit}'
            WHERE group_id = :g AND (payload->>'expenseId' = :taxi OR type = 'group.created')
            """
        ).param("g", UUID.fromString(id)).param("taxi", taxi).update()
        assertEquals(SharedJson.canon(feed), SharedJson.canon(feed(anna, "/groups/$id/activity").body))

        jdbc.sql("UPDATE events SET meta = NULL WHERE group_id = :g").param("g", UUID.fromString(id)).update()
        backfill.run(DefaultApplicationArguments())
        assertEquals(SharedJson.canon(feed), SharedJson.canon(feed(anna, "/groups/$id/activity").body), "replayed from the log")
    }

    /**
     * Phase 5 `expenseId` filter (an expense's edit history): only events whose payload names the expense — its
     * expense.* and comment.added events, not another expense's, not payments, not comment.deleted (no expenseId) —
     * with the usual hiding, the same items as the full feed, and `limit` counting the filtered events.
     */
    @Test
    fun expenseHistoryFilter() {
        val s = setup("history")
        val y = UUID.randomUUID().toString()
        check(push(s.anna, s.id,
            expenseCreated(s.annaMember, 500, mapOf(s.benMember to 500), expenseId = y, description = "Taxi"),   // 15
            expenseUpdated(y, "amount" to 600, "shares" to lines(mapOf(s.benMember to 600))),                   // 16
            event("comment.added", mapOf("commentId" to UUID.randomUUID().toString(), "expenseId" to y,
                "authorMemberId" to s.annaMember, "text" to "Late night", "createdAt" to at(20))),                // 17
        ).status == 200)
        val path = "/groups/${s.id}/activity?expenseId="
        val page = feed(s.ben, path + s.x).body
        // seq 6 (no-op update) and 9 (the deleted comment) are hidden as in the full feed
        assertEquals(listOf(12L, 11, 8, 7, 5), page["items"].values().map { it["seq"].asLong() })
        assertTrue(page["nextBefore"].isNull)
        val full = items(s.ben, s.id).filter { it["expenseId"]?.takeUnless(JsonNode::isNull)?.asString() == s.x }
        assertEquals(SharedJson.canon(full), SharedJson.canon(page["items"]), "same per-viewer items as the full feed")
        assertEquals(listOf(17L, 16, 15), feed(s.anna, path + y).body["items"].values().map { it["seq"].asLong() })
        assertEquals(SharedJson.canon(page), SharedJson.canon(feed(s.ben, path + s.x.uppercase()).body), "the id is compared in lowercase")

        // limit counts filtered events: seq 12, 11 | 9 (hidden), 8 | 7, 6 (hidden) | 5
        val seen = mutableListOf<List<Long>>()
        val cursors = mutableListOf<Long?>()
        var before: Long? = null
        do {
            val p = feed(s.ben, path + s.x + "&limit=2" + (before?.let { "&before=$it" } ?: "")).body
            seen += p["items"].values().map { it["seq"].asLong() }
            before = p["nextBefore"].takeUnless { it.isNull }?.asLong()
            cursors += before
        } while (before != null)
        assertEquals(listOf(listOf(12L, 11), listOf(8L), listOf(7L), listOf(5L)), seen)
        assertEquals(listOf(11L, 8, 6, null), cursors)

        // an expense not in this group (unknown, or another group's: no cross-group reads) is an empty page, not 404
        val other = createGroup(s.anna, name = "Milan")
        val z = UUID.randomUUID().toString()
        check(push(s.anna, other["id"].asString(), expenseCreated(other["myMemberId"].asString(), 900, mapOf(other["myMemberId"].asString() to 900), expenseId = z)).status == 200)
        for (unknown in listOf(UUID.randomUUID().toString(), z)) {
            assertEquals(SharedJson.canon(mapOf("items" to emptyList<Any>(), "nextBefore" to null)), SharedJson.canon(feed(s.ben, path + unknown).body))
        }
        assertEquals(403, http.get("/groups/${other["id"].asString()}/activity?expenseId=$z", s.ben).status, "Ben is not in Milan")
        assertEquals(403, http.get(path + s.x, login("Af-history-stranger")).status)
        assertEquals(401, http.get(path + s.x).status)

        for (bad in listOf("abc", "${s.x}0", "1")) {
            val res = http.get(path + bad, s.ben)
            assertEquals(400 to "VALIDATION", res.status to res.code(), res.text)
        }
        // an empty value is no filter, like an empty limit (Spring reads "" as a null UUID)
        assertEquals(SharedJson.canon(feed(s.ben, "/groups/${s.id}/activity").body), SharedJson.canon(feed(s.ben, path).body))
        // not a filter on the overall feed: ignored there
        assertEquals(SharedJson.canon(feed(s.ben, "/activity").body), SharedJson.canon(feed(s.ben, "/activity?expenseId=${s.x}").body))
    }
}
