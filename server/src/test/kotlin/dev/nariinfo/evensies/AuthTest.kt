package dev.nariinfo.evensies

import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals

class AuthTest : IntegrationTestBase() {
    @Test
    fun devLoginSameNameSameUser() {
        val a = http.post("/auth/dev", mapOf("name" to "Anna")).body
        val b = http.post("/auth/dev", mapOf("name" to "Anna")).body
        assertEquals(a["user"]["id"], b["user"]["id"])
        assertEquals("Anna", a["user"]["displayName"].asString())
        assertEquals(a["user"]["id"].asString(), http.get("/me", a["accessToken"].asString()).body["id"].asString())
    }

    @Test
    fun unauthenticatedRequestsAre401() {
        assertEquals(401, http.get("/me").status)
        assertEquals("UNAUTHORIZED", http.get("/me").code())
        assertEquals(401, http.get("/me", "not-a-jwt").status)
        assertEquals(200, http.get("/actuator/health").status)
    }

    @Test
    fun refreshRotates() {
        val login = http.post("/auth/dev", mapOf("name" to "Rot")).body
        val first = login["refreshToken"].asString()
        val rotated = http.post("/auth/refresh", mapOf("refreshToken" to first))
        assertEquals(200, rotated.status)
        val second = rotated.body["refreshToken"].asString()
        assertNotEquals(first, second)
        assertEquals(200, http.get("/me", rotated.body["accessToken"].asString()).status)
        assertEquals(401, http.post("/auth/refresh", mapOf("refreshToken" to first)).status)
        assertEquals(200, http.post("/auth/refresh", mapOf("refreshToken" to second)).status)
    }

    @Test
    fun deleteAccount() {
        val login = http.post("/auth/dev", mapOf("name" to "Gone")).body
        val token = login["accessToken"].asString()
        assertEquals(204, http.delete("/me", token).status)
        assertEquals(401, http.get("/me", token).status)
        assertEquals(401, http.post("/auth/refresh", mapOf("refreshToken" to login["refreshToken"].asString())).status)
    }

    @Test
    fun registerDevice() {
        val token = login("Dev")
        assertEquals(204, http.post("/devices", mapOf("deviceId" to "d1", "fcmToken" to "tok"), token).status)
        assertEquals(204, http.post("/devices", mapOf("deviceId" to "d1", "fcmToken" to "tok2"), token).status)
    }

    @Test
    fun renameMe() {
        val token = http.post("/auth/dev", mapOf("name" to "Ren")).body["accessToken"].asString()
        val renamed = http.patch("/me", mapOf("displayName" to "  Hyo 🍕  "), token)
        assertEquals(200, renamed.status, renamed.text)
        assertEquals("Hyo 🍕", http.get("/me", token).body["displayName"].asString())
        assertEquals(400, http.patch("/me", mapOf("displayName" to "   "), token).status)
        assertEquals(400, http.patch("/me", mapOf("displayName" to "x".repeat(31)), token).status)
        assertEquals(200, http.patch("/me", mapOf("displayName" to "🍕".repeat(30)), token).status, "30 emoji are 30 characters")
        assertEquals(401, http.patch("/me", mapOf("displayName" to "Nope"), null).status)
    }
}
