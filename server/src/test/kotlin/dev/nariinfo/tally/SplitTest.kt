package dev.nariinfo.tally

import dev.nariinfo.tally.money.Split
import dev.nariinfo.tally.money.SplitException
import dev.nariinfo.tally.money.SplitMode
import org.junit.jupiter.api.DynamicTest
import org.junit.jupiter.api.DynamicTest.dynamicTest
import org.junit.jupiter.api.Tag
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestFactory
import kotlin.test.fail

/** Runs with `./gradlew test -PincludeHyojun`. */
@Tag("hyojun")
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

            // TODO(효준): 단언.
            //  - expectedError != null 이면 result.exceptionOrNull()이 SplitException이고 code == expectedError.
            //  - 아니면 result.getOrThrow() == expected (Map 비교) 이고 값의 합 == amount.
            fail("TODO(효준)")
        }
    }

    @Test
    fun remainderDistributionIsDeterministic() {
        // TODO(효준): 성질 테스트. 임의의 amount(0..10_000)와 멤버 목록(1..7명, 섞인 순서)에 대해
        //  compute(EQUAL)의 합 == amount, 각 몫은 floor(amount/n) 또는 그보다 1 큼,
        //  같은 입력(멤버 순서만 바꿔도)에 같은 출력.
        TODO("TODO(효준)")
    }
}
