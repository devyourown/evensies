package dev.nariinfo.evensies.sync

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.common.RateLimiter
import dev.nariinfo.evensies.group.GroupRepository
import dev.nariinfo.evensies.group.MemberRepository
import dev.nariinfo.evensies.push.FcmNotifier
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
    private val fcm: FcmNotifier,
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
     * `sent` payment that needs no confirmation becomes `confirmed` in the stored payload), then notifies other devices.
     */
    fun pushValidated(groupId: UUID, userId: UUID, incoming: List<IncomingEvent>): PushResult {
        val group = groups.find(groupId) ?: throw ApiException.notFound("Group")
        if (incoming.isEmpty()) return PushResult(emptyList(), group.latestSeq)
        val normalized = validator.validateAll(stateStore.load(groupId), userId, incoming, stateStore::paymentCreator)
        val result = push(groupId, userId, normalized)
        fcm.notifyGroup(groupId, excludeUserId = userId)
        return result
    }

    /**
     * The sync core, all in one transaction: lock the group row (SELECT ... FOR UPDATE) so concurrent
     * pushes cannot overlap on seq; skip events whose clientId is already stored and return their
     * original seq (idempotent retries); assign seq = latestSeq + 1, +2, ... to the rest, store them,
     * apply them to the tables, then advance latestSeq.
     */
    fun push(groupId: UUID, userId: UUID, incoming: List<IncomingEvent>): PushResult = tx.execute<PushResult> {
        val group = groups.lockForUpdate(groupId) ?: throw ApiException.notFound("Group")
        val existing = events.findByGroupIdAndClientIdIn(groupId, incoming.map { it.clientId })
        val known = existing.associateTo(mutableMapOf()) { it.clientId to it.seq }
        var state = stateStore.load(groupId)
        var seq = group.latestSeq
        val results = incoming.map { e ->
            val seen = known[e.clientId]
            if (seen != null) {
                SeqResult(e.clientId, seen)
            } else {
                seq += 1
                events.insert(Event(groupId, seq, e.clientId, e.type, e.payload, actorUserId = userId, e.createdAt))
                state = EventApplier.apply(state, e.type, e.payload)   // state는 stateStore.load(groupId)로 시작
                stateStore.persist(groupId, userId, state, e.type, e.payload)
                known[e.clientId] = seq
                SeqResult(e.clientId, seq)
            }
        }
        if (seq != group.latestSeq) groups.updateLatestSeq(groupId, seq)
        PushResult(results = results, latestSeq = seq)
    }!!

    fun pull(groupId: UUID, after: Long, limit: Int): PullResult {
        val group = groups.find(groupId) ?: throw ApiException.notFound("Group")
        val list = events.findAfter(groupId, after, limit.coerceIn(1, MAX_PULL))
        return PullResult(list.map { it.toDto() }, group.latestSeq)
    }

    companion object {
        const val MAX_PULL = 500
    }
}
