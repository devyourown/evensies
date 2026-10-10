package dev.nariinfo.tally.auth

import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.stereotype.Repository
import java.time.OffsetDateTime
import java.util.UUID

@Repository
class DeviceRepository(private val jdbc: JdbcClient) {
    fun upsert(deviceId: String, userId: UUID, fcmToken: String) {
        jdbc.sql(
            """
            INSERT INTO devices (id, user_id, fcm_token, last_seen_at) VALUES (:id, :userId, :token, :now)
            ON CONFLICT (id) DO UPDATE SET user_id = EXCLUDED.user_id, fcm_token = EXCLUDED.fcm_token, last_seen_at = EXCLUDED.last_seen_at
            """
        ).param("id", deviceId).param("userId", userId).param("token", fcmToken).param("now", OffsetDateTime.now()).update()
    }

    fun fcmTokensForGroup(groupId: UUID, excludeUserId: UUID): List<String> = jdbc.sql(
        """
        SELECT DISTINCT d.fcm_token FROM devices d
        JOIN members m ON m.user_id = d.user_id
        WHERE m.group_id = :groupId AND m.removed = false AND d.user_id <> :exclude AND d.fcm_token IS NOT NULL
        """
    ).param("groupId", groupId).param("exclude", excludeUserId).query(String::class.java).list().filterNotNull()

    fun deleteByUser(userId: UUID) {
        jdbc.sql("DELETE FROM devices WHERE user_id = :userId").param("userId", userId).update()
    }
}
