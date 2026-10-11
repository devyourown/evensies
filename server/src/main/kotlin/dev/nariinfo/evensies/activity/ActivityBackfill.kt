package dev.nariinfo.evensies.activity

import dev.nariinfo.evensies.activity.Activity.memberOfUser
import dev.nariinfo.evensies.sync.EventApplier
import dev.nariinfo.evensies.sync.EventRepository
import dev.nariinfo.evensies.sync.GroupState
import org.slf4j.LoggerFactory
import org.springframework.boot.ApplicationArguments
import org.springframework.boot.ApplicationRunner
import org.springframework.stereotype.Component
import java.util.UUID

/**
 * At startup, fills `events.meta` for events stored before the activity feed existed: replays each such group's log
 * from seq 1 with the pure applier. Push batches are unknown here, so a missing actor is looked up in the state after
 * the whole log. Only rows with `meta IS NULL` are written, so concurrent pushes are unaffected.
 */
@Component
class ActivityBackfill(private val events: EventRepository) : ApplicationRunner {
    private val log = LoggerFactory.getLogger(javaClass)

    override fun run(args: ApplicationArguments) {
        val groupIds = events.groupsWithoutMeta()
        if (groupIds.isEmpty()) return
        groupIds.forEach(::backfill)
        log.info("Activity backfill: filled feed meta for {} groups", groupIds.size)
    }

    fun backfill(groupId: UUID) {
        var state = GroupState()
        val metas = events.findAfter(groupId, 0, Int.MAX_VALUE).map { e ->
            val before = state
            state = EventApplier.apply(state, e.type, e.payload)
            e to Activity.meta(before, state, e.type, e.payload, e.actorUserId?.toString())
        }
        for ((e, m) in metas) {
            if (e.meta == null) events.fillMeta(groupId, e.seq, m.copy(actorMemberId = m.actorMemberId ?: state.memberOfUser(e.actorUserId?.toString())))
        }
    }
}
