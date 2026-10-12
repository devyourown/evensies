package dev.nariinfo.evensies

import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** Blocking someone mutes them (docs/API.md "차단"); money stays visible. */
class BlockTest : IntegrationTestBase() {
    @Autowired
    private lateinit var capture: CapturingPushSender

    @Autowired
    private lateinit var jdbc: JdbcClient

    private class Person(val token: String, val id: String, val device: String)

    private fun person(name: String): Person {
        val token = login("$name-${UUID.randomUUID().toString().take(6)}")
        return Person(token, myId(token), device(token))
    }

    private fun assertError(status: Int, code: String, res: Http.Resp) {
        assertEquals(status, res.status, res.text)
        assertEquals(code, res.code(), res.text)
    }

    private fun block(p: Person, who: String) = http.put("/me/blocks/$who", null, p.token)

    @Test
    fun blockListUnblockAndValidation() {
        val anna = person("Bl-anna")
        val ben = person("Bl-ben")
        assertEquals(204, block(anna, ben.id).status)
        assertEquals(204, block(anna, ben.id).status, "twice is fine")
        val list = http.get("/me/blocks", anna.token).body
        assertEquals(ben.id, list.single()["userId"].asString())
        assertTrue(list.single()["displayName"].asString().startsWith("Bl-ben"))
        assertError(400, "VALIDATION", block(anna, anna.id))
        assertError(404, "NOT_FOUND", block(anna, UUID.randomUUID().toString()))
        assertEquals(400, http.put("/me/blocks/not-a-uuid", null, anna.token).status)
        assertEquals(401, http.put("/me/blocks/${ben.id}", null).status)
        assertEquals(204, http.delete("/me/blocks/${ben.id}", anna.token).status)
        assertEquals(0, http.get("/me/blocks", anna.token).body.size())
    }

    @Test
    fun aBlockedPersonCantAddRemindOrNotify() {
        val anna = person("Bl2-anna")
        val ben = person("Bl2-ben")
        val group = createGroup(anna.token)
        val id = group["id"].asString()
        val a = group["myMemberId"].asString()
        val b = join(ben.token, group, "Ben")
        assertEquals(200, push(anna.token, id, expenseCreated(a, 2000, mapOf(a to 1000, b to 1000))).status) // Ben owes Anna
        assertEquals(204, block(ben, anna.id).status) // Ben blocks Anna

        // Anna can't add Ben as a friend: by code 404, by userId 403, the same as unknown.
        val code = http.get("/me/friend-code", ben.token).body["friendCode"].asString()
        assertError(404, "NOT_FOUND", http.post("/friends", mapOf("id" to UUID.randomUUID().toString(), "defaultCurrency" to "EUR", "code" to code), anna.token))
        assertError(403, "FORBIDDEN", http.post("/friends", mapOf("id" to UUID.randomUUID().toString(), "defaultCurrency" to "EUR", "userId" to ben.id), anna.token))

        // Her reminder is accepted but never shown.
        assertEquals(200, http.post("/friends/${ben.id}/remind", null, anna.token).status)
        Thread.sleep(300)
        assertTrue(capture.to(ben.device).none { it.data["type"] == "remind" })

        // Her changes only sync on Ben's phones; Anna still sees Ben's.
        val before = capture.to(ben.device).size
        assertEquals(200, push(anna.token, id, expenseCreated(a, 600, mapOf(a to 300, b to 300), description = "Muted")).status)
        awaitUntil("Ben's data-only sync") { capture.to(ben.device).size > before }
        Thread.sleep(1200)
        assertTrue(capture.to(ben.device).drop(before).all { it.title == null && it.data["type"] == "sync" })
        assertEquals(200, push(ben.token, id, expenseCreated(b, 400, mapOf(a to 200, b to 200), description = "Shown")).status)
        awaitUntil("Anna's visible push") { capture.to(anna.device).any { it.body?.contains("Shown") == true } }
        assertEquals(3, snapshot(ben.token, id)["expenses"].size(), "money stays visible")

        // Unblock restores all of it.
        assertEquals(204, http.delete("/me/blocks/${anna.id}", ben.token).status)
        assertEquals(200, push(anna.token, id, expenseCreated(a, 800, mapOf(a to 400, b to 400), description = "Back")).status)
        awaitUntil("Ben's visible push again") { capture.to(ben.device).any { it.body?.contains("Back") == true } }
        assertEquals(200, http.post("/friends", mapOf("id" to UUID.randomUUID().toString(), "defaultCurrency" to "EUR", "code" to code), anna.token).status)
    }

    @Test
    fun accountDeletionRemovesBlocksInBothDirections() {
        val anna = person("Bl3-anna")
        val ben = person("Bl3-ben")
        val cara = person("Bl3-cara")
        assertEquals(204, block(anna, ben.id).status)
        assertEquals(204, block(cara, anna.id).status)
        assertEquals(204, http.delete("/me", anna.token).status)
        val rows = jdbc.sql("SELECT count(*) FROM user_blocks WHERE blocker = :u OR blocked = :u").param("u", UUID.fromString(anna.id)).query(Int::class.java).single()
        assertEquals(0, rows)
        assertEquals(0, http.get("/me/blocks", cara.token).body.size())
    }
}
