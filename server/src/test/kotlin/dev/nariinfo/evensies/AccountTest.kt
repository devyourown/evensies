package dev.nariinfo.evensies

import dev.nariinfo.evensies.email.EmailAddress
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import java.time.LocalDate
import java.time.ZoneOffset
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** Sign out everywhere, export everything and the Phase 10 parts of account deletion (docs/API.md "Email and account"). */
class AccountTest : IntegrationTestBase() {
    @Autowired
    private lateinit var jdbc: JdbcClient

    private fun count(sql: String, id: String) = jdbc.sql(sql).param("u", UUID.fromString(id)).query(Int::class.java).single()

    @Test
    fun logoutAllEndsEverySession() {
        val name = "Out-${UUID.randomUUID().toString().take(6)}"
        val phone = http.post("/auth/dev", mapOf("name" to name)).body
        val laptop = http.post("/auth/dev", mapOf("name" to name)).body
        val token = phone["accessToken"].asString()
        device(token)
        device(laptop["accessToken"].asString())
        assertEquals(204, http.post("/me/logout-all", null, token).status)
        assertEquals(401, http.post("/auth/refresh", mapOf("refreshToken" to phone["refreshToken"].asString())).status)
        assertEquals(401, http.post("/auth/refresh", mapOf("refreshToken" to laptop["refreshToken"].asString())).status)
        assertEquals(0, count("SELECT count(*) FROM devices WHERE user_id = :u", myId(token)))
        assertEquals(401, http.post("/me/logout-all", null).status)
    }

    @Test
    fun exportHoldsEveryGroupDeletedOnesIncluded() {
        val (anna, email) = emailUser("Exporter")
        assertEquals(200, http.put("/me/payment-methods", listOf(mapOf("type" to "upi", "value" to "anna@okicici")), anna).status)
        val kept = createGroup(anna, name = "Kept")
        val gone = createGroup(anna, name = "Gone")
        assertEquals(200, push(anna, gone["id"].asString(), event("group.deleted", emptyMap())).status)
        val ben = login("Exp-ben-${UUID.randomUUID().toString().take(6)}")
        val left = createGroup(ben, name = "Not mine")

        val res = http.get("/me/export", anna)
        assertEquals(200, res.status, res.text)
        assertEquals("attachment; filename=\"evensies-export-${LocalDate.now(ZoneOffset.UTC)}.json\"", res.headers["content-disposition"])
        val body = res.body
        assertEquals(email, body["user"]["email"].asString())
        assertEquals("Exporter", body["user"]["displayName"].asString())
        assertEquals("upi", body["paymentMethods"].single()["type"].asString())
        assertEquals("auto", body["notifications"]["emailDigest"].asString())
        assertTrue(body["notifications"].has("emailDigestEffective"))
        val groups = body["groups"].values().associate { it["group"]["name"].asString() to it }
        assertEquals(setOf("Kept", "Gone"), groups.keys)
        assertTrue(groups.getValue("Gone")["group"]["deleted"].asBoolean())
        assertEquals(kept["id"].asString(), groups.getValue("Kept")["group"]["id"].asString())
        assertTrue(left["id"].asString() !in res.text)
        assertTrue(body.has("exportedAt"))
        // 3 per user per hour
        repeat(2) { assertEquals(200, http.get("/me/export", anna).status) }
        assertEquals(429, http.get("/me/export", anna).status)
    }

    @Test
    fun deletingTheAccountClearsEmailNamePrefsInvitesAndBlocks() {
        val (anna, email) = emailUser("Leaver")
        val id = myId(anna)
        val group = createGroup(anna)
        val placeholder = UUID.randomUUID().toString()
        assertEquals(200, push(anna, group["id"].asString(), memberAdded("Cara", placeholder)).status)
        val cara = address("Cara")
        assertEquals(204, http.post("/groups/${group["id"].asString()}/members/$placeholder/invite-email", mapOf("email" to cara), anna).status)
        assertEquals(1, mail.to(cara).size)
        assertEquals(200, http.put("/me/notifications", mapOf("expenses" to true, "comments" to true, "members" to true, "emailDigest" to "weekly"), anna).status)
        assertEquals(204, http.put("/me/blocks/${myId(login("Lv-x-${UUID.randomUUID().toString().take(6)}"))}", null, anna).status)
        assertEquals(204, http.post("/me/email", mapOf("email" to address("Pending")), anna).status)

        assertEquals(204, http.delete("/me", anna).status)
        val (name, stored) = jdbc.sql("SELECT display_name, email FROM users WHERE id = :u").param("u", UUID.fromString(id))
            .query { rs, _ -> rs.getString("display_name") to rs.getString("email") }.single()
        assertEquals("" to null, name to stored)
        assertEquals(0, count("SELECT count(*) FROM notification_prefs WHERE user_id = :u", id))
        assertEquals(0, count("SELECT count(*) FROM email_invites WHERE invited_by = :u", id))
        assertEquals(0, count("SELECT count(*) FROM user_blocks WHERE blocker = :u OR blocked = :u", id))
        assertEquals(0, count("SELECT count(*) FROM email_codes WHERE user_id = :u", id))
        assertEquals(0, jdbc.sql("SELECT count(*) FROM email_codes WHERE email = :e").param("e", email).query(Int::class.java).single())
        assertEquals(0, jdbc.sql("SELECT count(*) FROM email_suppressions WHERE email_hash = :h").param("h", EmailAddress.hash(email)).query(Int::class.java).single())
    }
}
