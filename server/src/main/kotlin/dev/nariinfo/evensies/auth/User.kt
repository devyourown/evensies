package dev.nariinfo.evensies.auth

import java.util.UUID

/** [provider] "apple", "google", "email" (Phase 10, subject = the address), "review" (subject `review:<username>`) or "dev"; [email] the verified account address. */
data class User(
    val id: UUID, val displayName: String, val deleted: Boolean, val homeCurrency: String? = null, val language: String? = null,
    val email: String? = null, val provider: String = "",
) {
    fun dto(emailBounced: Boolean = false) = UserDto(id, displayName, homeCurrency, language, email, emailBounced)
}

/**
 * [homeCurrency]: display currency for "≈" lines; null = never set (the app uses the phone region's currency).
 * [language] (Phase 9): the language of text the server renders for this user (push, reminders, email); null = English.
 * [email] (Phase 10): the verified account address, never shown to other members; [emailBounced]: mail to it bounces.
 */
data class UserDto(val id: UUID, val displayName: String, val homeCurrency: String?, val language: String?, val email: String?, val emailBounced: Boolean)
