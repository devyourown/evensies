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
/// - 잔액 = 낸 돈(paidBy인 지출의 amount 합) − 부담 몫(shares[me] 합) + 보낸 송금(from==me) − 받은 송금(to==me).
///   (송금은 from이 낸 돈을 to가 전부 부담한 지출과 같다. 받으면 받을 돈이 줄고, 보내면 줄 돈이 준다.)
/// - 결과 맵은 [members] 전부를 키로 가진다(활동 없으면 0).
/// - 합계는 항상 0 (shares 합 == amount이므로).
///
/// Phase 3 — TODO(효준) (docs/API.md "SplitSpec" 잔액, cases marked "pending": "hyojun" in shared/settlement-cases.json):
/// - For each line, sign = refund ? −1 : +1: balance[m] += sign × payers[m] for every payer,
///   balance[m] −= sign × shares[m] for every share.
/// - Payments unchanged: balance[from] += amount, balance[to] −= amount.
/// - Every member in [members] is a key (0 if no activity). Lines come validated
///   (Σ payers == Σ shares == amount, ids in members): no checks here. Σ balances == 0.
/// Until then a line with several payers or a refund throws UnimplementedError; callers go through tryCore.
Map<String, int> computeBalances(
  List<String> members,
  List<ExpenseLine> expenses,
  List<PaymentLine> payments,
) {
  final result = <String, int> {};
  for (final member in members) {
    result.putIfAbsent(member, () => 0);
  }
  for (final expense in expenses) {
    int sign = expense.refund ? -1 : 1;
    for (final (payer) in expense.payers.keys) {
      result.update(payer, (v) => v+(sign * expense.payers[payer]!));
    }
    for (final (member) in expense.shares.keys) {
      result.update(member, (v) => v-(sign * (expense.shares[member]??0)));
    }
  }
  for (final payment in payments) {
    result.update(payment.from, (v) => v+payment.amount);
    result.update(payment.to, (v) => v-payment.amount);
  }
  return result;
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
  final result = <Transfer>[];
  final creditor = <(String, int)>[];
  final debtor = <(String, int)>[];
  for (final member in balances.keys) {
    final amount = balances[member] ?? 0;
    if (amount < 0) {
      debtor.add((member, amount));
    } else if (amount > 0) {
      creditor.add((member, amount));
    }
  }
  while (debtor.isNotEmpty && creditor.isNotEmpty) {
    debtor.sort((a, b) => a.$2 == b.$2 ? b.$1.compareTo(a.$1) : b.$2.compareTo(a.$2));
    creditor.sort((a, b) => a.$2 == b.$2 ? b.$1.compareTo(a.$1) : a.$2.compareTo(b.$2));
    final debt = debtor.removeLast();
    final cred = creditor.removeLast();
    final amount = min(-(debt.$2), cred.$2);
    if (debt.$2 + amount != 0) debtor.add((debt.$1, debt.$2 + amount));
    if (cred.$2 - amount != 0) creditor.add((cred.$1, cred.$2 - amount));
    result.add(Transfer(from: debt.$1, to: cred.$1, amount: amount));
  }
  return result;
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
