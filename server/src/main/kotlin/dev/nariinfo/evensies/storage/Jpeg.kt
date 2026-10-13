package dev.nariinfo.evensies.storage

import dev.nariinfo.evensies.common.ApiException
import java.io.ByteArrayOutputStream

/**
 * Strips metadata from an uploaded JPEG by walking its markers, without decoding pixels (the app has already
 * re-encoded the image; the server never decodes untrusted pixels). docs/API.md "Profile photos".
 */
object Jpeg {
    /**
     * Keeps APP0 (JFIF) and APP14 (Adobe colour transform) and every coding segment (DQT, DHT, SOFn, DRI, SOS and the
     * entropy-coded data, several scans for progressive JPEGs); drops APP1–APP13, APP15 and COM (EXIF incl. GPS, XMP,
     * IPTC, embedded thumbnails) and everything after EOI. 400 NOT_JPEG for anything malformed (no SOI, a segment
     * running past the end, no EOI, SOS before SOFn); 400 IMAGE_TOO_LARGE when SOFn says an edge is over [maxEdge].
     */
    fun clean(b: ByteArray, maxEdge: Int): ByteArray {
        fun u(i: Int) = b[i].toInt() and 0xFF
        val n = b.size
        if (n < 4 || u(0) != 0xFF || u(1) != 0xD8) notJpeg()
        val out = ByteArrayOutputStream(n)
        out.write(b, 0, 2)
        var i = 2
        var frame = false
        while (true) {
            if (i >= n || u(i) != 0xFF) notJpeg()
            while (i < n && u(i) == 0xFF) i++ // fill bytes
            if (i >= n) notJpeg()
            val marker = u(i++)
            if (marker == 0xD9) { // EOI: trailing bytes are dropped
                out.write(0xFF); out.write(0xD9)
                return out.toByteArray()
            }
            if (marker in 0xD0..0xD7 || marker == 0x01) { out.write(0xFF); out.write(marker); continue } // no length
            if (marker == 0x00 || i + 2 > n) notJpeg()
            val len = (u(i) shl 8) or u(i + 1)
            if (len < 2 || i + len > n) notJpeg()
            if (marker in 0xC0..0xCF && marker != 0xC4 && marker != 0xC8 && marker != 0xCC) { // SOFn (not DHT, JPG, DAC)
                if (len < 8) notJpeg()
                val height = (u(i + 3) shl 8) or u(i + 4)
                val width = (u(i + 5) shl 8) or u(i + 6)
                if (width > maxEdge || height > maxEdge) throw ApiException.badRequest("IMAGE_TOO_LARGE", "The image is larger than $maxEdge px")
                frame = true
            }
            if (!(marker in 0xE1..0xED || marker == 0xEF || marker == 0xFE)) { out.write(0xFF); out.write(marker); out.write(b, i, len) }
            i += len
            if (marker != 0xDA) continue
            // SOS: entropy-coded data up to the next marker; FF00 (a stuffed FF) and RSTn are part of it.
            if (!frame) notJpeg()
            val start = i
            while (true) {
                if (i >= n) notJpeg()
                if (u(i) == 0xFF) {
                    var j = i + 1
                    while (j < n && u(j) == 0xFF) j++
                    if (j >= n) notJpeg()
                    if (u(j) != 0x00 && u(j) !in 0xD0..0xD7) break
                    i = j + 1
                } else {
                    i++
                }
            }
            out.write(b, start, i - start)
        }
    }

    private fun notJpeg(): Nothing = throw ApiException.badRequest("NOT_JPEG", "The file is not a JPEG")
}
