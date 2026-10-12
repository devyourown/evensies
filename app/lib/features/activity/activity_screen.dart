import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n.dart';
import '../../core/offline_banner.dart';
import '../../core/snack.dart';
import '../../data/db/database.dart';
import '../../domain/activity.dart';
import '../../domain/models.dart';
import '../../domain/recurrence.dart';
import '../../l10n/app_localizations_en.dart';
import '../../providers.dart';
import '../friends/home_data.dart';
import '../group_detail/balances.dart';

/// Overall feed across all my groups (route `/activity`).
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l.activity)),
        body: const Column(children: [OfflineBanner(), Expanded(child: ActivityList())]),
      );
}

/// Server feed, newest first, with the fetched items cached in drift for offline viewing.
class ActivityList extends ConsumerStatefulWidget {
  /// One group's feed; every group's when null.
  final String? groupId;
  const ActivityList({super.key, this.groupId});
  @override
  ConsumerState<ActivityList> createState() => _ActivityListState();
}

class _ActivityListState extends ConsumerState<ActivityList> {
  static const _pageSize = 50;
  List<ActivityItem> _items = const [];
  int? _nextBefore;
  bool _live = false; // _items came from the server (contiguous from the newest), not from the cache
  bool _loading = true; // first page in flight
  bool _failed = false; // first page failed: showing the cache, if any
  bool _loadingMore = false;
  bool _moreFailed = false;
  int _generation = 0; // bumped by every refresh so a late "more" page is dropped

  @override
  void initState() {
    super.initState();
    _loadCache();
    _refresh();
    _syncNow();
  }

  /// Names and the expense to open come from the local group, so pull it too (push may be off or missed).
  Future<void> _syncNow() {
    final sync = ref.read(syncProvider);
    final gid = widget.groupId;
    return (gid == null ? sync.syncAll() : sync.sync(gid)).catchError((_) {});
  }

  /// The paging cursor: seq in a group feed, feedId in the overall one (docs/API.md).
  int _key(ActivityItem i) => widget.groupId == null ? i.feedId ?? i.seq : i.seq;

  Future<void> _loadCache() async {
    final db = ref.read(dbProvider);
    final q = db.select(db.activity)
      ..orderBy([(a) => OrderingTerm.desc(a.feedId)])
      ..limit(_pageSize);
    final gid = widget.groupId;
    if (gid != null) q.where((a) => a.groupId.equals(gid));
    final rows = await q.get();
    // The network may have answered first.
    if (!mounted || !(_loading || _failed) || _items.isNotEmpty) return;
    setState(() => _items = [for (final r in rows) ActivityItem.fromJson((jsonDecode(r.json) as Map).cast())]);
  }

  Future<void> _cache(List<ActivityItem> items) => cacheActivity(ref.read(dbProvider), items, widget.groupId);

  Future<void> _refresh() async {
    final gen = ++_generation;
    try {
      final page = await ref.read(apiProvider).activity(groupId: widget.groupId, limit: _pageSize);
      await _cache(page.items);
      if (!mounted || gen != _generation) return;
      // Seen up to the newest item shown (docs/API.md 읽지 않은 활동); an empty page sends nothing.
      final newest = page.items.map((i) => i.feedId ?? 0).fold(0, (a, b) => a > b ? a : b);
      if (newest > 0) ref.read(unreadProvider.notifier).seen(newest, groupId: widget.groupId);
      final cut = page.nextBefore;
      setState(() {
        if (_live && cut != null && _items.isNotEmpty && cut <= _key(_items.first)) {
          // The new first page reaches what is loaded: keep the older pages instead of paging them again.
          _items = [...page.items, ..._items.where((i) => _key(i) < cut)];
        } else {
          _items = page.items;
          _nextBefore = cut;
        }
        _live = true;
        _failed = false;
        _moreFailed = false;
      });
    } catch (_) {
      if (mounted && gen == _generation) setState(() => _failed = true);
    } finally {
      if (mounted && gen == _generation) setState(() => _loading = false);
    }
  }

  Future<void> _more() async {
    final before = _nextBefore;
    if (!mounted || _loadingMore || before == null) return; // also runs from a post-frame callback
    final gen = _generation;
    setState(() {
      _loadingMore = true;
      _moreFailed = false;
    });
    try {
      final page = await ref.read(apiProvider).activity(groupId: widget.groupId, before: before, limit: _pageSize);
      await _cache(page.items);
      if (!mounted || gen != _generation) return;
      setState(() {
        _items = [..._items, ...page.items];
        _nextBefore = page.nextBefore;
      });
    } catch (_) {
      if (mounted) setState(() => _moreFailed = true);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // New events pulled by sync (push, resume, own writes) → reload the first page.
    void onSeq(int? a, int? b) {
      if (a != null && a != b) _refresh();
    }

    if (widget.groupId case final gid?) {
      ref.listen<int?>(groupProvider(gid).select((g) => g.value?.latestSeq), onSeq);
    } else {
      ref.listen<int?>(groupsProvider.select((g) => g.value?.fold<int>(0, (s, x) => s + x.latestSeq)), onSeq);
    }

    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l;
    Widget message(IconData icon, String title, String body, {Widget? action}) => ListView(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
            child: Column(children: [
              Icon(icon, size: 64, color: cs.primary),
              const SizedBox(height: 16),
              Text(title, style: text.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(body, style: TextStyle(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
              if (action != null) ...[const SizedBox(height: 16), action],
            ]),
          ),
        ]);

    final Widget child;
    if (_items.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_items.isEmpty && _failed) {
      child = message(Icons.cloud_off_outlined, l.activityNeedsConnection, l.activityOfflineNote,
          action: OutlinedButton(onPressed: _refresh, child: Text(l.retry)));
    } else if (_items.isEmpty && _nextBefore == null) {
      // Only a null nextBefore is the end: an empty page can be all hidden events.
      child = message(
          Icons.history, l.noActivityYet, widget.groupId == null ? l.activityAllGroups : l.activityThisGroup);
    } else {
      final rows = <Widget>[
        if (_failed)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(l.showingSaved,
                style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ),
      ];
      String? lastDay;
      final restoreOffered = <String>{}; // expense and payment ids: only the newest delete row offers Restore
      for (final (item: i, :count) in foldReceipts(_items)) {
        final day = dayLabel(i.createdAt, l: l);
        if (day != lastDay) {
          lastDay = day;
          rows.add(Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(day, style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
          ));
        }
        rows.add(ActivityTile(
          item: i,
          count: count,
          groupId: i.groupId ?? widget.groupId!,
          showGroup: widget.groupId == null,
          // Newest first, so this is the expense's (or payment's) latest delete: the only row that offers Restore. A
          // move counts as a delete with no Restore (it would count in both groups, docs/API.md 적용 규칙 13).
          offerRestore: switch (i.kind) {
            'expense_deleted' || 'expense_moved' =>
              i.expenseId != null && restoreOffered.add(i.expenseId!) && i.kind == 'expense_deleted',
            'payment_deleted' => i.paymentId != null && restoreOffered.add(i.paymentId!),
            _ => false,
          },
        ));
      }
      final wantMore = _nextBefore != null && !_moreFailed;
      if (_nextBefore != null) {
        rows.add(_moreFailed
            ? Center(child: TextButton(onPressed: _more, child: Text(l.loadMore)))
            : const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
              ));
      }
      child = ListView.builder(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: rows.length,
        itemBuilder: (_, n) {
          // Page in only when the end of the list is about to come into view.
          if (wantMore && !_loadingMore && n >= rows.length - 5) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _more());
          }
          return rows[n];
        },
      );
    }
    return RefreshIndicator(onRefresh: () => Future.wait([_refresh(), _syncNow()]), child: child);
  }
}

/// Fetched feed items into the offline cache; [groupId] for a group feed's items, which carry no groupId.
// ponytail: the cache keeps every fetched item (items never change; a deleted comment's row is dropped with its text,
// AppDatabase.dropDeletedCommentActivity); trim by age if it ever matters.
Future<void> cacheActivity(AppDatabase db, List<ActivityItem> items, String? groupId) =>
    db.batch((b) => b.insertAllOnConflictUpdate(db.activity, [
          for (final i in items)
            if ((i.groupId ?? groupId) case final gid?)
              ActivityCompanion.insert(
                groupId: gid,
                seq: i.seq,
                feedId: i.feedId ?? i.seq,
                createdAt: i.createdAt ?? '',
                json: jsonEncode({...i.json, 'groupId': gid}),
              ),
        ]));

/// The feed as rows, newest first: one person's receipt_added (or receipt_removed) in a row on one expense and day is
/// one row with their [count], and receipts added right with an expense show no row (its expense_added says it).
List<({ActivityItem item, int count})> foldReceipts(List<ActivityItem> items) {
  final rows = <({ActivityItem item, int count})>[];
  for (final i in items) {
    final last = rows.lastOrNull?.item;
    final same = last != null &&
        last.actorMemberId == i.actorMemberId &&
        last.expenseId == i.expenseId &&
        last.groupId == i.groupId &&
        _day(last.createdAt) == _day(i.createdAt);
    if (same && i.kind.startsWith('receipt_') && last.kind == i.kind) {
      rows.last = (item: last, count: rows.last.count + 1);
    } else if (same && i.kind == 'expense_added' && last.kind == 'receipt_added') {
      rows.last = (item: i, count: 1);
    } else {
      rows.add((item: i, count: 1));
    }
  }
  return rows;
}

DateTime? _local(String? iso) => iso == null ? null : DateTime.tryParse(iso)?.toLocal();

/// The local calendar day of a feed timestamp (folding rows), or null.
String? _day(String? iso) => _local(iso)?.toIso8601String().substring(0, 10);

/// "Today", "Yesterday", "Mon, 5 Oct" or "5 Oct 2025" for a feed timestamp, in [l]'s language (English by default).
String dayLabel(String? iso, {DateTime? now, AppLocalizations? l}) {
  final words = l ?? AppLocalizationsEn();
  final d = _local(iso);
  if (d == null) return words.earlier;
  final today = now ?? DateTime.now();
  // Calendar days in UTC: local midnights are 23 or 25 hours apart around a DST change.
  final diff = DateTime.utc(today.year, today.month, today.day).difference(DateTime.utc(d.year, d.month, d.day)).inDays;
  if (diff == 0) return words.today;
  if (diff == 1) return words.yesterday;
  return (d.year == today.year ? DateFormat.MMMEd() : DateFormat.yMMMd()).format(d);
}

/// One feed row; names and "me" come from the local group, so renames show up without a refetch.
class ActivityTile extends ConsumerWidget {
  final ActivityItem item;
  final String groupId;
  final bool showGroup;

  /// Whether a deleted expense's or payment's row may show Restore (the list offers it on the newest delete only).
  final bool offerRestore;

  /// In an expense's own History: no tap (that is where it would go) and no side inset (the screen has one).
  final bool embedded;

  /// The receipts this row stands for ([foldReceipts]).
  final int count;
  const ActivityTile({
    super.key,
    required this.item,
    this.count = 1,
    required this.groupId,
    this.showGroup = false,
    this.offerRestore = false,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l = context.l;
    final group = ref.watch(groupProvider(groupId)).value;
    final state = ref.watch(groupStateProvider(groupId)).value;
    final home = ref.watch(homeDataProvider).value;
    // In a friend group the other member is named as on the Friends tab, not by a claimed placeholder's old name.
    final friend = state != null && state.isFriend ? home?.friendName(groupId) : null;
    final names = {
      for (final m in state?.members ?? const <Member>[])
        m.id: friend != null && m.id != group?.myMemberId && m.userId != home?.myUserId ? friend : m.name,
    };
    // A series' row opens its latest repeat (none here: nothing to open, docs/API.md 푸시 앱).
    final expense = item.expenseId != null
        ? state?.expense(item.expenseId!)
        : item.kind.startsWith('recurrence_') && item.recurrenceId != null
            ? state?.latestRepeat(item.recurrenceId!)
            : null;
    final payment = item.paymentId == null ? null : state?.payment(item.paymentId!);
    final restorable = offerRestore && item.kind == 'expense_deleted' && expense != null && expense.deleted;
    // A deleted payment: not an edited one, and only for the payer's or receiver's user (docs/API.md 송금 되살리기).
    final me = ref.watch(sessionProvider).value?.userId;
    final restorablePayment = offerRestore &&
        item.kind == 'payment_deleted' &&
        payment != null &&
        payment.deleted &&
        !payment.replaced &&
        me != null &&
        (state?.member(payment.fromMember)?.userId == me || state?.member(payment.toMember)?.userId == me);
    final (icon, bg, fg) = switch (item.kind) {
      'expense_deleted' || 'payment_deleted' || 'member_removed' || 'receipt_removed' => (
          Icons.delete_outline,
          cs.errorContainer,
          cs.onErrorContainer
        ),
      'expense_added' => (Icons.receipt_long_outlined, cs.primaryContainer, cs.onPrimaryContainer),
      'expense_repeated' || 'recurrence_created' => (Icons.repeat, cs.primaryContainer, cs.onPrimaryContainer),
      'recurrence_updated' => (Icons.edit_calendar_outlined, cs.primaryContainer, cs.onPrimaryContainer),
      'recurrence_deleted' => (Icons.event_busy_outlined, cs.surfaceContainerHighest, cs.onSurfaceVariant),
      'receipt_added' => (Icons.add_photo_alternate_outlined, cs.primaryContainer, cs.onPrimaryContainer),
      'expense_updated' || 'payment_edited' => (Icons.edit_outlined, cs.primaryContainer, cs.onPrimaryContainer),
      'expense_restored' || 'payment_restored' => (Icons.restore, cs.primaryContainer, cs.onPrimaryContainer),
      'comment_added' => (Icons.chat_bubble_outline, cs.secondaryContainer, cs.onSecondaryContainer),
      'payment_added' || 'payment_confirmed' => (Icons.payments_outlined, cs.tertiaryContainer, cs.onTertiaryContainer),
      'member_added' || 'member_joined' || 'friend_added' => (
          Icons.person_add_alt,
          cs.surfaceContainerHighest,
          cs.onSurfaceVariant
        ),
      'expense_moved' => (Icons.drive_file_move_outline, cs.surfaceContainerHighest, cs.onSurfaceVariant),
      'member_left' => (Icons.logout, cs.surfaceContainerHighest, cs.onSurfaceVariant),
      _ => (Icons.group_outlined, cs.surfaceContainerHighest, cs.onSurfaceVariant),
    };
    final time = _local(item.createdAt);
    // A catch-up adds several repeats at once: each row says which date it is for.
    final due = item.kind == 'expense_repeated' ? DateTime.tryParse(expense?.date ?? '') : null;
    final meta = [
      // A friend group reads "Non-group · Ben".
      if (showGroup) home?.label(groupId, l) ?? group?.name ?? '',
      if (due != null && (time == null || !DateUtils.isSameDay(due, time))) l.forDate(DateFormat.MMMEd().format(due)),
      if (time != null) DateFormat.jm().format(time),
    ].where((s) => s.isNotEmpty).join(' · ');

    final kind = item.kind;
    final String? target;
    if (expense != null) {
      target = '/groups/$groupId/expenses/${expense.id}';
    } else if (group == null) {
      target = null; // not on this device yet
    } else if (payment != null) {
      target = '/groups/$groupId/payments/${payment.id}'; // the payment, its status and comments
    } else if (kind.startsWith('payment_')) {
      target = '/groups/$groupId/settle'; // not synced yet: where sent payments are confirmed
    } else if (kind == 'friend_added') {
      target = '/groups/$groupId'; // the friend's page
    } else if (kind.startsWith('member_')) {
      target = '/groups/$groupId/members';
    } else if (kind == 'group_updated') {
      target = '/groups/$groupId/settings';
    } else if (kind.startsWith('recurrence_')) {
      target = null;
    } else {
      target = showGroup ? '/groups/$groupId' : null;
    }
    final delta = myDeltaText(item);
    final actor = item.actorMemberId;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: embedded ? 0 : 16),
      leading: CircleAvatar(backgroundColor: bg, foregroundColor: fg, child: Icon(icon, size: 20)),
      // Comments can be long (the expense shows them in full); change lists are short enough to show whole.
      // An expense's History only marks when someone commented: the text is in Comments right below.
      title: Text(
          keepAll(
              embedded && kind == 'comment_added'
                  ? (actor != null && actor == group?.myMemberId
                      ? l.youCommented
                      : l.nameCommented(names[actor] ?? l.someone))
                  : activityText(item, names, group?.myMemberId, withDelta: false, count: count),
              l.localeName),
          maxLines: kind == 'comment_added' ? 3 : null,
          overflow: kind == 'comment_added' ? TextOverflow.ellipsis : null),
      subtitle: delta == null && meta.isEmpty
          ? null
          : Text.rich(TextSpan(style: TextStyle(color: cs.onSurfaceVariant), children: [
              // Same colors as the expense list's "you borrowed" / "you lent".
              if (delta != null)
                TextSpan(
                    text: delta,
                    style: TextStyle(color: item.myDelta! < 0 ? cs.error : cs.primary, fontWeight: FontWeight.w600)),
              if (delta != null && meta.isNotEmpty) const TextSpan(text: ' · '),
              TextSpan(text: meta),
            ])),
      trailing: restorable
          ? TextButton(
              onPressed: () async {
                await ref.read(localWritesProvider).restoreExpense(groupId, expense.id);
                if (context.mounted) showInfo(context, context.l.restoredName(expense.description));
              },
              child: Text(l.restore),
            )
          : restorablePayment
              ? TextButton(
                  key: const Key('restore-payment'),
                  onPressed: () async {
                    await ref.read(localWritesProvider).restorePayment(groupId, payment.id);
                    if (context.mounted) showInfo(context, context.l.paymentRestored);
                  },
                  child: Text(l.restore),
                )
              : null,
      onTap: target == null || embedded ? null : () => context.push(target!),
    );
  }
}
