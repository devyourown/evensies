import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/core_guard.dart';
import '../../core/money.dart';
import '../../core/offline_banner.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../group_detail/balances.dart';
import 'create_group_dialog.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider).value ?? const <GroupRow>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          IconButton(
              tooltip: 'Activity', onPressed: () => context.push('/activity'), icon: const Icon(Icons.history)),
          IconButton(
              tooltip: 'Join with a code',
              onPressed: () => context.push('/join-code'),
              icon: const Icon(Icons.group_add_outlined)),
          IconButton(
              tooltip: 'Settings',
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      body: Column(children: [
        const OfflineBanner(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(syncProvider).syncAll(),
            child: groups.isEmpty
                ? ListView(children: [
                    _Empty(onCreate: () => showCreateGroupDialog(context), onJoin: () => context.push('/join-code'))
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                    itemCount: groups.length,
                    itemBuilder: (_, i) => _GroupCard(group: groups[i]),
                  ),
          ),
        ),
      ]),
      floatingActionButton: groups.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showCreateGroupDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('New group'),
            ),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  const _Empty({required this.onCreate, required this.onJoin});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.group_outlined, size: 72, color: cs.primary),
          const SizedBox(height: 16),
          Text('No groups yet', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Create one for a trip or a flat, or join a friend\'s group with their invite code.',
              textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 32),
          FilledButton(onPressed: onCreate, child: const Text('Create group')),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onJoin, child: const Text('Join with a code')),
        ],
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  final GroupRow group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final res = ref.watch(balancesProvider(group.id)).value;
    final memberCount =
        (ref.watch(membersProvider(group.id)).value ?? const <MemberRow>[]).where((m) => !m.removed).length;
    String status;
    Color color = cs.onSurfaceVariant;
    if (res == null) {
      status = '…';
    } else if (res.balances == null) {
      status = notImplementedLabel;
    } else {
      final mine = res.balances![group.myMemberId] ?? 0;
      final cur = group.defaultCurrency;
      if (mine == 0) {
        status = 'Settled up';
      } else if (mine > 0) {
        status = 'You are owed ${formatMoney(mine, cur)}';
        color = cs.primary;
      } else {
        status = 'You owe ${formatMoney(-mine, cur)}';
        color = cs.error;
      }
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(child: Text(group.name.isEmpty ? '?' : group.name[0].toUpperCase())),
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text.rich(
          TextSpan(children: [
            TextSpan(text: '$memberCount ${memberCount == 1 ? 'member' : 'members'} · '),
            TextSpan(text: status, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/groups/${group.id}'),
      ),
    );
  }
}
