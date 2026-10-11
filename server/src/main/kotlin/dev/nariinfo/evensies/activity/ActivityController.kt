package dev.nariinfo.evensies.activity

import dev.nariinfo.evensies.activity.Activity.item
import dev.nariinfo.evensies.activity.Activity.withoutDeletedComments
import dev.nariinfo.evensies.config.userId
import dev.nariinfo.evensies.group.GroupService
import dev.nariinfo.evensies.sync.EventRepository
import dev.nariinfo.evensies.sync.GroupStateStore
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import java.util.UUID

/**
 * Feeds read [EventMeta] rows newest first and drop hidden events, so a page can hold fewer than `limit` items
 * (even none); only `nextBefore: null` means the end.
 */
@RestController
class ActivityController(private val groups: GroupService, private val events: EventRepository, private val stateStore: GroupStateStore) {
    @GetMapping("/groups/{id}/activity")
    fun group(
        auth: Authentication,
        @PathVariable id: UUID,
        @RequestParam before: Long?,
        @RequestParam(defaultValue = "50") limit: Int,
        @RequestParam expenseId: UUID?, // edit history of one expense; an expense not in this group gives an empty page
    ): ActivityPage {
        val (_, me) = groups.requireMember(id, auth.userId)
        val n = limit.coerceIn(1, MAX_LIMIT)
        val rows = events.findBefore(id, before ?: Long.MAX_VALUE, n, expenseId?.toString())
        val items = rows.mapNotNull { it.item(me.id.toString()) }.withoutDeletedComments(stateStore::deletedComments)
        return ActivityPage(items, rows.lastOrNull()?.seq?.takeIf { rows.size == n })
    }

    @GetMapping("/activity")
    fun all(auth: Authentication, @RequestParam before: Long?, @RequestParam(defaultValue = "50") limit: Int): ActivityPage {
        val n = limit.coerceIn(1, MAX_LIMIT)
        val rows = events.findBeforeForUser(auth.userId, before ?: Long.MAX_VALUE, n)
        val items = rows.mapNotNull { (e, me) -> e.item(me) }.withoutDeletedComments(stateStore::deletedComments)
        return ActivityPage(items, rows.lastOrNull()?.first?.feedId?.takeIf { rows.size == n })
    }

    companion object {
        const val MAX_LIMIT = 100
    }
}
