package dev.nariinfo.evensies.group

import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.stereotype.Repository
import tools.jackson.databind.ObjectMapper
import java.sql.ResultSet
import java.time.OffsetDateTime
import java.time.ZoneOffset
import java.util.UUID

@Repository
class GroupRepository(private val jdbc: JdbcClient, private val json: ObjectMapper) {
    private val mapper = { rs: ResultSet, _: Int ->
        Group(
            id = rs.getObject("id", UUID::class.java),
            name = rs.getString("name"),
            defaultCurrency = rs.getString("default_currency"),
            inviteCode = rs.getString("invite_code"),
            createdBy = rs.getObject("created_by", UUID::class.java),
            createdAt = rs.getObject("created_at", OffsetDateTime::class.java).toInstant(),
            latestSeq = rs.getLong("latest_seq"),
            simplifyDebts = rs.getBoolean("simplify_debts"),
            defaultSplit = rs.getString("default_split")?.let(json::readTree),
        )
    }

    fun find(id: UUID): Group? =
        jdbc.sql("SELECT * FROM groups WHERE id = :id").param("id", id).query(mapper).optional().orElse(null)

    /** Row lock for seq assignment. Must be called inside a transaction. */
    fun lockForUpdate(id: UUID): Group? =
        jdbc.sql("SELECT * FROM groups WHERE id = :id FOR UPDATE").param("id", id).query(mapper).optional().orElse(null)

    fun findByInviteCode(code: String): Group? =
        jdbc.sql("SELECT * FROM groups WHERE invite_code = :code").param("code", code).query(mapper).optional().orElse(null)

    fun insert(g: Group) {
        jdbc.sql(
            """
            INSERT INTO groups (id, name, default_currency, invite_code, created_by, created_at, latest_seq)
            VALUES (:id, :name, :currency, :code, :createdBy, :createdAt, :seq)
            """
        ).param("id", g.id).param("name", g.name).param("currency", g.defaultCurrency).param("code", g.inviteCode)
            .param("createdBy", g.createdBy).param("createdAt", g.createdAt.atOffset(ZoneOffset.UTC)).param("seq", g.latestSeq).update()
    }

    fun updateLatestSeq(id: UUID, seq: Long) {
        jdbc.sql("UPDATE groups SET latest_seq = :seq WHERE id = :id").param("seq", seq).param("id", id).update()
    }

    fun updateInviteCode(id: UUID, code: String) {
        jdbc.sql("UPDATE groups SET invite_code = :code WHERE id = :id").param("code", code).param("id", id).update()
    }

    fun listForUser(userId: UUID): List<GroupSummaryDto> = jdbc.sql(
        """
        SELECT g.id, g.name, g.default_currency, g.latest_seq,
               (SELECT count(*) FROM members c WHERE c.group_id = g.id AND c.removed = false) AS member_count
        FROM groups g JOIN members m ON m.group_id = g.id
        WHERE m.user_id = :userId AND m.removed = false
        ORDER BY g.created_at, g.id
        """
    ).param("userId", userId).query { rs, _ ->
        GroupSummaryDto(
            rs.getObject("id", UUID::class.java), rs.getString("name"), rs.getString("default_currency"),
            rs.getLong("latest_seq"), rs.getInt("member_count"),
        )
    }.list()
}
