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
    ],
)
@Import(TestcontainersConfiguration::class, PushCaptureConfiguration::class)
abstract class IntegrationTestBase {
    @LocalServerPort
    protected var port = 0

    @Autowired
    protected lateinit var mapper: ObjectMapper

    protected val http: Http by lazy { Http(port, mapper) }

    companion object {
        /** Exchange rates come from the local [FxStub], never the network. */
        @JvmStatic
        @DynamicPropertySource
        fun fxSource(registry: DynamicPropertyRegistry) = registry.add("evensies.fx.url") { FxStub.url }
    }

    protected fun login(name: String): String = http.post("/auth/dev", mapOf("name" to name)).body["accessToken"].asString()

    protected fun myId(token: String): String = http.get("/me", token).body["id"].asString()

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
