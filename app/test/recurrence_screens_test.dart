import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:evensies/core/env.dart';
import 'package:evensies/core/ids.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/local_writes.dart' show templateOf;
import 'package:evensies/data/receipts.dart';
import 'package:evensies/data/sync/group_state_store.dart';
import 'package:evensies/domain/activity.dart';
import 'package:evensies/domain/categories.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/domain/recurrence.dart';
import 'package:evensies/features/activity/activity_screen.dart';
import 'package:evensies/features/expense_detail/expense_detail_screen.dart';
import 'package:evensies/features/expense_form/expense_form_screen.dart';
import 'package:evensies/features/group_detail/group_detail_screen.dart';
import 'package:evensies/features/members/members_screen.dart';
import 'package:evensies/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

Expense rent(String id, {String date = '2026-10-01', int? n, String? series = 'r1', bool deleted = false}) => Expense(
      id: id,
      description: id == 'x9' ? 'Gym' : 'Rent',
      amount: 120000,
      currency: 'EUR',
      paidBy: 'm1',
      date: date,
      deleted: deleted,
      shares: const [Share(memberId: 'm1', amount: 60000), Share(memberId: 'm2', amount: 60000)],
      recurrenceId: series,
      occurrence: series == null ? null : n,
    );

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;

  setUpAll(() {
    Money.loadFromJson(File('../shared/currencies.json').readAsStringSync());
    Categories.loadFromJson(File('../shared/categories.json').readAsStringSync());
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await db.upsertGroup(const GroupRow(
        kind: 'group', id: 'g1', name: 'Flat', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'm2', simplifyDebts: true));
    // Rent, monthly since 1 Sep: the first expense, the server's repeat on 1 Oct, and Gym outside any series.
    await GroupStateStore(db).save(
      'g1',
      GroupState(
        name: 'Flat',
        defaultCurrency: 'EUR',
        members: const [Member(id: 'm1', name: 'Anna'), Member(id: 'm2', name: 'Ben')],
        expenses: [rent('x0', date: '2026-09-01', n: 0), rent('x1', n: 1), rent('x9', date: '2026-10-05', series: null)],
        recurrences: [
          Recurrence(
              id: 'r1', frequency: 'monthly', startDate: '2026-09-01', timeZone: '+02:00', template: templateOf(rent('x0'))),
        ],
      ),
      2,
    );
  });
  tearDown(() => db.close());

  Widget app(String location) => ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          syncProvider.overrideWithValue(NoSync(db)),
          apiProvider.overrideWithValue(FakeApi(db)),
          sharedPreferencesProvider.overrideWithValue(prefs),
          receiptFileProvider.overrideWith((ref, k) async => null),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(initialLocation: location, routes: [
            GoRoute(
              path: '/groups/g1',
              builder: (_, _) => const Scaffold(body: Text('group')),
              routes: [
                GoRoute(path: 'members', builder: (_, _) => const MembersScreen(groupId: 'g1')),
                GoRoute(path: 'expenses/new', builder: (_, _) => const ExpenseFormScreen(groupId: 'g1')),
                GoRoute(
                  path: 'expenses/:eid',
                  builder: (_, s) => ExpenseDetailScreen(groupId: 'g1', expenseId: s.pathParameters['eid']!),
                  routes: [
                    GoRoute(
                        path: 'edit',
                        builder: (_, s) => ExpenseFormScreen(groupId: 'g1', expenseId: s.pathParameters['eid'])),
                  ],
                ),
              ],
            ),
            GoRoute(
              path: '/tiles',
              builder: (_, _) => Consumer(builder: (context, ref, _) {
                final g = ref.watch(groupProvider('g1')).value;
                final names = {'m1': 'Anna', 'm2': 'Ben'};
                return Scaffold(
                  body: g == null
                      ? null
                      : ListView(children: [
                          for (final id in ['x1', 'x9'])
                            ExpenseTile(key: Key('tile-$id'), expense: rent(id, series: id == 'x9' ? null : 'r1'), group: g, names: names),
                          ActivityTile(
                            key: const Key('feed-series'),
                            groupId: 'g1',
                            item: ActivityItem.fromJson(const {
                              'seq': 9,
                              'kind': 'recurrence_updated',
                              'actorMemberId': 'm1',
                              'recurrenceId': 'r1',
                              'frequency': 'monthly',
                              'description': 'Rent',
                              'amount': 130000,
                              'currency': 'EUR',
                              'changes': [
                                {'field': 'amount', 'from': 120000, 'to': 130000}
                              ],
                            }),
                          ),
                          ActivityTile(
                            key: const Key('feed-repeat'),
                            groupId: 'g1',
                            item: ActivityItem.fromJson(const {
                              'seq': 8,
                              'kind': 'expense_repeated',
                              'createdAt': '2026-10-12T07:00:00Z', // caught up later
                              'expenseId': 'x1',
                              'recurrenceId': 'r1',
                              'frequency': 'monthly',
                              'description': 'Rent',
                              'amount': 120000,
                              'currency': 'EUR',
                              'myDelta': -60000,
                            }),
                          ),
                        ]),
                );
              }),
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
    t.view.physicalSize = const Size(800, 3000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  Future<List<(String, Map<String, dynamic>)>> outbox(WidgetTester t) async => [
        for (final o in (await t.runAsync(() => db.unsentOutbox('g1')))!)
          (o.type, (jsonDecode(o.payloadJson) as Map).cast<String, dynamic>())
      ];

  String next(String frequency, String start, {int minN = 1}) =>
      'Next: ${DateFormat.yMMMEd().format(DateTime.parse(firstOccurrenceOnOrAfter(frequency, start, todayIso(), minN: minN).date))}';

  /// The detail screen's next date: no year (always within one).
  String nextDay(String frequency, String start, {int minN = 1}) =>
      DateFormat.MMMEd().format(DateTime.parse(firstOccurrenceOnOrAfter(frequency, start, todayIso(), minN: minN).date));

  bool enabled(WidgetTester t, Key k) => t.widget<ButtonStyleButton>(find.byKey(k)).enabled;
  String repeatShown(WidgetTester t) =>
      t.widget<Text>(find.descendant(of: find.byKey(const Key('repeat')), matching: find.byType(Text))).data!;

  Future<void> pick(WidgetTester t, String label) async {
    await t.tap(find.byKey(const Key('repeat')));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(MenuItemButton, label));
    await t.pumpAndSettle();
  }

  Future<void> save(WidgetTester t) async {
    await t.pump(); // Save enables on the frame after the last typed field
    await t.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(t);
  }

  group('expense form', () {
    testWidgets('a new expense: Repeat → Every month shows the next date and saves a series with its first expense',
        (t) async {
      tall(t);
      await t.pumpWidget(app('/groups/g1/expenses/new'));
      await settle(t);
      expect(repeatShown(t), 'Never');
      expect(find.byKey(const Key('repeat-next')), findsNothing);
      await pick(t, 'Every month');
      expect(repeatShown(t), 'Every month');
      expect(find.text(next('monthly', todayIso())), findsOneWidget); // never today: that is the expense itself
      expect(find.byKey(const Key('repeat-future')), findsNothing);
      await t.enterText(find.byKey(const Key('amount')), '1200');
      await t.enterText(find.byKey(const Key('description')), 'Rent');
      await save(t);
      final out = await outbox(t);
      expect(out.map((o) => o.$1), ['recurrence.created', 'expense.created']);
      expect((out[0].$2['frequency'], out[0].$2['startDate']), ('monthly', todayIso()));
      expect((out[1].$2['recurrenceId'], out[1].$2['occurrence']), (out[0].$2['recurrenceId'], 0));
      expect(find.text('group'), findsOneWidget);
      await unmount(t);
    });

    testWidgets("an older repeat can't change the schedule: Repeat is off, with a hint naming the latest", (t) async {
      tall(t);
      await t.pumpWidget(app('/groups/g1/expenses/x0/edit'));
      await settle(t);
      expect(repeatShown(t), 'Every month');
      expect(enabled(t, const Key('repeat')), isFalse);
      expect(find.text('To change future repeats, edit the latest one (Oct 1)'), findsOneWidget);
      expect(find.byKey(const Key('repeat-future')), findsNothing);
      await t.enterText(find.byKey(const Key('description')), 'September rent');
      await save(t);
      final out = await outbox(t);
      expect(out.map((o) => o.$1), ['expense.updated']); // only this one
      await unmount(t);
    });

    testWidgets('the latest repeat carries a change forward while "Also change future repeats" is ticked', (t) async {
      tall(t);
      await t.pumpWidget(app('/groups/g1/expenses/x1/edit'));
      await settle(t);
      expect(enabled(t, const Key('repeat')), isTrue);
      expect(find.text(next('monthly', '2026-09-01', minN: 2)), findsOneWidget);
      expect(t.widget<CheckboxListTile>(find.byKey(const Key('repeat-future'))).value, isTrue);
      await t.enterText(find.byKey(const Key('description')), 'Rent + parking');
      await save(t);
      final out = await outbox(t);
      expect(out.map((o) => o.$1), ['expense.updated', 'recurrence.updated']);
      expect(out[1].$2, {
        'recurrenceId': 'r1',
        'fields': {'description': 'Rent + parking'}
      });
      await unmount(t);
    });

    testWidgets('unticked, only the latest repeat changes', (t) async {
      tall(t);
      await t.pumpWidget(app('/groups/g1/expenses/x1/edit'));
      await settle(t);
      await t.tap(find.byKey(const Key('repeat-future')));
      await t.pump();
      expect(find.text('Only this one changes'), findsOneWidget);
      await t.enterText(find.byKey(const Key('description')), 'Rent + parking');
      await save(t);
      expect((await outbox(t)).map((o) => o.$1), ['expense.updated']);
      await unmount(t);
    });

    testWidgets('Never on the latest repeat stops the series', (t) async {
      tall(t);
      await t.pumpWidget(app('/groups/g1/expenses/x1/edit'));
      await settle(t);
      await pick(t, 'Never');
      expect(find.text('Stops repeating. Repeats already added stay.'), findsOneWidget);
      expect(find.byKey(const Key('repeat-next')), findsNothing);
      await save(t);
      final out = await outbox(t);
      expect(out.map((o) => o.$1), ['recurrence.deleted']); // nothing else changed
      expect(out.single.$2, {'recurrenceId': 'r1'});
      await unmount(t);
    });

    testWidgets('another frequency on the latest repeat restarts the schedule from it', (t) async {
      tall(t);
      await t.pumpWidget(app('/groups/g1/expenses/x1/edit'));
      await settle(t);
      await pick(t, 'Every 2 weeks');
      expect(find.text(next('biweekly', '2026-10-01')), findsOneWidget);
      expect(find.byKey(const Key('repeat-future')), findsNothing); // a new schedule is always about the future
      await save(t);
      final out = await outbox(t);
      expect(out.map((o) => o.$1), ['recurrence.deleted', 'recurrence.created', 'expense.updated']);
      final created = out[1].$2;
      expect((created['frequency'], created['startDate'], (created['template'] as Map)['description']),
          ('biweekly', '2026-10-01', 'Rent'));
      expect(out[2].$2, {
        'expenseId': 'x1',
        'fields': {'recurrenceId': created['recurrenceId'], 'occurrence': 0}
      });
      await unmount(t);
    });

    testWidgets('an expense in no live series: Repeat starts one from it', (t) async {
      tall(t);
      await t.pumpWidget(app('/groups/g1/expenses/x9/edit'));
      await settle(t);
      expect(repeatShown(t), 'Never');
      expect(find.byKey(const Key('repeat-stop')), findsNothing);
      await pick(t, 'Every year');
      expect(find.text(next('yearly', '2026-10-05')), findsOneWidget);
      await save(t);
      final out = await outbox(t);
      expect(out.map((o) => o.$1), ['recurrence.created', 'expense.updated']);
      expect((out[0].$2['frequency'], out[0].$2['startDate']), ('yearly', '2026-10-05'));
      await unmount(t);
    });
  });

  group('expense detail', () {
    testWidgets('a repeat says how it repeats; Delete offers this one only', (t) async {
      tall(t);
      await t.pumpWidget(app('/groups/g1/expenses/x1'));
      await settle(t);
      expect(find.text('Repeats every month · next on ${nextDay('monthly', '2026-09-01', minN: 2)}'), findsOneWidget);
      await t.tap(find.byTooltip('Delete'));
      await t.pumpAndSettle();
      expect(find.text('Delete repeating expense?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(await outbox(t), isEmpty);
      await t.tap(find.byTooltip('Delete'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('delete-one')));
      await settle(t);
      expect((await outbox(t)).map((o) => o.$1), ['expense.deleted']);
      expect(find.text('Undo'), findsOneWidget);
      await unmount(t);
    });

    testWidgets('the latest repeat shows the next amount when future repeats changed; an older one no next', (t) async {
      tall(t);
      await t.runAsync(() => db.update(db.recurrences).write(RecurrencesCompanion(
          templateJson: Value(jsonEncode({...templateOf(rent('x0')), 'amount': 130000})))));
      await t.pumpWidget(app('/groups/g1/expenses/x1'));
      await settle(t);
      final day = nextDay('monthly', '2026-09-01', minN: 2);
      expect(find.text('Repeats every month · next €1,300.00 on $day'), findsOneWidget);
      await unmount(t);
      await t.pumpWidget(app('/groups/g1/expenses/x0'));
      await settle(t);
      expect(find.text('Repeats every month'), findsOneWidget);
      expect(find.textContaining('next '), findsNothing);
      await unmount(t);
    });

    testWidgets('Delete and stop repeating deletes it and stops the series', (t) async {
      tall(t);
      await t.pumpWidget(app('/groups/g1/expenses/x0'));
      await settle(t);
      await t.tap(find.byTooltip('Delete'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('delete-stop')));
      await settle(t);
      expect((await outbox(t)).map((o) => o.$1), ['expense.deleted', 'recurrence.deleted']);
      expect(find.text('Deleted “Rent” and stopped repeating'), findsOneWidget);
      expect(find.text('group'), findsOneWidget);
      await unmount(t);
    });

    testWidgets('an expense in no live series deletes as before', (t) async {
      tall(t);
      await t.pumpWidget(app('/groups/g1/expenses/x9'));
      await settle(t);
      expect(find.textContaining('Repeats'), findsNothing);
      await t.tap(find.byTooltip('Delete'));
      await t.pumpAndSettle();
      expect(find.text('Delete expense?'), findsOneWidget);
      expect(find.byKey(const Key('delete-stop')), findsNothing);
      await unmount(t);
    });
  });

  testWidgets('rows of a live series show the repeat mark; a series row in Activity opens its latest repeat',
      (t) async {
    tall(t);
    await t.pumpWidget(app('/tiles'));
    await settle(t);
    expect(find.descendant(of: find.byKey(const Key('tile-x1')), matching: find.byKey(const Key('repeat-mark'))),
        findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('tile-x9')), matching: find.byKey(const Key('repeat-mark'))),
        findsNothing);
    expect(find.text('Anna changed future “Rent”: €1,200.00 → €1,300.00'), findsOneWidget);
    expect(find.text('“Rent” · €1,200.00 was added (repeats monthly)'), findsOneWidget);
    expect(find.textContaining('you owe €600.00 · for Thu, Oct 1'), findsOneWidget);
    await t.tap(find.byKey(const Key('feed-series')));
    await settle(t);
    expect(find.text('Rent'), findsOneWidget); // x1's detail
    expect(find.textContaining('Oct 1, 2026'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('a stopped series: no repeat mark', (t) async {
    await t.runAsync(() => db.update(db.recurrences).write(const RecurrencesCompanion(deleted: Value(true))));
    tall(t);
    await t.pumpWidget(app('/tiles'));
    await settle(t);
    expect(find.byKey(const Key('repeat-mark')), findsNothing);
    await unmount(t);
  });

  testWidgets('removing someone still in a repeating expense says so', (t) async {
    tall(t);
    await t.pumpWidget(app('/groups/g1/members'));
    await settle(t);
    await t.tap(find.byTooltip('Remove'));
    await settle(t);
    expect(
        find.textContaining(
            "Anna is still in 1 repeating expense (Rent); they keep Anna's share until you edit the latest one."),
        findsOneWidget);
    await unmount(t);
  });
}
