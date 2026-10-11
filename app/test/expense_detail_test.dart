import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/sync/group_state_store.dart';
import 'package:evensies/domain/activity.dart';
import 'package:evensies/domain/categories.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/features/expense_detail/expense_detail_screen.dart';
import 'package:evensies/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fakes.dart';

Map<String, dynamic> item(int seq, String kind, Map<String, dynamic> fields) =>
    {'feedId': seq, 'seq': seq, 'kind': kind, 'createdAt': '2026-10-11T08:0$seq:00Z', ...fields};

void main() {
  late AppDatabase db;
  late FakeApi api;

  setUpAll(() {
    Money.loadFromJson('{"decimals":{"EUR":2}}');
    Categories.loadFromJson(File('../shared/categories.json').readAsStringSync());
  });

  Share s(String m, int a) => Share(memberId: m, amount: a);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    api = FakeApi(db);
    await db.upsertGroup(
        const GroupRow(id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'm1', simplifyDebts: true));
    await GroupStateStore(db).save(
      'g1',
      GroupState(
        name: 'Rome',
        defaultCurrency: 'EUR',
        members: const [Member(id: 'm1', name: 'Anna'), Member(id: 'm2', name: 'Ben'), Member(id: 'm3', name: 'Cara')],
        expenses: [
          Expense(
            id: 'x1',
            description: 'Hotel',
            amount: 30000,
            currency: 'EUR',
            payers: [s('m1', 20000), s('m2', 10000)],
            date: '2026-10-11',
            category: 'transportation.hotel',
            notes: 'Breakfast included',
            shares: [s('m1', 10000), s('m2', 10000), s('m3', 10000)],
          ),
          Expense(
            id: 'x2',
            description: 'Gelato',
            amount: 600,
            currency: 'EUR',
            paidBy: 'm2',
            date: '2026-10-11',
            category: 'food', // legacy free text that equals a parent key: shows General
            deleted: true,
            shares: [s('m2', 600)],
          ),
        ],
      ),
      0,
    );
  });
  tearDown(() => db.close());

  Widget app({String expenseId = 'x1', NoSync? sync}) => ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          apiProvider.overrideWithValue(api),
          syncProvider.overrideWithValue(sync ?? NoSync(db)),
        ],
        child: MaterialApp.router(
          // Nested: the group page is under the expense, so popping lands there.
          routerConfig: GoRouter(initialLocation: '/groups/g1/expenses/$expenseId', routes: [
            GoRoute(
              path: '/groups/g1',
              builder: (_, _) => const Scaffold(body: Text('group')),
              routes: [
                GoRoute(
                  path: 'expenses/:eid',
                  builder: (_, st) => ExpenseDetailScreen(groupId: 'g1', expenseId: st.pathParameters['eid']!),
                  routes: [GoRoute(path: 'edit', builder: (_, st) => Text('edit ${st.pathParameters['eid']}'))],
                ),
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
    t.view.physicalSize = const Size(800, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  testWidgets('shows who paid how much, each share, category and notes; Edit opens the form', (t) async {
    tall(t);
    await t.pumpWidget(app());
    await settle(t);
    expect(find.text('Hotel'), findsOneWidget);
    expect(find.text('€300.00'), findsOneWidget);
    expect(find.text('Hotel · Sun, 11 Oct 2026'), findsOneWidget); // category label · date
    expect(find.text('You paid €200.00 and owe €100.00'), findsOneWidget);
    expect(find.text('Ben paid €100.00 and owes €100.00'), findsOneWidget);
    expect(find.text('Cara owes €100.00'), findsOneWidget);
    expect(find.text('Breakfast included'), findsOneWidget);
    expect(find.text('Comments'), findsOneWidget);

    await t.tap(find.byTooltip('Edit'));
    await settle(t);
    expect(find.text('edit x1'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('History comes from the expense filter and is cached; items of other expenses are dropped', (t) async {
    tall(t);
    api.onActivity = (_, before) => (
          items: [
            ActivityItem.fromJson(item(3, 'comment_added',
                {'actorMemberId': 'm2', 'expenseId': 'x1', 'commentId': 'c1', 'description': 'Hotel', 'text': 'Nice'})),
            // An older server ignores expenseId: the app filters too.
            ActivityItem.fromJson(item(2, 'expense_added',
                {'actorMemberId': 'm2', 'expenseId': 'x2', 'description': 'Gelato', 'amount': 600, 'currency': 'EUR'})),
            ActivityItem.fromJson(item(1, 'expense_added',
                {'actorMemberId': 'm1', 'expenseId': 'x1', 'description': 'Hotel', 'amount': 30000, 'currency': 'EUR'})),
          ],
          nextBefore: null,
        );
    await t.pumpWidget(app());
    await settle(t);
    expect(api.activityExpenseIds, ['x1']);
    expect(find.text('Ben commented'), findsOneWidget); // the text itself is only in Comments
    expect(find.textContaining('Nice'), findsNothing);
    expect(find.text('You added “Hotel” · €300.00'), findsOneWidget);
    expect(find.textContaining('Gelato'), findsNothing);
    expect((await t.runAsync(() => db.select(db.activity).get()))!.length, 3);
    await unmount(t);
  });

  testWidgets('offline, History shows the cached rows of this expense', (t) async {
    tall(t);
    Future<void> cache(int seq, String expenseId, String description) => db.into(db.activity).insert(
        ActivityCompanion.insert(
            groupId: 'g1',
            seq: seq,
            feedId: seq,
            createdAt: '2026-10-11T08:0$seq:00Z',
            json: jsonEncode(item(seq, 'expense_updated', {
              'actorMemberId': 'm2',
              'expenseId': expenseId,
              'description': description,
              'currency': 'EUR',
              'changes': [
                {'field': 'amount', 'from': 28000, 'to': 30000},
              ],
            }))));
    await t.runAsync(() async {
      await cache(4, 'x1', 'Hotel');
      await cache(5, 'x2', 'Gelato');
    });
    await t.pumpWidget(app()); // onActivity unset = offline
    await settle(t);
    expect(find.text('Ben changed “Hotel”: €280.00 → €300.00'), findsOneWidget);
    expect(find.textContaining('Gelato'), findsNothing);
    expect(find.text('Showing saved history.'), findsOneWidget);
    await unmount(t);
  });

  test('payers keep the order sent through a load and save (a sync round), not memberId order', () async {
    final store = GroupStateStore(db);
    await store.save(
      'g2',
      GroupState(name: 'Lisbon', defaultCurrency: 'EUR', expenses: [
        Expense(id: 'y1', description: 'Hotel Alfama', amount: 30000, currency: 'EUR',
            payers: [s('m3', 18000), s('m1', 12000)], date: '2026-10-11', shares: [s('m3', 15000), s('m1', 15000)]),
      ]),
      0,
    );
    await store.save('g2', await store.load('g2'), 0);
    expect([for (final p in (await store.load('g2')).expense('y1')!.payers) p.memberId], ['m3', 'm1']);
  });

  testWidgets('pull to refresh syncs the group, so a remote edit shows without leaving', (t) async {
    final sync = _SyncSpy(db);
    await t.pumpWidget(app(sync: sync)); // the default 800×600 view: 400 px is past the pull threshold
    await settle(t);
    await t.fling(find.text('Hotel').first, const Offset(0, 400), 1000);
    await settle(t);
    expect(sync.synced, ['g1']);
    await unmount(t);
  });

  testWidgets('a deleted expense hides Edit and offers Restore', (t) async {
    tall(t);
    await t.pumpWidget(app(expenseId: 'x2'));
    await settle(t);
    expect(find.text('Deleted expense'), findsOneWidget);
    expect(find.text('General · Sun, 11 Oct 2026'), findsOneWidget);
    expect(find.byTooltip('Edit'), findsNothing);
    expect(find.byTooltip('Delete'), findsNothing);
    await t.tap(find.widgetWithText(FilledButton, 'Restore'));
    await settle(t);
    expect(find.byTooltip('Edit'), findsOneWidget);
    final out = (await t.runAsync(() => db.select(db.outbox).get()))!;
    expect(out.single.type, 'expense.restored');
    await unmount(t);
  });

  testWidgets('Delete asks, deletes, goes back and offers Undo', (t) async {
    tall(t);
    await t.pumpWidget(app());
    await settle(t);
    await t.tap(find.byTooltip('Delete'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(t);
    expect(find.text('group'), findsOneWidget);
    expect(find.text('Deleted “Hotel”'), findsOneWidget);
    expect((await t.runAsync(() => db.getExpense('x1')))!.deleted, isTrue);
    await unmount(t);
  });

  testWidgets('the software keyboard does not cover the comment composer', (t) async {
    t.view.physicalSize = const Size(390, 844); // iPhone 13–16 in points
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app());
    await settle(t);
    final input = find.byKey(const Key('comment-input'));
    await t.scrollUntilVisible(input, 200, scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(input);
    await t.pumpAndSettle();
    await t.tap(input);
    await t.pumpAndSettle();

    const keyboard = 336.0; // iPhone portrait keyboard with the suggestion bar
    t.view.viewInsets = const FakeViewPadding(bottom: keyboard);
    addTearDown(t.view.resetViewInsets);
    await t.pumpAndSettle();
    expect(t.getRect(input).bottom, lessThanOrEqualTo(844 - keyboard));
    expect(t.getRect(find.byTooltip('Send')).bottom, lessThanOrEqualTo(844 - keyboard));
    await unmount(t);
  });
}

class _SyncSpy extends NoSync {
  _SyncSpy(super.db);
  final synced = <String>[];
  @override
  Future<void> sync(String groupId) async => synced.add(groupId);
}
