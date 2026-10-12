package dev.nariinfo.evensies

import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.test.web.server.LocalServerPort
import org.springframework.context.annotation.Import
import org.springframework.test.context.DynamicPropertyRegistry
import org.springframework.test.context.DynamicPropertySource
import tools.jackson.databind.JsonNode
import tools.jackson.databind.ObjectMapper
import java.time.Instant
import java.util.UUID

@SpringBootTest(
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT,
    properties = [
        "evensies.auth.dev-login=true",
        "evensies.invite-rate-per-minute=100000", // all tests share 127.0.0.1
        "evensies.jwt-secret=test-only-secret-0123456789-0123456789",
        "evensies.push.batch-seconds=1",
        // Phase 10: email on, sent to CapturingMailSender; the hourly job runs only when a test calls it.
        "evensies.email.smtp-host=capture.invalid",
        "evensies.email.job-cron=-",
        "evensies.email.auth-rate-per-minute=100000",
        // base64 of "test-webhook-secret-0123456789"; written without the optional whsec_ prefix so secret scanners
        // don't mistake this test value for a real Stripe/Svix key (the server strips the prefix when present).
        "evensies.email.webhook-secret=dGVzdC13ZWJob29rLXNlY3JldC0wMTIzNDU2Nzg5",
        "evensies.support-email=help@evensies.test",
    ],
)
@Import(TestcontainersConfiguration::class, PushCaptureConfiguration::class, MailCaptureConfiguration::class)
abstract class IntegrationTestBase {
    @LocalServerPort
    protected var port = 0

    @Autowired
    protected lateinit var mapper: ObjectMapper

    protected val http: Http by lazy { Http(port, mapper) }

    /** Phase 10: every email the server sends; the clock the email code runs on. */
    @Autowired
    protected lateinit var mail: CapturingMailSender

    @Autowired
    protected lateinit var testClock: MutableClock

    /** A fresh address no other test uses. */
    protected fun address(name: String) = "${name.lowercase()}-${UUID.randomUUID().toString().take(8)}@example.test"

    /** Signs in with an emailed code (a new account named [name]); returns (token, address). */
    protected fun emailUser(name: String, address: String = address(name)): Pair<String, String> {
        check(http.post("/auth/email/start", mapOf("email" to address)).status == 204)
        val res = http.post("/auth/email/verify", mapOf("email" to address, "code" to mail.code(address)))
        check(res.status == 200) { "email sign-in failed: ${res.status} ${res.text}" }
        val token = res.body["accessToken"].asString()
        check(http.patch("/me", mapOf("displayName" to name), token).status == 200)
        return token to address
    }

    companion object {
        /** Exchange rates come from the local [FxStub], never the network. */
        @JvmStatic
        @DynamicPropertySource
        fun fxSource(registry: DynamicPropertyRegistry) {
            registry.add("evensies.fx.url") { FxStub.url }
            registry.add("evensies.storage-dir") { storageDir.toString() } // uploads never land in the source tree
        }

        val storageDir: java.nio.file.Path by lazy { java.nio.file.Files.createTempDirectory("evensies-storage") }
    }

    protected fun login(name: String): String = http.post("/auth/dev", mapOf("name" to name)).body["accessToken"].asString()

    protected fun myId(token: String): String = http.get("/me", token).body["id"].asString()

    /** Registers a phone for [token]'s user and returns its FCM token (pushes land in [CapturingPushSender]). */
    protected fun device(token: String): String {
        val fcm = "tok-${UUID.randomUUID()}"
        check(http.post("/devices", mapOf("deviceId" to UUID.randomUUID().toString(), "fcmToken" to fcm), token).status == 204)
        return fcm
    }

    protected fun awaitUntil(what: String, check: () -> Boolean) {
        val end = System.currentTimeMillis() + 5000
        while (System.currentTimeMillis() < end) {
            if (check()) return
            Thread.sleep(20)
        }
        kotlin.test.fail("Timed out waiting for $what")
    }

    /** Creates a group and returns the GroupDto. */
    protected fun createGroup(token: String, name: String = "Trip", currency: String = "EUR"): JsonNode {
        val res = http.post(
            "/groups", mapOf(
                "id" to UUID.randomUUID().toString(), "name" to name, "defaultCurrency" to currency,
                "memberId" to UUID.randomUUID().toString(), "memberName" to "Me",
            ), token
        )
        check(res.status == 200) { "createGroup failed: ${res.status} ${res.text}" }
        return res.body
    }

    /** Joins [group] through its invite as a new member and returns the member id. */
    protected fun join(token: String, group: JsonNode, name: String): String {
        val memberId = UUID.randomUUID().toString()
        val res = http.post("/invites/${group["inviteCode"].asString()}/join", mapOf("newMemberId" to memberId, "name" to name), token)
        check(res.status == 200) { "join failed: ${res.status} ${res.text}" }
        return memberId
    }

    protected fun event(type: String, payload: Map<String, Any?>, clientId: String = UUID.randomUUID().toString()) = mapOf(
        "clientId" to clientId, "type" to type, "payload" to payload, "createdAt" to Instant.now().toString(),
    )

    protected fun memberAdded(name: String, memberId: String = UUID.randomUUID().toString(), userId: String? = null) =
        event("member.added", mapOf("memberId" to memberId, "name" to name, "userId" to userId))

    /** [extra] adds or overrides payload keys (e.g. Phase 3 `payers`, `refund`, `split`). */
    protected fun expenseCreated(
        paidBy: String, amount: Long, shares: Map<String, Long>,
        expenseId: String = UUID.randomUUID().toString(), currency: String = "EUR", description: String = "Dinner",
        extra: Map<String, Any?> = emptyMap(),
    ) = event(
        "expense.created", mapOf(
            "expenseId" to expenseId, "description" to description, "amount" to amount, "currency" to currency,
            "fxRateToDefault" to null, "paidBy" to paidBy, "date" to "2026-10-10", "category" to null,
            "shares" to lines(shares),
        ) + extra
    )

    /** `[{memberId, amount}]`, the shape of `shares` and `payers`. */
    protected fun lines(amounts: Map<String, Long>) = amounts.map { mapOf("memberId" to it.key, "amount" to it.value) }

    protected fun expenseUpdated(expenseId: String, vararg fields: Pair<String, Any?>) =
        event("expense.updated", mapOf("expenseId" to expenseId, "fields" to mapOf(*fields)))

    protected fun push(token: String, groupId: String, vararg events: Map<String, Any?>) =
        http.post("/groups/$groupId/events", events.toList(), token)

    protected fun snapshot(token: String, groupId: String) = http.get("/groups/$groupId/snapshot", token).body
}
