package dev.nariinfo.evensies

import dev.nariinfo.evensies.group.GroupRepository
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.test.context.TestPropertySource
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * One per-IP bucket for every code lookup (docs/API.md "Groups: friend codes"): group invites and friend codes draw from it
 * together. Its own context with 4 lookups a minute; also the shared code namespace.
 */
@TestPropertySource(properties = ["evensies.invite-rate-per-minute=4"])
class CodeLookupLimitTest : IntegrationTestBase() {
    @Autowired
    private lateinit var groups: GroupRepository

    @Autowired
    private lateinit var jdbc: JdbcClient

    @Test
    fun inviteAndFriendCodeLookupsShareOneBucketPerIp() {
        val anna = login("Cl-anna")
        val ben = login("Cl-ben")
        val inviteCode = createGroup(anna)["inviteCode"].asString()
        val friendCode = http.get("/me/friend-code", anna).body["friendCode"].asString() // not a lookup
        assertEquals(200, http.get("/invites/$inviteCode").status)
        assertEquals(200, http.get("/friend-invites/$friendCode").status)
        assertEquals(200, http.get("/f/$friendCode").status)
        assertEquals(200, http.post("/friends", mapOf("id" to UUID.randomUUID().toString(), "defaultCurrency" to "EUR", "code" to friendCode), ben).status)
        for (res in listOf(http.get("/invites/$inviteCode"), http.get("/friend-invites/$friendCode"), http.get("/f/$friendCode"), http.get("/j/$inviteCode"),
            http.post("/friends", mapOf("id" to UUID.randomUUID().toString(), "defaultCurrency" to "EUR", "code" to friendCode), ben))) {
            assertEquals(429 to "RATE_LIMITED", res.status to res.code())
        }
        // POST /friends by name or userId never touches the IP bucket
        assertEquals(200, http.post("/friends", mapOf("id" to UUID.randomUUID().toString(), "defaultCurrency" to "EUR", "name" to "Zoe"), ben).status)
    }

    @Test
    fun groupInviteCodesAndFriendCodesShareOneNamespace() {
        val token = login("Cl-codes")
        val inviteCode = createGroup(token)["inviteCode"].asString()
        val friendCode = http.get("/me/friend-code", token).body["friendCode"].asString()
        assertTrue(groups.codeTaken(inviteCode), "a group's code")
        assertTrue(groups.codeTaken(friendCode), "a user's friend code")
        val free = generateSequence { groups.newCode() }.first { it != inviteCode && it != friendCode }
        assertEquals(false, groups.codeTaken(free))
        assertEquals(0L, jdbc.sql("SELECT count(*) FROM groups WHERE invite_code IN (SELECT friend_code FROM users)").query(Long::class.java).single())
    }
}
