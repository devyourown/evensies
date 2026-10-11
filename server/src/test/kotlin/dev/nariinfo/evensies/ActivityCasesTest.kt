package dev.nariinfo.evensies

import dev.nariinfo.evensies.activity.Activity
import dev.nariinfo.evensies.activity.Activity.memberOfUser
import dev.nariinfo.evensies.activity.ActivityItem
import dev.nariinfo.evensies.activity.ActivityText
import dev.nariinfo.evensies.activity.clip
import dev.nariinfo.evensies.money.Money
import dev.nariinfo.evensies.sync.EventApplier
import dev.nariinfo.evensies.sync.GroupState
import org.junit.jupiter.api.DynamicTest
import org.junit.jupiter.api.DynamicTest.dynamicTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestFactory
import tools.jackson.databind.JsonNode
import tools.jackson.databind.node.ObjectNode
import tools.jackson.module.kotlin.jacksonObjectMapper
import java.time.Instant
import kotlin.test.assertEquals

/** shared/activity-cases.json: feed items + English sentences per event log, push batch sentences, money display. */
class ActivityCasesTest {
    private val fixture = SharedJson.load("activity-cases.json")
    private val kotlinMapper = jacksonObjectMapper()

    private fun names(case: JsonNode) = case["names"].properties().associate { (k, v) -> k to v.asString() }

    /** Fixture items omit null keys and empty changes and have no DB values (groupId, feedId). */
    private fun compact(item: ActivityItem): JsonNode {
        val node = SharedJson.mapper.valueToTree<ObjectNode>(item)
        for (k in node.propertyNames().toList()) if (node[k].isNull || k == "groupId" || k == "feedId") node.remove(k)
        if (node["changes"].isEmpty) node.remove("changes")
        return node
    }

    @TestFactory
    fun feedCases(): List<DynamicTest> = fixture["cases"].values().map { case ->
        dynamicTest(case["name"].asString()) {
            val me = case["me"].asString()
            var state = GroupState()
            val applied = case["events"].values().map { e ->
                val before = state
                state = EventApplier.apply(state, e["type"].asString(), e["payload"])
                e to Activity.meta(before, state, e["type"].asString(), e["payload"], e["actorUserId"].asString())
            }
            val items = applied.mapNotNull { (e, m) ->
                val actor = e["actorUserId"].asString()
                Activity.item(
                    e["seq"].asLong(), e["type"].asString(), e["payload"], actor, Instant.parse(e["createdAt"].asString()),
                    m.copy(actorMemberId = m.actorMemberId ?: state.memberOfUser(actor)), me,
                )
            }.reversed()
            assertEquals(SharedJson.canon(case["expected"]), SharedJson.canon(items.map(::compact)))
            assertEquals(case["texts"].values().map { it.asString() }, items.map { ActivityText.sentence(it, names(case), me) })
        }
    }

    @TestFactory
    fun pushBatches(): List<DynamicTest> = fixture["batches"].values().map { case ->
        dynamicTest(case["name"].asString()) {
            val items = case["items"].values().map { kotlinMapper.treeToValue(it, ActivityItem::class.java) }
            assertEquals(case["text"].asString(), ActivityText.body(items, names(case), case["me"].asString()))
        }
    }

    @TestFactory
    fun money(): List<DynamicTest> = fixture["money"].values().map { m ->
        dynamicTest(m["text"].asString()) {
            assertEquals(m["text"].asString(), Money.display(m["minor"].asLong(), m["currency"].asString()))
        }
    }

    /** Push title/body clipping (docs/API.md "푸시"): "…" counts toward the limit and a surrogate pair is never split. */
    @Test
    fun clip() {
        assertEquals("abc", "abc".clip(3))
        assertEquals("ab…", "abcd".clip(3))
        assertEquals("a…", "a😀b".clip(3))
        assertEquals("a😀…", "a😀bc".clip(4))
    }
}
