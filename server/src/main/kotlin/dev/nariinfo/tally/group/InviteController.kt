package dev.nariinfo.tally.group

import dev.nariinfo.tally.config.AppProperties
import dev.nariinfo.tally.config.userId
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
    @GetMapping("/invites/{code}")
    fun preview(@PathVariable code: String): InvitePreviewDto = groups.preview(code)

    @PostMapping("/invites/{code}/join")
    fun join(auth: Authentication, @PathVariable code: String, @RequestBody req: JoinRequest): GroupDto =
        groups.join(code, auth.userId, req)

    /** Invite landing page for people without the app. */
    @GetMapping("/j/{code}", produces = [MediaType.TEXT_HTML_VALUE])
    fun landing(@PathVariable code: String): String {
        val p = groups.preview(code)
        val name = HtmlUtils.htmlEscape(p.name)
        val link = HtmlUtils.htmlEscape("${props.publicUrl}/j/$code")
        return """
            <!doctype html>
            <html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Join $name on Tally</title>
            <style>body{font-family:system-ui,sans-serif;max-width:28rem;margin:4rem auto;padding:0 1rem;line-height:1.5}
            a.btn{display:block;margin:.75rem 0;padding:.75rem;text-align:center;border-radius:.5rem;background:#1a73e8;color:#fff;text-decoration:none}
            a.store{background:#333}</style></head>
            <body>
            <h1>$name</h1>
            <p>You have been invited to split expenses with ${p.memberCount} member${if (p.memberCount == 1) "" else "s"}.</p>
            <a class="btn" href="tally://join/$code">Open in app</a>
            <a class="btn store" href="#">App Store (coming soon)</a>
            <a class="btn store" href="#">Google Play (coming soon)</a>
            <p><small>Installed the app? Copy this link and open the app: <code>$link</code></small></p>
            </body></html>
        """.trimIndent()
    }
}
