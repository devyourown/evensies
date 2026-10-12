import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/confirm.dart';
import '../../core/env.dart';
import '../../core/invite_code.dart';
import '../../core/person_avatar.dart';
import '../../core/snack.dart';
import '../../core/text_limits.dart';
import '../../data/db/database.dart';
import '../../data/sync/group_state_store.dart';
import '../../domain/recurrence.dart';
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
    final code = group?.inviteCode;
    final link = code == null ? null : '${ref.watch(serverUrlProvider)}/j/$code';
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('Invite code', textAlign: TextAlign.center, style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      // A QR code needs a light quiet zone, in dark mode too.
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: QrImageView(
                        key: const Key('invite-qr'),
                        data: link,
                        size: 160,
                        backgroundColor: Colors.white,
                        semanticsLabel: 'QR code of the invite link',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(formatInviteCode(code!),
                      textAlign: TextAlign.center,
                      style: text.displaySmall?.copyWith(fontFamily: 'monospace', letterSpacing: 4, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Anyone with this code can join and pick their name.',
                      textAlign: TextAlign.center, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: code));
                          if (context.mounted) showInfo(context, 'Code copied');
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy code'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => SharePlus.instance.share(ShareParams(
                            text: 'Join my group "${group!.name}" on Evensies: $link\n'
                                'Or open the app and enter code ${formatInviteCode(code)}')),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share link'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: SelectableText(link,
                          style: text.bodySmall?.copyWith(fontFamily: 'monospace', color: cs.onSurfaceVariant)),
                    ),
                    TextButton.icon(
                      onPressed: _rotating ? null : _rotate,
                      icon: _rotating
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh, size: 18),
                      label: const Text('Rotate code'),
                    ),
                  ]),
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
              leading: PersonAvatar(userId: m.userId, name: m.name),
              title: Text(m.id == group?.myMemberId ? '${m.name} (you)' : m.name),
              subtitle: Text(
                m.userId == null ? 'not joined yet — share the invite code' : 'linked',
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
    // A removed member is still a member: repeats keep their share until the latest one is edited (docs/API.md 반복 지출).
    final series = (await GroupStateStore(ref.read(dbProvider)).load(widget.groupId)).seriesWith(m.id);
    final names = seriesNames(series);
    if (!mounted) return;
    final ok = await confirm(context,
        title: 'Remove ${m.name}?',
        message: 'Their past expenses and balance stay in the group.'
            '${series.isEmpty ? '' : '\n\n${m.name} is still in ${series.length} repeating '
                '${series.length == 1 ? 'expense' : 'expenses'} ($names); they keep ${m.name}\'s share until you edit '
                'the latest one.'}',
        confirmLabel: 'Remove');
    if (!ok) return;
    await ref.read(localWritesProvider).removeMember(widget.groupId, m.id);
  }

  Future<void> _addMember() async {
    final ctl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          final ok = ctl.text.trim().isNotEmpty && fitsLimit(ctl.text, maxMemberName);
          return AlertDialog(
            title: const Text('Add member'),
            content: TextField(
              key: const Key('member-name'),
              controller: ctl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: limitedDecoration(const InputDecoration(labelText: 'Name'), ctl.text, maxMemberName),
              onChanged: (_) => setDialog(() {}),
              onSubmitted: (v) {
                if (ok) Navigator.pop(ctx, v.trim());
              },
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(onPressed: ok ? () => Navigator.pop(ctx, ctl.text.trim()) : null, child: const Text('Add')),
            ],
          );
        },
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(localWritesProvider).addMember(widget.groupId, name);
  }

  Future<void> _rotate() async {
    final ok = await confirm(context,
        title: 'Rotate invite code?',
        message: 'The current code and link stop working. People who already joined are not affected.',
        confirmLabel: 'Rotate',
        destructive: false);
    if (!ok) return;
    setState(() => _rotating = true);
    try {
      final code = await ref.read(apiProvider).rotateInvite(widget.groupId);
      final db = ref.read(dbProvider);
      final g = await db.getGroup(widget.groupId);
      if (g != null) await db.upsertGroup(g.copyWith(inviteCode: Value(code)));
      if (mounted) showInfo(context, 'New invite code ready');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _rotating = false);
    }
  }
}
