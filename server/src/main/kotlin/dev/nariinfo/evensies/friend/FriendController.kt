package dev.nariinfo.evensies.friend

import dev.nariinfo.evensies.config.userId
import dev.nariinfo.evensies.group.CodeLookupLimiter
import dev.nariinfo.evensies.group.GroupDto
import dev.nariinfo.evensies.group.landingPage
import jakarta.servlet.http.HttpServletRequest
import org.springframework.http.MediaType
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RestController
import tools.jackson.databind.JsonNode
import java.util.UUID

@RestController
class FriendController(private val friends: FriendService, private val limiter: CodeLookupLimiter) {
    @GetMapping("/me/friend-code")
    fun code(auth: Authentication): FriendCodeDto = friends.friendCode(auth.userId, rotate = false)

    @PostMapping("/me/friend-code/rotate")
    fun rotate(auth: Authentication): FriendCodeDto = friends.friendCode(auth.userId, rotate = true)

    @GetMapping("/friend-invites/{code}")
    fun preview(@PathVariable code: String, request: HttpServletRequest): FriendPreviewDto {
        limiter.throttle(request)
        return friends.preview(code)
    }

    /** Friend link landing page for people without the app. */
    @GetMapping("/f/{code}", produces = [MediaType.TEXT_HTML_VALUE])
    fun landing(@PathVariable code: String, request: HttpServletRequest): String {
        limiter.throttle(request)
        val name = friends.preview(code).displayName.ifBlank { "Someone" }
        return landingPage(
            title = "$name on Evensies", heading = name, text = "$name wants to split expenses with you.",
            code = code, appLink = "evensies://f/$code",
        )
    }

    @PostMapping("/friends")
    fun add(auth: Authentication, @RequestBody body: JsonNode, request: HttpServletRequest): GroupDto =
        friends.add(auth.userId, body) { limiter.throttle(request) }

    @PostMapping("/friends/{userId}/remind")
    fun remind(auth: Authentication, @PathVariable userId: UUID): RemindResult = friends.remind(auth.userId, userId)
}
