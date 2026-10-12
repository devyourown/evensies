import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../core/offline_banner.dart';
import '../../data/db/database.dart';
import '../../data/fx_rates.dart';
import '../../domain/fx.dart';
import '../../domain/models.dart';
import '../../providers.dart';
import '../activity/activity_screen.dart';
import '../categories/category_ui.dart';
import '../friends/friend_screen.dart';
import '../friends/home_data.dart';
import 'balances.dart';
import 'convert_sheet.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  /// `activity` opens the Activity tab (`/groups/{id}?tab=activity`, e.g. from a notification).
  final String? tab;
  const GroupDetailScreen({super.key, required this.groupId, this.tab});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  /// Opening a group pulls it: repeats added by the server and other members' changes show up without a push. Only one
  /// on this device: syncAll adopts the others (as push.dart does).
  @override
  void initState() {
    super.initState();
    final sync = ref.read(syncProvider), id = widget.groupId;
    ref.read(dbProvider).getGroup(id).then((g) {
      if (g != null) sync.syncLater(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupId = widget.groupId, tab = widget.tab;
    final async = ref.watch(groupProvider(groupId));
    final group = async.value;
    if (group == null && async.hasValue) return const _Gone();
    if (group == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    // A friend group is a person (docs/API.md 친구): links and pushes to it land on the friend's page.
    if (group.kind == 'friend') return _FriendGroup(groupId: groupId);
    return DefaultTabController(
      key: ValueKey(tab), // a new ?tab= on the same page re-selects the tab
      length: 3,
      initialIndex: tab == 'activity' ? 2 : 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          actions: [
            IconButton(
              tooltip: 'Search',
              onPressed: () => context.push('/search?group=$groupId'),
              icon: const Icon(Icons.search),
            ),
            IconButton(
              tooltip: 'Insights',
              onPressed: () => context.push('/groups/$groupId/insights'),
              icon: const Icon(Icons.insights),
            ),
            IconButton(
              tooltip: 'Members & invite',
              onPressed: () => context.push('/groups/$groupId/members'),
              icon: const Icon(Icons.people_outline),
            ),
            IconButton(
              tooltip: 'Group settings',
              onPressed: () => context.push('/groups/$groupId/settings'),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
          // The largest text sizes: tabs that scroll, not labels clipped to "Expe".
          bottom: TabBar(isScrollable: MediaQuery.textScalerOf(context).scale(1) > 2, tabs: [
            const Tab(text: 'Expenses'),
            const Tab(text: 'Balances'),
            Tab(
              child: Badge(
                key: const Key('group-activity-badge'),
                isLabelVisible: (ref.watch(unreadProvider)?.groups[groupId] ?? 0) > 0,
                label: Text(badgeLabel(ref.watch(unreadProvider)?.groups[groupId] ?? 0)),
                offset: const Offset(14, -6),
                child: const Text('Activity'),
              ),
            ),
          ]),
        ),
        body: Column(children: [
          const OfflineBanner(),
          Expanded(
            child: TabBarView(children: [
              _ExpensesTab(group: group),
              _BalancesTab(group: group),
              ActivityList(groupId: groupId),
            ]),
          ),
        ]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/groups/$groupId/expenses/new'),
          icon: const Icon(Icons.add),
          label: const Text('Expense'),
        ),
      ),
    );
  }
}

class _FriendGroup extends ConsumerWidget {
  final String groupId;
  const _FriendGroup({required this.groupId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = ref.watch(homeDataProvider).value?.friendKey(groupId);
    return key == null ? const Scaffold(body: Center(child: CircularProgressIndicator())) : FriendScreen(personKey: key);
  }
}

/// No local row: I left or was removed (here or on another device), or a just-joined group hasn't synced yet.
/// The screen switches to the group by itself once its row arrives.
class _Gone extends StatelessWidget {
  const _Gone();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_off_outlined, size: 64, color: cs.primary),
              const SizedBox(height: 16),
              Text("This group isn't on this device", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                "You left it, someone removed you, or it hasn't synced yet.",
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => context.go('/'), child: const Text('Back to groups')),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Sun, 11 Oct" above an expense date's rows (the group list, a friend's page).
class DateHeader extends StatelessWidget {
  final String date;
  const DateHeader(this.date, {super.key});
  @override
  Widget build(BuildContext context) {
    final d = DateTime.tryParse(date);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(d == null ? date : DateFormat('EEE, d MMM').format(d),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  final GroupRow group;
  const _ExpensesTab({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupStateProvider(group.id)).value;
    final cs = Theme.of(context).colorScheme;
    if (state == null) return const Center(child: CircularProgressIndicator());
    final expenses = state.expenses.where((e) => !e.deleted).toList()..sort((a, b) => b.date.compareTo(a.date));
    final payments = state.payments.where((p) => !p.deleted).toList();
    final names = {for (final m in state.members) m.id: m.name};

    Future<void> refresh() => ref.read(syncProvider).sync(group.id).catchError((_) {});

    if (expenses.isEmpty && payments.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        // Short content: without it there is nothing to pull.
        child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
            child: Column(children: [
              Icon(Icons.receipt_long_outlined, size: 64, color: cs.primary),
              const SizedBox(height: 16),
              Text('No expenses yet', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Tap "Expense" to add the first one.', style: TextStyle(color: cs.onSurfaceVariant)),
            ]),
          ),
        ]),
      );
    }

    final rows = <({String date, Widget tile})>[
      for (final e in expenses)
        (date: e.date, tile: ExpenseTile(expense: e, group: group, names: names)),
      for (final p in payments)
        (date: p.date, tile: PaymentTile(groupId: group.id, payment: p, names: names, myMemberId: group.myMemberId)),
    ]..sort((a, b) => b.date.compareTo(a.date));
    final items = <Widget>[];
    String? lastDate;
    for (final r in rows) {
      if (r.date != lastDate) {
        lastDate = r.date;
        items.add(DateHeader(r.date));
      }
      items.add(r.tile);
    }
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(padding: const EdgeInsets.only(bottom: 88), children: items),
    );
  }
}

/// One expense row: category, description, who paid, my part, the amount, a receipt mark and a repeat mark (a live
/// series, docs/API.md 반복 지출). Search and a friend's page reuse it.
class ExpenseTile extends ConsumerWidget {
  final Expense expense;
  final GroupRow group;

  /// memberId → name.
  final Map<String, String> names;

  /// A muted last line, e.g. the group and the matching note in Search.
  final String? extra;
  const ExpenseTile({super.key, required this.expense, required this.group, required this.names, this.extra});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = expense;
    final receipts = ref.watch(attachmentCountsProvider(group.id)).value?[e.id] ?? 0;
    final repeats = e.recurrenceId != null && ref.watch(activeSeriesProvider(group.id)).contains(e.recurrenceId);
    final myMemberId = group.myMemberId;
    final cs = Theme.of(context).colorScheme;
    final d = group.defaultCurrency;
    final foreign = e.currency != d;
    final rate = e.fxRateToDefault ?? 0;
    final fxMissing = foreign && !(rate > 0); // null or 0: not converted
    // "≈ €69.55" under a converted foreign amount.
    final approx = !foreign || fxMissing
        ? null
        : tryFx(() => convertAmount(
            amount: e.amount, fromDecimals: Money.digits(e.currency), toDecimals: Money.digits(d), rate: rate));

    int mineIn(List<Share> l) => l.where((s) => s.memberId == myMemberId).fold(0, (a, s) => a + s.amount);
    final myShare = mineIn(e.shares);
    final myPaid = mineIn(e.payers);
    final n = e.payers.length;
    // Splitwise's "you paid €12.80"; "2 people paid €300.00" rather than one name with "+1" (#107).
    final payer = n > 1 ? '$n people' : e.paidBy == myMemberId ? 'you' : names[e.paidBy] ?? '?';
    final who = e.refund ? 'refund to $payer' : '$payer paid ${formatMoney(e.amount, e.currency)}';
    // sign × (what I paid − my share); a refund reverses it (docs/API.md 잔액).
    final delta = (e.refund ? -1 : 1) * (myPaid - myShare);
    final involved = (myMemberId != null && e.payers.any((p) => p.memberId == myMemberId)) || myShare != 0;
    String mine;
    Color mineColor = cs.onSurfaceVariant;
    if (!involved) {
      mine = 'not involved';
    } else if (delta == 0) {
      mine = e.refund ? 'all yours' : 'you paid for yourself';
    } else if (delta > 0) {
      mine = '${e.refund ? 'you get back' : 'you lent'} ${formatMoney(delta, e.currency)}';
      mineColor = cs.primary;
    } else {
      mine = '${e.refund ? 'you owe' : 'you borrowed'} ${formatMoney(-delta, e.currency)}';
      mineColor = cs.error;
    }

    final subtitle = Text.rich(
      TextSpan(children: [
        TextSpan(text: '$who · $mine', style: TextStyle(color: mineColor)),
        if (extra != null) TextSpan(text: '\n$extra', style: TextStyle(color: cs.onSurfaceVariant)),
      ]),
      maxLines: extra == null ? null : 3,
      overflow: extra == null ? null : TextOverflow.ellipsis,
    );
    // The largest text sizes: no icon, and the amount under the text instead of a squeezed column at the end.
    final large = MediaQuery.textScalerOf(context).scale(1) > 2;
    final amounts = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: large ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          if (repeats) ...[
            Icon(Icons.repeat,
                key: const Key('repeat-mark'), size: 16, color: cs.onSurfaceVariant, semanticLabel: 'Repeats'),
            const SizedBox(width: 4),
          ],
          if (receipts > 0) ...[
            Icon(Icons.receipt_outlined,
                key: const Key('receipt-mark'),
                size: 16,
                color: cs.onSurfaceVariant,
                semanticLabel: receipts == 1 ? 'Has a receipt' : 'Has $receipts receipts'),
            const SizedBox(width: 4),
          ],
          if (e.refund) ...[
            Icon(Icons.undo, size: 16, color: cs.onSurfaceVariant, semanticLabel: 'Refund'),
            const SizedBox(width: 4),
          ],
          Text(formatMoney(e.amount, e.currency), style: Theme.of(context).textTheme.titleMedium),
        ]),
        if (foreign)
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (fxMissing) ...[
              Icon(Icons.warning_amber_rounded, size: 14, color: cs.error, semanticLabel: 'Not converted'),
              const SizedBox(width: 2),
            ],
            Text(approx == null ? e.currency : '≈ ${formatMoney(approx, d)}',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: fxMissing ? cs.error : cs.onSurfaceVariant)),
          ]),
      ],
    );

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: large ? null : CategoryAvatar(e.category),
      title: Text(e.description, maxLines: large ? 3 : 1, overflow: TextOverflow.ellipsis),
      isThreeLine: extra != null && !large,
      subtitle: large
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [subtitle, const SizedBox(height: 4), amounts],
            )
          : subtitle,
      trailing: large ? null : amounts,
      onTap: () => context.push('/groups/${group.id}/expenses/${e.id}'),
    );
  }
}

/// One payment row (the expense list, a friend's page); tapping opens the payment (docs/API.md 송금 상세).
class PaymentTile extends StatelessWidget {
  final String groupId;
  final Payment payment;

  /// memberId → name.
  final Map<String, String> names;
  final String? myMemberId;

  /// A muted last line, e.g. the group on a friend's page.
  final String? extra;
  const PaymentTile(
      {super.key, required this.groupId, required this.payment, required this.names, this.myMemberId, this.extra});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    String who(String id, {bool start = false}) => id == myMemberId ? (start ? 'You' : 'you') : names[id] ?? '?';
    final large = MediaQuery.textScalerOf(context).scale(1) > 2; // like ExpenseTile: the names wrap
    final pending = payment.pending
        ? Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: cs.tertiaryContainer, borderRadius: BorderRadius.circular(4)),
              child: Text('pending', style: text.labelSmall?.copyWith(color: cs.onTertiaryContainer)),
            ),
          )
        : null;
    final amount = Text(formatMoney(payment.amount, payment.currency), style: text.titleMedium);
    // The largest text sizes: the amount under the names, not a column squeezing them (as on ExpenseTile).
    final lines = [?pending, if (extra != null) Text(extra!, style: TextStyle(color: cs.onSurfaceVariant)), if (large) amount];
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      // Same tile as an expense's category, so the rows line up.
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.payments_outlined, size: 22, color: cs.onSurfaceVariant),
      ),
      title: Text('${who(payment.fromMember, start: true)} paid ${who(payment.toMember)}',
          maxLines: large ? 3 : 1, overflow: TextOverflow.ellipsis),
      subtitle: lines.isEmpty
          ? null
          : lines.length == 1
              ? lines.single
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: lines),
      trailing: large ? null : amount,
      onTap: () => context.push('/groups/$groupId/payments/${payment.id}'),
    );
  }
}

class _BalancesTab extends ConsumerWidget {
  final GroupRow group;
  const _BalancesTab({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(balancesProvider(group.id));
    final members = ref.watch(membersProvider(group.id)).value ?? const <MemberRow>[];
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // Short content: AlwaysScrollable, or there is nothing to pull.
    Widget list(List<Widget> children) => RefreshIndicator(
          onRefresh: () => ref.read(syncProvider).sync(group.id).catchError((_) {}),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            children: children,
          ),
        );
    final res = async.value;
    if (res == null) return const Center(child: CircularProgressIndicator());
    final d = group.defaultCurrency;
    final b = res.balances;
    final others = res.others;
    final rows = _rows(members, b);
    final maxAbs = rows.fold(0, (acc, m) => (b[m.id] ?? 0).abs() > acc ? (b[m.id] ?? 0).abs() : acc);
    final unsettled = maxAbs > 0;
    final me = group.myMemberId;
    final myPending = (ref.watch(groupStateProvider(group.id)).value?.payments ?? const <Payment>[])
        .where((p) => !p.deleted && p.pending && (p.fromMember == me || p.toMember == me))
        .length;
    final home = ref.watch(homeCurrencyProvider);
    final approx = approxIn(home, res.mine(me), ref.watch(latestFxProvider).value?.rates);

    return list([
      if (approx != null && approx != 0)
        Card(
          key: const Key('approx-total'),
          color: cs.secondaryContainer,
          child: ListTile(
            leading: Icon(Icons.currency_exchange, color: cs.onSecondaryContainer),
            title: Text('${approx < 0 ? 'You owe' : 'You are owed'} ≈ ${formatMoney(approx.abs(), home)} in total',
                style: TextStyle(color: cs.onSecondaryContainer, fontWeight: FontWeight.w600)),
            subtitle: Text('In your home currency, at the latest rates',
                style: TextStyle(color: cs.onSecondaryContainer)),
          ),
        ),
      if (!unsettled)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(children: [
            Icon(others.isNotEmpty ? Icons.currency_exchange : Icons.check_circle_outline, size: 64, color: cs.primary),
            const SizedBox(height: 16),
            // Never "All settled" next to the sections below.
            Text(others.isNotEmpty ? 'Nothing owed in $d' : 'All settled', style: text.titleMedium),
            Text(others.isNotEmpty ? 'Expenses in other currencies are below.' : 'Nobody owes anything.',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ]),
        ),
      if (whoPaysNext(b, {for (final m in members) if (!m.removed) m.id}) case final next?)
        Padding(
          key: const Key('pays-next'),
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Icon(Icons.east, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                next == me
                    ? 'You should pay next (you owe ${formatMoney(-b[next]!, d)}, the most)'
                    : '${members.firstWhere((m) => m.id == next).name} should pay next '
                        '(owes ${formatMoney(-b[next]!, d)}, the most)',
                style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ]),
        ),
      for (final m in rows)
        _BalanceRow(name: _name(m), amount: b[m.id] ?? 0, maxAbs: maxAbs, currency: d),
      if (unsettled || myPending > 0) ...[
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.push('/groups/${group.id}/settle'),
          icon: const Icon(Icons.handshake_outlined),
          label: Text(myPending > 0 ? 'Settle up · $myPending waiting' : 'Settle up'),
        ),
      ],
      for (final x in others) _NotConverted(group: group, res: res, currency: x, members: members),
    ]);
  }
}

/// Members to list for a bucket: everyone still in the group, plus people who left with a balance; largest first.
List<MemberRow> _rows(List<MemberRow> members, Map<String, int> b) =>
    members.where((m) => !m.removed || (b[m.id] ?? 0) != 0).toList()
      ..sort((x, y) => (b[y.id] ?? 0).compareTo(b[x.id] ?? 0));

String _name(MemberRow m) => m.name + (m.removed ? ' (removed)' : '');

/// "Not converted · JPY": one bucket outside the group currency (docs/API.md 통화별 잔액), with Convert.
class _NotConverted extends StatelessWidget {
  final GroupRow group;
  final BalanceResult res;
  final String currency;
  final List<MemberRow> members;
  const _NotConverted({required this.group, required this.res, required this.currency, required this.members});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final d = group.defaultCurrency;
    final b = res.byCurrency[currency] ?? const <String, int>{};
    final rows = _rows(members, b).where((m) => (b[m.id] ?? 0) != 0).toList();
    final maxAbs = rows.fold(0, (acc, m) => (b[m.id] ?? 0).abs() > acc ? (b[m.id] ?? 0).abs() : acc);
    final n = res.unconverted[currency] ?? 0;
    final unrated = res.unrated[currency] ?? 0; // what Convert fills in
    final rated = n - unrated; // has a rate that can't be used (convertExpense refused it)
    String count(int k) => '$k expense${k == 1 ? '' : 's'}';
    return Padding(
      key: Key('not-converted-$currency'),
      padding: const EdgeInsets.only(top: 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.currency_exchange, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text('Not converted · $currency', style: text.titleSmall)),
        ]),
        const SizedBox(height: 2),
        Text(
          [
            if (unrated > 0) '${count(unrated)} without a rate to $d',
            if (rated > 0) "${count(rated)} with a rate that can't be converted",
            if (n == 0) 'Payments in $currency',
            if (rows.isEmpty) 'everyone is even in $currency',
          ].join(' · '),
          style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        for (final m in rows) _BalanceRow(name: _name(m), amount: b[m.id] ?? 0, maxAbs: maxAbs, currency: currency),
        const SizedBox(height: 8),
        if (unrated > 0)
          OutlinedButton.icon(
            key: Key('convert-$currency'),
            onPressed: () => showConvertSheet(context, groupId: group.id, currencies: [currency]),
            icon: const Icon(Icons.currency_exchange),
            label: Text('Convert to $d'),
          ),
      ]),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String name;
  final int amount;
  final int maxAbs;
  final String currency;
  const _BalanceRow({required this.name, required this.amount, required this.maxAbs, required this.currency});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = amount == 0 ? cs.onSurfaceVariant : (amount > 0 ? cs.primary : cs.error);
    final frac = maxAbs == 0 ? 0.0 : amount.abs() / maxAbs;
    final label = amount == 0 ? 'settled' : (amount > 0 ? 'gets back' : 'owes');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Wraps instead of overflowing at the largest text sizes.
        Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            Text(formatMoney(amount.abs(), currency),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
          ]),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: frac, minHeight: 6, color: color, backgroundColor: cs.surfaceContainerHighest),
        ),
      ]),
    );
  }
}
