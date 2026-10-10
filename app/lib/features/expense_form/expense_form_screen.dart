import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/confirm.dart';
import '../../core/ids.dart';
import '../../core/money.dart';
import '../../core/snack.dart';
import '../../data/db/database.dart';
import '../../domain/models.dart';
import '../../domain/split.dart';
import '../../providers.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String? expenseId;
  const ExpenseFormScreen({super.key, required this.groupId, this.expenseId});
  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _fx = TextEditingController();
  final _category = TextEditingController();
  final _perMember = <String, TextEditingController>{};
  String? _currency;
  String? _paidBy;
  SplitMode _mode = SplitMode.equal;
  String _date = todayIso();
  Expense? _editing;
  bool _loaded = false;
  bool _busy = false;

  TextEditingController _ctl(String memberId) => _perMember.putIfAbsent(memberId, TextEditingController.new);

  Future<void> _loadExisting() async {
    _loaded = true;
    final id = widget.expenseId;
    if (id == null) return;
    final db = ref.read(dbProvider);
    final row = await db.getExpense(id);
    if (row == null) return;
    final shares = await db.getShares(id);
    final e = Expense(
      id: row.id,
      description: row.description,
      amount: row.amount,
      currency: row.currency,
      fxRateToDefault: row.fxRateToDefault,
      paidBy: row.paidBy,
      date: row.date,
      category: row.category,
      deleted: row.deleted,
      shares: [for (final s in shares) Share(memberId: s.memberId, amount: s.amount)],
    );
    setState(() {
      _editing = e;
      _amount.text = _minorToText(e.amount, e.currency);
      _description.text = e.description;
      _fx.text = e.fxRateToDefault?.toString() ?? '';
      _category.text = e.category ?? '';
      _currency = e.currency;
      _paidBy = e.paidBy;
      _date = e.date;
      _mode = SplitMode.exact;
      for (final s in e.shares) {
        _ctl(s.memberId).text = _minorToText(s.amount, e.currency);
      }
    });
  }

  String _minorToText(int minor, String currency) {
    final d = Money.digits(currency);
    final s = minor.abs().toString().padLeft(d + 1, '0');
    final r = d == 0 ? s : '${s.substring(0, s.length - d)}.${s.substring(s.length - d)}';
    return minor < 0 ? '-$r' : r;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) _loadExisting();
  }

  /// Exact: minor units still unassigned. Percent: percent still unassigned. Null when a field is unparsable.
  num? _remaining(int amount, List<MemberRow> members, String currency) {
    num sum = 0;
    for (final m in members) {
      final t = _ctl(m.id).text.trim();
      if (t.isEmpty) continue;
      final v = _mode == SplitMode.exact ? parseMoney(t, currency) : double.tryParse(t);
      if (v == null) return null;
      sum += v;
    }
    return _mode == SplitMode.exact ? amount - sum : 100 - sum;
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d.toIso8601String().substring(0, 10));
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupProvider(widget.groupId)).value;
    final members = (ref.watch(membersProvider(widget.groupId)).value ?? const <MemberRow>[])
        .where((m) => !m.removed || m.id == _editing?.paidBy || (_editing?.shares.any((s) => s.memberId == m.id) ?? false))
        .toList();
    if (group == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final currency = _currency ?? group.defaultCurrency;
    final paidBy = _paidBy ?? group.myMemberId ?? members.firstOrNull?.id;
    final amount = parseMoney(_amount.text, currency);
    final canSave = !_busy && amount != null && amount > 0 && _description.text.trim().isNotEmpty && paidBy != null && members.isNotEmpty;
    final dateLabel = DateFormat('EEE, d MMM yyyy').format(DateTime.tryParse(_date) ?? DateTime.now());

    Widget sectionLabel(String s) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(s, style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        );

    Widget? remainingLine;
    if (_mode != SplitMode.equal && amount != null) {
      final rem = _remaining(amount, members, currency);
      final String label;
      final Color color;
      if (rem == null) {
        label = 'Check the amounts';
        color = cs.error;
      } else if (rem == 0) {
        label = 'Adds up';
        color = cs.primary;
      } else {
        final r = _mode == SplitMode.exact ? formatMoney(rem.toInt(), currency) : '${_trimNum(rem)}%';
        label = rem > 0 ? 'remaining: $r' : 'over by: ${r.replaceFirst('-', '')}';
        color = cs.error;
      }
      remainingLine = Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(children: [
          Icon(rem == 0 ? Icons.check_circle_outline : Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: text.bodySmall?.copyWith(color: color)),
        ]),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing == null ? 'New expense' : 'Edit expense'),
        actions: [
          if (_editing != null)
            IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline), onPressed: () => _delete()),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
              child: TextField(
                key: const Key('amount'),
                controller: _amount,
                autofocus: widget.expenseId == null,
                style: text.displaySmall?.copyWith(fontWeight: FontWeight.w600),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: '0.00', border: InputBorder.none, isDense: true),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: currency,
                style: text.titleMedium?.copyWith(color: cs.onSurface),
                items: [for (final c in Money.currencies) DropdownMenuItem(value: c, child: Text(c))],
                onChanged: (v) => setState(() => _currency = v),
              ),
            ),
          ]),
          const Divider(height: 1),
          if (currency != group.defaultCurrency)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextField(
                controller: _fx,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Rate: 1 $currency in ${group.defaultCurrency}',
                  helperText: 'Needed to count this expense in balances',
                  prefixIcon: const Icon(Icons.currency_exchange),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('description'),
            controller: _description,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.notes)),
            onChanged: (_) => setState(() {}),
          ),
          sectionLabel('Paid by'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final m in members)
                ChoiceChip(
                  label: Text(m.name),
                  selected: m.id == paidBy,
                  onSelected: (_) => setState(() => _paidBy = m.id),
                ),
            ],
          ),
          sectionLabel('When'),
          Row(children: [
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: Text(dateLabel),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Category', isDense: true),
              ),
            ),
          ]),
          sectionLabel('Split'),
          SegmentedButton<SplitMode>(
            segments: const [
              ButtonSegment(value: SplitMode.equal, label: Text('Equal')),
              ButtonSegment(value: SplitMode.exact, label: Text('Exact')),
              ButtonSegment(value: SplitMode.percent, label: Text('Percent')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          if (_mode == SplitMode.equal)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                members.isEmpty
                    ? 'No members'
                    : 'Split equally between ${members.length} member${members.length == 1 ? '' : 's'}'
                        '${amount == null || amount <= 0 ? '' : ' · ${formatMoney(amount ~/ members.length, currency)} each'}',
                style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            )
          else ...[
            for (final m in members)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  key: Key('share-${m.id}'),
                  controller: _ctl(m.id),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: m.name,
                    isDense: true,
                    suffixText: _mode == SplitMode.percent ? '%' : currency,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ?remainingLine,
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: canSave ? () => _save(group, members, currency, amount, paidBy) : null,
            child: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    );
  }

  static String _trimNum(num v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('.00') ? s.substring(0, s.length - 3) : s;
  }

  Map<String, int>? _split(int amount, List<String> memberIds, String currency) {
    Map<String, double>? input;
    if (_mode != SplitMode.equal) {
      input = {};
      for (final id in memberIds) {
        final t = _ctl(id).text.trim();
        if (t.isEmpty) {
          input[id] = 0;
        } else if (_mode == SplitMode.exact) {
          final v = parseMoney(t, currency);
          if (v == null) return null;
          input[id] = v.toDouble();
        } else {
          final v = double.tryParse(t);
          if (v == null) return null;
          input[id] = v;
        }
      }
    }
    try {
      return computeSplit(amount: amount, mode: _mode, members: memberIds, input: input);
    } on SplitException catch (e) {
      showInfo(context, e.code == 'SUM_MISMATCH' ? 'Shares must add up to the total' : 'Split error: ${e.code}');
      return null;
    }
  }

  Future<void> _save(GroupRow group, List<MemberRow> members, String currency, int amount, String paidBy) async {
    final memberIds = members.map((m) => m.id).toList();
    final shares = _split(amount, memberIds, currency);
    if (shares == null) return;
    final fx = currency == group.defaultCurrency ? null : double.tryParse(_fx.text.trim());
    final cat = _category.text.trim().isEmpty ? null : _category.text.trim();
    final e = Expense(
      id: _editing?.id ?? newId(),
      description: _description.text.trim(),
      amount: amount,
      currency: currency,
      fxRateToDefault: fx,
      paidBy: paidBy,
      date: _date,
      category: cat,
      shares: [for (final id in memberIds) Share(memberId: id, amount: shares[id] ?? 0)],
    );
    setState(() => _busy = true);
    try {
      final w = ref.read(localWritesProvider);
      final old = _editing;
      if (old == null) {
        await w.createExpense(group.id, e);
      } else {
        await w.updateExpense(group.id, e, {
          if (e.description != old.description) 'description': e.description,
          if (e.amount != old.amount) 'amount': e.amount,
          if (e.currency != old.currency) 'currency': e.currency,
          if (e.fxRateToDefault != old.fxRateToDefault) 'fxRateToDefault': e.fxRateToDefault,
          if (e.paidBy != old.paidBy) 'paidBy': e.paidBy,
          if (e.date != old.date) 'date': e.date,
          if (e.category != old.category) 'category': e.category,
          if (!_sameShares(e.shares, old.shares)) 'shares': e.shares,
        });
      }
      if (mounted) context.pop();
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _sameShares(List<Share> a, List<Share> b) {
    final ma = {for (final s in a) s.memberId: s.amount};
    final mb = {for (final s in b) s.memberId: s.amount};
    return ma.length == mb.length && ma.entries.every((e) => mb[e.key] == e.value);
  }

  Future<void> _delete() async {
    final ok = await confirm(context, title: 'Delete expense?', message: 'This removes it for everyone in the group.');
    if (!ok || !mounted) return;
    await ref.read(localWritesProvider).deleteExpense(widget.groupId, _editing!.id);
    if (mounted) context.pop();
  }
}
