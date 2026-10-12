package dev.nariinfo.evensies

import dev.nariinfo.evensies.email.EmailAddress
import dev.nariinfo.evensies.email.EmailTokens
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import java.net.URI
import java.net.URLEncoder
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** Unsubscribe links (docs/API.md "수신 거부"): GET only shows the page, POST (button or RFC 8058 one-click) applies it. */
class UnsubscribeTest : IntegrationTestBase() {
    @Autowired
    private lateinit var tokens: EmailTokens

    @Autowired
    private lateinit var jdbc: JdbcClient

    private fun raw(method: String, t: String?, body: String? = null, lang: String? = null): HttpResponse<String> {
        val req = HttpRequest.newBuilder(URI("http://localhost:$port/email/unsubscribe" + (t?.let { "?t=" + URLEncoder.encode(it, Charsets.UTF_8) } ?: "")))
        lang?.let { req.header("Accept-Language", it) }
        if (body != null) req.header("Content-Type", "application/x-www-form-urlencoded")
        req.method(method, body?.let { HttpRequest.BodyPublishers.ofString(it) } ?: HttpRequest.BodyPublishers.noBody())
        return HttpClient.newHttpClient().send(req.build(), HttpResponse.BodyHandlers.ofString())
    }

    private fun digest(token: String) = http.get("/me/notifications", token).body["emailDigest"].asString()

    @Test
    fun aDigestLinkTurnsSummariesOffOnlyOnPost() {
        val (anna, _) = emailUser("Unsub")
        val t = tokens.unsubscribe(EmailTokens.DIGEST, myId(anna))
        val page = raw("GET", t)
        assertEquals(200, page.statusCode())
        assertTrue(page.headers().firstValue("content-type").get().startsWith("text/html"))
        assertTrue("<button" in page.body() && "method=\"post\"" in page.body(), page.body())
        assertEquals("auto", digest(anna), "GET changes nothing (link scanners prefetch)")
        val done = raw("POST", t)
        assertEquals(200, done.statusCode())
        assertTrue("get email summaries or reminders any more" in done.body(), done.body())
        assertEquals("off", digest(anna))

        val (ben, _) = emailUser("OneClick")
        assertEquals(200, raw("POST", tokens.unsubscribe(EmailTokens.DIGEST, myId(ben)), body = "List-Unsubscribe=One-Click").statusCode())
        assertEquals("off", digest(ben), "RFC 8058 one-click")
    }

    @Test
    fun anInvitesLinkSuppressesTheAddress() {
        val email = address("Invited")
        val t = tokens.unsubscribe(EmailTokens.INVITES, EmailAddress.hash(email))
        assertTrue("Stop all invites" in raw("GET", t).body())
        assertEquals(200, raw("POST", t).statusCode())
        val reason = jdbc.sql("SELECT reason FROM email_suppressions WHERE email_hash = :h").param("h", EmailAddress.hash(email)).query(String::class.java).single()
        assertEquals("unsubscribe", reason)
        val anna = login("Uns-anna-${UUID.randomUUID().toString().take(6)}")
        val id = createGroup(anna)["id"].asString()
        val cara = UUID.randomUUID().toString()
        assertEquals(200, push(anna, id, memberAdded("Cara", cara)).status)
        assertEquals(204, http.post("/groups/$id/members/$cara/invite-email", mapOf("email" to email), anna).status)
        assertEquals(0, mail.to(email).size, "silently skipped")
    }

    @Test
    fun aTamperedOrMissingTokenIsA400PageInTheReadersLanguage() {
        val (anna, _) = emailUser("Tamper")
        val t = tokens.unsubscribe(EmailTokens.DIGEST, myId(anna))
        val tampered = t.dropLast(2) + if (t.endsWith("AA")) "BB" else "AA"
        for (bad in listOf(tampered, "garbage", "a.b", null)) {
            val res = raw("POST", bad)
            assertEquals(400, res.statusCode(), bad)
            assertTrue("work any more. You can change your email settings in the app" in res.body(), res.body())
        }
        val forged = tokens.unsubscribe("other", myId(anna))
        assertEquals(400, raw("GET", forged).statusCode(), "an unknown kind")
        assertEquals("auto", digest(anna))
        val de = raw("GET", t, lang = "de-DE,de;q=0.9")
        assertTrue("<html lang=\"de\">" in de.body() && "Abbestellen" in de.body(), de.body())
    }
}
