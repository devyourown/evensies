package dev.nariinfo.tally.auth

import java.util.UUID

data class User(val id: UUID, val displayName: String, val deleted: Boolean)

data class UserDto(val id: UUID, val displayName: String)
