package dev.nariinfo.evensies

import dev.nariinfo.evensies.auth.AuthService
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.extension.ExtendWith
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.system.CapturedOutput
import org.springframework.boot.test.system.OutputCaptureExtension
import org.springframework.http.HttpMethod
import org.springframework.test.context.TestPropertySource
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

private const val USERNAME = "app-reviewer"
private const val PASSWORD = "test-review-password-0123456789"

/** A raw POST /auth/review (malformed bodies the JSON helper can't send). */
private fun rawReview(port: Int, body: String, type: String = "application/json"): HttpResponse<String> = HttpClient.newHttpClient().send(
    HttpRequest.newBuilder(URI("http://localhost:$port/auth/review")).header("Content-Type", type)
        .POST(HttpRequest.BodyPublishers.ofString(body)).build(), HttpResponse.BodyHandlers.ofString(),
)

/** docs/API.md "Review sign-in": a server with the review username and password set. */
@TestPropertySource(properties = ["evensies.auth.review-username=$USERNAME", "evensies.auth.review-password=$PASSWORD"])
class ReviewLoginTest : IntegrationTestBase() {
    /** Each test uses its own client IP (Tomcat trusts X-Forwarded-For from localhost), so the per-IP limits don't mix. */
    private fun review(ip: String, body: Any?) = http.send(HttpMethod.POST, "/auth/review", body, headers = mapOf("X-Forwarded-For" to ip))

    private fun review(ip: String, username: String = USERNAME, password: String = PASSWORD) =
        review(ip, mapOf("username" to username, "password" to password))

    @Test
    fun infoSaysItIsOn() = assertTrue(http.get("/info").body["reviewLogin"].asBoolean())

    @Test
    fun aWrongUsernameOrPasswordGetsTheSame401() {
        val wrongUser = review("203.0.113.1", username = "app-reviewer2")
        assertEquals(401, wrongUser.status, wrongUser.text)
        assertEquals("UNAUTHORIZED", wrongUser.code())
        val wrongPassword = review("203.0.113.1", password = "$PASSWORD-")
        assertEquals(401, wrongPassword.status)
        assertEquals(wrongUser.text, wrongPassword.text, "the response doesn't say which part was wrong")
        assertEquals(wrongUser.text, review("203.0.113.1", username = USERNAME.uppercase()).text)
        assertEquals(wrongUser.text, review("203.0.113.1", username = "", password = "").text)
    }

    @Test
    fun theAccountWorksLikeAnyOther() {
        val first = review("203.0.113.2")
        assertEquals(200, first.status, first.text)
        val token = first.body["accessToken"].asString()
        assertTrue(first.body["refreshToken"].asString().isNotEmpty())
        val id = first.body["user"]["id"].asString()
        assertEquals("", first.body["user"]["displayName"].asString(), "the app asks for a name")
        assertEquals(id, myId(token))
        assertEquals(id, review("203.0.113.2", username = " $USERNAME ").body["user"]["id"].asString(), "the same account; the username is trimmed")
        assertEquals(200, http.post("/auth/refresh", mapOf("refreshToken" to first.body["refreshToken"].asString())).status)

        assertEquals(200, http.patch("/me", mapOf("displayName" to "Reviewer"), token).status)
        val email = http.post("/me/email", mapOf("email" to address("Reviewer")), token)
        assertEquals(403, email.status, "reviewers share the account, so it can't hold anyone's address")
        assertEquals("FORBIDDEN", email.code())
        createGroup(token)
        assertEquals(204, http.delete("/me", token).status)

        val again = review("203.0.113.2")
        assertEquals(200, again.status, again.text)
        assertEquals(id, again.body["user"]["id"].asString(), "the same account, reopened")
        assertEquals("", again.body["user"]["displayName"].asString())
        assertEquals(0, http.get("/groups", again.body["accessToken"].asString()).body.size(), "the reopened account is empty")
    }

    @Test
    fun theEleventhAttemptInAMinuteFromOneIpIs429() {
        repeat(10) { assertEquals(401, review("203.0.113.3", password = "wrong").status) }
        val over = review("203.0.113.3")
        assertEquals(429, over.status, "the right password counts too once the IP is over")
        assertEquals("RATE_LIMITED", over.code())
        assertEquals(200, review("203.0.113.4").status, "another IP is not affected")
    }

    @Test
    fun oneIpv6SiteSharesOneLimit() {
        repeat(10) { assertEquals(401, review("2001:db8:1:2::1", password = "wrong").status) }
        assertEquals(429, review("2001:db8:1:2::ffff").status, "the same /64")
        assertEquals(200, review("2001:db8:1:3::1").status, "another /64")
    }

    @Test
    fun missingOrNonStringFieldsAre400() {
        for (body in listOf(
            emptyMap<String, Any?>(), mapOf("username" to USERNAME), mapOf("password" to PASSWORD),
            mapOf("username" to USERNAME, "password" to null), mapOf("username" to 1, "password" to PASSWORD), listOf(USERNAME, PASSWORD),
        )) {
            val res = review("203.0.113.5", body)
            assertEquals(400, res.status, "$body: ${res.text}")
            assertEquals("VALIDATION", res.code())
        }
        assertEquals(400, rawReview(port, "{not json").statusCode())
        val form = rawReview(port, """{"username":"$USERNAME","password":"$PASSWORD"}""", type = "text/plain")
        assertEquals(400, form.statusCode(), "JSON only, so a cross-site form post can't use up the limits")
        assertEquals(400, rawReview(port, " ".repeat(5000) + """{"username":"$USERNAME","password":"$PASSWORD"}""").statusCode(), "at most 4 KB is read")
    }
}

/** A username with a password under 20 characters: the feature stays off and the server warns once, without the values. */
@ExtendWith(OutputCaptureExtension::class)
@TestPropertySource(properties = ["evensies.auth.review-username=$USERNAME", "evensies.auth.review-password=too-short-password"])
class ReviewLoginShortPasswordTest : IntegrationTestBase() {
    @Autowired
    lateinit var auth: AuthService

    @Test
    fun sessionsFromBeforeEndWhenItIsOff() {
        val old = auth.login("review", "review:$USERNAME", "") // signed in while it was on
        val res = http.post("/auth/refresh", mapOf("refreshToken" to old.refreshToken))
        assertEquals(401, res.status, res.text)
        assertEquals(200, http.post("/auth/refresh", mapOf("refreshToken" to http.post("/auth/dev", mapOf("name" to "Other")).body["refreshToken"].asString())).status)
    }

    @Test
    fun itStaysOff(output: CapturedOutput) {
        assertFalse(http.get("/info").body["reviewLogin"].asBoolean())
        val res = http.post("/auth/review", mapOf("username" to USERNAME, "password" to "too-short-password"))
        assertEquals(404, res.status, res.text)
        assertEquals("NOT_FOUND", res.code())
        assertEquals(404, rawReview(port, "{not json").statusCode(), "off means 404 whatever the body")

        assertEquals(1, Regex("review sign-in stays off").findAll(output.all).count(), output.all.takeLast(2000))
        assertFalse(output.all.contains("too-short-password") || output.all.contains(USERNAME), "never log the values")
    }
}
