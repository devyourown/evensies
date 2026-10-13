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
import '../../data/api/dto.dart';
import '../../data/db/database.dart';
import '../../data/sync/group_state_store.dart';
import '../../domain/recurrence.dart';
import '../../providers.dart';
import '../auth/auth_service.dart' show infoProvider;
import '../auth/email_code_form.dart' show emailValid, normalizeEmail;

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
    final email = ref.watch(infoProvider).emailLogin;
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
              key: Key('member-${m.id}'),
              contentPadding: EdgeInsets.zero,
              leading: PersonAvatar(userId: m.userId, name: m.name),
              title: Text(m.id == group?.myMemberId ? l.youSuffix(m.name) : m.name),
              subtitle: Text(
                m.userId == null ? l.notJoinedYet : l.linked,
                style: TextStyle(color: m.userId == null ? cs.onSurfaceVariant : cs.primary),
              ),
              trailing: m.id == group?.myMemberId
                  ? null
                  // A placeholder can get an email invite (Phase 10, when this server sends email).
                  : email && m.userId == null
                      ? PopupMenuButton<String>(
                          key: Key('member-menu-${m.id}'),
                          tooltip: l.more,
                          onSelected: (v) => v == 'invite' ? _invite(m) : _remove(m),
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'invite', child: Text(l.inviteByEmail)),
                            PopupMenuItem(value: 'remove', child: Text(l.remove)),
                          ],
                        )
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
    // A removed member is still a member: repeats keep their share until the latest one is edited (docs/API.md, Recurring expenses).
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

  /// A placeholder, optionally invited by email (Phase 10, when this server sends email): added locally first, then
  /// synced so the server knows the member, then invited. Offline, the member stays and the invite waits for the
  /// member list.
  Future<void> _addMember() async {
    final ctl = TextEditingController(), emailCtl = TextEditingController();
    final withEmail = ref.read(infoProvider).emailLogin;
    final picked = await showDialog<({String name, String? email})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          final typed = emailCtl.text.trim();
          final ok = ctl.text.trim().isNotEmpty && fitsLimit(ctl.text, maxMemberName) && (typed.isEmpty || emailValid(typed));
          void done() => Navigator.pop(ctx, (name: ctl.text.trim(), email: typed.isEmpty ? null : normalizeEmail(typed)));
          return AlertDialog(
            title: Text(ctx.l.addMember),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                key: const Key('member-name'),
                controller: ctl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: limitedDecoration(ctx, InputDecoration(labelText: ctx.l.nameLabel), ctl.text, maxMemberName),
                onChanged: (_) => setDialog(() {}),
                onSubmitted: (_) {
                  if (ok) done();
                },
              ),
              if (withEmail)
                TextField(
                  key: const Key('member-email'),
                  controller: emailCtl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: ctx.l.inviteEmailField,
                    helperText: ctx.l.inviteEmailHelp,
                    helperMaxLines: 3,
                    errorText: typed.isNotEmpty && !emailValid(typed) ? ctx.l.emailInvalid : null,
                  ),
                  onChanged: (_) => setDialog(() {}),
                  onSubmitted: (_) {
                    if (ok) done();
                  },
                ),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l.cancel)),
              FilledButton(key: const Key('add-member'), onPressed: ok ? done : null, child: Text(ctx.l.add)),
            ],
          );
        },
      ),
    );
    if (picked == null || picked.name.isEmpty) return;
    final id = await ref.read(localWritesProvider).addMember(widget.groupId, picked.name);
    if (picked.email != null) await _sendInvite(id, picked.email!, added: true);
  }

  /// Invite by email… on a placeholder's row.
  Future<void> _invite(MemberRow m) async {
    final ctl = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          final typed = ctl.text.trim();
          final ok = emailValid(typed);
          return AlertDialog(
            title: Text(ctx.l.inviteByEmailTitle(m.name)),
            content: TextField(
              key: const Key('invite-email'),
              controller: ctl,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: ctx.l.emailLabel,
                helperText: ctx.l.inviteEmailHelp,
                helperMaxLines: 3,
                errorText: typed.isNotEmpty && !ok ? ctx.l.emailInvalid : null,
              ),
              onChanged: (_) => setDialog(() {}),
              onSubmitted: (_) {
                if (ok) Navigator.pop(ctx, normalizeEmail(typed));
              },
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l.cancel)),
              FilledButton(
                key: const Key('send-invite'),
                onPressed: ok ? () => Navigator.pop(ctx, normalizeEmail(typed)) : null,
                child: Text(ctx.l.send),
              ),
            ],
          );
        },
      ),
    );
    if (email != null) await _sendInvite(m.id, email);
  }

  /// Syncs first (the server must know the member), then `POST …/invite-email`. [added]: the member was just added
  /// here, so an offline failure says it was kept.
  Future<void> _sendInvite(String memberId, String email, {bool added = false}) async {
    final l = context.l;
    try {
      await ref.read(syncProvider).sync(widget.groupId);
      await ref.read(apiProvider).inviteByEmail(widget.groupId, memberId, email);
      if (mounted) showInfo(context, l.inviteEmailSent(email));
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(
          context,
          switch (e) {
            ApiException(code: 'NETWORK') => added ? l.inviteEmailOfflineAdded : l.inviteEmailOffline,
            ApiException(status: 429) => l.inviteEmailLimit,
            _ => e,
          });
    } catch (_) {
      // The sync failed without an answer (offline).
      if (mounted) showError(context, added ? l.inviteEmailOfflineAdded : l.inviteEmailOffline);
    }
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
