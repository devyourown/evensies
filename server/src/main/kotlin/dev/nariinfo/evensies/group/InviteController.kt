package dev.nariinfo.evensies.group

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.common.RateLimiter
import dev.nariinfo.evensies.common.Strings
import dev.nariinfo.evensies.config.AppProperties
import dev.nariinfo.evensies.config.userId
import jakarta.servlet.http.HttpServletRequest
import org.springframework.http.HttpHeaders
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.security.core.Authentication
import org.springframework.stereotype.Component
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.util.HtmlUtils
import java.nio.charset.StandardCharsets
import java.util.Locale

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
     * placeholder friend's link names the person who added them (docs/API.md "친구 그룹 규칙"). [m] (Phase 10, an
     * email invite's placeholder) is passed on to both links when it is UUID-shaped, else dropped.
     */
    @GetMapping("/j/{code}")
    fun landing(@PathVariable code: String, @RequestParam(required = false) m: String?, request: HttpServletRequest): ResponseEntity<String> {
        limiter.throttle(request)
        val p = groups.preview(code)
        val member = m?.takeIf { UUID_SHAPE.matches(it) }?.let { "?m=$it" } ?: ""
        val page = LandingPage(request, code, "evensies://join/$code$member", "/app/#/join/${InviteCodes.normalize(code)}$member")
        if (p.kind == "friend") return page.person(p.members.firstOrNull { it.linked }?.name, "friendAdded")
        return page.render(page.text("title", "group" to p.name), p.name, page.text("invited"), page.text("members", "count" to p.memberCount.toString()))
    }

    companion object {
        private val UUID_SHAPE = Regex("[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}")
    }
}

/**
 * The one landing template (`/j/` group invites, `/f/` friend codes, docs/API.md "랜딩 페이지"), in the first
 * `Accept-Language` language strings.json has, else English. [appLink] opens the app, [webLink] the web app.
 */
class LandingPage(request: HttpServletRequest, private val code: String, private val appLink: String, private val webLink: String) {
    val lang: String = request.getHeader(HttpHeaders.ACCEPT_LANGUAGE)?.let {
        try {
            Locale.lookupTag(Locale.LanguageRange.parse(it), Strings.languages)
        } catch (_: IllegalArgumentException) {
            null
        }
    } ?: "en"

    /** `landing.<key>` filled with [values]; a [words] placeholder is upper-cased at the start. */
    fun text(key: String, vararg values: Pair<String, String>, words: Set<String> = emptySet()) =
        Strings.fill(Strings.get(lang, "landing", key)!!, values.toMap(), words)

    /** A page about one person (friend link, friend group invite): their name, or `words.someone` when blank. */
    fun person(name: String?, textKey: String): ResponseEntity<String> {
        val shown = name?.ifBlank { null } ?: Strings.get(lang, "words", "someone")!!
        val words = if (name.isNullOrBlank()) setOf("name") else emptySet()
        return render(text("friendTitle", "name" to shown, words = words), Strings.fill("{name}", mapOf("name" to shown), words), text(textKey, "name" to shown, words = words))
    }

    /** Every text and value is HTML-escaped here. */
    fun render(title: String, heading: String, vararg paragraphs: String): ResponseEntity<String> {
        val norm = InviteCodes.normalize(code)
        val shown = if (norm.length == InviteCodes.LENGTH) norm.chunked(3).joinToString("-") else norm
        fun esc(s: String) = HtmlUtils.htmlEscape(s, "UTF-8")
        val html = """
            <!doctype html>
            <html lang="${esc(lang)}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
            <title>${esc(title)}</title>
            <style>body{font-family:system-ui,sans-serif;max-width:28rem;margin:4rem auto;padding:0 1rem;line-height:1.5}
            a.btn{display:block;margin:.75rem 0;padding:.75rem;text-align:center;border-radius:.5rem;background:#1a73e8;color:#fff;text-decoration:none}
            a.web{background:#fff;color:#1a73e8;border:1px solid #1a73e8}a.store{background:#333}
            .code{font-family:ui-monospace,monospace;font-size:1.5rem;letter-spacing:.1em}</style></head>
            <body>
            <h1>${esc(heading)}</h1>
            ${paragraphs.joinToString("") { "<p>${esc(it)}</p>" }}
            <p>${esc(text("code"))}<br><strong class="code">${esc(shown)}</strong></p>
            <a class="btn" href="${esc(appLink)}">${esc(text("openApp"))}</a>
            <a class="btn web" href="${esc(webLink)}">${esc(text("openWeb"))}</a>
            <a class="btn store" href="#">${esc(text("appStore"))}</a>
            <a class="btn store" href="#">${esc(text("googlePlay"))}</a>
            <p><small>${esc(text("hint", "code" to shown))}</small></p>
            </body></html>
        """.trimIndent()
        return ResponseEntity.ok().contentType(MediaType("text", "html", StandardCharsets.UTF_8))
            .header(HttpHeaders.VARY, HttpHeaders.ACCEPT_LANGUAGE).body(html)
    }
}
