package dev.nariinfo.evensies.sync

import dev.nariinfo.evensies.activity.Activity
import dev.nariinfo.evensies.activity.Activity.memberOfUser
import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.common.RateLimiter
import dev.nariinfo.evensies.group.GroupRepository
import dev.nariinfo.evensies.group.MemberRepository
import dev.nariinfo.evensies.push.PushNotifier
import org.springframework.stereotype.Service
import org.springframework.transaction.PlatformTransactionManager
import org.springframework.transaction.support.TransactionTemplate
import java.util.UUID

@Service
class EventService(
    private val groups: GroupRepository,
    private val members: MemberRepository,
    private val events: EventRepository,
    private val stateStore: GroupStateStore,
    private val validator: EventValidator,
    private val rateLimiter: RateLimiter,
    private val notifier: PushNotifier,
    txManager: PlatformTransactionManager,
) {
    private val tx = TransactionTemplate(txManager)

    /** POST /groups/{id}/events: membership, rate limit, then the validated push. */
    fun pushAsMember(groupId: UUID, userId: UUID, incoming: List<IncomingEvent>): PushResult {
        groups.find(groupId) ?: throw ApiException.notFound("Group")
        members.findByGroupAndUser(groupId, userId) ?: throw ApiException.forbidden()
        if (incoming.any { it.type == "group.created" }) throw ApiException.badRequest("VALIDATION", "group.created is server-generated")
        if (!rateLimiter.tryConsume(userId, incoming.size)) {
            throw ApiException(org.springframework.http.HttpStatus.TOO_MANY_REQUESTS, "RATE_LIMITED", "Too many events, try again later")
        }
        return pushValidated(groupId, userId, incoming)
    }

    /**
     * Validates the whole batch (400 on any failure, nothing stored), stores the normalized events (e.g. a
     * `sent` payment that needs no confirmation becomes `confirmed` in the stored payload), then notifies other
     * members about the newly stored events (a retry that stored nothing notifies nobody).
     */
    fun pushValidated(groupId: UUID, userId: UUID, incoming: List<IncomingEvent>): PushResult {
        val group = groups.find(groupId) ?: throw ApiException.notFound("Group")
        if (incoming.isEmpty()) return PushResult(emptyList(), group.latestSeq)
        val normalized = validator.validateAll(stateStore.load(groupId), userId, incoming, stateStore::paymentCreator)
        val (result, stored) = push(groupId, userId, normalized)
        if (stored.isNotEmpty()) notifier.notify(groupId, userId, stored)
        return result
    }

    /**
     * The sync core, all in one transaction: lock the group row (SELECT ... FOR UPDATE) so concurrent
     * pushes cannot overlap on seq; skip events whose clientId is already stored and return their
     * original seq (idempotent retries); assign seq = latestSeq + 1, +2, ... to the rest, apply them to the
     * tables, store them with their feed meta, then advance latestSeq. Returns the result and the newly stored events.
     */
    fun push(groupId: UUID, userId: UUID, incoming: List<IncomingEvent>): Pair<PushResult, List<Event>> = tx.execute {
        val group = groups.lockForUpdate(groupId) ?: throw ApiException.notFound("Group")
        val existing = events.findByGroupIdAndClientIdIn(groupId, incoming.map { it.clientId })
        val known = existing.associateTo(mutableMapOf()) { it.clientId to it.seq }
        var state = stateStore.load(groupId)
        var seq = group.latestSeq
        val stored = mutableListOf<Event>()
        val results = incoming.map { e ->
            val seen = known[e.clientId]
            if (seen != null) {
                SeqResult(e.clientId, seen)
            } else {
                seq += 1
                val before = state
                state = EventApplier.apply(state, e.type, e.payload)   // state는 stateStore.load(groupId)로 시작
                stateStore.persist(groupId, userId, state, e.type, e.payload)
                val meta = Activity.meta(before, state, e.type, e.payload, userId.toString())
                stored += Event(groupId, seq, e.clientId, e.type, e.payload, actorUserId = userId, e.createdAt, meta)
                known[e.clientId] = seq
                SeqResult(e.clientId, seq)
            }
        }
        // An actor without a member yet (seq 1 group.created) is the member the same batch adds for them.
        val actor = state.memberOfUser(userId.toString())
        val withActor = stored.map { if (it.meta!!.actorMemberId != null) it else it.copy(meta = it.meta.copy(actorMemberId = actor)) }
        withActor.forEach(events::insert)
        // After the inserts: the comment may have been added in this same batch.
        withActor.filter { it.type == "comment.deleted" }.forEach { e -> e.payload.text("commentId")?.let { events.blankCommentText(groupId, it) } }
        if (seq != group.latestSeq) groups.updateLatestSeq(groupId, seq)
        PushResult(results = results, latestSeq = seq) to withActor
    }

    fun pull(groupId: UUID, after: Long, limit: Int): PullResult {
        val group = groups.find(groupId) ?: throw ApiException.notFound("Group")
        val list = events.findAfter(groupId, after, limit.coerceIn(1, MAX_PULL))
        return PullResult(list.map { it.toDto() }, group.latestSeq)
    }

    companion object {
        const val MAX_PULL = 500
    }
}
