import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/confirm.dart';
import '../../core/env.dart';
import '../../core/invite_code.dart';
import '../../core/l10n.dart';
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
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.membersInvite)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (link != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(l.inviteCode, textAlign: TextAlign.center, style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
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
                        semanticsLabel: l.inviteQrLabel,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(formatInviteCode(code!),
                      textAlign: TextAlign.center,
                      style: text.displaySmall?.copyWith(fontFamily: 'monospace', letterSpacing: 4, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(l.inviteCodeHelp,
                      textAlign: TextAlign.center, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: code));
                          if (context.mounted) showInfo(context, context.l.codeCopied);
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: Text(l.copyCode),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => shareText(context, l.inviteShareText(group!.name, link, formatInviteCode(code))),
                        icon: const Icon(Icons.share, size: 18),
                        label: Text(l.shareLink),
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
                      label: Text(l.rotateCode),
                    ),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(l.members, style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
          ),
          for (final m in members)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: PersonAvatar(userId: m.userId, name: m.name),
              title: Text(m.id == group?.myMemberId ? l.youSuffix(m.name) : m.name),
              subtitle: Text(
                m.userId == null ? l.notJoinedYet : l.linked,
                style: TextStyle(color: m.userId == null ? cs.onSurfaceVariant : cs.primary),
              ),
              trailing: m.id == group?.myMemberId
                  ? null
                  : IconButton(
                      tooltip: l.remove,
                      icon: const Icon(Icons.person_remove_outlined),
                      onPressed: () => _remove(m),
                    ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addMember,
            icon: const Icon(Icons.person_add_outlined),
            label: Text(l.addPlaceholder),
          ),
        ],
      ),
    );
  }

  Future<void> _remove(MemberRow m) async {
    // A removed member is still a member: repeats keep their share until the latest one is edited (docs/API.md 반복 지출).
    final series = (await GroupStateStore(ref.read(dbProvider)).load(widget.groupId)).seriesWith(m.id);
    if (!mounted) return;
    final l = context.l;
    final names = seriesNames(l, series);
    final ok = await confirm(context,
        title: l.removeMemberTitle(m.name),
        message: series.isEmpty
            ? l.removeMemberMessage
            : '${l.removeMemberMessage}\n\n${l.removeMemberSeries(series.length, m.name, names)}',
        confirmLabel: l.remove);
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
            title: Text(ctx.l.addMember),
            content: TextField(
              key: const Key('member-name'),
              controller: ctl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: limitedDecoration(ctx, InputDecoration(labelText: ctx.l.nameLabel), ctl.text, maxMemberName),
              onChanged: (_) => setDialog(() {}),
              onSubmitted: (v) {
                if (ok) Navigator.pop(ctx, v.trim());
              },
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l.cancel)),
              FilledButton(onPressed: ok ? () => Navigator.pop(ctx, ctl.text.trim()) : null, child: Text(ctx.l.add)),
            ],
          );
        },
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref.read(localWritesProvider).addMember(widget.groupId, name);
  }

  Future<void> _rotate() async {
    final l = context.l;
    final ok = await confirm(context,
        title: l.rotateInviteTitle, message: l.rotateInviteMessage, confirmLabel: l.rotate, destructive: false);
    if (!ok) return;
    setState(() => _rotating = true);
    try {
      final code = await ref.read(apiProvider).rotateInvite(widget.groupId);
      final db = ref.read(dbProvider);
      final g = await db.getGroup(widget.groupId);
      if (g != null) await db.upsertGroup(g.copyWith(inviteCode: Value(code)));
      if (mounted) showInfo(context, context.l.newInviteReady);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _rotating = false);
    }
  }
}
