import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/core_guard.dart';
import '../../core/ids.dart';
import '../../core/money.dart';
import '../../core/snack.dart';
import '../../data/db/database.dart';
import '../../domain/models.dart';
import '../../domain/settlement.dart';
import '../../providers.dart';
import '../group_detail/balances.dart';

class SettleScreen extends ConsumerWidget {
  final String groupId;
  const SettleScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider(groupId)).value;
    final res = ref.watch(balancesProvider(groupId)).value;
    final members = {for (final m in ref.watch(membersProvider(groupId)).value ?? const <MemberRow>[]) m.id: m.name};
    Widget body;
    if (group == null || res == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (res.balances == null) {
      body = const Center(child: Text(notImplementedLabel));
    } else {
      final transfers = tryCore(() => simplifyDebts(res.balances!));
      if (transfers == null) {
        body = const Center(child: Text(notImplementedLabel));
      } else if (transfers.isEmpty) {
        body = const Center(child: Text('All settled up!'));
      } else {
        body = ListView(
          children: [
            for (final t in transfers)
              ListTile(
                title: Text('${members[t.from] ?? '?'} → ${members[t.to] ?? '?'}'),
                subtitle: Text(formatMoney(t.amount, group.defaultCurrency)),
                trailing: TextButton(
                  onPressed: () => _markPaid(context, ref, group, t),
                  child: const Text('Mark as paid'),
                ),
              ),
          ],
        );
      }
    }
    return Scaffold(appBar: AppBar(title: const Text('Settle up')), body: body);
  }

  Future<void> _markPaid(BuildContext context, WidgetRef ref, GroupRow group, Transfer t) async {
    try {
      await ref.read(localWritesProvider).createPayment(
            group.id,
            Payment(
              id: newId(),
              fromMember: t.from,
              toMember: t.to,
              amount: t.amount,
              currency: group.defaultCurrency,
              date: todayIso(),
            ),
          );
      if (context.mounted) showInfo(context, 'Payment recorded');
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}
