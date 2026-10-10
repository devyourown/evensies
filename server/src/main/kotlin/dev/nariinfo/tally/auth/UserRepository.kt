package dev.nariinfo.tally.auth

import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.stereotype.Repository
import java.sql.ResultSet
import java.time.OffsetDateTime
import java.util.UUID

@Repository
class UserRepository(private val jdbc: JdbcClient) {
    private val mapper = { rs: ResultSet, _: Int ->
        User(rs.getObject("id", UUID::class.java), rs.getString("display_name"), rs.getObject("deleted_at") != null)
    }

    fun find(id: UUID): User? =
        jdbc.sql("SELECT * FROM users WHERE id = :id").param("id", id).query(mapper).optional().orElse(null)

    /** Same (provider, subject) → same user. A deleted account logging in again is reactivated. */
    fun findOrCreate(provider: String, subject: String, displayName: String): User = jdbc.sql(
        """
        INSERT INTO users (id, provider, subject, display_name) VALUES (:id, :provider, :subject, :name)
        ON CONFLICT (provider, subject) DO UPDATE SET deleted_at = NULL
        RETURNING *
        """
    ).param("id", UUID.randomUUID()).param("provider", provider).param("subject", subject).param("name", displayName)
        .query(mapper).single()

    fun markDeleted(id: UUID) {
        jdbc.sql("UPDATE users SET deleted_at = :now WHERE id = :id AND deleted_at IS NULL")
            .param("now", OffsetDateTime.now()).param("id", id).update()
    }
}
