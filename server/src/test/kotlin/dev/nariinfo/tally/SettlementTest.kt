package dev.nariinfo.tally

import dev.nariinfo.tally.money.ExpenseLine
import dev.nariinfo.tally.money.PaymentLine
import dev.nariinfo.tally.money.Settlement
import dev.nariinfo.tally.money.Transfer
import org.junit.jupiter.api.DynamicTest
import org.junit.jupiter.api.DynamicTest.dynamicTest
import org.junit.jupiter.api.Tag
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.TestFactory
import kotlin.test.fail

/** Runs with `./gradlew test -PincludeHyojun`. */
@Tag("hyojun")
class SettlementTest {
    @TestFactory
    fun sharedSettlementCases(): List<DynamicTest> = SharedJson.load("settlement-cases.json")["cases"].values().map { case ->
        dynamicTest(case["name"].asString()) {
            val members = case["members"].values().map { it.asString() }
            val expenses = case["expenses"].values().map { e ->
                ExpenseLine(e["paidBy"].asString(), e["amount"].asLong(), e["shares"].properties().associate { (k, v) -> k to v.asLong() })
            }
            val payments = case["payments"].values().map { PaymentLine(it["from"].asString(), it["to"].asString(), it["amount"].asLong()) }
            val expectedBalances = case["expectedBalances"].properties().associate { (k, v) -> k to v.asLong() }
            val expectedTransfers = case["expectedTransfers"].values().map { Transfer(it["from"].asString(), it["to"].asString(), it["amount"].asLong()) }

            val balances = Settlement.balances(members, expenses, payments)
            val transfers = Settlement.simplify(balances)

            // TODO(효준): 단언. balances == expectedBalances, transfers == expectedTransfers (순서 포함).
            fail("TODO(효준)")
        }
    }

    @Test
    fun balancesSumToZero() {
        // TODO(효준): 성질 테스트. 임의의 멤버·지출·송금(지출 shares 합 == amount)을 만들어
        //  Settlement.balances(...).values.sum() == 0.
        TODO("TODO(효준)")
    }

    @Test
    fun transfersSettleAllBalances() {
        // TODO(효준): 성질 테스트. 임의의 잔액(합 0)에 대해 simplify 결과를 적용하면
        //  (from은 amount만큼 더하고 to는 빼면) 모든 잔액이 0.
        TODO("TODO(효준)")
    }

    @Test
    fun transferCountIsAtMostMembersMinusOne() {
        // TODO(효준): 성질 테스트. 임의의 잔액(합 0, n명)에 대해 simplify(...).size <= n - 1.
        TODO("TODO(효준)")
    }

    @Test
    fun simplifyIsDeterministic() {
        // TODO(효준): 성질 테스트. 같은 잔액 맵을 키 순서만 바꿔 두 번 넣어도 simplify 결과가 같다.
        TODO("TODO(효준)")
    }
}
