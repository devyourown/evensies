package dev.nariinfo.evensies.group

import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.stereotype.Repository
import java.sql.ResultSet
import java.util.UUID

@Repository
class MemberRepository(private val jdbc: JdbcClient) {
    private val mapper = { rs: ResultSet, _: Int ->
        Member(
            id = rs.getObject("id", UUID::class.java),
            groupId = rs.getObject("group_id", UUID::class.java),
            userId = rs.getObject("user_id", UUID::class.java),
            name = rs.getString("name"),
            removed = rs.getBoolean("removed"),
        )
    }

    fun findByGroupAndUser(groupId: UUID, userId: UUID): Member? =
        jdbc.sql("SELECT * FROM members WHERE group_id = :g AND user_id = :u AND removed = false ORDER BY created_at LIMIT 1")
            .param("g", groupId).param("u", userId).query(mapper).optional().orElse(null)

    fun find(id: UUID): Member? =
        jdbc.sql("SELECT * FROM members WHERE id = :id").param("id", id).query(mapper).optional().orElse(null)

    fun listByGroup(groupId: UUID): List<Member> =
        jdbc.sql("SELECT * FROM members WHERE group_id = :g ORDER BY created_at, id").param("g", groupId).query(mapper).list()

    /**
     * The abuse cap counts normal groups only: friend groups are unlimited (docs/API.md "Groups" limits), and so are deleted
     * ones (Phase 10), so a restore is never blocked by the cap.
     */
    fun countGroupsOfUser(userId: UUID): Int = jdbc.sql(
        """
        SELECT count(DISTINCT m.group_id) FROM members m JOIN groups g ON g.id = m.group_id
        WHERE m.user_id = :u AND m.removed = false AND g.kind = 'group' AND g.deleted_at IS NULL
        """
    ).param("u", userId).query(Int::class.java).single()

    /**
     * Shared groups (docs/API.md "Friends: shared groups"): both users have a linked member row there, removed ones included, any
     * kind. The one definition behind avatars and reminders. [activeOnly]: both rows not removed, which adding a friend
     * by userId needs (a friend group can't be left, and it shows each one's payment methods to the other).
     */
    fun sharedGroups(a: UUID, b: UUID, activeOnly: Boolean = false): List<UUID> = jdbc.sql(
        "SELECT DISTINCT x.group_id FROM members x JOIN members y ON y.group_id = x.group_id WHERE x.user_id = :a AND y.user_id = :b" +
            if (activeOnly) " AND x.removed = false AND y.removed = false" else ""
    ).param("a", a).param("b", b).query(UUID::class.java).list().filterNotNull()

    /**
     * Placeholder friends of [userId] (docs/API.md "POST /friends" limits): friend groups where they are an active member
     * and the other member has no user (not yet claimed, or the friend deleted their account).
     */
    fun countPlaceholderFriends(userId: UUID): Int = jdbc.sql(
        """
        SELECT count(DISTINCT m.group_id) FROM members m JOIN groups g ON g.id = m.group_id
        WHERE m.user_id = :u AND m.removed = false AND g.kind = 'friend'
          AND EXISTS (SELECT 1 FROM members p WHERE p.group_id = m.group_id AND p.user_id IS NULL)
        """
    ).param("u", userId).query(Int::class.java).single()

    /** Account deletion: every member row of this user becomes a placeholder. */
    fun unlinkUser(userId: UUID) {
        jdbc.sql("UPDATE members SET user_id = NULL WHERE user_id = :u").param("u", userId).update()
    }
}
