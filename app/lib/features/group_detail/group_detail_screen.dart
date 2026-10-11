import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/core_guard.dart';
import '../../core/money.dart';
import '../../core/offline_banner.dart';
import '../../data/db/database.dart';
import '../../data/fx_rates.dart';
import '../../domain/fx.dart';
import '../../domain/models.dart';
import '../../providers.dart';
import '../activity/activity_screen.dart';
import 'balances.dart';
import 'convert_sheet.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;

  /// `activity` opens the Activity tab (`/groups/{id}?tab=activity`, e.g. from a notification).
  final String? tab;
  const GroupDetailScreen({super.key, required this.groupId, this.tab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(groupProvider(groupId));
    final group = async.value;
    if (group == null && async.hasValue) return const _Gone();
    if (group == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return DefaultTabController(
      key: ValueKey(tab), // a new ?tab= on the same page re-selects the tab
      length: 3,
      initialIndex: tab == 'activity' ? 2 : 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          actions: [
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
          bottom: const TabBar(tabs: [Tab(text: 'Expenses'), Tab(text: 'Balances'), Tab(text: 'Activity')]),
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

String _dateHeader(String iso) {
  final d = DateTime.tryParse(iso);
  return d == null ? iso : DateFormat('EEE, d MMM').format(d);
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
    final me = group.myMemberId;

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
        (date: e.date, tile: _ExpenseTile(expense: e, group: group, payerName: names[e.paidBy] ?? '?', myMemberId: me)),
      for (final p in payments)
        (date: p.date, tile: _PaymentTile(payment: p, from: names[p.fromMember] ?? '?', to: names[p.toMember] ?? '?')),
    ]..sort((a, b) => b.date.compareTo(a.date));
    final items = <Widget>[];
    String? lastDate;
    for (final r in rows) {
      if (r.date != lastDate) {
        lastDate = r.date;
        items.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(_dateHeader(r.date),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        ));
      }
      items.add(r.tile);
    }
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(padding: const EdgeInsets.only(bottom: 88), children: items),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final GroupRow group;
  final String payerName;
  final String? myMemberId;
  const _ExpenseTile({required this.expense, required this.group, required this.payerName, required this.myMemberId});

  @override
  Widget build(BuildContext context) {
    final e = expense;
    final cs = Theme.of(context).colorScheme;
    final d = group.defaultCurrency;
    final foreign = e.currency != d;
    final rate = e.fxRateToDefault ?? 0;
    final fxMissing = foreign && !(rate > 0); // null or 0: not converted
    // "≈ €69.55" under a converted foreign amount (hidden while convertAmount is a stub).
    final approx = !foreign || fxMissing || !fxReady
        ? null
        : tryFx(() => convertAmount(
            amount: e.amount, fromDecimals: Money.digits(e.currency), toDecimals: Money.digits(d), rate: rate));

    int mineIn(List<Share> l) => l.where((s) => s.memberId == myMemberId).fold(0, (a, s) => a + s.amount);
    final myShare = mineIn(e.shares);
    final myPaid = mineIn(e.payers);
    final payer = '$payerName${e.payers.length > 1 ? ' +${e.payers.length - 1}' : ''}';
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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(e.description, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${e.refund ? 'refund to' : 'paid by'} $payer · $mine', style: TextStyle(color: mineColor)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
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
      ),
      onTap: () => context.push('/groups/${group.id}/expenses/${e.id}'),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Payment payment;
  final String from, to;
  const _PaymentTile({required this.payment, required this.from, required this.to});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(Icons.payments_outlined, color: cs.onSurfaceVariant),
      title: Text('$from paid $to', maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: payment.pending
          ? Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: cs.tertiaryContainer, borderRadius: BorderRadius.circular(4)),
                child: Text('pending', style: text.labelSmall?.copyWith(color: cs.onTertiaryContainer)),
              ),
            )
          : null,
      trailing: Text(formatMoney(payment.amount, payment.currency), style: text.titleMedium),
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
    if (!async.hasValue) return const Center(child: CircularProgressIndicator());
    final res = async.value;
    if (res == null) {
      return list([const ListTile(leading: Icon(Icons.construction), title: Text(notImplementedLabel))]);
    }
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
      if (res.unsupported > 0)
        Card(
          color: cs.tertiaryContainer,
          child: ListTile(
            leading: Icon(Icons.construction, color: cs.onTertiaryContainer),
            title: Text(
                '${res.unsupported} expense${res.unsupported == 1 ? '' : 's'} with several payers or refunds '
                "${res.unsupported == 1 ? "isn't" : "aren't"} counted yet",
                style: TextStyle(color: cs.onTertiaryContainer)),
            subtitle: Text(notImplementedLabel, style: TextStyle(color: cs.onTertiaryContainer)),
          ),
        ),
      if (!unsettled)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(children: [
            Icon(
                res.unsupported > 0
                    ? Icons.hourglass_empty
                    : others.isNotEmpty
                        ? Icons.currency_exchange
                        : Icons.check_circle_outline,
                size: 64,
                color: res.unsupported > 0 ? cs.onSurfaceVariant : cs.primary),
            const SizedBox(height: 16),
            // Never "All settled" next to the cards above or the sections below.
            Text(
                res.unsupported > 0
                    ? 'Balances are incomplete'
                    : others.isNotEmpty
                        ? 'Nothing owed in $d'
                        : 'All settled',
                style: text.titleMedium),
            Text(
                res.unsupported > 0
                    ? 'Nothing to settle among the expenses counted so far.'
                    : others.isNotEmpty
                        ? 'Expenses in other currencies are below.'
                        : 'Nobody owes anything.',
                style: TextStyle(color: cs.onSurfaceVariant)),
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
    final rated = n - unrated; // has a rate that can't be used yet
    final ready = fxReady;
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
            if (rated > 0)
              ready
                  ? "${count(rated)} with a rate that can't be converted"
                  : '${count(rated)} with a rate, counted in $d once conversion is ready',
            if (n == 0) 'Payments in $currency',
            if (rows.isEmpty) 'everyone is even in $currency',
          ].join(' · '),
          style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        for (final m in rows) _BalanceRow(name: _name(m), amount: b[m.id] ?? 0, maxAbs: maxAbs, currency: currency),
        const SizedBox(height: 8),
        if (!ready && n > 0)
          // Not a button: there is nothing to tap yet.
          Row(children: [
            Icon(Icons.info_outline, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Converting to $d: $notImplementedLabel',
                  style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ),
          ])
        else if (ready && unrated > 0)
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
        Row(children: [
          Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(width: 8),
          Text(formatMoney(amount.abs(), currency),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
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
