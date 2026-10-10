package dev.nariinfo.evensies.sync

import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.stereotype.Repository
import tools.jackson.databind.ObjectMapper
import java.sql.ResultSet
import java.time.OffsetDateTime
import java.time.ZoneOffset
import java.util.UUID

@Repository
class EventRepository(private val jdbc: JdbcClient, private val mapper: ObjectMapper) {
    private val rowMapper = { rs: ResultSet, _: Int ->
        Event(
            groupId = rs.getObject("group_id", UUID::class.java),
            seq = rs.getLong("seq"),
            clientId = rs.getObject("client_id", UUID::class.java),
            type = rs.getString("type"),
            payload = mapper.readTree(rs.getString("payload")),
            actorUserId = rs.getObject("actor_user_id", UUID::class.java),
            createdAt = rs.getObject("created_at", OffsetDateTime::class.java).toInstant(),
        )
    }

    fun insert(e: Event) {
        jdbc.sql(
            """
            INSERT INTO events (group_id, seq, client_id, type, payload, actor_user_id, created_at)
            VALUES (:groupId, :seq, :clientId, :type, CAST(:payload AS jsonb), :actor, :createdAt)
            """
        ).param("groupId", e.groupId).param("seq", e.seq).param("clientId", e.clientId).param("type", e.type)
            .param("payload", mapper.writeValueAsString(e.payload)).param("actor", e.actorUserId)
            .param("createdAt", e.createdAt.atOffset(ZoneOffset.UTC)).update()
    }

    /** Already-stored events for these client ids (for push dedupe). */
    fun findByGroupIdAndClientIdIn(groupId: UUID, clientIds: Collection<UUID>): List<Event> {
        if (clientIds.isEmpty()) return emptyList()
        return jdbc.sql("SELECT * FROM events WHERE group_id = :groupId AND client_id IN (:ids) ORDER BY seq")
            .param("groupId", groupId).param("ids", clientIds.toList()).query(rowMapper).list()
    }

    fun findAfter(groupId: UUID, after: Long, limit: Int): List<Event> =
        jdbc.sql("SELECT * FROM events WHERE group_id = :groupId AND seq > :after ORDER BY seq LIMIT :limit")
            .param("groupId", groupId).param("after", after).param("limit", limit).query(rowMapper).list()
}
