package dev.nariinfo.evensies

import dev.nariinfo.evensies.config.SecurityConfig
import org.junit.jupiter.api.Test
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.nio.file.Files
import java.nio.file.Paths
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * The web app at /app/ (docs/API.md "웹 앱"), served from static/app/ (here the test stand-ins in src/test/resources),
 * the CSP on every response, and GET /info without sign-in settings. No CORS origins are configured in this context.
 */
class WebHostingTest : IntegrationTestBase() {
    /** java.net.http never follows redirects by default and keeps every header value. */
    private fun raw(path: String, method: String = "GET", vararg headers: String): HttpResponse<String> {
        val req = HttpRequest.newBuilder(URI("http://localhost:$port$path")).method(method, HttpRequest.BodyPublishers.noBody())
        if (headers.isNotEmpty()) req.headers(*headers)
        return HttpClient.newHttpClient().send(req.build(), HttpResponse.BodyHandlers.ofString())
    }

    private fun HttpResponse<*>.header(name: String): String? = headers().allValues(name).takeIf { it.isNotEmpty() }?.joinToString(", ")

    @Test
    fun rootAndAppRedirectToTheApp() {
        for (path in listOf("/", "/app")) {
            val res = raw(path)
            assertEquals(302, res.statusCode(), path)
            assertTrue(res.header("location")!!.endsWith("/app/"), "$path → ${res.header("location")}")
        }
    }

    @Test
    fun theAppIsServedWithoutATokenAndRevalidated() {
        val page = raw("/app/")
        assertEquals(200, page.statusCode())
        assertTrue(page.header("content-type")!!.startsWith("text/html"), page.header("content-type"))
        assertTrue(page.body().contains("<html"), page.body())
        assertEquals("no-cache", page.header("cache-control"))

        val wasm = raw("/app/test-fixture.wasm")
        assertEquals(200, wasm.statusCode())
        assertEquals("application/wasm", wasm.header("content-type"))
        assertEquals("no-cache", wasm.header("cache-control"))

        assertEquals(200, raw("/app/index.html").statusCode())
        assertEquals("NOT_FOUND", http.get("/app/missing.js").code(), "a missing file is our 404, not a login wall")
    }

    @Test
    fun theApiStillNeedsAToken() {
        val res = http.get("/groups")
        assertEquals(401, res.status)
        assertEquals("UNAUTHORIZED", res.code())
        assertEquals(401, http.get("/me").status)
        assertEquals(401, http.post("/groups", mapOf("id" to "x")).status)
    }

    /** API, landing, static, redirect, error and auth responses all carry the same policy. */
    @Test
    fun everyResponseCarriesTheCsp() {
        val token = login("Web-csp")
        val group = createGroup(token)
        val responses = listOf(
            raw("/"), raw("/app/"), raw("/app/test-fixture.wasm"), raw("/groups"), raw("/info"), raw("/j/${group["inviteCode"].asString()}"),
            raw("/app/missing.js"), raw("/actuator/health"),
        )
        for (res in responses) {
            assertEquals(SecurityConfig.CSP, res.header("content-security-policy"), res.uri().toString())
            assertTrue(res.header("content-security-policy")!!.endsWith("frame-ancestors 'none'"))
            // image_picker and file_picker hand the app a blob: URL; reading it is a connect (Chrome blocked avatars).
            assertTrue(res.header("content-security-policy")!!.contains("connect-src 'self' blob: "))
        }
        assertEquals(SecurityConfig.CSP, http.get("/me", token).headers["content-security-policy"])
    }

    /** Every third-party host the CSP lets the web app reach is disclosed in the privacy notice (phase 9 design). */
    @Test
    fun cspHostsAreDisclosedInThePrivacyNotice() {
        val privacy = Files.readString(Paths.get("..", "docs", "privacy.md"))
        val hosts = Regex("https://(?:\\*\\.)?([^/; ]+)").findAll(SecurityConfig.CSP).map { it.groupValues[1] }.toSet()
        assertTrue(hosts.size >= 5, hosts.toString())
        for (host in hosts) assertTrue(privacy.contains(host), "docs/privacy.md does not mention $host")
    }

    @Test
    fun infoWithoutWebSignIn() {
        val info = http.get("/info")
        assertEquals(200, info.status, info.text)
        assertTrue(info.body["appleServicesId"].isNull && info.body["googleWebClientId"].isNull, info.text)
        assertTrue(info.body["devLogin"].asBoolean(), "the test context turns dev login on")
    }

    @Test
    fun noCorsWithoutConfiguredOrigins() {
        val preflight = raw("/groups", "OPTIONS", "Origin", "http://localhost:7357", "Access-Control-Request-Method", "POST")
        assertNull(preflight.header("access-control-allow-origin"))
        val get = raw("/info", "GET", "Origin", "http://localhost:7357")
        assertEquals(200, get.statusCode())
        assertNull(get.header("access-control-allow-origin"))
    }
}
