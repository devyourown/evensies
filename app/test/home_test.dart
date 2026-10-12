import 'dart:io';

import 'package:drift/native.dart';
import 'package:evensies/core/env.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/data/api/dto.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/sync/group_state_store.dart';
import 'package:evensies/domain/activity.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/features/group_detail/group_detail_screen.dart' show ExpenseTile;
import 'package:evensies/providers.dart';
import 'package:evensies/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Home (Groups / Friends tabs), the overall card, filters and settled sections, a friend's page and settling with a
/// friend across groups (docs/API.md 개요 화면, 친구와 한 번에 정산), through the app's router.
void main() {
  late AppDatabase db;
  late FakeApi6 api;
  late NoSync sync;
  late SharedPreferences prefs;

  setUpAll(() => Money.loadFromJson(File('../shared/currencies.json').readAsStringSync()));

  Share s(String m, int a) => Share(memberId: m, amount: a);
  Expense x(String id, String paidBy, List<Share> shares, {String cur = 'EUR'}) => Expense(
      id: id, description: id, amount: shares.fold(0, (a, s) => a + s.amount), currency: cur, paidBy: paidBy,
      date: '2026-10-1${id.length % 9}', shares: shares);

  Future<void> group(String id, String name, String kind, String me, List<Member> members,
      {List<Expense> expenses = const [], List<Payment> payments = const []}) async {
    await db.upsertGroup(GroupRow(
        type: 'other', deleted: false, kind: kind, id: id, name: name, defaultCurrency: 'EUR', latestSeq: 0, myMemberId: me, simplifyDebts: true,
        inviteCode: 'INV$id'));
    await GroupStateStore(db).save(
        id,
        GroupState(
            name: name, defaultCurrency: 'EUR', kind: kind, members: members, expenses: expenses, payments: payments),
        0);
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    api = FakeApi6(db);
    sync = NoSync(db, api);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await db.saveSession(const SessionRow(
        id: 1, accessToken: 'a', refreshToken: 'r', userId: 'u-anna', displayName: 'Anna', homeCurrency: 'EUR'));
    // Rome: Ben paid the hotel for three; I owe Ben €30, Carlo (a placeholder) owes Ben, not me.
    await group('g-rome', 'Rome', 'group', 'r1', const [
      Member(id: 'r1', name: 'Anna', userId: 'u-anna'),
      Member(id: 'r2', name: 'Ben', userId: 'u-ben'),
      Member(id: 'r3', name: 'Carlo'),
    ], expenses: [x('hotel', 'r2', [s('r1', 3000), s('r2', 3000), s('r3', 3000)])]);
    // Non-group with Ben: I paid the taxi, Ben owes me €10.
    await group('g-ben', 'Anna & Ben', 'friend', 'f1', const [
      Member(id: 'f1', name: 'Anna', userId: 'u-anna'),
      Member(id: 'f2', name: 'Ben', userId: 'u-ben'),
    ], expenses: [x('taxi', 'f1', [s('f1', 1000), s('f2', 1000)])]);
    // Flat: settled with Dana.
    await group('g-flat', 'Flat', 'group', 'a1', const [
      Member(id: 'a1', name: 'Anna', userId: 'u-anna'),
      Member(id: 'a2', name: 'Dana', userId: 'u-dana'),
    ]);
    // Tokyo: Eva owes me ¥3,000 (not converted), I owe Eva €5.
    await group('g-jp', 'Tokyo', 'group', 'j1', const [
      Member(id: 'j1', name: 'Anna', userId: 'u-anna'),
      Member(id: 'j2', name: 'Eva', userId: 'u-eva'),
    ], expenses: [
      x('sushi', 'j1', [s('j2', 3000)], cur: 'JPY'),
      x('tea', 'j2', [s('j1', 500)]),
    ]);
  });
  tearDown(() => db.close());

  Widget app() => ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          apiProvider.overrideWithValue(api),
          syncProvider.overrideWithValue(sync),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: Consumer(builder: (_, ref, _) => MaterialApp.router(routerConfig: ref.watch(routerProvider))),
      );

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 4; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pumpAndSettle();
    }
  }

  Future<void> open(WidgetTester t) async {
    t.view.physicalSize = const Size(800, 2000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app());
    await settle(t);
  }

  Future<void> unmount(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 10));
  }

  testWidgets('Groups tab: the overall card, normal groups only, settled ones closed under Settled up', (t) async {
    await open(t);
    expect(find.text('Groups'), findsWidgets);
    expect(find.text('You are owed ¥3,000'), findsOneWidget);
    expect(find.text('You owe €25.00'), findsOneWidget); // Ben €30 − €10 non-group, and Eva €5
    expect(find.text('Rome'), findsOneWidget);
    expect(find.text('Tokyo'), findsOneWidget);
    expect(find.text('Anna & Ben'), findsNothing); // a friend group is a person
    expect(find.text('Settled up (1)'), findsOneWidget);
    expect(find.text('Flat'), findsNothing); // closed by default
    await t.tap(find.text('Settled up (1)'));
    await settle(t);
    expect(find.text('Flat'), findsOneWidget);

    await t.tap(find.byKey(const Key('filter-owesMe')));
    await settle(t);
    expect(find.text('Tokyo'), findsOneWidget);
    expect(find.text('Rome'), findsNothing);
    expect(find.text('Settled up (1)'), findsNothing);
    await t.tap(find.byKey(const Key('filter-iOwe')));
    await settle(t);
    expect(find.text('Rome'), findsOneWidget);
    expect(find.text('Tokyo'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('the overall card words the home-currency total as owe/owed, never as a minus amount', (t) async {
    // Net: Eva owes me ¥3,000 (€20.00 at 150), I owe €25.00 → I owe ≈ €5.00.
    t.view.physicalSize = const Size(800, 2000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
        apiProvider.overrideWithValue(api),
        syncProvider.overrideWithValue(sync),
        sharedPreferencesProvider.overrideWithValue(prefs),
        latestFxProvider.overrideWith((_) => Stream.value(const FxTable(date: '2026-10-11', rates: {'EUR': 1, 'JPY': 150}))),
      ],
      child: Consumer(builder: (_, ref, _) => MaterialApp.router(routerConfig: ref.watch(routerProvider))),
    ));
    await settle(t);
    expect(find.text('You owe ≈ €5.00 in total'), findsOneWidget);
    expect(find.textContaining('−'), findsNothing);
    await unmount(t);
  });

  test('members come by name, case-insensitively', () async {
    await group('g-abc', 'ABC', 'group', 'z', const [
      Member(id: 'z', name: 'zoe'),
      Member(id: 'b', name: 'Ben'),
      Member(id: 'a', name: 'anna'),
    ]);
    expect([for (final m in await db.watchMembers('g-abc').first) m.name], ['anna', 'Ben', 'zoe']);
  });

  testWidgets('Friends tab: everyone across groups, the largest currency then *, settled people closed', (t) async {
    await open(t);
    await t.tap(find.text('Friends').last);
    await settle(t);
    // Ben: €10 non-group minus €30 Rome. Eva: two currencies (no rates on this device: by code). Carlo owes Ben only.
    expect(find.text('you owe €20.00'), findsOneWidget);
    expect(find.text('you owe €5.00*'), findsOneWidget);
    expect(find.text('Carlo'), findsNothing);
    expect(find.text('Settled up (1)'), findsOneWidget);
    expect(find.text('Dana'), findsNothing);
    await t.tap(find.byKey(const Key('filter-owesMe')));
    await settle(t);
    expect(find.text('Eva'), findsOneWidget); // ¥3,000 owed to me
    expect(find.text('Ben'), findsNothing);
    await unmount(t);
  });

  testWidgets("a friend's page: the net, the balance per group, non-group expenses; Settle up records each line",
      (t) async {
    await open(t);
    await t.tap(find.text('Friends').last);
    await settle(t);
    await t.tap(find.text('Ben'));
    await settle(t);
    expect(find.text('You owe Ben €20.00'), findsOneWidget);
    expect(find.byKey(const Key('breakdown-non-group')), findsOneWidget);
    expect(find.byKey(const Key('together-non-group')), findsOneWidget); // the expenses' section
    expect(find.text('Ben owes you €10.00'), findsOneWidget); // the non-group row
    expect(find.text('you owe Ben €30.00'), findsOneWidget); // Rome
    expect(find.text('taxi'), findsOneWidget); // non-group expense list
    expect(find.byKey(const Key('friend-remind')), findsNothing); // Ben doesn't owe me overall

    await t.tap(find.byKey(const Key('friend-settle')));
    await settle(t);
    expect(find.text('Settle up with Ben'), findsOneWidget);
    expect(find.text('Non-group: Ben pays you €10.00'), findsOneWidget);
    expect(find.text('Rome: you pay Ben €30.00'), findsOneWidget);
    await t.tap(find.byKey(const Key('settle-EUR')));
    await settle(t);
    final ps = (await t.runAsync(() => db.select(db.payments).get()))!;
    expect({for (final p in ps) p.groupId: (p.fromMember, p.toMember, p.amount, p.currency, p.status)}, {
      'g-ben': ('f2', 'f1', 1000, 'EUR', 'confirmed'), // the offset line: no money moves
      'g-rome': ('r1', 'r2', 3000, 'EUR', 'sent'), // Ben confirms
    });
    expect(sync.later.toSet(), {'g-ben', 'g-rome'});
    await unmount(t);
  });

  testWidgets("a friend's page lists what we share in every group, by group; two friend groups are one section",
      (t) async {
    t.view.physicalSize = const Size(800, 3000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      // A claimed placeholder friend: a second friend group with Ben (docs/API.md 친구).
      await group('g-ben-old', 'Anna & Ben P.', 'friend', 'o1', const [
        Member(id: 'o1', name: 'Anna', userId: 'u-anna'),
        Member(id: 'o2', name: 'Ben P.', userId: 'u-ben'),
      ], expenses: [x('lunch', 'o1', [s('o2', 500)])]);
      // Ski: Ben and Dana share the fondue, I'm not in it.
      await group('g-ski', 'Ski', 'group', 'k1', const [
        Member(id: 'k1', name: 'Anna', userId: 'u-anna'),
        Member(id: 'k2', name: 'Ben', userId: 'u-ben'),
        Member(id: 'k3', name: 'Dana', userId: 'u-dana'),
      ], expenses: [x('fondue', 'k3', [s('k2', 800), s('k3', 800)])]);
    });
    await open(t);
    ProviderScope.containerOf(t.element(find.byType(Navigator).first)).read(routerProvider).push('/friends/u-ben');
    await settle(t);
    expect(find.text('You owe Ben €15.00'), findsOneWidget); // €10 + €5 non-group − €30 Rome
    expect(find.byKey(const Key('breakdown-non-group')), findsOneWidget);
    expect(find.text('Ben owes you €15.00'), findsOneWidget); // both friend groups in one line
    double y(Finder f) => t.getTopLeft(f).dy;
    // Non-group first (both friend groups), then Rome; Ski has nothing of ours (Ben and Dana only).
    final nonGroup = y(find.byKey(const Key('together-non-group'))), rome = y(find.byKey(const Key('together-g-rome')));
    expect(nonGroup < rome, isTrue);
    expect(find.byKey(const Key('together-g-ski')), findsNothing);
    expect(find.text('fondue'), findsNothing);
    for (final d in ['lunch', 'taxi']) {
      expect(y(find.text(d)), allOf(greaterThan(nonGroup), lessThan(rome)), reason: d);
    }
    expect(y(find.text('lunch')) < y(find.text('taxi')), isTrue); // newest first
    // Day headers in each section, like the group's list.
    expect(y(find.text('Thu, Oct 15').first), allOf(greaterThan(nonGroup), lessThan(y(find.text('lunch')))));
    expect(y(find.text('Wed, Oct 14').first),
        allOf(greaterThan(y(find.text('lunch'))), lessThan(y(find.text('taxi')))));
    expect(y(find.text('hotel')) > rome, isTrue); // Ben paid, I share
    expect(y(find.text('Thu, Oct 15').last), allOf(greaterThan(rome), lessThan(y(find.text('hotel'))))); // its day too
    expect(t.widget<ExpenseTile>(find.ancestor(of: find.text('hotel'), matching: find.byType(ExpenseTile))).extra, isNull);
    await t.tap(find.byKey(const Key('together-g-rome')));
    await settle(t);
    expect(find.text('Expenses'), findsOneWidget); // the group
    await unmount(t);
  });

  testWidgets('no friend group and no group we are both still in: no Add expense, the friend link instead', (t) async {
    final shared = <Object?>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'), (c) async {
      shared.add(c.arguments);
      return 'dev.fluttercommunity.plus/share/unavailable';
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('dev.fluttercommunity.plus/share'), null));
    api.code = (friendCode: 'K7P4QX', link: 'https://e.test/f/K7P4QX');
    // Dana left the Flat (her member is removed); I share nothing else with her.
    await t.runAsync(() => group('g-flat', 'Flat', 'group', 'a1', const [
          Member(id: 'a1', name: 'Anna', userId: 'u-anna'),
          Member(id: 'a2', name: 'Dana', userId: 'u-dana', removed: true),
        ]));
    await open(t);
    final router = ProviderScope.containerOf(t.element(find.byType(Navigator).first)).read(routerProvider);
    router.push('/friends/u-dana');
    await settle(t);
    expect(find.byKey(const Key('friend-add-expense')), findsNothing);
    expect(find.text('You no longer share a group with Dana. Send them your friend link to add expenses.'),
        findsOneWidget);
    await t.tap(find.byKey(const Key('share-friend-link')));
    await settle(t);
    expect(shared.toString(), contains('Add me on Evensies to split expenses: https://e.test/f/K7P4QX'));

    // Home's Add expense: the same words as a dialog.
    router.go('/expenses/new');
    await settle(t);
    await t.tap(find.text('Dana'));
    await settle(t);
    expect(find.byKey(const Key('no-shared-group')), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await settle(t);
    expect(api.friendCalls, isEmpty); // no POST /friends that would only answer 403
    await unmount(t);
  });

  testWidgets('a stale device: POST /friends answers 403, the friend link dialog instead of the error', (t) async {
    api.onAddFriend = (_) => throw const ApiException(status: 403, code: 'FORBIDDEN', message: 'Forbidden');
    await open(t);
    final router = ProviderScope.containerOf(t.element(find.byType(Navigator).first)).read(routerProvider);
    router.push('/friends/u-dana'); // still in the Flat on this device
    await settle(t);
    await t.tap(find.byKey(const Key('friend-add-expense')));
    await settle(t);
    expect(find.text('You no longer share a group with Dana. Send them your friend link to add expenses.'),
        findsOneWidget);
    expect(find.text('Forbidden'), findsNothing);
    await unmount(t);
  });

  testWidgets('Remind: sent, or why not', (t) async {
    await t.runAsync(() => group('g-ben2', 'Anna & Eva', 'friend', 'e1', const [
          Member(id: 'e1', name: 'Anna', userId: 'u-anna'),
          Member(id: 'e2', name: 'Eva', userId: 'u-eva'),
        ]));
    await open(t);
    await t.tap(find.text('Friends').last);
    await settle(t);
    await t.tap(find.text('Eva'));
    await settle(t);
    api.remindResult = const ApiException(status: 429, code: 'RATE_LIMITED', message: 'x');
    await t.tap(find.byKey(const Key('friend-remind')));
    await settle(t);
    expect(find.text('You can remind Eva again tomorrow'), findsOneWidget);
    expect(api.reminded, ['u-eva']);
    await t.pump(const Duration(seconds: 5));
    api.remindResult = const {'JPY': 3000};
    await t.tap(find.byKey(const Key('friend-remind')));
    await settle(t);
    expect(find.text('Reminder sent to Eva'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('a placeholder friend: Request and Invite, no Remind', (t) async {
    await t.runAsync(() => group('g-pf', 'Anna & Zoe', 'friend', 'z1', const [
          Member(id: 'z1', name: 'Anna', userId: 'u-anna'),
          Member(id: 'z2', name: 'Zoe'),
        ], expenses: [x('pizza', 'z1', [s('z2', 1200)])]));
    await open(t);
    await t.tap(find.text('Friends').last);
    await settle(t);
    expect(find.text('owes you €12.00\nnot on Evensies yet'), findsOneWidget);
    await t.tap(find.text('Zoe'));
    await settle(t);
    expect(find.byKey(const Key('friend-request')), findsOneWidget);
    expect(find.byKey(const Key('friend-invite')), findsOneWidget);
    expect(find.byKey(const Key('friend-remind')), findsNothing);
    await unmount(t);
  });

  testWidgets('/friends is the Friends tab', (t) async {
    await open(t);
    ProviderScope.containerOf(t.element(find.byType(Navigator).first)).read(routerProvider).go('/friends');
    await settle(t);
    expect(find.text('you owe €20.00'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('opening a friend group by its group link shows the friend page', (t) async {
    await open(t);
    final router = ProviderScope.containerOf(t.element(find.byType(Navigator).first)).read(routerProvider);
    router.go('/groups/g-ben');
    await settle(t);
    expect(find.text('You owe Ben €20.00'), findsOneWidget);
    await unmount(t);
  });

  testWidgets("a friend group's members or settings link (an activity row) shows the friend page, no Remove or Leave",
      (t) async {
    await open(t);
    final router = ProviderScope.containerOf(t.element(find.byType(Navigator).first)).read(routerProvider);
    for (final path in ['/groups/g-ben/members', '/groups/g-ben/settings']) {
      router.go(path);
      await settle(t);
      expect(find.text('You owe Ben €20.00'), findsOneWidget, reason: path);
      expect(find.text('Add placeholder member'), findsNothing);
      expect(find.text('Leave group'), findsNothing);
    }
    router.go('/groups/g-rome/members'); // a normal group keeps its screen
    await settle(t);
    expect(find.text('Add placeholder member'), findsOneWidget);
    await unmount(t);
  });

  testWidgets("a friend's page marks the friend group's unread items seen (it has no Activity tab)", (t) async {
    api.unread = const ActivityUnread(total: 1, groups: {'g-ben': 1});
    api.onActivity = (g, _) => (
          items: [
            if (g == 'g-ben')
              ActivityItem.fromJson(
                  {'feedId': 77, 'seq': 3, 'kind': 'friend_added', 'memberId': 'f1', 'createdAt': '2026-10-11T08:00:00Z'}),
          ],
          nextBefore: null,
        );
    await open(t);
    final c = ProviderScope.containerOf(t.element(find.byType(Navigator).first));
    await t.runAsync(() => c.read(unreadProvider.notifier).refresh());
    c.read(routerProvider).push('/groups/g-ben?tab=activity'); // what a friend_added push opens
    await settle(t);
    expect(find.text('You owe Ben €20.00'), findsOneWidget);
    expect(api.seenCalls, [(77, 'g-ben')]);
    await unmount(t);
  });

  testWidgets('Add expense asks with whom; a friend opens the friend group form', (t) async {
    await open(t);
    await t.tap(find.text('Add expense'));
    await settle(t);
    expect(find.text('Add expense · with whom?'), findsOneWidget);
    expect(find.byKey(const Key('with-u-ben')), findsOneWidget);
    expect(find.byKey(const Key('with-g-rome')), findsOneWidget);
    expect(find.byKey(const Key('with-g-ben')), findsNothing); // not as a group
    await t.tap(find.byKey(const Key('with-u-ben')));
    await settle(t);
    expect(find.text('New expense'), findsOneWidget);
    expect(find.text('With Non-group · Ben'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('a linked person without a friend group: the first expense creates it (online)', (t) async {
    api.onAddFriend = (body) => const GroupDto(
        id: 'g-dana', name: 'Anna & Dana', defaultCurrency: 'EUR', inviteCode: 'X', latestSeq: 3, myMemberId: 'd1',
        kind: 'friend');
    api.snap = (
      group: const GroupDto(
          id: 'g-dana', name: 'Anna & Dana', defaultCurrency: 'EUR', inviteCode: 'X', latestSeq: 3, myMemberId: 'd1',
          kind: 'friend'),
      state: const GroupState(name: 'Anna & Dana', defaultCurrency: 'EUR', kind: 'friend', members: [
        Member(id: 'd1', name: 'Anna', userId: 'u-anna'),
        Member(id: 'd2', name: 'Dana', userId: 'u-dana'),
      ]),
      latestSeq: 3,
    );
    await open(t);
    await t.tap(find.text('Add expense'));
    await settle(t);
    await t.tap(find.byKey(const Key('with-u-dana')));
    await settle(t);
    expect(api.friendCalls.single['userId'], 'u-dana');
    expect(api.friendCalls.single['defaultCurrency'], 'EUR');
    expect((await t.runAsync(() => db.getGroup('g-dana')))!.kind, 'friend');
    expect(find.text('With Non-group · Dana'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('the largest text size on a phone: tabs, a friend page and settling fit (no overflow)', (t) async {
    t.view.physicalSize = const Size(402, 874); // iPhone 16 Pro in points
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.textScaleFactorTestValue = 3.12; // iOS accessibility XXXL body text
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await t.pumpWidget(app());
    await settle(t); // an overflow fails the test
    await t.tap(find.text('Friends').last);
    await settle(t);
    await t.scrollUntilVisible(find.text('Ben'), 200, scrollable: find.byType(Scrollable).first);
    final router = ProviderScope.containerOf(t.element(find.byType(Navigator).first)).read(routerProvider);
    router.push('/friends/u-ben');
    await settle(t);
    expect(find.text('You owe Ben €20.00'), findsOneWidget);
    router.push('/friends/u-ben/settle');
    await settle(t);
    expect(find.byKey(const Key('settle-EUR')), findsOneWidget);
    await unmount(t);
  });
}
