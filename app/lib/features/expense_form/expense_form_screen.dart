import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupProvider(widget.groupId)).value;
    final members = (ref.watch(membersProvider(widget.groupId)).value ?? const <MemberRow>[])
        .where((m) => !m.removed || m.id == _editing?.paidBy || (_editing?.shares.any((s) => s.memberId == m.id) ?? false))
        .toList();
    if (group == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final currency = _currency ?? group.defaultCurrency;
    final paidBy = _paidBy ?? group.myMemberId ?? members.firstOrNull?.id;
    final amount = parseMoney(_amount.text, currency);
    final canSave = !_busy && amount != null && amount >= 0 && _description.text.trim().isNotEmpty && paidBy != null && members.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing == null ? 'New expense' : 'Edit expense'),
        actions: [
          if (_editing != null)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete()),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(
              child: TextField(
                key: const Key('amount'),
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: currency,
              items: [for (final c in Money.currencies) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (v) => setState(() => _currency = v),
            ),
          ]),
          if (currency != group.defaultCurrency)
            TextField(
              controller: _fx,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: '1 $currency = ? ${group.defaultCurrency} (fx rate)'),
            ),
          TextField(
            key: const Key('description'),
            controller: _description,
            decoration: const InputDecoration(labelText: 'Description'),
            onChanged: (_) => setState(() {}),
          ),
          DropdownButtonFormField<String>(
            initialValue: members.any((m) => m.id == paidBy) ? paidBy : null,
            decoration: const InputDecoration(labelText: 'Paid by'),
            items: [for (final m in members) DropdownMenuItem(value: m.id, child: Text(m.name))],
            onChanged: (v) => setState(() => _paidBy = v),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            trailing: Text(_date),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(_date) ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (d != null) setState(() => _date = d.toIso8601String().substring(0, 10));
            },
          ),
          TextField(controller: _category, decoration: const InputDecoration(labelText: 'Category (optional)')),
          const SizedBox(height: 16),
          SegmentedButton<SplitMode>(
            segments: const [
              ButtonSegment(value: SplitMode.equal, label: Text('Equal')),
              ButtonSegment(value: SplitMode.exact, label: Text('Exact')),
              ButtonSegment(value: SplitMode.percent, label: Text('Percent')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          if (_mode != SplitMode.equal)
            for (final m in members)
              TextField(
                key: Key('share-${m.id}'),
                controller: _ctl(m.id),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: m.name, suffixText: _mode == SplitMode.percent ? '%' : currency),
              ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: canSave ? () => _save(group, members, currency, amount, paidBy) : null,
            child: const Text('Save'),
          ),
        ],
      ),
    );
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
      showInfo(context, 'Split error: ${e.code}');
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete expense?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(localWritesProvider).deleteExpense(widget.groupId, _editing!.id);
    if (mounted) context.pop();
  }
}
