import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/core_guard.dart';
import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../group_detail/balances.dart';
import 'create_group_dialog.dart';
import 'paste_invite_dialog.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider).value ?? const <GroupRow>[];
    final offline = ref.watch(offlineProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        actions: [
          if (offline) const Padding(padding: EdgeInsets.only(right: 8), child: Chip(label: Text('offline'))),
          IconButton(onPressed: () => context.push('/settings'), icon: const Icon(Icons.settings)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(syncProvider).syncAll(),
        child: groups.isEmpty
            ? ListView(children: [_Empty(onCreate: () => showCreateGroupDialog(context), onPaste: () => showPasteInviteDialog(context))])
            : ListView.builder(
                itemCount: groups.length,
                itemBuilder: (_, i) => _GroupTile(group: groups[i]),
              ),
      ),
      floatingActionButton: groups.isEmpty
          ? null
          : FloatingActionButton(onPressed: () => showCreateGroupDialog(context), child: const Icon(Icons.add)),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onPaste;
  const _Empty({required this.onCreate, required this.onPaste});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.group_outlined, size: 64),
            const SizedBox(height: 16),
            const Text('No groups yet'),
            const SizedBox(height: 24),
            FilledButton(onPressed: onCreate, child: const Text('Create group')),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onPaste, child: const Text('Paste invite link')),
          ],
        ),
      );
}

class _GroupTile extends ConsumerWidget {
  final GroupRow group;
  const _GroupTile({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final res = ref.watch(balancesProvider(group.id)).value;
    Widget subtitle;
    if (res == null) {
      subtitle = const Text('…');
    } else if (res.balances == null) {
      subtitle = const Text(notImplementedLabel);
    } else {
      final mine = res.balances![group.myMemberId] ?? 0;
      final cur = group.defaultCurrency;
      subtitle = Text(mine == 0
          ? 'Settled up'
          : mine > 0
              ? 'You are owed ${formatMoney(mine, cur)}'
              : 'You owe ${formatMoney(-mine, cur)}');
    }
    return ListTile(
      title: Text(group.name),
      subtitle: subtitle,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/groups/${group.id}'),
    );
  }
}
