package dev.nariinfo.evensies

import dev.nariinfo.evensies.friend.FriendService
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.transaction.PlatformTransactionManager
import org.springframework.transaction.support.TransactionTemplate
import tools.jackson.databind.JsonNode
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

/** Phase 6 friends (docs/API.md "Friends"): friend codes, POST /friends, friend group rules, placeholder claims. */
class FriendTest : IntegrationTestBase() {
    @Autowired
    private lateinit var capture: CapturingPushSender

    @Autowired
    private lateinit var jdbc: JdbcClient

    @Autowired
    private lateinit var txManager: PlatformTransactionManager

    private fun tag() = UUID.randomUUID().toString().take(6)

    private fun addFriend(token: String, vararg body: Pair<String, Any?>, id: String = UUID.randomUUID().toString()) =
        http.post("/friends", mapOf("id" to id, "defaultCurrency" to "EUR") + body, token)

    private fun friendCode(token: String) = http.get("/me/friend-code", token).body["friendCode"].asString()

    private fun ok(res: Http.Resp): JsonNode {
        assertEquals(200, res.status, res.text)
        return res.body
    }

    private fun assertError(status: Int, code: String, res: Http.Resp) {
        assertEquals(status, res.status, res.text)
        assertEquals(code, res.code(), res.text)
    }

    private fun pairRows(a: String, b: String): List<String> = jdbc.sql(
        "SELECT group_id FROM friendships WHERE (user_lo = :a AND user_hi = :b) OR (user_lo = :b AND user_hi = :a)"
    ).param("a", UUID.fromString(a)).param("b", UUID.fromString(b)).query(String::class.java).list().filterNotNull()

    @Test
    fun byCodeMakesOneFriendGroupFromEitherSide() {
        val t = tag()
        val anna = login("Anna-$t")
        val ben = login("Ben-$t")
        val annaDevice = device(anna)

        val first = ok(http.get("/me/friend-code", anna))
        val code = first["friendCode"].asString()
        assertEquals(6, code.length)
        assertEquals("http://localhost:8080/f/$code", first["link"].asString())
        assertEquals(code, friendCode(anna), "created once, then kept")

        assertEquals("Anna-$t", ok(http.get("/friend-invites/${code.lowercase().chunked(3).joinToString("-")}"))["displayName"].asString())
        val page = http.get("/f/$code")
        assertEquals(200, page.status)
        assertTrue(page.text.contains("Anna-$t wants to split expenses with you") && page.text.contains("evensies://f/$code"), page.text)
        assertEquals(404, http.get("/friend-invites/ZZZZZZ").status)
        assertEquals(404, http.get("/f/ZZZZZZ").status)

        val g = ok(addFriend(ben, "code" to code))
        val id = g["id"].asString()
        assertEquals("friend", g["kind"].asString())
        assertEquals(3, g["latestSeq"].asLong())
        assertEquals("Ben-$t & Anna-$t", g["name"].asString())
        val events = http.get("/groups/$id/events?after=0", ben).body["events"].values().toList()
        assertEquals(listOf("group.created", "member.added", "member.added"), events.map { it["type"].asString() })
        assertEquals("friend", events[0]["payload"]["kind"].asString())
        assertEquals(listOf(myId(ben), myId(anna)), events.drop(1).map { it["payload"]["userId"].asString() })
        assertEquals(g["myMemberId"].asString(), events[1]["payload"]["memberId"].asString())
        assertTrue(events.all { it["actorUserId"].asString() == myId(ben) })
        assertEquals("friend", snapshot(anna, id)["group"]["kind"].asString())
        assertEquals("friend", http.get("/groups", anna).body.values().single { it["id"].asString() == id }["kind"].asString())

        // the same two people, again and from the other side, get the same group
        assertEquals(id, ok(addFriend(ben, "code" to code))["id"].asString())
        assertEquals(id, ok(addFriend(anna, "userId" to myId(ben)))["id"].asString())
        assertEquals(id, ok(addFriend(anna, "code" to friendCode(ben)))["id"].asString())
        assertEquals(listOf(id), pairRows(myId(anna), myId(ben)))
        assertEquals(1, http.get("/groups", ben).body.size())

        // Anna's phone: a visible friend_added push titled with the other person's name, badge = her unread count
        awaitUntil("Anna's friend push") { capture.to(annaDevice).any { it.body != null } }
        val push = capture.to(annaDevice).first { it.body != null }
        assertEquals("Ben-$t", push.title)
        assertEquals("Ben-$t added you as a friend", push.body)
        assertEquals(mapOf("type" to "sync", "groupId" to id, "seq" to "3"), push.data)
        assertEquals(1, push.badge)
        val feed = http.get("/groups/$id/activity", anna).body["items"].values().toList()
        assertEquals(listOf("friend_added"), feed.map { it["kind"].asString() }, "seq 1 and 2 are hidden")

        // own code and own id
        assertError(400, "SELF_FRIEND", addFriend(anna, "code" to code))
        assertError(400, "SELF_FRIEND", addFriend(anna, "userId" to myId(anna)))

        // rotating: the old code is gone at once
        val rotated = ok(http.post("/me/friend-code/rotate", null, anna))["friendCode"].asString()
        assertNotEquals(code, rotated)
        assertEquals(rotated, friendCode(anna))
        assertEquals(404, http.get("/friend-invites/$code").status)
        assertError(404, "NOT_FOUND", addFriend(ben, "code" to code))
        assertEquals(id, ok(addFriend(ben, "code" to rotated))["id"].asString())

        // a retry with the same id returns that group; someone else's group id is 403
        assertEquals(id, ok(addFriend(ben, "code" to rotated, id = id))["id"].asString())
        val stranger = login("Stranger-$t")
        assertError(403, "FORBIDDEN", addFriend(stranger, "name" to "Zed", id = id))
        assertEquals(403, http.get("/groups/$id", stranger).status)
        assertEquals(403, http.get("/groups/$id/snapshot", stranger).status)
        assertEquals(401, http.get("/me/friend-code").status)
        assertEquals(401, http.post("/friends", mapOf("id" to UUID.randomUUID().toString(), "defaultCurrency" to "EUR", "name" to "X")).status)
    }

    @Test
    fun twoPeopleAddingEachOtherAtOnceGetOneGroup() {
        val t = tag()
        val carla = login("Carla-$t")
        val dario = login("Dario-$t")
        val carlaCode = friendCode(carla)
        val darioCode = friendCode(dario)
        val pool = Executors.newFixedThreadPool(2)
        val start = CountDownLatch(1)
        val a = pool.submit<Http.Resp> { start.await(); addFriend(carla, "code" to darioCode) }
        val b = pool.submit<Http.Resp> { start.await(); addFriend(dario, "code" to carlaCode) }
        start.countDown()
        val ids = listOf(ok(a.get()), ok(b.get())).map { it["id"].asString() }
        pool.shutdown()
        assertEquals(1, ids.toSet().size, "$ids")
        assertEquals(ids.take(1), pairRows(myId(carla), myId(dario)))
        assertEquals(1, http.get("/groups", carla).body.size())
        assertEquals(1, http.get("/groups", dario).body.size())
    }

    @Test
    fun byUserIdNeedsASharedGroup() {
        val t = tag()
        val anna = login("Anna-$t")
        val erik = login("Erik-$t")
        val erikId = myId(erik)
        assertError(403, "FORBIDDEN", addFriend(anna, "userId" to erikId))
        assertError(403, "FORBIDDEN", addFriend(anna, "userId" to UUID.randomUUID().toString()), )
        assertError(400, "VALIDATION", addFriend(anna, "userId" to "not-a-uuid"))

        val group = createGroup(anna)
        join(erik, group, "Erik")
        val g = ok(addFriend(anna, "userId" to erikId))
        assertEquals("friend", g["kind"].asString())
        // both must still be in it: a friend group can't be left and shows payment methods, so leaving ends this path
        val frida = login("Frida-$t")
        val fridaMember = join(frida, group, "Frida")
        assertEquals(200, push(frida, group["id"].asString(), event("member.removed", mapOf("memberId" to fridaMember))).status)
        assertError(403, "FORBIDDEN", addFriend(anna, "userId" to myId(frida)))
        assertError(403, "FORBIDDEN", addFriend(frida, "userId" to myId(anna)))
        assertEquals(404, http.get("/users/${myId(anna)}/avatar", frida).status, "avatars keep the wide rule: no photo, not 403")
        // a deleted account looks like a stranger
        val gus = login("Gus-$t")
        join(gus, group, "Gus")
        val gusId = myId(gus)
        assertEquals(204, http.delete("/me", gus).status)
        assertError(403, "FORBIDDEN", addFriend(anna, "userId" to gusId))
    }

    @Test
    fun requestValidation() {
        val anna = login("Anna-${tag()}")
        for (body in listOf(
            arrayOf<Pair<String, Any?>>(),
            arrayOf("name" to "Ben", "code" to "K7P4QX"),
            arrayOf("name" to "Ben", "userId" to UUID.randomUUID().toString()),
            arrayOf("name" to "   "),
            arrayOf("name" to "x".repeat(31)),
            arrayOf("name" to 12),
            arrayOf("code" to null, "userId" to null, "name" to null),
        )) assertError(400, "VALIDATION", addFriend(anna, *body))
        assertEquals(200, addFriend(anna, "name" to "😀".repeat(30)).status, "30 code points")
        assertError(400, "VALIDATION", http.post("/friends", mapOf("defaultCurrency" to "EUR", "name" to "Ben"), anna))
        assertError(400, "VALIDATION", http.post("/friends", mapOf("id" to UUID.randomUUID().toString(), "name" to "Ben"), anna))
        assertError(400, "UNKNOWN_CURRENCY", addFriend(anna, "name" to "Ben", "defaultCurrency" to "XXX"))
        assertError(404, "NOT_FOUND", addFriend(anna, "code" to "ZZZZZZ"))
    }

    @Test
    fun placeholderFriendIsClaimedThroughItsInvite() {
        val t = tag()
        val anna = login("Anna-$t")
        val pf = ok(addFriend(anna, "name" to "  Gina  "))
        val id = pf["id"].asString()
        assertEquals("friend", pf["kind"].asString())
        assertEquals("Anna-$t & Gina", pf["name"].asString())
        val gina = snapshot(anna, id)["members"].values().single { it["name"].asString() == "Gina" }
        assertTrue(gina["userId"].isNull)
        assertEquals(listOf("friend_added"), http.get("/groups/$id/activity", anna).body["items"].values().map { it["kind"].asString() })

        val code = pf["inviteCode"].asString()
        val preview = ok(http.get("/invites/$code"))
        assertEquals("friend", preview["kind"].asString())
        // the landing names the person, never the internal "Anna & Gina"
        val page = http.get("/j/$code").text
        assertTrue(page.contains("Anna-$t added you as a friend on Evensies.") && !page.contains("Gina"), page)
        val ginaUser = login("Gina-$t")
        val newMember = http.post("/invites/$code/join", mapOf("newMemberId" to UUID.randomUUID().toString(), "name" to "Gina"), ginaUser)
        assertError(409, "LIMIT_EXCEEDED", newMember)
        assertEquals(listOf<String>(), pairRows(myId(anna), myId(ginaUser)), "a placeholder friend has no pair row yet")

        val claimed = ok(http.post("/invites/$code/join", mapOf("memberId" to gina["id"].asString()), ginaUser))
        assertEquals("friend", claimed["kind"].asString())
        assertEquals(listOf(id), pairRows(myId(anna), myId(ginaUser)))
        assertEquals(id, ok(addFriend(anna, "userId" to myId(ginaUser)))["id"].asString())
        assertEquals(id, ok(http.post("/invites/$code/join", mapOf("memberId" to gina["id"].asString()), ginaUser))["id"].asString(), "a retried claim")

        // the pair already had a group: both stay, the first one stays canonical
        val hugo = login("Hugo-$t")
        val canonical = ok(addFriend(anna, "code" to friendCode(hugo)))["id"].asString()
        val second = ok(addFriend(anna, "name" to "Hugo"))
        val hugoPlaceholder = snapshot(anna, second["id"].asString())["members"].values().single { it["userId"].isNull }["id"].asString()
        ok(http.post("/invites/${second["inviteCode"].asString()}/join", mapOf("memberId" to hugoPlaceholder), hugo))
        assertEquals(listOf(canonical), pairRows(myId(anna), myId(hugo)))
        assertEquals(2, http.get("/groups", hugo).body.size())
        assertEquals(canonical, ok(addFriend(hugo, "userId" to myId(anna)))["id"].asString())
    }

    @Test
    fun friendGroupRules() {
        val t = tag()
        val anna = login("Anna-$t")
        val ben = login("Ben-$t")
        val g = ok(addFriend(anna, "code" to friendCode(ben)))
        val id = g["id"].asString()
        val members = snapshot(anna, id)["members"].values().map { it["id"].asString() }
        val a = g["myMemberId"].asString()
        val b = members.single { it != a }

        assertError(409, "LIMIT_EXCEEDED", push(anna, id, memberAdded("Carla")))
        assertError(400, "VALIDATION", push(ben, id, event("member.removed", mapOf("memberId" to b))))
        assertError(400, "VALIDATION", push(anna, id, event("member.removed", mapOf("memberId" to b))))
        assertError(400, "VALIDATION", push(anna, id, event("group.updated", mapOf("kind" to "group"))))
        assertError(400, "VALIDATION", push(anna, id, event("group.updated", mapOf("name" to "Us", "kind" to null))))
        assertEquals(200, push(anna, id, event("group.updated", mapOf("name" to "Us"))).status, "other settings are allowed")
        assertEquals("friend", http.get("/groups/$id", anna).body["kind"].asString())
        // a non-group expense is a normal expense in the friend group
        assertEquals(200, push(ben, id, expenseCreated(b, 2000, mapOf(a to 1000, b to 1000))).status)
        assertEquals(1, snapshot(anna, id)["expenses"].size())
        // Splitwise import: a new name would be a third member
        val csv = "Date,Description,Category,Cost,Currency,Carla\n2026-10-01,Taxi,General,10.00,EUR,0.00\n".toByteArray()
        assertError(409, "LIMIT_EXCEEDED", http.upload("/groups/$id/import/splitwise", "file", "s.csv", csv, anna))

        // a kind key is refused in every group
        val normal = createGroup(anna)
        assertError(400, "VALIDATION", push(anna, normal["id"].asString(), event("group.updated", mapOf("kind" to "friend"))))
        assertEquals("group", normal["kind"].asString())
        assertEquals("group", http.get("/groups", anna).body.values().single { it["id"] == normal["id"] }["kind"].asString())
        assertEquals("group", http.get("/invites/${normal["inviteCode"].asString()}").body["kind"].asString())
    }

    /** The 100-group cap counts normal groups only; friend groups and placeholder claims never hit it. */
    @Test
    fun friendGroupsAreOutsideTheGroupCap() {
        val t = tag()
        fun fill(token: String, kind: String) {
            val user = UUID.fromString(myId(token))
            repeat(100) {
                val g = UUID.randomUUID()
                jdbc.sql("INSERT INTO groups (id, name, default_currency, invite_code, created_by, kind) VALUES (:g, 'x', 'EUR', :c, :u, :k)")
                    .param("g", g).param("c", g.toString()).param("u", user).param("k", kind).update()
                jdbc.sql("INSERT INTO members (id, group_id, user_id, name) VALUES (:m, :g, :u, 'Me')")
                    .param("m", UUID.randomUUID()).param("g", g).param("u", user).update()
            }
        }
        val friendly = login("Friendly-$t")
        fill(friendly, "friend")
        createGroup(friendly) // 100 friend groups don't count

        val busy = login("Busy-$t")
        fill(busy, "group")
        assertError(409, "LIMIT_EXCEEDED", http.post("/groups", mapOf("id" to UUID.randomUUID().toString(), "name" to "G",
            "defaultCurrency" to "EUR", "memberId" to UUID.randomUUID().toString(), "memberName" to "Me"), busy))
        assertEquals(200, addFriend(busy, "name" to "Ivo").status)
        val other = login("Other-$t")
        val pf = ok(addFriend(other, "name" to "Busy"))
        val placeholder = snapshot(other, pf["id"].asString())["members"].values().single { it["userId"].isNull }["id"].asString()
        assertEquals(200, http.post("/invites/${pf["inviteCode"].asString()}/join", mapOf("memberId" to placeholder), busy).status)
        assertEquals(200, addFriend(busy, "code" to friendCode(other)).status)
    }

    /** Placeholder friends are capped per user; a retry, a friend on Evensies and a claimed placeholder don't count. */
    @Test
    fun placeholderFriendsAreCapped() {
        val t = tag()
        val anna = login("Anna-$t")
        val annaId = UUID.fromString(myId(anna))
        repeat(FriendService.MAX_PLACEHOLDER_FRIENDS - 1) {
            val g = UUID.randomUUID()
            jdbc.sql("INSERT INTO groups (id, name, default_currency, invite_code, created_by, kind) VALUES (:g, 'x', 'EUR', :c, :u, 'friend')")
                .param("g", g).param("c", g.toString()).param("u", annaId).update()
            jdbc.sql("INSERT INTO members (id, group_id, user_id, name) VALUES (:a, :g, :u, 'Me'), (:b, :g, NULL, 'Pal')")
                .param("a", UUID.randomUUID()).param("b", UUID.randomUUID()).param("g", g).param("u", annaId).update()
        }
        val last = ok(addFriend(anna, "name" to "Pal"))
        assertError(409, "LIMIT_EXCEEDED", addFriend(anna, "name" to "One more"))
        assertEquals(last["id"], ok(addFriend(anna, "name" to "Pal", id = last["id"].asString()))["id"], "a retry")
        val ben = login("Ben-$t")
        ok(addFriend(anna, "code" to friendCode(ben)))
        val placeholder = snapshot(anna, last["id"].asString())["members"].values().single { it["userId"].isNull }["id"].asString()
        ok(http.post("/invites/${last["inviteCode"].asString()}/join", mapOf("memberId" to placeholder), ben))
        assertEquals(200, addFriend(anna, "name" to "Room again").status, "the claim freed a slot")
    }

    /** An account deleted while POST /friends waits for its row lock is not linked afterwards (its cleanup already ran). */
    @Test
    fun anAccountDeletedMeanwhileIsNotAdded() {
        val t = tag()
        val anna = login("Anna-$t")
        val ben = login("Ben-$t")
        join(ben, createGroup(anna), "Ben")
        val benId = myId(ben)
        val updated = CountDownLatch(1)
        val commit = CountDownLatch(1)
        val pool = Executors.newFixedThreadPool(2)
        try {
            // Ben's DELETE /me holds his row from markDeleted until its commit
            val deletion = pool.submit {
                TransactionTemplate(txManager).executeWithoutResult {
                    jdbc.sql("UPDATE users SET deleted_at = now() WHERE id = :u").param("u", UUID.fromString(benId)).update()
                    updated.countDown()
                    commit.await()
                }
            }
            updated.await()
            val adding = pool.submit<Http.Resp> { addFriend(anna, "userId" to benId) }
            awaitUntil("POST /friends waiting for Ben's row") {
                jdbc.sql("SELECT count(*) FROM pg_stat_activity WHERE wait_event_type = 'Lock' AND query LIKE 'SELECT id FROM users%FOR UPDATE'")
                    .query(Long::class.java).single() > 0
            }
            commit.countDown()
            deletion.get()
            assertError(403, "FORBIDDEN", adding.get())
        } finally {
            commit.countDown()
            pool.shutdown()
        }
        assertEquals(listOf<String>(), pairRows(myId(anna), benId))
        assertEquals(1, http.get("/groups", anna).body.size(), "no friend group")
    }
}
