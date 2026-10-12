import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/confirm.dart';
import '../../core/money.dart';
import '../../core/offline_banner.dart';
import '../../core/person_avatar.dart';
import '../../core/snack.dart';
import '../../domain/models.dart';
import '../../providers.dart';
import '../expense_form/comment_thread.dart';
import '../group_detail/balances.dart';
import 'payment_sheet.dart';

/// One payment (route `/groups/{id}/payments/{pid}`, docs/API.md 송금 기록·편집): who paid whom, the status with
/// Phase 1's Confirm received / Not received, Edit and Delete for the payer's or receiver's user, and comments.
class PaymentDetailScreen extends ConsumerWidget {
  final String groupId;
  final String paymentId;
  const PaymentDetailScreen({super.key, required this.groupId, required this.paymentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider(groupId)).value;
    final state = ref.watch(groupStateProvider(groupId)).value;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (group == null || state == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final p = state.payment(paymentId);
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.payments_outlined, size: 64, color: cs.primary),
              const SizedBox(height: 16),
              Text("This payment isn't on this device", style: text.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text("It hasn't synced yet, or its group was left.",
                  style: TextStyle(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
    }
    final me = ref.watch(sessionProvider).value?.userId;
    final from = state.member(p.fromMember), to = state.member(p.toMember);
    String name(Member? m) => m == null ? 'Someone' : (m.id == group.myMemberId ? 'You' : m.name);
    // The payer's or the receiver's user (docs/API.md: payment.deleted is theirs).
    final mine = me != null && (from?.userId == me || to?.userId == me);
    final iReceive = me != null && to?.userId == me;
    final date = DateTime.tryParse(p.date);

    return Scaffold(
      appBar: AppBar(
        title: Text(p.replaced ? 'Edited payment' : p.deleted ? 'Deleted payment' : 'Payment'),
        actions: [
          if (mine && !p.deleted) ...[
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                // An edit is a new payment (docs/API.md 송금 기록·편집): show it, not the old one, now deleted.
                final id = await showPaymentSheet(context, groupId: groupId, editing: p);
                if (id != null && context.mounted) context.replace('/groups/$groupId/payments/$id');
              },
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref, p),
            ),
          ],
        ],
      ),
      body: Column(children: [
        const OfflineBanner(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(syncProvider).sync(groupId).catchError((_) {}),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                // An edited payment was replaced by the new one, so it can't come back (docs/API.md 적용 규칙 7).
                if (p.deleted && p.replaced)
                  Card(
                    key: const Key('payment-edited'),
                    color: cs.secondaryContainer,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined, color: cs.onSecondaryContainer),
                      title: Text('This payment was edited', style: TextStyle(color: cs.onSecondaryContainer)),
                      subtitle: Text('The edited payment counts instead. Its comments stay here.',
                          style: TextStyle(color: cs.onSecondaryContainer)),
                    ),
                  )
                else if (p.deleted)
                  Card(
                    key: const Key('payment-deleted'),
                    color: cs.errorContainer,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: cs.onErrorContainer),
                      title: Text('This payment was deleted', style: TextStyle(color: cs.onErrorContainer)),
                      subtitle: Text("It doesn't count in balances.", style: TextStyle(color: cs.onErrorContainer)),
                      trailing: mine
                          ? FilledButton(
                              key: const Key('restore-payment'),
                              onPressed: () => ref.read(localWritesProvider).restorePayment(groupId, p.id),
                              child: const Text('Restore'),
                            )
                          : null,
                    ),
                  ),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  PersonAvatar(userId: from?.userId, name: from?.name ?? '?', radius: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.arrow_forward, color: cs.onSurfaceVariant),
                  ),
                  PersonAvatar(userId: to?.userId, name: to?.name ?? '?', radius: 28),
                ]),
                const SizedBox(height: 16),
                Text('${name(from)} paid ${name(to) == 'You' ? 'you' : name(to)}',
                    textAlign: TextAlign.center, style: text.titleMedium),
                const SizedBox(height: 4),
                Text(formatMoney(p.amount, p.currency),
                    key: const Key('payment-amount'),
                    textAlign: TextAlign.center,
                    style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(date == null ? p.date : DateFormat('EEE, d MMM yyyy').format(date),
                    textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                if (p.pending && !p.deleted) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: cs.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Text(
                          iReceive
                              ? '${name(from)} says they sent you this. Did it arrive?'
                              : 'Waiting for ${name(to)} to confirm',
                          style: TextStyle(color: cs.onSecondaryContainer),
                        ),
                        if (iReceive)
                          Wrap(alignment: WrapAlignment.end, spacing: 4, children: [
                            TextButton(
                                onPressed: () => _notReceived(context, ref, p, name(from)),
                                child: const Text('Not received')),
                            FilledButton(
                              onPressed: () => ref.read(localWritesProvider).confirmPayment(groupId, p.id),
                              child: const Text('Confirm received'),
                            ),
                          ])
                        else
                          const SizedBox(height: 4),
                      ]),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 16),
                CommentThread(groupId: groupId, paymentId: p.id),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Payment p) async {
    final ok = await confirm(context, title: 'Delete payment?', message: 'The debt it settled comes back.');
    if (!ok || !context.mounted) return;
    final writes = ref.read(localWritesProvider);
    final messenger = ScaffoldMessenger.of(context); // the app-wide one, so the SnackBar outlives this screen
    await writes.deletePayment(groupId, p.id);
    if (!context.mounted) return;
    context.pop();
    showUndo(messenger, 'Payment deleted', () => writes.restorePayment(groupId, p.id));
  }

  Future<void> _notReceived(BuildContext context, WidgetRef ref, Payment p, String from) async {
    final ok = await confirm(context,
        title: 'Not received?',
        message: 'The payment from $from is removed and the debt comes back.',
        confirmLabel: 'Not received');
    if (!ok || !context.mounted) return;
    final writes = ref.read(localWritesProvider);
    final messenger = ScaffoldMessenger.of(context);
    await writes.deletePayment(groupId, p.id);
    showUndo(messenger, 'Payment removed', () => writes.restorePayment(groupId, p.id));
  }
}
