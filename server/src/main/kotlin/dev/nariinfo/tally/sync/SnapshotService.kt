package dev.nariinfo.tally.sync

import dev.nariinfo.tally.group.GroupService
import org.springframework.stereotype.Service
import java.util.UUID

@Service
class SnapshotService(private val groupService: GroupService, private val stateStore: GroupStateStore) {
    fun snapshot(groupId: UUID, userId: UUID): SnapshotDto {
        val (group, member) = groupService.requireMember(groupId, userId)
        val state = stateStore.load(groupId)
        return SnapshotDto(
            group = group.toDto(member.id),
            members = state.members.values.toList(),
            expenses = state.expenses.values.toList(),
            payments = state.payments.values.toList(),
            latestSeq = group.latestSeq,
        )
    }
}
