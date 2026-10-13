package dev.nariinfo.evensies

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.storage.Jpeg
import org.junit.jupiter.api.Test
import java.awt.image.BufferedImage
import java.io.ByteArrayOutputStream
import javax.imageio.IIOImage
import javax.imageio.ImageIO
import javax.imageio.ImageWriteParam
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse

/** storage/Jpeg.clean: metadata out, coding segments untouched, nothing decoded (docs/API.md "Profile photos"). */
class JpegTest {
    companion object {
        /** A real JPEG from the JDK encoder: SOI, APP0 (JFIF), DQT, SOF, DHT, SOS…, EOI, no other metadata. */
        fun jpeg(width: Int = 40, height: Int = 30, progressive: Boolean = false): ByteArray {
            val img = BufferedImage(width, height, BufferedImage.TYPE_INT_RGB)
            for (x in 0 until width) for (y in 0 until height) img.setRGB(x, y, (x * 6 shl 16) or (y * 8 shl 8) or 0x40)
            val writer = ImageIO.getImageWritersByFormatName("jpeg").next()
            val out = ByteArrayOutputStream()
            ImageIO.createImageOutputStream(out).use { ios ->
                writer.output = ios
                val param = writer.defaultWriteParam
                if (progressive) param.progressiveMode = ImageWriteParam.MODE_DEFAULT
                writer.write(null, IIOImage(img, null, null), param)
            }
            writer.dispose()
            return out.toByteArray()
        }

        fun segment(marker: Int, payload: ByteArray): ByteArray =
            byteArrayOf(0xFF.toByte(), marker.toByte(), ((payload.size + 2) shr 8).toByte(), (payload.size + 2).toByte()) + payload

        /** [plain] with EXIF (GPS), XMP-ish APP1, IPTC (APP13), a comment and trailing bytes added. */
        fun withMetadata(plain: ByteArray): ByteArray =
            plain.copyOfRange(0, 2) +
                segment(0xE1, "Exif\u0000\u0000GPSLatitude 37.5665".toByteArray()) +
                segment(0xED, "Photoshop 3.0 IPTC".toByteArray()) +
                plain.copyOfRange(2, plain.size - 2) + // between SOI and EOI
                segment(0xFE, "secret comment".toByteArray()) +
                plain.copyOfRange(plain.size - 2, plain.size) + "TRAILER".toByteArray()

        private fun String.foundIn(b: ByteArray) = String(b, Charsets.ISO_8859_1).contains(this)
    }

    private fun code(block: () -> Unit) = assertFailsWith<ApiException> { block() }.code

    @Test
    fun metadataAndTrailingBytesGoAndTheImageStaysTheSame() {
        for (progressive in listOf(false, true)) {
            val plain = jpeg(progressive = progressive)
            val clean = Jpeg.clean(withMetadata(plain), 1024)
            for (s in listOf("Exif", "GPS", "Photoshop", "secret", "TRAILER")) assertFalse(s.foundIn(clean), "$s, progressive=$progressive")
            assertContentEquals(plain, clean, "only the added segments are removed (progressive=$progressive)")
            val img = ImageIO.read(clean.inputStream())
            assertEquals(40 to 30, img.width to img.height)
        }
    }

    @Test
    fun scanDataKeepsStuffedBytesAndRestartMarkers() {
        val sof = segment(0xC0, byteArrayOf(8, 0, 2, 0, 2, 1, 1, 0x11, 0))
        val sos = segment(0xDA, byteArrayOf(1, 1, 0, 0, 0x3F, 0))
        val data = byteArrayOf(0x12, 0xFF.toByte(), 0x00, 0x34, 0xFF.toByte(), 0xD0.toByte(), 0x56)
        val eoi = byteArrayOf(0xFF.toByte(), 0xD9.toByte())
        val soi = byteArrayOf(0xFF.toByte(), 0xD8.toByte())
        val file = soi + segment(0xE0, "JFIF\u0000".toByteArray()) + sof + sos + data + segment(0xE1, "Exif".toByteArray()) + eoi
        assertContentEquals(soi + segment(0xE0, "JFIF\u0000".toByteArray()) + sof + sos + data + eoi, Jpeg.clean(file, 1024))
    }

    @Test
    fun rejectsWhatIsNotAJpegWithoutDecoding() {
        val png = ByteArrayOutputStream().also { ImageIO.write(BufferedImage(4, 4, BufferedImage.TYPE_INT_RGB), "png", it) }.toByteArray()
        assertEquals("NOT_JPEG", code { Jpeg.clean(png, 1024) })
        assertEquals("NOT_JPEG", code { Jpeg.clean(ByteArray(0), 1024) })
        val plain = jpeg()
        assertEquals("NOT_JPEG", code { Jpeg.clean(plain.copyOfRange(0, plain.size / 2), 1024) }, "truncated, no EOI")
        val soi = byteArrayOf(0xFF.toByte(), 0xD8.toByte())
        assertEquals("NOT_JPEG", code { Jpeg.clean(soi + byteArrayOf(0xFF.toByte(), 0xE1.toByte(), 0x7F, 0x00, 1, 2), 1024) }, "segment past the end")
        assertEquals("NOT_JPEG", code { Jpeg.clean(soi + segment(0xDA, byteArrayOf(1, 1, 0, 0, 0x3F, 0)) + byteArrayOf(0xFF.toByte(), 0xD9.toByte()), 1024) }, "SOS before SOF")
        // A header that claims 5000 × 5000 is refused from the SOF alone: there are no pixels to decode here.
        val huge = soi + segment(0xC2, byteArrayOf(8, 0x13, 0x88.toByte(), 0x13, 0x88.toByte(), 1, 1, 0x11, 0))
        assertEquals("IMAGE_TOO_LARGE", code { Jpeg.clean(huge, 1024) })
        assertEquals("IMAGE_TOO_LARGE", code { Jpeg.clean(jpeg(width = 1025, height = 10), 1024) })
        Jpeg.clean(jpeg(width = 1024, height = 10), 1024) // the edge itself is fine
    }
}
