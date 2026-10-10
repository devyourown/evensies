import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/core_guard.dart';
import '../../core/money.dart';
import '../../core/offline_banner.dart';
import '../../data/db/database.dart';
import '../../domain/models.dart';
import '../../providers.dart';
import 'balances.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider(groupId)).value;
    if (group == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          actions: [
            IconButton(
              tooltip: 'Members & invite',
              onPressed: () => context.push('/groups/$groupId/members'),
              icon: const Icon(Icons.people_outline),
            ),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'Expenses'), Tab(text: 'Balances')]),
        ),
        body: Column(children: [
          const OfflineBanner(),
          Expanded(child: TabBarView(children: [_ExpensesTab(group: group), _BalancesTab(group: group)])),
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
    final names = {for (final m in state.members) m.id: m.name};
    final me = group.myMemberId;

    Future<void> refresh() => ref.read(syncProvider).sync(group.id).catchError((_) {});

    if (expenses.isEmpty) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(children: [
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

    final items = <Widget>[];
    String? lastDate;
    for (final e in expenses) {
      if (e.date != lastDate) {
        lastDate = e.date;
        items.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(_dateHeader(e.date),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        ));
      }
      items.add(_ExpenseTile(expense: e, group: group, payerName: names[e.paidBy] ?? '?', myMemberId: me));
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
    final foreign = e.currency != group.defaultCurrency;
    final fxMissing = foreign && e.fxRateToDefault == null;

    final myShare = e.shares.where((s) => s.memberId == myMemberId).fold(0, (a, s) => a + s.amount);
    final paidByMe = e.paidBy == myMemberId;
    String mine;
    Color mineColor = cs.onSurfaceVariant;
    if (myMemberId == null || (!paidByMe && myShare == 0)) {
      mine = 'not involved';
    } else if (paidByMe) {
      final lent = e.amount - myShare;
      mine = lent > 0 ? 'you lent ${formatMoney(lent, e.currency)}' : 'you paid for yourself';
      if (lent > 0) mineColor = cs.primary;
    } else {
      mine = 'you borrowed ${formatMoney(myShare, e.currency)}';
      mineColor = cs.error;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(e.description, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('paid by $payerName · $mine', style: TextStyle(color: mineColor)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(formatMoney(e.amount, e.currency), style: Theme.of(context).textTheme.titleMedium),
          if (foreign)
            Row(mainAxisSize: MainAxisSize.min, children: [
              if (fxMissing) ...[
                Icon(Icons.warning_amber_rounded, size: 14, color: cs.error),
                const SizedBox(width: 2),
              ],
              Text(e.currency,
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

class _BalancesTab extends ConsumerWidget {
  final GroupRow group;
  const _BalancesTab({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final res = ref.watch(balancesProvider(group.id)).value;
    final members = ref.watch(membersProvider(group.id)).value ?? const <MemberRow>[];
    final cs = Theme.of(context).colorScheme;
    if (res == null) return const Center(child: CircularProgressIndicator());
    final b = res.balances;
    if (b == null) {
      return const Center(child: ListTile(leading: Icon(Icons.construction), title: Text(notImplementedLabel)));
    }
    final rows = members.where((m) => !m.removed || (b[m.id] ?? 0) != 0).toList()
      ..sort((x, y) => (b[y.id] ?? 0).compareTo(b[x.id] ?? 0));
    final maxAbs = rows.fold(0, (acc, m) => (b[m.id] ?? 0).abs() > acc ? (b[m.id] ?? 0).abs() : acc);
    final unsettled = maxAbs > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      children: [
        if (res.missingFx > 0)
          Card(
            color: cs.errorContainer,
            child: ListTile(
              leading: Icon(Icons.warning_amber_rounded, color: cs.onErrorContainer),
              title: Text('${res.missingFx} expense${res.missingFx == 1 ? '' : 's'} missing an fx rate',
                  style: TextStyle(color: cs.onErrorContainer)),
              subtitle: Text('Not counted in balances. Edit the expense to add a rate.',
                  style: TextStyle(color: cs.onErrorContainer)),
            ),
          ),
        if (!unsettled)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(children: [
              Icon(Icons.check_circle_outline, size: 64, color: cs.primary),
              const SizedBox(height: 16),
              Text('All settled', style: Theme.of(context).textTheme.titleMedium),
              Text('Nobody owes anything.', style: TextStyle(color: cs.onSurfaceVariant)),
            ]),
          ),
        for (final m in rows) _BalanceRow(name: m.name + (m.removed ? ' (removed)' : ''), amount: b[m.id] ?? 0, maxAbs: maxAbs, currency: group.defaultCurrency),
        if (unsettled) ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/groups/${group.id}/settle'),
            icon: const Icon(Icons.handshake_outlined),
            label: const Text('Settle up'),
          ),
        ],
      ],
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
