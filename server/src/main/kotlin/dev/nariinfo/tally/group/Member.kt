package dev.nariinfo.tally.group

import java.util.UUID

data class Member(val id: UUID, val groupId: UUID, val userId: UUID?, val name: String, val removed: Boolean)
