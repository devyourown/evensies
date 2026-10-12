package dev.nariinfo.evensies.auth

import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.stereotype.Repository
import java.sql.ResultSet
import java.time.OffsetDateTime
import java.util.UUID

@Repository
class UserRepository(private val jdbc: JdbcClient) {
    private val mapper = { rs: ResultSet, _: Int ->
        User(rs.getObject("id", UUID::class.java), rs.getString("display_name"), rs.getObject("deleted_at") != null, rs.getString("home_currency"), rs.getString("language"))
    }

    fun find(id: UUID): User? =
        jdbc.sql("SELECT * FROM users WHERE id = :id").param("id", id).query(mapper).optional().orElse(null)

    /** Same (provider, subject) → same user. A deleted account logging in again is reactivated. */
    fun findOrCreate(provider: String, subject: String, displayName: String): User = jdbc.sql(
        """
        INSERT INTO users (id, provider, subject, display_name) VALUES (:id, :provider, :subject, :name)
        ON CONFLICT (provider, subject) DO UPDATE SET deleted_at = NULL,
            display_name = CASE WHEN users.display_name = '' THEN EXCLUDED.display_name ELSE users.display_name END
        RETURNING *
        """
    ).param("id", UUID.randomUUID()).param("provider", provider).param("subject", subject).param("name", displayName)
        .query(mapper).single()

    /** A null [name] or [homeCurrency] keeps that column; [language] is written (null clears it) only when [setLanguage]. */
    fun update(id: UUID, name: String?, homeCurrency: String?, setLanguage: Boolean = false, language: String? = null): User = jdbc.sql(
        """
        UPDATE users SET display_name = COALESCE(:name, display_name), home_currency = COALESCE(:currency, home_currency),
            language = CASE WHEN :setLanguage THEN CAST(:language AS text) ELSE language END
        WHERE id = :id RETURNING *
        """
    ).param("name", name).param("currency", homeCurrency).param("setLanguage", setLanguage).param("language", language)
        .param("id", id).query(mapper).single()

    /** Phase 6 friend codes (`users.friend_code`, one namespace with group invite codes). */
    fun friendCode(id: UUID): String? =
        jdbc.sql("SELECT friend_code FROM users WHERE id = :id").param("id", id).query(String::class.java).optional().orElse(null)

    /** [onlyIfNone]: the first `GET /me/friend-code` keeps a code another request set meanwhile. */
    fun setFriendCode(id: UUID, code: String, onlyIfNone: Boolean) {
        jdbc.sql("UPDATE users SET friend_code = :c WHERE id = :id" + if (onlyIfNone) " AND friend_code IS NULL" else "")
            .param("c", code).param("id", id).update()
    }

    fun findByFriendCode(code: String): User? =
        jdbc.sql("SELECT * FROM users WHERE friend_code = :c AND deleted_at IS NULL").param("c", code).query(mapper).optional().orElse(null)

    fun markDeleted(id: UUID) {
        jdbc.sql("UPDATE users SET deleted_at = :now, friend_code = NULL WHERE id = :id AND deleted_at IS NULL")
            .param("now", OffsetDateTime.now()).param("id", id).update()
    }
}
