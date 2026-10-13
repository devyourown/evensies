package dev.nariinfo.evensies

import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import tools.jackson.databind.JsonNode
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** POST /friends/{userId}/remind (docs/API.md "Reminders") and the `reminders` notification switch. */
class ReminderTest : IntegrationTestBase() {
    @Autowired
    private lateinit var capture: CapturingPushSender

    private class Person(val token: String, val id: String, val name: String, val device: String)

    private fun person(name: String): Person {
        val token = login("$name-${UUID.randomUUID().toString().take(6)}")
        return Person(token, myId(token), http.get("/me", token).body["displayName"].asString(), device(token))
    }

    private fun remind(from: Person, to: String) = http.post("/friends/$to/remind", null, from.token)

    /** A friend group of [a] and [b] in [currency]; returns (groupId, a's member, b's member). */
    private fun friends(a: Person, b: Person, currency: String = "EUR"): Triple<String, String, String> {
        val code = http.get("/me/friend-code", b.token).body["friendCode"].asString()
        val g = http.post("/friends", mapOf("id" to UUID.randomUUID().toString(), "defaultCurrency" to currency, "code" to code), a.token).body
        val am = g["myMemberId"].asString()
        return Triple(g["id"].asString(), am, snapshot(a.token, g["id"].asString())["members"].values().single { it["id"].asString() != am }["id"].asString())
    }

    /** [b] joins a new group of [a]'s; returns (group, a's member, b's member). */
    private fun shared(a: Person, b: Person, currency: String = "EUR"): Triple<JsonNode, String, String> {
        val g = createGroup(a.token, currency = currency)
        return Triple(g, g["myMemberId"].asString(), join(b.token, g, "B"))
    }

    private fun reminders(p: Person) = capture.to(p.device).filter { it.data["type"] == "remind" }

    @Test
    fun owedAcrossAFriendAndASharedGroupInTwoCurrencies() {
        val anna = person("Rm-anna")
        val ben = person("Rm-ben")
        val (f, fa, fb) = friends(anna, ben)
        assertEquals(200, push(anna.token, f, expenseCreated(fa, 3000, mapOf(fa to 1500, fb to 1500))).status)
        val (g, ga, gb) = shared(anna, ben, "USD")
        assertEquals(200, push(anna.token, g["id"].asString(), expenseCreated(ga, 2400, mapOf(ga to 1200, gb to 1200), currency = "USD")).status)

        val res = remind(anna, ben.id)
        assertEquals(200, res.status, res.text)
        assertEquals(SharedJson.canon(mapOf("amounts" to listOf(mapOf("currency" to "EUR", "amount" to 1500), mapOf("currency" to "USD", "amount" to 1200)))),
            SharedJson.canon(res.body))
        awaitUntil("the reminder push") { reminders(ben).isNotEmpty() }
        val push = reminders(ben).single()
        assertEquals("${anna.name} sent a reminder", push.title)
        assertEquals("You owe ${anna.name} €15.00 and $12.00.", push.body)
        assertEquals(mapOf("type" to "remind", "fromUserId" to anna.id), push.data)
        assertNull(push.badge)

        // once a day per pair
        val again = remind(anna, ben.id)
        assertEquals(429, again.status)
        assertEquals("RATE_LIMITED", again.code())
        val retryAfter = again.headers.getValue("retry-after").toLong()
        assertTrue(retryAfter in 86_000..86_400, "$retryAfter")
        Thread.sleep(300)
        assertEquals(1, reminders(ben).size)

        // Ben owes nothing back: his reminder to Anna is 409, and so is one to someone he owes
        assertEquals("NOTHING_OWED", remind(ben, anna.id).code())
        assertEquals(409, remind(ben, anna.id).status)
    }

    @Test
    fun nothingOwedDoesNotUseTheDaysSlot() {
        val anna = person("Rm-anna")
        val carla = person("Rm-carla")
        val (g, a, c) = shared(anna, carla)
        val id = g["id"].asString()
        assertEquals(409, remind(anna, carla.id).status)
        // settled exactly: still nothing
        assertEquals(200, push(anna.token, id, expenseCreated(a, 1000, mapOf(a to 500, c to 500)),
            event("payment.created", mapOf("paymentId" to UUID.randomUUID().toString(), "fromMember" to c, "toMember" to a,
                "amount" to 500, "currency" to "EUR", "date" to "2026-10-11"))).status)
        assertEquals("NOTHING_OWED", remind(anna, carla.id).code())
        assertEquals(200, push(anna.token, id, expenseCreated(a, 3000, mapOf(a to 1000, c to 2000), currency = "CHF")).status)
        val ok = remind(anna, carla.id)
        assertEquals(200, ok.status, ok.text)
        assertEquals("CHF", ok.body["amounts"].single()["currency"].asString())
        // three currencies: "…, … and more." (a new pair, so a fresh slot)
        val dario = person("Rm-dario")
        val (h, ha, hd) = shared(anna, dario)
        for (cur in listOf("EUR", "JPY", "USD")) assertEquals(200, push(anna.token, h["id"].asString(), expenseCreated(ha, 2000, mapOf(hd to 2000), currency = cur)).status)
        assertEquals(200, remind(anna, dario.id).status)
        awaitUntil("Dario's reminder") { reminders(dario).isNotEmpty() }
        assertEquals("You owe ${anna.name} €20.00, ¥2,000 and more.", reminders(dario).single().body)
    }

    @Test
    fun whoCanBeReminded() {
        val anna = person("Rm-anna")
        val stranger = person("Rm-stranger")
        assertEquals(403, remind(anna, stranger.id).status)
        assertEquals(403, remind(anna, anna.id).status)
        assertEquals(403, remind(anna, UUID.randomUUID().toString()).status)
        assertEquals(401, http.post("/friends/${stranger.id}/remind", null).status)

        // a removed member still counts; a placeholder friend is not a user
        val ben = person("Rm-ben")
        val (g, a, b) = shared(anna, ben)
        val id = g["id"].asString()
        assertEquals(200, push(anna.token, id, expenseCreated(a, 1000, mapOf(b to 1000))).status)
        assertEquals(200, push(ben.token, id, event("member.removed", mapOf("memberId" to b))).status)
        assertEquals(200, remind(anna, ben.id).status)
    }

    /** reminders=false: the same 200, no push. PUT without `reminders` (a Phase 2–5 app) keeps the stored value. */
    @Test
    fun theRecipientCanTurnRemindersOff() {
        val anna = person("Rm-anna")
        val erik = person("Rm-erik")
        val on = mapOf("expenses" to true, "comments" to true, "members" to true)
        assertEquals(true, http.get("/me/notifications", erik.token).body["reminders"].asBoolean())
        assertEquals(false, http.put("/me/notifications", on + ("reminders" to false), erik.token).body["reminders"].asBoolean())
        assertEquals(false, http.put("/me/notifications", on, erik.token).body["reminders"].asBoolean(), "missing = unchanged")
        assertEquals(false, http.get("/me/notifications", erik.token).body["reminders"].asBoolean())
        for (bad in listOf<Any?>(null, "false", 0)) {
            val res = http.put("/me/notifications", on + ("reminders" to bad), erik.token)
            assertEquals(400 to "VALIDATION", res.status to res.code(), "$bad")
        }

        val (g, a, e) = shared(anna, erik)
        val id = g["id"].asString()
        assertEquals(200, push(anna.token, id, expenseCreated(a, 1000, mapOf(e to 1000))).status)
        assertEquals(200, remind(anna, erik.id).status)
        // the notifier works in order: once Erik got the sync for a later push, a reminder would have arrived before it
        val seq = push(anna.token, id, event("group.updated", emptyMap())).body["latestSeq"].asLong().toString()
        awaitUntil("Erik's sync") { capture.to(erik.device).any { it.data["seq"] == seq } }
        assertEquals(emptyList(), reminders(erik))
    }

    /** Phase 4 buckets: a foreign expense with a rate counts in the group currency, one without stays in its own. */
    @Test
    fun foreignExpensesFollowTheCurrencyBuckets() {
        val anna = person("Rm-anna")
        val ben = person("Rm-ben")
        val (g, a, b) = shared(anna, ben)
        assertEquals(200, push(anna.token, g["id"].asString(),
            expenseCreated(a, 3000, mapOf(b to 3000), currency = "JPY", extra = mapOf("fxRateToDefault" to 0.0061)),
            expenseCreated(a, 1000, mapOf(b to 1000), currency = "JPY"),
        ).status)
        val res = remind(anna, ben.id)
        assertEquals(200, res.status, res.text)
        assertEquals(SharedJson.canon(listOf(mapOf("currency" to "EUR", "amount" to 1830), mapOf("currency" to "JPY", "amount" to 1000))),
            SharedJson.canon(res.body["amounts"]), "¥3,000 × 0.0061 = €18.30")
    }
}
