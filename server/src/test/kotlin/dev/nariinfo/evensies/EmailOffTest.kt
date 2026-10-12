package dev.nariinfo.evensies

import dev.nariinfo.evensies.email.EmailJobs
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.test.context.TestPropertySource
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.time.Instant
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** A server without SMTP settings (docs/API.md "이메일"): every email feature is off and says so; nothing else changes. */
@TestPropertySource(properties = ["evensies.email.smtp-host=", "evensies.email.webhook-secret=", "evensies.support-email="])
class EmailOffTest : IntegrationTestBase() {
    @Autowired
    private lateinit var jobs: EmailJobs

    private fun assertError(status: Int, code: String, res: Http.Resp) {
        assertEquals(status, res.status, res.text)
        assertEquals(code, res.code(), res.text)
    }

    @Test
    fun everyEmailFeatureIsOff() {
        val info = http.get("/info").body
        assertEquals(false, info["emailLogin"].asBoolean())
        assertEquals(false, info["appleLogin"].asBoolean(), "no Apple ids on this server")
        assertEquals(false, info["googleLogin"].asBoolean())
        assertTrue(info["supportEmail"].isNull)
        assertTrue(info["devLogin"].asBoolean())

        assertError(400, "EMAIL_NOT_CONFIGURED", http.post("/auth/email/start", mapOf("email" to "a@example.test")))
        val token = login("Off-${UUID.randomUUID().toString().take(6)}")
        assertError(400, "EMAIL_NOT_CONFIGURED", http.post("/me/email", mapOf("email" to "a@example.test"), token))
        val group = createGroup(token)
        val cara = UUID.randomUUID().toString()
        assertEquals(200, push(token, group["id"].asString(), memberAdded("Cara", cara)).status)
        assertError(400, "EMAIL_NOT_CONFIGURED", http.post("/groups/${group["id"].asString()}/members/$cara/invite-email", mapOf("email" to "c@example.test"), token))
        assertEquals("off", http.get("/me/notifications", token).body["emailDigestEffective"].asString())

        val webhook = HttpClient.newHttpClient().send(
            HttpRequest.newBuilder(URI("http://localhost:$port/webhooks/email")).header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString("{}")).build(), HttpResponse.BodyHandlers.ofString(),
        )
        assertEquals(404, webhook.statusCode(), "an empty secret turns the webhook off")

        jobs.run(Instant.now(), force = true)
        assertEquals(204, http.post("/dev/jobs/email", null, token).status)
        assertEquals(0, mail.sent.size, "nothing is ever sent")
    }
}
