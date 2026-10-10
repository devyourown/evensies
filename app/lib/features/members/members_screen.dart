import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/env.dart';
import '../../core/snack.dart';
import '../../data/db/database.dart';
import '../../providers.dart';

class MembersScreen extends ConsumerWidget {
  final String groupId;
  const MembersScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider(groupId)).value;
    final members = ref.watch(membersProvider(groupId)).value ?? const <MemberRow>[];
    final link = group?.inviteCode == null ? null : '${ref.watch(serverUrlProvider)}/j/${group!.inviteCode}';
    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: ListView(
        children: [
          for (final m in members)
            ListTile(
              leading: Icon(m.userId == null ? Icons.person_outline : Icons.person),
              title: Text(m.name),
              subtitle: Text(m.removed ? 'removed' : (m.userId == null ? 'placeholder' : 'linked')),
              trailing: m.removed || m.id == group?.myMemberId
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.person_remove_outlined),
                      onPressed: () => ref.read(localWritesProvider).removeMember(groupId, m.id),
                    ),
            ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Add placeholder member'),
            onTap: () => _addMember(context, ref),
          ),
          const Divider(),
          if (link != null) ...[
            ListTile(leading: const Icon(Icons.link), title: const Text('Invite link'), subtitle: Text(link)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                FilledButton.icon(
                  onPressed: () => SharePlus.instance.share(ShareParams(text: 'Join my Tally group: $link')),
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
                const SizedBox(width: 12),
                TextButton(onPressed: () => _rotate(context, ref), child: const Text('Rotate code')),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _addMember(BuildContext context, WidgetRef ref) async {
    final ctl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add member'),
        content: TextField(controller: ctl, autofocus: true, decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctl.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(localWritesProvider).addMember(groupId, name);
  }

  Future<void> _rotate(BuildContext context, WidgetRef ref) async {
    try {
      final code = await ref.read(apiProvider).rotateInvite(groupId);
      final db = ref.read(dbProvider);
      final g = await db.getGroup(groupId);
      if (g != null) await db.upsertGroup(g.copyWith(inviteCode: Value(code)));
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}
