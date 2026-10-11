package dev.nariinfo.evensies.sync

import dev.nariinfo.evensies.common.ApiException
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.stereotype.Repository
import tools.jackson.databind.JsonNode
import java.sql.ResultSet
import java.time.LocalDate
import java.time.Instant
import java.time.OffsetDateTime
import java.time.ZoneOffset
import java.util.UUID

/** Loads a group's state from the member/expense/payment/comment tables and writes back what an event touched. */
@Repository
class GroupStateStore(private val jdbc: JdbcClient) {
    fun load(groupId: UUID): GroupState {
        val group = jdbc.sql("SELECT name, default_currency FROM groups WHERE id = :id").param("id", groupId)
            .query { rs, _ -> rs.getString("name") to rs.getString("default_currency") }.optional().orElse(null)
        val members = jdbc.sql("SELECT * FROM members WHERE group_id = :id ORDER BY created_at, id").param("id", groupId)
            .query { rs, _ ->
                MemberDto(rs.getString("id"), rs.getString("name"), rs.getString("user_id"), rs.getBoolean("removed"))
            }.list()
        val shares = jdbc.sql(
            "SELECT s.* FROM expense_shares s JOIN expenses e ON e.id = s.expense_id WHERE e.group_id = :id ORDER BY s.expense_id, s.position"
        ).param("id", groupId).query { rs, _ -> rs.getString("expense_id") to ShareDto(rs.getString("member_id"), rs.getLong("amount")) }
            .list().groupBy({ it.first }, { it.second })
        val expenses = jdbc.sql("SELECT * FROM expenses WHERE group_id = :id ORDER BY created_at, id").param("id", groupId)
            .query { rs, _ ->
                ExpenseDto(
                    id = rs.getString("id"),
                    description = rs.getString("description"),
                    amount = rs.getLong("amount"),
                    currency = rs.getString("currency"),
                    fxRateToDefault = rs.getObject("fx_rate_to_default", Double::class.javaObjectType),
                    paidBy = rs.getString("paid_by"),
                    date = rs.getObject("date", LocalDate::class.java).toString(),
                    category = rs.getString("category"),
                    deleted = rs.getObject("deleted_at") != null,
                    shares = shares[rs.getString("id")] ?: emptyList(),
                    notes = rs.getString("notes"),
                )
            }.list()
        val payments = jdbc.sql("SELECT * FROM payments WHERE group_id = :id ORDER BY created_at, id").param("id", groupId)
            .query { rs: ResultSet, _ ->
                PaymentDto(
                    id = rs.getString("id"),
                    fromMember = rs.getString("from_member"),
                    toMember = rs.getString("to_member"),
                    amount = rs.getLong("amount"),
                    currency = rs.getString("currency"),
                    date = rs.getObject("date", LocalDate::class.java).toString(),
                    deleted = rs.getObject("deleted_at") != null,
                    status = rs.getString("status"),
                )
            }.list()
        val comments = jdbc.sql("SELECT * FROM comments WHERE group_id = :id ORDER BY created_at, id").param("id", groupId)
            .query { rs, _ ->
                CommentDto(
                    id = rs.getString("id"),
                    expenseId = rs.getString("expense_id"),
                    authorMemberId = rs.getString("author_member_id"),
                    text = rs.getString("text"),
                    createdAt = rs.getObject("created_at", OffsetDateTime::class.java).toInstant().toString(),
                    deleted = rs.getObject("deleted_at") != null,
                )
            }.list()
        return GroupState(
            name = group?.first,
            defaultCurrency = group?.second,
            members = members.associateBy { it.id },
            expenses = expenses.associateBy { it.id },
            payments = payments.associateBy { it.id },
            comments = comments.associateBy { it.id },
        )
    }

    /**
     * Upserts the one entity the event refers to, taking its values from the already-applied state. Ids are global
     * primary keys: an id that already belongs to another group is rejected (400, the push transaction rolls back),
     * otherwise a client could take over another group's member, expense, payment or comment row.
     */
    fun persist(groupId: UUID, actorUserId: UUID, state: GroupState, type: String, payload: JsonNode) {
        when (type.substringBefore('.')) {
            "group" -> jdbc.sql("UPDATE groups SET name = :name, default_currency = :cur WHERE id = :id")
                .param("name", state.name).param("cur", state.defaultCurrency).param("id", groupId).update()
            "member" -> state.members[payload.text("memberId")]?.let { upsertMember(groupId, it) }
            "expense" -> state.expenses[payload.text("expenseId")]?.let { upsertExpense(groupId, actorUserId, it) }
            "payment" -> state.payments[payload.text("paymentId")]?.let { upsertPayment(groupId, actorUserId, it) }
            "comment" -> state.comments[payload.text("commentId")]?.let { upsertComment(groupId, it) }
        }
    }

    private fun upsertMember(groupId: UUID, m: MemberDto) {
        jdbc.sql(
            """
            INSERT INTO members (id, group_id, user_id, name, removed) VALUES (:id, :groupId, :userId, :name, :removed)
            ON CONFLICT (id) DO UPDATE SET user_id = EXCLUDED.user_id, name = EXCLUDED.name, removed = EXCLUDED.removed
            WHERE members.group_id = EXCLUDED.group_id
            """
        ).param("id", UUID.fromString(m.id)).param("groupId", groupId).param("userId", m.userId?.let(UUID::fromString))
            .param("name", m.name).param("removed", m.removed).update().requireOwnRow()
    }

    private fun upsertExpense(groupId: UUID, actorUserId: UUID, e: ExpenseDto) {
        val now = OffsetDateTime.now()
        jdbc.sql(
            """
            INSERT INTO expenses (id, group_id, description, amount, currency, fx_rate_to_default, paid_by, date, category, notes, created_by, updated_at, deleted_at)
            VALUES (:id, :groupId, :description, :amount, :currency, :fx, :paidBy, :date, :category, :notes, :actor, :now, CASE WHEN :deleted THEN :now ELSE NULL END)
            ON CONFLICT (id) DO UPDATE SET
              description = EXCLUDED.description, amount = EXCLUDED.amount, currency = EXCLUDED.currency,
              fx_rate_to_default = EXCLUDED.fx_rate_to_default, paid_by = EXCLUDED.paid_by, date = EXCLUDED.date,
              category = EXCLUDED.category, notes = EXCLUDED.notes, updated_at = EXCLUDED.updated_at,
              deleted_at = CASE WHEN :deleted THEN COALESCE(expenses.deleted_at, EXCLUDED.updated_at) ELSE NULL END
            WHERE expenses.group_id = EXCLUDED.group_id
            """
        ).param("id", UUID.fromString(e.id)).param("groupId", groupId).param("description", e.description)
            .param("amount", e.amount).param("currency", e.currency).param("fx", e.fxRateToDefault)
            .param("paidBy", UUID.fromString(e.paidBy)).param("date", LocalDate.parse(e.date)).param("category", e.category)
            .param("notes", e.notes).param("actor", actorUserId).param("now", now).param("deleted", e.deleted).update().requireOwnRow()
        jdbc.sql("DELETE FROM expense_shares WHERE expense_id = :id").param("id", UUID.fromString(e.id)).update()
        for ((i, s) in e.shares.withIndex()) {
            jdbc.sql("INSERT INTO expense_shares (expense_id, member_id, amount, position) VALUES (:eid, :mid, :amount, :pos)")
                .param("eid", UUID.fromString(e.id)).param("mid", UUID.fromString(s.memberId)).param("amount", s.amount).param("pos", i).update()
        }
    }

    private fun upsertPayment(groupId: UUID, actorUserId: UUID, p: PaymentDto) {
        jdbc.sql(
            """
            INSERT INTO payments (id, group_id, from_member, to_member, amount, currency, date, created_by, status, deleted_at)
            VALUES (:id, :groupId, :from, :to, :amount, :currency, :date, :actor, :status, CASE WHEN :deleted THEN :now ELSE NULL END)
            ON CONFLICT (id) DO UPDATE SET
              from_member = EXCLUDED.from_member, to_member = EXCLUDED.to_member, amount = EXCLUDED.amount,
              currency = EXCLUDED.currency, date = EXCLUDED.date, status = EXCLUDED.status,
              deleted_at = CASE WHEN :deleted THEN COALESCE(payments.deleted_at, :now) ELSE NULL END
            WHERE payments.group_id = EXCLUDED.group_id
            """
        ).param("id", UUID.fromString(p.id)).param("groupId", groupId).param("from", UUID.fromString(p.fromMember))
            .param("to", UUID.fromString(p.toMember)).param("amount", p.amount).param("currency", p.currency)
            .param("date", LocalDate.parse(p.date)).param("actor", actorUserId).param("deleted", p.deleted)
            .param("status", p.status).param("now", OffsetDateTime.now()).update().requireOwnRow()
    }

    /** Only the tombstone changes after creation (a deleted comment's text becomes ""). */
    private fun upsertComment(groupId: UUID, c: CommentDto) {
        jdbc.sql(
            """
            INSERT INTO comments (id, group_id, expense_id, author_member_id, text, created_at, deleted_at)
            VALUES (:id, :groupId, :expenseId, :author, :text, :createdAt, CASE WHEN :deleted THEN :now ELSE NULL END)
            ON CONFLICT (id) DO UPDATE SET text = EXCLUDED.text,
              deleted_at = CASE WHEN :deleted THEN COALESCE(comments.deleted_at, :now) ELSE NULL END
            WHERE comments.group_id = EXCLUDED.group_id
            """
        ).param("id", UUID.fromString(c.id)).param("groupId", groupId).param("expenseId", UUID.fromString(c.expenseId))
            .param("author", UUID.fromString(c.authorMemberId)).param("text", c.text)
            .param("createdAt", Instant.parse(c.createdAt).atOffset(ZoneOffset.UTC)).param("deleted", c.deleted)
            .param("now", OffsetDateTime.now()).update().requireOwnRow()
    }

    /** An upsert whose ON CONFLICT ... WHERE same group did not match touched 0 rows: the id is another group's. */
    private fun Int.requireOwnRow() {
        if (this == 0) throw ApiException.badRequest("VALIDATION", "This id is already used in another group")
    }

    /** Of these comment ids, the ones deleted now (feed hiding rule 5). */
    fun deletedComments(ids: Collection<String>): Set<String> {
        if (ids.isEmpty()) return emptySet()
        return jdbc.sql("SELECT id FROM comments WHERE id IN (:ids) AND deleted_at IS NOT NULL")
            .param("ids", ids.map(UUID::fromString)).query(String::class.java).list().filterNotNull().toSet()
    }

    /** Who created a stored payment (null if unknown); used for payment.deleted permission. */
    fun paymentCreator(paymentId: String): String? =
        jdbc.sql("SELECT created_by FROM payments WHERE id = :id").param("id", UUID.fromString(paymentId))
            .query { rs, _ -> rs.getString("created_by") }.optional().orElse(null)
}
