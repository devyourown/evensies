import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/core_guard.dart';
import '../../core/money.dart';
import '../../core/offline_banner.dart';
import '../../core/person_avatar.dart';
import '../../data/db/database.dart';
import '../../data/fx_rates.dart';
import '../../domain/overview.dart';
import '../../providers.dart';
import '../friends/home_data.dart';
import '../group_detail/balances.dart';
import 'create_group_dialog.dart';

/// Home (route `/`, `/?tab=friends`): Groups and Friends tabs, each with the overall card, the filter chips and a
/// closed "Settled up (n)" section (docs/API.md 개요 화면).
class GroupsScreen extends ConsumerStatefulWidget {
  /// `friends` opens the Friends tab.
  final String? tab;
  const GroupsScreen({super.key, this.tab});
  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

enum HomeFilter { all, owesMe, iOwe }

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  late int _tab = widget.tab == 'friends' ? 1 : 0;
  HomeFilter _filter = HomeFilter.all;

  @override
  void didUpdateWidget(GroupsScreen old) {
    super.didUpdateWidget(old);
    if (old.tab != widget.tab) _tab = widget.tab == 'friends' ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(homeDataProvider).value;
    final rows = ref.watch(groupsProvider).value ?? const <GroupRow>[];
    final unread = ref.watch(unreadProvider)?.total ?? 0;
    final friends = _tab == 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(friends ? 'Friends' : 'Groups'),
        actions: [
          IconButton(tooltip: 'Search', onPressed: () => context.push('/search'), icon: const Icon(Icons.search)),
          IconButton(
            tooltip: 'Activity',
            onPressed: () => context.push('/activity'),
            icon: Badge(
              key: const Key('activity-badge'),
              isLabelVisible: unread > 0,
              label: Text(badgeLabel(unread)),
              child: const Icon(Icons.history),
            ),
          ),
          if (friends)
            IconButton(
                tooltip: 'Add a friend',
                onPressed: () => context.push('/friends/add'),
                icon: const Icon(Icons.person_add_alt))
          else
            PopupMenuButton<String>(
              tooltip: 'New group',
              icon: const Icon(Icons.group_add_outlined),
              onSelected: (v) => v == 'new' ? showCreateGroupDialog(context) : context.push('/join-code'),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'new', child: Text('New group')),
                PopupMenuItem(value: 'join', child: Text('Join with a code')),
              ],
            ),
          IconButton(
              tooltip: 'Settings',
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      body: Column(children: [
        const OfflineBanner(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(syncProvider).syncAll(),
            child: friends ? _friendsTab(data) : _groupsTab(data, rows),
          ),
        ),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.group_outlined), selectedIcon: Icon(Icons.group), label: 'Groups'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Friends'),
        ],
      ),
      floatingActionButton: rows.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/expenses/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add expense'),
            ),
    );
  }

  Widget _chips() => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Wrap(spacing: 8, runSpacing: 4, children: [
          for (final (f, label) in const [
            (HomeFilter.all, 'All'),
            (HomeFilter.owesMe, 'Owes me'),
            (HomeFilter.iOwe, 'I owe'),
          ])
            ChoiceChip(
              key: Key('filter-${f.name}'),
              label: Text(label),
              selected: _filter == f,
              onSelected: (_) => setState(() => _filter = f),
            ),
        ]),
      );

  /// What the chip keeps, from the per-currency amounts (+ owed to me).
  bool _keep(Map<String, int> amounts) => switch (_filter) {
        HomeFilter.all => true,
        HomeFilter.owesMe => amounts.values.any((v) => v > 0),
        HomeFilter.iOwe => amounts.values.any((v) => v < 0),
      };

  /// The open rows, then (with All) "Settled up (n)", closed by default.
  List<Widget> _sections(List<Widget> open, List<Widget> settled) => [
        ...open,
        if (_filter == HomeFilter.all && settled.isNotEmpty)
          Theme(
            // No divider lines around the tile.
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              key: const Key('settled-section'),
              tilePadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text('Settled up (${settled.length})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              children: settled,
            ),
          ),
      ];

  Widget _groupsTab(HomeData? data, List<GroupRow> rows) {
    final groups = rows.where((g) => g.kind != 'friend').toList();
    if (groups.isEmpty) {
      return ListView(children: [
        if (data != null && data.people.isNotEmpty) Padding(padding: const EdgeInsets.all(16), child: OverallCard(data: data)),
        _Empty(onCreate: () => showCreateGroupDialog(context), onJoin: () => context.push('/join-code')),
      ]);
    }
    final open = <Widget>[], settled = <Widget>[];
    for (final g in groups) {
      final res = data?.group(g.id)?.res;
      final mine = res?.mine(g.myMemberId) ?? const <String, int>{};
      if (!_keep(mine)) continue;
      // Not computed yet (or never): shown with the open ones.
      (res != null && mine.isEmpty ? settled : open).add(_GroupCard(group: g));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      children: [
        if (data != null) OverallCard(data: data),
        _chips(),
        ..._sections(open, settled),
        if (open.isEmpty && (settled.isEmpty || _filter != HomeFilter.all)) _nothing(),
      ],
    );
  }

  Widget _nothing() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          _filter == HomeFilter.owesMe
              ? 'Nobody owes you anything'
              : _filter == HomeFilter.iOwe
                  ? "You don't owe anything"
                  : 'Nothing here yet',
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );

  Widget _friendsTab(HomeData? data) {
    final cs = Theme.of(context).colorScheme;
    if (data == null) return const Center(child: CircularProgressIndicator());
    if (data.people.isEmpty) {
      return ListView(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Icon(Icons.person_add_alt, size: 72, color: cs.primary),
            const SizedBox(height: 16),
            Text('No friends yet', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Add a friend to split expenses outside a group. People you share a group with show up here too.',
                textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 32),
            FilledButton(onPressed: () => context.push('/friends/add'), child: const Text('Add a friend')),
          ]),
        ),
      ]);
    }
    final rates = ref.watch(latestFxProvider).value?.rates;
    final open = <Widget>[], settled = <Widget>[];
    for (final p in data.people) {
      if (!_keep(p.net)) continue;
      (p.settled ? settled : open).add(PersonTile(person: p, data: data, rates: rates));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      children: [
        OverallCard(data: data),
        _chips(),
        ..._sections(open, settled),
        if (open.isEmpty && (settled.isEmpty || _filter != HomeFilter.all)) _nothing(),
        const SizedBox(height: 8),
        // At the start: the extended FAB sits at the end, over a centered button when the list doesn't scroll.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => context.push('/friends/add'),
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Add a friend'),
          ),
        ),
      ],
    );
  }
}

/// "You are owed €42.10 · $15.00", "You owe €8.00", "≈ €61.20 overall" (home currency), on both tabs.
class OverallCard extends ConsumerWidget {
  final HomeData data;
  const OverallCard({super.key, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final o = data.overview;
    String list(Map<String, int> m) => ([...m.keys]..sort()).map((c) => formatMoney(m[c]!, c)).join(' · ');
    final net = {
      for (final c in {...o.owedToMe.keys, ...o.iOwe.keys}) c: (o.owedToMe[c] ?? 0) - (o.iOwe[c] ?? 0),
    };
    final home = ref.watch(homeCurrencyProvider);
    final approx = net.isEmpty ? null : approxIn(home, net, ref.watch(latestFxProvider).value?.rates);
    final n = data.notIncluded;
    return Card(
      key: const Key('overall-card'),
      margin: const EdgeInsets.only(bottom: 12),
      color: cs.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (o.owedToMe.isEmpty && o.iOwe.isEmpty)
            Row(children: [
              Icon(Icons.check_circle_outline, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('You are all settled up', style: text.titleMedium)),
            ]),
          if (o.owedToMe.isNotEmpty)
            Text('You are owed ${list(o.owedToMe)}',
                style: text.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
          if (o.iOwe.isNotEmpty)
            Text('You owe ${list(o.iOwe)}', style: text.titleMedium?.copyWith(color: cs.error, fontWeight: FontWeight.w600)),
          if (approx != null)
            Text('≈ ${approx < 0 ? '−' : ''}${formatMoney(approx.abs(), home)} overall',
                key: const Key('overall-approx'), style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          if (n > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('$n group${n == 1 ? '' : 's'} not included yet',
                  style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ),
        ]),
      ),
    );
  }
}

/// A person on the Friends tab: photo or initials, name, and my balance with them across everything.
class PersonTile extends StatelessWidget {
  final Person person;
  final HomeData data;
  final Map<String, double>? rates;
  const PersonTile({super.key, required this.person, required this.data, this.rates});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final p = person;
    final balance = personBalanceText(p.net, rates);
    final c = p.net.isEmpty ? null : largestCurrency(p.net, rates);
    final color = c == null ? cs.onSurfaceVariant : (p.net[c]! > 0 ? cs.primary : cs.error);
    final sub = [
      if (p.groupId != null) data.label(p.groupId!),
      if (p.userId == null && p.groupId == null) 'not on Evensies yet',
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        key: Key('person-${p.key}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: PersonAvatar(userId: p.userId, name: p.name),
        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text.rich(TextSpan(children: [
          TextSpan(text: balance, style: TextStyle(color: color, fontWeight: c == null ? null : FontWeight.w500)),
          if (sub.isNotEmpty) TextSpan(text: '\n$sub', style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ])),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/friends/${p.key}'),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  const _Empty({required this.onCreate, required this.onJoin});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.group_outlined, size: 72, color: cs.primary),
          const SizedBox(height: 16),
          Text('No groups yet', style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Create one for a trip or a flat, or join a friend\'s group with their invite code.',
              textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 32),
          FilledButton(onPressed: onCreate, child: const Text('Create group')),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onJoin, child: const Text('Join with a code')),
        ],
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  final GroupRow group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(balancesProvider(group.id));
    final res = async.value;
    final memberCount =
        (ref.watch(membersProvider(group.id)).value ?? const <MemberRow>[]).where((m) => !m.removed).length;
    final muted = TextStyle(color: cs.onSurfaceVariant);
    // One line per currency I have a balance in (group currency first), each in its own colour, then "≈" in my home
    // currency on its own line: nothing is cut off.
    final lines = <TextSpan>[];
    if (!async.hasValue) {
      lines.add(TextSpan(text: '…', style: muted));
    } else if (res == null) {
      lines.add(TextSpan(text: notImplementedLabel, style: muted));
    } else {
      final mine = res.mine(group.myMemberId);
      if (mine.isEmpty) lines.add(TextSpan(text: 'Settled up', style: muted));
      for (final MapEntry(key: cur, value: v) in mine.entries) {
        lines.add(TextSpan(
            text: owedText(v, cur),
            style: TextStyle(color: v > 0 ? cs.primary : cs.error, fontWeight: FontWeight.w500)));
      }
      if (res.unsupported > 0) lines.last = TextSpan(text: '${lines.last.text} so far', style: lines.last.style);
      final home = ref.watch(homeCurrencyProvider);
      final approx = mine.isEmpty ? null : approxIn(home, mine, ref.watch(latestFxProvider).value?.rates);
      if (approx != null) {
        final a = formatMoney(approx.abs(), home);
        lines.add(TextSpan(text: mine.length == 1 ? '≈ $a' : 'Net ≈ ${approx < 0 ? '−' : '+'}$a', style: muted));
      }
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(child: Text(group.name.isEmpty ? '?' : group.name.characters.first.toUpperCase())),
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text.rich(TextSpan(children: [
          TextSpan(text: '$memberCount ${memberCount == 1 ? 'member' : 'members'} · '),
          for (final (i, l) in lines.indexed) ...[if (i > 0) const TextSpan(text: '\n'), l],
        ])),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/groups/${group.id}'),
      ),
    );
  }
}
