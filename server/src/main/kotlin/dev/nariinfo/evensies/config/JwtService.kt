package dev.nariinfo.evensies.config

import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import com.auth0.jwt.exceptions.JWTVerificationException
import org.springframework.stereotype.Component
import java.time.Instant
import java.util.UUID

@Component
class JwtService(props: AppProperties) {
    private val algorithm: Algorithm

    init {
        require(props.jwtSecret.length >= 32) { "EVENSIES_JWT_SECRET must be set and at least 32 characters" }
        algorithm = Algorithm.HMAC256(props.jwtSecret)
    }

    fun sign(userId: UUID, now: Instant = Instant.now()): String = JWT.create()
        .withSubject(userId.toString())
        .withIssuedAt(now)
        .withExpiresAt(now.plus(ACCESS_TTL))
        .sign(algorithm)

    /** Returns the user id, or null when the token is invalid or expired. */
    fun verify(token: String): UUID? = try {
        UUID.fromString(JWT.require(algorithm).build().verify(token).subject)
    } catch (_: JWTVerificationException) {
        null
    } catch (_: IllegalArgumentException) {
        null
    }

    companion object {
        val ACCESS_TTL: java.time.Duration = java.time.Duration.ofMinutes(15)
    }
}
