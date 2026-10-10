import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/confirm.dart';
import '../../core/env.dart';
import '../../core/snack.dart';
import '../../data/db/database.dart';
import '../../providers.dart';

class MembersScreen extends ConsumerStatefulWidget {
  final String groupId;
  const MembersScreen({super.key, required this.groupId});
  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  bool _rotating = false;

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupProvider(widget.groupId)).value;
    final members = (ref.watch(membersProvider(widget.groupId)).value ?? const <MemberRow>[]).where((m) => !m.removed);
    final link = group?.inviteCode == null ? null : '${ref.watch(serverUrlProvider)}/j/${group!.inviteCode}';
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Members & invite')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (link != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.link, color: cs.primary),
                    const SizedBox(width: 8),
                    Text('Invite link', style: text.titleMedium),
                  ]),
                  const SizedBox(height: 4),
                  Text('Anyone with this link can join and pick their name.',
                      style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  SelectableText(link, style: text.bodyMedium?.copyWith(fontFamily: 'monospace')),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: link));
                          if (context.mounted) showInfo(context, 'Link copied');
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => SharePlus.instance.share(ShareParams(text: 'Join my Evensies group: $link')),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share'),
                      ),
                    ),
                  ]),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _rotating ? null : _rotate,
                      icon: _rotating
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh, size: 18),
                      label: const Text('Rotate code'),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('Members', style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
          ),
          for (final m in members)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: m.userId == null ? cs.surfaceContainerHighest : cs.primaryContainer,
                child: Icon(m.userId == null ? Icons.person_outline : Icons.person,
                    color: m.userId == null ? cs.onSurfaceVariant : cs.onPrimaryContainer),
              ),
              title: Text(m.id == group?.myMemberId ? '${m.name} (you)' : m.name),
              subtitle: Text(
                m.userId == null ? 'not joined yet — share the invite link' : 'linked',
                style: TextStyle(color: m.userId == null ? cs.onSurfaceVariant : cs.primary),
              ),
              trailing: m.id == group?.myMemberId
                  ? null
                  : IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.person_remove_outlined),
                      onPressed: () => _remove(m),
                    ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addMember,
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Add placeholder member'),
          ),
        ],
      ),
    );
  }

  Future<void> _remove(MemberRow m) async {
    final ok = await confirm(context,
        title: 'Remove ${m.name}?',
        message: 'Their past expenses and balance stay in the group.',
        confirmLabel: 'Remove');
    if (!ok) return;
    await ref.read(localWritesProvider).removeMember(widget.groupId, m.id);
  }

  Future<void> _addMember() async {
    final ctl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add member'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctl.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(localWritesProvider).addMember(widget.groupId, name);
  }

  Future<void> _rotate() async {
    final ok = await confirm(context,
        title: 'Rotate invite code?',
        message: 'The current link stops working. People who already joined are not affected.',
        confirmLabel: 'Rotate',
        destructive: false);
    if (!ok) return;
    setState(() => _rotating = true);
    try {
      final code = await ref.read(apiProvider).rotateInvite(widget.groupId);
      final db = ref.read(dbProvider);
      final g = await db.getGroup(widget.groupId);
      if (g != null) await db.upsertGroup(g.copyWith(inviteCode: Value(code)));
      if (mounted) showInfo(context, 'New invite link ready');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _rotating = false);
    }
  }
}
