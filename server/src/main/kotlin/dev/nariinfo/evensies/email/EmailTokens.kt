package dev.nariinfo.evensies.email

import dev.nariinfo.evensies.config.AppProperties
import org.springframework.stereotype.Component
import java.security.MessageDigest
import java.util.Base64
import java.util.HexFormat
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

/** docs/API.md "Email validation": addresses are trimmed and lower-cased; no SMTPUTF8. */
object EmailAddress {
    private val shape = Regex("^[^\\s@]{1,64}@[a-z0-9-]+(\\.[a-z0-9-]+)+$")
    const val MAX = 254

    /** The stored form, or null when [raw] isn't an address we send to. */
    fun normalize(raw: String?): String? = raw?.trim()?.lowercase()?.takeIf { it.length <= MAX && shape.matches(it) }

    /** `email_suppressions.email_hash` / `email_log.to_hash`: sha256 hex of the normalized address. */
    fun hash(email: String): String = HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(email.toByteArray(Charsets.UTF_8)))
}

/**
 * Code hashes and unsubscribe tokens (docs/API.md "Tokens"), keyed with K = HMAC-SHA256(EVENSIES_JWT_SECRET, "evensies-email"),
 * so there is no new secret. Tokens never expire; rotating the JWT secret breaks old links.
 */
@Component
class EmailTokens(props: AppProperties) {
    private val key: ByteArray = hmac(props.jwtSecret.toByteArray(Charsets.UTF_8), "evensies-email")
    private val b64 = Base64.getUrlEncoder().withoutPadding()

    private fun hmac(key: ByteArray, text: String): ByteArray =
        Mac.getInstance("HmacSHA256").apply { init(SecretKeySpec(key, "HmacSHA256")) }.doFinal(text.toByteArray(Charsets.UTF_8))

    /** HMAC(K, email + ":" + code); only this is stored, never the code. */
    fun codeHash(email: String, code: String): String = HexFormat.of().formatHex(hmac(key, "$email:$code"))

    fun codeMatches(hash: String, email: String, code: String): Boolean =
        MessageDigest.isEqual(hash.toByteArray(Charsets.US_ASCII), codeHash(email, code).toByteArray(Charsets.US_ASCII))

    /** `base64url("{kind}:{subject}") + "." + base64url(first 16 bytes of HMAC(K, same))`; kinds [DIGEST] and [INVITES]. */
    fun unsubscribe(kind: String, subject: String): String {
        val text = "$kind:$subject"
        return b64.encodeToString(text.toByteArray(Charsets.UTF_8)) + "." + b64.encodeToString(hmac(key, text).copyOf(16))
    }

    /** (kind, subject) of a token this server made, else null (tampered, malformed, or an old JWT secret). */
    fun parseUnsubscribe(token: String?): Pair<String, String>? {
        val (body, sig) = token?.split('.')?.takeIf { it.size == 2 } ?: return null
        val text = try { Base64.getUrlDecoder().decode(body).toString(Charsets.UTF_8) } catch (_: IllegalArgumentException) { return null }
        val given = try { Base64.getUrlDecoder().decode(sig) } catch (_: IllegalArgumentException) { return null }
        if (!MessageDigest.isEqual(given, hmac(key, text).copyOf(16))) return null
        val kind = text.substringBefore(':', "")
        return if (kind == DIGEST || kind == INVITES) kind to text.substringAfter(':') else null
    }

    companion object {
        /** subject = user id; also covers recurring reminders. */
        const val DIGEST = "digest"
        /** subject = [EmailAddress.hash] of the invited address. */
        const val INVITES = "invites"
    }
}
