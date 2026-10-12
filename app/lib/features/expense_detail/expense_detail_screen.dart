import 'dart:convert';

import 'package:drift/drift.dart' show BooleanExpressionOperators, CustomExpression, OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/confirm.dart';
import '../../core/money.dart';
import '../../core/offline_banner.dart';
import '../../core/snack.dart';
import '../../domain/activity.dart';
import '../../domain/categories.dart';
import '../../domain/insights.dart' show paidAmounts;
import '../../domain/itemized.dart';
import '../../domain/models.dart';
import '../../providers.dart';
import '../activity/activity_screen.dart';
import '../categories/category_ui.dart';
import '../expense_form/comment_thread.dart';
import '../group_detail/balances.dart';
import '../receipts/receipt_widgets.dart';

/// One expense, read-only (route `/groups/{id}/expenses/{eid}`): who paid, each person's share, notes, History and
/// comments. Edit opens the form; a deleted expense offers Restore instead.
class ExpenseDetailScreen extends ConsumerWidget {
  final String groupId;
  final String expenseId;
  const ExpenseDetailScreen({super.key, required this.groupId, required this.expenseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider(groupId)).valueOrNull;
    final state = ref.watch(groupStateProvider(groupId)).valueOrNull;
    if (group == null || state == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final e = state.expense(expenseId);
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (e == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.receipt_long_outlined, size: 64, color: cs.primary),
              const SizedBox(height: 16),
              Text("This expense isn't on this device", style: text.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text("It hasn't synced yet, or its group was left.",
                  style: TextStyle(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
    }
    final me = group.myMemberId;
    final names = {for (final m in state.members) m.id: m.name};
    final d = group.defaultCurrency;
    final rate = e.fxRateToDefault ?? 0;
    final date = DateTime.tryParse(e.date);

    Widget section(String s) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(s, style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(e.deleted ? 'Deleted expense' : 'Expense'),
        actions: [
          if (!e.deleted) ...[
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/groups/$groupId/expenses/${e.id}/edit'),
            ),
            IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(context, ref, e)),
          ],
        ],
      ),
      body: Column(children: [
        const OfflineBanner(),
        Expanded(
          // Pull to sync: a change made on another phone shows here (History reloads on the new latestSeq).
          child: RefreshIndicator(
            onRefresh: () => ref.read(syncProvider).sync(groupId).catchError((_) {}),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (e.deleted)
                  DeletedExpenseCard(
                    groupId: groupId,
                    expenseId: e.id,
                    onRestore: () => ref.read(localWritesProvider).restoreExpense(groupId, e.id),
                  ),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CategoryAvatar(e.category, size: 56),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.description, style: text.titleLarge),
                      const SizedBox(height: 2),
                      Row(children: [
                        if (e.refund) ...[
                          Icon(Icons.undo, size: 20, color: cs.onSurfaceVariant, semanticLabel: 'Refund'),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(formatMoney(e.amount, e.currency),
                              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(
                        [
                          Categories.labelOf(e.category),
                          date == null ? e.date : DateFormat('EEE, d MMM yyyy').format(date),
                          if (e.refund) 'Refund',
                        ].join(' · '),
                        style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      if (e.currency != d)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            rate > 0 ? 'Rate: 1 ${e.currency} = ${e.fxRateToDefault} $d' : 'Not converted to $d',
                            style: text.bodySmall?.copyWith(color: rate > 0 ? cs.onSurfaceVariant : cs.error),
                          ),
                        ),
                    ]),
                  ),
                ]),
                section(e.refund ? 'Received and split back' : 'Who paid and who owes'),
                for (final row in _people(e, names, me))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: row.isMe ? cs.primaryContainer : cs.secondaryContainer,
                        foregroundColor: row.isMe ? cs.onPrimaryContainer : cs.onSecondaryContainer,
                        child: Text(row.name.isEmpty ? '?' : row.name.characters.first.toUpperCase(),
                            style: text.labelLarge),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(row.text)),
                    ]),
                  ),
                if (e.split?.bill case final bill?) ...[
                  section('Items'),
                  _ItemsList(bill: bill, names: names, me: me, currency: e.currency),
                ],
                if (e.notes != null) ...[
                  section('Notes'),
                  Text(e.notes!, key: const Key('detail-notes')),
                ],
                if (!e.deleted || state.receiptsOf(e.id).isNotEmpty) ...[
                  section('Receipts'),
                  ReceiptStrip(
                    groupId: groupId,
                    expenseId: e.id,
                    ids: [for (final a in state.receiptsOf(e.id)) a.id],
                    editable: !e.deleted,
                  ),
                ],
                section('History'),
                ExpenseHistory(groupId: groupId, expenseId: e.id),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 16),
                CommentThread(groupId: groupId, expenseId: e.id),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Expense e) async {
    final ok = await confirm(context,
        title: 'Delete expense?', message: 'This removes it for everyone in the group. You can restore it from Activity.');
    if (!ok || !context.mounted) return;
    final writes = ref.read(localWritesProvider);
    final messenger = ScaffoldMessenger.of(context); // the app-wide one, so the SnackBar outlives this screen
    await writes.deleteExpense(groupId, e.id);
    if (!context.mounted) return;
    context.pop();
    showUndo(messenger, 'Deleted “${e.description}”', () => writes.restoreExpense(groupId, e.id));
  }
}

/// The banner on a deleted expense (detail and form): Restore, or for a moved one only where it went. Restoring a moved
/// expense would count it here and in its new group (docs/API.md 적용 규칙 13).
class DeletedExpenseCard extends ConsumerWidget {
  final String groupId;
  final String expenseId;

  /// Null disables Restore (busy).
  final VoidCallback? onRestore;
  const DeletedExpenseCard({super.key, required this.groupId, required this.expenseId, required this.onRestore});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final moved = ref.watch(movedAwayProvider((groupId: groupId, expenseId: expenseId))).value;
    if (moved == true) {
      return Card(
        key: const Key('moved-card'),
        color: cs.secondaryContainer,
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Icon(Icons.drive_file_move_outline, color: cs.onSecondaryContainer),
          title: Text('Moved to another group', style: TextStyle(color: cs.onSecondaryContainer)),
          subtitle: Text('It counts there now. Its comments and history stay here.',
              style: TextStyle(color: cs.onSecondaryContainer)),
        ),
      );
    }
    return Card(
      color: cs.errorContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.delete_outline, color: cs.onErrorContainer),
        title: Text('This expense was deleted', style: TextStyle(color: cs.onErrorContainer)),
        subtitle: Text('Restore it to count it in balances again.', style: TextStyle(color: cs.onErrorContainer)),
        // Not offered until it is known not to be a move.
        trailing: moved == null ? null : FilledButton(onPressed: onRestore, child: const Text('Restore')),
      ),
    );
  }
}

/// The bill of an itemized expense: each line with its price and people, then tax, tip and discount.
class _ItemsList extends StatelessWidget {
  final ItemizedBill bill;
  final Map<String, String> names;
  final String? me;
  final String currency;
  const _ItemsList({required this.bill, required this.names, required this.me, required this.currency});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    String who(String id) => id == me ? 'You' : names[id] ?? 'Someone';
    Widget row(String label, int amount, {String? sub, bool minus = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label),
                if (sub != null) Text(sub, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ]),
            ),
            const SizedBox(width: 12),
            Text('${minus ? '−' : ''}${formatMoney(amount, currency)}'),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final l in bill.lines) row(l.name, l.amount, sub: l.memberIds.map(who).join(', ')),
      if (bill.tax != 0) row('Tax', bill.tax),
      if (bill.tip != 0) row('Tip or service', bill.tip),
      if (bill.discount != 0) row('Discount', bill.discount, minus: true),
    ]);
  }
}

/// "Anna paid €30.00 and owes €10.00", one line per person in the expense: payers first, in the order sent.
/// For a refund: who received it and who gets a part back.
List<({String name, bool isMe, String text})> _people(Expense e, Map<String, String> names, String? me) {
  final paid = paidAmounts(e);
  final owes = <String, int>{};
  for (final s in e.shares) {
    owes[s.memberId] = (owes[s.memberId] ?? 0) + s.amount;
  }
  String m(int v) => formatMoney(v, e.currency);
  return [
    for (final id in {...paid.keys, ...owes.keys})
      if ((paid[id] ?? 0) != 0 || (owes[id] ?? 0) != 0)
        () {
          final isMe = id == me;
          final name = isMe ? 'You' : names[id] ?? 'Someone';
          final p = paid[id] ?? 0, o = owes[id] ?? 0;
          final (did, owe) = e.refund
              ? ('received', isMe ? 'get back' : 'gets back')
              : ('paid', isMe ? 'owe' : 'owes');
          final text = p != 0 && o != 0
              ? '$name $did ${m(p)} and $owe ${m(o)}'
              : p != 0
                  ? '$name $did ${m(p)}'
                  : '$name $owe ${m(o)}';
          return (name: name, isMe: isMe, text: text);
        }(),
  ];
}

/// The expense's own events from the group feed (docs/API.md `expenseId`), newest first, 20 at a time; offline it
/// shows what the activity cache holds for this expense.
class ExpenseHistory extends ConsumerStatefulWidget {
  final String groupId;
  final String expenseId;
  const ExpenseHistory({super.key, required this.groupId, required this.expenseId});
  @override
  ConsumerState<ExpenseHistory> createState() => _ExpenseHistoryState();
}

class _ExpenseHistoryState extends ConsumerState<ExpenseHistory> {
  static const _pageSize = 20;
  List<ActivityItem> _items = const [];
  int? _nextBefore;
  bool _loading = true;
  bool _live = false; // _items came from the server
  bool _loadingMore = false;
  int _generation = 0; // bumped by every refresh, so a late first page is dropped

  @override
  void initState() {
    super.initState();
    _loadCache();
    _refresh();
  }

  /// A server before Phase 5 ignores the filter: keep only this expense's items either way.
  List<ActivityItem> _mine(List<ActivityItem> items) =>
      [for (final i in items) if (i.expenseId?.toLowerCase() == widget.expenseId.toLowerCase()) i];

  Future<void> _loadCache() async {
    final db = ref.read(dbProvider);
    final rows = await (db.select(db.activity)
          ..where((a) =>
              a.groupId.equals(widget.groupId) &
              const CustomExpression<String>(r"json_extract(json, '$.expenseId')").equals(widget.expenseId))
          ..orderBy([(a) => OrderingTerm.desc(a.feedId)]))
        .get();
    if (!mounted || _live) return; // the network answered first
    setState(() => _items = [for (final r in rows) ActivityItem.fromJson((jsonDecode(r.json) as Map).cast())]);
  }

  /// The first page ([before] null) replaces the list, a later one appends; dropped if a refresh started meanwhile.
  Future<void> _fetch({int? before}) async {
    final gen = _generation;
    final page = await ref
        .read(apiProvider)
        .activity(groupId: widget.groupId, before: before, limit: _pageSize, expenseId: widget.expenseId);
    await cacheActivity(ref.read(dbProvider), page.items, widget.groupId);
    if (!mounted || gen != _generation) return;
    setState(() {
      _items = [if (before != null) ..._items, ..._mine(page.items)];
      _nextBefore = page.nextBefore;
      _live = true;
    });
  }

  Future<void> _refresh() async {
    final gen = ++_generation;
    try {
      await _fetch();
    } catch (_) {
      // Offline or an error: the cached rows stay.
    } finally {
      if (mounted && gen == _generation) setState(() => _loading = false);
    }
  }

  Future<void> _more() async {
    if (_loadingMore || _nextBefore == null) return;
    setState(() => _loadingMore = true);
    try {
      await _fetch(before: _nextBefore);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A change pulled by sync (an edit here or elsewhere, a comment) → the first page again.
    ref.listen<int?>(groupProvider(widget.groupId).select((g) => g.value?.latestSeq), (a, b) {
      if (a != null && a != b) _refresh();
    });
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (_items.isEmpty && (_loading || _nextBefore == null)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: _loading
            ? const Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : Text(_live ? 'No history yet.' : 'History shows up here once you are online.',
                style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
      );
    }
    final rows = <Widget>[];
    String? lastDay;
    for (final (item: i, :count) in foldReceipts(_items)) {
      final day = dayLabel(i.createdAt);
      if (day != lastDay) {
        lastDay = day;
        rows.add(Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(day, style: text.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
        ));
      }
      rows.add(ActivityTile(key: ValueKey(i.seq), item: i, count: count, groupId: widget.groupId, embedded: true));
    }
    // An older server ignores the filter: a page can hold none of this expense's items yet more may follow.
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (!_live && !_loading)
        Text('Showing saved history.', style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      ...rows,
      if (_nextBefore != null)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _loadingMore ? null : _more,
            child: _loadingMore
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Show more'),
          ),
        ),
    ]);
  }
}
