package dev.nariinfo.evensies

import dev.nariinfo.evensies.push.NotificationPrefs
import dev.nariinfo.evensies.storage.Sweep
import dev.nariinfo.evensies.sync.EventApplier
import dev.nariinfo.evensies.sync.GroupState
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import java.awt.image.BufferedImage
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.nio.file.Files
import java.util.UUID
import java.util.zip.ZipInputStream
import javax.imageio.ImageIO
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Receipt photos over real HTTP (docs/API.md "Receipts", rule 14, "Export and import"): upload, download, the
 * `attachment.*` events, file deletion after commit, activity and push, and the ZIP export.
 */
class ReceiptsTest : IntegrationTestBase() {
    @Autowired
    private lateinit var capture: CapturingPushSender

    @Autowired
    private lateinit var jdbc: JdbcClient

    @Autowired
    private lateinit var sweep: Sweep

    /** Anna's group with Ben, and Anna's expense [x] (€30.00 split 15/15). */
    private class Setup(val id: String, val anna: String, val ben: String, val a: String, val b: String, val x: String)

    private fun setup(): Setup {
        val t = UUID.randomUUID().toString().take(6)
        val anna = login("Rc-anna-$t")
        val ben = login("Rc-ben-$t")
        val group = createGroup(anna)
        val id = group["id"].asString()
        val a = group["myMemberId"].asString()
        val b = join(ben, group, "Ben")
        val x = UUID.randomUUID().toString()
        check(push(anna, id, expenseCreated(a, 3000, mapOf(a to 1500, b to 1500), expenseId = x)).status == 200)
        return Setup(id, anna, ben, a, b, x)
    }

    private val image = JpegTest.jpeg(width = 64, height = 48)
    private val thumb = JpegTest.jpeg(width = 16, height = 12)

    private fun upload(token: String, groupId: String, attachmentId: String, parts: Map<String, ByteArray> = mapOf("image" to image, "thumb" to thumb)) =
        http.multipart("/groups/$groupId/attachments/$attachmentId", parts, token)

    private fun added(attachmentId: Any?, expenseId: Any?) = event("attachment.added", mapOf("attachmentId" to attachmentId, "expenseId" to expenseId))

    private fun removed(attachmentId: Any?, vararg extra: Pair<String, Any?>) = event("attachment.deleted", mapOf("attachmentId" to attachmentId) + extra)

    /** Uploads and attaches a new receipt to [expenseId]; returns its id. */
    private fun attach(token: String, groupId: String, expenseId: String): String {
        val r = UUID.randomUUID().toString()
        assertStatus(201, null, upload(token, groupId, r))
        assertStatus(200, null, push(token, groupId, added(r, expenseId)))
        return r
    }

    private fun file(groupId: String, id: String, thumb: Boolean = false) = storageDir.resolve("attachments/$groupId/$id${if (thumb) "_thumb" else ""}.jpg")

    private fun assertStatus(status: Int, code: String?, res: Http.Resp) {
        assertEquals(status, res.status, res.text)
        if (code != null) assertEquals(code, res.code(), res.text)
    }

    private fun attachments(token: String, groupId: String) = snapshot(token, groupId)["attachments"].values().associate { it["id"].asString() to it }

    @Test
    fun uploadThenDownload() {
        val s = setup()
        val r = UUID.randomUUID().toString()
        val res = upload(s.anna, s.id, r, mapOf("image" to JpegTest.withMetadata(image), "thumb" to JpegTest.withMetadata(thumb)))
        assertStatus(201, null, res)
        assertEquals(r, res.body["id"].asString())
        assertEquals(0, snapshot(s.anna, s.id)["attachments"].size(), "an upload is on no expense until attachment.added")

        // any member downloads it, even before it is attached; metadata and trailing bytes are gone
        for (viewer in listOf(s.anna, s.ben)) {
            val full = http.get("/groups/${s.id}/attachments/$r", viewer)
            assertEquals(200, full.status)
            assertContentEquals(image, full.bytes)
            assertEquals("image/jpeg", full.headers["content-type"])
            assertEquals("private, max-age=31536000, immutable", full.headers["cache-control"])
            assertEquals("nosniff", full.headers["x-content-type-options"])
            val small = http.get("/groups/${s.id}/attachments/$r/thumb", viewer)
            assertEquals(200, small.status)
            assertContentEquals(thumb, small.bytes)
            assertEquals("image/jpeg", small.headers["content-type"])
            assertEquals("private, max-age=31536000, immutable", small.headers["cache-control"])
        }

        // a retry is 200 and the first write wins
        val retry = upload(s.ben, s.id, r, mapOf("image" to JpegTest.jpeg(width = 8, height = 8), "thumb" to thumb))
        assertStatus(200, null, retry)
        assertEquals(r, retry.body["id"].asString())
        assertContentEquals(image, http.get("/groups/${s.id}/attachments/$r", s.ben).bytes)

        // the same id in another group (Anna is in both): 409 for an upload, 404 for a download there
        val other = createGroup(s.anna, name = "Other")["id"].asString()
        assertStatus(409, "DUPLICATE", upload(s.anna, other, r))
        assertStatus(404, "NOT_FOUND", http.get("/groups/$other/attachments/$r", s.anna))
        assertStatus(404, "NOT_FOUND", http.get("/groups/$other/attachments/$r/thumb", s.anna))
        assertFalse(Files.exists(file(other, r)))

        // strangers: 403 (membership first), unknown group 404, unknown id 404, no token 401
        val stranger = login("Rc-stranger-${UUID.randomUUID().toString().take(6)}")
        assertStatus(403, "FORBIDDEN", upload(stranger, s.id, UUID.randomUUID().toString()))
        assertStatus(403, "FORBIDDEN", http.get("/groups/${s.id}/attachments/$r", stranger))
        assertStatus(403, "FORBIDDEN", http.get("/groups/${s.id}/attachments/$r/thumb", stranger))
        assertStatus(404, "NOT_FOUND", upload(s.anna, UUID.randomUUID().toString(), UUID.randomUUID().toString()))
        assertStatus(404, "NOT_FOUND", http.get("/groups/${UUID.randomUUID()}/attachments/$r", s.anna))
        assertStatus(404, "NOT_FOUND", http.get("/groups/${s.id}/attachments/${UUID.randomUUID()}", s.anna))
        assertEquals(401, http.get("/groups/${s.id}/attachments/$r").status)
        assertEquals(401, http.multipart("/groups/${s.id}/attachments/$r", mapOf("image" to image, "thumb" to thumb), null).status)
        assertStatus(400, "VALIDATION", http.get("/groups/${s.id}/attachments/not-a-uuid", s.anna))
    }

    @Test
    fun rejectedUploads() {
        val s = setup()
        fun bad(status: Int, code: String, parts: Map<String, ByteArray>) {
            val r = UUID.randomUUID().toString()
            assertStatus(status, code, upload(s.anna, s.id, r, parts))
            assertFalse(Files.exists(file(s.id, r)), "nothing written")
            assertStatus(404, "NOT_FOUND", http.get("/groups/${s.id}/attachments/$r", s.anna))
        }
        val png = ByteArrayOutputStream().also { ImageIO.write(BufferedImage(8, 8, BufferedImage.TYPE_INT_RGB), "png", it) }.toByteArray()
        val soi = byteArrayOf(0xFF.toByte(), 0xD8.toByte())
        val huge = soi + JpegTest.segment(0xC0, byteArrayOf(8, 0x13, 0x88.toByte(), 0x13, 0x88.toByte(), 1, 1, 0x11, 0)) // 5000 × 5000
        bad(400, "VALIDATION", mapOf("image" to image))
        bad(400, "VALIDATION", mapOf("thumb" to thumb))
        bad(400, "VALIDATION", mapOf("file" to image, "thumb" to thumb))
        bad(400, "NOT_JPEG", mapOf("image" to png, "thumb" to thumb))
        bad(400, "NOT_JPEG", mapOf("image" to image, "thumb" to png))
        bad(400, "IMAGE_TOO_LARGE", mapOf("image" to huge, "thumb" to thumb))
        bad(400, "IMAGE_TOO_LARGE", mapOf("image" to image, "thumb" to JpegTest.jpeg(width = 1025, height = 4)))
        bad(413, "TOO_LARGE", mapOf("image" to image + ByteArray(2_500_000 - image.size), "thumb" to thumb))
        bad(413, "TOO_LARGE", mapOf("image" to image, "thumb" to thumb + ByteArray(204_801 - thumb.size)))
        bad(413, "TOO_LARGE", mapOf("image" to ByteArray(6 * 1024 * 1024), "thumb" to thumb)) // over the multipart cap

        // exactly at both limits: stored, trailing zeros dropped
        val r = UUID.randomUUID().toString()
        assertStatus(201, null, upload(s.anna, s.id, r, mapOf("image" to image + ByteArray(2_097_152 - image.size), "thumb" to thumb + ByteArray(204_800 - thumb.size))))
        assertContentEquals(image, http.get("/groups/${s.id}/attachments/$r", s.anna).bytes)
        assertContentEquals(thumb, http.get("/groups/${s.id}/attachments/$r/thumb", s.anna).bytes)
    }

    @Test
    fun sixtyUploadsAnHour() {
        val s = setup()
        // failed attempts count (parts missing: 400), and the limit comes before every other check
        repeat(60) { assertStatus(400, "VALIDATION", upload(s.ben, s.id, UUID.randomUUID().toString(), mapOf("image" to image))) }
        assertStatus(429, "RATE_LIMITED", upload(s.ben, s.id, UUID.randomUUID().toString()))
        assertStatus(201, null, upload(s.anna, s.id, UUID.randomUUID().toString())) // per user
    }

    @Test
    fun attachEvents() {
        val s = setup()
        val y = UUID.randomUUID().toString()
        check(push(s.anna, s.id, expenseCreated(s.a, 1000, mapOf(s.a to 1000), expenseId = y, description = "Taxi")).status == 200)
        val seq = snapshot(s.anna, s.id)["latestSeq"].asLong()

        // not uploaded, or uploaded to another group (IDOR) → ATTACHMENT_NOT_UPLOADED; nothing is stored
        val nowhere = UUID.randomUUID().toString()
        assertStatus(400, "ATTACHMENT_NOT_UPLOADED", push(s.anna, s.id, added(nowhere, s.x)))
        val other = createGroup(s.anna, name = "Other")["id"].asString()
        val elsewhere = UUID.randomUUID().toString()
        assertStatus(201, null, upload(s.anna, other, elsewhere))
        assertStatus(400, "ATTACHMENT_NOT_UPLOADED", push(s.anna, s.id, added(elsewhere, s.x)))
        // shapes and unknown expenses
        val r = UUID.randomUUID().toString()
        assertStatus(201, null, upload(s.ben, s.id, r))
        assertStatus(400, "VALIDATION", push(s.anna, s.id, added("a1", s.x)))
        assertStatus(400, "VALIDATION", push(s.anna, s.id, added(r, "x1")))
        assertStatus(400, "VALIDATION", push(s.anna, s.id, added(r, null)))
        assertStatus(400, "VALIDATION", push(s.anna, s.id, added(null, s.x)))
        assertStatus(400, "VALIDATION", push(s.anna, s.id, added(r, 5)))
        assertStatus(400, "VALIDATION", push(s.anna, s.id, added(r, UUID.randomUUID().toString())))
        assertStatus(400, "VALIDATION", push(s.anna, s.id, removed("a1")))
        assertStatus(400, "VALIDATION", push(s.anna, s.id, removed(null)))
        assertEquals(seq, snapshot(s.anna, s.id)["latestSeq"].asLong(), "nothing stored")

        // any member attaches an upload of anyone in the group; the same pair again is a no-op, another expense is 400
        assertStatus(200, null, push(s.anna, s.id, added(r, s.x)))
        assertStatus(200, null, push(s.ben, s.id, added(r, s.x)))
        assertStatus(400, "VALIDATION", push(s.anna, s.id, added(r, y)))
        assertEquals(listOf(r), attachments(s.ben, s.id).keys.toList())

        // a new expense and its receipt in one batch
        val z = UUID.randomUUID().toString()
        val zr = UUID.randomUUID().toString()
        assertStatus(201, null, upload(s.anna, s.id, zr))
        assertStatus(200, null, push(s.anna, s.id, expenseCreated(s.a, 500, mapOf(s.a to 500), expenseId = z, description = "Bus"), added(zr, z)))
        assertEquals(z, attachments(s.anna, s.id).getValue(zr)["expenseId"].asString())

        // at most 10 live receipts per expense: the 11th is 409, a removed one frees a place
        repeat(9) { attach(s.ben, s.id, s.x) }
        val eleventh = UUID.randomUUID().toString()
        assertStatus(201, null, upload(s.anna, s.id, eleventh))
        assertStatus(409, "LIMIT_EXCEEDED", push(s.anna, s.id, added(eleventh, s.x)))
        assertStatus(200, null, push(s.anna, s.id, added(eleventh, y))) // another expense still has room
        val twelfth = UUID.randomUUID().toString()
        val thirteenth = UUID.randomUUID().toString()
        assertStatus(201, null, upload(s.anna, s.id, twelfth))
        assertStatus(201, null, upload(s.anna, s.id, thirteenth))
        // a batch whose second add goes over the cap is refused as a whole
        assertStatus(409, "LIMIT_EXCEEDED", push(s.anna, s.id, removed(r), added(twelfth, s.x), added(thirteenth, s.x)))
        assertFalse(attachments(s.anna, s.id).getValue(r)["deleted"].asBoolean())
        assertStatus(200, null, push(s.anna, s.id, removed(r), added(twelfth, s.x)))
        assertEquals(10, attachments(s.anna, s.id).values.count { it["expenseId"].asString() == s.x && !it["deleted"].asBoolean() })

        // the snapshot is what a replay of the pulled log gives (order aside: the snapshot lists uploads in upload order)
        val pulled = http.get("/groups/${s.id}/events?after=0", s.ben).body["events"].values()
        val replayed = pulled.fold(GroupState()) { st, e -> EventApplier.apply(st, e["type"].asString(), e["payload"]) }
        assertEquals(
            SharedJson.canon(replayed.attachments.values.sortedBy { it.id }),
            SharedJson.canon(snapshot(s.ben, s.id)["attachments"].values().sortedBy { it["id"].asString() }),
        )
        assertEquals(0, snapshot(s.anna, other)["attachments"].size(), "the other group is untouched")
    }

    @Test
    fun removingDeletesTheFiles() {
        val s = setup()
        val r = attach(s.anna, s.id, s.x)
        val kept = attach(s.anna, s.id, s.x)
        assertTrue(Files.exists(file(s.id, r)) && Files.exists(file(s.id, r, thumb = true)))

        // another group's member can't reach these files: their delete passes and is ignored (rule 4)
        val t = UUID.randomUUID().toString().take(6)
        val carla = login("Rc-carla-$t")
        val cg = createGroup(carla)["id"].asString()
        assertStatus(200, null, push(carla, cg, removed(r, "expenseId" to s.x)))
        assertTrue(Files.exists(file(s.id, r)) && Files.exists(file(s.id, r, thumb = true)))
        assertFalse(http.get("/groups/$cg/events?after=0", carla).body["events"].values().last()["payload"].has("expenseId"), "unknown id: expenseId dropped")

        // any member removes it; the stored payload names the expense the receipt is on, whatever was sent
        assertStatus(200, null, push(s.ben, s.id, removed(r, "expenseId" to UUID.randomUUID().toString())))
        val stored = http.get("/groups/${s.id}/events?after=0", s.ben).body["events"].values().last()
        assertEquals("attachment.deleted", stored["type"].asString())
        assertEquals(s.x, stored["payload"]["expenseId"].asString())
        awaitUntil("the files are deleted after commit") { !Files.exists(file(s.id, r)) && !Files.exists(file(s.id, r, thumb = true)) }
        assertStatus(404, "NOT_FOUND", http.get("/groups/${s.id}/attachments/$r", s.anna))
        assertStatus(404, "NOT_FOUND", http.get("/groups/${s.id}/attachments/$r/thumb", s.anna))
        assertTrue(attachments(s.anna, s.id).getValue(r)["deleted"].asBoolean())
        assertStatus(200, null, upload(s.anna, s.id, r)) // the row stays: a late retry of the upload is still 200
        assertStatus(404, "NOT_FOUND", http.get("/groups/${s.id}/attachments/$r", s.anna))

        // a second delete, a re-add and a retried push change nothing and are hidden
        val seq = snapshot(s.anna, s.id)["latestSeq"].asLong()
        val again = removed(r)
        assertStatus(200, null, push(s.anna, s.id, again, added(r, s.x)))
        assertStatus(200, null, push(s.anna, s.id, again))
        // the uppercase form of the id would miss it in the state yet revive (or move) its row: only lowercase ids pass
        assertStatus(400, "VALIDATION", push(s.anna, s.id, added(r.uppercase(), s.x)))
        assertEquals(seq + 2, snapshot(s.anna, s.id)["latestSeq"].asLong())
        assertTrue(attachments(s.anna, s.id).getValue(r)["deleted"].asBoolean())

        // the expense's History finds receipts (attachment.deleted by its normalized expenseId)
        val history = http.get("/groups/${s.id}/activity?expenseId=${s.x}", s.anna).body["items"].values().map { it["kind"].asString() }
        assertEquals(listOf("receipt_removed", "receipt_added", "receipt_added", "expense_added"), history)

        // deleting the expense keeps its receipts; a receipt can still be attached to it, and a restore shows them all
        assertStatus(200, null, push(s.anna, s.id, event("expense.deleted", mapOf("expenseId" to s.x))))
        assertTrue(Files.exists(file(s.id, kept)))
        val late = attach(s.ben, s.id, s.x)
        assertStatus(200, null, push(s.anna, s.id, event("expense.restored", mapOf("expenseId" to s.x))))
        val live = attachments(s.ben, s.id).filterValues { !it["deleted"].asBoolean() }.keys
        assertEquals(setOf(kept, late), live)
        assertContentEquals(image, http.get("/groups/${s.id}/attachments/$late", s.ben).bytes)
    }

    @Test
    fun activityAndPush() {
        val s = setup()
        val benDevice = device(s.ben)
        // a new expense saved with its receipt: one sentence for the expense, not "made 2 changes"
        val y = UUID.randomUUID().toString()
        val r = UUID.randomUUID().toString()
        assertStatus(201, null, upload(s.anna, s.id, r))
        assertStatus(200, null, push(s.anna, s.id, expenseCreated(s.a, 2000, mapOf(s.a to 1000, s.b to 1000), expenseId = y, description = "Taxi"), added(r, y)))
        awaitUntil("Ben's push") { capture.to(benDevice).any { it.body != null } }
        assertEquals("Me added “Taxi” · €20.00 · you owe €10.00", capture.to(benDevice).first { it.body != null }.body)

        // a receipt on its own (sent when the batch window ends)
        attach(s.anna, s.id, s.x)
        awaitUntil("Ben's receipt push") { capture.to(benDevice).count { it.body != null } == 2 }
        assertEquals("Me added a receipt to “Dinner”", capture.to(benDevice).last { it.body != null }.body)

        // the feed keeps both rows; Ben's removal reads as his
        assertStatus(200, null, push(s.ben, s.id, removed(r)))
        val items = http.get("/groups/${s.id}/activity?limit=4", s.anna).body["items"].values().toList()
        assertEquals(listOf("receipt_removed", "receipt_added", "receipt_added", "expense_added"), items.map { it["kind"].asString() })
        assertEquals(listOf(y, s.b, "Taxi"), listOf("expenseId", "actorMemberId", "description").map { items[0][it].asString() })
        assertTrue(items[0]["amount"].isNull && items[0]["myDelta"].isNull, "${items[0]}")

        // receipts are in the expenses push category
        assertFalse(NotificationPrefs(expenses = false).allows("receipt_added"))
        assertFalse(NotificationPrefs(expenses = false).allows("receipt_removed"))
        assertTrue(NotificationPrefs(comments = false, members = false).allows("receipt_added"))
    }

    @Test
    fun zipWithReceipts() {
        val s = setup()
        val gone = UUID.randomUUID().toString()
        check(push(s.anna, s.id, expenseCreated(s.a, 800, mapOf(s.a to 800), expenseId = gone, description = "Gone")).status == 200)
        val live = attach(s.anna, s.id, s.x)
        val removedOne = attach(s.anna, s.id, s.x)
        val onDeleted = attach(s.ben, s.id, gone)
        val noFile = attach(s.ben, s.id, s.x)
        assertStatus(201, null, upload(s.anna, s.id, UUID.randomUUID().toString())) // never attached: not in the ZIP
        assertStatus(200, null, push(s.anna, s.id, removed(removedOne), event("expense.deleted", mapOf("expenseId" to gone))))
        Files.delete(file(s.id, noFile)) // a missing file is skipped

        val res = http.get("/groups/${s.id}/export?format=zip", s.ben)
        assertEquals(200, res.status, res.text)
        assertEquals("application/zip", res.headers["content-type"])
        assertEquals("attachment; filename=\"evensies-${s.id}.zip\"", res.headers["content-disposition"])
        val entries = LinkedHashMap<String, ByteArray>()
        ZipInputStream(ByteArrayInputStream(res.bytes)).use { zip ->
            generateSequence { zip.nextEntry }.forEach { entries[it.name] = zip.readAllBytes() }
        }
        assertEquals(setOf("group.json", "receipts/$live.jpg", "receipts/$onDeleted.jpg"), entries.keys)
        assertContentEquals(image, entries.getValue("receipts/$live.jpg"))
        val json = http.get("/groups/${s.id}/export?format=json", s.ben)
        assertEquals(SharedJson.canon(json.body), SharedJson.canon(mapper.readTree(entries.getValue("group.json"))))
        assertEquals(4, json.body["attachments"].size())

        val stranger = login("Rc-zip-${UUID.randomUUID().toString().take(6)}")
        assertStatus(403, "FORBIDDEN", http.get("/groups/${s.id}/export?format=zip", stranger))
        assertStatus(404, "NOT_FOUND", http.get("/groups/${UUID.randomUUID()}/export?format=zip", s.anna))
        assertStatus(400, "VALIDATION", http.get("/groups/${s.id}/export?format=pdf", s.anna))
        assertEquals(200, http.get("/groups/${s.id}/export", s.anna).status, "json stays the default")
    }

    /** Phase 8 daily sweep (docs/API.md "Recurring expenses", daily clean-up): week-old unattached uploads go, rows and files; deleted rows lose their files. */
    @Test
    fun sweepRemovesStaleUploads() {
        val s = setup()
        val stale = UUID.randomUUID().toString()
        val fresh = UUID.randomUUID().toString()
        assertStatus(201, null, upload(s.anna, s.id, stale))
        assertStatus(201, null, upload(s.anna, s.id, fresh))
        val attached = attach(s.anna, s.id, s.x)
        val removedOne = attach(s.anna, s.id, s.x)
        assertStatus(200, null, push(s.anna, s.id, removed(removedOne)))
        awaitUntil("files of the removed receipt deleted after commit") { !Files.exists(file(s.id, removedOne)) }
        Files.write(file(s.id, removedOne), image) // as if a crash came between the commit and the file deletion
        jdbc.sql("UPDATE attachments SET created_at = now() - interval '8 days' WHERE id IN (:ids)")
            .param("ids", listOf(stale, attached).map(UUID::fromString)).update()

        sweep.run()

        fun rowExists(id: String) = jdbc.sql("SELECT count(*) FROM attachments WHERE id = :id").param("id", UUID.fromString(id)).query(Long::class.java).single() > 0
        assertFalse(rowExists(stale))
        assertFalse(Files.exists(file(s.id, stale)) || Files.exists(file(s.id, stale, thumb = true)))
        assertStatus(404, "NOT_FOUND", http.get("/groups/${s.id}/attachments/$stale", s.anna))
        for (kept in listOf(fresh, attached)) {
            assertTrue(rowExists(kept))
            assertTrue(Files.exists(file(s.id, kept)) && Files.exists(file(s.id, kept, thumb = true)))
        }
        assertTrue(rowExists(removedOne), "a deleted receipt keeps its row")
        assertFalse(Files.exists(file(s.id, removedOne)))
        assertEquals(setOf(attached, removedOne), attachments(s.anna, s.id).keys)
    }
}
