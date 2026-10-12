import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/env.dart';
import '../../core/ids.dart';
import '../../core/money.dart';
import '../../core/offline_banner.dart';
import '../../core/person_avatar.dart';
import '../../core/snack.dart';
import '../../data/api/dto.dart';
import '../../domain/models.dart' show GroupState;
import '../../domain/overview.dart';
import '../../domain/payment_methods.dart';
import '../../providers.dart';
import '../group_detail/group_detail_screen.dart' show DateHeader, ExpenseTile, PaymentTile;
import '../settings/settings_screen.dart' show exportGroup;
import 'add_friend_screen.dart' show shareFriendLink;
import 'home_data.dart';

/// "Ben owes you €4.00" / "You owe Ben €3.00".
String friendAmountText(String name, int v, String currency, {bool capital = true}) {
  final m = formatMoney(v.abs(), currency);
  return v > 0 ? '$name owes you $m' : '${capital ? 'You' : 'you'} owe $name $m';
}

/// The group a new expense with [p] goes to: their friend group (the smallest id), a placeholder's own group, or a new
/// friend group (`POST /friends {userId}`, online only; docs/API.md 친구).
Future<String> groupForExpenseWith(WidgetRef ref, Person p) async {
  if (p.friendGroups.isNotEmpty) return p.friendGroups.first;
  if (p.groupId != null) return p.groupId!;
  final dto = await ref
      .read(apiProvider)
      .addFriend(id: newId(), defaultCurrency: ref.read(homeCurrencyProvider), userId: p.userId);
  await ref.read(syncProvider).adoptFromSnapshot(dto.id);
  return dto.id;
}

/// Whether a new expense with [p] can be added (docs/API.md 개요 Add expense): always with a friend group; for a
/// linked person without one, only while a normal group on this device has both of us as active, linked members (what
/// `POST /friends {userId}` needs). A placeholder in a normal group (`m:`) gets expenses in that group.
bool canAddExpenseWith(HomeData data, Person p) {
  if (p.friendGroups.isNotEmpty) return true;
  if (p.userId == null) return false;
  bool active(GroupState s, String? user) => s.members.any((m) => !m.removed && m.userId == user);
  return data.groups.any((g) => !g.state.isFriend && active(g.state, data.myUserId) && active(g.state, p.userId));
}

String noSharedGroupText(String name) =>
    'You no longer share a group with $name. Send them your friend link to add expenses.';

/// The same line as a dialog (the With picker, or a stale device that got a 403): Share friend link or Cancel.
Future<void> showNoSharedGroup(BuildContext context, WidgetRef ref, Person p) async {
  final share = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('no-shared-group'),
      content: Text(noSharedGroupText(p.name)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, true),
          icon: const Icon(Icons.share, size: 18),
          label: const Text('Share friend link'),
        ),
      ],
    ),
  );
  if (share == true && context.mounted) await shareFriendLink(context, ref);
}

/// Opens a new expense with [p]; tells the user when the friend group can't be created now.
Future<void> addExpenseWith(BuildContext context, WidgetRef ref, Person p, {bool replace = false}) async {
  try {
    final gid = await groupForExpenseWith(ref, p);
    if (!context.mounted) return;
    replace ? context.pushReplacement('/groups/$gid/expenses/new') : context.push('/groups/$gid/expenses/new');
  } on ApiException catch (e) {
    if (!context.mounted) return;
    // This device still thought we share a group: the same message as when it knows (docs/API.md 개요).
    if (e.status == 403 && e.code != 'NETWORK') return showNoSharedGroup(context, ref, p);
    showError(context, e.code == 'NETWORK' ? 'The first expense with ${p.name} needs a connection.' : e.message);
  }
}

/// A person (route `/friends/{key}`, docs/API.md 개요 화면): photo and net per currency, the balance per group, the
/// non-group expenses, and Settle up, Remind or Request, Invite.
class FriendScreen extends ConsumerStatefulWidget {
  final String personKey;
  const FriendScreen({super.key, required this.personKey});
  @override
  ConsumerState<FriendScreen> createState() => _FriendScreenState();
}

class _FriendScreenState extends ConsumerState<FriendScreen> {
  bool _reminding = false;

  /// Friend groups marked seen (or tried) while this page is open: once each, so no build asks again.
  final _marking = <String>{};

  /// A friend group has no Activity tab: its unread items (a friend_added push opens this page) are seen here, up to
  /// its newest feed item (docs/API.md 읽지 않은 활동).
  Future<void> _markSeen(String groupId) async {
    try {
      final page = await ref.read(apiProvider).activity(groupId: groupId, limit: 1);
      final newest = page.items.map((i) => i.feedId ?? 0).fold(0, (a, b) => a > b ? a : b);
      if (newest > 0) await ref.read(unreadProvider.notifier).seen(newest, groupId: groupId);
    } catch (_) {} // offline: the badge stays until the page is opened again or the feed is
  }

  Future<void> _remind(Person p) async {
    setState(() => _reminding = true);
    try {
      await ref.read(apiProvider).remind(p.userId!);
      if (mounted) showInfo(context, 'Reminder sent to ${p.name}');
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(
        context,
        switch (e) {
          ApiException(status: 429) => 'You can remind ${p.name} again tomorrow',
          ApiException(status: 409) => "${p.name} doesn't owe you anything",
          ApiException(code: 'NETWORK') => 'Sending a reminder needs a connection.',
          _ => e.message,
        },
      );
    } finally {
      if (mounted) setState(() => _reminding = false);
    }
  }

  /// Phase 1's Request text for someone not on Evensies, with my ways to get paid when they can be loaded.
  Future<void> _request(HomeData data, Person p) async {
    final owed = {for (final e in p.net.entries) if (e.value > 0) e.key: e.value};
    final c = largestCurrency(owed, ref.read(latestFxProvider).value?.rates);
    var methods = const <PaymentMethod>[];
    try {
      methods = await ref.read(apiProvider).getMyPaymentMethods();
    } catch (_) {}
    final msg = requestText(
      formattedAmount: ([...owed.keys]..sort()).map((x) => formatMoney(owed[x]!, x)).join(' and '),
      group: p.groupId == null ? 'our shared expenses' : data.label(p.groupId!),
      methods: methods,
      amountMinor: owed[c]!,
      currency: c,
    );
    await SharePlus.instance.share(ShareParams(text: msg));
  }

  /// A placeholder friend claims their member through the friend group's invite link.
  Future<void> _invite(HomeData data, Person p) async {
    final code = data.group(p.friendGroups.first)?.row.inviteCode;
    if (code == null) return;
    final link = '${ref.read(serverUrlProvider)}/j/$code';
    await SharePlus.instance
        .share(ShareParams(text: 'I added you on Evensies so we can split expenses. Join me: $link'));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(homeDataProvider);
    final data = async.value;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (data == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final p = data.person(widget.personKey);
    if (p == null) {
      return Scaffold(
        appBar: AppBar(),
        body: RefreshIndicator(
          onRefresh: () => ref.read(syncProvider).syncAll(),
          child: ListView(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
              child: Column(children: [
                Icon(Icons.person_search_outlined, size: 64, color: cs.primary),
                const SizedBox(height: 16),
                Text("This person isn't on this device", style: text.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text("It hasn't synced yet, or you no longer share a group.",
                    style: TextStyle(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
              ]),
            ),
          ]),
        ),
      );
    }
    final unread = ref.watch(unreadProvider)?.groups ?? const <String, int>{};
    for (final g in p.friendGroups) {
      if ((unread[g] ?? 0) > 0 && _marking.add(g)) _markSeen(g);
    }
    final byGroup = data.overview.byGroup[p.key] ?? const <String, Map<String, int>>{};
    final lines = friendLines(data.ledgers.values, p.key);
    final owesMe = p.owesMe;
    // Everything between the two of us in every shared group, by group, like Splitwise's friend page (docs/API.md
    // 함께한 기록): all of a friend group, and in another group what both of us paid or share, or a payment between us.
    final sections = <String, List<({String date, int order, Widget tile})>>{}; // '' = Non-group (friend groups)
    for (final g in data.groups) {
      final keyOf = {for (final m in g.state.members) m.id: personKey(g.row.id, g.state, m)};
      final mine = {for (final e in keyOf.entries) if (e.value == data.myUserId) e.key};
      final theirs = {for (final e in keyOf.entries) if (e.value == p.key) e.key};
      if (mine.isEmpty || theirs.isEmpty) continue;
      bool both(Iterable<String> ids) => g.state.isFriend || (ids.any(mine.contains) && ids.any(theirs.contains));
      final gid = g.row.id;
      final names = {for (final m in g.state.members) m.id: m.name};
      final rows = sections.putIfAbsent(g.state.isFriend ? '' : gid, () => []);
      var order = rows.length;
      for (final e in g.state.expenses) {
        if (e.deleted || !both([for (final x in [...e.payers, ...e.shares]) if (x.amount != 0) x.memberId])) continue;
        rows.add((date: e.date, order: order++, tile: ExpenseTile(expense: e, group: g.row, names: names)));
      }
      for (final x in g.state.payments) {
        if (x.deleted || !both([x.fromMember, x.toMember])) continue;
        rows.add((
          date: x.date,
          order: order++,
          tile: PaymentTile(groupId: gid, payment: x, names: names, myMemberId: g.row.myMemberId),
        ));
      }
    }
    sections.removeWhere((_, rows) => rows.isEmpty);
    for (final rows in sections.values) {
      rows.sort((a, b) => a.date != b.date ? b.date.compareTo(a.date) : b.order.compareTo(a.order));
    }
    // Non-group first, then the groups by their newest row (same day: by name).
    final order = sections.keys.toList()
      ..sort((a, b) {
        if (a.isEmpty || b.isEmpty) return a.isEmpty ? -1 : 1;
        final d = sections[b]!.first.date.compareTo(sections[a]!.first.date);
        return d != 0 ? d : data.label(a).toLowerCase().compareTo(data.label(b).toLowerCase());
      });
    final canAdd = canAddExpenseWith(data, p);
    // Two friend groups of one person (a claimed placeholder friend, docs/API.md 친구) are one Non-group line.
    final nonGroup = <String, int>{};
    final groupLines = <String, Map<String, int>>{};
    for (final MapEntry(key: gid, value: amounts) in byGroup.entries) {
      if (data.group(gid)?.state.isFriend == true) {
        for (final MapEntry(key: c, value: v) in amounts.entries) {
          nonGroup[c] = (nonGroup[c] ?? 0) + v;
        }
      } else {
        groupLines[gid] = amounts;
      }
    }
    nonGroup.removeWhere((_, v) => v == 0);

    Widget section(String s) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(s, style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        );
    final currencies = [...p.net.keys]..sort();
    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          if (p.friendGroups.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (f) => exportGroup(context, ref, p.friendGroups.first, 'Non-group · ${p.name}', f),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'csv', child: Text('Export non-group expenses (CSV)')),
                PopupMenuItem(value: 'json', child: Text('Export non-group expenses (JSON)')),
                PopupMenuItem(value: 'zip', child: Text('Export non-group expenses (ZIP with receipts)')),
              ],
            ),
        ],
      ),
      body: Column(children: [
        const OfflineBanner(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(syncProvider).syncAll(),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                const SizedBox(height: 16),
                Center(child: PersonAvatar(userId: p.userId, name: p.name, radius: 40)),
                const SizedBox(height: 12),
                Text(p.name, textAlign: TextAlign.center, style: text.headlineSmall),
                if (p.userId == null)
                  Text('Not on Evensies yet',
                      textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 8),
                if (currencies.isEmpty)
                  Text('All settled up',
                      key: const Key('friend-settled'),
                      textAlign: TextAlign.center,
                      style: text.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
                for (final c in currencies)
                  Text(friendAmountText(p.name, p.net[c]!, c),
                      textAlign: TextAlign.center,
                      style: text.titleMedium
                          ?.copyWith(color: p.net[c]! > 0 ? cs.primary : cs.error, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                    if (lines.isNotEmpty)
                      FilledButton.icon(
                        key: const Key('friend-settle'),
                        onPressed: () => context.push('/friends/${p.key}/settle'),
                        icon: const Icon(Icons.handshake_outlined),
                        label: const Text('Settle up'),
                      ),
                    if (p.userId != null && owesMe)
                      FilledButton.tonalIcon(
                        key: const Key('friend-remind'),
                        onPressed: _reminding ? null : () => _remind(p),
                        icon: _reminding
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.notifications_active_outlined),
                        label: const Text('Remind'),
                      ),
                    if (p.userId == null && owesMe)
                      FilledButton.tonalIcon(
                        key: const Key('friend-request'),
                        onPressed: () => _request(data, p),
                        icon: const Icon(Icons.ios_share),
                        label: const Text('Request'),
                      ),
                    if (p.userId == null && p.friendGroups.isNotEmpty)
                      OutlinedButton.icon(
                        key: const Key('friend-invite'),
                        onPressed: () => _invite(data, p),
                        icon: const Icon(Icons.person_add_alt),
                        label: const Text('Invite'),
                      ),
                  ]),
                ),
                if (nonGroup.isNotEmpty || groupLines.isNotEmpty) ...[
                  section('Balances'),
                  if (nonGroup.isNotEmpty)
                    _BreakdownRow(
                        key: const Key('breakdown-non-group'), label: 'Non-group', name: p.name, amounts: nonGroup),
                  for (final MapEntry(key: gid, value: amounts) in groupLines.entries)
                    _BreakdownRow(
                      key: Key('breakdown-$gid'),
                      label: data.label(gid),
                      name: p.name,
                      amounts: amounts,
                      onTap: () => context.push('/groups/$gid'),
                    ),
                ],
                if (p.userId != null && !canAdd)
                  Padding(
                    key: const Key('no-shared-group'),
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: Card(
                      color: cs.surfaceContainerHigh,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Text(noSharedGroupText(p.name)),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              key: const Key('share-friend-link'),
                              onPressed: () => shareFriendLink(context, ref),
                              icon: const Icon(Icons.share, size: 18),
                              label: const Text('Share friend link'),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                if (sections.isEmpty && p.friendGroups.isNotEmpty) ...[
                  section('Expenses and payments'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Nothing together yet. Add an expense below.',
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                ],
                for (final key in order) ...[
                  _SectionHeader(
                    key: Key('together-${key.isEmpty ? 'non-group' : key}'),
                    label: key.isEmpty ? 'Non-group' : data.label(key),
                    onTap: key.isEmpty ? null : () => context.push('/groups/$key'),
                  ),
                  for (final (i, r) in sections[key]!.indexed) ...[
                    if (i == 0 || sections[key]![i - 1].date != r.date) DateHeader(r.date),
                    r.tile,
                  ],
                ],
              ],
            ),
          ),
        ),
      ]),
      // A placeholder in a normal group: add expenses there. No shared group any more: the friend link above.
      floatingActionButton: !canAdd
          ? null
          : FloatingActionButton.extended(
              key: const Key('friend-add-expense'),
              onPressed: () => addExpenseWith(context, ref, p),
              icon: const Icon(Icons.add),
              label: const Text('Add expense'),
            ),
    );
  }
}

/// A group's section on the friend page; tapping a normal group's opens it.
class _SectionHeader extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _SectionHeader({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Row(children: [
          Icon(onTap == null ? Icons.person_outline : Icons.group_outlined, size: 18, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant))),
          if (onTap != null) Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
        ]),
      ),
    );
  }
}

/// "Rome: you owe Ben €3.00", one line per currency in its colour; tapping a normal group opens it.
class _BreakdownRow extends StatelessWidget {
  final String label;
  final String name;
  final Map<String, int> amounts;
  final VoidCallback? onTap;
  const _BreakdownRow({super.key, required this.label, required this.name, required this.amounts, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cur = [...amounts.keys]..sort();
    return ListTile(
      leading: Icon(onTap == null ? Icons.person_outline : Icons.group_outlined, color: cs.onSurfaceVariant),
      title: Text(label),
      subtitle: Text.rich(TextSpan(children: [
        for (final (i, c) in cur.indexed)
          TextSpan(
            text: '${i > 0 ? '\n' : ''}${friendAmountText(name, amounts[c]!, c, capital: false)}',
            style: TextStyle(color: amounts[c]! > 0 ? cs.primary : cs.error),
          ),
      ])),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
