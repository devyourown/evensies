import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/core_guard.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import 'balances.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider(groupId)).value;
    if (group == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final offline = ref.watch(offlineProvider);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(group.name),
          actions: [
            if (offline) const Padding(padding: EdgeInsets.only(right: 8), child: Chip(label: Text('offline'))),
            IconButton(onPressed: () => context.push('/groups/$groupId/members'), icon: const Icon(Icons.people)),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'Expenses'), Tab(text: 'Balances')]),
        ),
        body: TabBarView(children: [_ExpensesTab(group: group), _BalancesTab(group: group)]),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/groups/$groupId/expenses/new'),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  final GroupRow group;
  const _ExpensesTab({required this.group});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expensesProvider(group.id)).value ?? const <ExpenseRow>[];
    final members = {for (final m in ref.watch(membersProvider(group.id)).value ?? const <MemberRow>[]) m.id: m.name};
    if (expenses.isEmpty) return const Center(child: Text('No expenses yet. Tap + to add one.'));
    return RefreshIndicator(
      onRefresh: () => ref.read(syncProvider).sync(group.id).catchError((_) {}),
      child: ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (_, i) {
          final e = expenses[i];
          return ListTile(
            title: Text(e.description),
            subtitle: Text('${e.date} · paid by ${members[e.paidBy] ?? '?'}'),
            trailing: Text(formatMoney(e.amount, e.currency)),
            onTap: () => context.push('/groups/${group.id}/expenses/${e.id}'),
          );
        },
      ),
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
    if (res == null) return const Center(child: CircularProgressIndicator());
    final b = res.balances;
    return ListView(
      children: [
        if (res.missingFx > 0)
          ListTile(leading: const Icon(Icons.warning_amber), title: Text('${res.missingFx} expense(s) need an fx rate')),
        if (b == null)
          const ListTile(leading: Icon(Icons.construction), title: Text(notImplementedLabel))
        else ...[
          for (final m in members)
            ListTile(
              title: Text(m.name + (m.removed ? ' (removed)' : '')),
              trailing: Text(
                formatMoney(b[m.id] ?? 0, group.defaultCurrency),
                style: TextStyle(color: (b[m.id] ?? 0) < 0 ? Colors.red : Colors.green),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: () => context.push('/groups/${group.id}/settle'),
              child: const Text('Settle up'),
            ),
          ),
        ],
      ],
    );
  }
}
