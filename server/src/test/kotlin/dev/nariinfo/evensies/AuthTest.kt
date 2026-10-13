package dev.nariinfo.evensies

import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

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

    /** Review sign-in (ReviewLoginTest) is off unless configured: no endpoint, `reviewLogin: false`. */
    @Test
    fun reviewLoginIsOffByDefault() {
        assertEquals(false, http.get("/info").body["reviewLogin"].asBoolean())
        val res = http.post("/auth/review", mapOf("username" to "app-reviewer", "password" to "test-review-password-0123456789"))
        assertEquals(404, res.status, res.text)
        assertEquals("NOT_FOUND", res.code())
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

    /** Phase 4: homeCurrency in UserDto (login, GET and PATCH /me). PATCH needs a key, checks everything, then writes. */
    @Test
    fun homeCurrency() {
        val login = http.post("/auth/dev", mapOf("name" to "Home")).body
        val token = login["accessToken"].asString()
        assertTrue(login["user"].has("homeCurrency") && login["user"]["homeCurrency"].isNull, "never set: null")
        assertTrue(http.get("/me", token).body["homeCurrency"].isNull)

        val set = http.patch("/me", mapOf("homeCurrency" to "USD"), token)
        assertEquals(200, set.status, set.text)
        assertEquals("USD", set.body["homeCurrency"].asString())
        assertEquals("Home", set.body["displayName"].asString(), "the name is kept")
        assertEquals("USD", http.get("/me", token).body["homeCurrency"].asString())
        assertEquals("USD", http.post("/auth/dev", mapOf("name" to "Home")).body["user"]["homeCurrency"].asString(), "login returns it")

        val both = http.patch("/me", mapOf("displayName" to " Hjome ", "homeCurrency" to "ZAR"), token)
        assertEquals(200, both.status, both.text)
        assertEquals(listOf("Hjome", "ZAR"), listOf(both.body["displayName"].asString(), both.body["homeCurrency"].asString()))
        val old = http.patch("/me", mapOf("displayName" to "Home"), token)
        assertEquals(200, old.status, "the Phase 1 body still works")
        assertEquals("ZAR", old.body["homeCurrency"].asString(), "and keeps the currency")
        val nullKey = http.patch("/me", mapOf("displayName" to "Home", "homeCurrency" to null), token)
        assertEquals(200, nullKey.status, nullKey.text)
        assertEquals("ZAR", nullKey.body["homeCurrency"].asString(), "null counts as absent: it can't be cleared")

        for ((body, code) in listOf(
            emptyMap<String, Any?>() to "VALIDATION",
            mapOf("homeCurrency" to null) to "VALIDATION",
            mapOf("displayName" to null, "homeCurrency" to null) to "VALIDATION",
            listOf("USD") to "VALIDATION",
            null to "VALIDATION",
            mapOf("homeCurrency" to 840) to "VALIDATION",
            mapOf("homeCurrency" to listOf("USD")) to "VALIDATION",
            mapOf("homeCurrency" to true) to "VALIDATION",
            mapOf("displayName" to 5) to "VALIDATION",
            mapOf("homeCurrency" to "usd") to "UNKNOWN_CURRENCY",
            mapOf("homeCurrency" to "XXX") to "UNKNOWN_CURRENCY",
            mapOf("homeCurrency" to "XAU") to "UNKNOWN_CURRENCY",
            mapOf("homeCurrency" to "") to "UNKNOWN_CURRENCY",
            // nothing is written when any part is bad
            mapOf("displayName" to "Changed", "homeCurrency" to "usd") to "UNKNOWN_CURRENCY",
            mapOf("displayName" to "  ", "homeCurrency" to "JPY") to "VALIDATION",
        )) {
            val res = http.patch("/me", body, token)
            assertEquals(400, res.status, "$body: ${res.text}")
            assertEquals(code, res.code(), "$body")
        }
        val me = http.get("/me", token).body
        assertEquals(listOf("Home", "ZAR"), listOf(me["displayName"].asString(), me["homeCurrency"].asString()))

        assertEquals(401, http.patch("/me", mapOf("homeCurrency" to "USD"), null).status)
        assertEquals(204, http.delete("/me", token).status)
        assertEquals(401, http.patch("/me", mapOf("homeCurrency" to "USD"), token).status, "deleted account")
    }
}
