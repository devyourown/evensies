package dev.nariinfo.evensies.group

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.common.RateLimiter
import dev.nariinfo.evensies.config.AppProperties
import dev.nariinfo.evensies.config.userId
import jakarta.servlet.http.HttpServletRequest
import org.springframework.http.MediaType
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.util.HtmlUtils

@RestController
class InviteController(private val groups: GroupService, private val props: AppProperties) {
    // Invite codes are short, so lookups are rate limited per client IP to make guessing impractical.
    private val limiter = RateLimiter(capacity = props.inviteRatePerMinute, refillPerSecond = props.inviteRatePerMinute / 60)

    private fun throttle(request: HttpServletRequest) {
        if (!limiter.tryConsume(request.remoteAddr)) throw ApiException.tooManyRequests("Too many invite attempts, try again in a minute")
    }

    @GetMapping("/invites/{code}")
    fun preview(@PathVariable code: String, request: HttpServletRequest): InvitePreviewDto {
        throttle(request)
        return groups.preview(code)
    }

    @PostMapping("/invites/{code}/join")
    fun join(auth: Authentication, @PathVariable code: String, @RequestBody req: JoinRequest, request: HttpServletRequest): GroupDto {
        throttle(request)
        return groups.join(code, auth.userId, req)
    }

    /** Invite landing page for people without the app. */
    @GetMapping("/j/{code}", produces = [MediaType.TEXT_HTML_VALUE])
    fun landing(@PathVariable code: String, request: HttpServletRequest): String {
        throttle(request)
        val p = groups.preview(code)
        val norm = InviteCodes.normalize(code)
        val shown = HtmlUtils.htmlEscape(if (norm.length == InviteCodes.LENGTH) norm.chunked(3).joinToString("-") else norm)
        val name = HtmlUtils.htmlEscape(p.name)
        return """
            <!doctype html>
            <html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Join $name on Evensies</title>
            <style>body{font-family:system-ui,sans-serif;max-width:28rem;margin:4rem auto;padding:0 1rem;line-height:1.5}
            a.btn{display:block;margin:.75rem 0;padding:.75rem;text-align:center;border-radius:.5rem;background:#1a73e8;color:#fff;text-decoration:none}
            a.store{background:#333}</style></head>
            <body>
            <h1>$name</h1>
            <p>You have been invited to split expenses with ${p.memberCount} member${if (p.memberCount == 1) "" else "s"}.</p>
            <p>Invite code: <strong style="font-family:ui-monospace,monospace;font-size:1.5rem;letter-spacing:.1em">$shown</strong></p>
            <a class="btn" href="evensies://join/$code">Open in app</a>
            <a class="btn store" href="#">App Store (coming soon)</a>
            <a class="btn store" href="#">Google Play (coming soon)</a>
            <p><small>Installed the app? Open it, tap <b>Join with a code</b> and enter <b>$shown</b>.</small></p>
            </body></html>
        """.trimIndent()
    }
}
