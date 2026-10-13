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

/**
 * shared/activity-cases.json: feed items + English sentences per event log, push batch sentences, money display (M(x)
 * per language) and the localized sentences, batches and reminders (Phase 9).
 */
class ActivityCasesTest {
    private val fixture = SharedJson.load("activity-cases.json")
    private val kotlinMapper = jacksonObjectMapper()

    /** A JSON null is a real null (Phase 8: a repeat added by Evensies), not the text "null". */
    private fun actor(e: JsonNode): String? = e["actorUserId"]?.takeUnless { it.isNull }?.asString()

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
                e to Activity.meta(before, state, e["type"].asString(), e["payload"], actor(e))
            }
            val items = applied.mapNotNull { (e, m) ->
                val actor = actor(e)
                Activity.item(
                    e["seq"].asLong(), e["type"].asString(), e["payload"], actor, Instant.parse(e["createdAt"].asString()),
                    m.copy(actorMemberId = m.actorMemberId ?: state.memberOfUser(actor)), me,
                )
            }.reversed()
            assertEquals(SharedJson.canon(case["expected"]), SharedJson.canon(items.map(::compact)))
            assertEquals(case["texts"].values().map { it.asString() }, items.map { ActivityText.sentence(it, names(case), me, friend = state.kind == "friend") })
        }
    }

    /** A friend group's name ("Anna & Ben") is internal: deleting a friend reads as their non-group expenses. */
    @Test
    fun friendGroupDeleteAndRestoreDontShowTheInternalName() {
        val names = mapOf("m1" to "Anna", "m2" to "Ben")
        val deleted = ActivityItem(seq = 4, kind = "group_deleted", createdAt = Instant.EPOCH, actorMemberId = "m1", name = "Anna & Ben")
        val restored = deleted.copy(seq = 5, kind = "group_restored")
        assertEquals("Anna deleted your non-group expenses", ActivityText.sentence(deleted, names, "m2", friend = true))
        assertEquals("You deleted these non-group expenses", ActivityText.sentence(deleted, names, "m1", friend = true))
        assertEquals("Anna restored your non-group expenses", ActivityText.body(listOf(restored), names, "m2", friend = true))
        assertEquals("Anna님이 그룹 밖 지출을 삭제했어요", ActivityText.sentence(deleted, names, "m2", "ko", friend = true))
        assertEquals("Anna deleted the group “Anna & Ben”", ActivityText.sentence(deleted, names, "m2"), "a real group keeps its name")
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
        val lang = m["lang"]?.asString() ?: "en"
        dynamicTest("$lang ${m["text"].asString()}") {
            assertEquals(m["text"].asString(), Money.display(m["minor"].asLong(), m["currency"].asString(), lang))
        }
    }

    /** One item: its sentence; more: the push batch sentence; `remind`: the reminder push title and body. */
    @TestFactory
    fun localized(): List<DynamicTest> = fixture["localized"].values().map { case ->
        dynamicTest(case["name"].asString()) {
            val lang = case["lang"].asString()
            val remind = case["remind"]
            if (remind != null) {
                val amounts = remind["amounts"].values().map { it["currency"].asString() to it["amount"].asLong() }
                val (title, body) = ActivityText.reminder(remind["from"].asString(), amounts, lang)
                assertEquals(case["title"].asString(), title)
                assertEquals(case["text"].asString(), body)
                return@dynamicTest
            }
            val items = case["items"].values().map { kotlinMapper.treeToValue(it, ActivityItem::class.java) }
            val me = case["me"].asString()
            val text = if (items.size == 1) ActivityText.sentence(items[0], names(case), me, lang) else ActivityText.body(items, names(case), me, lang)
            assertEquals(case["text"].asString(), text)
        }
    }

    /** Push title/body clipping (docs/API.md "Push notifications"): "…" counts toward the limit and a surrogate pair is never split. */
    @Test
    fun clip() {
        assertEquals("abc", "abc".clip(3))
        assertEquals("ab…", "abcd".clip(3))
        assertEquals("a…", "a😀b".clip(3))
        assertEquals("a😀…", "a😀bc".clip(4))
    }
}
