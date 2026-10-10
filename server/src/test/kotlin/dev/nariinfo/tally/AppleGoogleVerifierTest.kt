package dev.nariinfo.tally

import com.auth0.jwk.Jwk
import com.auth0.jwk.JwkProvider
import com.auth0.jwt.JWT
import com.auth0.jwt.algorithms.Algorithm
import dev.nariinfo.tally.auth.IdTokenVerifier
import dev.nariinfo.tally.common.ApiException
import org.junit.jupiter.api.Test
import java.security.KeyPairGenerator
import java.security.interfaces.RSAPrivateKey
import java.security.interfaces.RSAPublicKey
import java.time.Instant
import java.util.Base64
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

class AppleGoogleVerifierTest {
    private val keys = KeyPairGenerator.getInstance("RSA").apply { initialize(2048) }.generateKeyPair()
    private val pub = keys.public as RSAPublicKey
    private val priv = keys.private as RSAPrivateKey

    /** Fake JWKS: serves our local public key under kid "k1". */
    private val jwks = JwkProvider { kid ->
        val b64 = Base64.getUrlEncoder().withoutPadding()
        Jwk.fromValues(
            mapOf(
                "kid" to kid, "kty" to "RSA", "alg" to "RS256", "use" to "sig",
                "n" to b64.encodeToString(pub.modulus.toByteArray()),
                "e" to b64.encodeToString(pub.publicExponent.toByteArray()),
            )
        )
    }
    private val verifier = IdTokenVerifier(jwks, setOf("https://accounts.google.com"), listOf("my-client"), listOf("name", "email"))

    private fun token(
        iss: String = "https://accounts.google.com", aud: String = "my-client",
        exp: Instant = Instant.now().plusSeconds(600), key: RSAPrivateKey = priv, name: String? = "Anna",
    ): String = JWT.create().withKeyId("k1").withIssuer(iss).withAudience(aud).withSubject("sub-1")
        .withExpiresAt(exp).apply { name?.let { withClaim("name", it) } }.withClaim("email", "a@x.io")
        .sign(Algorithm.RSA256(pub, key))

    @Test
    fun validTokenYieldsIdentity() {
        val id = verifier.verify(token())
        assertEquals("sub-1", id.subject)
        assertEquals("Anna", id.displayName)
        assertEquals("a@x.io", verifier.verify(token(name = null)).displayName)
    }

    @Test
    fun rejectsBadAudienceIssuerExpiryAndSignature() {
        assertEquals(401, assertFailsWith<ApiException> { verifier.verify(token(aud = "other")) }.status.value())
        assertEquals(401, assertFailsWith<ApiException> { verifier.verify(token(iss = "https://evil")) }.status.value())
        assertEquals(401, assertFailsWith<ApiException> { verifier.verify(token(exp = Instant.now().minusSeconds(60))) }.status.value())
        val otherKey = KeyPairGenerator.getInstance("RSA").apply { initialize(2048) }.generateKeyPair().private as RSAPrivateKey
        assertEquals(401, assertFailsWith<ApiException> { verifier.verify(token(key = otherKey)) }.status.value())
        assertEquals(401, assertFailsWith<ApiException> { verifier.verify("garbage") }.status.value())
    }

    @Test
    fun unconfiguredProviderIsRejected() {
        val unconfigured = IdTokenVerifier(jwks, setOf("https://appleid.apple.com"), emptyList(), listOf("email"))
        assertEquals("AUTH_NOT_CONFIGURED", assertFailsWith<ApiException> { unconfigured.verify(token()) }.code)
    }
}
