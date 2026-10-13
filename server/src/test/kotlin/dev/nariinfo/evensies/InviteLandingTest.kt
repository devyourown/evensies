package dev.nariinfo.evensies

import dev.nariinfo.evensies.common.Strings
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import org.springframework.web.util.HtmlUtils
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

/** `/j/{code}` and `/f/{code}` in the Accept-Language language (docs/API.md "Landing pages"). */
class InviteLandingTest : IntegrationTestBase() {
    @Autowired
    private lateinit var jdbc: JdbcClient

    private fun page(path: String, acceptLanguage: String? = null): Http.Resp {
        val res = http.get(path, headers = acceptLanguage?.let { mapOf("Accept-Language" to it) } ?: emptyMap())
        assertEquals(200, res.status, res.text)
        return res
    }

    private fun lang(res: Http.Resp) = Regex("<html lang=\"([a-z]+)\">").find(res.text)!!.groupValues[1]

    private fun landing(lang: String, key: String) = Strings.get(lang, "landing", key)!!

    @Test
    fun theLanguageFollowsAcceptLanguage() {
        val token = login("Land-anna")
        val code = createGroup(token, name = "Trip")["inviteCode"].asString()
        val cases = mapOf(
            null to "en", "ko-KR" to "ko", "ko-KR,ko;q=0.9,en-US;q=0.8" to "ko", "fr-CA" to "fr", "pt-BR" to "pt", "de;q=0.5, ja;q=0.9" to "ja",
            "xx" to "en", "xx, it;q=0.1" to "it", "*" to "en", "en-GB" to "en", "not a header;;q=x" to "en",
        )
        for ((header, expected) in cases) {
            val res = page("/j/$code", header)
            assertEquals(expected, lang(res), "$header")
            assertEquals("Accept-Language", res.headers["vary"], "$header")
            assertTrue(res.headers["content-type"]!!.startsWith("text/html") && res.headers["content-type"]!!.contains("UTF-8", ignoreCase = true))
        }

        val ko = page("/j/$code", "ko-KR").text
        for (key in listOf("invited", "openApp", "openWeb", "code", "appStore", "googlePlay")) {
            assertNotEquals(landing("en", key), landing("ko", key), "ko $key is translated")
            assertTrue(ko.contains(HtmlUtils.htmlEscape(landing("ko", key), "UTF-8")), "ko $key")
        }
        assertTrue(ko.contains(Strings.fill(landing("ko", "title"), mapOf("group" to "Trip"))))
        assertTrue(ko.contains(Strings.fill(landing("ko", "members"), mapOf("count" to "1"))))
        assertTrue(page("/j/$code", "fr-CA").text.contains(HtmlUtils.htmlEscape(landing("fr", "openWeb"), "UTF-8")))

        val en = page("/j/$code").text
        assertTrue(en.contains("<title>Join Trip on Evensies</title>") && en.contains("<h1>Trip</h1>"), en)
        assertTrue(en.contains("You’re invited to split expenses in this group.") && en.contains("Members: 1"), en)
        assertTrue(en.contains("Open in the app") && en.contains("Continue in the browser"), en)
        assertTrue(en.contains("Have the app? Open it, tap “Join with a code” and enter ${code.chunked(3).joinToString("-")}."), en)
        assertFalse(en.contains("<b>"), "the old emphasis is gone")
    }

    @Test
    fun theBrowserLinks() {
        val token = login("Land-links")
        val code = createGroup(token)["inviteCode"].asString()
        val typed = code.lowercase().chunked(3).joinToString("-")
        val group = page("/j/$typed").text
        assertTrue(group.contains("href=\"/app/#/join/$code\""), group)
        assertTrue(group.contains("href=\"evensies://join/$typed\""), "the app link keeps the code as typed")

        val friendCode = http.get("/me/friend-code", token).body["friendCode"].asString()
        val friend = page("/f/${friendCode.lowercase()}", "de-AT").text
        assertTrue(friend.contains("href=\"/app/#/friends/add?code=$friendCode\""), friend)
        assertTrue(friend.contains("href=\"evensies://f/${friendCode.lowercase()}\""), friend)
        assertEquals("de", lang(page("/f/$friendCode", "de-AT")))
        assertEquals(404, http.get("/f/ZZZZZZ", headers = mapOf("Accept-Language" to "ko")).status)
    }

    @Test
    fun namesAreEscapedAndABlankNameIsSomeone() {
        val token = login("Land-<b>x</b>")
        val code = createGroup(token, name = "<script>alert(1)</script> & co")["inviteCode"].asString()
        val group = page("/j/$code", "ja").text
        assertFalse(group.contains("<script>"), group)
        assertTrue(group.contains("&lt;script&gt;alert(1)&lt;/script&gt; &amp; co"), group)

        val friendCode = http.get("/me/friend-code", token).body["friendCode"].asString()
        val friend = page("/f/$friendCode").text
        assertFalse(friend.contains("<b>x</b>"), friend)
        assertTrue(friend.contains("Land-&lt;b&gt;x&lt;/b&gt; wants to split expenses with you."), friend)

        // An account without a name (Apple sends it only once): words.someone, upper-cased at the start.
        jdbc.sql("UPDATE users SET display_name = '' WHERE id = :id").param("id", UUID.fromString(myId(token))).update()
        val someone = page("/f/$friendCode").text
        assertTrue(someone.contains("<title>Someone on Evensies</title>") && someone.contains("<h1>Someone</h1>"), someone)
        assertTrue(someone.contains("Someone wants to split expenses with you."), someone)
        val de = page("/f/$friendCode", "de").text
        assertTrue(de.contains("<h1>${Strings.get("de", "words", "someone")!!.replaceFirstChar { it.uppercase() }}</h1>"), de)
    }
}
