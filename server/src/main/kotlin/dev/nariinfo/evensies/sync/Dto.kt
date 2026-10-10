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
)
data class PaymentDto(
    val id: String,
    val fromMember: String,
    val toMember: String,
    val amount: Long,
    val currency: String,
    val date: String,
    val deleted: Boolean,
)

data class SnapshotDto(
    val group: GroupDto,
    val members: List<MemberDto>,
    val expenses: List<ExpenseDto>,
    val payments: List<PaymentDto>,
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
