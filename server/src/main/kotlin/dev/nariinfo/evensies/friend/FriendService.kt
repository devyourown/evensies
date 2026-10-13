package dev.nariinfo.evensies.friend

import dev.nariinfo.evensies.activity.ActivityText
import dev.nariinfo.evensies.auth.AuthService
import dev.nariinfo.evensies.auth.BlockRepository
import dev.nariinfo.evensies.auth.User
import dev.nariinfo.evensies.auth.UserRepository
import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.common.RateLimiter
import dev.nariinfo.evensies.config.AppProperties
import dev.nariinfo.evensies.group.Group
import dev.nariinfo.evensies.group.GroupDto
import dev.nariinfo.evensies.group.GroupRepository
import dev.nariinfo.evensies.group.GroupService
import dev.nariinfo.evensies.group.InviteCodes
import dev.nariinfo.evensies.group.MemberRepository
import dev.nariinfo.evensies.money.GroupLedger
import dev.nariinfo.evensies.money.Money
import dev.nariinfo.evensies.money.Overview
import dev.nariinfo.evensies.push.NotificationPrefsRepository
import dev.nariinfo.evensies.push.PushNotifier
import dev.nariinfo.evensies.sync.Event
import dev.nariinfo.evensies.sync.EventService
import dev.nariinfo.evensies.sync.GroupStateStore
import dev.nariinfo.evensies.sync.IncomingEvent
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.transaction.PlatformTransactionManager
import org.springframework.transaction.support.TransactionTemplate
import tools.jackson.databind.JsonNode
import tools.jackson.databind.ObjectMapper
import java.time.Instant
import java.util.UUID

data class FriendCodeDto(val friendCode: String, val link: String)
data class FriendPreviewDto(val displayName: String)
data class AmountDto(val currency: String, val amount: Long)
data class RemindResult(val amounts: List<AmountDto>)

/** Friends are hidden two-person groups (docs/API.md "Friends"); this builds them and sends reminders ("Reminders"). */
@Service
class FriendService(
    private val users: UserRepository,
    private val auth: AuthService,
    private val groups: GroupRepository,
    private val groupService: GroupService,
    private val members: MemberRepository,
    private val friends: FriendRepository,
    private val events: EventService,
    private val stateStore: GroupStateStore,
    private val notifier: PushNotifier,
    private val prefs: NotificationPrefsRepository,
    private val rateLimiter: RateLimiter,
    private val props: AppProperties,
    private val mapper: ObjectMapper,
    private val blocks: BlockRepository,
    txManager: PlatformTransactionManager,
) {
    private val tx = TransactionTemplate(txManager)

    /** The caller's code, made on the first call ([rotate]: always a new one; the old code is gone at once). */
    fun friendCode(me: UUID, rotate: Boolean): FriendCodeDto {
        auth.me(me) // 401 for deleted accounts
        if (rotate || users.friendCode(me) == null) users.setFriendCode(me, groups.newCode(), onlyIfNone = !rotate)
        val code = users.friendCode(me)!!
        return FriendCodeDto(code, props.publicUrl.trimEnd('/') + "/f/" + code)
    }

    fun preview(code: String): FriendPreviewDto =
        FriendPreviewDto(users.findByFriendCode(InviteCodes.normalize(code))?.displayName ?: throw ApiException.notFound("Friend code"))

    /**
     * POST /friends: `{id, defaultCurrency}` and exactly one of `code` (friend code; [throttleCode] is the per-IP code
     * lookup bucket), `userId` (someone in a group with me now) or `name` (a placeholder friend). Every call takes 3
     * events from the caller's push bucket.
     */
    fun add(me: UUID, body: JsonNode, throttleCode: () -> Unit): GroupDto {
        if (!rateLimiter.tryConsume(me, 3)) throw ApiException.tooManyRequests("Too many requests, try again later")
        fun text(k: String): String? = body.get(k)?.takeUnless { it.isNull }?.let { if (it.isString) it.asString() else bad("$k must be a string") }
        val id = text("id")?.let(::uuid) ?: bad("id is required")
        if (groups.find(id) != null) return groupService.get(id, me) // a retry (403 if it is someone else's group)
        val code = text("code")
        val userId = text("userId")
        val name = text("name")?.trim()
        if (listOfNotNull(code, userId, name).size != 1) bad("Send exactly one of code, userId and name")
        if (name != null && (name.isEmpty() || name.codePointCount(0, name.length) > AuthService.MAX_NAME)) {
            bad("name must be 1 to ${AuthService.MAX_NAME} characters")
        }
        val currency = text("defaultCurrency") ?: bad("defaultCurrency is required")
        if (!Money.isKnown(currency)) throw ApiException.badRequest("UNKNOWN_CURRENCY", "Unknown currency $currency")
        val myName = auth.me(me).displayName.ifBlank { "Friend" }
        if (name != null) {
            // ponytail: count then insert, no lock; parallel calls can pass the cap by a few (the event bucket bounds them).
            if (members.countPlaceholderFriends(me) >= MAX_PLACEHOLDER_FRIENDS) {
                throw ApiException.limit("At most $MAX_PLACEHOLDER_FRIENDS friends who aren't on Evensies yet")
            }
            return tx.execute { create(id, me, myName, null, name, currency); groupService.get(id, me) }!!
        }

        val other: User = if (code != null) {
            throttleCode()
            users.findByFriendCode(InviteCodes.normalize(code)) ?: throw ApiException.notFound("Friend code")
        } else {
            val them = uuid(userId!!)
            if (them == me) selfFriend()
            users.find(them)?.takeIf { !it.deleted && members.sharedGroups(me, them, activeOnly = true).isNotEmpty() }
                ?: throw notShared() // unknown and deleted look the same
        }
        if (other.id == me) selfFriend()
        // Phase 10: someone who blocked me looks unknown.
        if (blocks.isBlocked(other.id, me)) throw if (code != null) ApiException.notFound("Friend code") else notShared()
        val (dto, stored) = tx.execute {
            // An account deleted since the lookup above is gone: its cleanup already ran, so nothing may link it now.
            if (friends.lockUsers(me, other.id) < 2) throw if (code != null) ApiException.notFound("Friend code") else notShared()
            friends.findGroup(me, other.id)?.let { existing ->
                // Phase 10 "delete friend" deleted the pair's group: adding them again restores it, history and all.
                val restored = if (groups.find(existing)?.deleted == true) events.pushTrusted(existing, me, listOf(event("group.restored", emptyMap()))) else emptyList()
                return@execute groupService.get(existing, me) to restored
            }
            val stored = create(id, me, myName, other.id, other.displayName.ifBlank { "Friend" }, currency)
            friends.insertPair(me, other.id, id)
            groupService.get(id, me) to stored
        }!!
        // After commit: the push worker reads the new group and members on another connection.
        if (stored.isNotEmpty()) notifier.notify(stored.first().groupId, me, stored)
        return dto
    }

    /** The group row and the three server-made events (seq 1–3), stored without the validator; the caller's transaction. */
    private fun create(id: UUID, me: UUID, myName: String, otherUser: UUID?, otherName: String, currency: String): List<Event> {
        groups.insert(Group(id, "$myName & $otherName", currency, groups.newCode(), me, Instant.now(), 0, kind = "friend"))
        return events.pushTrusted(
            id, me, listOf(
                event("group.created", mapOf("name" to "$myName & $otherName", "defaultCurrency" to currency, "kind" to "friend")),
                event("member.added", mapOf("memberId" to UUID.randomUUID(), "name" to myName, "userId" to me)),
                event("member.added", mapOf("memberId" to UUID.randomUUID(), "name" to otherName, "userId" to otherUser)),
            )
        )
    }

    /**
     * What [them] owes me per currency across every shared group (docs/API.md "Overview"), then one reminder push per pair
     * per 24 hours. Nothing owed is 409 and doesn't use the day's slot.
     */
    fun remind(me: UUID, them: UUID): RemindResult {
        val sender = auth.me(me)
        val shared = if (me == them) emptyList() else members.sharedGroups(me, them)
        if (shared.isEmpty()) throw notShared()
        // A deleted group (Phase 10, e.g. a deleted friend) doesn't count until it is restored.
        val ledgers = shared.map(stateStore::load).zip(shared).filterNot { it.first.deleted }.mapNotNull { (state, g) -> GroupLedger.of(g.toString(), state, me.toString()) }
        val owed = Overview.compute(ledgers, me.toString()).people[them.toString()].orEmpty().filterValues { it > 0 }.toSortedMap()
        if (owed.isEmpty()) throw ApiException(HttpStatus.CONFLICT, "NOTHING_OWED", "They don't owe you anything")
        if (!friends.takeReminderSlot(me, them)) {
            throw ApiException(HttpStatus.TOO_MANY_REQUESTS, "RATE_LIMITED", "One reminder a day", friends.secondsUntilNextReminder(me, them))
        }
        // Phase 10: a reminder from someone they blocked is accepted but never shown.
        if (prefs.get(them).reminders && !blocks.isBlocked(them, me)) {
            val (title, body) = ActivityText.reminder(sender.displayName, owed.toList(), users.find(them)?.language ?: "en")
            notifier.remind(them, me, title, body)
        }
        return RemindResult(owed.map { (c, v) -> AmountDto(c, v) })
    }

    private fun event(type: String, payload: Map<String, Any?>) =
        IncomingEvent(UUID.randomUUID(), type, mapper.valueToTree(payload), Instant.now())

    private fun uuid(s: String): UUID = try { UUID.fromString(s) } catch (_: IllegalArgumentException) { bad("Not a UUID: $s") }

    private fun notShared() = ApiException.forbidden("You don't share a group with this person")

    private fun selfFriend(): Nothing = throw ApiException.badRequest("SELF_FRIEND", "You can't add yourself as a friend")

    private fun bad(message: String): Nothing = throw ApiException.badRequest("VALIDATION", message)

    companion object {
        const val MAX_PLACEHOLDER_FRIENDS = 200
    }
}
