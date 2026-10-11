import '../core/core_guard.dart';
import '../core/money.dart';
import 'models.dart';
import 'settlement.dart';

typedef BalanceFn = Map<String, int> Function(List<String> members, List<ExpenseLine> lines, List<PaymentLine> payments);

class BalanceResult {
  /// null only if computeBalances throws UnimplementedError even for single-payer lines (defensive).
  final Map<String, int>? balances;

  /// Expenses in a foreign currency with no fx rate; excluded from [balances].
  final int missingFx;

  /// Expenses with several payers or a refund while computeBalances can't count them yet (TODO(효준)); excluded.
  final int unsupported;

  /// What [balances] was computed from (Settle up reuses it for pairwise debts).
  final List<String> members;
  final List<ExpenseLine> lines;
  final List<PaymentLine> payments;
  const BalanceResult(this.balances, this.missingFx,
      {this.unsupported = 0, this.members = const [], this.lines = const [], this.payments = const []});

  /// Transfers for Settle up: fewest payments, or debts as recorded when the group turned simplifying off.
  List<Transfer>? transfers({required bool simplify}) {
    final b = balances;
    if (b == null) return null;
    return tryCore(() => simplify ? simplifyDebts(b) : pairwiseDebts(members, lines, payments));
  }
}

/// Converts every expense to the group's default currency and runs [compute] (computeBalances).
/// Payments are assumed to be in the default currency (the settle screen creates them that way).
/// While [compute] can't handle several payers or refunds, those lines are left out and counted as unsupported.
BalanceResult balancesOf(GroupState s, {BalanceFn compute = computeBalances}) {
  final def = s.defaultCurrency;
  var missing = 0;
  final lines = <ExpenseLine>[];
  for (final e in s.expenses.where((e) => !e.deleted)) {
    double rate = 1;
    if (e.currency != def) {
      if (e.fxRateToDefault == null) {
        missing++;
        continue;
      }
      rate = e.fxRateToDefault!;
    }
    int conv(int v) => (v * rate).round();
    lines.add(ExpenseLine(
      payers: {for (final p in e.payers) p.memberId: conv(p.amount)},
      amount: conv(e.amount),
      shares: {for (final sh in e.shares) sh.memberId: conv(sh.amount)},
      refund: e.refund,
    ));
  }
  final pays = [
    for (final p in s.payments.where((p) => !p.deleted)) PaymentLine(from: p.fromMember, to: p.toMember, amount: p.amount),
  ];
  final ids = s.members.map((m) => m.id).toList();
  final all = tryCore(() => compute(ids, lines, pays));
  if (all != null) return BalanceResult(all, missing, members: ids, lines: lines, payments: pays);
  final simple = [for (final l in lines) if (l.payers.length == 1 && !l.refund) l];
  return BalanceResult(tryCore(() => compute(ids, simple, pays)), missing,
      unsupported: lines.length - simple.length, members: ids, lines: simple, payments: pays);
}

/// Why [me] can't leave yet, or null when my balance is zero and every expense is counted. Only the app checks it
/// (docs/API.md 그룹 나가기): the settings screen before the tap, LocalWrites.leaveGroup again after its sync.
String? leaveBlocker(BalanceResult res, String? me, String currency) {
  final b = res.balances;
  if (b == null) return "Balances can't be computed yet";
  if (res.unsupported > 0 || res.missingFx > 0) return "Some expenses aren't counted in balances yet";
  final mine = b[me] ?? 0;
  if (mine == 0) return null;
  final m = formatMoney(mine.abs(), currency);
  return mine < 0 ? 'You owe $m · settle up first' : 'You are owed $m · settle up first';
}
