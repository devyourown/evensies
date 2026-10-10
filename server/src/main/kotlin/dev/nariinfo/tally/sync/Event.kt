package dev.nariinfo.tally.sync

import tools.jackson.databind.JsonNode
import java.time.Instant
import java.util.UUID

data class Event(
    val groupId: UUID,
    val seq: Long,
    val clientId: UUID,
    val type: String,
    val payload: JsonNode,
    val actorUserId: UUID?,
    val createdAt: Instant,
) {
    fun toDto() = EventDto(seq, clientId, type, payload, actorUserId, createdAt)
}
