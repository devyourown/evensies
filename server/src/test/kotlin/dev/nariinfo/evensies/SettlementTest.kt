package dev.nariinfo.evensies

import dev.nariinfo.evensies.money.ExpenseLine
import dev.nariinfo.evensies.money.PaymentLine
import dev.nariinfo.evensies.money.Settlement
import dev.nariinfo.evensies.money.Transfer
import org.junit.jupiter.api.DynamicTest
import org.junit.jupiter.api.DynamicTest.dynamicTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestFactory
import org.junit.jupiter.api.Assumptions.assumeTrue
import tools.jackson.databind.JsonNode
import dev.nariinfo.evensies.money.Split
import dev.nariinfo.evensies.money.SplitMode
import kotlin.random.Random
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class SettlementTest {
    @TestFactory
    fun sharedSettlementCases(): List<DynamicTest> = SharedJson.load("settlement-cases.json")["cases"].values().map { case ->
        dynamicTest(case["name"].asString()) {
            val members = case["members"].values().map { it.asString() }
            fun amounts(n: JsonNode) = n.properties().associate { (k, v) -> k to v.asLong() }
            val expenses = case["expenses"].values().map { e ->
                val shares = amounts(e["shares"])
                val payers = e["payers"]?.let(::amounts) ?: mapOf(e["paidBy"].asString() to e["amount"].asLong())
                ExpenseLine(payers, e["amount"].asLong(), shares, refund = e["refund"]?.asBoolean() ?: false)
            }
            val payments = case["payments"].values().map { PaymentLine(it["from"].asString(), it["to"].asString(), it["amount"].asLong()) }
            val expectedBalances = amounts(case["expectedBalances"])
            val expectedTransfers = case["expectedTransfers"].values().map { Transfer(it["from"].asString(), it["to"].asString(), it["amount"].asLong()) }

            // Transfers come from the expected balances, so they are checked even while the balances are pending.
            assertEquals(expectedTransfers, Settlement.simplify(expectedBalances))
            case["expectedPairwise"]?.let { want ->
                val pairwise = want.values().map { Transfer(it["from"].asString(), it["to"].asString(), it["amount"].asLong()) }
                assertEquals(pairwise, Settlement.pairwiseDebts(members, expenses, payments), "pairwise (simplify debts off)")
            }
            assumeTrue(case["pending"] == null, "pending: hyojun (multi-payer / refund balances land with his Dart computeBalances)")
            assertEquals(expectedBalances, Settlement.balances(members, expenses, payments))
        }
    }

    // Random members (3..8), expenses (0..20, shares from Split so they sum to amount) and payments (0..20).
    private val rnd = Random(42)

    private data class Case(val members: List<String>, val expenses: List<ExpenseLine>, val payments: List<PaymentLine>)

    private fun randomCase(): Case {
        val n = rnd.nextInt(3, 9)
        val members = (0 until n).map { "m$it" }
        val expenses = List(rnd.nextInt(0, 21)) {
            val amount = rnd.nextLong(0, 10_000)
            ExpenseLine(members[rnd.nextInt(n)], amount, Split.compute(amount, SplitMode.EQUAL, members, null))
        }
        val payments = List(rnd.nextInt(0, 21)) {
            val i = rnd.nextInt(n)
            val j = (i + 1 + rnd.nextInt(n - 1)) % n // never equal to i
            PaymentLine(members[i], members[j], rnd.nextLong(0, 5_000))
        }
        return Case(members, expenses, payments)
    }

    private fun forEachCase(body: (members: List<String>, balances: Map<String, Long>) -> Unit) =
        repeat(200) { randomCase().let { c -> body(c.members, Settlement.balances(c.members, c.expenses, c.payments)) } }

    @Test
    fun balancesSumToZero() = forEachCase { _, balances -> assertEquals(0L, balances.values.sum(), "$balances") }

    @Test
    fun transfersSettleAllBalances() = forEachCase { _, balances ->
        val left = balances.toMutableMap()
        for (t in Settlement.simplify(balances)) {
            left[t.from] = left.getValue(t.from) + t.amount
            left[t.to] = left.getValue(t.to) - t.amount
        }
        assertTrue(left.values.all { it == 0L }, "$balances -> $left")
    }

    @Test
    fun transferCountIsAtMostMembersMinusOne() = forEachCase { members, balances ->
        assertTrue(Settlement.simplify(balances).size <= members.size - 1, "$balances")
    }

    @Test
    fun simplifyIsDeterministic() = forEachCase { _, balances ->
        val reversed = LinkedHashMap<String, Long>().also { m -> balances.entries.reversed().forEach { m[it.key] = it.value } }
        assertEquals(Settlement.simplify(balances), Settlement.simplify(reversed))
    }

    @Test
    fun noTransferInvolvesZeroBalanceMember() = forEachCase { _, balances ->
        for (t in Settlement.simplify(balances)) {
            assertTrue(balances.getValue(t.from) != 0L && balances.getValue(t.to) != 0L && t.amount > 0, "$t in $balances")
        }
    }
}
