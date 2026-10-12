/// Overview (docs/API.md 개요): what I owe and am owed per person and in total, summed from each group's Settle up
/// transfers. The Friends tab, the overall card, the friend page and the server's reminders all use these rules
/// (shared/overview-cases.json). There is no second ledger.
library;

import 'dart:math' show pow;

import '../core/money.dart';
import 'balances.dart';
import 'models.dart';
import 'settlement.dart';

/// Person key of [m] in group [groupId]: the userId if linked; `g:<groupId>` for a friend group's placeholder;
/// `m:<memberId>` for a placeholder in a normal group.
String personKey(String groupId, GroupState s, Member m) => m.userId ?? (s.isFriend ? 'g:$groupId' : 'm:${m.id}');

/// Whether [key] is a person on Evensies (a userId), not a placeholder.
bool isLinkedKey(String key) => !key.startsWith('g:') && !key.startsWith('m:');

class GroupLedger {
  final String groupId;

  /// The member new payments use: my active member, else my first one in state order.
  final String myMemberId;

  /// memberId → person key, for every member (mine included).
  final Map<String, String> personOf;

  /// currency → groupTransfers(state)[currency]: what Settle up shows, unconverted buckets included.
  final Map<String, List<Transfer>> transfers;
  const GroupLedger({required this.groupId, required this.myMemberId, required this.personOf, required this.transfers});

  /// My person key (my userId).
  String get me => personOf[myMemberId]!;

  /// Null if no member has [myUserId].
  static GroupLedger? of({required String groupId, required GroupState state, required String myUserId}) {
    final mine = state.members.where((m) => m.userId == myUserId).toList();
    if (mine.isEmpty) return null;
    final res = balancesOf(state);
    return GroupLedger(
      groupId: groupId,
      myMemberId: (mine.where((m) => !m.removed).firstOrNull ?? mine.first).id,
      personOf: {for (final m in state.members) m.id: personKey(groupId, state, m)},
      transfers: res.transfers(simplify: state.simplifyDebts),
    );
  }
}

class Overview {
  /// person → currency → amount (+ they owe me, − I owe them).
  final Map<String, Map<String, int>> people;

  /// person → groupId → currency → amount.
  final Map<String, Map<String, Map<String, int>>> byGroup;

  /// currency → total; no zero entries.
  final Map<String, int> owedToMe, iOwe;
  const Overview({this.people = const {}, this.byGroup = const {}, this.owedToMe = const {}, this.iOwe = const {}});
  static const empty = Overview();
}

/// docs/API.md 개요 rules 1–5: every member of mine counts as me (removed ones too); a transfer between two of mine or
/// between two others is ignored; no conversion, no rounding; zeros dropped.
Overview computeOverview(List<GroupLedger> ledgers) {
  final people = <String, Map<String, int>>{};
  final byGroup = <String, Map<String, Map<String, int>>>{};
  void add(String person, String groupId, String currency, int v) {
    final p = people.putIfAbsent(person, () => {});
    p[currency] = (p[currency] ?? 0) + v;
    final g = byGroup.putIfAbsent(person, () => {}).putIfAbsent(groupId, () => {});
    g[currency] = (g[currency] ?? 0) + v;
  }

  for (final l in ledgers) {
    final me = l.me;
    for (final MapEntry(key: cur, value: ts) in l.transfers.entries) {
      for (final t in ts) {
        final a = l.personOf[t.from], b = l.personOf[t.to];
        if (a == null || b == null || (a == me) == (b == me)) continue;
        b == me ? add(a, l.groupId, cur, t.amount) : add(b, l.groupId, cur, -t.amount);
      }
    }
  }
  Map<String, int> nonZero(Map<String, int> m) => {for (final e in m.entries) if (e.value != 0) e.key: e.value};
  final p2 = {
    for (final e in people.entries)
      if (nonZero(e.value) case final m when m.isNotEmpty) e.key: m,
  };
  final g2 = <String, Map<String, Map<String, int>>>{};
  for (final MapEntry(key: person, value: groups) in byGroup.entries) {
    final kept = {
      for (final e in groups.entries)
        if (nonZero(e.value) case final m when m.isNotEmpty) e.key: m,
    };
    if (kept.isNotEmpty) g2[person] = kept;
  }
  final owed = <String, int>{}, owe = <String, int>{};
  for (final amounts in p2.values) {
    for (final MapEntry(key: c, value: v) in amounts.entries) {
      if (v > 0) owed[c] = (owed[c] ?? 0) + v;
      if (v < 0) owe[c] = (owe[c] ?? 0) - v;
    }
  }
  return Overview(people: p2, byGroup: g2, owedToMe: owed, iOwe: owe);
}

/// One person on the Friends tab (docs/API.md 개요 화면).
class Person {
  final String key;
  final String name;

  /// Null for a placeholder.
  final String? userId;

  /// The normal group of an `m:` placeholder (its subtitle).
  final String? groupId;

  /// Their friend groups, smallest id first: new non-group expenses go to the first one.
  final List<String> friendGroups;

  /// currency → amount (+ they owe me); empty when settled.
  final Map<String, int> net;
  const Person({
    required this.key,
    required this.name,
    this.userId,
    this.groupId,
    this.friendGroups = const [],
    this.net = const {},
  });
  bool get settled => net.isEmpty;
  bool get owesMe => net.values.any((v) => v > 0);
  bool get iOweThem => net.values.any((v) => v < 0);
}

/// Everyone I share a group with, plus friends: every person key except me. A placeholder in a normal group (`m:`)
/// only while there is a balance with them. The name comes from the friend group (the smallest id), else from the
/// first shared group by name. [groups]: every group on this device.
List<Person> peopleOf(List<({String id, String name, GroupState state})> groups, Overview o, String myUserId) {
  final names = <String, String>{}, friendNames = <String, String>{};
  final friendGroups = <String, List<String>>{}, groupOf = <String, String>{}, userIds = <String, String?>{};
  final sorted = [...groups]..sort((a, b) {
      final n = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return n != 0 ? n : a.id.compareTo(b.id);
    });
  for (final g in sorted) {
    if (!g.state.members.any((m) => m.userId == myUserId)) continue;
    for (final m in g.state.members) {
      if (m.userId == myUserId) continue;
      final key = personKey(g.id, g.state, m);
      if (key.startsWith('m:') && !o.people.containsKey(key)) continue;
      names.putIfAbsent(key, () => m.name);
      userIds[key] = m.userId;
      if (key.startsWith('m:')) groupOf[key] = g.id;
      if (g.state.isFriend) {
        final list = friendGroups.putIfAbsent(key, () => []);
        list.add(g.id);
        list.sort();
        if (list.first == g.id) friendNames[key] = m.name;
      }
    }
  }
  return [
    for (final key in names.keys)
      Person(
        key: key,
        name: friendNames[key] ?? names[key]!,
        userId: userIds[key],
        groupId: groupOf[key],
        friendGroups: friendGroups[key] ?? const [],
        net: o.people[key] ?? const {},
      ),
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}

/// The currency shown for [amounts] (docs/API.md 개요 화면): the largest in EUR at the latest local rates
/// (|amount| / 10^digits / perEur[c], for sorting only); currencies without a rate go last, ties by code.
String largestCurrency(Map<String, int> amounts, Map<String, double>? perEur) {
  double? size(String c) {
    final r = perEur?[c];
    return r == null || !(r > 0) ? null : amounts[c]!.abs() / pow(10, Money.digits(c)) / r;
  }

  final cs = amounts.keys.toList()
    ..sort((a, b) {
      final x = size(a), y = size(b);
      if (x == null || y == null) return x != null ? -1 : y != null ? 1 : a.compareTo(b);
      final c = y.compareTo(x);
      return c != 0 ? c : a.compareTo(b);
    });
  return cs.first;
}

/// "owes you €12.00", "you owe $5.00", with `*` when there are several currencies; "settled up" when empty.
String personBalanceText(Map<String, int> net, Map<String, double>? perEur) {
  if (net.isEmpty) return 'settled up';
  final c = largestCurrency(net, perEur);
  final v = net[c]!;
  final m = formatMoney(v.abs(), c);
  return '${v > 0 ? 'owes you $m' : 'you owe $m'}${net.length > 1 ? '*' : ''}';
}

/// One Settle up transfer between me and a person, in one group and currency (docs/API.md 친구와 한 번에 정산).
class FriendLine {
  final String groupId;
  final String currency;
  final Transfer transfer;

  /// I pay (the transfer is from my member); otherwise they pay me.
  final bool iPay;
  const FriendLine({required this.groupId, required this.currency, required this.transfer, required this.iPay});
  int get signed => iPay ? -transfer.amount : transfer.amount;
}

/// Every transfer between me and [key] across [ledgers].
List<FriendLine> friendLines(Iterable<GroupLedger> ledgers, String key) => [
      for (final l in ledgers)
        for (final MapEntry(key: cur, value: ts) in l.transfers.entries)
          for (final t in ts)
            if ((l.personOf[t.from], l.personOf[t.to]) case (final a?, final b?)
                when (a == l.me && b == key) || (a == key && b == l.me))
              FriendLine(groupId: l.groupId, currency: cur, transfer: t, iPay: a == l.me),
    ];

/// currency → Σ what they owe me over [lines]; zero nets are kept (their lines still clear the groups).
Map<String, int> netByCurrency(List<FriendLine> lines) {
  final net = <String, int>{};
  for (final l in lines) {
    net[l.currency] = (net[l.currency] ?? 0) + l.signed;
  }
  return net;
}

/// The payments that settle [currency] with [key] (one per line, in its group and currency, with its from, to and
/// amount). A line I pay while the net says I owe follows Phase 1 (`sent` for a linked person); everything else
/// (what I receive, and offset lines where no money moves) is `confirmed`.
List<({String groupId, Payment payment})> settlePayments(List<FriendLine> lines, String key, String currency,
    {required String date, required String Function() newId}) {
  final mine = [for (final l in lines) if (l.currency == currency) l];
  final net = mine.fold(0, (a, l) => a + l.signed);
  return [
    for (final l in mine)
      (
        groupId: l.groupId,
        payment: Payment(
          id: newId(),
          fromMember: l.transfer.from,
          toMember: l.transfer.to,
          amount: l.transfer.amount,
          currency: currency,
          date: date,
          status: l.iPay && net < 0 && isLinkedKey(key) ? 'sent' : 'confirmed',
        ),
      ),
  ];
}
