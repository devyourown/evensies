package dev.nariinfo.evensies.auth

import java.util.UUID

data class User(val id: UUID, val displayName: String, val deleted: Boolean, val homeCurrency: String? = null, val language: String? = null) {
    fun dto() = UserDto(id, displayName, homeCurrency, language)
}

/**
 * [homeCurrency]: display currency for "≈" lines; null = never set (the app uses the phone region's currency).
 * [language] (Phase 9): the language of text the server renders for this user (push, reminders); null = English.
 */
data class UserDto(val id: UUID, val displayName: String, val homeCurrency: String?, val language: String?)
