import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../domain/balances.dart';
import '../../domain/models.dart';
import '../../domain/overview.dart';
import '../../providers.dart';
import '../group_detail/balances.dart' show groupStateProvider;

/// One local group with its state and balances (null while they can't be computed).
typedef HomeGroup = ({GroupRow row, GroupState state, BalanceResult? res});

/// Everything the Home tabs, the friend pages and the With picker read (docs/API.md 개요 화면).
class HomeData {
  final List<HomeGroup> groups;
  final Overview overview;
  final List<Person> people;
  final Map<String, GroupLedger> ledgers;

  /// Groups whose balances can't be computed yet: "{n} group(s) not included yet".
  final int notIncluded;
  final String? myUserId;
  const HomeData({
    required this.groups,
    required this.overview,
    required this.people,
    required this.ledgers,
    required this.notIncluded,
    required this.myUserId,
  });

  HomeGroup? group(String id) => groups.where((g) => g.row.id == id).firstOrNull;
  Person? person(String key) => people.where((p) => p.key == key).firstOrNull;

  /// Normal groups only (the Groups tab), by name like the database query.
  List<HomeGroup> get normalGroups => [for (final g in groups) if (g.row.kind != 'friend') g];

  /// The friend page key of a friend group: the other member's userId, or `g:<id>` for a placeholder friend.
  String? friendKey(String groupId) {
    final g = group(groupId);
    if (g == null || !g.state.isFriend) return null;
    final other = g.state.members.where((m) => m.userId != myUserId).firstOrNull;
    return other == null ? null : personKey(groupId, g.state, other);
  }

  /// "Rome", or "Non-group · Ben" for a friend group (exports, search, the overall feed), with the name the Friends tab
  /// shows (a claimed placeholder friend's group may still hold the placeholder's name).
  String label(String groupId) {
    final g = group(groupId);
    if (g == null) return '';
    if (!g.state.isFriend) return g.row.name;
    final other = g.state.members.where((m) => m.userId != myUserId).firstOrNull;
    return 'Non-group · ${friendName(groupId) ?? other?.name ?? g.row.name}';
  }

  /// The person's name of a friend group's other member, as on the Friends tab; null if unknown.
  String? friendName(String groupId) => switch (friendKey(groupId)) { final k? => person(k)?.name, null => null };
}

/// Recomputed from every local group on any change.
/// ponytail: full recompute; cache per group if someone has hundreds of groups.
final homeDataProvider = FutureProvider<HomeData>((ref) async {
  final me = ref.watch(sessionProvider.select((s) => s.value?.userId));
  final rows = await ref.watch(groupsProvider.future);
  final groups = <HomeGroup>[];
  for (final g in rows) {
    final state = await ref.watch(groupStateProvider(g.id).future);
    groups.add((row: g, state: state, res: balancesOf(state)));
  }
  final ledgers = <String, GroupLedger>{};
  var notIncluded = 0;
  if (me != null) {
    for (final g in groups) {
      final l = GroupLedger.of(groupId: g.row.id, state: g.state, myUserId: me);
      if (l != null) {
        ledgers[g.row.id] = l;
      } else if (g.state.members.any((m) => m.userId == me)) {
        notIncluded++;
      }
    }
  }
  final overview = computeOverview(ledgers.values.toList());
  return HomeData(
    groups: groups,
    overview: overview,
    people: me == null
        ? const []
        : peopleOf([for (final g in groups) (id: g.row.id, name: g.row.name, state: g.state)], overview, me),
    ledgers: ledgers,
    notIncluded: notIncluded,
    myUserId: me,
  );
});
