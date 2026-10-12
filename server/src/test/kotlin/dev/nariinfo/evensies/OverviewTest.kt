package dev.nariinfo.evensies

import dev.nariinfo.evensies.money.Balances
import dev.nariinfo.evensies.money.GroupLedger
import dev.nariinfo.evensies.money.Overview
import dev.nariinfo.evensies.sync.EventApplier
import dev.nariinfo.evensies.sync.GroupState
import org.junit.jupiter.api.DynamicTest
import org.junit.jupiter.api.DynamicTest.dynamicTest
import org.junit.jupiter.api.TestFactory
import tools.jackson.databind.JsonNode
import tools.jackson.databind.node.ObjectNode
import kotlin.test.assertEquals

/**
 * shared/overview-cases.json: snapshot-shaped groups → Balances.ofGroup → Balances.transfers → GroupLedger → Overview,
 * plus the invariant owedToMe − iOwe = the sum of my members' balances per currency.
 */
class OverviewTest {
    /** Builds the state through the applier, so the fixture's defaults are the event defaults. */
    private fun state(g: JsonNode): GroupState {
        val m = SharedJson.mapper
        val events = mutableListOf<Pair<String, JsonNode>>()
        fun add(type: String, payload: Any) { events += type to m.valueToTree(payload) }
        add("group.created", mapOf("name" to g["id"].asString(), "defaultCurrency" to g["defaultCurrency"].asString(), "kind" to g["kind"].asString()))
        g["simplifyDebts"]?.let { add("group.updated", mapOf("simplifyDebts" to it.asBoolean())) }
        for (x in g["members"]) {
            add("member.added", mapOf("memberId" to x["id"].asString(), "name" to x["name"].asString(), "userId" to x["userId"]?.takeUnless { it.isNull }?.asString()))
            if (x["removed"]?.asBoolean() == true) add("member.removed", mapOf("memberId" to x["id"].asString()))
        }
        for (x in g["expenses"]) {
            add("expense.created", (x.deepCopy() as ObjectNode).put("expenseId", x["id"].asString()))
            if (x["deleted"]?.asBoolean() == true) add("expense.deleted", mapOf("expenseId" to x["id"].asString()))
        }
        for (x in g["payments"]) {
            add("payment.created", (x.deepCopy() as ObjectNode).put("paymentId", x["id"].asString()))
            if (x["deleted"]?.asBoolean() == true) add("payment.deleted", mapOf("paymentId" to x["id"].asString()))
        }
        return events.fold(GroupState()) { s, (type, p) -> EventApplier.apply(s, type, p) }
    }

    @TestFactory
    fun sharedOverviewCases(): List<DynamicTest> = SharedJson.load("overview-cases.json")["cases"].values().map { case ->
        dynamicTest(case["name"].asString()) {
            val me = case["me"].asString()
            val states = case["groups"].values().associate { it["id"].asString() to state(it) }
            val overview = Overview.compute(states.mapNotNull { (id, s) -> GroupLedger.of(id, s, me) }, me)
            val e = case["expected"]
            assertEquals(SharedJson.canon(e["people"]), SharedJson.canon(overview.people), "people")
            assertEquals(SharedJson.canon(e["byGroup"]), SharedJson.canon(overview.byGroup), "byGroup")
            assertEquals(SharedJson.canon(e["owedToMe"]), SharedJson.canon(overview.owedToMe), "owedToMe")
            assertEquals(SharedJson.canon(e["iOwe"]), SharedJson.canon(overview.iOwe), "iOwe")

            val mine = HashMap<String, Long>()
            for (s in states.values) {
                val ids = s.members.values.filter { it.userId == me }.map { it.id }.toSet()
                for ((cur, b) in Balances.ofGroup(s).byCurrency) mine[cur] = (mine[cur] ?: 0) + b.filterKeys { it in ids }.values.sum()
            }
            for (cur in mine.keys + overview.owedToMe.keys + overview.iOwe.keys) {
                assertEquals(mine[cur] ?: 0, (overview.owedToMe[cur] ?: 0) - (overview.iOwe[cur] ?: 0), "invariant in $cur")
            }
        }
    }
}
