package dev.nariinfo.evensies

import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.dao.DataIntegrityViolationException
import org.springframework.jdbc.core.simple.JdbcClient
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

/** Phase 9 `users.language` (docs/API.md "Authentication", "User language"): UserDto.language and PATCH /me's keep / set / clear. */
class UserLanguageTest : IntegrationTestBase() {
    @Autowired
    private lateinit var jdbc: JdbcClient

    private fun name() = "Lang-${UUID.randomUUID().toString().take(8)}"

    @Test
    fun setKeepAndClear() {
        val name = name()
        val login = http.post("/auth/dev", mapOf("name" to name)).body
        val token = login["accessToken"].asString()
        assertTrue(login["user"].has("language") && login["user"]["language"].isNull, "never set: null (English)")
        assertTrue(http.get("/me", token).body["language"].isNull)

        val set = http.patch("/me", mapOf("language" to "ko"), token)
        assertEquals(200, set.status, set.text)
        assertEquals("ko", set.body["language"].asString())
        assertEquals(name, set.body["displayName"].asString(), "a language-only body keeps the name")
        assertEquals("ko", http.get("/me", token).body["language"].asString())
        assertEquals("ko", http.post("/auth/dev", mapOf("name" to name)).body["user"]["language"].asString(), "login returns it")

        val legacy = http.patch("/me", mapOf("displayName" to "Renamed"), token)
        assertEquals(200, legacy.status)
        assertEquals("ko", legacy.body["language"].asString(), "an old app's body (no key) keeps it")
        val nullOthers = http.patch("/me", mapOf("displayName" to null, "homeCurrency" to null, "language" to "de"), token)
        assertEquals(listOf("Renamed", "de"), listOf(nullOthers.body["displayName"].asString(), nullOthers.body["language"].asString()))
        val all = http.patch("/me", mapOf("displayName" to "Hyo", "homeCurrency" to "KRW", "language" to "ja"), token).body
        assertEquals(listOf("Hyo", "KRW", "ja"), listOf(all["displayName"].asString(), all["homeCurrency"].asString(), all["language"].asString()))

        val cleared = http.patch("/me", mapOf("language" to null), token)
        assertEquals(200, cleared.status, "a null language is a clear, not an empty body")
        assertTrue(cleared.body["language"].isNull)
        assertEquals("KRW", cleared.body["homeCurrency"].asString())
        assertTrue(http.get("/me", token).body["language"].isNull)

        val unknown = http.patch("/me", mapOf("language" to "xx"), token)
        assertEquals("xx", unknown.body["language"].asString(), "a well-formed code without strings is stored (rendered as English)")
    }

    @Test
    fun badBodiesAreRejectedAndWriteNothing() {
        val token = login(name())
        assertEquals(200, http.patch("/me", mapOf("displayName" to "Kept", "language" to "fr"), token).status)
        val bad = listOf(
            mapOf("language" to "de_AT"), mapOf("language" to "de-AT"), mapOf("language" to "x"), mapOf("language" to "deutsch"),
            mapOf("language" to "<b>"), mapOf("language" to "DE"), mapOf("language" to ""), mapOf("language" to " ko"),
            mapOf("language" to 12), mapOf("language" to true), mapOf("language" to listOf("ko")), mapOf("language" to mapOf("ko" to 1)),
            emptyMap(), mapOf("displayName" to null), mapOf("displayName" to null, "homeCurrency" to null),
            mapOf("displayName" to "Changed", "language" to "x"), mapOf("homeCurrency" to "USD", "language" to "deutsch"),
        )
        for (body in bad) {
            val res = http.patch("/me", body, token)
            assertEquals(400, res.status, "$body → ${res.text}")
            assertEquals("VALIDATION", res.code(), "$body")
        }
        val me = http.get("/me", token).body
        assertEquals(listOf("Kept", "fr"), listOf(me["displayName"].asString(), me["language"].asString()))
        assertTrue(me["homeCurrency"].isNull, "checked before anything is written")
        assertEquals("UNKNOWN_CURRENCY", http.patch("/me", mapOf("homeCurrency" to "usd", "language" to "ko"), token).code())
        assertEquals("fr", http.get("/me", token).body["language"].asString())
    }

    @Test
    fun signedOutAndDeletedAccountsAre401AndTheColumnIsChecked() {
        assertEquals(401, http.patch("/me", mapOf("language" to "ko"), null).status)
        val token = login(name())
        val id = UUID.fromString(myId(token))
        assertFailsWith<DataIntegrityViolationException>("V11's CHECK") {
            jdbc.sql("UPDATE users SET language = 'EN' WHERE id = :id").param("id", id).update()
        }
        assertEquals(204, http.delete("/me", token).status)
        assertEquals(401, http.patch("/me", mapOf("language" to "ko"), token).status)
    }
}
