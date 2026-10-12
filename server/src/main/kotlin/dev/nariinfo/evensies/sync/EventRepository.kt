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

    /**
     * Unread candidates (docs/API.md "읽지 않은 활동"): the overall feed's events and `me` (same member choice as
     * [findBeforeForUser]) newer than the user's mark in that group, not by the user, stored since that member row
     * was created. Hiding rules are applied by the caller. Per group it reads only the events past the mark
     * (index `events_group_feed_id`), so a user who has read everything costs one index probe per group.
     * ponytail: at most [limit] newest rows are looked at, so a huge backlog undercounts; fine for a badge. A group with
     * no mark yet (joined, Activity never opened) is read back to its first event; a mark at join if that gets slow.
     */
    fun unreadCandidates(userId: UUID, limit: Int): List<Pair<Event, String>> = jdbc.sql(UNREAD_SQL)
        .param("u", userId).param("limit", limit).query { rs, i -> rowMapper(rs, i) to rs.getString("my_member_id") }.list()

    /**
     * Raises the user's mark in [groupId] (null = every group they are an active member of) to [feedId], capped at the
     * newest stored feed_id so a huge value can't mark future items as read; never lowers it.
     */
    fun markSeen(userId: UUID, feedId: Long, groupId: UUID?) {
        jdbc.sql(
            """
            INSERT INTO activity_seen (user_id, group_id, feed_id)
            SELECT DISTINCT :u, group_id, LEAST(:f, (SELECT COALESCE(max(feed_id), 0) FROM events)) FROM members
            WHERE user_id = :u AND removed = false AND (CAST(:g AS uuid) IS NULL OR group_id = :g)
            ON CONFLICT (user_id, group_id) DO UPDATE SET feed_id = GREATEST(activity_seen.feed_id, EXCLUDED.feed_id)
            """
        ).param("u", userId).param("f", feedId).param("g", groupId).update()
    }

    /**
     * Phase 10 digest window: events with [after] < feed_id <= [upTo] in the groups where [userId] is an active member
     * (paired with that member, as in [findBeforeForUser]), not by the user or by someone they blocked, oldest first,
     * at most [limit]. Per group it reads only past the mark (index `events_group_feed_id`).
     */
    fun digestWindow(userId: UUID, after: Long, upTo: Long, limit: Int): List<Pair<Event, String>> = jdbc.sql(
        """
        SELECT e.*, m.id AS my_member_id
        FROM (SELECT DISTINCT ON (group_id) group_id, id FROM members WHERE user_id = :u AND removed = false ORDER BY group_id, created_at) m
        CROSS JOIN LATERAL (
            SELECT * FROM events e
            WHERE e.group_id = m.group_id AND e.feed_id > :after AND e.feed_id <= :upTo AND e.actor_user_id IS DISTINCT FROM :u
              AND NOT EXISTS (SELECT 1 FROM user_blocks b WHERE b.blocker = :u AND b.blocked = e.actor_user_id)
            ORDER BY e.feed_id LIMIT :limit
        ) e
        ORDER BY e.feed_id LIMIT :limit
        """
    ).param("u", userId).param("after", after).param("upTo", upTo).param("limit", limit)
        .query { rs, i -> rowMapper(rs, i) to rs.getString("my_member_id") }.list()

    fun maxFeedId(): Long = jdbc.sql("SELECT COALESCE(max(feed_id), 0) FROM events").query(Long::class.java).single()

    fun deleteSeenByUser(userId: UUID) {
        jdbc.sql("DELETE FROM activity_seen WHERE user_id = :u").param("u", userId).update()
    }

    /** Groups with events stored before the activity feed existed. */
    fun groupsWithoutMeta(): List<UUID> =
        jdbc.sql("SELECT DISTINCT group_id FROM events WHERE meta IS NULL").query(UUID::class.java).list().filterNotNull()

    fun fillMeta(groupId: UUID, seq: Long, meta: EventMeta) {
        jdbc.sql("UPDATE events SET meta = CAST(:meta AS jsonb) WHERE group_id = :g AND seq = :seq AND meta IS NULL")
            .param("meta", mapper.writeValueAsString(meta)).param("g", groupId).param("seq", seq).update()
    }

    companion object {
        /** [unreadCandidates]; internal so a test can check its plan. */
        internal const val UNREAD_SQL = """
            SELECT e.*, m.id AS my_member_id
            FROM (SELECT DISTINCT ON (group_id) group_id, id, created_at FROM members WHERE user_id = :u AND removed = false ORDER BY group_id, created_at) m
            LEFT JOIN activity_seen s ON s.user_id = :u AND s.group_id = m.group_id
            CROSS JOIN LATERAL (
                SELECT * FROM events e
                WHERE e.group_id = m.group_id AND e.feed_id > COALESCE(s.feed_id, 0)
                  AND e.actor_user_id IS DISTINCT FROM :u AND e.received_at >= m.created_at
                ORDER BY e.feed_id DESC LIMIT :limit
            ) e
            ORDER BY e.feed_id DESC LIMIT :limit
        """
    }
}
