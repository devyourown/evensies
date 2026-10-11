import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core_guard.dart';
import '../../data/sync/group_state_store.dart';
import '../../domain/models.dart';
import '../../domain/settlement.dart';
import '../../providers.dart';

class BalanceResult {
  /// null only if computeBalances throws UnimplementedError (defensive).
  final Map<String, int>? balances;
  /// Expenses in a foreign currency with no fx rate; excluded from [balances].
  final int missingFx;
  const BalanceResult(this.balances, this.missingFx);
}

/// Converts every expense to the group's default currency and runs computeBalances.
/// Payments are assumed to be in the default currency (the settle screen creates them that way).
BalanceResult balancesOf(GroupState s) {
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
      paidBy: e.paidBy,
      amount: conv(e.amount),
      shares: {for (final sh in e.shares) sh.memberId: conv(sh.amount)},
    ));
  }
  final pays = [
    for (final p in s.payments.where((p) => !p.deleted)) PaymentLine(from: p.fromMember, to: p.toMember, amount: p.amount),
  ];
  final ids = s.members.map((m) => m.id).toList();
  return BalanceResult(tryCore(() => computeBalances(ids, lines, pays)), missing);
}

/// Current GroupState from drift; re-reads whenever the group's rows change.
final groupStateProvider = FutureProvider.family<GroupState, String>((ref, id) {
  ref.watch(membersProvider(id));
  ref.watch(expensesProvider(id));
  ref.watch(paymentsProvider(id));
  ref.watch(commentsProvider(id));
  ref.watch(groupProvider(id));
  return GroupStateStore(ref.watch(dbProvider)).load(id);
});

final balancesProvider = FutureProvider.family<BalanceResult, String>(
    (ref, id) async => balancesOf(await ref.watch(groupStateProvider(id).future)));
