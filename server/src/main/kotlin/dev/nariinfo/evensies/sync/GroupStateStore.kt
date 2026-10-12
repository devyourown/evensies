package dev.nariinfo.evensies.sync

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.recurrence.Schedule
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.stereotype.Repository
import tools.jackson.databind.JsonNode
import tools.jackson.databind.ObjectMapper
import java.sql.ResultSet
import java.time.Duration
import java.time.LocalDate
import java.time.Instant
import java.time.OffsetDateTime
import java.time.ZoneId
import java.time.ZoneOffset
import java.util.UUID

/** Loads a group's state from the member/expense/payment/comment/attachment/recurrence tables and writes back what an event touched. */
@Repository
class GroupStateStore(private val jdbc: JdbcClient, private val mapper: ObjectMapper) {
    fun load(groupId: UUID): GroupState {
        val group = jdbc.sql("SELECT name, default_currency, simplify_debts, default_split, kind, type, cover_image_id, deleted_at FROM groups WHERE id = :id")
            .param("id", groupId).query { rs, _ ->
                GroupState(
                    name = rs.getString("name"), defaultCurrency = rs.getString("default_currency"),
                    simplifyDebts = rs.getBoolean("simplify_debts"), defaultSplit = json(rs.getString("default_split")),
                    kind = rs.getString("kind"), type = rs.getString("type"), coverImageId = rs.getString("cover_image_id"),
                    deleted = rs.getObject("deleted_at") != null,
                )
            }.optional().orElse(GroupState())
        val members = jdbc.sql("SELECT * FROM members WHERE group_id = :id ORDER BY created_at, id").param("id", groupId)
            .query { rs, _ ->
                MemberDto(rs.getString("id"), rs.getString("name"), rs.getString("user_id"), rs.getBoolean("removed"))
            }.list()
        fun lines(table: String) = jdbc.sql(
            "SELECT s.* FROM $table s JOIN expenses e ON e.id = s.expense_id WHERE e.group_id = :id ORDER BY s.expense_id, s.position"
        ).param("id", groupId).query { rs, _ -> rs.getString("expense_id") to ShareDto(rs.getString("member_id"), rs.getLong("amount")) }
            .list().groupBy({ it.first }, { it.second })
        val shares = lines("expense_shares")
        val payers = lines("expense_payers")
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
                    payers = payers[rs.getString("id")] ?: listOf(ShareDto(rs.getString("paid_by"), rs.getLong("amount"))),
                    refund = rs.getBoolean("refund"),
                    split = json(rs.getString("split")),
                    moved = rs.getBoolean("moved"),
                    recurrenceId = rs.getString("recurrence_id"),
                    occurrence = rs.getObject("occurrence", Int::class.javaObjectType),
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
                    replaced = rs.getBoolean("replaced"),
                )
            }.list()
        val comments = jdbc.sql("SELECT * FROM comments WHERE group_id = :id ORDER BY created_at, id").param("id", groupId)
            .query { rs, _ ->
                CommentDto(
                    id = rs.getString("id"),
                    expenseId = rs.getString("expense_id"),
                    paymentId = rs.getString("payment_id"),
                    authorMemberId = rs.getString("author_member_id"),
                    text = rs.getString("text"),
                    createdAt = rs.getObject("created_at", OffsetDateTime::class.java).toInstant().toString(),
                    deleted = rs.getObject("deleted_at") != null,
                )
            }.list()
        // Attached receipts only; upload order, which can differ from a replay's attach order (docs/API.md "snapshot").
        val attachments = jdbc.sql(
            "SELECT id, expense_id, deleted_at FROM attachments WHERE group_id = :id AND expense_id IS NOT NULL ORDER BY created_at, id"
        ).param("id", groupId).query { rs, _ -> AttachmentDto(rs.getString("id"), rs.getString("expense_id"), rs.getObject("deleted_at") != null) }.list()
        val recurrences = jdbc.sql(
            "SELECT id, frequency, start_date, time_zone, template, deleted_at, remind_days_before FROM recurrences WHERE group_id = :id ORDER BY created_at, id"
        ).param("id", groupId).query { rs, _ ->
            RecurrenceDto(
                rs.getString("id"), rs.getString("frequency"), rs.getObject("start_date", LocalDate::class.java).toString(),
                rs.getString("time_zone"), mapper.readTree(rs.getString("template")), rs.getObject("deleted_at") != null,
                rs.getObject("remind_days_before", Int::class.javaObjectType),
            )
        }.list()
        return group.copy(
            recurrences = recurrences.associateBy { it.id },
            members = members.associateBy { it.id },
            expenses = expenses.associateBy { it.id },
            payments = payments.associateBy { it.id },
            comments = comments.associateBy { it.id },
            attachments = attachments.associateBy { it.id },
        )
    }

    /**
     * Upserts the one entity the event refers to, taking its values from the already-applied state. Ids are global
     * primary keys: an id that already belongs to another group is rejected (400, the push transaction rolls back),
     * otherwise a client could take over another group's member, expense, payment or comment row. [actorUserId] null =
     * Evensies (Phase 8 scheduler); [createdAt] is the event's (client) time, used when a series is first stored.
     */
    fun persist(groupId: UUID, actorUserId: UUID?, state: GroupState, type: String, payload: JsonNode, createdAt: Instant) {
        when (type.substringBefore('.')) {
            "group" -> {
                val restored = type == "group.restored" &&
                    jdbc.sql("SELECT deleted_at IS NOT NULL FROM groups WHERE id = :id").param("id", groupId).query(Boolean::class.java).single()
                jdbc.sql(
                    """
                    UPDATE groups SET name = :name, default_currency = :cur, simplify_debts = :simplify, default_split = CAST(:split AS jsonb),
                      type = :type, cover_image_id = :cover, deleted_at = CASE WHEN :deleted THEN COALESCE(deleted_at, now()) ELSE NULL END
                    WHERE id = :id
                    """
                ).param("name", state.name).param("cur", state.defaultCurrency).param("simplify", state.simplifyDebts)
                    .param("split", state.defaultSplit?.let(mapper::writeValueAsString)).param("type", state.type)
                    .param("cover", state.coverImageId?.let(UUID::fromString)).param("deleted", state.deleted).param("id", groupId).update()
                if (restored) restartSeries(groupId)
            }
            "member" -> state.members[payload.text("memberId")]?.let { upsertMember(groupId, it) }
            "expense" -> state.expenses[payload.text("expenseId")]?.let { upsertExpense(groupId, actorUserId, it) }
            "payment" -> state.payments[payload.text("paymentId")]?.let { upsertPayment(groupId, actorUserId, it) }
            "comment" -> state.comments[payload.text("commentId")]?.let { upsertComment(groupId, it) }
            // The upload made the row (validated for attachment.added); the group check keeps other groups' rows out.
            "attachment" -> state.attachments[payload.text("attachmentId")]?.let { a ->
                jdbc.sql(
                    """
                    UPDATE attachments SET expense_id = :expenseId,
                      deleted_at = CASE WHEN :deleted THEN COALESCE(deleted_at, now()) ELSE NULL END
                    WHERE id = :id AND group_id = :groupId
                    """
                ).param("expenseId", UUID.fromString(a.expenseId)).param("deleted", a.deleted).param("id", UUID.fromString(a.id))
                    .param("groupId", groupId).update()
            }
            "recurrence" -> state.recurrences[payload.text("recurrenceId")]?.let { upsertRecurrence(groupId, actorUserId, it, createdAt) }
        }
    }

    /**
     * After creation only the template and the stop change. The scheduler's columns are set on the first insert only:
     * the first occurrence on or after the creation day in the series' zone, where creation is the event's createdAt
     * limited to the last [CATCH_UP] (an offline-made series keeps its repeats, a wrong clock can't add a burst).
     */
    private fun upsertRecurrence(groupId: UUID, actorUserId: UUID?, r: RecurrenceDto, createdAt: Instant) {
        val now = Instant.now()
        val created = createdAt.coerceIn(now - CATCH_UP, now)
        val start = LocalDate.parse(r.startDate)
        val (n, date) = Schedule.firstOnOrAfter(r.frequency, start, LocalDate.ofInstant(created, ZoneId.of(r.timeZone)))
        jdbc.sql(
            """
            INSERT INTO recurrences (id, group_id, frequency, start_date, time_zone, template, created_by, deleted_at, next_occurrence, next_due_at, remind_days_before)
            VALUES (:id, :groupId, :frequency, :startDate, :timeZone, CAST(:template AS jsonb), :actor, CASE WHEN :deleted THEN now() ELSE NULL END, :n, :due, :remind)
            ON CONFLICT (id) DO UPDATE SET template = EXCLUDED.template, remind_days_before = EXCLUDED.remind_days_before,
              deleted_at = CASE WHEN :deleted THEN COALESCE(recurrences.deleted_at, now()) ELSE NULL END
            WHERE recurrences.group_id = EXCLUDED.group_id
            """
        ).param("id", UUID.fromString(r.id)).param("groupId", groupId).param("frequency", r.frequency).param("startDate", start)
            .param("remind", r.remindDaysBefore)
            .param("timeZone", r.timeZone).param("template", mapper.writeValueAsString(r.template)).param("actor", actorUserId)
            .param("deleted", r.deleted).param("n", n).param("due", Schedule.dueAt(date, r.timeZone).atOffset(ZoneOffset.UTC))
            .update().requireOwnRow()
    }

    /**
     * A restored group's live series skip the deleted period (docs/API.md "그룹 삭제"): each moves on to its first
     * occurrence on or after today in its zone (never back), so the days it was deleted are not posted in a burst.
     */
    private fun restartSeries(groupId: UUID) {
        class Live(val id: UUID, val frequency: String, val start: LocalDate, val zone: String, val n: Int)
        val rows = jdbc.sql("SELECT id, frequency, start_date, time_zone, next_occurrence FROM recurrences WHERE group_id = :g AND deleted_at IS NULL")
            .param("g", groupId).query { rs, _ ->
                Live(rs.getObject("id", UUID::class.java), rs.getString("frequency"), rs.getObject("start_date", LocalDate::class.java), rs.getString("time_zone"), rs.getInt("next_occurrence"))
            }.list()
        for (r in rows) {
            val (n, date) = Schedule.firstOnOrAfter(r.frequency, r.start, LocalDate.now(ZoneId.of(r.zone)), minN = r.n)
            jdbc.sql("UPDATE recurrences SET next_occurrence = :n, next_due_at = :due WHERE id = :id")
                .param("n", n).param("due", Schedule.dueAt(date, r.zone).atOffset(ZoneOffset.UTC)).param("id", r.id).update()
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

    private fun upsertExpense(groupId: UUID, actorUserId: UUID?, e: ExpenseDto) {
        val now = OffsetDateTime.now()
        jdbc.sql(
            """
            INSERT INTO expenses (id, group_id, description, amount, currency, fx_rate_to_default, paid_by, date, category, notes, refund, split, moved, recurrence_id, occurrence, created_by, updated_at, deleted_at)
            VALUES (:id, :groupId, :description, :amount, :currency, :fx, :paidBy, :date, :category, :notes, :refund, CAST(:split AS jsonb), :moved, :recurrenceId, :occurrence, :actor, :now, CASE WHEN :deleted THEN :now ELSE NULL END)
            ON CONFLICT (id) DO UPDATE SET
              description = EXCLUDED.description, amount = EXCLUDED.amount, currency = EXCLUDED.currency,
              fx_rate_to_default = EXCLUDED.fx_rate_to_default, paid_by = EXCLUDED.paid_by, date = EXCLUDED.date,
              category = EXCLUDED.category, notes = EXCLUDED.notes, refund = EXCLUDED.refund, split = EXCLUDED.split,
              moved = EXCLUDED.moved, recurrence_id = EXCLUDED.recurrence_id, occurrence = EXCLUDED.occurrence, updated_at = EXCLUDED.updated_at,
              deleted_at = CASE WHEN :deleted THEN COALESCE(expenses.deleted_at, EXCLUDED.updated_at) ELSE NULL END
            WHERE expenses.group_id = EXCLUDED.group_id
            """
        ).param("id", UUID.fromString(e.id)).param("groupId", groupId).param("description", e.description)
            .param("amount", e.amount).param("currency", e.currency).param("fx", e.fxRateToDefault)
            .param("paidBy", UUID.fromString(e.paidBy)).param("date", LocalDate.parse(e.date)).param("category", e.category)
            .param("notes", e.notes).param("refund", e.refund).param("split", e.split?.let(mapper::writeValueAsString))
            .param("moved", e.moved).param("recurrenceId", e.recurrenceId?.let(UUID::fromString)).param("occurrence", e.occurrence)
            .param("actor", actorUserId).param("now", now).param("deleted", e.deleted).update().requireOwnRow()
        replaceLines("expense_shares", e.id, e.shares)
        replaceLines("expense_payers", e.id, e.payers)
    }

    /** Shares and payers are stored by delete-and-reinsert, keeping the order sent. */
    private fun replaceLines(table: String, expenseId: String, lines: List<ShareDto>) {
        val id = UUID.fromString(expenseId)
        jdbc.sql("DELETE FROM $table WHERE expense_id = :id").param("id", id).update()
        for ((i, s) in lines.withIndex()) {
            jdbc.sql("INSERT INTO $table (expense_id, member_id, amount, position) VALUES (:eid, :mid, :amount, :pos)")
                .param("eid", id).param("mid", UUID.fromString(s.memberId)).param("amount", s.amount).param("pos", i).update()
        }
    }

    private fun json(text: String?): JsonNode? = text?.let(mapper::readTree)

    private fun upsertPayment(groupId: UUID, actorUserId: UUID?, p: PaymentDto) {
        jdbc.sql(
            """
            INSERT INTO payments (id, group_id, from_member, to_member, amount, currency, date, created_by, status, replaced, deleted_at)
            VALUES (:id, :groupId, :from, :to, :amount, :currency, :date, :actor, :status, :replaced, CASE WHEN :deleted THEN :now ELSE NULL END)
            ON CONFLICT (id) DO UPDATE SET
              from_member = EXCLUDED.from_member, to_member = EXCLUDED.to_member, amount = EXCLUDED.amount,
              currency = EXCLUDED.currency, date = EXCLUDED.date, status = EXCLUDED.status, replaced = EXCLUDED.replaced,
              deleted_at = CASE WHEN :deleted THEN COALESCE(payments.deleted_at, :now) ELSE NULL END
            WHERE payments.group_id = EXCLUDED.group_id
            """
        ).param("id", UUID.fromString(p.id)).param("groupId", groupId).param("from", UUID.fromString(p.fromMember))
            .param("to", UUID.fromString(p.toMember)).param("amount", p.amount).param("currency", p.currency)
            .param("date", LocalDate.parse(p.date)).param("actor", actorUserId).param("deleted", p.deleted)
            .param("status", p.status).param("replaced", p.replaced).param("now", OffsetDateTime.now()).update().requireOwnRow()
    }

    /** Only the tombstone changes after creation (a deleted comment's text becomes ""). */
    private fun upsertComment(groupId: UUID, c: CommentDto) {
        jdbc.sql(
            """
            INSERT INTO comments (id, group_id, expense_id, payment_id, author_member_id, text, created_at, deleted_at)
            VALUES (:id, :groupId, :expenseId, :paymentId, :author, :text, :createdAt, CASE WHEN :deleted THEN :now ELSE NULL END)
            ON CONFLICT (id) DO UPDATE SET text = EXCLUDED.text,
              deleted_at = CASE WHEN :deleted THEN COALESCE(comments.deleted_at, :now) ELSE NULL END
            WHERE comments.group_id = EXCLUDED.group_id
            """
        ).param("id", UUID.fromString(c.id)).param("groupId", groupId).param("expenseId", c.expenseId?.let(UUID::fromString))
            .param("paymentId", c.paymentId?.let(UUID::fromString))
            .param("author", UUID.fromString(c.authorMemberId)).param("text", c.text)
            .param("createdAt", Instant.parse(c.createdAt).atOffset(ZoneOffset.UTC)).param("deleted", c.deleted)
            .param("now", OffsetDateTime.now()).update().requireOwnRow()
    }

    /** An upsert whose ON CONFLICT ... WHERE same group did not match touched 0 rows: the id is another group's. */
    private fun Int.requireOwnRow() {
        if (this == 0) throw ApiException.badRequest("VALIDATION", "This id is already used in another group")
    }

    companion object {
        /** How far back a series' creation time counts (docs/API.md "반복 지출"). */
        val CATCH_UP: Duration = Duration.ofDays(30)
    }

    /** Of these comment ids, the ones deleted now (feed hiding rule 5). */
    fun deletedComments(ids: Collection<String>): Set<String> {
        if (ids.isEmpty()) return emptySet()
        return jdbc.sql("SELECT id FROM comments WHERE id IN (:ids) AND deleted_at IS NOT NULL")
            .param("ids", ids.map(UUID::fromString)).query(String::class.java).list().filterNotNull().toSet()
    }

    /** The group an attachment id was uploaded to (null if never), deleted or not. */
    fun uploadGroup(attachmentId: UUID): UUID? =
        jdbc.sql("SELECT group_id FROM attachments WHERE id = :id").param("id", attachmentId).query(UUID::class.java).optional().orElse(null)

    /** This group's non-deleted upload row exists (attached or not): what a download may serve. */
    fun isLiveUpload(groupId: UUID, attachmentId: UUID): Boolean =
        jdbc.sql("SELECT count(*) FROM attachments WHERE id = :id AND group_id = :g AND deleted_at IS NULL")
            .param("id", attachmentId).param("g", groupId).query(Long::class.java).single() > 0

    /** A new upload, not on any expense yet; a DuplicateKeyException when the id is taken. */
    fun insertUpload(groupId: UUID, attachmentId: UUID, userId: UUID) {
        jdbc.sql("INSERT INTO attachments (id, group_id, uploaded_by) VALUES (:id, :g, :u)")
            .param("id", attachmentId).param("g", groupId).param("u", userId).update()
    }

    /** Who created a stored payment (null if unknown); used for payment.deleted / payment.restored permission. */
    fun paymentCreator(paymentId: String): String? =
        jdbc.sql("SELECT created_by FROM payments WHERE id = :id").param("id", UUID.fromString(paymentId))
            .query { rs, _ -> rs.getString("created_by") }.optional().orElse(null)
}
