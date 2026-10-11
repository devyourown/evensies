import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/snack.dart';
import '../../data/api/dto.dart';
import '../../data/fx_rates.dart';
import '../../domain/fx.dart';
import '../../domain/models.dart';
import '../../providers.dart';
import 'balances.dart';

/// Expenses in [currency] that count as not converted: not deleted, rate null or 0 (docs/API.md 통화 환산).
List<Expense> unconvertedIn(GroupState s, String currency) => [
      for (final e in s.expenses)
        if (!e.deleted && e.currency == currency && !((e.fxRateToDefault ?? 0) > 0)) e,
    ];

/// Convert to the group currency (docs/API.md 통화 환산 Convert): per currency the count, the total, a rate prefilled
/// from `GET /fx` (or the cache) and a preview. Convert writes the rate into every one of those expenses.
Future<void> showConvertSheet(BuildContext context, {required String groupId, required List<String> currencies}) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => ConvertSheet(groupId: groupId, currencies: currencies),
    );

class ConvertSheet extends ConsumerStatefulWidget {
  final String groupId;
  final List<String> currencies;
  const ConvertSheet({super.key, required this.groupId, required this.currencies});
  @override
  ConsumerState<ConvertSheet> createState() => _ConvertSheetState();
}

class _ConvertSheetState extends ConsumerState<ConvertSheet> {
  late final _rates = {for (final c in widget.currencies) c: TextEditingController()};
  FxTable? _table;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  /// Today's rates (or the newest cached ones).
  Future<void> _prefill() async {
    final table = await ref.read(fxRatesProvider).lookup();
    final d = (await ref.read(dbProvider).getGroup(widget.groupId))?.defaultCurrency;
    if (!mounted) return;
    setState(() {
      _loading = false;
      _table = table;
      for (final MapEntry(key: c, value: ctl) in _rates.entries) {
        final r = table == null || d == null ? null : crossRate(table.rates, c, d);
        if (r != null && ctl.text.isEmpty) ctl.text = r.toString();
      }
    });
  }

  @override
  void dispose() {
    for (final c in _rates.values) {
      c.dispose();
    }
    super.dispose();
  }

  double? _rate(String c) {
    final r = double.tryParse(_rates[c]!.text.trim().replaceAll(',', '.'));
    return r != null && r.isFinite && r > 0 ? r : null;
  }

  Future<void> _convert(String d, Map<String, int> counts) async {
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final writes = ref.read(localWritesProvider), groupId = widget.groupId; // Undo runs after this sheet is gone
    try {
      final before = <String, Map<String, double?>>{}; // currency → expenseId → previous rate
      for (final c in widget.currencies) {
        final r = _rate(c);
        if (r != null && (counts[c] ?? 0) > 0) before[c] = await writes.convertCurrency(groupId, c, r);
      }
      final n = before.values.fold(0, (a, m) => a + m.length);
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text('Converted $n expense${n == 1 ? '' : 's'} to $d'),
        action: n == 0
            ? null
            : SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  for (final MapEntry(key: c, value: m) in before.entries) {
                    writes.setRates(groupId, c, m);
                  }
                },
              ),
      ));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupProvider(widget.groupId)).value;
    final state = ref.watch(groupStateProvider(widget.groupId)).value;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (group == null || state == null) {
      return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
    }
    final d = group.defaultCurrency;
    final counts = <String, int>{};
    final t = _table;
    final source = t == null
        ? 'No automatic rate. Enter one.'
        : '${t.offline ? 'offline · ' : ''}rate of ${DateFormat('d MMM').format(DateTime.parse(t.date))}';
    final rows = <Widget>[];
    for (final c in widget.currencies) {
      final xs = unconvertedIn(state, c);
      counts[c] = xs.length;
      final total = xs.fold<int>(0, (a, e) => a + (e.refund ? -e.amount : e.amount));
      final r = _rate(c);
      final preview = r == null
          ? null
          : tryFx(() => convertAmount(amount: total, fromDecimals: Money.digits(c), toDecimals: Money.digits(d), rate: r));
      rows.add(Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Text('${formatMoney(total, c)} · ${xs.length} expense${xs.length == 1 ? '' : 's'}',
                  style: text.titleMedium),
            ),
            if (preview != null)
              Text('≈ ${formatMoney(preview, d)}', style: text.titleMedium?.copyWith(color: cs.primary)),
          ]),
          const SizedBox(height: 8),
          TextField(
            key: Key('convert-rate-$c'),
            controller: _rates[c],
            enabled: xs.isNotEmpty,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Rate: 1 $c in $d',
              prefixIcon: const Icon(Icons.currency_exchange),
              helperText: xs.isEmpty ? 'Nothing left to convert' : (_loading ? 'Looking up the rate…' : source),
              errorText: _rates[c]!.text.trim().isNotEmpty && r == null ? 'Enter a rate above 0' : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ]),
      ));
    }
    final ready = widget.currencies.any((c) => (counts[c] ?? 0) > 0 && _rate(c) != null);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Convert to $d', style: text.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Fills in this rate on every expense that has none, so they count in $d balances. '
              'You can still change the rate on each expense.',
              style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            ...rows,
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const Key('convert'),
              onPressed: ready && !_busy ? () => _convert(d, counts) : null,
              icon: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.currency_exchange),
              label: Text('Convert to $d'),
            ),
          ]),
        ),
      ),
    );
  }
}
