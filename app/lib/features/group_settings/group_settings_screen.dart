import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/confirm.dart';
import '../../core/currency_picker.dart';
import '../../core/offline_banner.dart';
import '../../core/snack.dart';
import '../../core/text_limits.dart';
import '../../data/db/database.dart';
import '../../data/sync/group_state_store.dart';
import '../../domain/models.dart';
import '../../domain/recurrence.dart' show Series;
import '../../domain/split.dart';
import '../../providers.dart';
import '../expense_form/split_editor.dart';
import '../group_detail/balances.dart';

/// Group settings (route `/groups/:id/settings`): name, default currency, simplify debts, default split, leave.
/// Any member may change them (no admins); changes travel as `group.updated` (docs/API.md rules 11–12).
class GroupSettingsScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupSettingsScreen({super.key, required this.groupId});
  @override
  ConsumerState<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  bool _leaving = false;

  String get _id => widget.groupId;

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupProvider(_id)).value;
    final state = ref.watch(groupStateProvider(_id)).value;
    final res = ref.watch(balancesProvider(_id));
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
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
            title: const Text('Name'),
            subtitle: Text(group.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _rename(group),
          ),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Default currency'),
            subtitle: locked
                ? const Text("Can't change after the first expense or payment")
                : const Text('Balances and payments use it'),
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
          header('Splitting'),
          SwitchListTile(
            key: const Key('simplify'),
            secondary: const Icon(Icons.auto_fix_high_outlined),
            title: const Text('Simplify debts'),
            subtitle: const Text(
              "Combines debts so the group needs fewer payments. Nobody's total changes, only who "
              'pays whom.',
            ),
            isThreeLine: true,
            value: group.simplifyDebts,
            onChanged: (v) => ref.read(localWritesProvider).updateGroup(_id, simplifyDebts: v),
          ),
          ListTile(
            key: const Key('default-split'),
            leading: const Icon(Icons.pie_chart_outline),
            title: const Text('Default split'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(describeSplit(split, state)),
                if (split != null && splitFits(split, [for (final m in state.members) if (!m.removed) m.id]) == false)
                  Text('No longer adds up · tap to fix', key: const Key('split-stale'), style: TextStyle(color: cs.error)),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _editDefaultSplit(group, state, split),
          ),
          header('Membership'),
          ListTile(
            key: const Key('leave'),
            leading: Icon(Icons.logout, color: canLeave ? cs.error : null),
            title: Text('Leave group', style: TextStyle(color: canLeave ? cs.error : null)),
            subtitle: leaveNote == null ? null : Text(leaveNote),
            enabled: canLeave && !_leaving,
            trailing: _leaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : null,
            onTap: () => _leave(group),
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Group settings')),
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
    final why = leaveBlocker(value, group.myMemberId) ?? state.seriesBlocker(group.myMemberId);
    return (why == null, why ?? 'Your balance is settled');
  }

  Future<void> _rename(GroupRow group) async {
    final ctl = TextEditingController(text: group.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          final ok = fitsLimit(ctl.text, maxGroupName); // the server refuses longer names (docs/API.md 글자 수)
          return AlertDialog(
            title: const Text('Rename group'),
            content: TextField(
              key: const Key('name'),
              controller: ctl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: limitedDecoration(const InputDecoration(labelText: 'Group name'), ctl.text, maxGroupName),
              onChanged: (_) => setDialog(() {}),
              onSubmitted: (v) {
                if (ok) Navigator.pop(ctx, v.trim());
              },
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                key: const Key('save-name'),
                onPressed: ok ? () => Navigator.pop(ctx, ctl.text.trim()) : null,
                child: const Text('Save'),
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
    final ok = await confirm(
      context,
      title: 'Leave “${group.name}”?',
      message:
          "You won't see this group any more. Your past expenses stay with the other members. "
          'To come back, ask for the invite code.',
      confirmLabel: 'Leave',
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _leaving = true);
    try {
      await ref.read(localWritesProvider).leaveGroup(_id);
      router.go('/');
      messenger.showSnackBar(SnackBar(content: Text('You left “${group.name}”')));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }
}

/// "Equal", "Percent · Anna 60%, Ben 40%", "Shares · Anna 2, Ben 1": members in group order, people with 0 and
/// people who left are not named.
String describeSplit(SplitSpec? s, GroupState state) {
  if (s == null || s.mode == SplitMode.equal) return 'Equal · everyone';
  final input = s.input ?? const <String, double>{};
  final parts = [
    for (final m in state.members)
      if (!m.removed && (input[m.id] ?? 0) != 0)
        '${m.name} ${trimNum(input[m.id]!)}${s.mode == SplitMode.percent ? '%' : ''}',
  ];
  return '${s.mode == SplitMode.percent ? 'Percent' : 'Shares'} · ${parts.join(', ')}';
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
              Text('Default split', style: text.titleLarge),
              const SizedBox(height: 4),
              Text(
                'New expenses start with this split. You can still change it on each expense.',
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
                    child: const Text('Use equal'),
                  ),
                  const Spacer(),
                  FilledButton(
                    key: const Key('save-split'),
                    onPressed: ok ? () => Navigator.pop(context, _ctl.spec(ids, widget.currency)) : null,
                    child: const Text('Save'),
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
