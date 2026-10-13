import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cover.dart';
import '../../core/l10n.dart';
import '../../core/snack.dart';
import '../../data/db/database.dart';
import '../../providers.dart';

/// Settings → Deleted groups (route `/settings/deleted`, docs/API.md, Group types, covers and deletion): groups and deleted friends (their
/// non-group expenses) that any member can bring back with everything in them. Offline too.
class DeletedGroupsScreen extends ConsumerWidget {
  const DeletedGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(deletedGroupsProvider).value;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l;
    final Widget body;
    if (rows == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (rows.isEmpty) {
      body = ListView(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
          child: Column(children: [
            Icon(Icons.restore_from_trash_outlined, size: 64, color: cs.primary),
            const SizedBox(height: 16),
            Text(l.deletedGroupsEmpty, style: text.titleMedium, textAlign: TextAlign.center),
          ]),
        ),
      ]);
    } else {
      body = ListView(padding: const EdgeInsets.only(bottom: 32), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(keepAll(l.deletedGroupsHelp, l.localeName),
              style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ),
        for (final g in rows) _DeletedRow(group: g),
      ]);
    }
    return Scaffold(appBar: AppBar(title: Text(l.deletedGroups)), body: body);
  }
}

class _DeletedRow extends ConsumerWidget {
  final GroupRow group;
  const _DeletedRow({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    final friend = group.kind == 'friend';
    // A friend group is named by the other person (the Friends tab no longer has them).
    final other = friend
        ? (ref.watch(membersProvider(group.id)).value ?? const <MemberRow>[])
            .where((m) => m.id != group.myMemberId)
            .firstOrNull
            ?.name
        : null;
    final name = friend ? l.nonGroupWith(other ?? group.name) : group.name;
    return ListTile(
      key: Key('deleted-${group.id}'),
      leading: friend
          ? const CircleAvatar(child: Icon(Icons.person_outline))
          : GroupCover(groupId: group.id, type: group.type, coverImageId: group.coverImageId, size: 40),
      title: Text(name),
      trailing: FilledButton.tonal(
        onPressed: () async {
          await ref.read(localWritesProvider).restoreGroup(group.id);
          if (context.mounted) showInfo(context, l.restoredName(name));
        },
        child: Text(l.restore),
      ),
    );
  }
}
