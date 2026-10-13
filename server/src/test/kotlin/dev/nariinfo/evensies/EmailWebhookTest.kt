package dev.nariinfo.evensies

import dev.nariinfo.evensies.email.EmailAddress
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.time.Instant
import java.util.Base64
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import kotlin.test.assertEquals
import kotlin.test.assertNull

/** Resend's bounce and complaint webhook (docs/API.md "Unsubscribes and bounces"), signed the Svix way with the test secret from IntegrationTestBase. */
class EmailWebhookTest : IntegrationTestBase() {
    @Autowired
    private lateinit var jdbc: JdbcClient

    private val key = Base64.getDecoder().decode("dGVzdC13ZWJob29rLXNlY3JldC0wMTIzNDU2Nzg5")

    private fun sign(id: String, ts: Long, body: String, k: ByteArray = key) =
        "v1," + Base64.getEncoder().encodeToString(Mac.getInstance("HmacSHA256").apply { init(SecretKeySpec(k, "HmacSHA256")) }.doFinal("$id.$ts.$body".toByteArray()))

    private fun post(body: String, ts: Long = Instant.now().epochSecond, signature: String? = null, id: String = "msg_${System.nanoTime()}"): Int {
        val req = HttpRequest.newBuilder(URI("http://localhost:$port/webhooks/email")).header("Content-Type", "application/json")
            .header("svix-id", id).header("svix-timestamp", ts.toString())
            .header("svix-signature", signature ?: ("v1,bm90LXRoaXMtb25l " + sign(id, ts, body)))
            .POST(HttpRequest.BodyPublishers.ofString(body))
        return HttpClient.newHttpClient().send(req.build(), HttpResponse.BodyHandlers.ofString()).statusCode()
    }

    private fun reason(email: String): String? = jdbc.sql("SELECT reason FROM email_suppressions WHERE email_hash = :h").param("h", EmailAddress.hash(email))
        .query(String::class.java).optional().orElse(null)

    @Test
    fun aBounceAndAComplaintAreSuppressed() {
        val bounced = address("Bounced")
        assertEquals(204, post("""{"type":"email.bounced","data":{"to":["${bounced.uppercase()}"],"subject":"x"}}"""))
        assertEquals("bounce", reason(bounced))

        val (token, complained) = emailUser("Complained")
        assertEquals(204, post("""{"type":"email.complained","data":{"to":["$complained"]}}"""))
        assertEquals("complaint", reason(complained))
        assertEquals("off", http.get("/me/notifications", token).body["emailDigest"].asString(), "a complaint also turns the summaries off")
        assertEquals(true, http.get("/me", token).body["emailBounced"].asBoolean().not())

        val other = address("Delivered")
        assertEquals(204, post("""{"type":"email.delivered","data":{"to":["$other"]}}"""))
        assertNull(reason(other), "other types are ignored")
    }

    @Test
    fun aBadOrOldSignatureIs401() {
        val email = address("Forged")
        val body = """{"type":"email.bounced","data":{"to":["$email"]}}"""
        val ts = Instant.now().epochSecond
        assertEquals(401, post(body, signature = "v1,AAAA"))
        assertEquals(401, post(body, signature = sign("other-id", ts, body)))
        assertEquals(401, post(body, signature = sign("m", ts, body, "wrong-key-0123456789".toByteArray()), id = "m"))
        val old = ts - 301
        assertEquals(401, post(body, ts = old, signature = sign("m2", old, body), id = "m2"), "older than 5 minutes")
        assertNull(reason(email))
    }
}
