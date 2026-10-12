package dev.nariinfo.evensies.push

import dev.nariinfo.evensies.activity.Activity.item
import dev.nariinfo.evensies.activity.Activity.withoutDeletedComments
import dev.nariinfo.evensies.activity.ActivityItem
import dev.nariinfo.evensies.activity.ActivityText
import dev.nariinfo.evensies.activity.UnreadActivity
import dev.nariinfo.evensies.auth.BlockRepository
import dev.nariinfo.evensies.auth.DeviceRepository
import dev.nariinfo.evensies.auth.UserRepository
import dev.nariinfo.evensies.config.AppProperties
import dev.nariinfo.evensies.group.Group
import dev.nariinfo.evensies.group.GroupRepository
import dev.nariinfo.evensies.group.Member
import dev.nariinfo.evensies.group.MemberRepository
import dev.nariinfo.evensies.sync.Event
import dev.nariinfo.evensies.sync.GroupStateStore
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import java.time.Duration
import java.time.Instant
import java.util.UUID
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Push fan-out after a committed push (docs/API.md "푸시"): every linked, active member except the actor gets either a
 * visible notification (title = group name, or in a friend group the other member's name; body = [ActivityText.body] in
 * the recipient's `users.language`, read when the message goes out; badge = the recipient's unread total) or a data-only
 * sync message. Visible items are filtered by the recipient's
 * [NotificationPrefs] and batched per recipient and group: after a visible push, items within
 * `evensies.push.batch-seconds` are queued and sent together when the window ends. Reminders ([remind]) go out here too.
 *
 * Everything runs on one background thread, so pushes never wait for FCM and the batch state needs no locks.
 * ponytail: in-memory, single-instance state; queued items are lost on restart (by contract). Shared state (Redis or a
 * table) if the server ever runs more than one instance.
 */
@Component
class PushNotifier(
    private val sender: PushSender,
    private val groups: GroupRepository,
    private val members: MemberRepository,
    private val devices: DeviceRepository,
    private val users: UserRepository,
    private val prefs: NotificationPrefsRepository,
    private val blocks: BlockRepository,
    private val stateStore: GroupStateStore,
    private val unread: UnreadActivity,
    props: AppProperties,
) {
    private val log = LoggerFactory.getLogger(javaClass)
    private val window = Duration.ofSeconds(props.push.batchSeconds)
    private val worker = Executors.newSingleThreadScheduledExecutor { Thread(it, "push-notifier").apply { isDaemon = true } }

    /** Per (recipient user, group): when the last visible push went out and what waits for the window to end. */
    private class Slot(var lastVisible: Instant = Instant.EPOCH, val pending: MutableList<ActivityItem> = mutableListOf())
    private val slots = HashMap<Pair<UUID, UUID>, Slot>()

    /** [stored] = the events this push newly stored (with meta); a null actor (Evensies, Phase 8) notifies everyone. Never throws. */
    fun notify(groupId: UUID, actorUserId: UUID?, stored: List<Event>) {
        worker.execute { guarded(groupId) { fanOut(groupId, actorUserId, stored) } }
    }

    private fun fanOut(groupId: UUID, actorUserId: UUID?, stored: List<Event>) {
        val group = groups.find(groupId) ?: return
        val all = members.listByGroup(groupId)
        val names = all.associate { it.id.toString() to it.name }
        val byMessage = LinkedHashMap<Visible?, MutableList<String>>() // null = data-only
        for (m in all) {
            val user = m.userId ?: continue
            if (m.removed || user == actorUserId) continue
            val tokens = devices.fcmTokensOfUser(user)
            if (tokens.isEmpty()) continue
            val me = m.id.toString()
            val wanted = prefs.get(user)
            // Phase 10: a blocked actor's changes and a deleted group's (but its delete and restore) only sync, never show.
            val muted = actorUserId != null && blocks.isBlocked(user, actorUserId)
            val items = if (muted) emptyList() else stored.mapNotNull { it.item(me) }.filter { wanted.allows(it.kind) }.shown(group)
                .withoutDeletedComments(stateStore::deletedComments)
            val visible = if (items.isNotEmpty() && claimVisible(user to groupId, items)) visible(group, all, m, items, names) else null
            byMessage.getOrPut(visible) { mutableListOf() } += tokens
        }
        for ((v, tokens) in byMessage) send(tokens, v?.title, v?.body, data(group), v?.badge)
    }

    private fun List<ActivityItem>.shown(group: Group) = if (group.deleted) filter { it.kind in DELETION_KINDS } else this

    /** The badge and language differ per recipient, so tokens are grouped by the whole visible message. */
    private data class Visible(val title: String, val body: String, val badge: Int)

    private fun visible(group: Group, all: List<Member>, me: Member, items: List<ActivityItem>, names: Map<String, String>): Visible {
        val title = if (group.kind == "friend") all.firstOrNull { it.id != me.id }?.name ?: group.name else group.name
        val lang = users.find(me.userId!!)?.language ?: "en"
        return Visible(ActivityText.title(title), ActivityText.body(items, names, me.id.toString(), lang, friend = group.kind == "friend"), unread.of(me.userId).total)
    }

    /** A reminder (docs/API.md "리마인더") to every device of [toUser]; no badge, data `{type: remind, fromUserId}`. */
    fun remind(toUser: UUID, fromUser: UUID, title: String, body: String) {
        worker.execute {
            guarded(toUser) {
                val tokens = devices.fcmTokensOfUser(toUser)
                if (tokens.isNotEmpty()) send(tokens, title, body, mapOf("type" to "remind", "fromUserId" to fromUser.toString()))
            }
        }
    }

    /** True: send [items] now. False: they joined the queue, flushed when the window since the last visible push ends. */
    private fun claimVisible(key: Pair<UUID, UUID>, items: List<ActivityItem>): Boolean {
        val slot = slots.getOrPut(key) { Slot() }
        val now = Instant.now()
        val windowEnd = slot.lastVisible.plus(window)
        if (slot.pending.isEmpty() && !now.isBefore(windowEnd)) {
            slot.lastVisible = now
            return true
        }
        if (slot.pending.isEmpty()) {
            worker.schedule({ guarded(key.second) { flush(key) } }, Duration.between(now, windowEnd).toMillis(), TimeUnit.MILLISECONDS)
        }
        slot.pending += items
        return false
    }

    private fun flush(key: Pair<UUID, UUID>) {
        val (user, groupId) = key
        val slot = slots[key] ?: return
        val pending = slot.pending.toList()
        slot.pending.clear()
        slot.lastVisible = Instant.now()
        val group = groups.find(groupId) ?: return
        val items = pending.shown(group).withoutDeletedComments(stateStore::deletedComments)
        val me = members.findByGroupAndUser(groupId, user) ?: return // left the group meanwhile
        val tokens = devices.fcmTokensOfUser(user)
        if (items.isEmpty() || tokens.isEmpty()) return
        val all = members.listByGroup(groupId)
        val v = visible(group, all, me, items, all.associate { it.id.toString() to it.name })
        send(tokens, v.title, v.body, data(group), v.badge)
    }

    /** In multicasts of at most [PushSender.MAX_TOKENS]; tokens FCM reports as dead are deleted. */
    private fun send(tokens: List<String>, title: String?, body: String?, data: Map<String, String>, badge: Int? = null) {
        for (chunk in tokens.chunked(PushSender.MAX_TOKENS)) {
            val dead = sender.send(chunk, title, body, data, badge)
            if (dead.isNotEmpty()) devices.deleteTokens(dead)
        }
    }

    /** FCM data values are strings. */
    private fun data(group: Group) = mapOf("type" to "sync", "groupId" to group.id.toString(), "seq" to group.latestSeq.toString())

    companion object {
        /** What a deleted group still shows (docs/API.md "그룹 삭제"). */
        val DELETION_KINDS = setOf("group_deleted", "group_restored")
    }

    private fun guarded(id: UUID, block: () -> Unit) {
        try {
            block()
        } catch (e: Exception) {
            log.warn("Push fan-out failed for {}: {}", id, e.toString())
        }
    }
}
