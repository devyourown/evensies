package dev.nariinfo.evensies.sync

import dev.nariinfo.evensies.activity.EventMeta
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
    /** Server-internal feed values (activity package); never sent in pulls. Null only before the backfill ran. */
    val meta: EventMeta? = null,
    /** Global storage order (overall feed cursor); assigned by the database. */
    val feedId: Long = 0,
    /** When the server stored it (the feed's time; createdAt is the client's clock); assigned by the database. */
    val receivedAt: Instant? = null,
) {
    fun toDto() = EventDto(seq, clientId, type, payload, actorUserId, createdAt)
}
