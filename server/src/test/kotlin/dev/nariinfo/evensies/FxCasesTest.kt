package dev.nariinfo.evensies

import dev.nariinfo.evensies.money.ConvertedExpense
import dev.nariinfo.evensies.money.Fx
import dev.nariinfo.evensies.money.FxException
import org.junit.jupiter.api.DynamicTest
import org.junit.jupiter.api.DynamicTest.dynamicTest
import org.junit.jupiter.api.TestFactory
import kotlin.test.assertEquals
import kotlin.test.assertIs

/** shared/fx-cases.json against the Kotlin port in money/Fx.kt (same file as the Dart test/domain/fx_test.dart). */
class FxCasesTest {
    @TestFactory
    fun sharedFxCases(): List<DynamicTest> = SharedJson.load("fx-cases.json")["cases"].values().map { case ->
        dynamicTest(case["name"].asString()) {
            val amount = case["amount"].asLong()
            val from = case["fromDecimals"].asInt()
            val to = case["toDecimals"].asInt()
            val rate = case["rate"].asDouble() // may be a JSON int (0)
            val result: Result<Any> = runCatching {
                when (val fn = case["fn"].asString()) {
                    "amount" -> Fx.convertAmount(amount, from, to, rate)
                    "expense" -> Fx.convertExpense(amount, case["parts"].properties().associate { (k, v) -> k to v.asLong() }, from, to, rate)
                    else -> error("unknown fn $fn")
                }
            }
            val error = case["error"]?.asString()
            if (error != null) {
                val e = result.exceptionOrNull()
                assertIs<FxException>(e, "expected FxException($error) but got $result")
                assertEquals(error, e.code)
            } else {
                val expected = case["expected"]
                val actual = result.getOrThrow()
                if (expected.isObject) {
                    val parts = expected["parts"].properties().associate { (k, v) -> k to v.asLong() }
                    assertEquals(ConvertedExpense(expected["amount"].asLong(), parts), actual)
                    assertEquals((actual as ConvertedExpense).amount, actual.parts.values.sum(), "parts add up to the total")
                } else {
                    assertEquals(expected.asLong(), actual)
                }
            }
        }
    }
}
