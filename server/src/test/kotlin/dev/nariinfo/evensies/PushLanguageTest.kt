package dev.nariinfo.evensies

import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.jdbc.core.simple.JdbcClient
import java.util.UUID
import kotlin.test.assertEquals

/**
 * Phase 9: visible push bodies, batch sentences and reminders in each recipient's `users.language` (docs/API.md "Push notifications",
 * "Reminders"); null and languages strings.json lacks are English. Tests run with `evensies.push.batch-seconds=1`.
 */
class PushLanguageTest : IntegrationTestBase() {
    @Autowired
    private lateinit var capture: CapturingPushSender

    @Autowired
    private lateinit var jdbc: JdbcClient

    private class User(val token: String, val device: String, var seen: Int = 0)

    private fun user(name: String, language: String?): User {
        val token = login("$name-${UUID.randomUUID().toString().take(6)}")
        if (language != null) check(http.patch("/me", mapOf("language" to language), token).status == 200)
        check(http.put("/me/notifications", mapOf("expenses" to true, "comments" to true, "members" to false), token).status == 200) // no join pushes, no open batch window
        return User(token, device(token))
    }

    /** Anna's group with the others joined under [names]; returns (groupId, member ids by name). */
    private fun group(anna: User, others: Map<String, User>): Pair<String, Map<String, String>> {
        val id = UUID.randomUUID().toString()
        val annaMember = UUID.randomUUID().toString()
        val g = http.post("/groups", mapOf("id" to id, "name" to "Trip", "defaultCurrency" to "EUR", "memberId" to annaMember, "memberName" to "Anna"), anna.token).body
        val members = mapOf("Anna" to annaMember) + others.mapValues { (name, u) -> join(u.token, g, name) }
        // every join fan-out is done once all of them got the data message of a later no-op
        val seq = push(anna.token, id, event("group.updated", emptyMap())).body["latestSeq"].asLong().toString()
        for (u in others.values) awaitUntil("drain") { capture.to(u.device).any { it.data["seq"] == seq } }
        for (u in others.values) u.seen = capture.to(u.device).size
        return id to members
    }

    /** The next visible body [u] gets. */
    private fun body(u: User): String {
        awaitUntil("a visible push") { capture.to(u.device).drop(u.seen).any { it.body != null } }
        val new = capture.to(u.device).drop(u.seen)
        val i = new.indexOfFirst { it.body != null }
        u.seen += i + 1
        return new[i].body!!
    }

    private fun payment(from: String, to: String, amount: Long) = event(
        "payment.created", mapOf("paymentId" to UUID.randomUUID().toString(), "fromMember" to from, "toMember" to to,
            "amount" to amount, "currency" to "EUR", "date" to "2026-10-11", "status" to "sent"),
    )

    @Test
    fun eachRecipientReadsTheirOwnLanguage() {
        val anna = user("Pl-anna", null)
        val ben = user("Pl-ben", "de")
        val carl = user("Pl-carl", "ko")
        val dora = user("Pl-dora", null)
        val eve = user("Pl-eve", "xx")
        val (id, m) = group(anna, mapOf("Ben" to ben, "Carl" to carl, "Dora" to dora, "Eve" to eve))

        assertEquals(200, push(anna.token, id, expenseCreated(m.getValue("Anna"), 3000, mapOf(m.getValue("Anna") to 1500, m.getValue("Ben") to 1500))).status)
        assertEquals("Anna hat „Dinner“ hinzugefügt · 30,00 € · du schuldest 15,00 €", body(ben))
        assertEquals("Anna added “Dinner” · €30.00", body(dora))
        assertEquals("Anna added “Dinner” · €30.00", body(eve), "a language without strings is English")
        body(carl)

        // inside the batch window: sent when it ends, still per language
        assertEquals(200, push(anna.token, id, payment(m.getValue("Anna"), m.getValue("Carl"), 1200)).status)
        assertEquals("Anna님이 나에게 송금했어요 · €12.00 · 내 확인을 기다리는 중", body(carl))
        assertEquals("Anna paid Carl €12.00 · waiting for Carl to confirm", body(dora))
    }

    @Test
    fun batchesAndTheLanguageAtSendTime() {
        val anna = user("Pl-anna", null)
        val ben = user("Pl-ben", "de")
        val dora = user("Pl-dora", null)
        val (id, m) = group(anna, mapOf("Ben" to ben, "Dora" to dora))
        val a = m.getValue("Anna")
        val b = m.getValue("Ben")

        assertEquals(200, push(anna.token, id, expenseCreated(a, 3000, mapOf(a to 1500, b to 1500)),
            expenseCreated(a, 1800, mapOf(a to 900, b to 900), description = "Taxi")).status)
        assertEquals("Anna hat 2 Ausgaben hinzugefügt", body(ben))
        assertEquals("Anna added 2 expenses", body(dora))

        // Dora switches to German while her next push waits for the window: it goes out in German.
        assertEquals(200, push(anna.token, id, expenseCreated(a, 1000, mapOf(a to 1000), description = "Bus")).status)
        assertEquals(200, http.patch("/me", mapOf("language" to "de"), dora.token).status)
        assertEquals("Anna hat „Bus“ hinzugefügt · 10,00 €", body(dora))
        assertEquals(200, http.patch("/me", mapOf("language" to null), dora.token).status)
        Thread.sleep(1100) // past the window: the next push goes out at once, in English again
        assertEquals(200, push(anna.token, id, expenseCreated(a, 500, mapOf(a to 500), description = "Tea")).status)
        assertEquals("Anna added “Tea” · €5.00", body(dora))
    }

    @Test
    fun remindersAreInTheRecipientsLanguage() {
        val anna = user("Pl-anna", "ko")
        val ben = user("Pl-ben", "de")
        val annaName = http.get("/me", anna.token).body["displayName"].asString()
        val code = http.get("/me/friend-code", ben.token).body["friendCode"].asString()
        val f = http.post("/friends", mapOf("id" to UUID.randomUUID().toString(), "defaultCurrency" to "EUR", "code" to code), anna.token).body
        val fa = f["myMemberId"].asString()
        val fb = snapshot(anna.token, f["id"].asString())["members"].values().single { it["id"].asString() != fa }["id"].asString()
        assertEquals(200, push(anna.token, f["id"].asString(), expenseCreated(fa, 3000, mapOf(fa to 1500, fb to 1500))).status)
        assertEquals(200, http.post("/friends/${myId(ben.token)}/remind", null, anna.token).status)
        awaitUntil("the reminder") { capture.to(ben.device).any { it.data["type"] == "remind" } }
        val push = capture.to(ben.device).single { it.data["type"] == "remind" }
        assertEquals("$annaName hat dich erinnert", push.title, "the recipient's language, not the sender's")
        assertEquals("Du schuldest $annaName 15,00 €.", push.body)

        // A sender without a name: words.someone, upper-cased only at the start.
        jdbc.sql("UPDATE users SET display_name = '' WHERE id = :id").param("id", UUID.fromString(myId(ben.token))).update()
        assertEquals(200, push(ben.token, f["id"].asString(), expenseCreated(fb, 9000, mapOf(fa to 9000))).status)
        assertEquals(200, http.patch("/me", mapOf("language" to null), anna.token).status)
        assertEquals(200, http.post("/friends/${myId(anna.token)}/remind", null, ben.token).status)
        awaitUntil("the reminder") { capture.to(anna.device).any { it.data["type"] == "remind" } }
        val en = capture.to(anna.device).single { it.data["type"] == "remind" }
        assertEquals("Someone sent a reminder", en.title)
        assertEquals("You owe someone €75.00.", en.body, "9000 − 1500")
    }
}
