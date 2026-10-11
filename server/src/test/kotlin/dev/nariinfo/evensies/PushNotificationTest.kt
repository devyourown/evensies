package dev.nariinfo.evensies

import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.test.fail

/**
 * Push fan-out through the captured [CapturingPushSender] (docs/API.md "푸시", "알림 설정").
 * Tests run with `evensies.push.batch-seconds=1`.
 */
class PushNotificationTest : IntegrationTestBase() {
    @Autowired
    private lateinit var capture: CapturingPushSender

    @Autowired
    private lateinit var jdbc: JdbcClient

    private class User(val token: String, val device: String, var seen: Int = 0)

    private class Setup(val id: String, val anna: User, val ben: User, val carla: User, val a: String, val b: String, val c: String)

    private val allOn = mapOf("expenses" to true, "comments" to true, "members" to true)

    private fun user(name: String): User {
        val token = login(name)
        val device = "tok-${UUID.randomUUID()}"
        check(http.post("/devices", mapOf("deviceId" to UUID.randomUUID().toString(), "fcmToken" to device), token).status == 204)
        return User(token, device)
    }

    private fun prefs(u: User, p: Map<String, Any?>) = http.put("/me/notifications", p, u.token)

    /**
     * Anna's group "Trip" with Ben and Carla. Joins happen with member pushes off so that no visible push (and no batch
     * window) is left over; [drain] then guarantees every setup fan-out is done before the test starts counting.
     */
    private fun setup(tag: String): Setup {
        val anna = user("Pn-anna-$tag")
        val ben = user("Pn-ben-$tag")
        val carla = user("Pn-carla-$tag")
        for (u in listOf(anna, ben, carla)) check(prefs(u, allOn + ("members" to false)).status == 200)
        val group = createGroup(anna.token)
        val b = join(ben.token, group, "Ben")
        val c = join(carla.token, group, "Carla")
        val s = Setup(group["id"].asString(), anna, ben, carla, group["myMemberId"].asString(), b, c)
        drain(s, ben, carla)
        for (u in listOf(anna, ben, carla)) {
            check(prefs(u, allOn).status == 200)
            u.seen = capture.to(u.device).size
        }
        return s
    }

    /** Messages a user got since the last [take]. */
    private fun take(u: User): List<CapturingPushSender.Sent> = capture.to(u.device).drop(u.seen).also { u.seen += it.size }

    private fun await(what: String, check: () -> Boolean) {
        val end = System.currentTimeMillis() + 5000
        while (System.currentTimeMillis() < end) {
            if (check()) return
            Thread.sleep(20)
        }
        fail("Timed out waiting for $what")
    }

    private fun awaitNew(u: User, count: Int): List<CapturingPushSender.Sent> {
        await("$count new message(s)") { capture.to(u.device).size - u.seen >= count }
        return take(u)
    }

    /** Anna pushes a hidden no-op; the notifier runs fan-outs in order, so once [observers] got it, all earlier ones are done. */
    private fun drain(s: Setup, vararg observers: User) {
        val seq = push(s.anna.token, s.id, event("group.updated", emptyMap())).body["latestSeq"].asLong().toString()
        for (u in observers) await("drain marker") { capture.to(u.device).drop(u.seen).any { it.data["seq"] == seq } }
    }

    private fun expense(s: Setup, shares: Map<String, Long>, description: String = "Dinner", expenseId: String = UUID.randomUUID().toString()) =
        expenseCreated(s.a, shares.values.sum(), shares, expenseId = expenseId, description = description)

    private fun comment(expenseId: String, author: String, text: String) = event(
        "comment.added", mapOf("commentId" to UUID.randomUUID().toString(), "expenseId" to expenseId, "authorMemberId" to author,
            "text" to text, "createdAt" to "2026-10-11T09:00:00Z"),
    )

    private fun assertDataOnly(m: CapturingPushSender.Sent, groupId: String) {
        assertNull(m.title)
        assertNull(m.body)
        assertEquals("sync", m.data["type"])
        assertEquals(groupId, m.data["groupId"])
    }

    /** The next visible body [u] gets (a push inside the batch window first sends data-only, then the batch). */
    private fun awaitBody(u: User): String {
        await("a visible push") { capture.to(u.device).drop(u.seen).any { it.body != null } }
        return take(u).first { it.body != null }.body!!
    }

    /** Phase 3: settings changes and leaving are `members` pushes; a refund's myDelta is reversed in the sentence. */
    @Test
    fun settingsLeavingAndRefundsArePushed() {
        val s = setup("phase3")
        push(s.anna.token, s.id, event("group.updated", mapOf("simplifyDebts" to false)))
        assertEquals("Me changed the group: simplify debts off", awaitBody(s.ben))
        assertEquals("Me changed the group: simplify debts off", awaitBody(s.carla))

        push(s.anna.token, s.id, expenseCreated(s.a, 600, mapOf(s.a to 300, s.b to 300), description = "Refund",
            extra = mapOf("payers" to lines(mapOf(s.a to 600)), "refund" to true)))
        assertEquals("Me added a refund “Refund” · €6.00 · you get back €3.00", awaitBody(s.ben), "−1 × (0 − 300)")

        push(s.carla.token, s.id, event("member.removed", mapOf("memberId" to s.c)))
        assertEquals("Carla left the group", awaitBody(s.anna))
        assertEquals("Carla left the group", awaitBody(s.ben))
    }

    @Test
    fun othersGetTheirOwnSentenceAndTheActorNothing() {
        val s = setup("fan")
        val res = push(s.anna.token, s.id, expense(s, mapOf(s.a to 1500, s.b to 1000, s.c to 500)))
        val seq = res.body["latestSeq"].asLong().toString()

        val ben = awaitNew(s.ben, 1).single()
        assertEquals("Trip", ben.title)
        assertEquals("Me added “Dinner” · €30.00 · you owe €10.00", ben.body)
        assertEquals(mapOf("type" to "sync", "groupId" to s.id, "seq" to seq), ben.data)
        assertEquals("Me added “Dinner” · €30.00 · you owe €5.00", awaitNew(s.carla, 1).single().body)

        // a removed member is no longer a recipient
        push(s.anna.token, s.id, event("member.removed", mapOf("memberId" to s.c)))
        push(s.anna.token, s.id, expense(s, mapOf(s.a to 100, s.b to 100)))
        drain(s, s.ben)
        assertEquals(emptyList(), take(s.carla))
        assertEquals(emptyList(), take(s.anna), "the actor never gets a push for their own change")
    }

    @Test
    fun preferencesTurnVisiblePushesIntoDataOnly() {
        val s = setup("prefs")
        assertEquals(SharedJson.canon(allOn), SharedJson.canon(http.get("/me/notifications", s.ben.token).body))
        val off = mapOf("expenses" to false, "comments" to true, "members" to false)
        assertEquals(SharedJson.canon(off), SharedJson.canon(prefs(s.ben, off).body))
        assertEquals(SharedJson.canon(off), SharedJson.canon(http.get("/me/notifications", s.ben.token).body))

        // expenses off: data-only; Carla (all on) still sees it
        val x = UUID.randomUUID().toString()
        push(s.anna.token, s.id, expense(s, mapOf(s.a to 1000, s.b to 1000), expenseId = x))
        assertDataOnly(awaitNew(s.ben, 1).single(), s.id)
        assertEquals("Trip", awaitNew(s.carla, 1).single().title)

        // comments on: visible
        push(s.anna.token, s.id, comment(x, s.a, "Receipt is in the car"))
        assertEquals("Me commented on “Dinner”: Receipt is in the car", awaitNew(s.ben, 1).single().body)

        // members off: data-only for a new placeholder; payments count as expenses
        prefs(s.ben, mapOf("expenses" to false, "comments" to false, "members" to false))
        push(s.anna.token, s.id, memberAdded("Dario"))
        push(s.anna.token, s.id, event("payment.created", mapOf("paymentId" to UUID.randomUUID().toString(), "fromMember" to s.b,
            "toMember" to s.a, "amount" to 500, "currency" to "EUR", "date" to "2026-10-11")))
        push(s.anna.token, s.id, comment(x, s.a, "Second"))
        awaitNew(s.ben, 3).forEach { assertDataOnly(it, s.id) }

        // validation: all three keys, real booleans
        for (bad in listOf<Any>(mapOf("expenses" to true, "comments" to true), allOn + ("members" to "false"), allOn + ("members" to 1),
            allOn + ("members" to null), listOf(true, true, true))) {
            val res = http.put("/me/notifications", bad, s.ben.token)
            assertEquals(400, res.status, "$bad")
            assertEquals("VALIDATION", res.code())
        }
        assertEquals(401, http.get("/me/notifications").status)
        assertEquals(401, http.put("/me/notifications", allOn).status)

        // account deletion removes the stored preferences
        val benId = UUID.fromString(myId(s.ben.token))
        assertEquals(204, http.delete("/me", s.ben.token).status)
        assertEquals(0L, jdbc.sql("SELECT count(*) FROM notification_prefs WHERE user_id = :u").param("u", benId).query(Long::class.java).single())
    }

    @Test
    fun burstsWithinTheWindowAreBatched() {
        val s = setup("batch")
        val x = UUID.randomUUID().toString()
        // one push with two expenses: visible at once, as one batch sentence
        push(s.anna.token, s.id, expense(s, mapOf(s.a to 1000, s.b to 1000), expenseId = x), expense(s, mapOf(s.a to 500, s.b to 500), "Taxi"))
        val first = awaitNew(s.ben, 1).single()
        assertEquals("Me added 2 expenses", first.body)
        assertEquals("Me added 2 expenses", awaitNew(s.carla, 1).single().body)

        // inside the window: data-only now, one visible push when it ends
        val started = System.currentTimeMillis()
        push(s.anna.token, s.id, expense(s, mapOf(s.a to 300, s.b to 300), "Bus"))
        push(s.anna.token, s.id, comment(x, s.a, "Who paid the tip?"))
        push(s.ben.token, s.id, comment(x, s.b, "I did")) // a second actor, for Carla's batch
        val now = awaitNew(s.ben, 2)
        now.forEach { assertDataOnly(it, s.id) }
        val batched = awaitNew(s.ben, 1).single()
        assertTrue(System.currentTimeMillis() - started >= 500, "the batch waits for the window")
        assertEquals("Trip", batched.title)
        assertEquals("Me made 2 changes", batched.body, "Ben's own comment is not in his batch")
        assertEquals("sync", batched.data["type"])

        val carla = awaitNew(s.carla, 4)
        carla.take(3).forEach { assertDataOnly(it, s.id) }
        assertEquals("3 new changes", carla.last().body)
    }

    @Test
    fun aRetryThatStoresNothingSendsNothing() {
        val s = setup("retry")
        val e = expense(s, mapOf(s.a to 1000, s.b to 1000))
        push(s.anna.token, s.id, e)
        assertEquals("Trip", awaitNew(s.ben, 1).single().title)
        assertEquals(200, push(s.anna.token, s.id, e).status)
        drain(s, s.ben)
        val after = take(s.ben)
        assertEquals(1, after.size, "only the drain marker: $after")
        assertDataOnly(after.single(), s.id)
    }

    /** FCM refuses multicasts over 500 tokens (the capture enforces it), so one user's 600 rows must not mute the bucket. */
    @Test
    fun manyTokensGoInChunksAndDeadOnesArePruned() {
        val s = setup("chunks")
        val ben = UUID.fromString(myId(s.ben.token))
        val fake = (1..600).map { "fake-$it-${UUID.randomUUID()}" }
        for (t in fake) {
            jdbc.sql("INSERT INTO devices (id, user_id, fcm_token) VALUES (:id, :u, :t)").param("id", t).param("u", ben).param("t", t).update()
        }
        capture.dead += fake
        val start = capture.sent.size
        push(s.anna.token, s.id, expense(s, mapOf(s.a to 1000, s.b to 1000)))
        assertEquals("Me added “Dinner” · €20.00 · you owe €10.00", awaitNew(s.ben, 1).single().body)
        await("all 601 of Ben's tokens") { capture.sent.drop(start).flatMap { it.tokens }.toSet().containsAll(fake) }
        assertTrue(capture.sent.drop(start).all { it.tokens.size <= 500 })
        // FCM reported the fakes as dead: only Ben's real device is left
        await("dead tokens deleted") {
            jdbc.sql("SELECT fcm_token FROM devices WHERE user_id = :u").param("u", ben).query(String::class.java).list() == listOf(s.ben.device)
        }
    }

    @Test
    fun aUserKeepsOnlyTheirTenLatestDevices() {
        val token = login("Pn-devices")
        val user = UUID.fromString(myId(token))
        val tokens = (1..12).map { "tok-$it-${UUID.randomUUID()}" }
        for (t in tokens) check(http.post("/devices", mapOf("deviceId" to UUID.randomUUID().toString(), "fcmToken" to t), token).status == 204)
        val left = jdbc.sql("SELECT fcm_token FROM devices WHERE user_id = :u").param("u", user).query(String::class.java).list()
        assertEquals(tokens.drop(2).toSet(), left.toSet())
        // Someone else signs in on the phone that holds the newest token: it leaves this user.
        val other = login("Pn-devices-next")
        check(http.post("/devices", mapOf("deviceId" to UUID.randomUUID().toString(), "fcmToken" to tokens.last()), other).status == 204)
        val now = jdbc.sql("SELECT fcm_token FROM devices WHERE user_id = :u").param("u", user).query(String::class.java).list()
        assertEquals(tokens.drop(2).dropLast(1).toSet(), now.toSet())
    }

    /** Sign-out removes only the caller's own row for that phone: nothing reaches it any more, not even data messages. */
    @Test
    fun signingOutUnregistersThePhone() {
        val s = setup("sign-out")
        val ben = UUID.fromString(myId(s.ben.token))
        val deviceId = jdbc.sql("SELECT id FROM devices WHERE fcm_token = :t").param("t", s.ben.device).query(String::class.java).single()
        assertEquals(204, http.delete("/devices/$deviceId", s.anna.token).status) // not Anna's phone: no-op
        assertEquals(listOf(s.ben.device), jdbc.sql("SELECT fcm_token FROM devices WHERE user_id = :u").param("u", ben).query(String::class.java).list())
        assertEquals(204, http.delete("/devices/$deviceId", s.ben.token).status)
        assertEquals(204, http.delete("/devices/$deviceId", s.ben.token).status) // again: still 204
        assertEquals(401, http.delete("/devices/$deviceId").status)
        push(s.anna.token, s.id, expense(s, mapOf(s.a to 1000, s.b to 1000)))
        awaitNew(s.carla, 1)
        drain(s, s.carla)
        assertEquals(emptyList(), take(s.ben))
    }

    /** A long comment must not push the message past FCM's 4096-byte limit (the sync data would be lost with it). */
    @Test
    fun longTextIsClipped() {
        val s = setup("clip")
        val x = UUID.randomUUID().toString()
        push(s.anna.token, s.id, expense(s, mapOf(s.a to 1000, s.b to 1000), description = "저녁".repeat(100), expenseId = x))
        assertEquals(200, awaitNew(s.ben, 1).single().body!!.length)
        Thread.sleep(1100) // past the 1-second batch window
        push(s.anna.token, s.id, comment(x, s.a, "가".repeat(1000)))
        val body = awaitNew(s.ben, 1).single().body!!
        assertEquals(200, body.length)
        assertTrue(body.startsWith("Me commented on “저녁") && body.endsWith("…"), body)
    }

    /** Offline, a comment can be added and deleted in one push: nobody gets its text. */
    @Test
    fun aCommentDeletedInTheSamePushIsNotAnnounced() {
        val s = setup("taken-back")
        val x = UUID.randomUUID().toString()
        push(s.anna.token, s.id, expense(s, mapOf(s.a to 1000, s.b to 1000), expenseId = x))
        awaitNew(s.ben, 1)
        Thread.sleep(1100)
        val c = comment(x, s.a, "Ben still owes me for the hotel")
        @Suppress("UNCHECKED_CAST")
        val commentId = (c["payload"] as Map<String, Any?>)["commentId"]
        push(s.anna.token, s.id, c, event("comment.deleted", mapOf("commentId" to commentId)))
        assertDataOnly(awaitNew(s.ben, 1).single(), s.id)
    }
}
