package dev.nariinfo.evensies.activity

import dev.nariinfo.evensies.activity.Activity.item
import dev.nariinfo.evensies.activity.Activity.withoutDeletedComments
import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.config.userId
import dev.nariinfo.evensies.group.GroupService
import dev.nariinfo.evensies.sync.EventRepository
import dev.nariinfo.evensies.sync.GroupStateStore
import org.springframework.security.core.Authentication
import org.springframework.stereotype.Component
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController
import tools.jackson.databind.JsonNode
import java.util.UUID

/** docs/API.md "Unread activity": groups without unread items are left out; [total] is their sum. */
data class ActivityUnread(val total: Int, val groups: Map<UUID, Int>)

/** Unread items = the overall feed's items (same `me`, same hiding rules) newer than the user's marks, not their own. */
@Component
class UnreadActivity(private val events: EventRepository, private val stateStore: GroupStateStore) {
    fun of(userId: UUID): ActivityUnread {
        val items = events.unreadCandidates(userId, MAX_SCAN).mapNotNull { (e, me) -> e.item(me) }.withoutDeletedComments(stateStore::deletedComments)
        val groups = items.groupingBy { it.groupId!! }.eachCount()
        return ActivityUnread(groups.values.sum(), groups)
    }

    companion object {
        const val MAX_SCAN = 500
    }
}

/**
 * Feeds read [EventMeta] rows newest first and drop hidden events, so a page can hold fewer than `limit` items
 * (even none); only `nextBefore: null` means the end.
 */
@RestController
class ActivityController(
    private val groups: GroupService,
    private val events: EventRepository,
    private val stateStore: GroupStateStore,
    private val unread: UnreadActivity,
) {
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

    @GetMapping("/activity/unread")
    fun unread(auth: Authentication): ActivityUnread = unread.of(auth.userId)

    /** `{feedId, groupId?}`: raises the mark in that group, or without groupId in every group the caller is in. */
    @PostMapping("/activity/seen")
    fun seen(auth: Authentication, @RequestBody body: JsonNode): ActivityUnread {
        val feedId = body.get("feedId")?.takeIf { it.isIntegralNumber && it.canConvertToLong() && it.asLong() >= 0 }?.asLong()
            ?: throw ApiException.badRequest("VALIDATION", "feedId must be an integer >= 0")
        val groupId = body.get("groupId")?.takeUnless { it.isNull }?.let {
            try {
                UUID.fromString(it.takeIf { n -> n.isString }?.asString())
            } catch (_: Exception) {
                throw ApiException.badRequest("VALIDATION", "groupId must be a UUID")
            }
        }
        groupId?.let { groups.requireMember(it, auth.userId) }
        events.markSeen(auth.userId, feedId, groupId)
        return unread.of(auth.userId)
    }

    companion object {
        const val MAX_LIMIT = 100
    }
}
