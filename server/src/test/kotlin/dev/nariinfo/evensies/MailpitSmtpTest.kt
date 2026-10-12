package dev.nariinfo.evensies

import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.test.web.server.LocalServerPort
import org.springframework.context.annotation.Import
import org.springframework.test.context.DynamicPropertyRegistry
import org.springframework.test.context.DynamicPropertySource
import org.testcontainers.containers.GenericContainer
import org.testcontainers.utility.DockerImageName
import tools.jackson.databind.JsonNode
import tools.jackson.databind.ObjectMapper
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * The real SMTP path (JavaMailSenderImpl, `EVENSIES_SMTP_TLS=none`) into a local Mailpit container, read back through
 * Mailpit's API: plain text in UTF-8, the headers, and a code that signs in. Other email tests use CapturingMailSender.
 */
@SpringBootTest(
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
    properties = [
        "evensies.auth.dev-login=true",
        "evensies.jwt-secret=test-only-secret-0123456789-0123456789",
        "evensies.email.smtp-tls=none",
        "evensies.email.from=Evensies <no-reply@evensies.test>",
        "evensies.email.job-cron=-",
    ],
)
@Import(TestcontainersConfiguration::class)
class MailpitSmtpTest {
    companion object {
        private val mailpit: GenericContainer<*> by lazy {
            GenericContainer<Nothing>(DockerImageName.parse("axllent/mailpit:v1.27")).apply { addExposedPorts(1025, 8025); start() }
        }

        @JvmStatic
        @DynamicPropertySource
        fun smtp(registry: DynamicPropertyRegistry) {
            registry.add("evensies.email.smtp-host") { mailpit.host }
            registry.add("evensies.email.smtp-port") { mailpit.getMappedPort(1025) }
            registry.add("evensies.fx.url") { FxStub.url }
            registry.add("evensies.storage-dir") { IntegrationTestBase.storageDir.toString() }
        }
    }

    @LocalServerPort
    private var port = 0

    @Autowired
    private lateinit var mapper: ObjectMapper

    private val http by lazy { Http(port, mapper) }

    private fun api(path: String): JsonNode {
        val res = HttpClient.newHttpClient().send(
            HttpRequest.newBuilder(URI("http://${mailpit.host}:${mailpit.getMappedPort(8025)}/api/v1/$path")).build(), HttpResponse.BodyHandlers.ofString(),
        )
        return mapper.readTree(res.body())
    }

    /** The newest message to [address], waiting briefly for delivery. */
    private fun latest(address: String): JsonNode {
        repeat(50) {
            api("messages").get("messages").values().firstOrNull { m -> m["To"].values().any { it["Address"].asString() == address } }?.let { return it }
            Thread.sleep(100)
        }
        error("no mail to $address")
    }

    @Test
    fun aCodeArrivesOverSmtpAndSignsIn() {
        val address = "mailpit-${UUID.randomUUID().toString().take(8)}@example.test"
        assertEquals(204, http.post("/auth/email/start", mapOf("email" to address)).status)
        val summary = latest(address)
        val message = api("message/${summary["ID"].asString()}")
        val code = Regex("\\d{6}").find(summary["Subject"].asString())!!.value
        assertEquals("$code is your Evensies code", message["Subject"].asString())
        assertTrue(message["Text"].asString().startsWith("Your sign-in code is $code."), message["Text"].asString())
        assertEquals("no-reply@evensies.test", message["From"]["Address"].asString())
        val headers = api("message/${summary["ID"].asString()}/headers")
        assertEquals("auto-generated", headers["Auto-Submitted"][0].asString())
        assertTrue(headers["Content-Type"][0].asString().lowercase().let { "text/plain" in it && "utf-8" in it }, headers["Content-Type"].toString())
        assertTrue(headers["List-Unsubscribe"] == null)

        val login = http.post("/auth/email/verify", mapOf("email" to address, "code" to code))
        assertEquals(200, login.status, login.text)
        assertEquals(address, login.body["user"]["email"].asString())
        assertEquals(true, http.get("/info").body["emailLogin"].asBoolean())

        // An invite carries the one-click unsubscribe headers and non-ASCII text survives.
        val token = login.body["accessToken"].asString()
        assertEquals(200, http.patch("/me", mapOf("displayName" to "Zoë"), token).status)
        val group = http.post("/groups", mapOf("id" to UUID.randomUUID().toString(), "name" to "Café 東京", "defaultCurrency" to "EUR",
            "memberId" to UUID.randomUUID().toString(), "memberName" to "Zoë"), token).body
        val cara = UUID.randomUUID().toString()
        val event = mapOf("clientId" to UUID.randomUUID().toString(), "type" to "member.added", "payload" to mapOf("memberId" to cara, "name" to "Cara", "userId" to null),
            "createdAt" to java.time.Instant.now().toString())
        assertEquals(200, http.post("/groups/${group["id"].asString()}/events", listOf(event), token).status)
        val invited = "mailpit-cara-${UUID.randomUUID().toString().take(8)}@example.test"
        assertEquals(204, http.post("/groups/${group["id"].asString()}/members/$cara/invite-email", mapOf("email" to invited), token).status)
        val invite = latest(invited)
        assertEquals("Zoë invited you to “Café 東京” on Evensies", invite["Subject"].asString())
        val inviteHeaders = api("message/${invite["ID"].asString()}/headers")
        assertTrue(inviteHeaders["List-Unsubscribe"][0].asString().startsWith("<http://localhost:8080/email/unsubscribe?t="))
        assertEquals("List-Unsubscribe=One-Click", inviteHeaders["List-Unsubscribe-Post"][0].asString())
    }
}
