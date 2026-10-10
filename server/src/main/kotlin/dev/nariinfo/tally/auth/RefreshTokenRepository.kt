package dev.nariinfo.tally.auth

import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.stereotype.Repository
import java.time.Instant
import java.time.OffsetDateTime
import java.time.ZoneOffset
import java.util.UUID

@Repository
class RefreshTokenRepository(private val jdbc: JdbcClient) {
    fun insert(token: String, userId: UUID, expiresAt: Instant) {
        jdbc.sql("INSERT INTO refresh_tokens (token, user_id, expires_at) VALUES (:token, :userId, :exp)")
            .param("token", token).param("userId", userId).param("exp", expiresAt.atOffset(ZoneOffset.UTC)).update()
    }

    /** Consumes the token: returns its user id if valid and not expired, deleting it either way. */
    fun consume(token: String): UUID? = jdbc.sql(
        "DELETE FROM refresh_tokens WHERE token = :token RETURNING user_id, expires_at"
    ).param("token", token).query { rs, _ ->
        val exp = rs.getObject("expires_at", OffsetDateTime::class.java).toInstant()
        if (exp.isAfter(Instant.now())) rs.getObject("user_id", UUID::class.java) else null
    }.optional().orElse(null)

    fun deleteByUser(userId: UUID) {
        jdbc.sql("DELETE FROM refresh_tokens WHERE user_id = :userId").param("userId", userId).update()
    }
}
