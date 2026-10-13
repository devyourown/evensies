import 'package:flutter/material.dart';

import '../../core/l10n.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../domain/itemized.dart';
import '../../domain/models.dart';
import '../../domain/split.dart';
import '../../l10n/app_localizations_en.dart';

/// Whether a percent or shares [spec] still computes for [ids] (people missing from it get 0): false when e.g. the
/// percentages of people who left no longer add up to 100.
bool splitFits(SplitSpec spec, List<String> ids) {
  final mode = spec.mode;
  if (mode == null) return false; // itemized: never a default split
  try {
    computeSplit(amount: 10000, mode: mode, members: ids, input: {for (final id in ids) id: spec.input?[id] ?? 0.0});
    return true;
  } on SplitException {
    return false;
  }
}

/// Why an itemized bill can't be saved (computeItemizedSplit's codes).
String itemizedErrorText(AppLocalizations l, String code) => switch (code) {
      'UNASSIGNED_ITEM' => l.itemsGiveEveryone,
      'ZERO_SUBTOTAL' => l.itemsAddPrices,
      'NEGATIVE_TOTAL' => l.itemsDiscountTooBig,
      'NEGATIVE_AMOUNT' => l.errorNegativeAmount,
      _ => l.itemsDontAddUp,
    };


/// What the rows add up to: [shares] (memberId → minor units) when an amount was given and the split works,
/// a [status] line for under the rows, and whether it can be saved.
typedef SplitOutcome = ({Map<String, int>? shares, String status, bool ok});

/// State of [SplitEditor]: the mode, who is ticked for equal, one text field per member and mode, and the items.
class SplitEditorController extends ChangeNotifier {
  SplitMode _mode;
  SplitEditorController([this._mode = SplitMode.equal]);

  /// Items (docs/API.md, Itemized split): the bill from the Itemize screen. [mode] waits underneath while it is on.
  ItemizedBill? _bill;
  bool _items = false;
  bool get items => _items;
  ItemizedBill? get bill => _bill;

  /// Items mode with [b] (from the Itemize screen, or a stored itemized split).
  void setItems(ItemizedBill b) {
    _bill = b;
    _items = true;
    notifyListeners();
  }

  /// Members left out of an equal split; everyone else (also people who join later) is in.
  final unticked = <String>{};
  final _fields = <(SplitMode, String), TextEditingController>{};
  final _loaded = <SplitMode>{};

  SplitMode get mode => _mode;
  set mode(SplitMode m) {
    _mode = m;
    _items = false;
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
    _items = false;
    unticked
      ..clear()
      ..addAll(shown.where((m) => !ids.contains(m)));
    notifyListeners();
  }

  /// The typed numbers of a stored percent / shares / adjustment split, or the items of an itemized one.
  void load(SplitSpec spec, String currency) {
    final mode = spec.mode;
    if (spec.bill case final b?) return setItems(b);
    _mode = mode!;
    _items = false;
    if (mode == SplitMode.equal) return notifyListeners();
    _loaded.add(mode);
    for (final c in _fields.entries.where((e) => e.key.$1 == mode)) {
      c.value.text = '';
    }
    for (final e in (spec.input ?? const <String, double>{}).entries) {
      field(mode, e.key).text = mode == SplitMode.adjustment ? inputAmount(e.value.round(), currency) : numberText(e.value, decimals: 6);
    }
    notifyListeners();
  }

  void loadExact(List<Share> shares, String currency) {
    _mode = SplitMode.exact;
    _items = false;
    for (final s in shares) {
      field(SplitMode.exact, s.memberId).text = inputAmount(s.amount, currency);
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
        _ => parseDecimal(t),
      };
      if (v == null || !v.isFinite) return null;
      if ((_mode == SplitMode.percent || _mode == SplitMode.shares) && v < 0) return null;
      out[id] = v.toDouble();
    }
    return out;
  }

  /// The `split` to store (docs/API.md SplitSpec): null for exact.
  SplitSpec? spec(List<String> ids, String currency) => _items
      ? switch (_bill) { final b? => SplitSpec.itemized(b), null => null }
      : switch (_mode) {
    SplitMode.exact => null,
    SplitMode.equal => const SplitSpec(SplitMode.equal),
    final m => switch (input(ids, currency)) {
      final i? => SplitSpec(m, i),
      null => null,
    },
  };

  /// [ids] = the members on screen; [amount] null = no total yet (the default-split sheet). The status is in [l]'s
  /// language (English when not given: callers that only read `ok`).
  SplitOutcome evaluate(
      {required int? amount, required List<String> ids, required String currency, AppLocalizations? l}) {
    final t = l ?? AppLocalizationsEn();
    final has = amount != null && amount > 0;
    Map<String, int> run(List<String> members, Map<String, double>? input) =>
        computeSplit(amount: amount!, mode: _mode, members: members, input: input);
    String error(SplitException e) => switch (e.code) {
      'NEGATIVE_SHARE' => t.adjustmentsDontFit,
      'NO_MEMBERS' => t.giveSomeoneShare,
      'INVALID_INPUT' => t.checkNumbers,
      _ => t.splitDoesntAddUp,
    };
    if (_items) {
      final b = _bill;
      if (b == null) return (shares: null, status: t.addTheItems, ok: false);
      try {
        return (shares: computeItemizedSplit(b), status: '', ok: true); // the summary names everyone's part
      } on SplitException catch (e) {
        return (shares: null, status: itemizedErrorText(t, e.code), ok: false);
      }
    }
    try {
      switch (_mode) {
        case SplitMode.equal:
          final ticked = ids.where((id) => !unticked.contains(id)).toList();
          if (ticked.isEmpty) return (shares: null, status: t.pickOnePerson, ok: false);
          if (!has) return (shares: null, status: t.splitEquallyBetween(ticked.length), ok: true);
          return (
            shares: run(ticked, null),
            status: ticked.length == 1
                ? t.allForOnePerson
                : t.splitEquallyEach(ticked.length, formatMoney(amount ~/ ticked.length, currency)),
            ok: true,
          );
        case SplitMode.exact:
          final input = this.input(ids, currency);
          if (input == null) return (shares: null, status: t.checkAmounts, ok: false);
          if (!has) return (shares: null, status: t.enterTotalFirst, ok: false);
          final rem = amount - input.values.fold(0.0, (a, b) => a + b).round();
          if (rem != 0) {
            final r = formatMoney(rem.abs(), currency);
            return (shares: null, status: rem > 0 ? t.remaining(r) : t.overBy(r), ok: false);
          }
          return (shares: run(ids, input), status: t.addsUp, ok: true);
        case SplitMode.percent:
          final input = this.input(ids, currency);
          if (input == null) return (shares: null, status: t.checkNumbers, ok: false);
          final rem = 100 - input.values.fold(0.0, (a, b) => a + b);
          if (rem.abs() >= 0.001) {
            return (
              shares: null,
              status: rem > 0
                  ? t.remaining(t.percentValue(numberText(rem)))
                  : t.overBy(t.percentValue(numberText(-rem))),
              ok: false,
            );
          }
          if (!has) return (shares: null, status: t.addsUp, ok: true);
          return (shares: run(ids, input), status: t.addsUp, ok: true);
        case SplitMode.shares:
          final input = this.input(ids, currency);
          if (input == null) return (shares: null, status: t.checkNumbers, ok: false);
          final total = input.values.fold(0.0, (a, b) => a + b);
          if (total <= 0) return (shares: null, status: t.giveSomeoneShare, ok: false);
          final status = total == 1 ? t.oneShareInTotal : t.sharesInTotal(numberText(total));
          if (!has) return (shares: null, status: status, ok: true);
          return (shares: run(ids, input), status: status, ok: true);
        case SplitMode.adjustment:
          final input = this.input(ids, currency);
          if (input == null) return (shares: null, status: t.checkAmounts, ok: false);
          if (!has) return (shares: null, status: t.enterTotalFirst, ok: false);
          return (shares: run(ids, input), status: t.restSplitEqually, ok: true);
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

/// Per-member split rows with the mode chips: Equal (tick boxes) · Exact · % · Shares · ± (adjustment) · Items,
/// the live amount on each row and a status line ("remaining: €2.00", "Adds up", errors). Used by the expense form
/// and by the default-split sheet in group settings ([amount] null there).
class SplitEditor extends StatelessWidget {
  final SplitEditorController controller;
  final List<MemberRow> members;
  final int? amount;
  final String currency;
  final List<SplitMode> modes;

  /// Opens the Itemize screen (the form's); null hides Items.
  final VoidCallback? onItems;
  const SplitEditor({
    super.key,
    required this.controller,
    required this.members,
    required this.amount,
    required this.currency,
    this.modes = SplitMode.values,
    this.onItems,
  });

  static String? _tooltip(AppLocalizations l, SplitMode m) => switch (m) {
        SplitMode.percent => l.byPercent,
        SplitMode.shares => l.byShares,
        SplitMode.adjustment => l.byAdjustment,
        _ => null,
      };

  static String _label(AppLocalizations l, SplitMode m) => switch (m) {
        SplitMode.equal => l.modeEqual,
        SplitMode.exact => l.modeExact,
        SplitMode.percent => '%',
        SplitMode.shares => l.modeShares,
        SplitMode.adjustment => '±',
      };

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: controller, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final c = controller;
    final l = context.l;
    final ids = [for (final m in members) m.id];
    final out = c.evaluate(amount: amount, ids: ids, currency: currency, l: l);
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
        SplitMode.adjustment => ('±', currency, inputAmount(0, currency)),
        _ => (null, currency, inputAmount(0, currency)), // 0, 0.00 or 0.000: the currency's decimals
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
    final items = c.items;
    final neutral = mode == SplitMode.equal || mode == SplitMode.shares || mode == SplitMode.adjustment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Six ways don't fit a segmented control: chips that wrap (whole words at every text size).
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final m in modes)
            ChoiceChip(
              label: Text(_label(l, m), key: Key('mode-${m.name}')),
              tooltip: _tooltip(l, m),
              selected: !items && m == mode,
              onSelected: (_) => c.mode = m,
            ),
          if (onItems != null)
            ChoiceChip(
              label: Text(l.items, key: const Key('mode-itemized')),
              tooltip: l.byItem,
              selected: items,
              // Back to the items already made, else the Itemize screen.
              onSelected: (_) => c.bill == null ? onItems!() : c.setItems(c.bill!),
            ),
        ]),
        if (items)
          _ItemsSummary(bill: c.bill, shares: shares, members: members, currency: currency, onEdit: onItems!)
        else ...[
          if (mode == SplitMode.adjustment)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l.adjustmentHelp,
                style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          for (final m in members) row(m),
        ],
        if (members.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l.noMembers, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
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

/// "4 items · Anna €18.40 · Ben €22.80 · Edit" (docs/API.md, Itemized split).
class _ItemsSummary extends StatelessWidget {
  final ItemizedBill? bill;
  final Map<String, int>? shares;
  final List<MemberRow> members;
  final String currency;
  final VoidCallback onEdit;
  const _ItemsSummary(
      {required this.bill, required this.shares, required this.members, required this.currency, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final n = bill?.lines.length ?? 0;
    final names = {for (final m in members) m.id: m.name};
    final s = shares ?? const <String, int>{};
    // In the order people are listed, anyone else (not shown here) after them.
    final ids = [for (final m in members) if (s.containsKey(m.id)) m.id, for (final id in s.keys) if (!names.containsKey(id)) id];
    final l = context.l;
    final parts = [for (final id in ids) '${names[id] ?? l.someone} ${formatMoney(s[id]!, currency)}'];
    return Card(
      key: const Key('items-summary'),
      margin: const EdgeInsets.only(top: 12),
      color: cs.surfaceContainerHigh,
      child: ListTile(
        leading: Icon(Icons.receipt_long_outlined, color: cs.primary),
        title: Text(l.itemCount(n), style: text.titleSmall),
        subtitle: parts.isEmpty ? null : Text(parts.join(' · ')),
        trailing: TextButton(key: const Key('items-edit'), onPressed: onEdit, child: Text(l.edit)),
        onTap: onEdit,
      ),
    );
  }
}
