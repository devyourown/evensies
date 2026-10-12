package dev.nariinfo.evensies

import dev.nariinfo.evensies.auth.IdTokenVerifier
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.beans.factory.annotation.Qualifier
import org.springframework.test.context.TestPropertySource
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * A server with web sign-in and a development CORS origin (docs/API.md "웹 앱"): exact-origin CORS, GET /info, and the
 * accepted `aud` lists. WebHostingTest covers the same without these settings.
 */
@TestPropertySource(
    properties = [
        "evensies.cors-origins=http://localhost:7357, http://localhost:8081",
        "evensies.auth.apple-client-id=dev.nariinfo.evensies",
        "evensies.auth.apple-services-id=dev.nariinfo.evensies.web",
        "evensies.auth.google-client-ids=ios-client,web-client",
        "evensies.auth.google-web-client-id=web-client",
    ],
)
class CorsAndInfoTest : IntegrationTestBase() {
    @Autowired
    @Qualifier("appleVerifier")
    private lateinit var apple: IdTokenVerifier

    @Autowired
    @Qualifier("googleVerifier")
    private lateinit var google: IdTokenVerifier

    private fun raw(path: String, method: String, vararg headers: String): HttpResponse<String> {
        val req = HttpRequest.newBuilder(URI("http://localhost:$port$path")).method(method, HttpRequest.BodyPublishers.noBody())
        if (headers.isNotEmpty()) req.headers(*headers)
        return HttpClient.newHttpClient().send(req.build(), HttpResponse.BodyHandlers.ofString())
    }

    private fun preflight(origin: String, method: String = "PATCH", headers: String = "authorization,content-type") =
        raw("/me", "OPTIONS", "Origin", origin, "Access-Control-Request-Method", method, "Access-Control-Request-Headers", headers)

    private fun HttpResponse<*>.header(name: String): String? = headers().firstValue(name).orElse(null)

    @Test
    fun anAllowedOriginsPreflight() {
        val res = preflight("http://localhost:7357")
        assertEquals(200, res.statusCode(), res.body())
        assertEquals("http://localhost:7357", res.header("access-control-allow-origin"))
        assertEquals(listOf("GET", "POST", "PUT", "PATCH", "DELETE"), res.header("access-control-allow-methods")!!.split(",").map(String::trim))
        assertEquals(setOf("authorization", "content-type"), res.header("access-control-allow-headers")!!.lowercase().split(",").map(String::trim).toSet())
        assertEquals("3600", res.header("access-control-max-age"))
        assertNull(res.header("access-control-allow-credentials"), "the token is a header, never a cookie")
        assertEquals("http://localhost:8081", preflight("http://localhost:8081").header("access-control-allow-origin"), "a comma list, trimmed")

        // the real request: allowed origin echoed, the API still needs the token
        val token = login("Cors-anna")
        val me = HttpClient.newHttpClient().send(
            HttpRequest.newBuilder(URI("http://localhost:$port/me")).header("Origin", "http://localhost:7357").header("Authorization", "Bearer $token").build(),
            HttpResponse.BodyHandlers.ofString(),
        )
        assertEquals(200, me.statusCode())
        assertEquals("http://localhost:7357", me.header("access-control-allow-origin"))
        assertEquals(401, raw("/me", "GET", "Origin", "http://localhost:7357").statusCode())
    }

    @Test
    fun otherOriginsMethodsAndHeadersAreRefused() {
        for (res in listOf(
            preflight("https://evil.example"),
            preflight("http://localhost:7358"),
            preflight("http://LOCALHOST:7357.evil.example"),
            preflight("http://localhost:7357", method = "TRACE"),
            preflight("http://localhost:7357", headers = "x-custom"),
        )) {
            assertEquals(403, res.statusCode(), res.body())
            assertNull(res.header("access-control-allow-origin"))
            assertTrue(!res.body().contains("\"code\""), "Spring's own body, not our error JSON: ${res.body()}")
        }
        val evil = raw("/info", "GET", "Origin", "https://evil.example")
        assertEquals(403, evil.statusCode())
        assertNull(evil.header("access-control-allow-origin"))
        assertEquals(200, raw("/info", "GET").statusCode(), "same-origin and non-browser calls send no Origin")
    }

    @Test
    fun infoNamesTheWebSignInIds() {
        val info = http.get("/info")
        assertEquals(200, info.status, info.text)
        assertEquals("dev.nariinfo.evensies.web", info.body["appleServicesId"].asString())
        assertEquals("web-client", info.body["googleWebClientId"].asString())
        assertTrue(info.body["devLogin"].asBoolean())
        // Phase 10: which sign-ins this server offers and the operator's contact address.
        assertTrue(info.body["appleLogin"].asBoolean() && info.body["googleLogin"].asBoolean() && info.body["emailLogin"].asBoolean())
        assertEquals("help@evensies.test", info.body["supportEmail"].asString())
    }

    /** docs/API.md "받는 `aud`": Apple = bundle id + Services ID, Google = the phone ids ∪ the web id (no duplicate). */
    @Test
    fun theVerifiersAcceptTheWebAudiences() {
        assertEquals(listOf("dev.nariinfo.evensies", "dev.nariinfo.evensies.web"), apple.audiences)
        assertEquals(listOf("ios-client", "web-client"), google.audiences)
    }
}
