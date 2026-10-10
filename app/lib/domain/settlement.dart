class ExpenseLine {
  final String paidBy;
  final int amount;
  final Map<String, int> shares;
  const ExpenseLine({required this.paidBy, required this.amount, required this.shares});
}

class PaymentLine {
  final String from;
  final String to;
  final int amount;
  const PaymentLine({required this.from, required this.to, required this.amount});
}

class Transfer {
  final String from;
  final String to;
  final int amount;
  const Transfer({required this.from, required this.to, required this.amount});
  @override
  bool operator ==(Object other) =>
      other is Transfer && other.from == from && other.to == to && other.amount == amount;
  @override
  int get hashCode => Object.hash(from, to, amount);
  @override
  String toString() => 'Transfer($from -> $to: $amount)';
}

/// 멤버별 잔액. 양수 = 받을 돈(채권자), 음수 = 줄 돈(채무자).
///
/// TODO(효준): 본문 구현. 규칙(shared/settlement-cases.json이 검증):
/// - 잔액 = 낸 돈(paidBy인 지출의 amount 합) − 부담 몫(shares[me] 합) + 받은 송금(to==me) − 보낸 송금(from==me).
/// - 결과 맵은 [members] 전부를 키로 가진다(활동 없으면 0).
/// - 합계는 항상 0 (shares 합 == amount이므로).
Map<String, int> computeBalances(
  List<String> members,
  List<ExpenseLine> expenses,
  List<PaymentLine> payments,
) {
  throw UnimplementedError('TODO(효준)');
}

/// 잔액을 0으로 만드는 송금 목록(탐욕법).
///
/// TODO(효준): 본문 구현. 규칙:
/// - 채권자(>0)와 채무자(<0)를 각각 절댓값 큰 순으로 정렬. 동률이면 memberId 오름차순.
/// - 가장 큰 채권자 c와 가장 큰 채무자 d를 맞붙여 min(c.balance, -d.balance)만큼 Transfer(from: d, to: c).
///   0이 된 쪽을 빼고 반복(남은 쪽은 재정렬 후 다시 최대값 선택).
/// - 잔액 0인 멤버는 송금에 등장하지 않는다. 결과 수 ≤ n−1.
/// - 같은 입력 → 같은 출력(결정적). 결과 송금을 모두 적용하면 모든 잔액이 0.
List<Transfer> simplifyDebts(Map<String, int> balances) {
  throw UnimplementedError('TODO(효준)');
}
