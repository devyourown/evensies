package dev.nariinfo.evensies

import dev.nariinfo.evensies.sync.EventApplier
import dev.nariinfo.evensies.sync.GroupState
import org.junit.jupiter.api.DynamicTest
import org.junit.jupiter.api.DynamicTest.dynamicTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestFactory
import tools.jackson.databind.JsonNode
import tools.jackson.databind.node.ObjectNode
import java.nio.file.Files
import kotlin.random.Random
import kotlin.test.assertEquals

class EventApplierTest {
    private fun applyAll(events: List<JsonNode>, start: GroupState = GroupState()): GroupState =
        events.fold(start) { s, e -> EventApplier.apply(s, e["type"].asString(), e["payload"]) }

    private fun actual(s: GroupState) = SharedJson.canon(
        mapOf("members" to s.members.values, "expenses" to s.expenses.values, "payments" to s.payments.values, "comments" to s.comments.values)
    )

    /** Missing expected values are defaults (fixture _doc): removed=false, notes=null, comments=[]. */
    private fun expected(node: JsonNode): String {
        val copy = node.deepCopy() as ObjectNode
        for (m in copy["members"]) if (!m.has("removed")) (m as ObjectNode).put("removed", false)
        for (e in copy["expenses"]) if (!e.has("notes")) (e as ObjectNode).putNull("notes")
        if (!copy.has("comments")) copy.putArray("comments")
        return SharedJson.canon(copy)
    }

    @TestFactory
    fun sharedSyncCases(): List<DynamicTest> = SharedJson.load("sync-cases.json")["cases"].values().map { case ->
        dynamicTest(case["name"].asString()) {
            val events = case["events"].values().sortedBy { it["seq"].asLong() }
            val want = expected(case["expected"])
            assertEquals(want, actual(applyAll(events)), "in seq order")
            assertEquals(want, actual(applyAll(events.flatMap { listOf(it, it) })), "each event applied twice")
            assertEquals(want, actual(applyAll(events, applyAll(events))), "whole sequence applied twice")
            if (case["permute"]?.asBoolean() == true) {
                val rnd = Random(42)
                repeat(20) {
                    val delivered = events.shuffled(rnd).sortedBy { it["seq"].asLong() }
                    assertEquals(want, actual(applyAll(delivered)), "shuffled delivery, applied by seq")
                }
            }
        }
    }

    @Test
    fun currenciesResourceMatchesShared() {
        val resource = javaClass.getResourceAsStream("/currencies.json")!!.readAllBytes().decodeToString()
        assertEquals(Files.readString(SharedJson.path("currencies.json")), resource, "copy shared/currencies.json to server/src/main/resources/currencies.json")
    }
}
