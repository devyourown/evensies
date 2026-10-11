import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/confirm.dart';
import '../../core/core_guard.dart';
import '../../core/ids.dart';
import '../../core/money.dart';
import '../../core/snack.dart';
import '../../data/db/database.dart';
import '../../data/sync/group_state_store.dart';
import '../../domain/models.dart';
import '../../domain/split.dart';
import '../../providers.dart';
import 'comment_thread.dart';
import 'split_editor.dart';

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
  final _notes = TextEditingController();
  static const _maxNotes = 500; // UTF-16 units, like the server
  static const _maxDescription = 200; // the server checks it only when sent, so an unchanged long one may stay
  final _split = SplitEditorController();
  final _payerFields = <String, TextEditingController>{};
  bool _several = false; // "Several people" paid
  String? _currency;
  String? _paidBy;
  bool _refund = false;
  String _date = todayIso();
  Expense? _editing;
  /// The stored split when the editor couldn't rebuild it and opened as exact: kept if the shares stay the same.
  SplitSpec? _keptSplit;
  /// Set when the group's default split no longer computes for today's members and the form starts as equal.
  String? _defaultNote;
  bool _loaded = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _split.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _split.dispose();
    for (final c in [_amount, _description, _fx, _category, _notes, ..._payerFields.values]) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _payer(String memberId) => _payerFields.putIfAbsent(memberId, TextEditingController.new);

  Future<void> _loadExisting() async {
    _loaded = true;
    final db = ref.read(dbProvider);
    final id = widget.expenseId;
    if (id == null) return _startFromDefault(db);
    final state = await GroupStateStore(db).load(widget.groupId);
    final e = state.expense(id);
    if (e == null || !mounted) return;
    setState(() {
      _editing = e;
      _amount.text = minorToText(e.amount, e.currency);
      _description.text = e.description;
      _fx.text = e.fxRateToDefault?.toString() ?? '';
      _category.text = e.category ?? '';
      _notes.text = e.notes ?? '';
      _currency = e.currency;
      _date = e.date;
      _refund = e.refund;
      _several = e.payers.length > 1;
      _paidBy = e.paidBy;
      for (final p in e.payers) {
        _payer(p.memberId).text = minorToText(p.amount, e.currency);
      }
      _openSplit(e, [for (final m in state.members) m.id]);
    });
  }

  /// The stored mode with the typed numbers when they still give the stored shares (zeros aside); otherwise, or
  /// while that mode is a TODO(효준) stub, the amounts as exact (docs/API.md SplitSpec). No split (exact, or saved
  /// before Phase 3) whose shares are an equal split of the people in it opens as equal.
  void _openSplit(Expense e, List<String> shown) {
    final ids = [for (final s in e.shares) s.memberId];
    Map<String, int> nonZero(Map<String, int> m) => {
          for (final x in m.entries)
            if (x.value != 0) x.key: x.value
        };
    final stored = nonZero({for (final s in e.shares) s.memberId: s.amount});
    final spec = e.split;
    Map<String, int>? again;
    _keptSplit = null;
    if (spec != null && ids.isNotEmpty) {
      try {
        again = tryCore(() => computeSplit(amount: e.amount, mode: spec.mode, members: ids, input: spec.input));
      } on SplitException {
        again = null;
      }
    }
    if (ids.isEmpty) {
      _split.loadEqual(shown, shown); // no shares stored (not written by this app): start like a new expense
    } else if (spec == null &&
        stored.isNotEmpty &&
        mapEquals(computeSplit(amount: e.amount, mode: SplitMode.equal, members: stored.keys.toList()), stored)) {
      _split.loadEqual(stored.keys, {...shown, ...ids});
    } else if (spec == null || again == null || !mapEquals(nonZero(again), stored)) {
      _split.loadExact(e.shares, e.currency);
      _keptSplit = spec;
    } else if (spec.mode == SplitMode.equal) {
      _split.loadEqual(ids, {...shown, ...ids});
    } else {
      _split.load(spec, e.currency);
    }
  }

  /// New expense: the group's default split (percent or shares) if it can be computed for today's members,
  /// otherwise equal with everyone ticked.
  Future<void> _startFromDefault(AppDatabase db) async {
    final spec = splitFromJson((await db.getGroup(widget.groupId))?.defaultSplitJson);
    if (spec == null || spec.mode == SplitMode.equal) return;
    final ids = [
      for (final m in await (db.select(db.members)..where((m) => m.groupId.equals(widget.groupId))).get())
        if (!m.removed) m.id
    ];
    final fits = splitFits(spec, ids); // null: a TODO(효준) stub mode, quietly equal
    if (!mounted || fits == null) return;
    if (!fits) return setState(() => _defaultNote = "The group's default split no longer adds up, so this starts equal");
    _split.load(SplitSpec(spec.mode, {for (final id in ids) id: spec.input?[id] ?? 0.0}), ''); // joined later: 0
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) _loadExisting();
  }

  /// Several payers: per person amounts (empty or zero dropped) that must add up to [amount].
  ({List<Share>? payers, String status, bool ok}) _payers(
      int? amount, List<MemberRow> members, String currency, String? single) {
    if (!_several) {
      return single == null || amount == null
          ? (payers: null, status: '', ok: false)
          : (payers: [Share(memberId: single, amount: amount)], status: '', ok: true);
    }
    final list = <Share>[];
    for (final m in members) {
      final t = _payer(m.id).text.trim();
      if (t.isEmpty) continue;
      final v = parseMoney(t, currency);
      if (v == null || v < 0) return (payers: null, status: 'Check the amounts', ok: false);
      if (v > 0) list.add(Share(memberId: m.id, amount: v));
    }
    if (amount == null) return (payers: null, status: 'Enter the total first', ok: false);
    final left = amount - list.fold<int>(0, (a, p) => a + p.amount);
    if (left > 0) return (payers: null, status: '${formatMoney(left, currency)} left to assign', ok: false);
    if (left < 0) return (payers: null, status: 'over by: ${formatMoney(-left, currency)}', ok: false);
    // A zero total still needs a payer.
    if (list.isEmpty && single != null) list.add(Share(memberId: single, amount: 0));
    return (payers: list, status: 'Adds up', ok: list.isNotEmpty);
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

  /// "Ben owes the full amount" / "I owe Ben the full amount": one payer, equal with only [owes] ticked.
  void _setFull(String payer, String owes, List<String> shown) => setState(() {
        _several = false;
        _paidBy = payer;
        _split.loadEqual([owes], shown);
      });

  bool _isFull(String? paidBy, String payer, String owes, List<String> shown) =>
      !_several &&
      paidBy == payer &&
      _split.mode == SplitMode.equal &&
      shown.where((id) => !_split.unticked.contains(id)).toList().join() == owes;

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupProvider(widget.groupId)).value;
    final all = ref.watch(membersProvider(widget.groupId)).value ?? const <MemberRow>[];
    final e0 = _editing;
    bool involved(String id) =>
        e0 != null && (e0.payers.any((p) => p.memberId == id) || e0.shares.any((s) => s.memberId == id));
    final members = all.where((m) => !m.removed || involved(m.id)).toList();
    if (group == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final ids = [for (final m in members) m.id];
    final currency = _currency ?? group.defaultCurrency;
    final paidBy = _paidBy ?? group.myMemberId ?? members.firstOrNull?.id;
    final amount = parseMoney(_amount.text, currency);
    final deleted = _editing?.deleted ?? false;
    final notesLength = _notes.text.trim().length;
    final descriptionLength = _description.text.trim().length;
    final descriptionTooLong = descriptionLength > _maxDescription && _description.text.trim() != _editing?.description;
    final split = _split.evaluate(amount: amount, ids: ids, currency: currency);
    final payers = _payers(amount, members, currency, paidBy);
    final canSave = !_busy &&
        !deleted &&
        notesLength <= _maxNotes &&
        !descriptionTooLong &&
        amount != null &&
        amount > 0 &&
        _description.text.trim().isNotEmpty &&
        members.isNotEmpty &&
        payers.ok &&
        split.ok &&
        split.shares != null;
    final dateLabel = DateFormat('EEE, d MMM yyyy').format(DateTime.tryParse(_date) ?? DateTime.now());
    final active = all.where((m) => !m.removed).toList();
    final me = group.myMemberId;
    final other = active.length == 2 && active.any((m) => m.id == me) ? active.firstWhere((m) => m.id != me) : null;

    Widget sectionLabel(String s) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(s, style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        );

    Widget statusLine(String s, bool ok, {Key? key}) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            Icon(ok ? Icons.check_circle_outline : Icons.info_outline, size: 16, color: ok ? cs.primary : cs.error),
            const SizedBox(width: 6),
            Expanded(child: Text(s, key: key, style: text.bodySmall?.copyWith(color: ok ? cs.primary : cs.error))),
          ]),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing == null ? 'New expense' : (deleted ? 'Deleted expense' : 'Edit expense')),
        actions: [
          if (_editing != null && !deleted)
            IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline), onPressed: () => _delete()),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (deleted)
            Card(
              color: cs.errorContainer,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: cs.onErrorContainer),
                title: Text('This expense was deleted', style: TextStyle(color: cs.onErrorContainer)),
                subtitle: Text('Restore it to count it in balances again.', style: TextStyle(color: cs.onErrorContainer)),
                trailing: FilledButton(onPressed: _busy ? null : _restore, child: const Text('Restore')),
              ),
            ),
          // A deleted expense is read-only until restored, so no stale edit survives the restore.
          IgnorePointer(
            ignoring: deleted,
            child: Opacity(
              opacity: deleted ? 0.6 : 1,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: const Icon(Icons.notes),
                    counterText: descriptionLength > _maxDescription - 20 ? '$descriptionLength/$_maxDescription' : null,
                    errorText: descriptionTooLong ? 'Too long' : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                sectionLabel(_refund ? 'Received by' : 'Paid by'),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final m in members)
                      ChoiceChip(
                        label: Text(m.name),
                        selected: !_several && m.id == paidBy,
                        onSelected: (_) => setState(() {
                          _several = false;
                          _paidBy = m.id;
                        }),
                      ),
                    ChoiceChip(
                      key: const Key('several-payers'),
                      avatar: const Icon(Icons.group_outlined, size: 18),
                      label: const Text('Several people'),
                      selected: _several,
                      onSelected: (_) => setState(() {
                        // Start from what the single payer paid.
                        if (!_several && paidBy != null && _payerFields.values.every((c) => c.text.trim().isEmpty)) {
                          _payer(paidBy).text = _amount.text.trim();
                        }
                        _several = true;
                      }),
                    ),
                  ],
                ),
                if (_several) ...[
                  for (final m in members)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        key: Key('payer-${m.id}'),
                        controller: _payer(m.id),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration:
                            InputDecoration(labelText: m.name, isDense: true, suffixText: currency, hintText: '0.00'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  statusLine(payers.status, payers.ok, key: const Key('payers-status')),
                ],
                sectionLabel('When'),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(dateLabel),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _category,
                      decoration: const InputDecoration(labelText: 'Category', isDense: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilterChip(
                    key: const Key('refund'),
                    avatar: Icon(Icons.undo, size: 18, color: _refund ? cs.onSecondaryContainer : cs.onSurfaceVariant),
                    showCheckmark: false,
                    label: const Text('Refund'),
                    tooltip: 'Money that came back, e.g. the hotel returned a deposit',
                    selected: _refund,
                    onSelected: (v) => setState(() => _refund = v),
                  ),
                ]),
                sectionLabel(_refund ? 'Split back to' : 'Split'),
                // A refund reverses who owes whom, so the labels would be backwards (Splitwise hides them too).
                if (other != null && me != null && !_refund) ...[
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    ChoiceChip(
                      key: const Key('full-they-owe'),
                      label: Text('${other.name} owes the full amount'),
                      selected: _isFull(paidBy, me, other.id, ids),
                      onSelected: (_) => _setFull(me, other.id, ids),
                    ),
                    ChoiceChip(
                      key: const Key('full-i-owe'),
                      label: Text('I owe ${other.name} the full amount'),
                      selected: _isFull(paidBy, other.id, me, ids),
                      onSelected: (_) => _setFull(other.id, me, ids),
                    ),
                  ]),
                  const SizedBox(height: 12),
                ],
                if (_defaultNote != null && _split.mode == SplitMode.equal)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_defaultNote!, key: const Key('default-note'), style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                SplitEditor(controller: _split, members: members, amount: amount, currency: currency),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('notes'),
                  controller: _notes,
                  minLines: 1,
                  maxLines: 5,
                  // No maxLength: Flutter counts characters as seen (an emoji is 1), the limit counts UTF-16 units.
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    prefixIcon: const Icon(Icons.sticky_note_2_outlined),
                    counterText: notesLength > _maxNotes - 50 ? '$notesLength/$_maxNotes' : null,
                    errorText: notesLength > _maxNotes ? 'Too long' : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: canSave ? () => _save(group, ids, currency, amount, payers.payers!, split.shares!) : null,
            child: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
          if (_editing != null) ...[
            const SizedBox(height: 32),
            const Divider(height: 1),
            const SizedBox(height: 16),
            CommentThread(groupId: widget.groupId, expenseId: _editing!.id),
          ],
        ],
      ),
    );
  }

  Future<void> _save(
      GroupRow group, List<String> ids, String currency, int amount, List<Share> payers, Map<String, int> split) async {
    final fx = currency == group.defaultCurrency ? null : double.tryParse(_fx.text.trim());
    final cat = _category.text.trim().isEmpty ? null : _category.text.trim();
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    final old = _editing;
    var e = Expense(
      id: old?.id ?? newId(),
      description: _description.text.trim(),
      amount: amount,
      currency: currency,
      fxRateToDefault: fx,
      payers: payers,
      date: _date,
      category: cat,
      notes: notes,
      refund: _refund,
      split: _split.spec(ids, currency),
      // Equal: only the ticked people; the other modes: everyone shown, zeros included (docs/API.md SplitSpec).
      shares: [
        for (final id in ids)
          if (_split.mode != SplitMode.equal || split.containsKey(id)) Share(memberId: id, amount: split[id] ?? 0)
      ],
    );
    // Opened as exact only because the stored split couldn't be rebuilt, and the shares are what they were: the
    // split didn't change, so keep it (no `split: null`, no money fields for a description edit).
    if (old != null && _keptSplit != null && _split.mode == SplitMode.exact && _same(e.shares, old.shares)) {
      e = e.copyWith(split: _keptSplit, shares: old.shares);
    }
    // No stored split that opened as equal (see _openSplit), same shares: still no split, so no money fields.
    if (old != null && old.split == null && _split.mode == SplitMode.equal && _same(e.shares, old.shares)) {
      e = e.copyWith(clearSplit: true, shares: old.shares);
    }
    setState(() => _busy = true);
    try {
      final w = ref.read(localWritesProvider);
      if (old == null) {
        await w.createExpense(group.id, e);
      } else {
        final money = e.amount != old.amount ||
            e.paidBy != old.paidBy ||
            !_same(e.payers, old.payers) ||
            !_same(e.shares, old.shares) ||
            e.split != old.split ||
            e.refund != old.refund;
        await w.updateExpense(group.id, e, {
          if (e.description != old.description) 'description': e.description,
          if (e.currency != old.currency) 'currency': e.currency,
          if (e.fxRateToDefault != old.fxRateToDefault) 'fxRateToDefault': e.fxRateToDefault,
          if (e.date != old.date) 'date': e.date,
          if (e.category != old.category) 'category': e.category,
          if (e.notes != old.notes) 'notes': e.notes,
          // Any money field changed: all six together, so the server can check them as one (docs/API.md).
          if (money) ...{
            'amount': e.amount,
            'paidBy': e.paidBy,
            'payers': e.payers,
            'shares': e.shares,
            'split': e.split,
            'refund': e.refund,
          },
        });
      }
      if (mounted) context.pop();
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Zero entries aside: they don't change any balance.
  bool _same(List<Share> a, List<Share> b) => mapEquals(
        {for (final s in a) if (s.amount != 0) s.memberId: s.amount},
        {for (final s in b) if (s.amount != 0) s.memberId: s.amount},
      );

  Future<void> _delete() async {
    final ok = await confirm(context,
        title: 'Delete expense?', message: 'This removes it for everyone in the group. You can restore it from Activity.');
    if (!ok || !mounted) return;
    final e = _editing!;
    final writes = ref.read(localWritesProvider);
    final messenger = ScaffoldMessenger.of(context); // the app-wide one, so the SnackBar outlives this screen
    await writes.deleteExpense(widget.groupId, e.id);
    if (!mounted) return;
    context.pop();
    messenger.showSnackBar(SnackBar(
      content: Text('Deleted “${e.description}”'),
      duration: const Duration(seconds: 10),
      persist: false, // actions persist by default; Undo is only offered for 10 s
      action: SnackBarAction(label: 'Undo', onPressed: () => writes.restoreExpense(widget.groupId, e.id)),
    ));
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      await ref.read(localWritesProvider).restoreExpense(widget.groupId, _editing!.id);
      if (mounted) await _loadExisting(); // the restored values, not what the fields showed
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
