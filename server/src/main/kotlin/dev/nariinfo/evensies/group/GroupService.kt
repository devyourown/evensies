package dev.nariinfo.evensies.group

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.money.Money
import dev.nariinfo.evensies.sync.EventService
import dev.nariinfo.evensies.sync.IncomingEvent
import org.springframework.context.annotation.Lazy
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import tools.jackson.databind.ObjectMapper
import java.time.Instant
import java.util.UUID

@Service
class GroupService(
    private val groups: GroupRepository,
    private val members: MemberRepository,
    @Lazy private val events: EventService,
    private val mapper: ObjectMapper,
) {

    /** 404 if the group does not exist, 403 if the user is not an active member. */
    fun requireMember(groupId: UUID, userId: UUID): Pair<Group, Member> {
        val group = groups.find(groupId) ?: throw ApiException.notFound("Group")
        val member = members.findByGroupAndUser(groupId, userId) ?: throw ApiException.forbidden()
        return group to member
    }

    fun get(groupId: UUID, userId: UUID): GroupDto = requireMember(groupId, userId).let { (g, m) -> g.toDto(m.id) }

    fun list(userId: UUID): List<GroupSummaryDto> = groups.listForUser(userId)

    @Transactional
    fun create(userId: UUID, req: CreateGroupRequest): GroupDto {
        groups.find(req.id)?.let { return get(req.id, userId) } // retried create is idempotent
        if (req.name.isBlank() || req.memberName.isBlank()) throw ApiException.badRequest("VALIDATION", "name and memberName are required")
        if (!Money.isKnown(req.defaultCurrency)) throw ApiException.badRequest("UNKNOWN_CURRENCY", "Unknown currency ${req.defaultCurrency}")
        requireGroupQuota(userId)
        groups.insert(Group(req.id, req.name, req.defaultCurrency, newInviteCode(), userId, Instant.now(), 0))
        events.pushValidated(
            req.id, userId, listOf(
                event("group.created", mapOf("name" to req.name, "defaultCurrency" to req.defaultCurrency)),
                event("member.added", mapOf("memberId" to req.memberId, "name" to req.memberName, "userId" to userId)),
            )
        )
        return get(req.id, userId)
    }

    fun rotateInvite(groupId: UUID, userId: UUID): InviteCodeDto {
        requireMember(groupId, userId)
        val code = newInviteCode()
        groups.updateInviteCode(groupId, code)
        return InviteCodeDto(code)
    }

    fun preview(code: String): InvitePreviewDto {
        val group = groups.findByInviteCode(InviteCodes.normalize(code)) ?: throw ApiException.notFound("Invite")
        val active = members.listByGroup(group.id).filter { !it.removed }
        return InvitePreviewDto(group.id, group.name, active.size, active.map { InviteMemberDto(it.id, it.name, it.userId != null) })
    }

    fun join(code: String, userId: UUID, req: JoinRequest): GroupDto {
        val group = groups.findByInviteCode(InviteCodes.normalize(code)) ?: throw ApiException.notFound("Invite")
        members.findByGroupAndUser(group.id, userId)?.let { return group.toDto(it.id) } // already a member
        requireGroupQuota(userId)
        val event = when {
            req.memberId != null -> {
                val placeholder = members.find(req.memberId)
                if (placeholder == null || placeholder.groupId != group.id || placeholder.removed) throw ApiException.notFound("Member")
                if (placeholder.userId != null) throw ApiException.badRequest("MEMBER_TAKEN", "That member is already linked to a user")
                event("member.linked", mapOf("memberId" to req.memberId, "userId" to userId))
            }
            req.newMemberId != null && !req.name.isNullOrBlank() ->
                event("member.added", mapOf("memberId" to req.newMemberId, "name" to req.name, "userId" to userId))
            else -> throw ApiException.badRequest("VALIDATION", "Send memberId, or newMemberId and name")
        }
        events.pushValidated(group.id, userId, listOf(event))
        return get(group.id, userId)
    }

    private fun requireGroupQuota(userId: UUID) {
        if (members.countGroupsOfUser(userId) >= MAX_GROUPS_PER_USER) throw ApiException.limit("A user can be in at most $MAX_GROUPS_PER_USER groups")
    }

    private fun event(type: String, payload: Map<String, Any?>) =
        IncomingEvent(UUID.randomUUID(), type, mapper.valueToTree(payload), Instant.now())

    /** Retries on the (rare) collision with an existing group's code. */
    private fun newInviteCode(): String = generateSequence { InviteCodes.generate() }.first { groups.findByInviteCode(it) == null }

    companion object {
        const val MAX_GROUPS_PER_USER = 100
    }
}
