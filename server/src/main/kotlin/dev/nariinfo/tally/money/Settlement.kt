package dev.nariinfo.tally.money

import kotlin.math.abs
import kotlin.math.min

data class ExpenseLine(val paidBy: String, val amount: Long, val shares: Map<String, Long>)
data class PaymentLine(val from: String, val to: String, val amount: Long)
data class Transfer(val from: String, val to: String, val amount: Long)

object Settlement {
    /**
     * 멤버별 잔액. 테스트: shared/settlement-cases.json (SettlementTest).
     *
     * 잔액 = 낸 돈(paidBy로 낸 expense.amount 합) − 부담 몫(shares[me] 합)
     *        + 보낸 송금(from == me) − 받은 송금(to == me)
     * 모든 members가 결과에 들어간다(활동 없으면 0). shares에만 등장하고 members에 없는 ID는 없다고 가정한다.
     * 불변식: 결과 값의 합 == 0.
     */
    fun balances(members: List<String>, expenses: List<ExpenseLine>, payments: List<PaymentLine>): Map<String, Long> {
        val result = LinkedHashMap<String, Long>()
        for (member in members) result[member] = 0L
        for (expense in expenses) {
            result[expense.paidBy] = result.getValue(expense.paidBy) + expense.amount
            for ((member, share) in expense.shares) result[member] = result.getValue(member) - share
        }
        // A payment is an expense paid by `from` and owed entirely by `to`.
        for (payment in payments) {
            result[payment.from] = result.getValue(payment.from) + payment.amount
            result[payment.to] = result.getValue(payment.to) - payment.amount
        }
        return result
    }

    /**
     * 부채 단순화(탐욕법).
     *
     * 1. 양수(채권자)와 음수(채무자)를 각각 절댓값 큰 순으로 정렬. 절댓값이 같으면 memberId 오름차순.
     * 2. 가장 큰 채권자 c와 가장 큰 채무자 d를 맞붙여 min(c.amount, |d.amount|)만큼 Transfer(from=d, to=c)를 만든다.
     * 3. 0이 된 쪽을 빼고(둘 다 0이면 둘 다) 다시 1부터 반복. 잔액 0인 멤버는 처음부터 제외.
     * 결과 순서 = 생성 순서.
     * 불변식: transfers.size <= 멤버 수 − 1, 모든 transfer를 적용하면 모든 잔액이 0, 결정적.
     */
    fun simplify(balances: Map<String, Long>): List<Transfer> {
        val result = ArrayList<Transfer>()
        val creditors = ArrayList<Pair<String, Long>>()
        val debtors = ArrayList<Pair<String, Long>>()
        for ((member, amount) in balances) {
            if (amount < 0) debtors += member to amount
            else if (amount > 0) creditors += member to amount
        }
        // Largest absolute amount first; ties by member id ascending. Same rule for both lists.
        val largestFirst = compareByDescending<Pair<String, Long>> { abs(it.second) }.thenBy { it.first }
        while (debtors.isNotEmpty() && creditors.isNotEmpty()) {
            debtors.sortWith(largestFirst)
            creditors.sortWith(largestFirst)
            val (debtor, debt) = debtors.removeAt(0)
            val (creditor, credit) = creditors.removeAt(0)
            val amount = min(-debt, credit)
            if (debt + amount != 0L) debtors += debtor to debt + amount
            if (credit - amount != 0L) creditors += creditor to credit - amount
            result += Transfer(from = debtor, to = creditor, amount = amount)
        }
        return result
    }
}
