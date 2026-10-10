package dev.nariinfo.tally.group

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
) {
    fun toDto(myMemberId: UUID?) = GroupDto(id, name, defaultCurrency, inviteCode, createdAt, latestSeq, myMemberId)
}

data class GroupDto(
    val id: UUID,
    val name: String,
    val defaultCurrency: String,
    val inviteCode: String,
    val createdAt: Instant,
    val latestSeq: Long,
    val myMemberId: UUID?,
)

data class GroupSummaryDto(val id: UUID, val name: String, val defaultCurrency: String, val latestSeq: Long, val memberCount: Int)

data class CreateGroupRequest(val id: UUID, val name: String, val defaultCurrency: String, val memberId: UUID, val memberName: String)

data class InviteCodeDto(val inviteCode: String)

data class InvitePreviewDto(val groupId: UUID, val name: String, val memberCount: Int, val members: List<InviteMemberDto>)
data class InviteMemberDto(val id: UUID, val name: String, val linked: Boolean)

/** Either memberId (claim a placeholder) or newMemberId + name. */
data class JoinRequest(val memberId: UUID? = null, val newMemberId: UUID? = null, val name: String? = null)
