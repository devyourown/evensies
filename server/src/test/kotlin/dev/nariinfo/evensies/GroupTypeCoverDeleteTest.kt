package dev.nariinfo.evensies

import dev.nariinfo.evensies.recurrence.RecurrenceScheduler
import dev.nariinfo.evensies.storage.Sweep
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.http.HttpMethod
import org.springframework.jdbc.core.simple.JdbcClient
import tools.jackson.databind.JsonNode
import java.nio.file.Files
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import java.util.UUID
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Group type, cover photo and delete/restore (docs/API.md "Group types, covers and deletion", rule 17) over real HTTP: validation,
 * the cover pipeline, members-only access, delete for everyone, the abuse cap, the scheduler and friend groups.
 */
class GroupTypeCoverDeleteTest : IntegrationTestBase() {
    @Autowired
    private lateinit var jdbc: JdbcClient

    @Autowired
    private lateinit var scheduler: RecurrenceScheduler

    @Autowired
    private lateinit var sweep: Sweep

    @Autowired
    private lateinit var capture: CapturingPushSender

    private fun tag() = UUID.randomUUID().toString().take(6)

    private fun assertError(status: Int, code: String, res: Http.Resp) {
        assertEquals(status, res.status, res.text)
        assertEquals(code, res.code(), res.text)
    }

    private fun ok(res: Http.Resp) = res.also { assertEquals(200, it.status, it.text) }

    private fun newGroup(token: String, type: String? = null) = http.post(
        "/groups", mapOf(
            "id" to UUID.randomUUID().toString(), "name" to "Rome", "defaultCurrency" to "EUR",
            "memberId" to UUID.randomUUID().toString(), "memberName" to "Me",
        ) + (type?.let { mapOf("type" to it) } ?: emptyMap()), token,
    )

    private fun updated(vararg fields: Pair<String, Any?>) = event("group.updated", mapOf(*fields))

    private fun cover(token: String, groupId: String, bytes: ByteArray) = http.upload("/groups/$groupId/cover", "file", "cover.jpg", bytes, token, HttpMethod.PUT)

    private fun coverFile(groupId: String, coverId: String) = storageDir.resolve("covers/$groupId/$coverId.jpg")

    private fun pulled(token: String, groupId: String): List<JsonNode> = http.get("/groups/$groupId/events?after=0", token).body["events"].values().toList()

    @Test
    fun typeOnCreateAndUpdateWithValidation() {
        val anna = login("Gt-anna-${tag()}")
        val trip = ok(newGroup(anna, "trip")).body
        assertEquals(
            setOf("id", "name", "defaultCurrency", "inviteCode", "createdAt", "latestSeq", "myMemberId", "simplifyDebts", "defaultSplit", "kind", "type", "coverImageId", "deleted"),
            trip.propertyNames().toSet(), "GroupDto",
        )
        assertEquals(setOf("id", "name", "defaultCurrency", "latestSeq", "memberCount", "kind", "type", "coverImageId", "deleted"),
            http.get("/groups", anna).body[0].propertyNames().toSet(), "GroupSummaryDto")
        assertEquals("trip", trip["type"].asString())
        assertTrue(trip["coverImageId"].isNull)
        assertFalse(trip["deleted"].asBoolean())
        assertEquals("other", createGroup(anna)["type"].asString(), "missing = other")
        assertError(400, "VALIDATION", newGroup(anna, "castle"))

        val id = trip["id"].asString()
        ok(push(anna, id, updated("type" to "home")))
        assertEquals("home", http.get("/groups/$id", anna).body["type"].asString())
        assertEquals("home", http.get("/groups", anna).body.values().single { it["id"].asString() == id }["type"].asString())
        assertEquals("home", snapshot(anna, id)["group"]["type"].asString())
        for (bad in listOf("castle", null, 3)) assertError(400, "VALIDATION", push(anna, id, updated("type" to bad)))
        assertError(400, "VALIDATION", push(anna, id, updated("coverImageId" to UUID.randomUUID().toString())))
        assertError(400, "VALIDATION", push(anna, id, updated("coverImageId" to "not-a-uuid")))
        ok(push(anna, id, updated("coverImageId" to null)))
        assertEquals("trip", pulled(anna, id).first()["payload"]["type"].asString(), "POST /groups puts the type in group.created")
    }

    @Test
    fun coverUploadIsMembersOnlyAndReplacedFilesGo() {
        val t = tag()
        val anna = login("Cv-anna-$t")
        val ben = login("Cv-ben-$t")
        val stranger = login("Cv-stranger-$t")
        val benDevice = device(ben)
        val group = createGroup(anna)
        val id = group["id"].asString()
        join(ben, group, "Ben")

        val plain = JpegTest.jpeg()
        val first = ok(cover(anna, id, JpegTest.withMetadata(plain))).body
        val c1 = first["coverImageId"].asString()
        assertEquals(http.get("/groups/$id", anna).body["latestSeq"].asLong(), first["latestSeq"].asLong())
        assertEquals(c1, http.get("/groups/$id", ben).body["coverImageId"].asString())
        assertEquals(c1, pulled(ben, id).last().let { assertEquals("group.updated", it["type"].asString()); it["payload"]["coverImageId"].asString() })
        val got = http.get("/groups/$id/cover/$c1", ben)
        assertEquals(200, got.status)
        assertContentEquals(plain, got.bytes, "GPS EXIF and comments are gone")
        assertEquals("image/jpeg", got.headers["content-type"])
        assertEquals("private, max-age=31536000, immutable", got.headers["cache-control"])
        assertEquals(403, http.get("/groups/$id/cover/$c1", stranger).status)
        assertEquals(403, cover(stranger, id, plain).status)
        val strangers = createGroup(stranger)["id"].asString()
        assertEquals(404, http.get("/groups/$strangers/cover/$c1", stranger).status, "another group's cover id through your own group (IDOR)")
        assertEquals(403, push(stranger, id, event("group.deleted", emptyMap())).status, "a non-member can't delete")
        assertEquals(404, http.get("/groups/$id/cover/${UUID.randomUUID()}", ben).status)
        awaitUntil("Ben's cover push") { capture.to(benDevice).any { it.body?.contains("cover photo") == true } }

        val c2 = ok(cover(ben, id, JpegTest.jpeg(width = 20, height = 20))).body["coverImageId"].asString()
        assertEquals(404, http.get("/groups/$id/cover/$c1", anna).status, "only the current id is served")
        assertEquals(200, http.get("/groups/$id/cover/$c2", anna).status)
        assertFalse(Files.exists(coverFile(id, c1)), "the replaced file goes after commit")
        assertTrue(Files.exists(coverFile(id, c2)))

        ok(push(anna, id, updated("coverImageId" to null)))
        assertTrue(http.get("/groups/$id", anna).body["coverImageId"].isNull)
        assertFalse(Files.exists(coverFile(id, c2)), "clearing deletes the file")
        assertEquals(404, http.get("/groups/$id/cover/$c2", anna).status)

        // The daily sweep removes a file that isn't the current cover (e.g. an upload whose push failed).
        val c3 = ok(cover(anna, id, plain)).body["coverImageId"].asString()
        val orphan = storageDir.resolve("covers/$id/${UUID.randomUUID()}.jpg")
        Files.write(orphan, plain)
        sweep.sweepCovers()
        assertTrue(Files.exists(orphan), "a file younger than an hour may be an upload whose event hasn't committed yet")
        Files.setLastModifiedTime(orphan, java.nio.file.attribute.FileTime.from(Instant.now().minus(java.time.Duration.ofHours(2))))
        sweep.sweepCovers()
        assertFalse(Files.exists(orphan))
        assertTrue(Files.exists(coverFile(id, c3)))
    }

    @Test
    fun rejectedCovers() {
        val anna = login("Cv-bad-${tag()}")
        val id = createGroup(anna)["id"].asString()
        val soi = byteArrayOf(0xFF.toByte(), 0xD8.toByte())
        assertError(400, "IMAGE_TOO_LARGE", cover(anna, id, soi + JpegTest.segment(0xC0, byteArrayOf(8, 0x4E, 0x20, 0x4E, 0x20, 1, 1, 0x11, 0))))
        assertError(400, "NOT_JPEG", cover(anna, id, "not a jpeg".toByteArray()))
        val big = JpegTest.jpeg()
        assertError(413, "TOO_LARGE", cover(anna, id, big + ByteArray(1_048_577 - big.size)))
        assertError(400, "VALIDATION", http.upload("/groups/$id/cover", "photo", "c.jpg", big, anna, HttpMethod.PUT))
        assertEquals(404, cover(anna, UUID.randomUUID().toString(), big).status)
        assertTrue(http.get("/groups/$id", anna).body["coverImageId"].isNull, "nothing stored for rejected uploads")
        // 20 per hour, failed attempts included (5 so far; the unknown group failed before the bucket)
        repeat(16) { assertEquals(400, cover(anna, id, "x".toByteArray()).status) }
        assertError(429, "RATE_LIMITED", cover(anna, id, big))
    }

    @Test
    fun anyMemberDeletesForEveryoneAndRestoresWithNothingLost() {
        val t = tag()
        val anna = login("Del-anna-$t")
        val ben = login("Del-ben-$t")
        val annaDevice = device(anna)
        val group = createGroup(anna)
        val id = group["id"].asString()
        val a = group["myMemberId"].asString()
        val b = join(ben, group, "Ben")

        ok(push(ben, id, event("group.deleted", emptyMap())))
        assertTrue(http.get("/groups/$id", anna).body["deleted"].asBoolean())
        assertTrue(http.get("/groups", anna).body.values().single { it["id"].asString() == id }["deleted"].asBoolean(), "GET /groups lists deleted groups")
        awaitUntil("the delete push") { capture.to(annaDevice).any { it.body == "Ben deleted the group “Trip”" } }

        // An offline edit made after the deletion still arrives and applies, quietly.
        val sentBefore = capture.to(annaDevice).size
        val x = UUID.randomUUID().toString()
        ok(push(ben, id, expenseCreated(b, 1000, mapOf(a to 500, b to 500), expenseId = x)))
        awaitUntil("the silent sync") { capture.to(annaDevice).size > sentBefore }
        Thread.sleep(1200) // past the 1 s batch window: nothing visible follows
        assertTrue(capture.to(annaDevice).drop(sentBefore).all { it.title == null && it.data["type"] == "sync" }, "a deleted group only syncs")
        assertEquals(x, snapshot(anna, id)["expenses"].values().single()["id"].asString())

        // Invites of a deleted group look unknown.
        val code = group["inviteCode"].asString()
        assertEquals(404, http.get("/invites/$code").status)
        assertEquals(404, http.get("/j/$code").status)
        assertEquals(404, http.post("/invites/$code/join", mapOf("newMemberId" to UUID.randomUUID().toString(), "name" to "C"), login("Del-c-$t")).status)

        ok(push(anna, id, event("group.restored", emptyMap())))
        assertFalse(http.get("/groups/$id", ben).body["deleted"].asBoolean())
        assertEquals(1, snapshot(ben, id)["expenses"].size())
        assertEquals(200, http.get("/invites/$code").status)
        val kinds = http.get("/groups/$id/activity", ben).body["items"].values().map { it["kind"].asString() }
        assertTrue(kinds.containsAll(listOf("group_deleted", "group_restored")), kinds.toString())

        // Old events and replays: a second delete is a no-op, the log replays to the same state.
        ok(push(ben, id, event("group.deleted", emptyMap()), event("group.deleted", emptyMap())))
        assertTrue(snapshot(anna, id)["group"]["deleted"].asBoolean())
        val retry = event("group.restored", emptyMap())
        val seq = ok(push(anna, id, retry)).body["results"][0]["seq"].asLong()
        assertEquals(seq, ok(push(anna, id, retry)).body["results"][0]["seq"].asLong(), "idempotent by clientId")
    }

    @Test
    fun theGroupCapIgnoresDeletedGroups() {
        val anna = login("Cap-${tag()}")
        val ids = (1..100).map { createGroup(anna)["id"].asString() }
        assertError(409, "LIMIT_EXCEEDED", newGroup(anna))
        ok(push(anna, ids.first(), event("group.deleted", emptyMap())))
        val extra = ok(newGroup(anna)).body["id"].asString()
        ok(push(anna, ids.first(), event("group.restored", emptyMap())))
        assertFalse(http.get("/groups/${ids.first()}", anna).body["deleted"].asBoolean(), "a restore is never blocked by the cap")
        assertEquals(101, http.get("/groups", anna).body.size())
        assertTrue(extra in http.get("/groups", anna).body.values().map { it["id"].asString() })
    }

    /** A deleted group's series wait; a restore moves them on to today, so the deleted period isn't posted in a burst. */
    @Test
    fun theSchedulerSkipsADeletedGroupAndARestoreSkipsTheDeletedPeriod() {
        val anna = login("Sch-${tag()}")
        val group = createGroup(anna)
        val id = group["id"].asString()
        val a = group["myMemberId"].asString()
        ok(push(anna, id, event("group.deleted", emptyMap())))
        val r = UUID.randomUUID().toString()
        val start = LocalDate.now(ZoneOffset.UTC).minusMonths(5)
        val template = mapOf(
            "description" to "Rent", "amount" to 1000, "currency" to "EUR", "fxRateToDefault" to null, "paidBy" to a,
            "category" to null, "shares" to lines(mapOf(a to 1000)),
        )
        ok(push(anna, id, event("recurrence.created", mapOf("recurrenceId" to r, "frequency" to "monthly", "startDate" to start.toString(), "timeZone" to "UTC", "template" to template))))
        // Pretend the series has been due since the 1st repeat (the group was deleted all that time).
        jdbc.sql("UPDATE recurrences SET next_occurrence = 1, next_due_at = :t WHERE id = :id")
            .param("t", Instant.now().minusSeconds(120 * 86400).atOffset(ZoneOffset.UTC)).param("id", UUID.fromString(r)).update()
        scheduler.runDue(Instant.now())
        assertTrue(pulled(anna, id).none { it["type"].asString() == "expense.created" }, "nothing posts while the group is deleted")

        ok(push(anna, id, event("group.restored", emptyMap())))
        val n = jdbc.sql("SELECT next_occurrence FROM recurrences WHERE id = :id").param("id", UUID.fromString(r)).query(Int::class.java).single()
        assertEquals(5, n, "moved to the first occurrence on or after today")
        scheduler.runDue(Instant.now())
        val repeats = pulled(anna, id).filter { it["type"].asString() == "expense.created" && it["actorUserId"].isNull }
        assertTrue(repeats.size <= 1 && repeats.all { it["payload"]["occurrence"].asInt() >= 5 }, repeats.toString())
        jdbc.sql("UPDATE recurrences SET deleted_at = now() WHERE id = :id").param("id", UUID.fromString(r)).update()
    }

    /** Delete friend: the pair's friend group is deleted; adding them again restores it (by either of them). */
    @Test
    fun addingADeletedFriendAgainRestoresTheirGroup() {
        val t = tag()
        val anna = login("Fr-anna-$t")
        val ben = login("Fr-ben-$t")
        val benId = myId(ben)
        val annaDevice = device(anna)
        val benDevice = device(ben)
        join(ben, createGroup(anna), "Ben")
        val friend = ok(http.post("/friends", mapOf("id" to UUID.randomUUID().toString(), "defaultCurrency" to "EUR", "userId" to benId), anna)).body
        val f = friend["id"].asString()
        val a = friend["myMemberId"].asString()
        val b = snapshot(anna, f)["members"].values().single { it["id"].asString() != a }["id"].asString()
        ok(push(anna, f, expenseCreated(a, 2000, mapOf(a to 1000, b to 1000))))
        ok(push(anna, f, event("group.deleted", emptyMap())))
        assertTrue(http.get("/groups/$f", ben).body["deleted"].asBoolean(), "deleted for both of them")
        // The friend group's internal name ("Anna & Ben") never shows: the push talks about non-group expenses.
        awaitUntil("Ben's delete push") { capture.to(benDevice).any { it.body == "Fr-anna-$t deleted your non-group expenses" } }

        val again = ok(http.post("/friends", mapOf("id" to UUID.randomUUID().toString(), "defaultCurrency" to "EUR", "userId" to myId(anna)), ben)).body
        assertEquals(f, again["id"].asString(), "the same friend group")
        assertFalse(again["deleted"].asBoolean())
        val last = pulled(ben, f).last()
        assertEquals("group.restored" to benId, last["type"].asString() to last["actorUserId"].asString())
        assertEquals(1, snapshot(ben, f)["expenses"].size(), "the history comes back")
        awaitUntil("Anna's restore push") { capture.to(annaDevice).any { it.body == "Fr-ben-$t restored your non-group expenses" } }
        assertFalse((capture.to(benDevice) + capture.to(annaDevice)).any { Regex("(deleted|restored) the group").containsMatchIn(it.body.orEmpty()) })
        // Adding a friend whose group is live adds nothing.
        val seq = http.get("/groups/$f", anna).body["latestSeq"].asLong()
        ok(http.post("/friends", mapOf("id" to UUID.randomUUID().toString(), "defaultCurrency" to "EUR", "userId" to benId), anna))
        assertEquals(seq, http.get("/groups/$f", anna).body["latestSeq"].asLong())
    }
}
