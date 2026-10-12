package dev.nariinfo.evensies.auth

import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.stereotype.Repository
import java.time.OffsetDateTime
import java.util.UUID

@Repository
class DeviceRepository(private val jdbc: JdbcClient) {
    fun upsert(deviceId: String, userId: UUID, fcmToken: String, notificationsAllowed: Boolean = true) {
        jdbc.sql(
            """
            INSERT INTO devices (id, user_id, fcm_token, last_seen_at, notifications_allowed) VALUES (:id, :userId, :token, :now, :allowed)
            ON CONFLICT (id) DO UPDATE SET user_id = EXCLUDED.user_id, fcm_token = EXCLUDED.fcm_token, last_seen_at = EXCLUDED.last_seen_at,
              notifications_allowed = EXCLUDED.notifications_allowed
            """
        ).param("id", deviceId).param("userId", userId).param("token", fcmToken).param("now", OffsetDateTime.now())
            .param("allowed", notificationsAllowed).update()
        // A token belongs to one phone: after a sign-in as someone else (or a reinstall) the old row must stop receiving pushes.
        jdbc.sql("DELETE FROM devices WHERE fcm_token = :token AND id <> :id").param("token", fcmToken).param("id", deviceId).update()
        // Every reinstall registers a new device id: keep only the most recently seen ones, so no user fans out to unbounded tokens.
        jdbc.sql(
            """
            DELETE FROM devices WHERE user_id = :u AND id NOT IN
              (SELECT id FROM devices WHERE user_id = :u ORDER BY last_seen_at DESC, id LIMIT $MAX_PER_USER)
            """
        ).param("u", userId).update()
    }

    /** Sign-out on that phone: only the caller's own row, so a guessed id cannot mute someone else. */
    fun delete(deviceId: String, userId: UUID) {
        jdbc.sql("DELETE FROM devices WHERE id = :id AND user_id = :u").param("id", deviceId).param("u", userId).update()
    }

    /** Tokens FCM reported as no longer valid. */
    fun deleteTokens(tokens: Collection<String>) {
        jdbc.sql("DELETE FROM devices WHERE fcm_token IN (:t)").param("t", tokens.toList()).update()
    }

    fun fcmTokensOfUser(userId: UUID): List<String> =
        jdbc.sql("SELECT DISTINCT fcm_token FROM devices WHERE user_id = :u AND fcm_token IS NOT NULL")
            .param("u", userId).query(String::class.java).list().filterNotNull()

    /**
     * Phase 10 "auto" digests: a device that can show this user's pushes (an FCM token, notifications allowed, seen in
     * the last 60 days). FCM being configured and the push switches are checked by the caller.
     */
    fun hasPushCapable(userId: UUID, since: OffsetDateTime): Boolean = jdbc.sql(
        "SELECT EXISTS (SELECT 1 FROM devices WHERE user_id = :u AND fcm_token IS NOT NULL AND notifications_allowed AND last_seen_at > :since)"
    ).param("u", userId).param("since", since).query(Boolean::class.java).single()

    fun deleteByUser(userId: UUID) {
        jdbc.sql("DELETE FROM devices WHERE user_id = :userId").param("userId", userId).update()
    }

    companion object {
        const val MAX_PER_USER = 10
    }
}
