package dev.nariinfo.evensies.push

import dev.nariinfo.evensies.auth.AuthService
import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.config.userId
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.security.core.Authentication
import org.springframework.stereotype.Repository
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RestController
import dev.nariinfo.evensies.email.DigestMode
import tools.jackson.databind.JsonNode
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import java.util.UUID

/**
 * Which visible pushes a user wants (docs/API.md "Notification settings"); sync data messages are always sent. [reminders] (Phase 6)
 * is for reminders other people send, which are not feed items.
 */
data class NotificationPrefs(
    val expenses: Boolean = true,
    val comments: Boolean = true,
    val members: Boolean = true,
    val reminders: Boolean = true,
    /** Phase 10 email summary: auto, daily, weekly, monthly or off. */
    val emailDigest: String = "auto",
    /** Read-only: what [emailDigest] means now (daily, weekly, monthly or off; off without an address or with email off). */
    val emailDigestEffective: String = "off",
) {
    /** All three Phase 2 push switches off counts as no push ("auto" summaries then go out daily). A function: not in the JSON. */
    fun pushOff(): Boolean = !expenses && !comments && !members

    fun allows(kind: String) = when {
        kind.startsWith("expense_") || kind.startsWith("payment_") || kind.startsWith("receipt_") || kind.startsWith("recurrence_") -> expenses
        kind == "comment_added" -> comments
        kind.startsWith("member_") || kind.startsWith("group_") || kind == "friend_added" -> members
        else -> true
    }
}

@Repository
class NotificationPrefsRepository(private val jdbc: JdbcClient) {
    /** No stored row = everything on. */
    fun get(userId: UUID): NotificationPrefs =
        jdbc.sql("SELECT * FROM notification_prefs WHERE user_id = :u").param("u", userId)
            .query { rs, _ ->
                NotificationPrefs(rs.getBoolean("expenses"), rs.getBoolean("comments"), rs.getBoolean("members"), rs.getBoolean("reminders"), rs.getString("email_digest"))
            }
            .optional().orElse(NotificationPrefs())

    fun put(userId: UUID, p: NotificationPrefs) {
        jdbc.sql(
            """
            INSERT INTO notification_prefs (user_id, expenses, comments, members, reminders, email_digest) VALUES (:u, :e, :c, :m, :r, :d)
            ON CONFLICT (user_id) DO UPDATE SET expenses = EXCLUDED.expenses, comments = EXCLUDED.comments, members = EXCLUDED.members,
              reminders = EXCLUDED.reminders, email_digest = EXCLUDED.email_digest
            """
        ).param("u", userId).param("e", p.expenses).param("c", p.comments).param("m", p.members).param("r", p.reminders)
            .param("d", p.emailDigest).update()
    }

    /**
     * Starts the digest clock at [now] with the window after the newest stored event, so nothing old is sent: for a
     * user without a row (made here) or without a clock, and whenever `emailDigest` changes.
     */
    fun resetDigestClock(userId: UUID, now: Instant) {
        jdbc.sql(
            """
            INSERT INTO notification_prefs (user_id, last_digest_at, last_digest_feed_id) VALUES (:u, :t, (SELECT COALESCE(max(feed_id), 0) FROM events))
            ON CONFLICT (user_id) DO UPDATE SET last_digest_at = EXCLUDED.last_digest_at, last_digest_feed_id = EXCLUDED.last_digest_feed_id
            """
        ).param("u", userId).param("t", now.atOffset(ZoneOffset.UTC)).update()
    }

    /** After a digest run for this user (sent, or nothing to say). */
    fun advanceDigest(userId: UUID, now: Instant, feedId: Long) {
        jdbc.sql("UPDATE notification_prefs SET last_digest_at = :t, last_digest_feed_id = :f WHERE user_id = :u")
            .param("t", now.atOffset(ZoneOffset.UTC)).param("f", feedId).param("u", userId).update()
    }

    /** Unsubscribe link, complaint. */
    fun digestOff(userId: UUID) {
        jdbc.sql(
            "INSERT INTO notification_prefs (user_id, email_digest) VALUES (:u, 'off') ON CONFLICT (user_id) DO UPDATE SET email_digest = 'off'"
        ).param("u", userId).update()
    }

    fun deleteByUser(userId: UUID) {
        jdbc.sql("DELETE FROM notification_prefs WHERE user_id = :u").param("u", userId).update()
    }
}

@RestController
class NotificationPrefsController(
    private val repo: NotificationPrefsRepository,
    private val auth: AuthService,
    private val digestMode: DigestMode,
    private val clock: Clock,
) {
    @GetMapping("/me/notifications")
    fun get(authentication: Authentication): NotificationPrefs = withEffective(authentication.userId, repo.get(authentication.userId))

    /**
     * Full replace; the three Phase 2 keys must be JSON booleans (no coercion from strings or numbers). `reminders`
     * (Phase 6) and `emailDigest` (Phase 10) are optional so older apps keep working: missing keeps the stored value,
     * present must be valid. A changed `emailDigest` restarts the summary clock.
     */
    @PutMapping("/me/notifications")
    fun put(authentication: Authentication, @RequestBody body: JsonNode): NotificationPrefs {
        fun flag(k: String) = body.get(k)?.takeIf { it.isBoolean }?.asBoolean()
            ?: throw ApiException.badRequest("VALIDATION", "$k must be true or false")
        val reminders = if (body.has("reminders")) flag("reminders") else null
        val digest = if (body.has("emailDigest")) {
            body.get("emailDigest").takeIf { it.isString && it.asString() in DIGEST_MODES }?.asString()
                ?: throw ApiException.badRequest("VALIDATION", "emailDigest must be one of ${DIGEST_MODES.joinToString()}")
        } else null
        val base = NotificationPrefs(flag("expenses"), flag("comments"), flag("members"))
        val me = authentication.userId
        auth.me(me) // 401 for deleted accounts
        val stored = repo.get(me)
        val prefs = base.copy(reminders = reminders ?: stored.reminders, emailDigest = digest ?: stored.emailDigest)
        repo.put(me, prefs)
        if (prefs.emailDigest != stored.emailDigest) repo.resetDigestClock(me, clock.instant())
        return withEffective(me, prefs)
    }

    private fun withEffective(userId: UUID, p: NotificationPrefs) = p.copy(emailDigestEffective = digestMode.effective(auth.user(userId), p))

    companion object {
        val DIGEST_MODES = listOf("auto", "daily", "weekly", "monthly", "off")
    }
}
