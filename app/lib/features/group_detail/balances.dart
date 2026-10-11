import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  ref.watch(groupProvider(id));
  return GroupStateStore(ref.watch(dbProvider)).load(id);
});

final balancesProvider = FutureProvider.family<BalanceResult, String>(
    (ref, id) async => balancesOf(await ref.watch(groupStateProvider(id).future)));
