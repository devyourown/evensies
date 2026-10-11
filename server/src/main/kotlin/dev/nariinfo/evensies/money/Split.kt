package dev.nariinfo.evensies.money

import kotlin.math.abs
import kotlin.math.floor

enum class SplitMode { EQUAL, EXACT, PERCENT, SHARES, ADJUSTMENT }

/** code: SUM_MISMATCH | NEGATIVE_AMOUNT | NO_MEMBERS | INVALID_INPUT | NEGATIVE_SHARE */
class SplitException(val code: String) : RuntimeException(code)

object Split {
    /**
     * 분할 계산. 테스트: shared/split-cases.json (SplitTest).
     *
     * 입력
     *  - amount: 최소 단위 정수 (EUR 1234 = €12.34). 음수면 SplitException("NEGATIVE_AMOUNT").
     *  - members: 멤버 ID 목록. 비어 있으면 SplitException("NO_MEMBERS"). 정렬되어 있지 않을 수 있다.
     *  - mode:
     *      EQUAL   → input 무시. amount / n 씩, 나머지 r = amount % n 은
     *                memberId 오름차순으로 앞에서부터 r명에게 1씩 더한다.
     *      EXACT   → input[memberId] = 확정 금액(정수). 합이 amount와 다르면 SplitException("SUM_MISMATCH").
     *      PERCENT → input[memberId] = 비율(%). 합이 100과 다르면(오차 1e-6 허용) "SUM_MISMATCH".
     *                각 몫 = floor(amount * pct / 100). 바닥 처리로 남은 나머지는 EQUAL과 같은 규칙
     *                (memberId 오름차순, 앞에서부터 1씩)으로 배분한다.
     * 출력: 모든 members에 대한 memberId → 금액. 합은 반드시 amount.
     * 불변식: 결정적(같은 입력 → 같은 출력), 합 == amount, 각 몫 >= 0.
     *
     * Phase 3 (port of Hyojun's Dart computeSplit; cases marked "pending": "hyojun" in shared/split-cases.json):
     *  - PERCENT: leftover minor units go only to members whose percent is > 0 (a 0% member always gets 0).
     *  - SHARES: input = share counts (>= 0, fractional, missing = 0); negative/NaN/infinite → "INVALID_INPUT".
     *    w = round(count * 100), W = Σ w; W == 0 → "NO_MEMBERS". share = amount * w / W (integer math);
     *    leftover +1 each to members with w > 0, memberId ascending.
     *  - ADJUSTMENT: input = minor-unit adjustments (may be negative, missing = 0); not whole/NaN/infinite →
     *    "INVALID_INPUT". base = amount − Σ adj; base < 0 → "NEGATIVE_SHARE". Split base like EQUAL, then add each
     *    adj; any result < 0 → "NEGATIVE_SHARE".
     *  - SHARES/ADJUSTMENT ignore input keys not in members.
     * Until Hyojun's Dart lands (ported in the same push) they are TODO(); no server code calls them yet.
     */
    fun compute(amount: Long, mode: SplitMode, members: List<String>, input: Map<String, Double>?): Map<String, Long> {
        if (amount < 0) throw SplitException("NEGATIVE_AMOUNT")
        if (members.isEmpty()) throw SplitException("NO_MEMBERS")
        val sorted = members.sorted()
        val result = LinkedHashMap<String, Long>()
        when (mode) {
            SplitMode.EQUAL -> {
                val quotient = amount / members.size
                val remainder = amount % members.size
                for (member in sorted) result[member] = quotient
                giveRemainder(result, sorted, remainder)
            }
            SplitMode.EXACT -> {
                for (member in sorted) result[member] = input?.get(member)?.toLong() ?: 0L
                if (result.values.sum() != amount) throw SplitException("SUM_MISMATCH")
            }
            SplitMode.PERCENT -> {
                val totalPercent = input?.values?.sum() ?: 0.0
                if (abs(totalPercent - 100.0) >= 0.001) throw SplitException("SUM_MISMATCH")
                for (member in sorted) result[member] = floor(amount * (input?.get(member) ?: 0.0) / 100).toLong()
                // TODO(효준): the leftover goes only to members whose percent is > 0 (port with the Dart fix).
                giveRemainder(result, sorted, amount - result.values.sum())
            }
            SplitMode.SHARES, SplitMode.ADJUSTMENT -> TODO("효준: port computeSplit ${mode.name.lowercase()} from app/lib/domain/split.dart")
        }
        return result
    }

    /** Adds 1 to the first [k] members of [sorted] (member ids ascending). Same rule as the Dart `_giveRemainder`. */
    private fun giveRemainder(result: MutableMap<String, Long>, sorted: List<String>, k: Long) {
        sorted.forEachIndexed { index, member -> if (index < k) result[member] = result.getValue(member) + 1 }
    }
}
