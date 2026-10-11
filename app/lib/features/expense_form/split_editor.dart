import 'package:flutter/material.dart';

import '../../core/core_guard.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../domain/models.dart';
import '../../domain/split.dart';

/// Whether computeSplit handles [mode] (false while that mode is a stub that throws UnimplementedError).
bool splitModeReady(SplitMode mode) =>
    implemented(() => computeSplit(amount: 0, mode: mode, members: const ['a'], input: const {'a': 0}));

/// Whether [spec] still computes for [ids] (people missing from it get 0): false when it doesn't (e.g. the
/// percentages of people who left no longer add up to 100), null while computeSplit is a stub for that mode.
bool? splitFits(SplitSpec spec, List<String> ids) {
  final input = {for (final id in ids) id: spec.input?[id] ?? 0.0};
  try {
    return tryCore(() => computeSplit(amount: 10000, mode: spec.mode, members: ids, input: input)) == null ? null : true;
  } on SplitException {
    return false;
  }
}

/// "1.5", "-10.00" → text; minor units go through the currency's decimals.
String minorToText(int minor, String currency) {
  final d = Money.digits(currency);
  final s = minor.abs().toString().padLeft(d + 1, '0');
  final r = d == 0 ? s : '${s.substring(0, s.length - d)}.${s.substring(s.length - d)}';
  return minor < 0 ? '-$r' : r;
}

/// At most two decimals, no trailing zeros: 33.3, 12.5, 2.
String trimNum(num v) => v.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

/// A typed number as it was typed: 2, 1.5, 33.333.
String _numText(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();

/// What the rows add up to: [shares] (memberId → minor units) when an amount was given and the split works,
/// a [status] line for under the rows, and whether it can be saved.
typedef SplitOutcome = ({Map<String, int>? shares, String status, bool ok});

/// State of [SplitEditor]: the mode, who is ticked for equal, and one text field per member and mode.
class SplitEditorController extends ChangeNotifier {
  SplitMode _mode;
  SplitEditorController([this._mode = SplitMode.equal]);

  /// Members left out of an equal split; everyone else (also people who join later) is in.
  final unticked = <String>{};
  final _fields = <(SplitMode, String), TextEditingController>{};
  final _loaded = <SplitMode>{};

  SplitMode get mode => _mode;
  set mode(SplitMode m) {
    _mode = m;
    notifyListeners();
  }

  void tick(String id, bool on) {
    on ? unticked.remove(id) : unticked.add(id);
    notifyListeners();
  }

  TextEditingController field(SplitMode mode, String memberId) => _fields.putIfAbsent((mode, memberId), () {
    // A fresh shares split starts at one share each; a loaded one counts missing people as 0.
    final c = TextEditingController(text: mode == SplitMode.shares && !_loaded.contains(mode) ? '1' : '');
    c.addListener(notifyListeners);
    return c;
  });

  /// Equal over [ids] only: everyone else in [shown] is unticked.
  void loadEqual(Iterable<String> ids, Iterable<String> shown) {
    _mode = SplitMode.equal;
    unticked
      ..clear()
      ..addAll(shown.where((m) => !ids.contains(m)));
    notifyListeners();
  }

  /// The typed numbers of a stored percent / shares / adjustment split.
  void load(SplitSpec spec, String currency) {
    _mode = spec.mode;
    if (spec.mode == SplitMode.equal) return notifyListeners();
    _loaded.add(spec.mode);
    for (final c in _fields.entries.where((e) => e.key.$1 == spec.mode)) {
      c.value.text = '';
    }
    for (final e in (spec.input ?? const <String, double>{}).entries) {
      field(spec.mode, e.key).text = spec.mode == SplitMode.adjustment
          ? minorToText(e.value.round(), currency)
          : _numText(e.value);
    }
    notifyListeners();
  }

  void loadExact(List<Share> shares, String currency) {
    _mode = SplitMode.exact;
    for (final s in shares) {
      field(SplitMode.exact, s.memberId).text = minorToText(s.amount, currency);
    }
    notifyListeners();
  }

  /// Typed numbers per member (empty = 0): minor units for exact and adjustment. Null if one doesn't parse,
  /// or a percent / share count is below zero.
  Map<String, double>? input(List<String> ids, String currency) {
    final out = <String, double>{};
    for (final id in ids) {
      final t = field(_mode, id).text.trim();
      if (t.isEmpty) {
        out[id] = 0;
        continue;
      }
      final num? v = switch (_mode) {
        SplitMode.exact || SplitMode.adjustment => parseMoney(t, currency),
        _ => double.tryParse(t),
      };
      if (v == null || !v.isFinite) return null;
      if ((_mode == SplitMode.percent || _mode == SplitMode.shares) && v < 0) return null;
      out[id] = v.toDouble();
    }
    return out;
  }

  /// The `split` to store (docs/API.md SplitSpec): null for exact.
  SplitSpec? spec(List<String> ids, String currency) => switch (_mode) {
    SplitMode.exact => null,
    SplitMode.equal => const SplitSpec(SplitMode.equal),
    final m => switch (input(ids, currency)) {
      final i? => SplitSpec(m, i),
      null => null,
    },
  };

  /// [ids] = the members on screen; [amount] null = no total yet (the default-split sheet).
  SplitOutcome evaluate({required int? amount, required List<String> ids, required String currency}) {
    final has = amount != null && amount > 0;
    Map<String, int>? run(List<String> members, Map<String, double>? input) =>
        tryCore(() => computeSplit(amount: amount!, mode: _mode, members: members, input: input));
    String error(SplitException e) => switch (e.code) {
      'NEGATIVE_SHARE' => "Adjustments don't fit the total",
      'NO_MEMBERS' => 'Give someone a share',
      'INVALID_INPUT' => 'Check the numbers',
      _ => "The split doesn't add up",
    };
    if (!splitModeReady(_mode)) return (shares: null, status: notImplementedLabel, ok: false);
    try {
      switch (_mode) {
        case SplitMode.equal:
          final ticked = ids.where((id) => !unticked.contains(id)).toList();
          if (ticked.isEmpty) return (shares: null, status: 'Pick at least one person', ok: false);
          final people = '${ticked.length} ${ticked.length == 1 ? 'person' : 'people'}';
          if (!has) return (shares: null, status: 'Split equally between $people', ok: true);
          final shares = run(ticked, null);
          return (
            shares: shares,
            status: ticked.length == 1
                ? 'All of it for 1 person'
                : 'Split equally between $people · ${formatMoney(amount ~/ ticked.length, currency)} each',
            ok: shares != null,
          );
        case SplitMode.exact:
          final input = this.input(ids, currency);
          if (input == null) return (shares: null, status: 'Check the amounts', ok: false);
          if (!has) return (shares: null, status: 'Enter the total first', ok: false);
          final rem = amount - input.values.fold(0.0, (a, b) => a + b).round();
          if (rem != 0) {
            final r = formatMoney(rem.abs(), currency);
            return (shares: null, status: rem > 0 ? 'remaining: $r' : 'over by: $r', ok: false);
          }
          return (shares: run(ids, input), status: 'Adds up', ok: true);
        case SplitMode.percent:
          final input = this.input(ids, currency);
          if (input == null) return (shares: null, status: 'Check the numbers', ok: false);
          final rem = 100 - input.values.fold(0.0, (a, b) => a + b);
          if (rem.abs() >= 0.001) {
            return (
              shares: null,
              status: rem > 0 ? 'remaining: ${trimNum(rem)}%' : 'over by: ${trimNum(-rem)}%',
              ok: false,
            );
          }
          if (!has) return (shares: null, status: 'Adds up', ok: true);
          final shares = run(ids, input);
          return (shares: shares, status: 'Adds up', ok: shares != null);
        case SplitMode.shares:
          final input = this.input(ids, currency);
          if (input == null) return (shares: null, status: 'Check the numbers', ok: false);
          final total = input.values.fold(0.0, (a, b) => a + b);
          if (total <= 0) return (shares: null, status: 'Give someone a share', ok: false);
          final status = '${trimNum(total)} ${total == 1 ? 'share' : 'shares'} in total';
          if (!has) return (shares: null, status: status, ok: true);
          final shares = run(ids, input);
          return (shares: shares, status: status, ok: shares != null);
        case SplitMode.adjustment:
          final input = this.input(ids, currency);
          if (input == null) return (shares: null, status: 'Check the amounts', ok: false);
          if (!has) return (shares: null, status: 'Enter the total first', ok: false);
          final shares = run(ids, input);
          return (shares: shares, status: 'The rest is split equally', ok: shares != null);
      }
    } on SplitException catch (e) {
      return (shares: null, status: error(e), ok: false);
    }
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }
}

/// Per-member split rows with the mode switch: Equal (tick boxes) · Exact · % · Shares · ± (adjustment),
/// the live amount on each row and a status line ("remaining: €2.00", "Adds up", errors). Used by the expense form
/// and by the default-split sheet in group settings ([amount] null there).
class SplitEditor extends StatelessWidget {
  final SplitEditorController controller;
  final List<MemberRow> members;
  final int? amount;
  final String currency;
  final List<SplitMode> modes;
  const SplitEditor({
    super.key,
    required this.controller,
    required this.members,
    required this.amount,
    required this.currency,
    this.modes = SplitMode.values,
  });

  static String? _tooltip(SplitMode m) => splitModeReady(m)
      ? switch (m) {
          SplitMode.percent => 'By percent',
          SplitMode.shares => 'By shares',
          SplitMode.adjustment => 'Adjust: extra or less for someone, the rest equally',
          _ => null,
        }
      : notImplementedLabel;

  static const _labels = {
    SplitMode.equal: 'Equal',
    SplitMode.exact: 'Exact',
    SplitMode.percent: '%',
    SplitMode.shares: 'Shares',
    SplitMode.adjustment: '±',
  };

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: controller, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final c = controller;
    final ids = [for (final m in members) m.id];
    final out = c.evaluate(amount: amount, ids: ids, currency: currency);
    final shares = out.shares;
    final mode = c.mode;

    Widget live(String id) => SizedBox(
      width: 88,
      child: Text(
        shares?[id] == null ? '' : formatMoney(shares![id]!, currency),
        key: Key('live-$id'),
        textAlign: TextAlign.end,
        style: text.bodyMedium?.copyWith(color: (shares?[id] ?? 0) == 0 ? cs.onSurfaceVariant : cs.onSurface),
      ),
    );

    Widget row(MemberRow m) {
      if (mode == SplitMode.equal) {
        final on = !c.unticked.contains(m.id);
        return CheckboxListTile(
          key: Key('tick-${m.id}'),
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: on,
          title: Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          secondary: amount == null ? null : live(m.id),
          onChanged: (v) => c.tick(m.id, v ?? false),
        );
      }
      final (String? prefix, String? suffix, String hint) = switch (mode) {
        SplitMode.percent => (null, '%', '0'),
        SplitMode.shares => (null, null, '0'),
        SplitMode.adjustment => ('±', currency, minorToText(0, currency)),
        _ => (null, currency, minorToText(0, currency)), // 0, 0.00 or 0.000: the currency's decimals
      };
      final field = TextField(
        key: Key('share-${m.id}'),
        controller: c.field(mode, m.id),
        keyboardType: TextInputType.numberWithOptions(decimal: true, signed: mode == SplitMode.adjustment),
        textAlign: mode == SplitMode.exact ? TextAlign.start : TextAlign.end,
        decoration: InputDecoration(
          labelText: mode == SplitMode.exact ? m.name : null,
          hintText: hint,
          isDense: true,
          prefixText: prefix,
          suffixText: suffix,
        ),
      );
      if (mode == SplitMode.exact) return Padding(padding: const EdgeInsets.only(top: 8), child: field);
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Expanded(child: Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            SizedBox(width: mode == SplitMode.adjustment ? 132 : 96, child: field),
            if (amount != null) live(m.id),
          ],
        ),
      );
    }

    final good = out.ok;
    final color = good ? cs.primary : cs.error;
    final neutral = mode == SplitMode.equal || mode == SplitMode.shares || mode == SplitMode.adjustment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The largest text sizes: chips that wrap, not segments that break the words mid-way.
        if (MediaQuery.textScalerOf(context).scale(1) > 2)
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final m in modes)
              ChoiceChip(
                label: Text(_labels[m]!, key: Key('mode-${m.name}')),
                tooltip: _tooltip(m),
                selected: m == mode,
                onSelected: splitModeReady(m) ? (_) => c.mode = m : null,
              ),
          ])
        else
          SegmentedButton<SplitMode>(
            showSelectedIcon: false,
            segments: [
              for (final m in modes)
                ButtonSegment(
                  value: m,
                  label: Text(_labels[m]!, key: Key('mode-${m.name}')),
                  enabled: splitModeReady(m),
                  tooltip: _tooltip(m),
                ),
            ],
            selected: {mode},
            onSelectionChanged: (s) => c.mode = s.first,
          ),
        if (mode == SplitMode.adjustment)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Add or take off an amount for someone; the rest is split equally.',
              style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        for (final m in members) row(m),
        if (members.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('No members', style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          )
        else if (out.status.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  good ? (neutral ? Icons.info_outline : Icons.check_circle_outline) : Icons.error_outline,
                  size: 16,
                  color: good && neutral ? cs.onSurfaceVariant : color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    out.status,
                    key: const Key('split-status'),
                    style: text.bodySmall?.copyWith(color: good && neutral ? cs.onSurfaceVariant : color),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
