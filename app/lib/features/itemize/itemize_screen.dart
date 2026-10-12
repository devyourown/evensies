import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../domain/itemized.dart';
import '../../domain/split.dart';
import '../expense_form/split_editor.dart' show itemizedErrorText, minorToText, trimNum;

/// Server limits on a bill (docs/API.md SplitSpec itemized).
const maxItemLines = 200, maxItemName = 100;

/// Opens the Itemize screen and returns the bill on Done (null when the user goes back). [members]: the group's,
/// removed ones included (a removed member already on a line stays there, by name). [image]: the receipt photo, shown on
/// top; [printedTotal]: what the scanned receipt says it comes to (a mismatch is a warning, not an error), and
/// [printedTip] whether that total has a tip in it (a tip added on the card slip isn't a mismatch); [me]: my member,
/// "You" and first under Each person.
Future<ItemizedBill?> showItemize(
  BuildContext context, {
  required List<MemberRow> members,
  required String currency,
  ItemizedBill? bill,
  File? image,
  int? printedTotal,
  bool printedTip = true,
  String? me,
}) =>
    Navigator.of(context).push<ItemizedBill>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ItemizeScreen(
          members: members,
          currency: currency,
          bill: bill,
          image: image,
          printedTotal: printedTotal,
          printedTip: printedTip,
          me: me),
    ));

/// Lines with prices and the people on each; tax, tip and a discount spread by subtotal; live per-person totals
/// (docs/API.md 항목별 분할).
class ItemizeScreen extends StatefulWidget {
  final List<MemberRow> members;
  final String currency;
  final ItemizedBill? bill;
  final File? image;
  final int? printedTotal;
  final bool printedTip;
  final String? me;
  const ItemizeScreen({
    super.key,
    required this.members,
    required this.currency,
    this.bill,
    this.image,
    this.printedTotal,
    this.printedTip = true,
    this.me,
  });
  @override
  State<ItemizeScreen> createState() => _ItemizeScreenState();
}

class _Line {
  final key = UniqueKey();
  final name = TextEditingController();
  final amount = TextEditingController();
  final people = <String>{};
  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

/// Tax, tip or discount: an amount, or a percent of the subtotal (always stored as the amount).
class _Extra {
  final text = TextEditingController();
  bool percent = false;
}

class _ItemizeScreenState extends State<ItemizeScreen> {
  final _lines = <_Line>[];
  final _tax = _Extra(), _tip = _Extra(), _discount = _Extra();

  String get _cur => widget.currency;

  @override
  void initState() {
    super.initState();
    final b = widget.bill;
    for (final l in b?.lines ?? const <ItemLine>[]) {
      _lines.add(_Line()
        ..name.text = l.name
        ..amount.text = minorToText(l.amount, _cur)
        ..people.addAll(l.memberIds));
    }
    if (_lines.isEmpty) _lines.add(_Line());
    for (final (e, v) in [(_tax, b?.tax ?? 0), (_tip, b?.tip ?? 0), (_discount, b?.discount ?? 0)]) {
      if (v != 0) e.text.text = minorToText(v, _cur);
    }
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    for (final e in [_tax, _tip, _discount]) {
      e.text.dispose();
    }
    super.dispose();
  }

  List<MemberRow> get _active => [for (final m in widget.members) if (!m.removed) m];

  /// The amount of [e] in minor units, a percent going through [percentOf]; null when it doesn't parse.
  int? _extra(_Extra e, int subtotal) {
    final t = e.text.text.trim();
    if (t.isEmpty) return 0;
    if (!e.percent) return parseMoney(t, _cur);
    final pct = double.tryParse(t.replaceAll(',', '.'));
    return pct == null || !pct.isFinite || pct < 0 ? null : percentOf(subtotal, pct);
  }

  /// Switching keeps what it is worth: 10 % of €40.00 becomes €4.00 and back.
  void _toggle(_Extra e, bool percent, int subtotal) {
    if (e.percent == percent) return;
    final v = _extra(e, subtotal);
    setState(() {
      e.percent = percent;
      if (v == null || v == 0) return;
      e.text.text = percent ? (subtotal == 0 ? '' : trimNum(v * 100 / subtotal)) : minorToText(v, _cur);
    });
  }

  void _addLine() => setState(() => _lines.add(_Line()));

  void _everyone() => setState(() {
        for (final l in _lines.where((l) => l.people.isEmpty)) {
          l.people.addAll(_active.map((m) => m.id));
        }
      });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final names = {for (final m in widget.members) m.id: m.name};

    // What the screen holds as a bill, or why not yet.
    final amounts = [for (final l in _lines) parseMoney(l.amount.text, _cur)];
    final subtotal = amounts.fold(0, (a, v) => a + (v ?? 0));
    final tax = _extra(_tax, subtotal), tip = _extra(_tip, subtotal), discount = _extra(_discount, subtotal);
    String? problem;
    if (_lines.isEmpty) {
      problem = 'Add an item';
    } else if (_lines.length > maxItemLines) {
      problem = 'At most $maxItemLines items';
    } else if (_lines.any((l) => l.name.text.trim().isEmpty)) {
      problem = 'Give every item a name';
    } else if (_lines.any((l) => l.name.text.trim().length > maxItemName)) {
      problem = 'An item name is too long';
    } else if (amounts.any((v) => v == null || v < 0) || tax == null || tip == null || discount == null) {
      problem = 'Check the amounts';
    }
    final unassigned = _lines.where((l) => l.people.isEmpty).length;
    final bill = ItemizedBill(
      lines: [
        for (final (i, l) in _lines.indexed)
          ItemLine(name: l.name.text.trim(), amount: amounts[i] ?? 0, memberIds: [...l.people]),
      ],
      tax: tax ?? 0,
      tip: tip ?? 0,
      discount: discount ?? 0,
    );
    Map<String, int>? shares;
    if (problem == null) {
      try {
        shares = computeItemizedSplit(bill);
      } on SplitException catch (e) {
        problem = itemizedErrorText(e.code);
      }
    }
    final total = itemizedTotal(bill);
    final printed = widget.printedTotal;
    final onReceipt = widget.printedTip ? total : total - bill.tip;

    Widget money(int v, {TextStyle? style, Key? key}) => Text(formatMoney(v, _cur), key: key, style: style);
    Widget row(String label, Widget value, {TextStyle? style}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [Expanded(child: Text(label, style: style)), value]),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Items'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              key: const Key('itemize-done'),
              onPressed: problem == null ? () => Navigator.pop(context, bill) : null,
              child: const Text('Done'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (widget.image case final img?)
            Card(
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                key: const Key('itemize-photo'),
                initiallyExpanded: true,
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Receipt'),
                shape: const Border(),
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: InteractiveViewer(maxScale: 5, child: Image.file(img, fit: BoxFit.contain)),
                  ),
                ],
              ),
            ),
          for (final l in _lines)
            _LineCard(
              key: l.key,
              line: l,
              currency: _cur,
              active: _active,
              names: names,
              onChanged: () => setState(() {}),
              onRemove: () => setState(() {
                _lines.remove(l);
                l.dispose();
              }),
            ),
          Wrap(spacing: 8, runSpacing: 4, children: [
            OutlinedButton.icon(
              key: const Key('itemize-add'),
              onPressed: _lines.length >= maxItemLines ? null : _addLine,
              icon: const Icon(Icons.add),
              label: const Text('Add item'),
            ),
            if (unassigned > 0 && _active.isNotEmpty)
              TextButton.icon(
                key: const Key('itemize-everyone'),
                onPressed: _everyone,
                icon: const Icon(Icons.groups_outlined),
                label: const Text('Give the rest to everyone'),
              ),
          ]),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          row('Subtotal', money(subtotal, key: const Key('itemize-subtotal'))),
          for (final (label, e, key) in [('Tax', _tax, 'tax'), ('Tip or service', _tip, 'tip'), ('Discount', _discount, 'discount')])
            _ExtraRow(
              key: Key('itemize-$key'),
              label: label,
              extra: e,
              currency: _cur,
              amount: _extra(e, subtotal),
              onToggle: (p) => _toggle(e, p, subtotal),
              onChanged: () => setState(() {}),
            ),
          const SizedBox(height: 4),
          row('Total', money(total, key: const Key('itemize-total'), style: text.titleMedium), style: text.titleMedium),
          if (printed != null && printed != onReceipt)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: cs.tertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Receipt says ${formatMoney(printed, _cur)} · items differ by ${formatMoney((printed - onReceipt).abs(), _cur)}',
                    key: const Key('itemize-mismatch'),
                    style: text.bodySmall?.copyWith(color: cs.tertiary),
                  ),
                ),
              ]),
            ),
          const SizedBox(height: 16),
          Text('Each person', style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          if (problem != null)
            Row(children: [
              Icon(Icons.error_outline, size: 16, color: cs.error),
              const SizedBox(width: 6),
              Expanded(
                child: Text(unassigned > 0 && problem == itemizedErrorText('UNASSIGNED_ITEM')
                    ? '$unassigned item${unassigned == 1 ? '' : 's'} without a person'
                    : problem,
                    key: const Key('itemize-problem'), style: text.bodySmall?.copyWith(color: cs.error)),
              ),
            ])
          else
            // Me first as "You", then the others in the group's order (a set: each once).
            for (final id in {?widget.me, for (final m in widget.members) m.id, ...shares!.keys})
              if (shares[id] case final v?)
                row(id == widget.me ? 'You' : names[id] ?? 'Someone', money(v, key: Key('itemize-person-$id'))),
        ],
      ),
    );
  }
}

/// One line: name, price, and its people (chips, "All"); swipe to remove. Highlighted while nobody is on it.
class _LineCard extends StatelessWidget {
  final _Line line;
  final String currency;
  final List<MemberRow> active;
  final Map<String, String> names;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  const _LineCard({
    super.key,
    required this.line,
    required this.currency,
    required this.active,
    required this.names,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final large = MediaQuery.textScalerOf(context).scale(1) > 2;
    final l = line;
    final empty = l.people.isEmpty;
    final all = active.isNotEmpty && active.every((m) => l.people.contains(m.id));
    // Removed members stay on lines they were on, by name.
    final gone = [for (final id in l.people) if (!active.any((m) => m.id == id)) id];
    final name = TextField(
      key: const Key('item-name'),
      controller: l.name,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(hintText: 'Item', isDense: true),
      onChanged: (_) => onChanged(),
    );
    final amount = TextField(
      key: const Key('item-amount'),
      controller: l.amount,
      textAlign: TextAlign.end,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(hintText: minorToText(0, currency), suffixText: currency, isDense: true),
      onChanged: (_) => onChanged(),
    );
    return Dismissible(
      key: l.key,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: cs.errorContainer,
        child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
      ),
      onDismissed: (_) => onRemove(),
      child: Card(
        key: const Key('item-line'),
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: empty ? cs.error : cs.outlineVariant),
        ),
        color: empty ? cs.errorContainer.withValues(alpha: 0.35) : null,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (large) ...[name, amount] else Row(children: [Expanded(child: name), const SizedBox(width: 12), SizedBox(width: 120, child: amount)]),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 4, children: [
              FilterChip(
                key: const Key('item-all'),
                label: const Text('All'),
                selected: all,
                onSelected: (on) {
                  on ? l.people.addAll(active.map((m) => m.id)) : l.people.removeAll(active.map((m) => m.id));
                  onChanged();
                },
              ),
              for (final m in active)
                FilterChip(
                  key: Key('item-person-${m.id}'),
                  label: Text(m.name),
                  selected: l.people.contains(m.id),
                  onSelected: (on) {
                    on ? l.people.add(m.id) : l.people.remove(m.id);
                    onChanged();
                  },
                ),
              for (final id in gone)
                FilterChip(
                  label: Text('${names[id] ?? 'Someone'} (left)'),
                  selected: true,
                  onSelected: (_) {
                    l.people.remove(id);
                    onChanged();
                  },
                ),
            ]),
            if (empty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Who had this?', style: text.bodySmall?.copyWith(color: cs.error)),
              ),
          ]),
        ),
      ),
    );
  }
}

/// "Tax  [€|%]  [2.84]", with the amount a percent comes to.
class _ExtraRow extends StatelessWidget {
  final String label;
  final _Extra extra;
  final String currency;
  final int? amount;
  final ValueChanged<bool> onToggle;
  final VoidCallback onChanged;
  const _ExtraRow({
    super.key,
    required this.label,
    required this.extra,
    required this.currency,
    required this.amount,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final symbol = formatMoney(0, currency).replaceAll(RegExp(r'[\d.,\s]'), '');
    final toggle = SegmentedButton<bool>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      segments: [
        ButtonSegment(value: false, label: Text(symbol.isEmpty ? currency : symbol)),
        const ButtonSegment(value: true, label: Text('%')),
      ],
      selected: {extra.percent},
      onSelectionChanged: (s) => onToggle(s.first),
    );
    final field = SizedBox(
      width: 100,
      child: TextField(
        key: const Key('extra-field'),
        controller: extra.text,
        textAlign: TextAlign.end,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          isDense: true,
          hintText: extra.percent ? '0' : minorToText(0, currency),
          suffixText: extra.percent ? '%' : null,
        ),
        onChanged: (_) => onChanged(),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Text(label),
          Row(mainAxisSize: MainAxisSize.min, children: [
            toggle,
            const SizedBox(width: 8),
            field,
            if (extra.percent && amount != null) ...[
              const SizedBox(width: 8),
              Text(formatMoney(amount!, currency),
                  key: const Key('extra-amount'), style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ]),
        ],
      ),
    );
  }
}
