package dev.nariinfo.evensies

import dev.nariinfo.evensies.activity.Activity
import dev.nariinfo.evensies.activity.Activity.memberOfUser
import dev.nariinfo.evensies.activity.ActivityItem
import dev.nariinfo.evensies.email.DigestBuilder
import dev.nariinfo.evensies.email.DigestGroup
import org.junit.jupiter.api.DynamicTest
import org.junit.jupiter.api.DynamicTest.dynamicTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestFactory
import dev.nariinfo.evensies.sync.EventApplier
import dev.nariinfo.evensies.sync.GroupState
import tools.jackson.databind.JsonNode
import java.time.Instant
import java.time.YearMonth
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/** Email summary goldens (server/src/test/resources/digest-cases.json) and the pure builder's caps. */
class DigestBuilderTest {
    private val fixture = SharedJson.mapper.readTree(javaClass.getResourceAsStream("/digest-cases.json")!!.readAllBytes())

    /** A group's section the way EmailJobs builds it: meta per event, the window's items newest first. */
    private fun group(g: JsonNode, recipient: String, blocked: Set<String>): DigestGroup {
        var state = GroupState()
        val applied = g["events"].values().map { e ->
            val before = state
            state = EventApplier.apply(state, e["type"].asString(), e["payload"])
            e to Activity.meta(before, state, e["type"].asString(), e["payload"], e["actorUserId"].asString())
        }
        val me = state.memberOfUser(recipient)!!
        val items = applied.filter { (e, _) ->
            val actor = e["actorUserId"].asString()
            e["seq"].asLong() > g["windowAfterSeq"].asLong() && actor != recipient && actor !in blocked
        }.mapNotNull { (e, m) ->
            val actor = e["actorUserId"].asString()
            Activity.item(e["seq"].asLong(), e["type"].asString(), e["payload"], actor, Instant.parse("2026-11-01T10:00:00Z"),
                m.copy(actorMemberId = m.actorMemberId ?: state.memberOfUser(actor)), me)
        }.reversed()
        return DigestBuilder.group(state, items, me)
    }

    @TestFactory
    fun goldens(): List<DynamicTest> = fixture["cases"].values().map { case ->
        dynamicTest(case["name"].asString()) {
            val r = case["recipient"]
            val blocked = case["blocked"]?.values()?.map { it.asString() }?.toSet() ?: emptySet()
            val email = DigestBuilder.build(
                r["name"].asString(), r["language"]?.takeUnless { it.isNull }?.asString() ?: "en", case["mode"].asString(),
                auto = case["reason"].asString() == "auto", case["groups"].values().map { group(it, r["userId"].asString(), blocked) },
                "{unsubscribeUrl}", YearMonth.parse(case["month"]?.asString() ?: "2026-11"),
            )
            val want = case["expected"]
            if (want.isNull) return@dynamicTest assertNull(email)
            assertNotNull(email)
            assertEquals(want["subject"].asString(), email.subject)
            assertEquals(want["text"].asString(), email.text)
            assertEquals("{unsubscribeUrl}", email.unsubscribeUrl)
        }
    }

    private fun item(i: Int, comment: String? = null) = ActivityItem(
        seq = i.toLong(), kind = if (comment == null) "expense_deleted" else "comment_added", createdAt = Instant.EPOCH, actorMemberId = "m2",
        expenseId = "x$i", description = "Item\r\n$i", text = comment,
    )

    @Test
    fun thirtyLinesInAllAndUserTextOnOneLine() {
        val groups = (1..4).map { g -> DigestGroup("G$g", (1..10).map { item(it) }, mapOf("m1" to "Anna", "m2" to "Ben\nInjected: x"), "m1") }
        val text = DigestBuilder.build("Anna", "en", "daily", auto = false, groups, "u", YearMonth.of(2026, 11))!!.text
        assertEquals(30, text.lines().count { it.startsWith("• ") })
        assertTrue("…and 10 more in G4" in text, text)
        assertTrue("Item 1" in text && "Ben Injected: x deleted" in text, "CR/LF in user text become spaces")
        val long = "a".repeat(200)
        val one = DigestBuilder.build("Anna", "en", "daily", auto = false, listOf(DigestGroup("G", listOf(item(1, long)), mapOf("m2" to "Ben"), "m1")), "u", YearMonth.of(2026, 11))!!
        assertTrue("a".repeat(79) + "…" in one.text && "a".repeat(80) !in one.text, "comments are cut to 80")
    }

    /** A Hyojun function whose port hasn't landed (null balances) leaves the section out; the lines still go, a quiet month doesn't. */
    @Test
    fun missingBalancesLeaveTheSectionOut() {
        val groups = listOf(DigestGroup("G", listOf(item(1)), mapOf("m2" to "Ben"), "m1", balances = null))
        val email = DigestBuilder.build("Anna", "en", "daily", auto = true, groups, "u", YearMonth.of(2026, 11))!!
        assertTrue("Ben deleted" in email.text && "Your balances" !in email.text, email.text)
        assertNull(DigestBuilder.build("Anna", "en", "monthly", auto = true, listOf(groups[0].copy(items = emptyList())), "u", YearMonth.of(2026, 11)))
    }

    @Test
    fun emptyNameAndAutoMonthlyReason() {
        val groups = listOf(DigestGroup("G", emptyList(), emptyMap(), "m1", balances = mapOf("EUR" to 500L, "USD" to 0L)))
        val email = DigestBuilder.build("", "en", "monthly", auto = true, groups, "u", YearMonth.of(2026, 2))!!
        assertTrue(email.text.startsWith("Hi,\n\nYour balances\n• G: you are owed €5.00\n\n"), email.text)
        assertTrue("You get this monthly summary by default." in email.text)
        assertEquals("Your Evensies summary for February 2026", email.subject)
        assertEquals("2026년 2월 Evensies 요약", DigestBuilder.build("", "ko", "monthly", auto = true, groups, "u", YearMonth.of(2026, 2))!!.subject)
    }
}
