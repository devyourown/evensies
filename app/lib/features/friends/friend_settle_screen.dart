import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ids.dart';
import '../../core/l10n.dart';
import '../../core/money.dart';
import '../../core/person_avatar.dart';
import '../../core/snack.dart';
import '../../domain/overview.dart';
import '../../domain/payment_methods.dart';
import '../../providers.dart';
import '../group_detail/convert_sheet.dart';
import '../settle/pay_sheet.dart';
import 'friend_screen.dart' show friendAmountText;
import 'home_data.dart';

/// Settle up with one person across everything (route `/friends/{key}/settle`, docs/API.md 친구와 한 번에 정산): one
/// card per currency with the net and every line behind it; recording writes one payment per line, in its group.
class FriendSettleScreen extends ConsumerStatefulWidget {
  final String personKey;
  const FriendSettleScreen({super.key, required this.personKey});
  @override
  ConsumerState<FriendSettleScreen> createState() => _FriendSettleScreenState();
}

class _FriendSettleScreenState extends ConsumerState<FriendSettleScreen> {
  /// The group whose payment methods are read, with their member and mine there.
  ({String groupId, String? theirs, String mine})? _source;
  Map<String, List<PaymentMethod>>? _methods;
  bool _methodsFailed = false;
  final _busy = <String>{}; // currencies being recorded

  /// Their friend group, else any shared group (docs/API.md: by their member id there).
  void _loadMethods(HomeData data, Person p) {
    if (_source != null) return;
    final ledger = [
      for (final g in p.friendGroups) ?data.ledgers[g],
      for (final l in data.ledgers.values) if (l.personOf.containsValue(p.key)) l,
    ].firstOrNull;
    if (ledger == null) return;
    final theirs = ledger.personOf.entries.where((e) => e.value == p.key).map((e) => e.key).firstOrNull;
    _source = (groupId: ledger.groupId, theirs: theirs, mine: ledger.myMemberId);
    ref.read(apiProvider).groupPaymentMethods(ledger.groupId).then((m) {
      if (mounted) setState(() => _methods = m);
    }, onError: (_) {
      if (mounted) setState(() => _methodsFailed = true);
    });
  }

  Future<void> _record(HomeData data, Person p, List<FriendLine> lines, String currency) async {
    setState(() => _busy.add(currency));
    try {
      final payments = settlePayments(lines, p.key, currency, date: todayIso(), newId: newId);
      final w = ref.read(localWritesProvider);
      for (final x in payments) {
        await w.createPayment(x.groupId, x.payment);
      }
      final net = lines.where((l) => l.currency == currency).fold(0, (a, l) => a + l.signed);
      final sent = payments.any((x) => x.payment.pending);
      if (mounted) {
        final l = context.l;
        showInfo(
            context,
            sent
                ? l.markedAsSent(p.name)
                : net == 0
                    ? l.recordedInGroups(payments.length)
                    : l.paymentRecorded(formatMoney(net.abs(), currency)));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy.remove(currency));
    }
  }

  Future<void> _requestShare(Person p, int amount, String currency) async {
    final s = _source;
    final msg = requestText(
      context.l,
      formattedAmount: formatMoney(amount, currency),
      group: context.l.requestNoGroup,
      methods: s == null ? const [] : _methods?[s.mine] ?? const [],
      amountMinor: amount,
      currency: currency,
    );
    await shareText(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(homeDataProvider).value;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l;
    final p = data?.person(widget.personKey);
    if (data == null || p == null) {
      return Scaffold(appBar: AppBar(title: Text(l.settleUp)), body: const Center(child: CircularProgressIndicator()));
    }
    _loadMethods(data, p);
    final lines = friendLines(data.ledgers.values, p.key);
    final net = netByCurrency(lines);
    final currencies = [...net.keys]..sort();
    final theirMethods = _source?.theirs == null ? const <PaymentMethod>[] : _methods?[_source!.theirs] ?? const [];
    final muted = text.bodySmall?.copyWith(color: cs.onSurfaceVariant);

    Widget card(String c) {
      final v = net[c]!;
      final mine = [for (final l in lines) if (l.currency == c) l];
      final busy = _busy.contains(c);
      final unratedIn = {
        for (final l in mine)
          if (data.group(l.groupId) case final g? when g.row.defaultCurrency != c && (g.res.unrated[c] ?? 0) > 0) g.row.id,
      };
      final Widget action;
      if (busy) {
        action = const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
      } else if (v < 0) {
        action = FilledButton(
          key: Key('settle-$c'),
          onPressed: () => _record(data, p, lines, c),
          child: Text(theirMethods.isNotEmpty && p.userId != null ? l.iveSentIt : l.markAsPaid),
        );
      } else if (v > 0) {
        action = FilledButton(
            key: Key('settle-$c'), onPressed: () => _record(data, p, lines, c), child: Text(l.markAsReceived));
      } else {
        action = FilledButton.tonal(
            key: Key('settle-$c'), onPressed: () => _record(data, p, lines, c), child: Text(l.clearBothSides));
      }
      return Card(
        key: Key('friend-settle-$c'),
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(v == 0 ? l.evenIn(c) : friendAmountText(l, p.name, v, c),
                    style: text.titleMedium?.copyWith(
                        color: v == 0 ? cs.onSurfaceVariant : (v > 0 ? cs.primary : cs.error),
                        fontWeight: FontWeight.w600)),
                Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  if (v > 0 && !busy)
                    TextButton.icon(
                      onPressed: () => _requestShare(p, v, c),
                      icon: const Icon(Icons.ios_share, size: 18),
                      label: Text(l.request),
                    ),
                  action,
                ]),
              ],
            ),
            const SizedBox(height: 4),
            for (final x in mine)
              Text(
                switch ((
                  data.group(x.groupId)?.state.isFriend == true ? l.nonGroup : data.label(x.groupId, l),
                  formatMoney(x.transfer.amount, c),
                )) {
                  (final g, final m) => x.iPay ? l.linePayThem(g, p.name, m) : l.lineTheyPay(g, p.name, m),
                },
                style: muted,
              ),
            if (v == 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(l.noMoneyMoves, style: muted),
              ),
            if (v < 0 && p.userId != null) ...[
              const SizedBox(height: 8),
              PayChips(
                methods: _methods == null ? null : theirMethods,
                failed: _methodsFailed,
                toName: p.name,
                onPay: (m) => payWith(context, m, toName: p.name, amount: -v, currency: c, note: 'Evensies: ${p.name}'),
              ),
            ],
            for (final gid in unratedIn)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => showConvertSheet(context, groupId: gid, currencies: [c]),
                    icon: const Icon(Icons.currency_exchange, size: 18),
                    label: Text(l.convertIn(data.label(gid, l))),
                  ),
                ),
          ]),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.settleUpWith(p.name))),
      body: lines.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle_outline, size: 64, color: cs.primary),
                const SizedBox(height: 16),
                Text(l.nothingToSettleWith(p.name), style: text.titleMedium),
              ]),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(children: [
                  PersonAvatar(userId: p.userId, name: p.name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(l.settleWithIntro(p.name),
                        style: muted),
                  ),
                ]),
                const SizedBox(height: 16),
                for (final c in currencies) card(c),
              ],
            ),
    );
  }
}
