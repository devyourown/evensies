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
import tools.jackson.databind.JsonNode
import java.util.UUID

/** Which visible pushes a user wants (docs/API.md "알림 설정"); sync data messages are always sent. */
data class NotificationPrefs(val expenses: Boolean = true, val comments: Boolean = true, val members: Boolean = true) {
    fun allows(kind: String) = when {
        kind.startsWith("expense_") || kind.startsWith("payment_") -> expenses
        kind == "comment_added" -> comments
        kind.startsWith("member_") || kind == "group_updated" -> members
        else -> true
    }
}

@Repository
class NotificationPrefsRepository(private val jdbc: JdbcClient) {
    /** No stored row = everything on. */
    fun get(userId: UUID): NotificationPrefs =
        jdbc.sql("SELECT * FROM notification_prefs WHERE user_id = :u").param("u", userId)
            .query { rs, _ -> NotificationPrefs(rs.getBoolean("expenses"), rs.getBoolean("comments"), rs.getBoolean("members")) }
            .optional().orElse(NotificationPrefs())

    fun put(userId: UUID, p: NotificationPrefs) {
        jdbc.sql(
            """
            INSERT INTO notification_prefs (user_id, expenses, comments, members) VALUES (:u, :e, :c, :m)
            ON CONFLICT (user_id) DO UPDATE SET expenses = EXCLUDED.expenses, comments = EXCLUDED.comments, members = EXCLUDED.members
            """
        ).param("u", userId).param("e", p.expenses).param("c", p.comments).param("m", p.members).update()
    }

    fun deleteByUser(userId: UUID) {
        jdbc.sql("DELETE FROM notification_prefs WHERE user_id = :u").param("u", userId).update()
    }
}

@RestController
class NotificationPrefsController(private val repo: NotificationPrefsRepository, private val auth: AuthService) {
    @GetMapping("/me/notifications")
    fun get(authentication: Authentication): NotificationPrefs = repo.get(authentication.userId)

    /** Full replace; all three keys must be JSON booleans (no coercion from strings or numbers). */
    @PutMapping("/me/notifications")
    fun put(authentication: Authentication, @RequestBody body: JsonNode): NotificationPrefs {
        fun flag(k: String) = body.get(k)?.takeIf { it.isBoolean }?.asBoolean()
            ?: throw ApiException.badRequest("VALIDATION", "$k must be true or false")
        val prefs = NotificationPrefs(flag("expenses"), flag("comments"), flag("members"))
        auth.me(authentication.userId) // 401 for deleted accounts
        repo.put(authentication.userId, prefs)
        return prefs
    }
}
