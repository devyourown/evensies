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

class SettleScreen extends ConsumerStatefulWidget {
  final String groupId;
  const SettleScreen({super.key, required this.groupId});
  @override
  ConsumerState<SettleScreen> createState() => _SettleScreenState();
}

class _SettleScreenState extends ConsumerState<SettleScreen> {
  final _busy = <String>{}; // "$from>$to" while a payment is being written

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupProvider(widget.groupId)).value;
    final res = ref.watch(balancesProvider(widget.groupId)).value;
    final members = {for (final m in ref.watch(membersProvider(widget.groupId)).value ?? const <MemberRow>[]) m.id: m.name};
    final cs = Theme.of(context).colorScheme;
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
        body = Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle_outline, size: 64, color: cs.primary),
            const SizedBox(height: 16),
            Text('Nothing to settle', style: Theme.of(context).textTheme.titleMedium),
            Text('Everyone is even.', style: TextStyle(color: cs.onSurfaceVariant)),
          ]),
        );
      } else {
        body = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(transfers.length == 1 ? '1 transfer settles everything' : '${transfers.length} transfers settle everything',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            ),
            for (final t in transfers)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(text: members[t.from] ?? '?', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const TextSpan(text: '  →  '),
                            TextSpan(text: members[t.to] ?? '?', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(formatMoney(t.amount, group.defaultCurrency),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: cs.primary)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    _busy.contains('${t.from}>${t.to}')
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : FilledButton.tonal(
                            onPressed: () => _markPaid(group, t),
                            child: const Text('Mark as paid'),
                          ),
                  ]),
                ),
              ),
          ],
        );
      }
    }
    return Scaffold(appBar: AppBar(title: const Text('Settle up')), body: body);
  }

  Future<void> _markPaid(GroupRow group, Transfer t) async {
    final key = '${t.from}>${t.to}';
    setState(() => _busy.add(key));
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
      if (mounted) showInfo(context, 'Payment of ${formatMoney(t.amount, group.defaultCurrency)} recorded');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy.remove(key));
    }
  }
}
