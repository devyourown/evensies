package dev.nariinfo.tally.auth

import com.auth0.jwk.JwkProvider
import com.auth0.jwk.JwkProviderBuilder
import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import dev.nariinfo.tally.common.ApiException
import dev.nariinfo.tally.config.AppProperties
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import java.net.URI
import java.security.interfaces.RSAPublicKey
import java.util.concurrent.TimeUnit

data class VerifiedIdentity(val subject: String, val displayName: String)

/**
 * Verifies an OpenID Connect id token (RS256) against a JWKS: signature, issuer, audience, expiry.
 * The JwkProvider is injectable so tests can use a locally generated key pair.
 */
class IdTokenVerifier(
    private val jwks: JwkProvider,
    private val issuers: Set<String>,
    private val audiences: List<String>,
    private val nameClaims: List<String>,
) {
    fun verify(idToken: String): VerifiedIdentity {
        if (audiences.isEmpty()) throw ApiException.badRequest("AUTH_NOT_CONFIGURED", "This login provider is not configured on the server")
        val jwt = try {
            val decoded = JWT.decode(idToken)
            val key = jwks.get(decoded.keyId).publicKey as RSAPublicKey
            JWT.require(Algorithm.RSA256(key, null))
                .withAnyOfAudience(*audiences.toTypedArray())
                .build()
                .verify(decoded)
        } catch (e: ApiException) {
            throw e
        } catch (e: Exception) {
            throw ApiException.unauthorized("Invalid id token: ${e.message}")
        }
        if (jwt.issuer !in issuers) throw ApiException.unauthorized("Invalid id token issuer")
        val name = nameClaims.firstNotNullOfOrNull { jwt.getClaim(it).asString()?.takeIf(String::isNotBlank) } ?: "User"
        return VerifiedIdentity(jwt.subject, name)
    }
}

@Configuration
class IdTokenVerifierConfig {
    private fun provider(url: String): JwkProvider =
        JwkProviderBuilder(URI(url).toURL()).cached(10, 24, TimeUnit.HOURS).build()

    @Bean
    fun appleVerifier(props: AppProperties) = IdTokenVerifier(
        provider("https://appleid.apple.com/auth/keys"),
        setOf("https://appleid.apple.com"),
        listOfNotNull(props.auth.appleClientId.ifBlank { null }),
        listOf("name", "email"),
    )

    @Bean
    fun googleVerifier(props: AppProperties) = IdTokenVerifier(
        provider("https://www.googleapis.com/oauth2/v3/certs"),
        setOf("https://accounts.google.com", "accounts.google.com"),
        props.auth.googleClientIds.map(String::trim).filter(String::isNotEmpty),
        listOf("name", "email"),
    )
}
