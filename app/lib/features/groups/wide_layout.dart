import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/cover.dart';
import '../../core/l10n.dart';
import '../../core/money.dart';
import '../../core/person_avatar.dart';
import '../../domain/overview.dart';
import '../../providers.dart';
import '../activity/activity_screen.dart' show ActivityList;
import '../friends/friend_screen.dart' show addExpenseWith, canAddExpenseWith, friendAmountText;
import '../friends/home_data.dart';
import '../group_detail/balances.dart';
import 'create_group_dialog.dart';
import 'groups_screen.dart' show OverallCard;

/// Wide windows of the web app get Splitwise's three columns (docs/API.md, Web app: layout): groups and friends on the left,
/// the page in the middle, the balances of the group or friend on the right. Phones and windows under 1024 px keep
/// the one column.
const wideBreakpoint = 1024.0;

/// Tests turn the layout on outside the browser.
@visibleForTesting
bool debugWideLayout = false;

bool get wideLayoutPlatform => kIsWeb || debugWideLayout;

bool isWide(BuildContext context) => wideLayoutPlatform && MediaQuery.sizeOf(context).width >= wideBreakpoint;

/// The left and right columns around [child] (the router's page) when [isWide]; else [child] alone.
class WideShell extends ConsumerWidget {
  final Uri location;
  final Widget child;
  const WideShell({super.key, required this.location, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isWide(context)) return child;
    // A fresh sign-in: no "All settled up" and "No groups yet" while the groups are on their way.
    if (ref.watch(firstLoadProvider)) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final cs = Theme.of(context).colorScheme;
    final path = location.path;
    final group = RegExp(r'^/groups/([^/]+)').firstMatch(path)?.group(1);
    final friend = RegExp(r'^/friends/([^/]+)').firstMatch(path)?.group(1);
    final data = ref.watch(homeDataProvider).value;
    // A friend group's page is the friend's.
    final personKey = friend ?? (group == null ? null : data?.friendKey(group));
    return ColoredBox(
      color: cs.surfaceContainerLow,
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SizedBox(width: 300, child: _SideNav(location: location, group: group, person: personKey)),
        VerticalDivider(width: 1, color: cs.outlineVariant),
        // Its own semantics container: the page's modal barrier (BlockSemantics) would hide the sidebar from
        // screen readers otherwise.
        Expanded(child: ClipRect(child: Semantics(container: true, child: child))),
        VerticalDivider(width: 1, color: cs.outlineVariant),
        SizedBox(
          width: 340,
          child: Material(
            color: cs.surfaceContainerLow,
            child: personKey != null
                ? _FriendSummary(personKey: personKey)
                : group != null
                    ? _GroupSummary(groupId: group)
                    : path == '/'
                        ? const _RecentActivity()
                        : const _OverallSummary(),
          ),
        ),
      ]),
    );
  }
}

/// A small label above a list, with an optional action.
class _Heading extends StatelessWidget {
  final String text;
  final Widget? action;
  const _Heading(this.text, {this.action});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 4, 4),
      child: Row(children: [
        Expanded(
          child: Text(text.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant, letterSpacing: 0.8)),
        ),
        ?action,
      ]),
    );
  }
}

/// Dashboard, Recent activity, All expenses, the groups and the friends, each with my balance; the selected one
/// highlighted.
class _SideNav extends ConsumerWidget {
  final Uri location;
  final String? group, person;
  const _SideNav({required this.location, this.group, this.person});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l;
    final path = location.path;
    final data = ref.watch(homeDataProvider).value;
    final rates = ref.watch(latestFxProvider).value?.rates;
    final unread = ref.watch(unreadProvider)?.total ?? 0;
    void go(String to) => GoRouter.of(context).go(to);
    Widget item({
      required Key key,
      required Widget leading,
      required String title,
      String? subtitle,
      Color? subtitleColor,
      required bool selected,
      required String to,
    }) =>
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          child: ListTile(
            key: key,
            dense: true,
            selected: selected,
            selectedTileColor: cs.secondaryContainer,
            selectedColor: cs.onSecondaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: leading,
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: subtitle == null
                ? null
                : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: subtitleColor)),
            onTap: () => go(to),
          ),
        );
    final groups = data?.normalGroups ?? const <HomeGroup>[];
    final people = data?.people ?? const <Person>[];
    return Material(
      color: cs.surfaceContainerLow,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
          child: Row(children: [
            Icon(Icons.savings_outlined, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Evensies', style: text.titleLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
            ),
            IconButton(tooltip: l.search, onPressed: () => context.push('/search'), icon: const Icon(Icons.search)),
            IconButton(
                tooltip: l.settingsTitle,
                onPressed: () => go('/settings'),
                icon: const Icon(Icons.settings_outlined)),
          ]),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
            item(
              key: const Key('nav-dashboard'),
              leading: const Icon(Icons.dashboard_outlined),
              title: l.dashboard,
              selected: path == '/',
              to: '/',
            ),
            item(
              key: const Key('nav-activity'),
              leading: Badge(isLabelVisible: unread > 0, label: Text(badgeLabel(unread)), child: const Icon(Icons.history)),
              title: l.activity,
              selected: path == '/activity',
              to: '/activity',
            ),
            item(
              key: const Key('nav-all-expenses'),
              leading: const Icon(Icons.receipt_long_outlined),
              title: l.allExpenses,
              selected: path == '/search' && location.queryParameters['all'] == '1',
              to: '/search?all=1',
            ),
            _Heading(l.groups,
                action: PopupMenuButton<String>(
                  key: const Key('nav-new-group'),
                  tooltip: l.newGroup,
                  icon: const Icon(Icons.add, size: 20),
                  onSelected: (v) => v == 'new' ? showCreateGroupDialog(context) : context.push('/join-code'),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'new', child: Text(l.newGroup)),
                    PopupMenuItem(value: 'join', child: Text(l.joinWithCode)),
                  ],
                )),
            if (data != null && groups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Text(l.noGroupsYet, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ),
            for (final g in groups)
              () {
                final mine = g.res.mine(g.row.myMemberId);
                final c = mine.isEmpty ? null : largestCurrency(mine, rates);
                return item(
                  key: Key('nav-group-${g.row.id}'),
                  leading: GroupCover(groupId: g.row.id, type: g.row.type, coverImageId: g.row.coverImageId, size: 32),
                  title: g.row.name,
                  subtitle: c == null ? l.settledUp : owedText(l, mine[c]!, c, capital: false),
                  subtitleColor: c == null ? cs.onSurfaceVariant : (mine[c]! > 0 ? cs.primary : cs.error),
                  selected: group == g.row.id,
                  to: '/groups/${g.row.id}',
                );
              }(),
            _Heading(l.friends,
                action: IconButton(
                  key: const Key('nav-add-friend'),
                  tooltip: l.addAFriend,
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => context.push('/friends/add'),
                )),
            if (data != null && people.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Text(l.noFriendsYet, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ),
            for (final p in people)
              item(
                key: Key('nav-person-${p.key}'),
                leading: PersonAvatar(userId: p.userId, name: p.name, radius: 16),
                title: p.name,
                subtitle: personBalanceText(l, p.net, rates),
                subtitleColor: p.net.isEmpty
                    ? cs.onSurfaceVariant
                    : (p.net[largestCurrency(p.net, rates)]! > 0 ? cs.primary : cs.error),
                selected: person == p.key,
                to: '/friends/${p.key}',
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            key: const Key('nav-add-expense'),
            onPressed: groups.isEmpty && people.isEmpty ? null : () => _addExpense(context, ref, data!, group: group, person: person),
            icon: const Icon(Icons.add),
            label: Text(l.addExpense),
          ),
        ),
      ]),
    );
  }
}

/// The sidebar's Add expense (the pages beside it have no button of their own): with the friend or in the group that
/// is open, else with whom first.
void _addExpense(BuildContext context, WidgetRef ref, HomeData data, {String? group, String? person}) {
  final p = person == null ? null : data.person(person);
  if (p != null && canAddExpenseWith(data, p)) {
    addExpenseWith(context, ref, p);
  } else if (p == null && group != null) {
    context.push('/groups/$group/expenses/new');
  } else {
    context.push('/expenses/new');
  }
}

/// The group's balances, one row per member, and Settle up.
class _GroupSummary extends ConsumerWidget {
  final String groupId;
  const _GroupSummary({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l;
    final group = ref.watch(groupProvider(groupId)).value;
    final res = ref.watch(balancesProvider(groupId)).value;
    final state = ref.watch(groupStateProvider(groupId)).value;
    if (group == null || res == null || state == null) return const SizedBox.shrink();
    final b = res.balances;
    final d = group.defaultCurrency;
    final rows = [for (final m in state.members) if (!m.removed || (b[m.id] ?? 0) != 0) m];
    final unsettled = rows.any((m) => (b[m.id] ?? 0) != 0);
    return ListView(key: const Key('wide-group-summary'), padding: const EdgeInsets.only(bottom: 24), children: [
      _Heading(l.groupBalances),
      for (final m in rows)
        ListTile(
          dense: true,
          leading: PersonAvatar(userId: m.userId, name: m.name, radius: 16),
          title: Text(m.id == group.myMemberId ? l.youSuffix(m.name) : m.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            switch (b[m.id] ?? 0) {
              0 => l.balanceSettled,
              final v when v > 0 => '${l.balanceGetsBack} ${formatMoney(v, d)}',
              final v => '${l.balanceOwes} ${formatMoney(-v, d)}',
            },
            style: TextStyle(
                color: (b[m.id] ?? 0) == 0 ? cs.onSurfaceVariant : ((b[m.id] ?? 0) > 0 ? cs.primary : cs.error),
                fontWeight: FontWeight.w500),
          ),
        ),
      for (final c in res.others)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(l.summaryNotConverted(c), style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ),
      if (unsettled && !group.deleted)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: FilledButton.icon(
            key: const Key('wide-settle'),
            onPressed: () => context.push('/groups/$groupId/settle'),
            icon: const Icon(Icons.handshake_outlined),
            label: Text(l.settleUp),
          ),
        ),
    ]);
  }
}

/// What I owe the person or they owe me, per currency and per group.
class _FriendSummary extends ConsumerWidget {
  final String personKey;
  const _FriendSummary({required this.personKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l = context.l;
    final data = ref.watch(homeDataProvider).value;
    final p = data?.person(personKey);
    if (data == null || p == null) return const SizedBox.shrink();
    final byGroup = data.overview.byGroup[p.key] ?? const <String, Map<String, int>>{};
    final currencies = [...p.net.keys]..sort();
    return ListView(key: const Key('wide-friend-summary'), padding: const EdgeInsets.only(bottom: 24), children: [
      _Heading(l.yourBalance),
      if (currencies.isEmpty)
        ListTile(dense: true, title: Text(l.allSettledUp, style: TextStyle(color: cs.onSurfaceVariant))),
      for (final c in currencies)
        ListTile(
          dense: true,
          title: Text(friendAmountText(l, p.name, p.net[c]!, c),
              style: TextStyle(color: p.net[c]! > 0 ? cs.primary : cs.error, fontWeight: FontWeight.w600)),
        ),
      if (byGroup.isNotEmpty) _Heading(l.balances),
      for (final MapEntry(key: gid, value: amounts) in byGroup.entries)
        for (final c in [...amounts.keys]..sort())
          ListTile(
            dense: true,
            title: Text(data.label(gid, l), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(friendAmountText(l, p.name, amounts[c]!, c, capital: false),
                style: TextStyle(color: amounts[c]! > 0 ? cs.primary : cs.error)),
          ),
    ]);
  }
}

/// The overall card and who owes whom, beside pages that aren't a group or a friend.
class _OverallSummary extends ConsumerWidget {
  const _OverallSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(homeDataProvider).value;
    if (data == null) return const SizedBox.shrink();
    return ListView(key: const Key('wide-overall'), padding: const EdgeInsets.all(16), children: [
      OverallCard(data: data),
    ]);
  }
}

/// Beside the dashboard: the latest changes in every group.
class _RecentActivity extends StatelessWidget {
  const _RecentActivity();
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _Heading(context.l.activity),
        const Expanded(child: ActivityList()),
      ]);
}

/// The dashboard in the middle column (the `/` page when [isWide]): the overall card, then who owes me and whom I
/// owe, like Splitwise's.
class WideDashboard extends ConsumerWidget {
  const WideDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l;
    final data = ref.watch(homeDataProvider).value;
    final rates = ref.watch(latestFxProvider).value?.rates;
    Widget column(String title, List<Person> people, bool owesMe) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: text.titleSmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            if (people.isEmpty)
              Text(owesMe ? l.nobodyOwesYou : l.youOweNothing, style: TextStyle(color: cs.onSurfaceVariant)),
            for (final p in people)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: PersonAvatar(userId: p.userId, name: p.name),
                title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(personBalanceText(l, {
                  for (final e in p.net.entries)
                    if ((e.value > 0) == owesMe) e.key: e.value,
                }, rates), style: TextStyle(color: owesMe ? cs.primary : cs.error)),
                onTap: () => GoRouter.of(context).go('/friends/${p.key}'),
              ),
          ]),
        );
    return Scaffold(
      appBar: AppBar(title: Text(l.dashboard)),
      body: data == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 88), children: [
              OverallCard(data: data),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                column(l.dashboardOwesYou, [for (final p in data.people) if (p.owesMe) p], true),
                const SizedBox(width: 24),
                column(l.dashboardYouOwe, [for (final p in data.people) if (p.iOweThem) p], false),
              ]),
            ]),
    );
  }
}

/// The web app's one 640 px column with `surfaceContainerLow` around it (docs/API.md, Web app: layout): the sign-in pages
/// always, every page in windows under [wideBreakpoint] ([wide] false). Phones: [child] as is. The same widgets in
/// both cases, so crossing the breakpoint keeps the pages' state.
class WebColumn extends StatelessWidget {
  final Widget child;
  final bool wide;
  const WebColumn({super.key, required this.child, this.wide = false});

  @override
  Widget build(BuildContext context) {
    if (!wideLayoutPlatform) return child;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Center(
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: wide ? double.infinity : 640), child: child),
      ),
    );
  }
}
