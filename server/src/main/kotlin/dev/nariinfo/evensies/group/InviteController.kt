package dev.nariinfo.evensies.group

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.common.RateLimiter
import dev.nariinfo.evensies.config.AppProperties
import dev.nariinfo.evensies.config.userId
import jakarta.servlet.http.HttpServletRequest
import org.springframework.http.MediaType
import org.springframework.security.core.Authentication
import org.springframework.stereotype.Component
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.util.HtmlUtils

/**
 * Codes are short, so every lookup of a group invite or friend code shares one bucket per client IP to make guessing
 * impractical (docs/API.md "초대 코드", "친구 코드").
 */
@Component
class CodeLookupLimiter(props: AppProperties) {
    private val limiter = RateLimiter(capacity = props.inviteRatePerMinute, refillPerSecond = props.inviteRatePerMinute / 60)

    fun throttle(request: HttpServletRequest) {
        if (!limiter.tryConsume(request.remoteAddr)) throw ApiException.tooManyRequests("Too many invite attempts, try again in a minute")
    }
}

@RestController
class InviteController(private val groups: GroupService, private val limiter: CodeLookupLimiter) {
    @GetMapping("/invites/{code}")
    fun preview(@PathVariable code: String, request: HttpServletRequest): InvitePreviewDto {
        limiter.throttle(request)
        return groups.preview(code)
    }

    @PostMapping("/invites/{code}/join")
    fun join(auth: Authentication, @PathVariable code: String, @RequestBody req: JoinRequest, request: HttpServletRequest): GroupDto {
        limiter.throttle(request)
        return groups.join(code, auth.userId, req)
    }

    /**
     * Invite landing page for people without the app. A friend group's name ("Anna & Ben") is for exports only, so a
     * placeholder friend's link names the person who added them (docs/API.md "친구 그룹 규칙").
     */
    @GetMapping("/j/{code}", produces = [MediaType.TEXT_HTML_VALUE])
    fun landing(@PathVariable code: String, request: HttpServletRequest): String {
        limiter.throttle(request)
        val p = groups.preview(code)
        if (p.kind == "friend") {
            val name = p.members.firstOrNull { it.linked }?.name?.ifBlank { null } ?: "Someone"
            return landingPage(
                title = "$name on Evensies", heading = name, text = "$name added you as a friend on Evensies.",
                code = code, appLink = "evensies://join/$code",
            )
        }
        return landingPage(
            title = "Join ${p.name} on Evensies", heading = p.name,
            text = "You have been invited to split expenses with ${p.memberCount} member${if (p.memberCount == 1) "" else "s"}.",
            code = code, appLink = "evensies://join/$code",
        )
    }
}

/** The one landing template (`/j/` group invites, `/f/` friend codes). [title], [heading] and [text] are escaped here. */
fun landingPage(title: String, heading: String, text: String, code: String, appLink: String): String {
    val norm = InviteCodes.normalize(code)
    val shown = HtmlUtils.htmlEscape(if (norm.length == InviteCodes.LENGTH) norm.chunked(3).joinToString("-") else norm)
    fun esc(s: String) = HtmlUtils.htmlEscape(s)
    return """
        <!doctype html>
        <html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
        <title>${esc(title)}</title>
        <style>body{font-family:system-ui,sans-serif;max-width:28rem;margin:4rem auto;padding:0 1rem;line-height:1.5}
        a.btn{display:block;margin:.75rem 0;padding:.75rem;text-align:center;border-radius:.5rem;background:#1a73e8;color:#fff;text-decoration:none}
        a.store{background:#333}</style></head>
        <body>
        <h1>${esc(heading)}</h1>
        <p>${esc(text)}</p>
        <p>Invite code: <strong style="font-family:ui-monospace,monospace;font-size:1.5rem;letter-spacing:.1em">$shown</strong></p>
        <a class="btn" href="${esc(appLink)}">Open in app</a>
        <a class="btn store" href="#">App Store (coming soon)</a>
        <a class="btn store" href="#">Google Play (coming soon)</a>
        <p><small>Installed the app? Open it, tap <b>Join with a code</b> and enter <b>$shown</b>.</small></p>
        </body></html>
    """.trimIndent()
}
