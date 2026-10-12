import 'dart:convert';

import 'package:drift/drift.dart' show BooleanExpressionOperators, CustomExpression, OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/confirm.dart';
import '../../core/ids.dart';
import '../../core/l10n.dart';
import '../../core/money.dart';
import '../../core/offline_banner.dart';
import '../../core/snack.dart';
import '../../domain/activity.dart';
import '../../domain/categories.dart';
import '../../domain/insights.dart' show paidAmounts;
import '../../domain/itemized.dart';
import '../../domain/models.dart';
import '../../domain/recurrence.dart';
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
    final l = context.l;
    if (e == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.receipt_long_outlined, size: 64, color: cs.primary),
              const SizedBox(height: 16),
              Text(l.expenseNotHere, style: text.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(l.notSyncedOrLeft,
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
    final series = state.isActive(e.recurrenceId) ? state.recurrence(e.recurrenceId!) : null;
    // Its own line, in the form's words (docs/API.md 반복 지출 9단계). The latest repeat says when the next one comes
    // (always within a year, so no year), with its amount when future repeats were changed apart from it.
    String? repeats;
    if (series != null) {
      repeats = l.seriesRepeats(series.frequency);
      if (state.latestRepeat(series.id)?.id == e.id) {
        final n = firstOccurrenceOnOrAfter(series.frequency, series.startDate, todayIso(),
            minN: state.lastPosted(series.id) + 1);
        final day = DateFormat.MMMEd().format(DateTime.parse(n.date));
        final amount = (series.template['amount'] as num?)?.toInt() ?? e.amount;
        final currency = series.template['currency'] as String? ?? e.currency;
        repeats = amount == e.amount && currency == e.currency
            ? l.seriesRepeatsNext(series.frequency, day)
            : l.seriesRepeatsNextAmount(series.frequency, formatMoney(amount, currency), day);
      }
    }

    Widget section(String s) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(s, style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(e.deleted ? l.deletedExpense : l.expense),
        actions: [
          if (!e.deleted) ...[
            IconButton(
              tooltip: l.edit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/groups/$groupId/expenses/${e.id}/edit'),
            ),
            IconButton(
                tooltip: l.delete, icon: const Icon(Icons.delete_outline), onPressed: () => _delete(context, ref, e, series)),
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
                          Icon(Icons.undo, size: 20, color: cs.onSurfaceVariant, semanticLabel: l.refund),
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
                          date == null ? e.date : DateFormat.yMMMEd().format(date),
                          if (e.refund) l.refund,
                        ].join(' · '),
                        style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      if (repeats != null)
                        Padding(
                          key: const Key('series-line'),
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(children: [
                            Icon(Icons.repeat, size: 16, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(repeats, style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                            ),
                          ]),
                        ),
                      if (e.currency != d)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            rate > 0
                                ? l.rateLine(e.currency, numberText(rate, decimals: 10), d)
                                : l.notConvertedTo(d),
                            style: text.bodySmall?.copyWith(color: rate > 0 ? cs.onSurfaceVariant : cs.error),
                          ),
                        ),
                    ]),
                  ),
                ]),
                section(e.refund ? l.receivedSplitBack : l.whoPaidOwes),
                for (final row in _people(l, e, names, me))
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
                  section(l.items),
                  _ItemsList(bill: bill, names: names, me: me, currency: e.currency),
                ],
                if (e.notes != null) ...[
                  section(l.notes),
                  Text(e.notes!, key: const Key('detail-notes')),
                ],
                if (!e.deleted || state.receiptsOf(e.id).isNotEmpty) ...[
                  section(l.receipts),
                  ReceiptStrip(
                    groupId: groupId,
                    expenseId: e.id,
                    ids: [for (final a in state.receiptsOf(e.id)) a.id],
                    editable: !e.deleted,
                  ),
                ],
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 16),
                // History and comments in one thread, oldest first (Splitwise's expense page).
                ExpenseHistory(groupId: groupId, expenseId: e.id),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  /// In a live [series] it can also stop the repeats (Splitwise's "cancel future recurrences"); there is no restart, so
  /// that choice has no Undo.
  Future<void> _delete(BuildContext context, WidgetRef ref, Expense e, Recurrence? series) async {
    final bool stop;
    final l = context.l;
    if (series == null) {
      if (!await confirm(context, title: l.deleteExpenseTitle, message: l.deleteExpenseMessage)) {
        return;
      }
      stop = false;
    } else {
      final cs = Theme.of(context).colorScheme;
      final choice = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.deleteRepeatingTitle),
          content: Text(l.deleteRepeatingMessage),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            TextButton(
                key: const Key('delete-one'), onPressed: () => Navigator.pop(ctx, false), child: Text(l.deleteThisOne)),
            FilledButton(
              key: const Key('delete-stop'),
              style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.deleteAndStop),
            ),
          ],
        ),
      );
      if (choice == null) return;
      stop = choice;
    }
    if (!context.mounted) return;
    final writes = ref.read(localWritesProvider);
    final messenger = ScaffoldMessenger.of(context); // the app-wide one, so the SnackBar outlives this screen
    await writes.deleteExpense(groupId, e.id, stopRecurrence: stop ? series!.id : null);
    if (!context.mounted) return;
    context.pop();
    if (stop) {
      messenger.showSnackBar(SnackBar(content: Text(l.deletedAndStopped(e.description))));
    } else {
      showUndo(messenger, l.deletedName(e.description), () => writes.restoreExpense(groupId, e.id));
    }
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
          title: Text(context.l.movedToOtherGroup, style: TextStyle(color: cs.onSecondaryContainer)),
          subtitle: Text(context.l.movedNote,
              style: TextStyle(color: cs.onSecondaryContainer)),
        ),
      );
    }
    return Card(
      color: cs.errorContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.delete_outline, color: cs.onErrorContainer),
        title: Text(context.l.expenseWasDeleted, style: TextStyle(color: cs.onErrorContainer)),
        subtitle: Text(context.l.restoreToCount, style: TextStyle(color: cs.onErrorContainer)),
        // Not offered until it is known not to be a move.
        trailing: moved == null ? null : FilledButton(onPressed: onRestore, child: Text(context.l.restore)),
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
    final l = context.l;
    String who(String id) => id == me ? l.you : names[id] ?? l.someone;
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
      for (final x in bill.lines) row(x.name, x.amount, sub: x.memberIds.map(who).join(l.listJoiner)),
      if (bill.tax != 0) row(l.tax, bill.tax),
      if (bill.tip != 0) row(l.tipService, bill.tip),
      if (bill.discount != 0) row(l.discount, bill.discount, minus: true),
    ]);
  }
}

/// "Anna paid €30.00 and owes €10.00", one line per person in the expense: payers first, in the order sent.
/// For a refund: who received it and who gets a part back.
List<({String name, bool isMe, String text})> _people(
    AppLocalizations l, Expense e, Map<String, String> names, String? me) {
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
          // My own name too: the avatar shows its initial ("You"/"Tu" would read as someone else's), the sentences
          // for me don't use it.
          final name = names[id] ?? l.someone;
          final p = paid[id] ?? 0, o = owes[id] ?? 0;
          final text = switch ((e.refund, isMe, p != 0, o != 0)) {
            (false, true, true, true) => l.youPaidOwe(m(p), m(o)),
            (false, true, true, false) => l.youPaid(m(p)),
            (false, true, false, _) => l.youOwe(m(o)),
            (false, false, true, true) => l.namePaidOwes(name, m(p), m(o)),
            (false, false, true, false) => l.namePaid(name, m(p)),
            (false, false, false, _) => l.nameOwes(name, m(o)),
            (true, true, true, true) => l.youReceivedGetBack(m(p), m(o)),
            (true, true, true, false) => l.youReceived(m(p)),
            (true, true, false, _) => l.youGetBackLine(m(o)),
            (true, false, true, true) => l.nameReceivedGetsBack(name, m(p), m(o)),
            (true, false, true, false) => l.nameReceived(name, m(p)),
            (true, false, false, _) => l.nameGetsBack(name, m(o)),
          };
          return (name: name, isMe: isMe, text: text);
        }(),
  ];
}

/// The expense's own events from the group feed (docs/API.md `expenseId`), 20 at a time, threaded with its comments
/// ([CommentThread]); offline it shows what the activity cache holds for this expense.
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
    final l = context.l;
    // Oldest first: the earlier history pages load at the top. An older server ignores the filter, so a page can hold
    // none of this expense's items yet more may follow.
    final header = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (_loading && _items.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        )
      else if (!_live && _items.isEmpty)
        Text(l.historyOffline, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant))
      else if (!_live)
        Text(l.showingSavedHistory, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      if (_nextBefore != null)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            key: const Key('history-earlier'),
            onPressed: _loadingMore ? null : _more,
            child: _loadingMore
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l.showEarlier),
          ),
        ),
    ]);
    return CommentThread(
      groupId: widget.groupId,
      expenseId: widget.expenseId,
      history: _items,
      title: l.historyAndComments,
      header: header,
    );
  }
}
