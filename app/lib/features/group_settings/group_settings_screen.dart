import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;

import '../../core/money.dart';
import 'package:go_router/go_router.dart';

import '../../core/confirm.dart';
import '../../core/cover.dart';
import '../../core/currency_picker.dart';
import '../../core/l10n.dart';
import '../../core/offline_banner.dart';
import '../../core/snack.dart';
import '../../core/text_limits.dart';
import '../../data/api/dto.dart';
import '../../data/blob_store.dart';
import '../../data/db/database.dart';
import '../../data/images.dart';
import '../../data/receipts.dart' show receiptFilesProvider;
import '../../data/sync/group_state_store.dart';
import '../../domain/models.dart';
import '../../domain/recurrence.dart' show Series;
import '../../domain/split.dart';
import '../../providers.dart';
import '../expense_form/split_editor.dart';
import '../group_detail/balances.dart';

/// Group settings (route `/groups/:id/settings`): name, cover and type (Phase 10), default currency, simplify debts,
/// default split, leave, delete.
/// Any member may change them (no admins); changes travel as `group.updated` (docs/API.md rules 11–12).
class GroupSettingsScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupSettingsScreen({super.key, required this.groupId});
  @override
  ConsumerState<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  bool _leaving = false;
  bool _savingCover = false;

  String get _id => widget.groupId;

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupProvider(_id)).value;
    final state = ref.watch(groupStateProvider(_id)).value;
    final res = ref.watch(balancesProvider(_id));
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l;
    Widget header(String s) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(s, style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
    );
    final Widget body;
    if (group == null || state == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      // Every fx rate and payment amount is in the group currency (rule 12): deleted ones count, they can come back.
      final locked = state.expenses.isNotEmpty || state.payments.isNotEmpty;
      final split = splitFromJson(group.defaultSplitJson);
      final (canLeave, leaveNote) = _leaveState(group, res, state);
      body = ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          ListTile(
            key: const Key('rename'),
            leading: const Icon(Icons.edit_outlined),
            title: Text(l.nameField),
            subtitle: Text(group.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _rename(group),
          ),
          ListTile(
            key: const Key('cover'),
            leading: _savingCover
                ? const SizedBox(width: 48, height: 48, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                : GroupCover(groupId: _id, type: group.type, coverImageId: group.coverImageId, size: 48),
            title: Text(l.coverPhoto),
            subtitle: Text(l.coverPhotoHint),
            trailing: const Icon(Icons.chevron_right),
            enabled: !_savingCover,
            onTap: () => _cover(group),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: GroupTypeChips(
              value: group.type,
              onChanged: (t) {
                if (t != shownGroupType(group.type)) ref.read(localWritesProvider).updateGroup(_id, type: t);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: Text(l.defaultCurrency),
            subtitle: Text(locked ? l.cantChangeCurrency : l.currencyUsedFor),
            enabled: !locked,
            trailing: CurrencyPicker(
              key: const Key('currency'),
              value: group.defaultCurrency,
              width: 124,
              bare: true,
              pinned: [ref.watch(homeCurrencyProvider)],
              textStyle: text.titleMedium?.copyWith(color: locked ? cs.onSurfaceVariant : cs.onSurface),
              onChanged: locked ? null : (v) => ref.read(localWritesProvider).updateGroup(_id, defaultCurrency: v),
            ),
          ),
          header(l.splitting),
          SwitchListTile(
            key: const Key('simplify'),
            secondary: const Icon(Icons.auto_fix_high_outlined),
            title: Text(l.simplifyDebts),
            subtitle: Text(l.simplifyDebtsHelp),
            isThreeLine: true,
            value: group.simplifyDebts,
            onChanged: (v) => ref.read(localWritesProvider).updateGroup(_id, simplifyDebts: v),
          ),
          ListTile(
            key: const Key('default-split'),
            leading: const Icon(Icons.pie_chart_outline),
            title: Text(l.defaultSplit),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(describeSplit(l, split, state)),
                if (split != null && splitFits(split, [for (final m in state.members) if (!m.removed) m.id]) == false)
                  Text(l.splitStale, key: const Key('split-stale'), style: TextStyle(color: cs.error)),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editDefaultSplit(group, state, split),
          ),
          header(l.membership),
          ListTile(
            key: const Key('leave'),
            leading: Icon(Icons.logout, color: canLeave ? cs.error : null),
            title: Text(l.leaveGroup, style: TextStyle(color: canLeave ? cs.error : null)),
            subtitle: leaveNote == null ? null : Text(leaveNote),
            enabled: canLeave && !_leaving,
            trailing: _leaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : null,
            onTap: () => _leave(group),
          ),
          ListTile(
            key: const Key('delete-group'),
            leading: Icon(Icons.delete_outline, color: cs.error),
            title: Text(l.deleteGroup, style: TextStyle(color: cs.error)),
            subtitle: Text(l.deleteGroupHint),
            onTap: () => _delete(group),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.groupSettings)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: body),
        ],
      ),
    );
  }

  /// Leaving needs a zero balance in every currency and no live repeating expense with me in it (leaveGroup checks
  /// again after its sync).
  (bool, String?) _leaveState(GroupRow group, AsyncValue<BalanceResult> res, GroupState state) {
    final value = res.value;
    if (value == null) return (false, null);
    final l = context.l;
    final why = leaveBlocker(l, value, group.myMemberId) ?? state.seriesBlocker(l, group.myMemberId);
    return (why == null, why ?? l.balanceSettledNote);
  }

  /// Change cover (a photo prepared like the others: long edge 1600, EXIF dropped; uploaded, online only) or Remove
  /// cover (an event, offline too). The server pushes the new cover's `group.updated`; the sync brings it back.
  Future<void> _cover(GroupRow group) async {
    final l = context.l;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!kIsWeb)
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(ctx.l.photoTake),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
          ListTile(
            key: const Key('cover-choose'),
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(kIsWeb ? ctx.l.photoChooseFile : ctx.l.photoChoose),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          if (group.coverImageId != null)
            ListTile(
              key: const Key('cover-remove'),
              leading: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
              title: Text(ctx.l.removeCover, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (choice == null || !mounted) return;
    final store = ref.read(receiptFilesProvider).store;
    if (choice == 'remove') {
      await ref.read(localWritesProvider).updateGroup(_id, removeCover: true);
      await dropCover(store, group.coverImageId);
      return;
    }
    // Known offline: say so now, not after a photo was picked for nothing.
    if (ref.read(offlineProvider)) return showError(context, l.coverNeedsConnection);
    final source = choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
    try {
      final bytes = await ref.read(pickPhotoProvider)(source, maxEdge: 1600, quality: 82);
      if (bytes == null || !mounted) return;
      setState(() => _savingCover = true);
      final r = await ref.read(apiProvider).putCover(_id, bytes);
      // The bytes are the cover now: no download, and the old one's file goes.
      await store.write(BlobArea.cache, coverFileName(r.coverImageId), bytes).catchError((_) {});
      final db = ref.read(dbProvider);
      await (db.update(db.groups)..where((g) => g.id.equals(_id)))
          .write(GroupsCompanion(coverImageId: Value(r.coverImageId)));
      await dropCover(store, group.coverImageId);
      ref.read(syncProvider).syncLater(_id);
    } on ApiException catch (e) {
      if (mounted) {
        showError(
            context,
            switch (e) {
              ApiException(code: 'NETWORK') => l.coverNeedsConnection,
              ApiException(status: 429) => l.coverTooMany,
              ApiException(code: 'NOT_JPEG' || 'IMAGE_TOO_LARGE' || 'TOO_LARGE') => l.photoUnusable,
              _ => e,
            });
      }
    } catch (e) {
      if (mounted) showError(context, photoErrorText(l, e, source));
    } finally {
      if (mounted) setState(() => _savingCover = false);
    }
  }

  /// Deleted for everyone, offline too; Undo for 10 s, then Settings → Deleted groups or the activity row.
  Future<void> _delete(GroupRow group) async {
    final l = context.l;
    final ok = await confirm(context,
        title: l.deleteGroupTitle(group.name), message: l.deleteGroupMessage, confirmLabel: l.delete);
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final writes = ref.read(localWritesProvider);
    await writes.deleteGroup(_id);
    router.go('/');
    showUndo(messenger, l.groupDeletedName(group.name), () => writes.restoreGroup(_id));
  }

  Future<void> _rename(GroupRow group) async {
    final ctl = TextEditingController(text: group.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          final ok = fitsLimit(ctl.text, maxGroupName); // the server refuses longer names (docs/API.md 글자 수)
          return AlertDialog(
            title: Text(ctx.l.renameGroup),
            content: TextField(
              key: const Key('name'),
              controller: ctl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: limitedDecoration(ctx, InputDecoration(labelText: ctx.l.groupName), ctl.text, maxGroupName),
              onChanged: (_) => setDialog(() {}),
              onSubmitted: (v) {
                if (ok) Navigator.pop(ctx, v.trim());
              },
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(ctx.l.cancel)),
              FilledButton(
                key: const Key('save-name'),
                onPressed: ok ? () => Navigator.pop(ctx, ctl.text.trim()) : null,
                child: Text(ctx.l.save),
              ),
            ],
          );
        },
      ),
    );
    if (name == null || name.isEmpty || name == group.name) return;
    await ref.read(localWritesProvider).updateGroup(_id, name: name);
  }

  Future<void> _editDefaultSplit(GroupRow group, GroupState state, SplitSpec? current) async {
    final members = (ref.read(membersProvider(_id)).value ?? const <MemberRow>[]).where((m) => !m.removed).toList();
    final picked = await showModalBottomSheet<SplitSpec>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _DefaultSplitSheet(members: members, current: current, currency: group.defaultCurrency),
    );
    if (picked == null) return;
    final w = ref.read(localWritesProvider);
    if (picked.mode == SplitMode.equal) {
      if (current != null) await w.updateGroup(_id, clearDefaultSplit: true);
    } else if (picked != current) {
      await w.updateGroup(_id, defaultSplit: picked);
    }
  }

  Future<void> _leave(GroupRow group) async {
    final l = context.l;
    final ok = await confirm(context, title: l.leaveTitle(group.name), message: l.leaveMessage, confirmLabel: l.leave);
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _leaving = true);
    try {
      await ref.read(localWritesProvider).leaveGroup(_id);
      router.go('/');
      messenger.showSnackBar(SnackBar(content: Text(l.youLeft(group.name))));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }
}

/// "Equal", "Percent · Anna 60%, Ben 40%", "Shares · Anna 2, Ben 1": members in group order, people with 0 and
/// people who left are not named.
String describeSplit(AppLocalizations l, SplitSpec? s, GroupState state) {
  if (s == null || s.mode == SplitMode.equal) return l.splitEqualEveryone;
  final input = s.input ?? const <String, double>{};
  final percent = s.mode == SplitMode.percent;
  final parts = [
    for (final m in state.members)
      if (!m.removed && (input[m.id] ?? 0) != 0)
        '${m.name} ${percent ? l.percentValue(numberText(input[m.id]!)) : numberText(input[m.id]!)}',
  ].join(l.listJoiner);
  return percent ? l.splitPercentList(parts) : l.splitSharesList(parts);
}

/// Pops a SplitSpec: percent or shares to save, or `SplitSpec(equal)` for "Use equal".
class _DefaultSplitSheet extends StatefulWidget {
  final List<MemberRow> members;
  final SplitSpec? current;
  final String currency;
  const _DefaultSplitSheet({required this.members, required this.current, required this.currency});
  @override
  State<_DefaultSplitSheet> createState() => _DefaultSplitSheetState();
}

class _DefaultSplitSheetState extends State<_DefaultSplitSheet> {
  late final _ctl = SplitEditorController(SplitMode.percent);

  @override
  void initState() {
    super.initState();
    final c = widget.current;
    if (c != null && c.mode != SplitMode.equal) _ctl.load(c, widget.currency);
    _ctl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ids = [for (final m in widget.members) m.id];
    final ok = _ctl.evaluate(amount: null, ids: ids, currency: widget.currency).ok;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.l.defaultSplit, style: text.titleLarge),
              const SizedBox(height: 4),
              Text(
                context.l.defaultSplitHelp,
                style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              SplitEditor(
                controller: _ctl,
                members: widget.members,
                amount: null,
                currency: widget.currency,
                modes: const [SplitMode.percent, SplitMode.shares],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    key: const Key('use-equal'),
                    onPressed: () => Navigator.pop(context, const SplitSpec(SplitMode.equal)),
                    child: Text(context.l.useEqual),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const Key('save-split'),
                    onPressed: ok ? () => Navigator.pop(context, _ctl.spec(ids, widget.currency)) : null,
                    child: Text(context.l.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
