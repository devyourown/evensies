package dev.nariinfo.evensies.email

import dev.nariinfo.evensies.auth.UserRepository
import dev.nariinfo.evensies.common.Strings
import dev.nariinfo.evensies.config.AppProperties
import dev.nariinfo.evensies.push.NotificationPrefsRepository
import jakarta.servlet.http.HttpServletRequest
import org.springframework.http.HttpHeaders
import org.springframework.http.HttpStatus
import org.springframework.http.MediaType
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestHeader
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.util.HtmlUtils
import tools.jackson.databind.ObjectMapper
import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.time.Clock
import java.time.Duration
import java.time.Instant
import java.util.Base64
import java.util.Locale
import java.util.UUID
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

/**
 * Unsubscribe links and Resend's bounce webhook (docs/API.md "Unsubscribes and bounces"), both public. GET only shows a page
 * with one button, because link scanners prefetch; POST (the button, or a mail app's RFC 8058 one-click) applies it.
 */
@RestController
class EmailController(
    private val tokens: EmailTokens,
    private val prefs: NotificationPrefsRepository,
    private val mailer: Mailer,
    private val users: UserRepository,
    private val mapper: ObjectMapper,
    private val clock: Clock,
    private val props: AppProperties,
) {
    @GetMapping("/email/unsubscribe")
    fun page(@RequestParam(required = false) t: String?, request: HttpServletRequest): ResponseEntity<String> {
        val lang = language(request)
        val (kind, _) = tokens.parseUnsubscribe(t) ?: return html(HttpStatus.BAD_REQUEST, lang, text(lang, "invalid"))
        val form = """<form method="post" action="/email/unsubscribe?t=${esc(t!!)}"><button type="submit">${esc(text(lang, "button"))}</button></form>"""
        return html(HttpStatus.OK, lang, text(lang, if (kind == EmailTokens.DIGEST) "digest" else "invites"), form)
    }

    /** The body (`List-Unsubscribe=One-Click` from mail apps, nothing from the page's button) isn't needed. */
    @PostMapping("/email/unsubscribe")
    fun apply(@RequestParam(required = false) t: String?, request: HttpServletRequest): ResponseEntity<String> {
        val lang = language(request)
        val (kind, subject) = tokens.parseUnsubscribe(t) ?: return html(HttpStatus.BAD_REQUEST, lang, text(lang, "invalid"))
        if (kind == EmailTokens.DIGEST) {
            val userId = runCatching { UUID.fromString(subject) }.getOrNull()
            if (userId != null && users.find(userId)?.deleted == false) prefs.digestOff(userId)
            return html(HttpStatus.OK, lang, text(lang, "doneDigest"))
        }
        mailer.suppress(subject, "unsubscribe")
        return html(HttpStatus.OK, lang, text(lang, "doneInvites"))
    }

    /**
     * Resend (Svix) events: the signed content is `svix-id + "." + svix-timestamp + "." + body`, the key the base64 after
     * `whsec_`, the header `v1,<base64 sig>` entries, the timestamp within 5 minutes. Only `type` and `data.to` are read:
     * `email.bounced` suppresses each address as `bounce`; `email.complained` as `complaint` and turns its account's
     * summaries off. 404 while the secret is empty, 401 for a bad or old signature.
     */
    @PostMapping("/webhooks/email")
    fun webhook(
        @RequestHeader("svix-id", required = false) id: String?,
        @RequestHeader("svix-timestamp", required = false) timestamp: String?,
        @RequestHeader("svix-signature", required = false) signature: String?,
        @RequestBody(required = false) body: String?,
    ): ResponseEntity<Void> {
        val secret = props.email.webhookSecret.trim()
        if (secret.isEmpty()) return ResponseEntity.notFound().build()
        val ts = timestamp?.toLongOrNull()
        if (id == null || ts == null || signature == null || body == null ||
            Duration.between(Instant.ofEpochSecond(ts), clock.instant()).abs() > Duration.ofMinutes(5)
        ) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build()
        val key = try { Base64.getDecoder().decode(secret.removePrefix("whsec_")) } catch (_: IllegalArgumentException) { return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build() }
        val expected = Mac.getInstance("HmacSHA256").apply { init(SecretKeySpec(key, "HmacSHA256")) }.doFinal("$id.$ts.$body".toByteArray(StandardCharsets.UTF_8))
        val valid = signature.split(' ').any { entry ->
            val sig = entry.substringAfter("v1,", "")
            sig.isNotEmpty() && runCatching { MessageDigest.isEqual(Base64.getDecoder().decode(sig), expected) }.getOrDefault(false)
        }
        if (!valid) return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build()
        val event = runCatching { mapper.readTree(body) }.getOrNull() ?: return ResponseEntity.noContent().build()
        val reason = when (event.get("type")?.asString()) {
            "email.bounced" -> "bounce"
            "email.complained" -> "complaint"
            else -> return ResponseEntity.noContent().build()
        }
        val to = event.get("data")?.get("to")
        val addresses = (if (to?.isArray == true) to.values().map { it.asString() } else listOfNotNull(to?.asString())).mapNotNull(EmailAddress::normalize)
        for (address in addresses) {
            mailer.suppress(EmailAddress.hash(address), reason)
            if (reason == "complaint") users.findActiveByEmail(address)?.let { prefs.digestOff(it.id) }
        }
        return ResponseEntity.noContent().build()
    }

    private fun text(lang: String, key: String) = Strings.get(lang, "unsubscribe", key)!!

    /** The first `Accept-Language` language strings.json has, else English (as the invite landing pages). */
    private fun language(request: HttpServletRequest): String = request.getHeader(HttpHeaders.ACCEPT_LANGUAGE)?.let {
        try {
            Locale.lookupTag(Locale.LanguageRange.parse(it), Strings.languages)
        } catch (_: IllegalArgumentException) {
            null
        }
    } ?: "en"

    private fun esc(s: String) = HtmlUtils.htmlEscape(s, "UTF-8")

    /** The landing pages' look; every text is escaped here, [extra] is markup built from escaped parts. */
    private fun html(status: HttpStatus, lang: String, message: String, extra: String = ""): ResponseEntity<String> {
        val page = """
            <!doctype html>
            <html lang="${esc(lang)}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
            <meta name="robots" content="noindex"><title>${esc(text(lang, "title"))}</title>
            <style>body{font-family:system-ui,sans-serif;max-width:28rem;margin:4rem auto;padding:0 1rem;line-height:1.5}
            button{display:block;width:100%;margin:.75rem 0;padding:.75rem;border:0;border-radius:.5rem;background:#1a73e8;color:#fff;font-size:1rem}</style></head>
            <body>
            <h1>${esc(text(lang, "title"))}</h1>
            <p>${esc(message)}</p>
            $extra
            </body></html>
        """.trimIndent()
        return ResponseEntity.status(status).contentType(MediaType("text", "html", StandardCharsets.UTF_8))
            .header(HttpHeaders.VARY, HttpHeaders.ACCEPT_LANGUAGE).body(page)
    }
}
