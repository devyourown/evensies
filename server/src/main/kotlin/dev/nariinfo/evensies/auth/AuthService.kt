package dev.nariinfo.evensies.auth

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.config.JwtService
import dev.nariinfo.evensies.email.Mailer
import dev.nariinfo.evensies.friend.FriendRepository
import dev.nariinfo.evensies.group.MemberRepository
import dev.nariinfo.evensies.money.Money
import dev.nariinfo.evensies.payment.PaymentMethodRepository
import dev.nariinfo.evensies.push.NotificationPrefsRepository
import dev.nariinfo.evensies.storage.AvatarController
import dev.nariinfo.evensies.storage.FileStore
import dev.nariinfo.evensies.sync.EventRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.transaction.support.TransactionSynchronization
import org.springframework.transaction.support.TransactionSynchronizationManager
import java.security.SecureRandom
import java.time.Duration
import java.time.Instant
import java.util.Base64
import java.util.UUID

data class TokenPair(val accessToken: String, val refreshToken: String)
data class AuthResponse(val accessToken: String, val refreshToken: String, val user: UserDto)

@Service
class AuthService(
    private val users: UserRepository,
    private val refreshTokens: RefreshTokenRepository,
    private val devices: DeviceRepository,
    private val members: MemberRepository,
    private val paymentMethods: PaymentMethodRepository,
    private val notificationPrefs: NotificationPrefsRepository,
    private val friends: FriendRepository,
    private val events: EventRepository,
    private val files: FileStore,
    private val jwt: JwtService,
    private val blocks: BlockRepository,
    private val mailer: Mailer,
) {
    private val random = SecureRandom()

    /** [email]: a verified Apple/Google address, adopted when the account has none ([UserRepository.adoptEmail]). */
    fun login(provider: String, subject: String, displayName: String, email: String? = null): AuthResponse {
        val user = users.findOrCreate(provider, subject, displayName)
        return session(if (email != null && user.email == null) users.adoptEmail(user.id, email) ?: user else user)
    }

    /** New tokens for [user] (sign-in). */
    fun session(user: User): AuthResponse {
        val tokens = issue(user.id)
        return AuthResponse(tokens.accessToken, tokens.refreshToken, dto(user))
    }

    fun dto(user: User): UserDto = user.dto(emailBounced = user.email?.let(mailer::isBounced) ?: false)

    @Transactional
    fun refresh(refreshToken: String): TokenPair {
        val userId = refreshTokens.consume(refreshToken) ?: throw ApiException.unauthorized("Invalid or expired refresh token")
        val user = users.find(userId)
        if (user == null || user.deleted) throw ApiException.unauthorized("Account no longer exists")
        return issue(userId)
    }

    fun me(userId: UUID): UserDto = dto(user(userId))

    /** The active user, else 401. */
    fun user(userId: UUID): User {
        val user = users.find(userId)
        if (user == null || user.deleted) throw ApiException.unauthorized("Account no longer exists")
        return user
    }

    /**
     * PATCH /me: a null [displayName] or [homeCurrency] = leave as is; [language] is set (null clears it) only when
     * [setLanguage]. At least one is required. Everything is checked before anything is written.
     */
    fun updateMe(userId: UUID, displayName: String?, homeCurrency: String?, setLanguage: Boolean = false, language: String? = null): UserDto {
        if (displayName == null && homeCurrency == null && !setLanguage) {
            throw ApiException.badRequest("VALIDATION", "Send displayName, homeCurrency or language")
        }
        val name = displayName?.trim()
        if (name != null && (name.isEmpty() || name.codePointCount(0, name.length) > MAX_NAME)) {
            throw ApiException.badRequest("VALIDATION", "Name must be 1 to $MAX_NAME characters")
        }
        if (homeCurrency != null && !Money.isKnown(homeCurrency)) throw ApiException.badRequest("UNKNOWN_CURRENCY", "Unknown currency $homeCurrency")
        // A language strings.json lacks ("xx") is stored and rendered as English.
        if (language != null && !LANGUAGE.matches(language)) throw ApiException.badRequest("VALIDATION", "language must be 2 or 3 lowercase letters")
        me(userId) // 401 for deleted accounts
        return dto(users.update(userId, name, homeCurrency, setLanguage, language))
    }

    /**
     * Soft-deletes the user; their member rows become placeholders so group history stays intact (a friend sees a
     * placeholder friend). The friend code, pairs, reminders and unread marks go; the photo file goes after commit.
     * Phase 10: also the name, address, email settings, codes, the invites they sent and blocks in both directions.
     */
    @Transactional
    fun deleteAccount(userId: UUID) {
        users.deleteEmailData(userId)
        blocks.deleteByUser(userId)
        users.markDeleted(userId)
        members.unlinkUser(userId)
        refreshTokens.deleteByUser(userId)
        devices.deleteByUser(userId)
        paymentMethods.deleteByUser(userId)
        notificationPrefs.deleteByUser(userId)
        friends.deleteByUser(userId)
        events.deleteSeenByUser(userId)
        TransactionSynchronizationManager.registerSynchronization(object : TransactionSynchronization {
            override fun afterCommit() = files.delete(AvatarController.key(userId))
        })
    }

    /** Sign out on all devices: every refresh token and device row (pushes stop). ponytail: access tokens stay valid
     *  up to 15 minutes; add `users.tokens_valid_after` checked in JwtAuthFilter if instant revoke is needed. */
    @Transactional
    fun logoutAll(userId: UUID) {
        refreshTokens.deleteByUser(userId)
        devices.deleteByUser(userId)
    }

    private fun issue(userId: UUID): TokenPair {
        val bytes = ByteArray(32).also(random::nextBytes)
        val refresh = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes)
        refreshTokens.insert(refresh, userId, Instant.now().plus(REFRESH_TTL))
        return TokenPair(jwt.sign(userId), refresh)
    }

    companion object {
        const val MAX_NAME = 30
        private val LANGUAGE = Regex("[a-z]{2,3}") // the users.language CHECK
        val REFRESH_TTL: Duration = Duration.ofDays(30)
    }
}
