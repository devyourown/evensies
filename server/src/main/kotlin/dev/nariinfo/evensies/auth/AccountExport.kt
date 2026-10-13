package dev.nariinfo.evensies.auth

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.common.RateLimiter
import dev.nariinfo.evensies.config.userId
import dev.nariinfo.evensies.email.DigestMode
import dev.nariinfo.evensies.group.GroupRepository
import dev.nariinfo.evensies.payment.PaymentMethod
import dev.nariinfo.evensies.payment.PaymentMethodRepository
import dev.nariinfo.evensies.push.NotificationPrefs
import dev.nariinfo.evensies.push.NotificationPrefsRepository
import dev.nariinfo.evensies.sync.SnapshotDto
import dev.nariinfo.evensies.sync.SnapshotService
import org.springframework.http.ResponseEntity
import org.springframework.security.core.Authentication
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import java.util.UUID

data class ExportedUser(val id: UUID, val displayName: String, val email: String?, val homeCurrency: String?, val language: String?)

data class AccountExport(
    val exportedAt: Instant,
    val user: ExportedUser,
    val paymentMethods: List<PaymentMethod>,
    val notifications: NotificationPrefs,
    val groups: List<SnapshotDto>,
)

/**
 * "Export everything" (docs/API.md "Endpoints", `GET /me/export`): one JSON with the profile, payment methods, settings and a snapshot of
 * every group the user is an active member of, deleted ones included. Receipt images come with the per-group ZIP.
 */
@RestController
class AccountExportController(
    private val auth: AuthService,
    private val groups: GroupRepository,
    private val snapshots: SnapshotService,
    private val paymentMethods: PaymentMethodRepository,
    private val prefs: NotificationPrefsRepository,
    private val digestMode: DigestMode,
    private val clock: Clock,
) {
    /** Abuse cap: an export loads every group. */
    private val exports = RateLimiter(capacity = PER_HOUR.toDouble(), refillPerSecond = PER_HOUR / 3600.0)

    @GetMapping("/me/export")
    fun export(authentication: Authentication): ResponseEntity<AccountExport> {
        val user = auth.user(authentication.userId)
        if (!exports.tryConsume(user.id)) throw ApiException.tooManyRequests("Too many exports, try again later")
        val now = clock.instant()
        val p = prefs.get(user.id)
        val body = AccountExport(
            exportedAt = now,
            user = ExportedUser(user.id, user.displayName, user.email, user.homeCurrency, user.language),
            paymentMethods = paymentMethods.list(user.id),
            notifications = p.copy(emailDigestEffective = digestMode.effective(user, p)),
            groups = groups.listForUser(user.id).map { snapshots.snapshot(it.id, user.id) },
        )
        return ResponseEntity.ok().header("Content-Disposition", "attachment; filename=\"evensies-export-${now.atOffset(ZoneOffset.UTC).toLocalDate()}.json\"").body(body)
    }

    companion object {
        const val PER_HOUR = 3
    }
}
