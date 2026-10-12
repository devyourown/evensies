import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/domain/activity.dart';
import 'package:evensies/features/activity/activity_screen.dart';
import 'package:evensies/features/group_detail/group_detail_screen.dart';
import 'package:evensies/providers.dart';

import 'fakes.dart';

Map<String, dynamic> item(int seq, String kind, Map<String, dynamic> fields) =>
    {'groupId': 'g1', 'feedId': seq, 'seq': seq, 'kind': kind, 'createdAt': '2026-10-11T08:0$seq:00Z', ...fields};

void main() {
  late AppDatabase db;
  late FakeApi api;

  setUpAll(() => Money.loadFromJson('{"decimals":{"EUR":2},"symbols":{"EUR":"€","USD":"\$","GBP":"£","JPY":"¥","KRW":"₩"}}'));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    api = FakeApi(db);
    await db.upsertGroup(const GroupRow(kind: 'group', type: 'other', deleted: false, id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 9, myMemberId: 'm1', simplifyDebts: true));
    await db.into(db.members).insert(MembersCompanion.insert(id: 'm1', groupId: 'g1', name: 'Anna'));
    await db.into(db.members).insert(MembersCompanion.insert(id: 'm2', groupId: 'g1', name: 'Ben'));
    await db.into(db.expenses).insert(ExpensesCompanion.insert(
        id: 'x1',
        groupId: 'g1',
        description: 'Taxi',
        amount: 1800,
        currency: 'EUR',
        paidBy: 'm2',
        date: '2026-10-11',
        deleted: const Value(true)));
  });
  tearDown(() => db.close());

  Widget app({Widget home = const Scaffold(body: ActivityList(groupId: 'g1'))}) => ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          apiProvider.overrideWithValue(api),
          syncProvider.overrideWithValue(NoSync(db)),
        ],
        child: MaterialApp(home: home),
      );

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 3; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pumpAndSettle();
    }
  }

  Future<void> unmount(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 10));
  }

  testWidgets('renders sentences with local names and restores a deleted expense', (t) async {
    api.onActivity = (_, _) => (
          items: [
            ActivityItem.fromJson(item(3, 'expense_deleted',
                {'actorMemberId': 'm2', 'expenseId': 'x1', 'description': 'Taxi', 'amount': 1800, 'currency': 'EUR'})),
            ActivityItem.fromJson(item(2, 'expense_added', {
              'actorMemberId': 'm2',
              'expenseId': 'x1',
              'description': 'Taxi',
              'amount': 1800,
              'currency': 'EUR',
              'myDelta': -900
            })),
            ActivityItem.fromJson(item(1, 'member_joined', {'actorMemberId': 'm1', 'memberId': 'm1'})),
          ],
          nextBefore: null,
        );
    await t.pumpWidget(app());
    await settle(t);

    expect(find.text('Ben deleted “Taxi”'), findsOneWidget);
    expect(find.text('Ben added “Taxi” · €18.00'), findsOneWidget);
    expect(find.textContaining('you owe €9.00', findRichText: true), findsOneWidget); // its own colored line
    expect(find.text('You joined'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Restore'), findsOneWidget);

    await t.tap(find.widgetWithText(TextButton, 'Restore'));
    await settle(t);
    expect((await t.runAsync(() => db.getExpense('x1')))!.deleted, isFalse);
    final out = (await t.runAsync(() => db.select(db.outbox).get()))!;
    expect(out.single.type, 'expense.restored');
    expect(jsonDecode(out.single.payloadJson), {'expenseId': 'x1'});
    expect(find.widgetWithText(TextButton, 'Restore'), findsNothing);
    await unmount(t);
  });

  testWidgets("a deleted payment's newest delete row offers Restore to its people; an edited one none; receipts",
      (t) async {
    await t.runAsync(() async {
      await db.saveSession(const SessionRow(id: 1, accessToken: 'a', refreshToken: 'r', userId: 'u1', displayName: 'Anna'));
      await (db.update(db.members)..where((m) => m.id.equals('m1'))).write(const MembersCompanion(userId: Value('u1')));
      for (final (id, replaced) in [('p1', false), ('p2', true)]) {
        await db.into(db.payments).insert(PaymentsCompanion.insert(
            id: id, groupId: 'g1', fromMember: 'm2', toMember: 'm1', amount: 1500, currency: 'EUR', date: '2026-10-11',
            deleted: const Value(true), replaced: Value(replaced)));
      }
    });
    Map<String, dynamic> pay(String id) =>
        {'actorMemberId': 'm2', 'paymentId': id, 'fromMember': 'm2', 'toMember': 'm1', 'amount': 1500, 'currency': 'EUR'};
    api.onActivity = (_, _) => (
          items: [
            ActivityItem.fromJson(item(7, 'receipt_removed', {'actorMemberId': 'm1', 'expenseId': 'x1', 'description': 'Taxi'})),
            ActivityItem.fromJson(item(6, 'receipt_added', {'actorMemberId': 'm2', 'expenseId': 'x1', 'description': 'Taxi'})),
            ActivityItem.fromJson(item(5, 'payment_deleted', pay('p1'))),
            ActivityItem.fromJson(item(4, 'payment_deleted', pay('p2'))),
            ActivityItem.fromJson(item(3, 'payment_restored', pay('p1'))),
            ActivityItem.fromJson(item(2, 'payment_deleted', pay('p1'))),
          ],
          nextBefore: null,
        );
    await t.pumpWidget(app());
    await settle(t);
    expect(find.text('You removed a receipt from “Taxi”'), findsOneWidget);
    expect(find.text('Ben added a receipt to “Taxi”'), findsOneWidget);
    expect(find.text('Ben restored a payment of €15.00 from Ben to you'), findsOneWidget);
    expect(find.byKey(const Key('restore-payment')), findsOneWidget); // p1's newest delete only; p2 was edited
    await t.tap(find.byKey(const Key('restore-payment')));
    await settle(t);
    final out = (await t.runAsync(() => db.select(db.outbox).get()))!.single;
    expect((out.type, out.payloadJson), ('payment.restored', '{"paymentId":"p1"}'));
    expect(find.byKey(const Key('restore-payment')), findsNothing);
    await unmount(t);
  });

  testWidgets('follows nextBefore until null, also across empty pages', (t) async {
    api.onActivity = (_, before) => switch (before) {
          null => (items: [ActivityItem.fromJson(item(9, 'member_joined', {'memberId': 'm2'}))], nextBefore: 9),
          9 => (items: <ActivityItem>[], nextBefore: 5),
          _ => (items: [ActivityItem.fromJson(item(1, 'group_created', {'actorMemberId': 'm1', 'name': 'Rome'}))], nextBefore: null),
        };
    await t.pumpWidget(app());
    await settle(t);
    expect(api.activityCalls, [('g1', null), ('g1', 9), ('g1', 5)]);
    expect(find.text('Ben joined'), findsOneWidget);
    expect(find.text('You created the group “Rome”'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('offline: shows the cached items, or a retry message without any', (t) async {
    await t.pumpWidget(app());
    await settle(t);
    expect(find.text('Activity needs a connection'), findsOneWidget);
    await unmount(t);

    api.onActivity = (_, _) => (items: [ActivityItem.fromJson(item(2, 'member_added', {'actorMemberId': 'm1', 'memberId': 'm2'}))], nextBefore: null);
    await t.pumpWidget(app());
    await settle(t);
    expect(find.text('You added Ben'), findsOneWidget);
    await unmount(t);

    api.onActivity = null; // offline again: the item comes from the drift cache
    await t.pumpWidget(app());
    await settle(t);
    expect(find.text('You added Ben'), findsOneWidget);
    expect(find.text('Showing saved activity. Pull to refresh.'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('pages in on scroll only, and a refresh keeps the pages already loaded', (t) async {
    ActivityItem created(int seq) => ActivityItem.fromJson(
        {'groupId': 'g1', 'feedId': seq, 'seq': seq, 'kind': 'group_created', 'name': 'G$seq', 'createdAt': '2026-10-11T08:00:00Z'});
    var top = 100;
    api.onActivity = (_, before) => before == null
        ? (items: [for (var s = top; s > top - 50; s--) created(s)], nextBefore: top - 49)
        : (items: [for (var s = before - 1; s > 0; s--) created(s)], nextBefore: null);
    await t.pumpWidget(app());
    await settle(t);
    expect(api.activityCalls, [('g1', null)]); // nothing more until the end of the list comes near

    await t.drag(find.byType(ListView), const Offset(0, -20000));
    await settle(t);
    expect(api.activityCalls, [('g1', null), ('g1', 51)]);

    top = 101; // a new event arrives: only the first page is fetched again
    await t.runAsync(() => db.upsertGroup(
        const GroupRow(kind: 'group', type: 'other', deleted: false, id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 10, myMemberId: 'm1', simplifyDebts: true)));
    await settle(t);
    expect(api.activityCalls, [('g1', null), ('g1', 51), ('g1', null)]);
    await t.drag(find.byType(ListView), const Offset(0, -40000));
    await settle(t);
    expect(find.text('Someone created the group “G1”'), findsOneWidget); // page 2 is still there
    expect(api.activityCalls.length, 3);
    await t.drag(find.byType(ListView), const Offset(0, 40000));
    await settle(t);
    expect(find.text('Someone created the group “G101”'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('an empty first page that is not the end keeps paging', (t) async {
    api.onActivity = (_, before) => before == null
        ? (items: <ActivityItem>[], nextBefore: 40)
        : (items: [ActivityItem.fromJson(item(1, 'member_added', {'actorMemberId': 'm1', 'memberId': 'm2'}))], nextBefore: null);
    await t.pumpWidget(app());
    await settle(t);
    expect(api.activityCalls, [('g1', null), ('g1', 40)]);
    expect(find.text('You added Ben'), findsOneWidget);
    expect(find.text('No activity yet'), findsNothing);
    await unmount(t);
  });

  testWidgets('only the newest delete of an expense offers Restore', (t) async {
    final deleted = {'actorMemberId': 'm2', 'expenseId': 'x1', 'description': 'Taxi', 'amount': 1800, 'currency': 'EUR'};
    api.onActivity = (_, _) => (
          items: [
            ActivityItem.fromJson(item(5, 'expense_deleted', deleted)),
            ActivityItem.fromJson(item(4, 'expense_restored', deleted)),
            ActivityItem.fromJson(item(3, 'expense_deleted', deleted)),
          ],
          nextBefore: null,
        );
    await t.pumpWidget(app());
    await settle(t);
    expect(find.text('Ben deleted “Taxi”'), findsNWidgets(2));
    expect(find.widgetWithText(TextButton, 'Restore'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('deleted, restored, then moved: the older delete row offers no Restore', (t) async {
    final x = {'actorMemberId': 'm2', 'expenseId': 'x1', 'description': 'Taxi', 'amount': 1800, 'currency': 'EUR'};
    api.onActivity = (_, _) => (
          items: [
            ActivityItem.fromJson(item(5, 'expense_moved', x)),
            ActivityItem.fromJson(item(4, 'expense_restored', x)),
            ActivityItem.fromJson(item(3, 'expense_deleted', x)),
          ],
          nextBefore: null,
        );
    await t.pumpWidget(app());
    await settle(t);
    expect(find.text('Ben deleted “Taxi”'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Restore'), findsNothing);
    await unmount(t);
  });

  testWidgets("a claimed placeholder friend's rows use the name the Friends tab shows", (t) async {
    await t.runAsync(() async {
      await db.saveSession(const SessionRow(id: 1, accessToken: 'a', refreshToken: 'r', userId: 'u-anna', displayName: 'Anna'));
      // The canonical friend group (smallest id names the person) and the placeholder's, claimed by Kofi.
      for (final (gid, me, other, name) in [('ga', 'a1', 'a2', 'Kofi Mensah'), ('gz', 'z1', 'z2', 'Kofi M.')]) {
        await db.upsertGroup(GroupRow(
            type: 'other', deleted: false, kind: 'friend', id: gid, name: 'Anna & $name', defaultCurrency: 'EUR', latestSeq: 3, myMemberId: me,
            simplifyDebts: true));
        await db.into(db.members).insert(MembersCompanion.insert(id: me, groupId: gid, name: 'Anna', userId: const Value('u-anna')));
        await db.into(db.members).insert(MembersCompanion.insert(id: other, groupId: gid, name: name, userId: const Value('u-kofi')));
      }
    });
    api.onActivity = (_, _) => (
          items: [ActivityItem.fromJson({...item(4, 'member_joined', {'memberId': 'z2'}), 'groupId': 'gz'})],
          nextBefore: null,
        );
    await t.pumpWidget(app(home: const Scaffold(body: ActivityList())));
    await settle(t);
    expect(find.text('Kofi Mensah joined'), findsOneWidget);
    expect(find.textContaining('Non-group · Kofi Mensah', findRichText: true), findsOneWidget);
    expect(find.textContaining('Kofi M.', findRichText: true), findsNothing);
    await unmount(t);
  });

  testWidgets('payment and member rows open Settle up and Members', (t) async {
    api.onActivity = (_, _) => (
          items: [
            ActivityItem.fromJson(item(3, 'payment_added',
                {'paymentId': 'p1', 'fromMember': 'm2', 'toMember': 'm1', 'amount': 2400, 'currency': 'EUR', 'status': 'sent'})),
            ActivityItem.fromJson(item(2, 'member_added', {'actorMemberId': 'm1', 'memberId': 'm2'})),
          ],
          nextBefore: null,
        );
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: ActivityList(groupId: 'g1'))),
      GoRoute(path: '/groups/:id/settle', builder: (_, s) => Text('settle ${s.pathParameters['id']}')),
      GoRoute(path: '/groups/:id/members', builder: (_, s) => Text('members ${s.pathParameters['id']}')),
    ]);
    await t.pumpWidget(ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
        apiProvider.overrideWithValue(api),
        syncProvider.overrideWithValue(NoSync(db)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await settle(t);
    await t.tap(find.text('Ben paid you €24.00 · waiting for you to confirm'));
    await settle(t);
    expect(find.text('settle g1'), findsOneWidget);
    router.pop();
    await settle(t);
    await t.tap(find.text('You added Ben'));
    await settle(t);
    expect(find.text('members g1'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('a payment on this device opens its page, also from a comment on it; a moved expense has no Restore',
      (t) async {
    await t.runAsync(() => db.into(db.payments).insert(PaymentsCompanion.insert(
        id: 'p1', groupId: 'g1', fromMember: 'm2', toMember: 'm1', amount: 2400, currency: 'EUR', date: '2026-10-11')));
    api.onActivity = (_, _) => (
          items: [
            ActivityItem.fromJson(item(4, 'expense_moved',
                {'actorMemberId': 'm2', 'expenseId': 'x1', 'description': 'Taxi', 'amount': 1800, 'currency': 'EUR'})),
            ActivityItem.fromJson(item(3, 'comment_added', {
              'actorMemberId': 'm2', 'commentId': 'c1', 'paymentId': 'p1', 'fromMember': 'm2', 'toMember': 'm1',
              'amount': 2400, 'currency': 'EUR', 'text': 'Sent!',
            })),
          ],
          nextBefore: null,
        );
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: ActivityList(groupId: 'g1'))),
      GoRoute(
          path: '/groups/:id/payments/:pid',
          builder: (_, s) => Text('payment ${s.pathParameters['id']} ${s.pathParameters['pid']}')),
    ]);
    await t.pumpWidget(ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
        apiProvider.overrideWithValue(api),
        syncProvider.overrideWithValue(NoSync(db)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await settle(t);
    expect(find.text('Ben moved “Taxi” to another group'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Restore'), findsNothing);
    await t.tap(find.text('Ben commented on a payment of €24.00 from Ben to you: Sent!'));
    await settle(t);
    expect(find.text('payment g1 p1'), findsOneWidget);
    await unmount(t);
  });

  test("receipts fold: one person's run on one expense is one row; those added with the expense show none", () {
    ActivityItem a(int seq, String kind, String actor, String expense, {String at = '2026-10-11T10:00:00Z'}) =>
        ActivityItem.fromJson(
            {'seq': seq, 'kind': kind, 'actorMemberId': actor, 'expenseId': expense, 'createdAt': at});
    final rows = foldReceipts([
      // Newest first.
      a(9, 'receipt_added', 'm2', 'x2'),
      a(8, 'receipt_added', 'm2', 'x2'),
      a(7, 'receipt_added', 'm2', 'x2'),
      a(6, 'receipt_removed', 'm2', 'x2'),
      a(5, 'receipt_added', 'm1', 'x2'),
      a(4, 'receipt_added', 'm1', 'x1'),
      a(3, 'receipt_added', 'm1', 'x1'),
      a(2, 'expense_added', 'm1', 'x1'),
      a(1, 'receipt_added', 'm1', 'x1', at: '2026-10-09T10:00:00Z'), // another day
    ]);
    expect([for (final r in rows) (r.item.seq, r.count)], [(9, 3), (6, 1), (5, 1), (2, 1), (1, 1)]);
    expect(activityText(rows.first.item, {'m2': 'Sam'}, 'm1', count: 3), 'Sam added 3 receipts to “”');
  });

  test('day labels count calendar days, also across a DST change', () {
    String at(DateTime local) => local.toUtc().toIso8601String();
    final now = DateTime(2026, 3, 30, 10); // Europe: DST began on Sun 29 Mar
    expect(dayLabel(at(DateTime(2026, 3, 30, 0, 30)), now: now), 'Today');
    expect(dayLabel(at(DateTime(2026, 3, 29, 9)), now: now), 'Yesterday');
    expect(dayLabel(at(DateTime(2026, 3, 28, 23)), now: now), 'Sat, Mar 28');
    expect(dayLabel(at(DateTime(2026, 3, 29, 9)), now: DateTime(2026, 3, 31, 0, 10)), 'Sun, Mar 29');
  });

  testWidgets('opening and pulling to refresh also sync the group, so new names and expenses resolve', (t) async {
    final sync = _RecordingSync(db);
    api.onActivity = (_, _) => (items: [ActivityItem.fromJson(item(2, 'member_added', {'actorMemberId': 'm1', 'memberId': 'm2'}))], nextBefore: null);
    await t.pumpWidget(ProviderScope(
      overrides: [dbProvider.overrideWithValue(db), apiProvider.overrideWithValue(api), syncProvider.overrideWithValue(sync)],
      child: const MaterialApp(home: Scaffold(body: ActivityList(groupId: 'g1'))),
    ));
    await settle(t);
    expect(sync.calls, ['g1']);
    await t.fling(find.text('You added Ben'), const Offset(0, 400), 1000);
    await settle(t);
    expect(sync.calls, ['g1', 'g1']);
    expect(api.activityCalls, [('g1', null), ('g1', null)]);
    await unmount(t);
  });

  testWidgets('empty feed', (t) async {
    api.onActivity = (_, _) => (items: <ActivityItem>[], nextBefore: null);
    await t.pumpWidget(app());
    await settle(t);
    expect(find.text('No activity yet'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('group screen opens on the Activity tab with ?tab=activity', (t) async {
    api.onActivity = (_, _) => (items: [ActivityItem.fromJson(item(2, 'member_added', {'actorMemberId': 'm2', 'memberId': 'm1'}))], nextBefore: null);
    await t.pumpWidget(app(home: const GroupDetailScreen(groupId: 'g1', tab: 'activity')));
    await settle(t);
    expect(find.text('Ben added you'), findsOneWidget);
    expect(DefaultTabController.of(t.element(find.byType(TabBar))).index, 2);
    await unmount(t);
  });
}

class _RecordingSync extends NoSync {
  _RecordingSync(super.db);
  final calls = <String>[];
  @override
  Future<void> sync(String groupId) async => calls.add(groupId);
}
