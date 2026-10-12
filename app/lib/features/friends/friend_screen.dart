import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/confirm.dart';
import '../../core/env.dart';
import '../../core/ids.dart';
import '../../core/l10n.dart';
import '../../core/money.dart';
import '../../core/offline_banner.dart';
import '../../core/person_avatar.dart';
import '../../core/snack.dart';
import '../../data/api/dto.dart';
import '../../domain/models.dart' show GroupState;
import '../../domain/overview.dart';
import '../../domain/payment_methods.dart';
import '../../providers.dart';
import '../auth/auth_service.dart' show infoProvider;
import '../group_detail/group_detail_screen.dart' show DateHeader, ExpenseTile, PaymentTile;
import '../settings/settings_screen.dart' show exportGroup;
import 'add_friend_screen.dart' show shareFriendLink;
import 'home_data.dart';
import '../groups/wide_layout.dart' show isWide;

/// "Ben owes you €4.00" / "You owe Ben €3.00" ([capital] false: a line under a group name).
String friendAmountText(AppLocalizations l, String name, int v, String currency, {bool capital = true}) {
  final m = formatMoney(v.abs(), currency);
  return v > 0 ? l.friendOwesYou(name, m) : (capital ? l.friendYouOwe(name, m) : l.friendYouOweLine(name, m));
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


/// The same line as a dialog (the With picker, or a stale device that got a 403): Share friend link or Cancel.
Future<void> showNoSharedGroup(BuildContext context, WidgetRef ref, Person p) async {
  final share = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('no-shared-group'),
      content: Text(ctx.l.noSharedGroup(p.name)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l.cancel)),
        FilledButton.icon(
          onPressed: () => Navigator.pop(ctx, true),
          icon: const Icon(Icons.share, size: 18),
          label: Text(ctx.l.shareFriendLink),
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
    showError(context, e.code == 'NETWORK' ? context.l.firstExpenseNeedsConnection(p.name) : e);
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
      if (mounted) showInfo(context, context.l.reminderSent(p.name));
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(
        context,
        switch (e) {
          ApiException(status: 429) => context.l.remindTomorrow(p.name),
          ApiException(status: 409) => context.l.remindNothingOwed(p.name),
          ApiException(code: 'NETWORK') => context.l.remindNeedsConnection,
          _ => e,
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
    if (!mounted) return;
    final l = context.l;
    final amounts = ([...owed.keys]..sort()).map((x) => formatMoney(owed[x]!, x)).toList();
    final msg = requestText(
      l,
      formattedAmount: amounts.reduce((a, b) => l.amountsAnd(a, b)),
      group: p.groupId == null ? l.requestNoGroup : data.label(p.groupId!, l),
      methods: methods,
      amountMinor: owed[c]!,
      currency: c,
    );
    await shareText(context, msg);
  }

  /// Delete friend (docs/API.md 친구 삭제): `group.deleted` on every friend group with [p], offline too; their
  /// non-group expenses go for both of us, and come back with Undo, Settings → Deleted groups or adding them again.
  /// Shared groups stay. Like Splitwise, only once our non-group balance ([nonGroup], per currency) is settled: deleting
  /// would wipe that debt for both of us, so the dialog shows it and offers Settle up instead.
  Future<void> _deleteFriend(Person p, Map<String, int> nonGroup) async {
    final l = context.l;
    if (nonGroup.isNotEmpty) {
      final owed = [for (final c in [...nonGroup.keys]..sort()) friendAmountText(l, p.name, nonGroup[c]!, c)];
      final settle = await confirm(context,
          title: l.settleUpFirst,
          message: [owed.join('\n'), l.deleteFriendSettleFirst(p.name)].join('\n\n'),
          confirmLabel: l.settleUp,
          destructive: false);
      if (settle && mounted) context.push('/friends/${p.key}/settle');
      return;
    }
    final ok = await confirm(context,
        title: l.deleteFriendTitle(p.name), message: l.deleteFriendMessage(p.name), confirmLabel: l.delete);
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final writes = ref.read(localWritesProvider);
    final ids = [...p.friendGroups];
    for (final id in ids) {
      await writes.deleteGroup(id);
    }
    router.go('/?tab=friends');
    showUndo(messenger, l.friendDeleted(p.name), () async {
      for (final id in ids) {
        await writes.restoreGroup(id);
      }
    });
  }

  /// Block or unblock (docs/API.md 차단), online only: they can't add me or remind me, and their changes stop
  /// notifying me; shared groups and balances stay.
  Future<void> _block(Person p, {required bool block}) async {
    final l = context.l;
    if (block &&
        !await confirm(context,
            title: l.blockTitle(p.name), message: l.blockMessage(p.name), confirmLabel: l.block)) {
      return;
    }
    try {
      final api = ref.read(apiProvider);
      await (block ? api.block(p.userId!) : api.unblock(p.userId!));
      ref.invalidate(blocksProvider);
      if (mounted) showInfo(context, block ? l.blockedName(p.name) : l.unblockedName(p.name));
    } catch (e) {
      if (mounted) showError(context, e is ApiException && e.code == 'NETWORK' ? l.blockNeedsConnection : e);
    }
  }

  /// Report… opens an email to the server's support address with the person's user id.
  Future<void> _report(Person p, String support) =>
      openMail(context, support, subject: context.l.reportSubject, body: context.l.reportBody(p.userId!));

  /// A placeholder friend claims their member through the friend group's invite link.
  Future<void> _invite(HomeData data, Person p) async {
    final code = data.group(p.friendGroups.first)?.row.inviteCode;
    if (code == null) return;
    final link = '${ref.read(serverUrlProvider)}/j/$code';
    await shareText(context, context.l.inviteFriendText(link));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(homeDataProvider);
    final data = async.value;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l;
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
                Text(l.personNotHere, style: text.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(l.personNotHereNote,
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
        return d != 0 ? d : data.label(a, l).toLowerCase().compareTo(data.label(b, l).toLowerCase());
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
    final support = ref.watch(infoProvider).supportEmail;
    final blocked = p.userId != null && (ref.watch(blocksProvider).valueOrNull?.any((b) => b.userId == p.userId) ?? false);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isWide(context), // wide web layout: the sidebar is the way back
        title: Text(p.name),
        actions: [
          if (p.friendGroups.isNotEmpty || p.userId != null)
            PopupMenuButton<String>(
              key: const Key('friend-menu'),
              tooltip: l.more,
              onSelected: (v) => switch (v) {
                'delete' => _deleteFriend(p, nonGroup),
                'block' => _block(p, block: !blocked),
                'report' => _report(p, support!),
                _ => exportGroup(context, ref, p.friendGroups.first, l.nonGroupWith(p.name), v),
              },
              itemBuilder: (_) => [
                if (p.friendGroups.isNotEmpty) ...[
                  PopupMenuItem(value: 'csv', child: Text(l.exportNonGroupCsv)),
                  PopupMenuItem(value: 'json', child: Text(l.exportNonGroupJson)),
                  PopupMenuItem(value: 'zip', child: Text(l.exportNonGroupZip)),
                  const PopupMenuDivider(),
                  PopupMenuItem(key: const Key('delete-friend'), value: 'delete', child: Text(l.deleteFriend)),
                ],
                if (p.userId != null)
                  PopupMenuItem(
                      key: const Key('block-friend'), value: 'block', child: Text(blocked ? l.unblock : l.block)),
                if (p.userId != null && support != null)
                  PopupMenuItem(key: const Key('report-friend'), value: 'report', child: Text(l.report)),
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
                  Text(l.notOnEvensies,
                      textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 8),
                if (currencies.isEmpty)
                  Text(l.allSettledUp,
                      key: const Key('friend-settled'),
                      textAlign: TextAlign.center,
                      style: text.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
                for (final c in currencies)
                  Text(friendAmountText(l, p.name, p.net[c]!, c),
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
                        label: Text(l.settleUp),
                      ),
                    if (p.userId != null && owesMe)
                      FilledButton.tonalIcon(
                        key: const Key('friend-remind'),
                        onPressed: _reminding ? null : () => _remind(p),
                        icon: _reminding
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.notifications_active_outlined),
                        label: Text(l.remind),
                      ),
                    if (p.userId == null && owesMe)
                      FilledButton.tonalIcon(
                        key: const Key('friend-request'),
                        onPressed: () => _request(data, p),
                        icon: const Icon(Icons.ios_share),
                        label: Text(l.request),
                      ),
                    if (p.userId == null && p.friendGroups.isNotEmpty)
                      OutlinedButton.icon(
                        key: const Key('friend-invite'),
                        onPressed: () => _invite(data, p),
                        icon: const Icon(Icons.person_add_alt),
                        label: Text(l.invite),
                      ),
                  ]),
                ),
                if (nonGroup.isNotEmpty || groupLines.isNotEmpty) ...[
                  section(l.balances),
                  if (nonGroup.isNotEmpty)
                    _BreakdownRow(
                        key: const Key('breakdown-non-group'), label: l.nonGroup, name: p.name, amounts: nonGroup),
                  for (final MapEntry(key: gid, value: amounts) in groupLines.entries)
                    _BreakdownRow(
                      key: Key('breakdown-$gid'),
                      label: data.label(gid, l),
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
                          Text(l.noSharedGroup(p.name)),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              key: const Key('share-friend-link'),
                              onPressed: () => shareFriendLink(context, ref),
                              icon: const Icon(Icons.share, size: 18),
                              label: Text(l.shareFriendLink),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                if (sections.isEmpty && p.friendGroups.isNotEmpty) ...[
                  section(l.expensesAndPayments),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(l.nothingTogetherYet,
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                ],
                for (final key in order) ...[
                  _SectionHeader(
                    key: Key('together-${key.isEmpty ? 'non-group' : key}'),
                    label: key.isEmpty ? l.nonGroup : data.label(key, l),
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
      // Wide web layout: the sidebar's Add expense adds with them.
      floatingActionButton: !canAdd || isWide(context)
          ? null
          : FloatingActionButton.extended(
              key: const Key('friend-add-expense'),
              onPressed: () => addExpenseWith(context, ref, p),
              icon: const Icon(Icons.add),
              label: Text(l.addExpense),
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
            text: '${i > 0 ? '\n' : ''}${friendAmountText(context.l, name, amounts[c]!, c, capital: false)}',
            style: TextStyle(color: amounts[c]! > 0 ? cs.primary : cs.error),
          ),
      ])),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
