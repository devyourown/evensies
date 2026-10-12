import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/person_avatar.dart';
import '../../domain/overview.dart';
import 'friend_screen.dart' show addExpenseWith, canAddExpenseWith, showNoSharedGroup;
import 'home_data.dart';

/// A friend (non-group) or a group: who an expense is *With* (docs Phase 6).
typedef WithChoice = ({Person? person, String? groupId});

/// Friends (linked people and placeholder friends) and groups, with a search field. [except] leaves out the
/// expense's current group when moving.
class WithPicker extends ConsumerStatefulWidget {
  final ValueChanged<WithChoice> onPick;
  final String? except;
  const WithPicker({super.key, required this.onPick, this.except});
  @override
  ConsumerState<WithPicker> createState() => _WithPickerState();
}

class _WithPickerState extends ConsumerState<WithPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(homeDataProvider).value;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l;
    if (data == null) return const Center(child: CircularProgressIndicator());
    bool match(String s) => _q.isEmpty || s.toLowerCase().contains(_q.toLowerCase());
    final friends = [
      for (final p in data.people)
        if (!p.key.startsWith('m:') && !(p.friendGroups.length == 1 && p.friendGroups.first == widget.except) && match(p.name))
          p,
    ];
    final groups = [
      for (final g in data.normalGroups)
        if (g.row.id != widget.except && match(g.row.name)) g,
    ];
    Widget header(String s) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(s, style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        );
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            key: const Key('with-search'),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l.searchFriendsGroups,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _q = v.trim()),
          ),
        ),
        if (friends.isNotEmpty) header(l.friends),
        for (final p in friends)
          ListTile(
            key: Key('with-${p.key}'),
            leading: PersonAvatar(userId: p.userId, name: p.name),
            title: Text(p.name),
            // No friend group and no group we are both still in: the friend link instead (docs/API.md 개요).
            onTap: () => canAddExpenseWith(data, p)
                ? widget.onPick((person: p, groupId: null))
                : showNoSharedGroup(context, ref, p),
          ),
        if (groups.isNotEmpty) header(l.groups),
        for (final g in groups)
          ListTile(
            key: Key('with-${g.row.id}'),
            leading: CircleAvatar(child: Text(g.row.name.isEmpty ? '?' : g.row.name.characters.first.toUpperCase())),
            title: Text(g.row.name),
            onTap: () => widget.onPick((person: null, groupId: g.row.id)),
          ),
        if (friends.isEmpty && groups.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(_q.isEmpty ? l.noFriendsOrGroups : l.nothingMatches(_q),
                textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
          ),
      ],
    );
  }
}

/// Add expense from Home (route `/expenses/new`): first *with whom*, then the expense form of that friend or group.
class NewExpenseScreen extends ConsumerWidget {
  const NewExpenseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: Text(context.l.addExpenseWithWhom)),
        body: WithPicker(
          onPick: (c) => c.person != null
              ? addExpenseWith(context, ref, c.person!, replace: true)
              : context.pushReplacement('/groups/${c.groupId}/expenses/new'),
        ),
      );
}
