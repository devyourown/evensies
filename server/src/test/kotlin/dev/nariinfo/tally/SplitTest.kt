package dev.nariinfo.tally

import dev.nariinfo.tally.money.Split
import dev.nariinfo.tally.money.SplitException
import dev.nariinfo.tally.money.SplitMode
import org.junit.jupiter.api.DynamicTest
import org.junit.jupiter.api.DynamicTest.dynamicTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestFactory
import kotlin.random.Random
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertTrue

class SplitTest {
    @TestFactory
    fun sharedSplitCases(): List<DynamicTest> = SharedJson.load("split-cases.json")["cases"].values().map { case ->
        dynamicTest(case["name"].asString()) {
            val amount = case["amount"].asLong()
            val mode = SplitMode.valueOf(case["mode"].asString().uppercase())
            val members = case["members"].values().map { it.asString() }
            val input: Map<String, Double>? = case["input"]?.properties()?.associate { (k, v) -> k to v.asDouble() }
            val expectedError: String? = case["error"]?.asString()
            val expected: Map<String, Long>? = case["expected"]?.properties()?.associate { (k, v) -> k to v.asLong() }

            val result: Result<Map<String, Long>> = runCatching { Split.compute(amount, mode, members, input) }

            if (expectedError != null) {
                val e = result.exceptionOrNull()
                assertIs<SplitException>(e, "expected SplitException($expectedError) but got $result")
                assertEquals(expectedError, e.code)
            } else {
                val shares = result.getOrThrow()
                assertEquals(expected, shares)
                assertEquals(amount, shares.values.sum())
            }
        }
    }

    @Test
    fun remainderDistributionIsDeterministic() {
        val rnd = Random(42)
        repeat(500) {
            val n = rnd.nextInt(1, 8)
            val members = (0 until n).map { "m$it" }.shuffled(rnd)
            val amount = rnd.nextLong(0, 10_001)
            val shares = Split.compute(amount, SplitMode.EQUAL, members, null)
            assertEquals(amount, shares.values.sum(), "sum for amount=$amount members=$members")
            val base = amount / n
            assertTrue(shares.values.all { it == base || it == base + 1 }, "shares=$shares amount=$amount")
            assertEquals(shares, Split.compute(amount, SplitMode.EQUAL, members.sorted(), null), "order independence")
        }
    }

    @Test
    fun remainderGoesToLowestMemberIdsFirst() {
        assertEquals(mapOf("a" to 334L, "b" to 334L, "c" to 334L), Split.compute(1002, SplitMode.EQUAL, listOf("b", "c", "a"), null))
        assertEquals(mapOf("a" to 334L, "b" to 334L, "c" to 333L), Split.compute(1001, SplitMode.EQUAL, listOf("b", "c", "a"), null))
    }
}
