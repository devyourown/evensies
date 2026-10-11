import 'dart:math';

class ExpenseLine {
  /// memberId → amount paid (for a refund: amount received). Sums to [amount].
  final Map<String, int> payers;
  final int amount;
  /// memberId → amount owed (for a refund: amount it is split back to). Sums to [amount].
  final Map<String, int> shares;
  /// Money that came back (a refund): its effect on balances is the reverse of an expense.
  final bool refund;
  ExpenseLine({String? paidBy, Map<String, int>? payers, required this.amount, required this.shares, this.refund = false})
      : assert((paidBy == null) != (payers == null), 'pass paidBy or payers'),
        payers = payers ?? {paidBy!: amount};
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
/// 규칙(shared/settlement-cases.json이 검증):
/// - 지출마다 sign = refund ? −1 : +1. 낸 사람마다 +sign × 낸 금액, 부담하는 사람마다 −sign × 몫.
///   (환불은 받은 사람이 모두의 돈을 대신 받은 것이라 지출과 정반대로 움직인다.)
/// - 송금: 보낸 사람 +amount, 받은 사람 −amount
///   (송금은 from이 낸 돈을 to가 전부 부담한 지출과 같다. 받으면 받을 돈이 줄고, 보내면 줄 돈이 준다.)
/// - 결과 맵은 [members] 전부를 키로 가진다(활동 없으면 0). 입력은 검증된 값(Σ payers == Σ shares == amount,
///   id는 members 안)이라 여기서 다시 검사하지 않는다. 합계는 항상 0.
Map<String, int> computeBalances(
  List<String> members,
  List<ExpenseLine> expenses,
  List<PaymentLine> payments,
) {
  final balances = {for (final member in members) member: 0};
  void add(String member, int amount) => balances[member] = balances[member]! + amount;

  for (final expense in expenses) {
    final sign = expense.refund ? -1 : 1;
    expense.payers.forEach((member, paid) => add(member, sign * paid));
    expense.shares.forEach((member, owed) => add(member, -sign * owed));
  }
  for (final payment in payments) {
    add(payment.from, payment.amount);
    add(payment.to, -payment.amount);
  }
  return balances;
}

/// 잔액을 0으로 만드는 송금 목록(탐욕법).
///
/// 규칙:
/// - 채권자(>0)와 채무자(<0)를 각각 절댓값 큰 순으로 정렬. 동률이면 memberId 오름차순.
/// - 가장 큰 채권자 c와 가장 큰 채무자 d를 맞붙여 min(c.balance, -d.balance)만큼 Transfer(from: d, to: c).
///   0이 된 쪽을 빼고 반복(남은 쪽은 재정렬 후 다시 최대값 선택).
/// - 잔액 0인 멤버는 송금에 등장하지 않는다. 결과 수 ≤ n−1.
/// - 같은 입력 → 같은 출력(결정적). 결과 송금을 모두 적용하면 모든 잔액이 0.
List<Transfer> simplifyDebts(Map<String, int> balances) {
  // (memberId, amount) with a positive amount: what a creditor is owed / what a debtor owes.
  final creditors = [for (final MapEntry(:key, :value) in balances.entries) if (value > 0) (key, value)];
  final debtors = [for (final MapEntry(:key, :value) in balances.entries) if (value < 0) (key, -value)];
  int largestFirst((String, int) a, (String, int) b) => a.$2 != b.$2 ? b.$2.compareTo(a.$2) : a.$1.compareTo(b.$1);

  final transfers = <Transfer>[];
  while (creditors.isNotEmpty && debtors.isNotEmpty) {
    creditors.sort(largestFirst);
    debtors.sort(largestFirst);
    final (creditor, owed) = creditors.removeAt(0);
    final (debtor, owes) = debtors.removeAt(0);
    final amount = min(owed, owes);
    if (owed > amount) creditors.add((creditor, owed - amount));
    if (owes > amount) debtors.add((debtor, owes - amount));
    transfers.add(Transfer(from: debtor, to: creditor, amount: amount));
  }
  return transfers;
}

/// Debts as they arose, for groups with "simplify debts" off (docs/API.md, settlement-cases `expectedPairwise`).
/// Each expense line and each payment is settled on its own with `simplifyDebts(computeBalances(...))`; the
/// transfers are summed per (from, to) and netted per pair of people. Zero pairs are dropped; sorted by from, then to.
List<Transfer> pairwiseDebts(List<String> members, List<ExpenseLine> lines, List<PaymentLine> payments) {
  final net = <(String, String), int>{}; // (lo, hi) → what lo owes hi (negative: hi owes lo)
  void add(Transfer t) {
    final lo = t.from.compareTo(t.to) < 0;
    final key = lo ? (t.from, t.to) : (t.to, t.from);
    net[key] = (net[key] ?? 0) + (lo ? t.amount : -t.amount);
  }

  for (final l in lines) {
    simplifyDebts(computeBalances(members, [l], const [])).forEach(add);
  }
  for (final p in payments) {
    simplifyDebts(computeBalances(members, const [], [p])).forEach(add);
  }
  return [
    for (final MapEntry(key: (lo, hi), value: v) in net.entries)
      if (v != 0) v > 0 ? Transfer(from: lo, to: hi, amount: v) : Transfer(from: hi, to: lo, amount: -v),
  ]..sort((a, b) => a.from == b.from ? a.to.compareTo(b.to) : a.from.compareTo(b.from));
}
