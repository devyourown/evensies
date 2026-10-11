package dev.nariinfo.evensies.storage

import dev.nariinfo.evensies.auth.AuthService
import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.common.RateLimiter
import dev.nariinfo.evensies.config.userId
import dev.nariinfo.evensies.group.MemberRepository
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.DeleteMapping
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.multipart.MultipartFile
import java.nio.file.Files
import java.util.UUID

/** Profile photos (docs/API.md "프로필 사진"): visible to the user and to anyone sharing a group with them. */
@RestController
class AvatarController(private val files: FileStore, private val members: MemberRepository, private val auth: AuthService) {
    /** Failed attempts count too, so a client can't probe the parser in a loop. */
    private val uploads = RateLimiter(capacity = UPLOADS_PER_HOUR.toDouble(), refillPerSecond = UPLOADS_PER_HOUR / 3600.0)

    @PutMapping("/me/avatar")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun put(authentication: Authentication, @RequestParam(required = false) file: MultipartFile?) {
        val me = authentication.userId
        if (!uploads.tryConsume(me)) throw ApiException.tooManyRequests("Too many photo uploads, try again later")
        if (file == null) throw ApiException.badRequest("VALIDATION", "Send the photo as the multipart part 'file'")
        if (file.size > MAX_BYTES) throw ApiException(HttpStatus.PAYLOAD_TOO_LARGE, "TOO_LARGE", "The photo is larger than $MAX_BYTES bytes")
        val clean = Jpeg.clean(file.bytes, MAX_EDGE)
        auth.me(me) // 401 for deleted accounts
        files.write(key(me), clean)
    }

    @DeleteMapping("/me/avatar")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun delete(authentication: Authentication) = files.delete(key(authentication.userId))

    /** 403 before 404, so a stranger can't tell whether someone has a photo. */
    @GetMapping("/users/{userId}/avatar")
    fun get(authentication: Authentication, @PathVariable userId: UUID): ResponseEntity<ByteArray> {
        val me = authentication.userId
        if (me != userId && members.sharedGroups(me, userId).isEmpty()) throw ApiException.forbidden("You don't share a group with this person")
        val path = files.path(key(userId)) ?: throw ApiException.notFound("Photo")
        return ResponseEntity.ok().contentType(MediaType.IMAGE_JPEG)
            .header("Cache-Control", "private, max-age=3600").header("X-Content-Type-Options", "nosniff")
            .body(Files.readAllBytes(path))
    }

    companion object {
        const val MAX_BYTES = 307_200L
        const val MAX_EDGE = 1024
        const val UPLOADS_PER_HOUR = 10

        fun key(userId: UUID) = "avatars/$userId.jpg"
    }
}
