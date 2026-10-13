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

/// Balance per member. Positive = is owed money (creditor), negative = owes money (debtor).
///
/// Rules (checked by shared/settlement-cases.json):
/// - Per expense sign = refund ? −1 : +1. Each payer gets +sign × what they paid, each sharer −sign × their share.
///   (A refund moves the opposite way to an expense: the receiver got everyone's money back on their behalf.)
/// - Payment: sender +amount, receiver −amount
///   (a payment is an expense paid by from and owed entirely by to. Receiving lowers what you're owed, sending lowers
///   what you owe.)
/// - The result map has every one of [members] as a key (0 with no activity). The input is already validated
///   (Σ payers == Σ shares == amount, ids within members), so it isn't checked again here. The total is always 0.
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

/// The transfers that bring every balance to 0 (greedy).
///
/// Rules:
/// - Sort creditors (>0) and debtors (<0) each by absolute value, largest first. On a tie, memberId ascending.
/// - Pair the largest creditor c with the largest debtor d: Transfer(from: d, to: c) of min(c.balance, -d.balance).
///   Drop whichever reached 0 and repeat (the other one is re-sorted, then the largest is picked again).
/// - Members with a 0 balance never appear in a transfer. At most n−1 transfers.
/// - Same input → same output (deterministic). Applying every transfer brings every balance to 0.
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
