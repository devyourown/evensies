package dev.nariinfo.evensies.sync

import dev.nariinfo.evensies.activity.Activity
import dev.nariinfo.evensies.activity.Activity.memberOfUser
import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.common.RateLimiter
import dev.nariinfo.evensies.group.GroupRepository
import dev.nariinfo.evensies.group.MemberRepository
import dev.nariinfo.evensies.push.PushNotifier
import dev.nariinfo.evensies.storage.AttachmentController
import dev.nariinfo.evensies.storage.FileStore
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.PlatformTransactionManager
import org.springframework.transaction.support.TransactionSynchronization
import org.springframework.transaction.support.TransactionSynchronizationManager
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
    private val files: FileStore,
    txManager: PlatformTransactionManager,
) {
    private val log = LoggerFactory.getLogger(javaClass)
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
     * [push], then notifies other members about the newly stored events (a retry that stored nothing notifies nobody)
     * and, once committed, deletes the files of the receipts this push removed (Phase 7: an `attachment.deleted` that
     * changed the state; the row stays with `deleted_at`).
     */
    fun pushValidated(groupId: UUID, userId: UUID, incoming: List<IncomingEvent>): PushResult {
        val group = groups.find(groupId) ?: throw ApiException.notFound("Group")
        if (incoming.isEmpty()) return PushResult(emptyList(), group.latestSeq)
        val (result, stored) = push(groupId, userId, incoming)
        if (stored.isNotEmpty()) notifier.notify(groupId, userId, stored)
        val removed = stored.filter { it.type == "attachment.deleted" && it.meta?.noop == false }.mapNotNull { it.payload.text("attachmentId") }
        if (removed.isNotEmpty()) afterCommit { removed.forEach { deleteReceiptFiles(groupId, UUID.fromString(it)) } }
        return result
    }

    /** Now, or after the caller's transaction commits when the push joined one. */
    private fun afterCommit(block: () -> Unit) {
        if (!TransactionSynchronizationManager.isSynchronizationActive()) return block()
        TransactionSynchronizationManager.registerSynchronization(object : TransactionSynchronization {
            override fun afterCommit() = block()
        })
    }

    /** A failure leaves the file for the Phase 8 sweep: the push is already committed. */
    private fun deleteReceiptFiles(groupId: UUID, attachmentId: UUID) {
        for (key in AttachmentController.keys(groupId, attachmentId).toList()) {
            try {
                files.delete(key)
            } catch (e: Exception) {
                log.warn("Couldn't delete {}: {}", key, e.toString())
            }
        }
    }

    /**
     * Server-built events stored without the validator (POST /friends adds the *other* user's member, which a client
     * may never do), on the caller's transaction. Returns the newly stored events; the caller notifies after commit.
     */
    fun pushTrusted(groupId: UUID, userId: UUID, incoming: List<IncomingEvent>): List<Event> = push(groupId, userId, incoming, trusted = true).second

    /**
     * Phase 8 scheduler: validated like a member's push but by Evensies (no user: `actor_user_id` NULL, no membership
     * check or rate limit), on the caller's transaction. Returns the newly stored events; the caller notifies after commit.
     */
    fun pushAsEvensies(groupId: UUID, incoming: List<IncomingEvent>): List<Event> = push(groupId, null, incoming).second

    /**
     * The sync core, all in one transaction (joining the caller's, if any): lock the group row (SELECT ... FOR UPDATE) so concurrent
     * pushes cannot overlap on seq; validate the whole batch against the state loaded under that lock (400 on any
     * failure, nothing stored; validating before the lock would let a concurrent push slip in between); skip events
     * whose clientId is already stored and return their original seq (idempotent retries); assign seq = latestSeq + 1,
     * +2, ... to the rest, apply the normalized events (e.g. a `sent` payment that needs no confirmation becomes
     * `confirmed` in the stored payload) to the tables, store them with their feed meta, then advance latestSeq.
     * Returns the result and the newly stored events.
     */
    private fun push(groupId: UUID, userId: UUID?, incoming: List<IncomingEvent>, trusted: Boolean = false): Pair<PushResult, List<Event>> = tx.execute {
        val group = groups.lockForUpdate(groupId) ?: throw ApiException.notFound("Group")
        var state = stateStore.load(groupId)
        val normalized = if (trusted) incoming else validator.validateAll(
            state, userId, incoming, stateStore::paymentCreator, uploaded = { stateStore.uploadGroup(UUID.fromString(it)) == groupId },
        )
        val existing = events.findByGroupIdAndClientIdIn(groupId, normalized.map { it.clientId })
        val known = existing.associateTo(mutableMapOf()) { it.clientId to it.seq }
        var seq = group.latestSeq
        val stored = mutableListOf<Event>()
        val results = normalized.map { e ->
            val seen = known[e.clientId]
            if (seen != null) {
                SeqResult(e.clientId, seen)
            } else {
                seq += 1
                val before = state
                state = EventApplier.apply(state, e.type, e.payload)
                stateStore.persist(groupId, userId, state, e.type, e.payload, e.createdAt)
                val meta = Activity.meta(before, state, e.type, e.payload, userId?.toString())
                stored += Event(groupId, seq, e.clientId, e.type, e.payload, actorUserId = userId, e.createdAt, meta)
                known[e.clientId] = seq
                SeqResult(e.clientId, seq)
            }
        }
        // An actor without a member yet (seq 1 group.created) is the member the same batch adds for them.
        val actor = state.memberOfUser(userId?.toString())
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
