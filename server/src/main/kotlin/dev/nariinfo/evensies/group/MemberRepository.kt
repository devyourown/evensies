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

    fun countGroupsOfUser(userId: UUID): Int =
        jdbc.sql("SELECT count(DISTINCT group_id) FROM members WHERE user_id = :u AND removed = false")
            .param("u", userId).query(Int::class.java).single()

    /** Account deletion: every member row of this user becomes a placeholder. */
    fun unlinkUser(userId: UUID) {
        jdbc.sql("UPDATE members SET user_id = NULL WHERE user_id = :u").param("u", userId).update()
    }
}
