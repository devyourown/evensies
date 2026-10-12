package dev.nariinfo.evensies.sync

import dev.nariinfo.evensies.group.GroupDto
import tools.jackson.databind.JsonNode
import java.time.Instant
import java.util.UUID

// Snapshot shapes (docs/API.md). The same classes are the in-memory state the applier works on,
// so ids are plain strings: shared/sync-cases.json uses ids like "m1", the DB uses UUID strings.
data class MemberDto(val id: String, val name: String, val userId: String?, val removed: Boolean = false)
data class ShareDto(val memberId: String, val amount: Long)
data class ExpenseDto(
    val id: String,
    val description: String,
    val amount: Long,
    val currency: String,
    val fxRateToDefault: Double?,
    val paidBy: String,
    val date: String,
    val category: String?,
    val deleted: Boolean,
    val shares: List<ShareDto>,
    /** Free text, at most 500 UTF-16 chars; missing in old events = null. */
    val notes: String? = null,
    /**
     * Who paid (for a refund: who received it), in the order sent, summing to [amount]; [paidBy] is the primary payer
     * (applier rule 10). The defaults read events and stored feed meta from before Phase 3.
     */
    val payers: List<ShareDto> = listOf(ShareDto(paidBy, amount)),
    /** Money that came back: its balance effect is the reverse of an expense. */
    val refund: Boolean = false,
    /** SplitSpec as sent (docs/API.md "SplitSpec"): a hint for the editor, never used to recompute [shares]. null = exact. */
    val split: JsonNode? = null,
    /** Deleted by a move (`expense.deleted` with `movedTo`): it counts in the other group now, so it stays deleted (rule 13). */
    val moved: Boolean = false,
    /** Phase 8 (rule 16): the repeating series this expense belongs to and its number in it (0 = first); both or neither. */
    val recurrenceId: String? = null,
    val occurrence: Int? = null,
)
data class PaymentDto(
    val id: String,
    val fromMember: String,
    val toMember: String,
    val amount: Long,
    val currency: String,
    val date: String,
    val deleted: Boolean,
    /** "sent" (payer says it is paid) or "confirmed" (receiver confirmed, or no confirmation needed). */
    val status: String = "confirmed",
    /** Deleted by an edit (`payment.deleted` with `replacedBy`): the new payment counts now, so it stays deleted (rule 7). */
    val replaced: Boolean = false,
)

/** A receipt photo on an expense (Phase 7, rule 14). Only attached ones are in the state; deleted ones stay as tombstones. */
data class AttachmentDto(val id: String, val expenseId: String, val deleted: Boolean = false)

/**
 * A repeating series (Phase 8, rule 15). [template] is the `expense.created` payload of each repeat without
 * `expenseId`, `date`, `recurrenceId` and `occurrence`, kept as sent. Stopped series stay as tombstones (deleted = true).
 */
data class RecurrenceDto(
    val id: String,
    val frequency: String,
    val startDate: String,
    val timeZone: String,
    val template: JsonNode,
    val deleted: Boolean = false,
)

/**
 * Deleted comments stay as tombstones (deleted = true), like expenses and payments. Exactly one of [expenseId] and
 * [paymentId] (Phase 6, a comment on a payment) is set.
 */
data class CommentDto(
    val id: String,
    val expenseId: String?,
    val paymentId: String? = null,
    val authorMemberId: String,
    val text: String,
    val createdAt: String,
    val deleted: Boolean = false,
)

data class SnapshotDto(
    val group: GroupDto,
    val members: List<MemberDto>,
    val expenses: List<ExpenseDto>,
    val payments: List<PaymentDto>,
    val comments: List<CommentDto>,
    val attachments: List<AttachmentDto>,
    val recurrences: List<RecurrenceDto>,
    val latestSeq: Long,
)

// push / pull
data class IncomingEvent(val clientId: UUID, val type: String, val payload: JsonNode, val createdAt: Instant)
data class SeqResult(val clientId: UUID, val seq: Long)
data class PushResult(val results: List<SeqResult>, val latestSeq: Long)
data class EventDto(
    val seq: Long,
    val clientId: UUID,
    val type: String,
    val payload: JsonNode,
    val actorUserId: UUID?,
    val createdAt: Instant,
)
data class PullResult(val events: List<EventDto>, val latestSeq: Long)
