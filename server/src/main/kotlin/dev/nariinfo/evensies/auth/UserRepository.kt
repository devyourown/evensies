package dev.nariinfo.evensies.auth

import org.springframework.dao.DuplicateKeyException
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.stereotype.Repository
import java.sql.ResultSet
import java.time.OffsetDateTime
import java.util.UUID

@Repository
class UserRepository(private val jdbc: JdbcClient) {
    private val mapper = { rs: ResultSet, _: Int ->
        User(
            rs.getObject("id", UUID::class.java), rs.getString("display_name"), rs.getObject("deleted_at") != null, rs.getString("home_currency"),
            rs.getString("language"), rs.getString("email"), rs.getString("provider"),
        )
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

    /** Phase 10: the name and address go too (a sign-in later reactivates the account, as with Apple and Google). */
    fun markDeleted(id: UUID) {
        jdbc.sql("UPDATE users SET deleted_at = :now, friend_code = NULL, display_name = '', email = NULL WHERE id = :id AND deleted_at IS NULL")
            .param("now", OffsetDateTime.now()).param("id", id).update()
    }

    /** Account deletion (before [markDeleted]): codes for or by the user and the invite addresses they typed. */
    fun deleteEmailData(id: UUID) {
        jdbc.sql("DELETE FROM email_codes WHERE user_id = :u OR email = (SELECT email FROM users WHERE id = :u)").param("u", id).update()
        jdbc.sql("DELETE FROM email_invites WHERE invited_by = :u").param("u", id).update()
    }

    fun findActiveByEmail(email: String): User? =
        jdbc.sql("SELECT * FROM users WHERE email = :e AND deleted_at IS NULL").param("e", email).query(mapper).optional().orElse(null)

    /**
     * An Apple/Google address (docs/API.md "Account email"): stored only while the account has none, never had one removed
     * (DELETE /me/email), and no other active account holds it; a unique-index race is ignored, so accounts are never
     * merged. Returns the user after.
     */
    fun adoptEmail(id: UUID, email: String): User? = try {
        jdbc.sql(
            """
            UPDATE users SET email = :e WHERE id = :id AND email IS NULL AND NOT email_removed AND deleted_at IS NULL
              AND NOT EXISTS (SELECT 1 FROM users o WHERE o.email = :e AND o.deleted_at IS NULL)
            RETURNING *
            """
        ).param("e", email).param("id", id).query(mapper).optional().orElse(null)
    } catch (_: DuplicateKeyException) {
        null
    }

    /**
     * Sets (null clears and records the removal for [adoptEmail]) the address; an email-code account's subject follows
     * it, so the old address no longer signs in here. A deleted email-code account that had the address keeps it as its
     * subject (signing in reactivates it), so it gives it up first: the address is free once no active account holds it.
     * A DuplicateKeyException when another active account holds it.
     */
    fun setEmail(id: UUID, email: String?): User {
        if (email != null) {
            jdbc.sql("UPDATE users SET subject = subject || ':deleted:' || id WHERE provider = 'email' AND subject = :e AND deleted_at IS NOT NULL AND id <> :id")
                .param("e", email).param("id", id).update()
        }
        return jdbc.sql(
            """
            UPDATE users SET email = CAST(:e AS text), email_removed = email_removed OR CAST(:e AS text) IS NULL,
              subject = CASE WHEN provider = 'email' AND CAST(:e AS text) IS NOT NULL THEN CAST(:e AS text) ELSE subject END
            WHERE id = :id RETURNING *
            """
        ).param("e", email).param("id", id).query(mapper).single()
    }
}
