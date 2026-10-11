package dev.nariinfo.evensies.auth

import java.util.UUID

data class User(val id: UUID, val displayName: String, val deleted: Boolean, val homeCurrency: String? = null) {
    fun dto() = UserDto(id, displayName, homeCurrency)
}

/** [homeCurrency]: display currency for "≈" lines; null = never set (the app uses the phone region's currency). */
data class UserDto(val id: UUID, val displayName: String, val homeCurrency: String?)
