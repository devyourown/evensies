package dev.nariinfo.tally.sync

import dev.nariinfo.tally.config.userId
import dev.nariinfo.tally.group.GroupService
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

@RestController
@RequestMapping("/groups/{id}")
class EventController(
    private val events: EventService,
    private val snapshots: SnapshotService,
    private val groups: GroupService,
) {
    @PostMapping("/events")
    fun push(auth: Authentication, @PathVariable id: UUID, @RequestBody body: List<IncomingEvent>): PushResult =
        events.pushAsMember(id, auth.userId, body)

    @GetMapping("/events")
    fun pull(
        auth: Authentication,
        @PathVariable id: UUID,
        @RequestParam(defaultValue = "0") after: Long,
        @RequestParam(defaultValue = "500") limit: Int,
    ): PullResult {
        groups.requireMember(id, auth.userId)
        return events.pull(id, after, limit)
    }

    @GetMapping("/snapshot")
    fun snapshot(auth: Authentication, @PathVariable id: UUID): SnapshotDto = snapshots.snapshot(id, auth.userId)
}
