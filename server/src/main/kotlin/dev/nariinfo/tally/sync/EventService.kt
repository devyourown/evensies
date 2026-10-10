package dev.nariinfo.tally.sync

import dev.nariinfo.tally.common.ApiException
import dev.nariinfo.tally.common.RateLimiter
import dev.nariinfo.tally.config.AppProperties
import dev.nariinfo.tally.group.GroupRepository
import dev.nariinfo.tally.group.MemberRepository
import dev.nariinfo.tally.push.FcmNotifier
import org.slf4j.LoggerFactory
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
    private val props: AppProperties,
    txManager: PlatformTransactionManager,
) {
    private val log = LoggerFactory.getLogger(javaClass)
    private val tx = TransactionTemplate(txManager)

    init {
        if (props.sync.naive) log.warn("tally.sync.naive=true: push uses EventService.pushNaive (no lock, no dedupe). Dev only.")
    }

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

    /** Validates the whole batch (400 on any failure, nothing stored), stores it, then notifies other devices. */
    fun pushValidated(groupId: UUID, userId: UUID, incoming: List<IncomingEvent>): PushResult {
        val group = groups.find(groupId) ?: throw ApiException.notFound("Group")
        if (incoming.isEmpty()) return PushResult(emptyList(), group.latestSeq)
        validator.validateAll(stateStore.load(groupId), userId, incoming)
        val result = if (props.sync.naive) pushNaive(groupId, userId, incoming) else push(groupId, userId, incoming)
        fcm.notifyGroup(groupId, excludeUserId = userId)
        return result
    }

    /**
     * TODO(효준): push 트랜잭션의 핵심 (설계 §6.3, docs/API.md "push"). 아래 단계 순서대로 구현한다.
     * 전부 `tx.execute { }` 안(한 트랜잭션)에서 일어난다. 호출 전에 검증은 끝났고, 호출 후에 FCM을 보낸다.
     *
     *  1. 그룹 행 잠금: `groups.lockForUpdate(groupId)` (SELECT ... FOR UPDATE). 같은 그룹에 동시에 push하는
     *     두 요청이 seq를 겹치게 받지 못하게 하는 유일한 장치다. null이면 ApiException.notFound("Group").
     *  2. 중복 제거: `events.findByGroupIdAndClientIdIn(groupId, incoming.map { it.clientId })`로
     *     이미 저장된 clientId → seq 맵을 만든다. 중복인 이벤트는 저장·적용하지 않고 기존 seq를 그대로 돌려준다(오류 아님).
     *     한 요청 안에 같은 clientId가 두 번 있으면 두 번째도 첫 번째의 seq를 받는다.
     *  3. seq 부여: 새 이벤트마다 `seq = group.latestSeq + 1, +2, ...` (요청 배열 순서).
     *  4. 저장·적용: 새 이벤트마다
     *       events.insert(Event(groupId, seq, clientId, type, payload, actorUserId = userId, createdAt))
     *       state = EventApplier.apply(state, type, payload)   // state는 stateStore.load(groupId)로 시작
     *       stateStore.persist(groupId, userId, state, type, payload)
     *  5. `groups.updateLatestSeq(groupId, 마지막 seq)` (새 이벤트가 하나도 없으면 생략).
     *  6. PushResult(results = 요청 순서대로 SeqResult(clientId, seq), latestSeq = 갱신된 latest_seq) 반환.
     *
     * 불변식: 같은 요청을 두 번 보내도 결과가 같다(멱등). seq는 그룹 안에서 빈틈 없이 증가한다.
     * 검증: EventSyncTest (특히 `duplicatePushReturnsSameSeq`, `./gradlew test -PincludeHyojun`),
     *       그리고 application-dev.yml의 `tally.sync.naive`를 false로 바꾸고 전체 테스트.
     * 끝나면 아래 pushNaive를 지운다.
     */
    fun push(groupId: UUID, userId: UUID, incoming: List<IncomingEvent>): PushResult = tx.execute<PushResult> {
        TODO("TODO(효준)")
    }!!

    // ======================================================================================
    // !!! TEMPORARY REFERENCE IMPLEMENTATION — NOT FOR PRODUCTION !!!
    // No row lock (concurrent pushes to one group can collide on seq) and no clientId dedupe
    // (a retried push fails on the UNIQUE(group_id, client_id) constraint → 409).
    // Only used when tally.sync.naive=true (application-dev.yml). Hyojun deletes this once push() is done.
    // ======================================================================================
    fun pushNaive(groupId: UUID, userId: UUID, incoming: List<IncomingEvent>): PushResult = tx.execute<PushResult> {
        val group = groups.find(groupId) ?: throw ApiException.notFound("Group")
        var seq = group.latestSeq
        var state = stateStore.load(groupId)
        val results = incoming.map { e ->
            seq += 1
            events.insert(Event(groupId, seq, e.clientId, e.type, e.payload, userId, e.createdAt))
            state = EventApplier.apply(state, e.type, e.payload)
            stateStore.persist(groupId, userId, state, e.type, e.payload)
            SeqResult(e.clientId, seq)
        }
        groups.updateLatestSeq(groupId, seq)
        PushResult(results, seq)
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
