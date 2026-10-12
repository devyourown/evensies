package dev.nariinfo.evensies.group

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.friend.FriendRepository
import dev.nariinfo.evensies.money.Money
import dev.nariinfo.evensies.sync.EventService
import dev.nariinfo.evensies.sync.EventValidator
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
    private val friends: FriendRepository,
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
        if (req.type != null && req.type !in EventValidator.GROUP_TYPES) {
            throw ApiException.badRequest("VALIDATION", "type must be one of ${EventValidator.GROUP_TYPES.joinToString()}")
        }
        requireGroupQuota(userId)
        groups.insert(Group(req.id, req.name, req.defaultCurrency, groups.newCode(), userId, Instant.now(), 0))
        val created = mapOf("name" to req.name, "defaultCurrency" to req.defaultCurrency) + (req.type?.let { mapOf("type" to it) } ?: emptyMap())
        events.pushValidated(
            req.id, userId, listOf(
                event("group.created", created),
                event("member.added", mapOf("memberId" to req.memberId, "name" to req.memberName, "userId" to userId)),
            )
        )
        return get(req.id, userId)
    }

    fun rotateInvite(groupId: UUID, userId: UUID): InviteCodeDto {
        requireMember(groupId, userId)
        val code = groups.newCode()
        groups.updateInviteCode(groupId, code)
        return InviteCodeDto(code)
    }

    /** A deleted group's invite is 404 (preview, landing and join), like an unknown code. */
    private fun invited(code: String): Group =
        groups.findByInviteCode(InviteCodes.normalize(code))?.takeUnless { it.deleted } ?: throw ApiException.notFound("Invite")

    fun preview(code: String): InvitePreviewDto {
        val group = invited(code)
        val active = members.listByGroup(group.id).filter { !it.removed }
        return InvitePreviewDto(group.id, group.name, group.kind, active.size, active.map { InviteMemberDto(it.id, it.name, it.userId != null) })
    }

    /**
     * A friend group (Phase 6) skips the group cap; a new member there is 409 LIMIT_EXCEEDED (validator), and claiming
     * its placeholder records the pair in `friendships` unless the two already have a canonical friend group.
     */
    fun join(code: String, userId: UUID, req: JoinRequest): GroupDto {
        val group = invited(code)
        if (members.findByGroupAndUser(group.id, userId) == null) {
            if (group.kind == "group") requireGroupQuota(userId)
            events.pushValidated(group.id, userId, listOf(joinEvent(group, userId, req)))
        }
        if (group.kind == "friend") {
            members.listByGroup(group.id).mapNotNull { it.userId }.distinct().takeIf { it.size == 2 }?.let { (a, b) -> friends.insertPair(a, b, group.id) }
        }
        return get(group.id, userId)
    }

    private fun joinEvent(group: Group, userId: UUID, req: JoinRequest): IncomingEvent =
        when {
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

    private fun requireGroupQuota(userId: UUID) {
        if (members.countGroupsOfUser(userId) >= MAX_GROUPS_PER_USER) throw ApiException.limit("A user can be in at most $MAX_GROUPS_PER_USER groups")
    }

    private fun event(type: String, payload: Map<String, Any?>) =
        IncomingEvent(UUID.randomUUID(), type, mapper.valueToTree(payload), Instant.now())

    companion object {
        const val MAX_GROUPS_PER_USER = 100
    }
}
