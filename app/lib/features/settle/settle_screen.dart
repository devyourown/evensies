import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/confirm.dart';
import '../../core/ids.dart';
import '../../core/l10n.dart';
import '../../core/money.dart';
import '../../core/person_avatar.dart';
import '../../core/snack.dart';
import '../../data/db/database.dart';
import '../../data/fx_rates.dart';
import '../../domain/models.dart';
import '../../domain/payment_methods.dart';
import '../../domain/settlement.dart';
import '../../providers.dart';
import '../group_detail/balances.dart';
import '../group_detail/convert_sheet.dart';
import 'pay_sheet.dart';
import 'payment_sheet.dart';

class SettleScreen extends ConsumerStatefulWidget {
  final String groupId;
  const SettleScreen({super.key, required this.groupId});
  @override
  ConsumerState<SettleScreen> createState() => _SettleScreenState();
}

class _SettleScreenState extends ConsumerState<SettleScreen> {
  final _busy = <String>{}; // "$currency:$from>$to" or payment id while a write is in progress
  /// memberId → methods; null while loading or when offline ([_methodsFailed]).
  Map<String, List<PaymentMethod>>? _methods;
  bool _methodsFailed = false;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    try {
      final m = await ref.read(apiProvider).groupPaymentMethods(widget.groupId);
      if (mounted) setState(() => _methods = m);
    } catch (_) {
      if (mounted) setState(() => _methodsFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupProvider(widget.groupId)).value;
    final async = ref.watch(balancesProvider(widget.groupId));
    final res = async.value;
    final state = ref.watch(groupStateProvider(widget.groupId)).value;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l;
    Widget body;
    final record = Padding(
      padding: const EdgeInsets.only(top: 16),
      child: OutlinedButton.icon(
        key: const Key('record-payment'),
        onPressed: () => showPaymentSheet(context, groupId: widget.groupId),
        icon: const Icon(Icons.add),
        label: Text(l.recordAPayment),
      ),
    );
    if (group == null || res == null || state == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      // Every bucket settles in its own currency (docs/API.md, Balances per currency; Phase 6): the group currency first, then
      // the others by code.
      final all = res.transfers(simplify: group.simplifyDebts);
      final d = group.defaultCurrency;
      final others = [for (final c in all.keys) if (c != d && all[c]!.isNotEmpty) c]..sort();
      final transfers = all[d] ?? const <Transfer>[];
      final me = group.myMemberId;
      final pending = state.payments.where((p) => !p.deleted && p.pending && (p.fromMember == me || p.toMember == me)).toList();
      if (transfers.isEmpty && pending.isEmpty && others.isEmpty) {
        body = ListView(padding: const EdgeInsets.all(16), children: [
          const SizedBox(height: 64),
          Icon(Icons.check_circle_outline, size: 64, color: cs.primary),
          const SizedBox(height: 16),
          Text(l.nothingToSettle, style: text.titleMedium, textAlign: TextAlign.center),
          Text(l.everyoneEven, style: TextStyle(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          record,
        ]);
      } else {
        Widget header(String s, {Widget? trailing}) => Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 8),
              child: Row(children: [
                Expanded(child: Text(s, style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant))),
                ?trailing,
              ]),
            );
        body = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pending.isNotEmpty) ...[
              header(l.waitingForConfirmation),
              for (final p in pending) _pendingCard(group, state, p),
              const SizedBox(height: 8),
            ],
            if (transfers.isNotEmpty)
              header(!group.simplifyDebts
                  ? l.debtsAsRecorded
                  : others.isEmpty
                      ? l.transfersSettleEverything(transfers.length)
                      : l.transfersSettleBalance(transfers.length, d)),
            for (final t in transfers) _transferCard(group, state, t, d),
            for (final c in others) ...[
              Padding(
                key: Key('bucket-$c'),
                padding: const EdgeInsets.only(top: 16),
                child: header(l.notConvertedSettlesIn(c),
                    trailing: (res.unrated[c] ?? 0) > 0
                        ? TextButton.icon(
                            onPressed: () => showConvertSheet(context, groupId: group.id, currencies: [c]),
                            icon: const Icon(Icons.currency_exchange, size: 18),
                            label: Text(l.convert),
                          )
                        : null),
              ),
              for (final t in all[c]!) _transferCard(group, state, t, c),
            ],
            record,
          ],
        );
      }
    }
    return Scaffold(appBar: AppBar(title: Text(l.settleUp)), body: body);
  }

  String _name(GroupState s, String id) => s.member(id)?.name ?? '?';

  Widget _pendingCard(GroupRow group, GroupState s, Payment p) {
    final cs = Theme.of(context).colorScheme;
    final l = context.l;
    final amount = formatMoney(p.amount, p.currency);
    final iReceive = p.toMember == group.myMemberId;
    final busy = _busy.contains(p.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cs.secondaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/groups/${group.id}/payments/${p.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(iReceive ? Icons.call_received : Icons.hourglass_top, size: 20, color: cs.onSecondaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  iReceive
                      ? l.saysTheySent(_name(s, p.fromMember), amount)
                      : l.waitingToConfirmAmount(_name(s, p.toMember), amount),
                  style: TextStyle(color: cs.onSecondaryContainer),
                ),
              ),
            ]),
            if (iReceive)
              Wrap(alignment: WrapAlignment.end, spacing: 4, children: [
                if (busy)
                  const Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                else ...[
                  TextButton(onPressed: () => _notReceived(group, s, p), child: Text(l.notReceived)),
                  FilledButton(onPressed: () => _confirm(group, p), child: Text(l.confirmReceived)),
                ],
              ])
            else
              const SizedBox(height: 4),
          ]),
        ),
      ),
    );
  }

  /// One transfer in [cur]; tapping the card opens "Record a payment" prefilled with it (another amount or date).
  Widget _transferCard(GroupRow group, GroupState s, Transfer t, String cur) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l;
    final me = group.myMemberId;
    final iPay = t.from == me;
    final iReceive = t.to == me;
    final receiverMethods = _methods?[t.to] ?? const <PaymentMethod>[];
    final busy = _busy.contains('$cur:${t.from}>${t.to}');
    final muted = text.bodySmall?.copyWith(color: cs.onSurfaceVariant);
    final home = ref.watch(homeCurrencyProvider);
    final from = s.member(t.from);

    Widget actions;
    if (busy) {
      actions = const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
    } else if (iReceive) {
      actions = FilledButton.tonalIcon(
        onPressed: () => _request(group, t, cur),
        icon: const Icon(Icons.ios_share, size: 18),
        label: Text(l.request),
      );
    } else {
      actions = FilledButton.tonal(
        onPressed: () => _markPaid(group, s, t, cur),
        child: Text(iPay && receiverMethods.isNotEmpty ? l.iveSentIt : l.markAsPaid),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showPaymentSheet(context,
            groupId: group.id, from: t.from, to: t.to, amount: t.amount, currency: cur),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Wraps the button under the names at the largest text sizes.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  PersonAvatar(userId: from?.userId, name: from?.name ?? '?', radius: 16),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(text: iPay ? l.you : _name(s, t.from), style: const TextStyle(fontWeight: FontWeight.w600)),
                          const TextSpan(text: '  →  '),
                          TextSpan(text: iReceive ? l.you : _name(s, t.to), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ]),
                      ),
                      const SizedBox(height: 2),
                      Text(formatMoney(t.amount, cur), style: text.titleLarge?.copyWith(color: cs.primary)),
                      if (iPay || iReceive)
                        if (approxIn(home, {cur: t.amount}, ref.watch(latestFxProvider).value?.rates) case final approx?)
                          Text(l.approx(formatMoney(approx, home)), style: muted),
                    ]),
                  ),
                ]),
                actions,
              ],
            ),
            if (iPay) ...[
              const SizedBox(height: 8),
              PayChips(
                methods: _methods == null ? null : receiverMethods,
                failed: _methodsFailed,
                toName: _name(s, t.to),
                currency: cur,
                onPay: (m) =>
                    payWith(context, m, toName: _name(s, t.to), amount: t.amount, currency: cur, note: 'Evensies: ${group.name}'),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Future<void> _request(GroupRow group, Transfer t, String cur) async {
    final msg = requestText(
      context.l,
      formattedAmount: formatMoney(t.amount, cur),
      group: group.name,
      methods: _methods?[group.myMemberId] ?? const [],
      amountMinor: t.amount,
      currency: cur,
    );
    if (mounted) await shareText(context, msg);
  }

  Future<void> _markPaid(GroupRow group, GroupState s, Transfer t, String cur) async {
    final key = '$cur:${t.from}>${t.to}';
    final me = ref.read(sessionProvider).value?.userId;
    final receiver = s.member(t.to);
    // Same rule as the server: nobody to confirm (placeholder) or the receiver records it → confirmed.
    final confirmed = receiver?.userId == null || receiver?.userId == me;
    setState(() => _busy.add(key));
    try {
      await ref.read(localWritesProvider).createPayment(
            group.id,
            Payment(
              id: newId(),
              fromMember: t.from,
              toMember: t.to,
              amount: t.amount,
              currency: cur,
              date: todayIso(),
              status: confirmed ? 'confirmed' : 'sent',
            ),
          );
      final amount = formatMoney(t.amount, cur);
      if (mounted) {
        showInfo(context, confirmed ? context.l.paymentRecorded(amount) : context.l.markedAsSent(_name(s, t.to)));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy.remove(key));
    }
  }

  Future<void> _confirm(GroupRow group, Payment p) async {
    setState(() => _busy.add(p.id));
    try {
      await ref.read(localWritesProvider).confirmPayment(group.id, p.id);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy.remove(p.id));
    }
  }

  Future<void> _notReceived(GroupRow group, GroupState s, Payment p) async {
    final l = context.l;
    final ok = await confirm(context,
        title: l.notReceivedTitle, message: l.notReceivedMessage(_name(s, p.fromMember)), confirmLabel: l.notReceived);
    if (!ok || !mounted) return;
    setState(() => _busy.add(p.id));
    final writes = ref.read(localWritesProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await writes.deletePayment(group.id, p.id);
      showUndo(messenger, l.paymentRemovedSnack, () => writes.restorePayment(group.id, p.id));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy.remove(p.id));
    }
  }
}
