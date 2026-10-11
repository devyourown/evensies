import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/confirm.dart';
import '../../core/core_guard.dart';
import '../../core/ids.dart';
import '../../core/money.dart';
import '../../core/snack.dart';
import '../../data/db/database.dart';
import '../../data/fx_rates.dart';
import '../../domain/fx.dart';
import '../../domain/models.dart';
import '../../domain/payment_methods.dart';
import '../../domain/settlement.dart';
import '../../providers.dart';
import '../group_detail/balances.dart';
import '../group_detail/convert_sheet.dart';
import '../settings/payment_methods_screen.dart' show methodIcon;

class SettleScreen extends ConsumerStatefulWidget {
  final String groupId;
  const SettleScreen({super.key, required this.groupId});
  @override
  ConsumerState<SettleScreen> createState() => _SettleScreenState();
}

class _SettleScreenState extends ConsumerState<SettleScreen> {
  final _busy = <String>{}; // "$from>$to" or payment id while a write is in progress
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
    Widget body;
    if (group == null || !async.hasValue || state == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (res == null) {
      body = const Center(child: Text(notImplementedLabel));
    } else {
      // Payable transfers come from the group currency only; payments stay in it (docs/API.md 통화별 잔액).
      final transfers = res.transfers(simplify: group.simplifyDebts)[group.defaultCurrency];
      final me = group.myMemberId;
      final pending = state.payments.where((p) => !p.deleted && p.pending && (p.fromMember == me || p.toMember == me)).toList();
      final others = [for (final c in res.byCurrency.keys) if (c != group.defaultCurrency) c]..sort();
      if (transfers == null) {
        body = const Center(child: Text(notImplementedLabel));
      } else if (transfers.isEmpty && pending.isEmpty && res.unsupported == 0 && others.isEmpty) {
        body = Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle_outline, size: 64, color: cs.primary),
            const SizedBox(height: 16),
            Text('Nothing to settle', style: text.titleMedium),
            Text('Everyone is even.', style: TextStyle(color: cs.onSurfaceVariant)),
          ]),
        );
      } else {
        Widget header(String s) => Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 8),
              child: Text(s, style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            );
        body = ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pending.isNotEmpty) ...[
              header('Waiting for confirmation'),
              for (final p in pending) _pendingCard(group, state, p),
              const SizedBox(height: 8),
            ],
            if (res.unsupported > 0)
              Card(
                color: cs.tertiaryContainer,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.construction, color: cs.onTertiaryContainer),
                  title: Text(
                      '${res.unsupported} expense${res.unsupported == 1 ? '' : 's'} with several payers or refunds '
                      "${res.unsupported == 1 ? "isn't" : "aren't"} counted yet",
                      style: TextStyle(color: cs.onTertiaryContainer)),
                ),
              ),
            for (final c in others) _notConvertedCard(group, res, c),
            if (transfers.isNotEmpty)
              header(!group.simplifyDebts
                  ? 'Debts as recorded · simplify debts is off'
                  : res.unsupported > 0
                      ? '${transfers.length} transfer${transfers.length == 1 ? '' : 's'} (some expenses not counted yet)'
                      : '${transfers.length} transfer${transfers.length == 1 ? ' settles' : 's settle'} '
                          // Other currencies' cards are above: this pays only the group currency.
                          '${others.isEmpty ? 'everything' : 'the ${group.defaultCurrency} balance'}'),
            for (final t in transfers) _transferCard(group, state, t),
          ],
        );
      }
    }
    return Scaffold(appBar: AppBar(title: const Text('Settle up')), body: body);
  }

  String _name(GroupState s, String id) => s.member(id)?.name ?? '?';

  Widget _pendingCard(GroupRow group, GroupState s, Payment p) {
    final cs = Theme.of(context).colorScheme;
    final amount = formatMoney(p.amount, p.currency);
    final iReceive = p.toMember == group.myMemberId;
    final busy = _busy.contains(p.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: cs.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(iReceive ? Icons.call_received : Icons.hourglass_top, size: 20, color: cs.onSecondaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                iReceive
                    ? '${_name(s, p.fromMember)} says they sent you $amount'
                    : 'Waiting for ${_name(s, p.toMember)} to confirm $amount',
                style: TextStyle(color: cs.onSecondaryContainer),
              ),
            ),
          ]),
          if (iReceive)
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (busy)
                const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              else ...[
                TextButton(onPressed: () => _notReceived(group, s, p), child: const Text('Not received')),
                const SizedBox(width: 4),
                FilledButton(onPressed: () => _confirm(group, p), child: const Text('Confirm received')),
              ],
            ])
          else
            const SizedBox(height: 4),
        ]),
      ),
    );
  }

  Widget _transferCard(GroupRow group, GroupState s, Transfer t) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final me = group.myMemberId;
    final cur = group.defaultCurrency;
    final iPay = t.from == me;
    final iReceive = t.to == me;
    final receiverMethods = _methods?[t.to] ?? const <PaymentMethod>[];
    final busy = _busy.contains('${t.from}>${t.to}');
    final muted = text.bodySmall?.copyWith(color: cs.onSurfaceVariant);

    Widget actions;
    if (busy) {
      actions = const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
    } else if (iReceive) {
      actions = FilledButton.tonalIcon(
        onPressed: () => _request(group, t),
        icon: const Icon(Icons.ios_share, size: 18),
        label: const Text('Request'),
      );
    } else {
      actions = FilledButton.tonal(
        onPressed: () => _markPaid(group, s, t),
        child: Text(iPay && receiverMethods.isNotEmpty ? "I've sent it" : 'Mark as paid'),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: iPay ? 'You' : _name(s, t.from), style: const TextStyle(fontWeight: FontWeight.w600)),
                    const TextSpan(text: '  →  '),
                    TextSpan(text: iReceive ? 'You' : _name(s, t.to), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(formatMoney(t.amount, cur), style: text.titleLarge?.copyWith(color: cs.primary)),
                if (iPay || iReceive)
                  if (approxIn(ref.watch(homeCurrencyProvider), {cur: t.amount}, ref.watch(latestFxProvider).value?.rates)
                      case final approx?)
                    Text('≈ ${formatMoney(approx, ref.watch(homeCurrencyProvider))}', style: muted),
              ]),
            ),
            const SizedBox(width: 8),
            actions,
          ]),
          if (iPay) ...[
            const SizedBox(height: 8),
            if (_methods == null && !_methodsFailed)
              Text('Loading ways to pay…', style: muted)
            else if (_methodsFailed)
              Text('Offline: ways to pay are not available', style: muted)
            else if (receiverMethods.isEmpty)
              Text('Ask ${_name(s, t.to)} to add a way to get paid', style: muted)
            else
              Wrap(spacing: 8, runSpacing: 4, children: [
                for (final m in receiverMethods)
                  ActionChip(
                    avatar: Icon(methodIcon(m.type), size: 18),
                    label: Text(m.type == PaymentTypes.krBank ? m.bank ?? methodLabel(m.type) : methodLabel(m.type)),
                    onPressed: () => _pay(group, s, t, m),
                  ),
              ]),
          ],
        ]),
      ),
    );
  }

  /// "¥3,000 isn't converted yet · Convert": a bucket Settle up can't pay (payments stay in the group currency).
  Widget _notConvertedCard(GroupRow group, BalanceResult res, String currency) {
    final cs = Theme.of(context).colorScheme;
    final owed = (res.byCurrency[currency] ?? const <String, int>{}).values.where((v) => v > 0).fold(0, (a, v) => a + v);
    final canConvert = fxReady && (res.unrated[currency] ?? 0) > 0;
    return Card(
      key: Key('not-converted-$currency'),
      color: cs.surfaceContainerHigh,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.currency_exchange, color: cs.onSurfaceVariant),
        title: Text("${formatMoney(owed, currency)} isn't converted yet"),
        subtitle: Text(fxReady
            ? 'Convert it to ${group.defaultCurrency} to settle it here'
            : 'Converting to ${group.defaultCurrency}: $notImplementedLabel'),
        trailing: canConvert
            ? FilledButton.tonal(
                onPressed: () => showConvertSheet(context, groupId: group.id, currencies: [currency]),
                child: const Text('Convert'),
              )
            : null,
      ),
    );
  }

  Future<void> _copy(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) showInfo(context, message);
  }

  Future<void> _pay(GroupRow group, GroupState s, Transfer t, PaymentMethod m) async {
    final cur = group.defaultCurrency;
    final note = 'Evensies: ${group.name}';
    final uri = payLink(m, amountMinor: t.amount, currency: cur, note: note);
    if (uri == null) return _bankSheet(group, s, t, m);
    if (!prefillsAmount(m.type)) {
      await _copy(plainAmount(t.amount, cur), 'Amount copied: ${formatMoney(t.amount, cur)}');
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
    if (!ok && mounted) showInfo(context, 'Could not open $uri');
  }

  Future<void> _bankSheet(GroupRow group, GroupState s, Transfer t, PaymentMethod m) {
    final cur = group.defaultCurrency;
    final amount = formatMoney(t.amount, cur);
    final iban = m.type == PaymentTypes.iban;
    final qr = iban && cur == 'EUR';
    final account = iban ? m.value.replaceAllMapped(RegExp(r'.{4}'), (x) => '${x[0]} ').trim() : m.value;
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final text = Theme.of(ctx).textTheme;
        Widget line(String label, String value) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 96, child: Text(label, style: TextStyle(color: cs.onSurfaceVariant))),
                Expanded(child: SelectableText(value, style: text.bodyLarge)),
              ]),
            );
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Pay ${_name(s, t.to)} $amount', style: text.titleLarge),
              const SizedBox(height: 12),
              if (qr) ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: QrImageView(
                      key: const Key('epc-qr'),
                      data: epcPayload(
                          name: m.holder ?? '', iban: m.value, bic: m.bic, amountCents: t.amount, remittance: 'Evensies: ${group.name}'),
                      size: 200,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Scan with your banking app (SEPA QR)',
                    textAlign: TextAlign.center, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 12),
              ] else if (iban) ...[
                Text('QR code is only available for EUR transfers.', style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 8),
              ],
              if (!iban) line('Bank', m.bank ?? ''),
              line(iban ? 'IBAN' : 'Account', account),
              if (iban && m.bic != null) line('BIC', m.bic!),
              line('Holder', m.holder ?? ''),
              line('Amount', amount),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy, size: 18),
                    label: Text(iban ? 'Copy IBAN' : 'Copy account'),
                    onPressed: () => _copy(iban ? m.value : '${m.bank} ${m.value}', iban ? 'IBAN copied' : 'Account copied'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy amount'),
                    onPressed: () => _copy(plainAmount(t.amount, cur), 'Amount copied: $amount'),
                  ),
                ),
              ]),
            ]),
          ),
        );
      },
    );
  }

  Future<void> _request(GroupRow group, Transfer t) async {
    final cur = group.defaultCurrency;
    final msg = requestText(
      formattedAmount: formatMoney(t.amount, cur),
      group: group.name,
      methods: _methods?[group.myMemberId] ?? const [],
      amountMinor: t.amount,
      currency: cur,
    );
    await SharePlus.instance.share(ShareParams(text: msg));
  }

  Future<void> _markPaid(GroupRow group, GroupState s, Transfer t) async {
    final key = '${t.from}>${t.to}';
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
              currency: group.defaultCurrency,
              date: todayIso(),
              status: confirmed ? 'confirmed' : 'sent',
            ),
          );
      final amount = formatMoney(t.amount, group.defaultCurrency);
      if (mounted) {
        showInfo(context, confirmed ? 'Payment of $amount recorded' : 'Marked as sent. ${_name(s, t.to)} will confirm.');
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
    final ok = await confirm(context,
        title: 'Not received?',
        message: 'The payment from ${_name(s, p.fromMember)} is removed and the debt comes back.',
        confirmLabel: 'Not received');
    if (!ok) return;
    setState(() => _busy.add(p.id));
    try {
      await ref.read(localWritesProvider).deletePayment(group.id, p.id);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy.remove(p.id));
    }
  }
}
