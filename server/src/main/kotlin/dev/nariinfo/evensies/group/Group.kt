package dev.nariinfo.evensies.group

import tools.jackson.databind.JsonNode
import java.time.Instant
import java.util.UUID

data class Group(
    val id: UUID,
    val name: String,
    val defaultCurrency: String,
    val inviteCode: String,
    val createdBy: UUID,
    val createdAt: Instant,
    val latestSeq: Long,
    val simplifyDebts: Boolean = true,
    val defaultSplit: JsonNode? = null,
    /** "group" or "friend" (docs/API.md "친구"); fixed at creation. */
    val kind: String = "group",
    /** Phase 10 (rule 17): trip, home, couple or other; the current cover; deleted for everyone (restorable). */
    val type: String = "other",
    val coverImageId: UUID? = null,
    val deleted: Boolean = false,
) {
    fun toDto(myMemberId: UUID?) =
        GroupDto(id, name, defaultCurrency, inviteCode, createdAt, latestSeq, myMemberId, simplifyDebts, defaultSplit, kind, type, coverImageId, deleted)
}

data class GroupDto(
    val id: UUID,
    val name: String,
    val defaultCurrency: String,
    val inviteCode: String,
    val createdAt: Instant,
    val latestSeq: Long,
    val myMemberId: UUID?,
    /** Group settings (docs/API.md "그룹"), changed by `group.updated`. */
    val simplifyDebts: Boolean,
    val defaultSplit: JsonNode?,
    val kind: String,
    val type: String,
    val coverImageId: UUID?,
    val deleted: Boolean,
)

/** GET /groups lists deleted groups too (`deleted`), so the app can offer Restore. */
data class GroupSummaryDto(
    val id: UUID, val name: String, val defaultCurrency: String, val latestSeq: Long, val memberCount: Int, val kind: String,
    val type: String, val coverImageId: UUID?, val deleted: Boolean,
)

/** [type] (Phase 10): missing = "other". */
data class CreateGroupRequest(val id: UUID, val name: String, val defaultCurrency: String, val memberId: UUID, val memberName: String, val type: String? = null)

data class InviteCodeDto(val inviteCode: String)

data class InvitePreviewDto(val groupId: UUID, val name: String, val kind: String, val memberCount: Int, val members: List<InviteMemberDto>)
data class InviteMemberDto(val id: UUID, val name: String, val linked: Boolean)

/** Either memberId (claim a placeholder) or newMemberId + name. */
data class JoinRequest(val memberId: UUID? = null, val newMemberId: UUID? = null, val name: String? = null)
