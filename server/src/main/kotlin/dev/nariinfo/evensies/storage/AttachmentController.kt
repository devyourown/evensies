package dev.nariinfo.evensies.storage

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.common.RateLimiter
import dev.nariinfo.evensies.config.userId
import dev.nariinfo.evensies.group.GroupService
import dev.nariinfo.evensies.sync.GroupStateStore
import org.springframework.dao.DuplicateKeyException
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.multipart.MultipartFile
import java.nio.file.Files
import java.util.UUID

/**
 * Receipt photos (docs/API.md "영수증"): uploaded first, then attached by an `attachment.added` event. Only members
 * of the group can download them. The app makes the id, so a retried upload is safe (the first write wins).
 */
@RestController
@RequestMapping("/groups/{id}/attachments/{attachmentId}")
class AttachmentController(private val files: FileStore, private val groups: GroupService, private val stateStore: GroupStateStore) {
    /** Abuse cap; failed attempts and 200 retries count too. */
    private val uploads = RateLimiter(capacity = UPLOADS_PER_HOUR.toDouble(), refillPerSecond = UPLOADS_PER_HOUR / 3600.0)

    @PostMapping
    fun upload(
        auth: Authentication,
        @PathVariable id: UUID,
        @PathVariable attachmentId: UUID,
        @RequestParam(required = false) image: MultipartFile?,
        @RequestParam(required = false) thumb: MultipartFile?,
    ): ResponseEntity<Map<String, UUID>> {
        groups.requireMember(id, auth.userId)
        if (!uploads.tryConsume(auth.userId)) throw ApiException.tooManyRequests("Too many receipt uploads, try again later")
        if (image == null || thumb == null) throw ApiException.badRequest("VALIDATION", "Send the multipart parts 'image' and 'thumb'")
        if (image.size > MAX_IMAGE_BYTES || thumb.size > MAX_THUMB_BYTES) {
            throw ApiException(HttpStatus.PAYLOAD_TOO_LARGE, "TOO_LARGE", "image must be at most $MAX_IMAGE_BYTES bytes, thumb $MAX_THUMB_BYTES")
        }
        existing(id, attachmentId)?.let { return it }
        val cleanImage = Jpeg.clean(image.bytes, MAX_IMAGE_EDGE)
        val cleanThumb = Jpeg.clean(thumb.bytes, MAX_THUMB_EDGE)
        val (imageKey, thumbKey) = keys(id, attachmentId)
        // Files before the row: a row always has its files. A crash in between leaves files the Phase 8 sweep removes.
        files.write(imageKey, cleanImage)
        files.write(thumbKey, cleanThumb)
        try {
            stateStore.insertUpload(id, attachmentId, auth.userId)
        } catch (e: DuplicateKeyException) {
            // A concurrent upload of the same id won (an app retry, so the same photo). ponytail: if it was another
            // group's, the files just written stay without a row; the Phase 8 sweep can list orphan files if that matters.
            return existing(id, attachmentId) ?: throw e
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(mapOf("id" to attachmentId))
    }

    /** 200 for this group's row (deleted or not, files untouched), 409 for another group's, null when new. */
    private fun existing(groupId: UUID, attachmentId: UUID): ResponseEntity<Map<String, UUID>>? {
        val owner = stateStore.uploadGroup(attachmentId) ?: return null
        if (owner != groupId) throw ApiException(HttpStatus.CONFLICT, "DUPLICATE", "This id is already used in another group")
        return ResponseEntity.ok(mapOf("id" to attachmentId))
    }

    @GetMapping
    fun image(auth: Authentication, @PathVariable id: UUID, @PathVariable attachmentId: UUID) = download(auth, id, attachmentId, thumb = false)

    @GetMapping("/thumb")
    fun thumb(auth: Authentication, @PathVariable id: UUID, @PathVariable attachmentId: UUID) = download(auth, id, attachmentId, thumb = true)

    /** Membership first (404/403); an unknown, other-group or deleted id, or a missing file, is 404. */
    private fun download(auth: Authentication, groupId: UUID, attachmentId: UUID, thumb: Boolean): ResponseEntity<ByteArray> {
        groups.requireMember(groupId, auth.userId)
        if (!stateStore.isLiveUpload(groupId, attachmentId)) throw ApiException.notFound("Receipt")
        val path = files.path(keys(groupId, attachmentId).let { if (thumb) it.second else it.first }) ?: throw ApiException.notFound("Receipt")
        return ResponseEntity.ok().contentType(MediaType.IMAGE_JPEG)
            .header("Cache-Control", "private, max-age=31536000, immutable").header("X-Content-Type-Options", "nosniff")
            .body(Files.readAllBytes(path))
    }

    companion object {
        const val MAX_IMAGE_BYTES = 2_097_152L
        const val MAX_THUMB_BYTES = 204_800L
        const val MAX_IMAGE_EDGE = 4096
        const val MAX_THUMB_EDGE = 1024
        const val UPLOADS_PER_HOUR = 60

        /** Image and thumbnail keys, built from parsed UUIDs only. */
        fun keys(groupId: UUID, attachmentId: UUID) = "attachments/$groupId/$attachmentId.jpg" to "attachments/$groupId/${attachmentId}_thumb.jpg"
    }
}
