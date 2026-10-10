package dev.nariinfo.evensies.auth

import dev.nariinfo.evensies.common.ApiException
import dev.nariinfo.evensies.config.JwtService
import dev.nariinfo.evensies.group.MemberRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
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
    private val jwt: JwtService,
) {
    private val random = SecureRandom()

    fun login(provider: String, subject: String, displayName: String): AuthResponse {
        val user = users.findOrCreate(provider, subject, displayName)
        val tokens = issue(user.id)
        return AuthResponse(tokens.accessToken, tokens.refreshToken, UserDto(user.id, user.displayName))
    }

    @Transactional
    fun refresh(refreshToken: String): TokenPair {
        val userId = refreshTokens.consume(refreshToken) ?: throw ApiException.unauthorized("Invalid or expired refresh token")
        val user = users.find(userId)
        if (user == null || user.deleted) throw ApiException.unauthorized("Account no longer exists")
        return issue(userId)
    }

    fun me(userId: UUID): UserDto {
        val user = users.find(userId)
        if (user == null || user.deleted) throw ApiException.unauthorized("Account no longer exists")
        return UserDto(user.id, user.displayName)
    }

    /** Soft-deletes the user; their member rows become placeholders so group history stays intact. */
    @Transactional
    fun deleteAccount(userId: UUID) {
        users.markDeleted(userId)
        members.unlinkUser(userId)
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
        val REFRESH_TTL: Duration = Duration.ofDays(30)
    }
}
