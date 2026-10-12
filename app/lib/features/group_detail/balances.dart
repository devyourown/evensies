import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../data/sync/group_state_store.dart';
import '../../domain/balances.dart';
import '../../domain/models.dart';
import '../../providers.dart';

export '../../domain/balances.dart';

/// Current GroupState from drift; re-reads whenever the group's rows change.
final groupStateProvider = FutureProvider.family<GroupState, String>((ref, id) {
  ref.watch(membersProvider(id));
  ref.watch(expensesProvider(id));
  ref.watch(paymentsProvider(id));
  ref.watch(commentsProvider(id));
  ref.watch(attachmentCountsProvider(id));
  ref.watch(recurrencesProvider(id));
  ref.watch(groupProvider(id));
  return GroupStateStore(ref.watch(dbProvider)).load(id);
});

final balancesProvider = FutureProvider.family<BalanceResult, String>(
    (ref, id) async => balancesOf(await ref.watch(groupStateProvider(id).future)));

/// "You are owed €5.00" / "You owe €5.00"; [capital] false starts with "you".
String owedText(int balance, String currency, {bool capital = true}) {
  final you = capital ? 'You' : 'you';
  return balance < 0
      ? '$you owe ${formatMoney(-balance, currency)}'
      : '$you are owed ${formatMoney(balance, currency)}';
}
