import 'package:drift/drift.dart' show Value;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/env.dart';
import '../../core/ids.dart';
import '../../core/money.dart';
import '../../core/snack.dart';
import '../../core/text_limits.dart';
import '../../data/api/dto.dart';
import '../../data/db/database.dart';
import '../../data/sync/group_state_store.dart';
import '../../providers.dart';

Future<void> showCreateGroupDialog(BuildContext context) =>
    showDialog(context: context, builder: (_) => const _CreateGroupDialog());

class _CreateGroupDialog extends ConsumerStatefulWidget {
  const _CreateGroupDialog();
  @override
  ConsumerState<_CreateGroupDialog> createState() => _State();
}

class _State extends ConsumerState<_CreateGroupDialog> {
  final _name = TextEditingController();
  final _me = TextEditingController();
  static const _lastCurrencyKey = 'lastCurrency';
  late String _currency;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _me.text = ref.read(sessionProvider).value?.displayName ?? '';
    final last = ref.read(sharedPreferencesProvider).getString(_lastCurrencyKey);
    _currency = last != null && Money.decimals.containsKey(last)
        ? last
        : Money.currencyForLocale(PlatformDispatcher.instance.locale.toString());
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final api = ref.read(apiProvider);
      final db = ref.read(dbProvider);
      final id = newId();
      final memberId = newId();
      final dto = await api.createGroup(
        id: id,
        name: _name.text.trim(),
        defaultCurrency: _currency,
        memberId: memberId,
        memberName: _me.text.trim(),
      );
      await db.upsertGroup(GroupRow(
        id: dto.id,
        name: dto.name,
        defaultCurrency: dto.defaultCurrency,
        inviteCode: dto.inviteCode,
        latestSeq: dto.latestSeq,
        myMemberId: dto.myMemberId,
        simplifyDebts: dto.simplifyDebts,
        defaultSplitJson: splitToJson(dto.defaultSplit),
      ));
      await db.into(db.members).insert(MembersCompanion.insert(
          id: memberId, groupId: id, name: _me.text.trim(), userId: Value(ref.read(sessionProvider).value?.userId)));
      // group.created + member.added are already reflected locally; start pulling after them.
      await db.setLastSeq(id, dto.latestSeq);
      await ref.read(sharedPreferencesProvider).setString(_lastCurrencyKey, _currency);
      if (!mounted) return;
      Navigator.pop(context);
      context.push('/groups/$id');
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(context, e.code == 'NETWORK' ? 'Creating a group needs a connection.' : e);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('New group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                key: const Key('group-name'),
                controller: _name,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: limitedDecoration(const InputDecoration(labelText: 'Group name'), _name.text, maxGroupName)),
            TextField(
                key: const Key('my-name'),
                controller: _me,
                onChanged: (_) => setState(() {}),
                decoration: limitedDecoration(
                    const InputDecoration(labelText: 'Your name in this group'), _me.text, maxMemberName)),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: const InputDecoration(labelText: 'Default currency'),
              items: [for (final c in Money.currencies) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (v) => setState(() => _currency = v ?? _currency),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: _busy ||
                    _name.text.trim().isEmpty ||
                    _me.text.trim().isEmpty ||
                    !fitsLimit(_name.text, maxGroupName) ||
                    !fitsLimit(_me.text, maxMemberName)
                ? null
                : _create,
            child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create'),
          ),
        ],
      );
}
