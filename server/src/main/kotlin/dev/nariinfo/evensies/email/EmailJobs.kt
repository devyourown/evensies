package dev.nariinfo.evensies.email

import dev.nariinfo.evensies.activity.Activity.item
import dev.nariinfo.evensies.activity.Activity.memberOfUser
import dev.nariinfo.evensies.activity.Activity.withoutDeletedComments
import dev.nariinfo.evensies.auth.DeviceRepository
import dev.nariinfo.evensies.auth.User
import dev.nariinfo.evensies.auth.UserRepository
import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.config.AppProperties
import dev.nariinfo.evensies.group.GroupRepository
import dev.nariinfo.evensies.push.NotificationPrefs
import dev.nariinfo.evensies.push.NotificationPrefsRepository
import dev.nariinfo.evensies.push.PushSender
import dev.nariinfo.evensies.recurrence.Schedule
import dev.nariinfo.evensies.sync.EventApplier
import dev.nariinfo.evensies.sync.EventRepository
import dev.nariinfo.evensies.sync.GroupStateStore
import org.slf4j.LoggerFactory
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.http.HttpStatus
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Component
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.ResponseStatus
import org.springframework.web.bind.annotation.RestController
import tools.jackson.databind.ObjectMapper
import java.time.Clock
import java.time.Duration
import java.time.Instant
import java.time.LocalDate
import java.time.OffsetDateTime
import java.time.YearMonth
import java.time.ZoneOffset
import java.util.UUID

/** What an `emailDigest` choice means for a user now (docs/API.md "Summary emails"); also `emailDigestEffective`. */
@Component
class DigestMode(private val mailer: Mailer, private val devices: DeviceRepository, private val push: PushSender, private val clock: Clock) {
    /** "off" without an address, with email off on the server or a suppressed address; "auto" is daily without push, else monthly. */
    fun effective(user: User, prefs: NotificationPrefs): String {
        val email = user.email ?: return "off"
        if (!mailer.enabled || prefs.emailDigest == "off" || mailer.isSuppressed(email)) return "off"
        if (prefs.emailDigest != "auto") return prefs.emailDigest
        return if (canPush(user.id, prefs)) "monthly" else "daily"
    }

    /** A push-capable device (an FCM token, notifications allowed, seen within 60 days), FCM configured, a push switch on. */
    fun canPush(userId: UUID, prefs: NotificationPrefs) =
        push.enabled && !prefs.pushOff() && devices.hasPushCapable(userId, clock.instant().minus(Duration.ofDays(60)).atOffset(ZoneOffset.UTC))
}

/**
 * The hourly email work (docs/API.md "Hourly job"), in this order: purge, invite reminders, recurring-bill reminders,
 * digests. A step's failure is logged and the next step still runs. Does nothing while email is off.
 * ponytail: loads every digest candidate hourly on one instance; page by due time and take `pg_try_advisory_lock`
 * past 10k users or more than one instance.
 */
@Component
class EmailJobs(
    private val mailer: Mailer,
    private val tokens: EmailTokens,
    private val digestMode: DigestMode,
    private val invites: InviteEmails,
    private val prefs: NotificationPrefsRepository,
    private val events: EventRepository,
    private val groups: GroupRepository,
    private val users: UserRepository,
    private val stateStore: GroupStateStore,
    private val jdbc: JdbcClient,
    private val mapper: ObjectMapper,
    private val clock: Clock,
    private val props: AppProperties,
) {
    private val log = LoggerFactory.getLogger(javaClass)

    @Scheduled(cron = "\${evensies.email.job-cron:0 5 * * * *}")
    fun hourly() = run(clock.instant())

    /** [force] (POST /dev/jobs/email): ignore due times — digests, the 3-day invite wait and the reminder lead time. */
    fun run(now: Instant, force: Boolean = false) {
        if (!mailer.enabled) return
        step("purge") { purge(now) }
        step("invite reminders") { inviteReminders(now, force) }
        step("recurring reminders") { recurringReminders(now, force) }
        step("digests") { digests(now, force) }
    }

    private fun step(name: String, block: () -> Unit) {
        try {
            block()
        } catch (e: Exception) {
            log.warn("Email job step {} failed: {}", name, e.toString())
        }
    }

    private fun at(t: Instant) = t.atOffset(ZoneOffset.UTC)

    /** Expired codes; invite addresses after 14 days; the send log after 30. */
    fun purge(now: Instant) {
        jdbc.sql("DELETE FROM email_codes WHERE expires_at < :t").param("t", at(now)).update()
        jdbc.sql("DELETE FROM email_invites WHERE sent_at < :t").param("t", at(now - INVITE_KEPT)).update()
        jdbc.sql("DELETE FROM email_log WHERE sent_at < :t").param("t", at(now - LOG_KEPT)).update()
    }

    /** One reminder per invite after 3 days, while the placeholder is unclaimed and the group not deleted. */
    fun inviteReminders(now: Instant, force: Boolean) {
        class Due(val memberId: UUID, val groupId: UUID, val email: String, val invitedBy: UUID, val name: String)
        val due = jdbc.sql(
            """
            SELECT i.member_id, i.group_id, i.email, i.invited_by, m.name FROM email_invites i
            JOIN members m ON m.id = i.member_id AND m.user_id IS NULL AND NOT m.removed
            JOIN groups g ON g.id = i.group_id AND g.deleted_at IS NULL
            WHERE i.reminded_at IS NULL AND (:force OR i.sent_at < :cutoff) ORDER BY i.sent_at
            """
        ).param("force", force).param("cutoff", at(now - INVITE_REMINDER_AFTER)).query { rs, _ ->
            Due(rs.getObject("member_id", UUID::class.java), rs.getObject("group_id", UUID::class.java), rs.getString("email"),
                rs.getObject("invited_by", UUID::class.java), rs.getString("name"))
        }.list()
        for (d in due) {
            val group = groups.find(d.groupId) ?: continue
            val inviter = users.find(d.invitedBy)?.takeUnless { it.deleted } ?: continue
            val result = sendOrNull("invite_reminder") {
                mailer.send("invite_reminder", d.email, inviter.id, invites.message(group, d.memberId, d.name, inviter.displayName, inviter.language, d.email, reminder = true))
            } ?: continue
            if (result == Mailer.Result.OVER_BUDGET) return
            jdbc.sql("UPDATE email_invites SET reminded_at = :t WHERE member_id = :m").param("t", at(now)).param("m", d.memberId).update()
        }
    }

    /**
     * Before a repeat posts: every linked, active member on the template (payers or shares) with an address, not
     * suppressed, with summaries not off, who hasn't blocked the series' creator; once per occurrence. A failed send or
     * the budget stop leaves the occurrence open, so the next run retries only the members who didn't get it yet.
     */
    fun recurringReminders(now: Instant, force: Boolean) {
        class Due(val id: UUID, val groupId: UUID, val frequency: String, val start: LocalDate, val template: String, val createdBy: UUID?, val n: Int)
        val due = jdbc.sql(
            """
            SELECT r.id, r.group_id, r.frequency, r.start_date, r.template, r.created_by, r.next_occurrence FROM recurrences r
            JOIN groups g ON g.id = r.group_id AND g.deleted_at IS NULL
            WHERE r.deleted_at IS NULL AND r.remind_days_before IS NOT NULL AND r.reminded_occurrence < r.next_occurrence
              AND (:force OR (r.next_due_at - r.remind_days_before * interval '1 day' <= :now AND r.next_due_at > :now))
            ORDER BY r.next_due_at
            """
        ).param("force", force).param("now", at(now)).query { rs, _ ->
            Due(rs.getObject("id", UUID::class.java), rs.getObject("group_id", UUID::class.java), rs.getString("frequency"),
                rs.getObject("start_date", LocalDate::class.java), rs.getString("template"), rs.getObject("created_by", UUID::class.java), rs.getInt("next_occurrence"))
        }.list()
        for (r in due) {
            if (!mailer.withinBudget("recurring_reminder")) return
            val state = stateStore.load(r.groupId)
            val x = EventApplier.expense(r.id.toString(), mapper.readTree(r.template))
            val creator = r.createdBy?.let(users::find)
            val date = Schedule.occurrenceDate(r.frequency, r.start, r.n)
            val involved = (x.payers.map { it.memberId } + x.shares.map { it.memberId }).toSet()
            val ref = "${r.id}:${r.n}"
            var done = true
            for (m in state.members.values.filter { it.id in involved && !it.removed && it.userId != null }) {
                val user = users.find(UUID.fromString(m.userId))?.takeUnless { it.deleted } ?: continue
                val email = user.email ?: continue
                if (prefs.get(user.id).emailDigest == "off" || (r.createdBy != null && isBlocked(user.id, r.createdBy))) continue
                if (mailer.sent("recurring_reminder", user.id, ref)) continue
                val unsubscribe = unsubscribeUrl(user.id)
                val result = sendOrNull("recurring_reminder") {
                    mailer.send(
                        "recurring_reminder", email, user.id,
                        EmailTemplates.recurringReminder(
                            user.language ?: "en", user.displayName, x.description, x.amount, x.shares.firstOrNull { it.memberId == m.id }?.amount ?: 0,
                            x.currency, date, DigestBuilder.groupName(state, m.id), r.frequency, creator?.takeUnless { it.deleted }?.displayName.orEmpty(), unsubscribe,
                            byRecipient = user.id == r.createdBy,
                        ),
                        ref = ref,
                    )
                }
                if (result == Mailer.Result.OVER_BUDGET) return
                if (result == null) done = false
            }
            if (!done) continue
            jdbc.sql("UPDATE recurrences SET reminded_occurrence = :n WHERE id = :id AND reminded_occurrence < :n").param("n", r.n).param("id", r.id).update()
        }
    }

    private fun isBlocked(blocker: UUID, blocked: UUID) =
        jdbc.sql("SELECT EXISTS (SELECT 1 FROM user_blocks WHERE blocker = :a AND blocked = :b)").param("a", blocker).param("b", blocked).query(Boolean::class.java).single()

    /** Candidates: active users with an address, not suppressed, summaries not off. */
    fun digests(now: Instant, force: Boolean) {
        val candidates = jdbc.sql(
            """
            SELECT u.id, p.user_id IS NOT NULL AND p.last_digest_at IS NOT NULL AS clocked FROM users u LEFT JOIN notification_prefs p ON p.user_id = u.id
            WHERE u.deleted_at IS NULL AND u.email IS NOT NULL AND COALESCE(p.email_digest, 'auto') <> 'off'
              AND NOT EXISTS (SELECT 1 FROM email_suppressions s WHERE s.email_hash = encode(sha256(convert_to(u.email, 'UTF8')), 'hex'))
            ORDER BY u.id
            """
        ).query { rs, _ -> rs.getObject("id", UUID::class.java) to rs.getBoolean("clocked") }.list()
        val upTo = events.maxFeedId()
        for ((userId, clocked) in candidates) {
            if (!clocked) {
                prefs.resetDigestClock(userId, now) // starts the clock without sending
                continue
            }
            if (!mailer.withinBudget("digest")) return
            if (digest(userId, now, upTo, force) == Mailer.Result.OVER_BUDGET) return
        }
    }

    /** One user's digest; null when not due or the send failed (the window stays for the next run). */
    private fun digest(userId: UUID, now: Instant, upTo: Long, force: Boolean): Mailer.Result? {
        val user = users.find(userId)?.takeUnless { it.deleted } ?: return null
        val email = user.email ?: return null
        val p = prefs.get(userId)
        val (lastAt, lastFeed) = jdbc.sql("SELECT last_digest_at, last_digest_feed_id FROM notification_prefs WHERE user_id = :u").param("u", userId)
            .query { rs, _ -> rs.getObject("last_digest_at", OffsetDateTime::class.java).toInstant() to rs.getLong("last_digest_feed_id") }.single()
        val mode = digestMode.effective(user, p).takeUnless { it == "off" } ?: return null
        if (!force && now < DigestBuilder.nextDue(lastAt, mode)) return null
        val window = events.digestWindow(userId, lastFeed, upTo, MAX_WINDOW)
        val windowEnd = if (window.size == MAX_WINDOW) window.last().first.feedId else upTo
        val byGroup = window.groupBy { it.first.groupId }
        // ponytail: loads every group of the user (balances); cache states per run if digests get slow.
        val digestGroups = groups.listForUser(userId).mapNotNull { g ->
            val state = stateStore.load(g.id)
            val me = state.memberOfUser(userId.toString()) ?: return@mapNotNull null
            val items = byGroup[g.id].orEmpty().mapNotNull { (e, member) -> e.item(member) }.withoutDeletedComments(stateStore::deletedComments)
                .sortedByDescending { it.feedId }
            DigestBuilder.group(state, items, me)
        }.sortedWith(compareByDescending<DigestGroup> { it.items.firstOrNull()?.feedId ?: 0L }.thenBy { it.name })
        val message = DigestBuilder.build(
            user.displayName, user.language ?: "en", mode, auto = p.emailDigest == "auto", digestGroups, unsubscribeUrl(userId), YearMonth.from(at(now - Duration.ofDays(1))),
        )
        if (message == null) {
            prefs.advanceDigest(userId, now, windowEnd)
            return null
        }
        val result = sendOrNull("digest") { mailer.send("digest", email, userId, message) } ?: return null
        if (result != Mailer.Result.OVER_BUDGET) prefs.advanceDigest(userId, now, windowEnd)
        return result
    }

    private fun unsubscribeUrl(userId: UUID) = props.publicUrl.trimEnd('/') + "/email/unsubscribe?t=" + tokens.unsubscribe(EmailTokens.DIGEST, userId.toString())

    /** A failed send is logged and skipped (null); rejected addresses are suppressed by the mailer. */
    private fun sendOrNull(kind: String, send: () -> Mailer.Result): Mailer.Result? = try {
        send()
    } catch (e: ApiException) {
        log.warn("{} not sent: {}", kind, e.code)
        null
    }

    companion object {
        val INVITE_REMINDER_AFTER: Duration = Duration.ofDays(3)
        val INVITE_KEPT: Duration = Duration.ofDays(14)
        val LOG_KEPT: Duration = Duration.ofDays(30)
        const val MAX_WINDOW = 500
    }
}

/** Development only: runs the hourly job now, ignoring due times. Doesn't exist unless evensies.auth.dev-login=true. */
@RestController
@ConditionalOnProperty("evensies.auth.dev-login", havingValue = "true")
class DevEmailJobController(private val jobs: EmailJobs, private val clock: Clock) {
    @PostMapping("/dev/jobs/email")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    fun run() = jobs.run(clock.instant(), force = true)
}
