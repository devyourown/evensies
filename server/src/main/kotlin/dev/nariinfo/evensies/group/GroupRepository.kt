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
            kind = rs.getString("kind"),
            type = rs.getString("type"),
            coverImageId = rs.getObject("cover_image_id", UUID::class.java),
            deleted = rs.getObject("deleted_at") != null,
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
            INSERT INTO groups (id, name, default_currency, invite_code, created_by, created_at, latest_seq, kind)
            VALUES (:id, :name, :currency, :code, :createdBy, :createdAt, :seq, :kind)
            """
        ).param("id", g.id).param("kind", g.kind).param("name", g.name).param("currency", g.defaultCurrency).param("code", g.inviteCode)
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
        SELECT g.id, g.name, g.default_currency, g.latest_seq, g.kind, g.type, g.cover_image_id, g.deleted_at,
               (SELECT count(*) FROM members c WHERE c.group_id = g.id AND c.removed = false) AS member_count
        FROM groups g JOIN members m ON m.group_id = g.id
        WHERE m.user_id = :userId AND m.removed = false
        ORDER BY g.created_at, g.id
        """
    ).param("userId", userId).query { rs, _ ->
        GroupSummaryDto(
            rs.getObject("id", UUID::class.java), rs.getString("name"), rs.getString("default_currency"),
            rs.getLong("latest_seq"), rs.getInt("member_count"), rs.getString("kind"),
            rs.getString("type"), rs.getObject("cover_image_id", UUID::class.java), rs.getObject("deleted_at") != null,
        )
    }.list()

    /** Group invite codes and friend codes share one namespace (docs/API.md "Groups: friend codes"). */
    fun codeTaken(code: String): Boolean = jdbc.sql(
        "SELECT EXISTS (SELECT 1 FROM groups WHERE invite_code = :c) OR EXISTS (SELECT 1 FROM users WHERE friend_code = :c)"
    ).param("c", code).query(Boolean::class.java).single()

    /** A new 6-character code free in both tables (retries on the rare collision). */
    fun newCode(): String = generateSequence { InviteCodes.generate() }.first { !codeTaken(it) }
}
