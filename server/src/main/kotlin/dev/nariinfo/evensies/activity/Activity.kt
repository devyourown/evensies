package dev.nariinfo.evensies.activity

import dev.nariinfo.evensies.sync.Event
import dev.nariinfo.evensies.sync.ExpenseDto
import dev.nariinfo.evensies.sync.GroupState
import dev.nariinfo.evensies.sync.PaymentDto
import dev.nariinfo.evensies.sync.text
import tools.jackson.databind.JsonNode
import java.time.Instant
import java.util.UUID

data class GroupInfo(val name: String?, val defaultCurrency: String?)

/**
 * Stored in `events.meta` (server-internal, never pulled): what the feed needs about one event, captured while it is
 * applied. [noop] = the applier left the whole state unchanged. [expense] is the touched expense just after the event
 * (for `comment.*` the comment's expense), [expenseBefore] just before it; [group]/[groupBefore] likewise for `group.*`.
 */
data class EventMeta(
    val actorMemberId: String? = null,
    val noop: Boolean = false,
    val groupBefore: GroupInfo? = null,
    val group: GroupInfo? = null,
    val expenseBefore: ExpenseDto? = null,
    val expense: ExpenseDto? = null,
    val payment: PaymentDto? = null,
)

data class Change(val field: String, val from: Any?, val to: Any?)

/** docs/API.md "피드": every key is always present; unused ones are null, [changes] is []. */
data class ActivityItem(
    val groupId: UUID? = null,
    val feedId: Long? = null,
    val seq: Long,
    val kind: String,
    val createdAt: Instant,
    val actorMemberId: String? = null,
    val memberId: String? = null,
    val expenseId: String? = null,
    val commentId: String? = null,
    val paymentId: String? = null,
    val name: String? = null,
    val description: String? = null,
    val amount: Long? = null,
    val currency: String? = null,
    val fromMember: String? = null,
    val toMember: String? = null,
    val status: String? = null,
    val myDelta: Long? = null,
    val text: String? = null,
    val changes: List<Change> = emptyList(),
)

data class ActivityPage(val items: List<ActivityItem>, val nextBefore: Long?)

/** Feed derivation, shared by the feed endpoints and push (checked by shared/activity-cases.json). */
object Activity {
    private val EXPENSE_KINDS = mapOf(
        "expense.created" to "expense_added", "expense.updated" to "expense_updated",
        "expense.deleted" to "expense_deleted", "expense.restored" to "expense_restored",
    )
    private val PAYMENT_KINDS = mapOf(
        "payment.created" to "payment_added", "payment.confirmed" to "payment_confirmed", "payment.deleted" to "payment_deleted",
    )
    private val GROUP_FIELDS = listOf<Pair<String, (GroupInfo) -> Any?>>("name" to GroupInfo::name, "defaultCurrency" to GroupInfo::defaultCurrency)
    private val EXPENSE_FIELDS = listOf<Pair<String, (ExpenseDto) -> Any?>>(
        "description" to ExpenseDto::description, "amount" to ExpenseDto::amount, "currency" to ExpenseDto::currency,
        "fxRateToDefault" to ExpenseDto::fxRateToDefault, "paidBy" to ExpenseDto::paidBy, "date" to ExpenseDto::date,
        "category" to ExpenseDto::category, "shares" to ExpenseDto::shares, "notes" to ExpenseDto::notes,
    )
    /** Listed only by name: the values are not shown. */
    private val OPAQUE = setOf("shares", "notes")

    /**
     * Meta for one event applied as [before] → [after]. The actor is looked up in [after]; callers fill a missing one
     * from the state after the whole push batch (or the whole log) with [memberOfUser].
     */
    fun meta(before: GroupState, after: GroupState, type: String, p: JsonNode, actorUserId: String?): EventMeta {
        // group.created exists once (seq 1, server-made) and POST /groups stores the group row before it, so the
        // loaded state already has the name: never a no-op.
        val m = EventMeta(actorMemberId = after.memberOfUser(actorUserId), noop = before == after && type != "group.created")
        return when (type.substringBefore('.')) {
            "group" -> m.copy(groupBefore = GroupInfo(before.name, before.defaultCurrency), group = GroupInfo(after.name, after.defaultCurrency))
            "expense" -> m.copy(expenseBefore = before.expenses[p.text("expenseId")], expense = after.expenses[p.text("expenseId")])
            "comment" -> m.copy(expense = after.expenses[p.text("expenseId")])
            "payment" -> m.copy(payment = after.payments[p.text("paymentId")])
            else -> m
        }
    }

    /** The member linked to [userId] (an active one first: a user who left and rejoined has two). */
    fun GroupState.memberOfUser(userId: String?): String? {
        val linked = members.values.filter { userId != null && it.userId == userId }
        return (linked.firstOrNull { !it.removed } ?: linked.firstOrNull())?.id
    }

    /** The feed item for viewer [me] (a member id), or null when the event is hidden. */
    fun item(seq: Long, type: String, p: JsonNode, actorUserId: String?, createdAt: Instant, meta: EventMeta, me: String?): ActivityItem? {
        if (meta.noop || type == "comment.deleted" || (type == "member.added" && seq == 2L)) return null
        val base = ActivityItem(seq = seq, kind = "", createdAt = createdAt, actorMemberId = meta.actorMemberId)
        return when (type) {
            "group.created" -> base.copy(kind = "group_created", name = meta.group?.name)
            "group.updated" -> base.copy(kind = "group_updated", changes = changes(meta.groupBefore, meta.group, GROUP_FIELDS))
            "member.added" -> base.copy(
                kind = if (p.text("userId") != null && p.text("userId") == actorUserId) "member_joined" else "member_added",
                memberId = p.text("memberId"),
            )
            "member.linked" -> base.copy(kind = "member_joined", memberId = p.text("memberId"))
            "member.removed" -> base.copy(kind = "member_removed", memberId = p.text("memberId"))
            in EXPENSE_KINDS -> meta.expense?.let { x ->
                base.copy(
                    kind = EXPENSE_KINDS.getValue(type), expenseId = x.id, description = x.description, amount = x.amount,
                    currency = x.currency, myDelta = myDelta(x, me),
                    changes = if (type == "expense.updated") changes(meta.expenseBefore, x, EXPENSE_FIELDS) else emptyList(),
                )
            }
            "comment.added" -> base.copy(
                kind = "comment_added", expenseId = p.text("expenseId"), commentId = p.text("commentId"),
                description = meta.expense?.description, text = p.text("text"),
            )
            in PAYMENT_KINDS -> meta.payment?.let { x ->
                base.copy(
                    kind = PAYMENT_KINDS.getValue(type), paymentId = x.id, fromMember = x.fromMember, toMember = x.toMember,
                    amount = x.amount, currency = x.currency, status = x.status,
                )
            }
            else -> null
        }
    }

    /**
     * [item] for a stored event, timed when the server received it (list order); null for hidden events and for rows
     * the backfill has not reached yet.
     */
    fun Event.item(me: String?): ActivityItem? = meta?.let {
        item(seq, type, payload, actorUserId?.toString(), receivedAt ?: createdAt, it, me)?.copy(groupId = groupId, feedId = feedId)
    }

    /**
     * Hiding rule 5: a `comment_added` whose comment has been deleted since, so deleting takes the text back from feeds
     * and from pushes not sent yet. [deleted] returns which of the given comment ids are deleted now.
     */
    fun List<ActivityItem>.withoutDeletedComments(deleted: (List<String>) -> Set<String>): List<ActivityItem> {
        val ids = filter { it.kind == "comment_added" }.mapNotNull { it.commentId }
        if (ids.isEmpty()) return this
        val gone = deleted(ids)
        return filterNot { it.kind == "comment_added" && it.commentId in gone }
    }

    /** `(paidBy == me ? amount : 0) − my share`; null when [me] neither paid nor has a share. */
    private fun myDelta(x: ExpenseDto, me: String?): Long? {
        val share = x.shares.firstOrNull { it.memberId == me }?.amount
        if (me == null || (x.paidBy != me && share == null)) return null
        return (if (x.paidBy == me) x.amount else 0) - (share ?: 0)
    }

    private fun <T> changes(before: T?, after: T?, fields: List<Pair<String, (T) -> Any?>>): List<Change> {
        if (before == null || after == null) return emptyList()
        return fields.mapNotNull { (field, get) ->
            val from = get(before)
            val to = get(after)
            when {
                from == to -> null
                field in OPAQUE -> Change(field, null, null)
                else -> Change(field, from, to)
            }
        }
    }
}
