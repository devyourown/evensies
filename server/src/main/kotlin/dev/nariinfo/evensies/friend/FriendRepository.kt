package dev.nariinfo.evensies.friend

import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.stereotype.Repository
import java.util.UUID

/** `friendships` (the canonical friend group per pair of users) and `reminders` (the last reminder per pair). */
@Repository
class FriendRepository(private val jdbc: JdbcClient) {
    /**
     * The pair in table order: lo = the smaller id as a lowercase string, which is Postgres uuid order. Never
     * `UUID.compareTo`, which compares signed longs.
     */
    private fun pair(a: UUID, b: UUID) = if (a.toString() < b.toString()) a to b else b to a

    fun findGroup(a: UUID, b: UUID): UUID? {
        val (lo, hi) = pair(a, b)
        return jdbc.sql("SELECT group_id FROM friendships WHERE user_lo = :lo AND user_hi = :hi").param("lo", lo).param("hi", hi)
            .query(UUID::class.java).optional().orElse(null)
    }

    /** Keeps an existing pair's group: a claimed placeholder friend stays a second group of the same two people. */
    fun insertPair(a: UUID, b: UUID, groupId: UUID) {
        val (lo, hi) = pair(a, b)
        jdbc.sql("INSERT INTO friendships (user_lo, user_hi, group_id) VALUES (:lo, :hi, :g) ON CONFLICT DO NOTHING")
            .param("lo", lo).param("hi", hi).param("g", groupId).update()
    }

    /**
     * Both users' rows, in id order, locked until the transaction ends: two people adding each other queue up. Returns
     * how many are not deleted; a deletion that committed while this waited counts (the lock re-reads the row).
     */
    fun lockUsers(a: UUID, b: UUID): Int =
        jdbc.sql("SELECT id FROM users WHERE id IN (:a, :b) AND deleted_at IS NULL ORDER BY id FOR UPDATE")
            .param("a", a).param("b", b).query(UUID::class.java).list().size

    /** Takes today's reminder slot for the pair; false when one went out in the last 24 hours. */
    fun takeReminderSlot(from: UUID, to: UUID): Boolean = jdbc.sql(
        """
        INSERT INTO reminders (from_user, to_user, sent_at) VALUES (:f, :t, now())
        ON CONFLICT (from_user, to_user) DO UPDATE SET sent_at = now() WHERE reminders.sent_at < now() - interval '24 hours'
        """
    ).param("f", from).param("t", to).update() == 1

    /** Whole seconds until the next reminder from [from] to [to] is allowed, at least 1. */
    fun secondsUntilNextReminder(from: UUID, to: UUID): Long = jdbc.sql(
        "SELECT GREATEST(1, CEIL(EXTRACT(EPOCH FROM sent_at + interval '24 hours' - now())))::bigint FROM reminders WHERE from_user = :f AND to_user = :t"
    ).param("f", from).param("t", to).query(Long::class.java).optional().orElse(1L)

    /** Account deletion: the user's pairs and reminders in both directions (their friend groups stay, with a placeholder). */
    fun deleteByUser(userId: UUID) {
        jdbc.sql("DELETE FROM friendships WHERE user_lo = :u OR user_hi = :u").param("u", userId).update()
        jdbc.sql("DELETE FROM reminders WHERE from_user = :u OR to_user = :u").param("u", userId).update()
    }
}
