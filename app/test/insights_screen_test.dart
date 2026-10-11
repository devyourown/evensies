import 'dart:io';

import 'package:drift/native.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/sync/group_state_store.dart';
import 'package:evensies/domain/categories.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/features/insights/insights_screen.dart';
import 'package:evensies/features/search/search_screen.dart';
import 'package:evensies/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fakes.dart';

void main() {
  late AppDatabase db;

  setUpAll(() {
    Money.loadFromJson(File('../shared/currencies.json').readAsStringSync());
    Categories.loadFromJson(File('../shared/categories.json').readAsStringSync());
  });

  Share s(String m, int a) => Share(memberId: m, amount: a);

  /// Members are m1 (me) and m2 in g1, '${id}m1' and '${id}m2' elsewhere (member ids are unique across groups).
  Future<void> addGroup(String id, String name, List<Expense> expenses) async {
    final p = id == 'g1' ? '' : id;
    await db.upsertGroup(
        GroupRow(id: id, name: name, defaultCurrency: 'EUR', latestSeq: 0, myMemberId: '${p}m1', simplifyDebts: true));
    await GroupStateStore(db).save(
      id,
      GroupState(
        name: name,
        defaultCurrency: 'EUR',
        members: [Member(id: '${p}m1', name: 'Anna'), Member(id: '${p}m2', name: 'Ben')],
        expenses: expenses,
        comments: [
          if (id == 'g1')
            const Comment(id: 'c1', expenseId: 'x2', authorMemberId: 'm2', text: 'Lidl near the station',
                createdAt: '2026-10-02T10:00:00Z'),
        ],
      ),
      0,
    );
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await addGroup('g1', 'Rome', [
      Expense(id: 'x1', description: 'Dinner', amount: 3000, currency: 'EUR', paidBy: 'm1', date: '2026-09-05',
          category: 'food.dining_out', shares: [s('m1', 1500), s('m2', 1500)]),
      Expense(id: 'x2', description: 'Groceries', amount: 1200, currency: 'EUR', paidBy: 'm2', date: '2026-10-02',
          category: 'food.groceries', notes: 'for the week', shares: [s('m1', 600), s('m2', 600)]),
      Expense(id: 'x3', description: 'Ramen', amount: 2000, currency: 'JPY', paidBy: 'm2', date: '2026-10-03',
          category: 'food.dining_out', shares: [s('m1', 1000), s('m2', 1000)]),
      Expense(id: 'x4', description: 'Taxi', amount: 1250, currency: 'EUR', paidBy: 'm1', date: '2026-10-04',
          category: 'transportation.taxi', notes: 'to the airport', shares: [s('m1', 625), s('m2', 625)]),
    ]);
    await addGroup('g2', 'Paris', [
      Expense(id: 'y1', description: 'Airport bus', amount: 900, currency: 'EUR', paidBy: 'g2m2', date: '2026-08-01',
          shares: [s('g2m1', 450), s('g2m2', 450)]),
    ]);
  });
  tearDown(() => db.close());

  Widget app(String location) => ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          apiProvider.overrideWithValue(FakeApi(db)),
          syncProvider.overrideWithValue(NoSync(db)),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(initialLocation: location, routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: Text('home')),
              routes: [
                GoRoute(
                  path: 'search',
                  builder: (_, st) => SearchScreen(
                    groupId: st.uri.queryParameters['group'],
                    category: st.uri.queryParameters['category'],
                    month: st.uri.queryParameters['month'],
                  ),
                ),
                GoRoute(path: 'groups/:id/insights', builder: (_, st) => InsightsScreen(groupId: st.pathParameters['id']!)),
                GoRoute(path: 'groups/:id/expenses/:eid', builder: (_, st) => Text('expense ${st.pathParameters['eid']}')),
              ],
            ),
          ]),
        ),
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

  void tall(WidgetTester t) {
    t.view.physicalSize = const Size(800, 2600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  String net(WidgetTester t, String cur) => t.widget<Text>(find.byKey(Key('net-$cur'))).data!;

  group('Insights', () {
    testWidgets('all time, then month by month; other currencies keep their own totals', (t) async {
      tall(t);
      await t.pumpWidget(app('/groups/g1/insights'));
      await settle(t);
      expect(find.text('€54.50'), findsOneWidget); // 30.00 + 12.00 + 12.50 spent in EUR
      expect(net(t, 'EUR'), '+€15.25'); // paid 42.50 − share 27.25
      expect(find.text('Not converted · JPY'), findsOneWidget);
      expect(find.text('¥2,000'), findsOneWidget);
      expect(net(t, 'JPY'), '−¥1,000');

      await t.tap(find.byTooltip('Previous month')); // the latest month is shown next to All time: back from Oct
      await settle(t);
      expect(find.text('Sep 2026'), findsOneWidget);
      expect(find.text('€30.00'), findsWidgets);
      expect(net(t, 'EUR'), '+€15.00');
      expect(find.text('Not converted · JPY'), findsNothing); // nothing in JPY that month

      await t.tap(find.byTooltip('Next month'));
      await settle(t);
      expect(find.text('Oct 2026'), findsOneWidget);
      expect(net(t, 'EUR'), '+€0.25'); // paid 12.50 − share 12.25

      await t.tap(find.byKey(const Key('period-all')));
      await settle(t);
      expect(net(t, 'EUR'), '+€15.25');

      await t.tap(find.byKey(const Key('bar-2026-09')));
      await settle(t);
      expect(net(t, 'EUR'), '+€15.00');
      await unmount(t);
    });

    testWidgets('a subcategory opens Search filtered to it, in the period shown', (t) async {
      tall(t);
      await t.pumpWidget(app('/groups/g1/insights'));
      await settle(t);
      await t.tap(find.byTooltip('Next month'), warnIfMissed: false); // disabled at the latest month
      await t.tap(find.byKey(const Key('period-month')));
      await settle(t);
      await t.tap(find.text('Food and drink'));
      await settle(t);
      await t.tap(find.byKey(const Key('cat-row-food.groceries')));
      await settle(t);
      // Search lists exactly the grocery expenses of the group that month.
      expect(find.text('Groceries'), findsWidgets);
      expect(find.text('1 expense'), findsOneWidget);
      expect(find.text('Rome'), findsOneWidget); // the removable group chip
      await unmount(t);
    });

    testWidgets('the largest text size fits: the period bar wraps, labels keep their width', (t) async {
      t.view.physicalSize = const Size(402, 874); // iPhone 16 Pro in points
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = 3.12; // iOS accessibility XXXL body text
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pumpWidget(app('/groups/g1/insights'));
      await settle(t); // an overflow fails the test
      expect(t.getSize(find.text('Total spent')).width, greaterThan(150)); // not one letter per line
      await t.tap(find.byKey(const Key('period-month')));
      await settle(t);
      final list = find.byType(Scrollable).first;
      await t.scrollUntilVisible(find.text('Food and drink'), 300, scrollable: list);
      await t.ensureVisible(find.text('Food and drink'));
      await settle(t);
      await t.tap(find.text('Food and drink'));
      await settle(t);
      // The amount wraps under the label instead of squeezing it.
      expect(t.getSize(find.text('Food and drink')).width, greaterThan(150));
      expect(t.getSize(find.text('Groceries')).width, greaterThan(150));
      await t.scrollUntilVisible(find.text('By person'), 300, scrollable: list);
      await settle(t);
      await unmount(t);
    });

    testWidgets('a date the server let through without a month counts in all time only', (t) async {
      tall(t);
      await t.runAsync(() => addGroup('g4', 'Far', [
            Expense(id: 'z1', description: 'Future', amount: 500, currency: 'EUR', paidBy: 'g4m1', date: '+10000-01-01',
                shares: [s('g4m1', 250), s('g4m2', 250)]),
            Expense(id: 'z2', description: 'Now', amount: 300, currency: 'EUR', paidBy: 'g4m1', date: '2026-10-01',
                shares: [s('g4m1', 150), s('g4m2', 150)]),
          ]));
      await t.pumpWidget(app('/groups/g4/insights'));
      await settle(t);
      expect(net(t, 'EUR'), '+€4.00'); // all time: both (paid 8.00 − share 4.00)
      expect(find.text('Oct 2026'), findsOneWidget);
      await t.pumpWidget(app('/search?group=g4&month=%2B10000-'));
      await settle(t);
      expect(find.text('+10000-'), findsOneWidget); // the month chip of a bad link, as it is
      expect(monthRange(['+10000-', '2026-11', '2026-09']), ['2026-09', '2026-10', '2026-11']);
      await unmount(t);
    });

    testWidgets('a group without expenses says so', (t) async {
      await t.runAsync(() => addGroup('g3', 'Empty', const []));
      await t.pumpWidget(app('/groups/g3/insights'));
      await settle(t);
      expect(find.text('Nothing to show yet'), findsOneWidget);
      await unmount(t);
    });
  });

  group('Search', () {
    testWidgets('finds by note across groups and shows the excerpt and the group', (t) async {
      tall(t);
      await t.pumpWidget(app('/search'));
      await settle(t);
      expect(find.text('Search expenses'), findsOneWidget);
      await t.enterText(find.byKey(const Key('search-input')), 'airport');
      await t.pump(const Duration(milliseconds: 200)); // 150 ms debounce
      await settle(t);
      expect(find.text('2 expenses'), findsOneWidget);
      expect(find.textContaining('Rome · “to the airport”'), findsOneWidget);
      expect(find.text('Airport bus'), findsOneWidget);

      await t.tap(find.text('Taxi'));
      await settle(t);
      expect(find.text('expense x4'), findsOneWidget);
      await unmount(t);
    });

    testWidgets('within one group, by comment and by amount; removing the group chip searches all groups', (t) async {
      tall(t);
      await t.pumpWidget(app('/search?group=g1'));
      await settle(t);
      Future<void> type(String q) async {
        await t.enterText(find.byKey(const Key('search-input')), q);
        await t.pump(const Duration(milliseconds: 200));
        await settle(t);
      }

      await type('station');
      expect(find.textContaining('“Lidl near the station”'), findsOneWidget);
      await type('12,50');
      expect(find.text('Taxi'), findsOneWidget);
      expect(find.text('1 expense'), findsOneWidget);
      await type('bus');
      expect(find.text('No matches'), findsOneWidget);
      await t.tap(find.byTooltip('Search all groups'));
      await settle(t);
      expect(find.text('Airport bus'), findsOneWidget);
      await unmount(t);
    });
  });
}
