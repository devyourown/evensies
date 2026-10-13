package dev.nariinfo.evensies.storage

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.common.RateLimiter
import dev.nariinfo.evensies.config.userId
import dev.nariinfo.evensies.group.GroupService
import dev.nariinfo.evensies.sync.EventService
import dev.nariinfo.evensies.sync.IncomingEvent
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.multipart.MultipartFile
import tools.jackson.databind.node.JsonNodeFactory
import java.nio.file.Files
import java.time.Instant
import java.util.UUID

data class CoverDto(val coverImageId: UUID, val latestSeq: Long)

/**
 * Group cover photos (docs/API.md "Group types, covers and deletion"), visible to members only. An upload is cleaned like every image (Phase 6
 * [Jpeg.clean]), stored under a new id and set by a `group.updated {coverImageId}` from the uploader; the replaced file
 * goes after commit ([EventService.pushValidated]) and the daily [Sweep] removes any file that isn't the current one.
 */
@RestController
@RequestMapping("/groups/{id}/cover")
class CoverController(private val files: FileStore, private val groups: GroupService, private val events: EventService) {
    /** Abuse cap; failed attempts count too. */
    private val uploads = RateLimiter(capacity = UPLOADS_PER_HOUR.toDouble(), refillPerSecond = UPLOADS_PER_HOUR / 3600.0)

    @PutMapping
    fun put(auth: Authentication, @PathVariable id: UUID, @RequestParam(required = false) file: MultipartFile?): CoverDto {
        groups.requireMember(id, auth.userId)
        if (!uploads.tryConsume(auth.userId)) throw ApiException.tooManyRequests("Too many cover uploads, try again later")
        if (file == null) throw ApiException.badRequest("VALIDATION", "Send the photo as the multipart part 'file'")
        if (file.size > MAX_BYTES) throw ApiException(HttpStatus.PAYLOAD_TOO_LARGE, "TOO_LARGE", "The photo is larger than $MAX_BYTES bytes")
        val clean = Jpeg.clean(file.bytes, MAX_EDGE)
        val coverId = UUID.randomUUID()
        files.write(key(id, coverId), clean)
        val payload = JsonNodeFactory.instance.objectNode().put("coverImageId", coverId.toString())
        val result = try {
            events.pushValidated(id, auth.userId, listOf(IncomingEvent(UUID.randomUUID(), "group.updated", payload, Instant.now())))
        } catch (e: Exception) {
            files.delete(key(id, coverId))
            throw e
        }
        return CoverDto(coverId, result.latestSeq)
    }

    /** Membership first (404/403); only the current cover is served (404 for an old or unknown id). */
    @GetMapping("/{coverId}")
    fun get(auth: Authentication, @PathVariable id: UUID, @PathVariable coverId: UUID): ResponseEntity<ByteArray> {
        val (group, _) = groups.requireMember(id, auth.userId)
        if (group.coverImageId != coverId) throw ApiException.notFound("Cover")
        val path = files.path(key(id, coverId)) ?: throw ApiException.notFound("Cover")
        return ResponseEntity.ok().contentType(MediaType.IMAGE_JPEG)
            .header("Cache-Control", "private, max-age=31536000, immutable").header("X-Content-Type-Options", "nosniff")
            .body(Files.readAllBytes(path))
    }

    companion object {
        const val MAX_BYTES = 1_048_576L
        const val MAX_EDGE = 2048
        const val UPLOADS_PER_HOUR = 20

        /** Built from parsed UUIDs only. */
        fun key(groupId: UUID, coverId: UUID) = "covers/$groupId/$coverId.jpg"
    }
}
