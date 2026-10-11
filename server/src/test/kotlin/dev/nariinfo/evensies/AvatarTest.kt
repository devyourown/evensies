package dev.nariinfo.evensies

import org.springframework.http.HttpMethod
import org.junit.jupiter.api.Test
import java.awt.image.BufferedImage
import java.io.ByteArrayOutputStream
import java.nio.file.Files
import java.util.UUID
import javax.imageio.ImageIO
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** PUT/DELETE /me/avatar and GET /users/{id}/avatar (docs/API.md "프로필 사진"). */
class AvatarTest : IntegrationTestBase() {
    private fun upload(token: String, bytes: ByteArray, field: String = "file") =
        http.upload("/me/avatar", field, "me.jpg", bytes, token, HttpMethod.PUT)

    private fun file(userId: String) = storageDir.resolve("avatars/$userId.jpg")

    @Test
    fun uploadCleansAndOnlySharedGroupsCanSee() {
        val t = UUID.randomUUID().toString().take(6)
        val anna = login("Av-anna-$t")
        val ben = login("Av-ben-$t")
        val stranger = login("Av-stranger-$t")
        val annaId = myId(anna)
        val benId = myId(ben)
        join(ben, createGroup(anna), "Ben")

        val plain = JpegTest.jpeg()
        assertEquals(204, upload(anna, JpegTest.withMetadata(plain)).status)
        for (viewer in listOf(anna, ben)) {
            val res = http.get("/users/$annaId/avatar", viewer)
            assertEquals(200, res.status)
            assertContentEquals(plain, res.bytes, "EXIF, comments and trailing bytes are gone")
            assertEquals("image/jpeg", res.headers["content-type"])
            assertEquals("private, max-age=3600", res.headers["cache-control"])
            assertEquals("nosniff", res.headers["x-content-type-options"])
        }
        assertEquals(403, http.get("/users/$annaId/avatar", stranger).status)
        assertEquals(403, http.get("/users/$benId/avatar", stranger).status, "403 before 404: no hint whether there is a photo")
        assertEquals(403, http.get("/users/${UUID.randomUUID()}/avatar", stranger).status)
        assertEquals(404, http.get("/users/$benId/avatar", anna).status)
        assertEquals(404, http.get("/users/$benId/avatar", ben).status)
        assertEquals(401, http.get("/users/$annaId/avatar").status)

        // replace, then delete (twice: still 204)
        val other = JpegTest.jpeg(width = 20, height = 20)
        assertEquals(204, upload(anna, other).status)
        assertContentEquals(other, http.get("/users/$annaId/avatar", ben).bytes)
        assertEquals(204, http.delete("/me/avatar", anna).status)
        assertEquals(404, http.get("/users/$annaId/avatar", ben).status)
        assertEquals(204, http.delete("/me/avatar", anna).status)

        // account deletion removes the file
        assertEquals(204, upload(ben, plain).status)
        assertTrue(Files.exists(file(benId)))
        assertEquals(204, http.delete("/me", ben).status)
        assertFalse(Files.exists(file(benId)))
        assertEquals(403, http.get("/users/$benId/avatar", anna).status, "the deleted account no longer shares a group")
    }

    @Test
    fun rejectedUploads() {
        val anna = login("Av-bad-${UUID.randomUUID().toString().take(6)}")
        fun assertError(status: Int, code: String, res: Http.Resp) {
            assertEquals(status, res.status, res.text)
            assertEquals(code, res.code(), res.text)
        }
        val png = ByteArrayOutputStream().also { ImageIO.write(BufferedImage(8, 8, BufferedImage.TYPE_INT_RGB), "png", it) }.toByteArray()
        assertError(400, "NOT_JPEG", upload(anna, png))
        val soi = byteArrayOf(0xFF.toByte(), 0xD8.toByte())
        assertError(400, "IMAGE_TOO_LARGE", upload(anna, soi + JpegTest.segment(0xC0, byteArrayOf(8, 0x13, 0x88.toByte(), 0x13, 0x88.toByte(), 1, 1, 0x11, 0))))
        val big = JpegTest.jpeg()
        assertError(413, "TOO_LARGE", upload(anna, big + ByteArray(307_201 - big.size)))
        assertEquals(204, upload(anna, JpegTest.withMetadata(big).let { it + ByteArray(307_200 - it.size) }).status, "exactly 300 KB, trailing zeros dropped")
        assertError(413, "TOO_LARGE", upload(anna, ByteArray(6 * 1024 * 1024)))
        // the same with a Content-Length (as the app's HTTP client sends it): rejected before the body is read
        val boundary = "b0undary"
        val form = "--$boundary\r\nContent-Disposition: form-data; name=\"file\"; filename=\"me.jpg\"\r\n\r\n".toByteArray() +
            ByteArray(6 * 1024 * 1024) + "\r\n--$boundary--\r\n".toByteArray()
        val sized = java.net.http.HttpClient.newHttpClient().send(
            java.net.http.HttpRequest.newBuilder(java.net.URI("http://localhost:$port/me/avatar")).header("Authorization", "Bearer $anna")
                .header("Content-Type", "multipart/form-data; boundary=$boundary").PUT(java.net.http.HttpRequest.BodyPublishers.ofByteArray(form)).build(),
            java.net.http.HttpResponse.BodyHandlers.ofString(),
        )
        assertEquals(413 to true, sized.statusCode() to sized.body().contains("TOO_LARGE"))
        assertError(400, "VALIDATION", upload(anna, big, field = "photo"))
        // 10 attempts per hour, failed ones included: 5 so far (the 6 MB one never reached the controller)
        repeat(5) { assertEquals(400, upload(anna, png).status) }
        assertError(429, "RATE_LIMITED", upload(anna, big))
    }
}
