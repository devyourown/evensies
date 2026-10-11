package dev.nariinfo.evensies

import dev.nariinfo.evensies.group.InviteCodes

import org.junit.jupiter.api.Test
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

class GroupTest : IntegrationTestBase() {
    @Test
    fun createRecordsTwoEventsAndLists() {
        val token = login("Creator")
        val group = createGroup(token, "Rome")
        assertEquals(2, group["latestSeq"].asLong())
        assertEquals("Rome", group["name"].asString())
        assertEquals(InviteCodes.LENGTH, group["inviteCode"].asString().length)
        val id = group["id"].asString()
        val events = http.get("/groups/$id/events?after=0", token).body["events"]
        assertEquals(listOf("group.created", "member.added"), events.values().map { it["type"].asString() })
        assertEquals(listOf(1L, 2L), events.values().map { it["seq"].asLong() })
        assertEquals(group["myMemberId"].asString(), events[1]["payload"]["memberId"].asString())

        val list = http.get("/groups", token).body
        assertEquals(1, list.size())
        assertEquals(1, list[0]["memberCount"].asInt())
        assertEquals(id, http.get("/groups/$id", token).body["id"].asString())
    }

    @Test
    fun retriedCreateIsIdempotent() {
        val token = login("Retry")
        val body = mapOf(
            "id" to UUID.randomUUID().toString(), "name" to "X", "defaultCurrency" to "KRW",
            "memberId" to UUID.randomUUID().toString(), "memberName" to "Me",
        )
        val a = http.post("/groups", body, token)
        val b = http.post("/groups", body, token)
        assertEquals(200, b.status)
        assertEquals(a.body["latestSeq"], b.body["latestSeq"])
    }

    @Test
    fun invitePreviewAndJoin() {
        val anna = login("Anna-g")
        val group = createGroup(anna)
        val id = group["id"].asString()
        val code = group["inviteCode"].asString()
        val placeholder = UUID.randomUUID().toString()
        assertEquals(200, push(anna, id, memberAdded("Ben", placeholder)).status)

        val preview = http.get("/invites/$code") // no auth
        assertEquals(200, preview.status)
        assertEquals("Trip", preview.body["name"].asString())
        assertEquals(2, preview.body["memberCount"].asInt())
        val ben = preview.body["members"].values().first { it["name"].asString() == "Ben" }
        assertEquals(false, ben["linked"].asBoolean())
        assertEquals(404, http.get("/invites/NOPE").status)
        // Codes are 6 chars without look-alikes, and lookups ignore case, spaces and hyphens.
        assertTrue(code.length == InviteCodes.LENGTH && code.all { it in InviteCodes.ALPHABET }, code)
        val typed = code.lowercase().chunked(3).joinToString("-")
        assertEquals(200, http.get("/invites/$typed").status)
        assertTrue(http.get("/j/$code").text.contains(code.chunked(3).joinToString("-")))
        assertTrue(http.get("/j/$code").text.contains("Trip"))

        val benToken = login("Ben-g")
        val joined = http.post("/invites/$code/join", mapOf("memberId" to placeholder), benToken)
        assertEquals(200, joined.status)
        assertEquals(placeholder, joined.body["myMemberId"].asString())
        val linked = snapshot(benToken, id)["members"].values().first { it["id"].asString() == placeholder }
        assertEquals(myId(benToken), linked["userId"].asString())

        val carlToken = login("Carl-g")
        val newId = UUID.randomUUID().toString()
        val joined2 = http.post("/invites/$code/join", mapOf("newMemberId" to newId, "name" to "Carl"), carlToken)
        assertEquals(200, joined2.status)
        assertEquals(newId, joined2.body["myMemberId"].asString())
        assertEquals(3, http.get("/invites/$code").body["memberCount"].asInt())
        assertEquals(1, http.get("/groups", carlToken).body.size())

        val rotated = http.post("/groups/$id/invite/rotate", null, anna).body["inviteCode"].asString()
        assertEquals(404, http.get("/invites/$code").status)
        assertEquals(200, http.get("/invites/$rotated").status)
        assertEquals(401, http.post("/invites/$rotated/join", mapOf("memberId" to placeholder)).status)
    }

    @Test
    fun nonMemberIsForbidden() {
        val owner = login("Own")
        val id = createGroup(owner)["id"].asString()
        val stranger = login("Stranger")
        assertEquals(403, http.get("/groups/$id", stranger).status)
        assertEquals(403, http.get("/groups/$id/snapshot", stranger).status)
        assertEquals(403, push(stranger, id, memberAdded("X")).status)
        assertEquals(404, http.get("/groups/${UUID.randomUUID()}", stranger).status)
    }

    @Test
    fun memberLimitIs50() {
        val token = login("Big")
        val id = createGroup(token)["id"].asString()
        val fortyNine = (1..49).map { memberAdded("M$it") }.toTypedArray()
        assertEquals(200, push(token, id, *fortyNine).status)
        val over = push(token, id, memberAdded("M50"))
        assertEquals(409, over.status)
        assertEquals("LIMIT_EXCEEDED", over.code())
        assertNull(snapshot(token, id)["members"].values().firstOrNull { it["name"].asString() == "M50" })
    }

    @Test
    fun groupLimitIs100() {
        val token = login("Lim")
        repeat(100) { createGroup(token, "G$it") }
        val over = http.post(
            "/groups", mapOf(
                "id" to UUID.randomUUID().toString(), "name" to "G101", "defaultCurrency" to "EUR",
                "memberId" to UUID.randomUUID().toString(), "memberName" to "Me",
            ), token
        )
        assertEquals(409, over.status)
        assertEquals("LIMIT_EXCEEDED", over.code())
    }
}
