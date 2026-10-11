package dev.nariinfo.evensies.sync

import dev.nariinfo.evensies.activity.EventMeta
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
            meta = rs.getString("meta")?.let { mapper.readValue(it, EventMeta::class.java) },
            feedId = rs.getLong("feed_id"),
            receivedAt = rs.getObject("received_at", OffsetDateTime::class.java).toInstant(),
        )
    }

    fun insert(e: Event) {
        jdbc.sql(
            """
            INSERT INTO events (group_id, seq, client_id, type, payload, actor_user_id, created_at, meta)
            VALUES (:groupId, :seq, :clientId, :type, CAST(:payload AS jsonb), :actor, :createdAt, CAST(:meta AS jsonb))
            """
        ).param("groupId", e.groupId).param("seq", e.seq).param("clientId", e.clientId).param("type", e.type)
            .param("payload", mapper.writeValueAsString(e.payload)).param("actor", e.actorUserId)
            .param("createdAt", e.createdAt.atOffset(ZoneOffset.UTC)).param("meta", e.meta?.let(mapper::writeValueAsString)).update()
    }

    /**
     * The one in-place change to the log (docs/API.md 적용 규칙 8): a deleted comment's text leaves its stored
     * `comment.added` events, so pulls, exports and replays never hand it out again.
     */
    fun blankCommentText(groupId: UUID, commentId: String) {
        jdbc.sql(
            """
            UPDATE events SET payload = jsonb_set(payload, '{text}', '""')
            WHERE group_id = :g AND type = 'comment.added' AND payload->>'commentId' = :c AND payload->>'text' <> ''
            """
        ).param("g", groupId).param("c", commentId).update()
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

    /**
     * Group feed page: seq < [before], newest first; with [expenseId], only events whose payload names that expense.
     * ponytail: the filter scans the group's events; add an index on (group_id, (payload->>'expenseId')) past ~50k per group.
     */
    fun findBefore(groupId: UUID, before: Long, limit: Int, expenseId: String?): List<Event> {
        val filter = if (expenseId == null) "" else "AND payload->>'expenseId' = :expenseId"
        return jdbc.sql("SELECT * FROM events WHERE group_id = :groupId AND seq < :before $filter ORDER BY seq DESC LIMIT :limit")
            .param("groupId", groupId).param("before", before).param("limit", limit).param("expenseId", expenseId)
            .query(rowMapper).list()
    }

    /**
     * Overall feed page: feed_id < [before], newest first, over the groups where [userId] is an active member,
     * each event paired with that user's member id in its group.
     * ponytail: scans feed_id backwards across all groups; add a (group_id, feed_id) index + per-group merge if it gets slow.
     */
    fun findBeforeForUser(userId: UUID, before: Long, limit: Int): List<Pair<Event, String>> = jdbc.sql(
        """
        SELECT e.*, m.id AS my_member_id FROM events e
        JOIN (SELECT DISTINCT ON (group_id) group_id, id FROM members WHERE user_id = :u AND removed = false ORDER BY group_id, created_at) m
          ON m.group_id = e.group_id
        WHERE e.feed_id < :before ORDER BY e.feed_id DESC LIMIT :limit
        """
    ).param("u", userId).param("before", before).param("limit", limit)
        .query { rs, i -> rowMapper(rs, i) to rs.getString("my_member_id") }.list()

    /** Groups with events stored before the activity feed existed. */
    fun groupsWithoutMeta(): List<UUID> =
        jdbc.sql("SELECT DISTINCT group_id FROM events WHERE meta IS NULL").query(UUID::class.java).list().filterNotNull()

    fun fillMeta(groupId: UUID, seq: Long, meta: EventMeta) {
        jdbc.sql("UPDATE events SET meta = CAST(:meta AS jsonb) WHERE group_id = :g AND seq = :seq AND meta IS NULL")
            .param("meta", mapper.writeValueAsString(meta)).param("g", groupId).param("seq", seq).update()
    }
}
