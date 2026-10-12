import 'dart:convert';

import 'dart:io';

import 'package:drift/native.dart';
import 'package:evensies/core/env.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/data/api/dto.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/local_writes.dart';
import 'package:evensies/data/sync/group_state_store.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/domain/split.dart';
import 'package:evensies/features/expense_form/expense_form_screen.dart';
import 'package:evensies/domain/categories.dart';
import 'package:evensies/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Move an expense between groups and friends (docs/API.md 지출 옮기기).
void main() {
  Share s(String m, int a) => Share(memberId: m, amount: a);
  const source = [
    Member(id: 'a1', name: 'Anna', userId: 'u-anna'),
    Member(id: 'a2', name: 'Ben', userId: 'u-ben'),
    Member(id: 'a3', name: 'Cara'), // placeholder
    Member(id: 'a4', name: 'Dana', userId: 'u-dana'),
  ];
  const target = [
    Member(id: 'b1', name: 'Ben', userId: 'u-ben'),
    Member(id: 'b2', name: 'Anna', userId: 'u-anna'),
    Member(id: 'b3', name: 'Dana', userId: 'u-dana', removed: true),
  ];
  final e = Expense(
    id: 'x1',
    description: 'Hotel',
    amount: 3000,
    currency: 'USD',
    fxRateToDefault: 0.9,
    payers: [s('a2', 1000), s('a1', 2000)],
    date: '2026-10-11',
    category: 'travel.hotel',
    notes: 'Two nights',
    split: const SplitSpec(SplitMode.shares, {'a1': 1, 'a2': 2, 'a3': 0, 'a4': 0}),
    shares: [s('a1', 1000), s('a2', 2000), s('a3', 0), s('a4', 0)],
  );

  test('maps every involved member by user; zero entries and unmapped input keys are dropped', () {
    final m = remapForMove(e, source, target, id: 'y1', sameCurrency: true)!;
    expect(m.id, 'y1');
    expect([for (final p in m.payers) (p.memberId, p.amount)], [('b1', 1000), ('b2', 2000)]);
    expect(m.paidBy, 'b2'); // the largest payer (rule 10)
    expect([for (final x in m.shares) (x.memberId, x.amount)], [('b2', 1000), ('b1', 2000)]);
    expect(m.split, const SplitSpec(SplitMode.shares, {'b2': 1, 'b1': 2}));
    expect(m.split!.input!.containsKey('b3'), isFalse); // Dana's member there is removed
    expect((m.description, m.amount, m.currency, m.date, m.category, m.notes, m.refund),
        ('Hotel', 3000, 'USD', '2026-10-11', 'travel.hotel', 'Two nights', false));
    expect(m.fxRateToDefault, 0.9);
  });

  test('the rate stays only when both groups have the same default currency', () {
    expect(remapForMove(e, source, target, id: 'y1', sameCurrency: false)!.fxRateToDefault, isNull);
  });

  test('a placeholder or someone without an active member there blocks the move', () {
    expect(remapForMove(e.copyWith(shares: [s('a1', 1000), s('a3', 2000)]), source, target, id: 'y', sameCurrency: true),
        isNull);
    expect(remapForMove(e.copyWith(shares: [s('a1', 1000), s('a4', 2000)]), source, target, id: 'y', sameCurrency: true),
        isNull);
    expect(remapForMove(e, source, target.take(1).toList(), id: 'y', sameCurrency: true), isNull); // no Anna
  });

  group('LocalWrites.moveExpense', () {
    late AppDatabase db;
    late FakeApi api;
    late NoSync sync;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      api = FakeApi(db);
      sync = NoSync(db, api);
      await db.upsertGroup(const GroupRow(
          type: 'other', deleted: false, kind: 'group', id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'a1', simplifyDebts: true));
      await GroupStateStore(db).save('g1', GroupState(members: source, expenses: [e]), 0);
    });
    tearDown(() => db.close());

    test('pushes the new expense to the target first, then queues the delete with movedTo', () async {
      api.onPush = (g, events) => PushResult(seqByClientId: {for (final x in events) x.clientId: 9}, latestSeq: 9);
      final moved = remapForMove(e, source, target, id: 'y1', sameCurrency: false)!;
      await LocalWrites(db, sync).moveExpense('g1', e, 'g2', moved);
      final pushed = api.pushes.single.single;
      expect((pushed.type, pushed.payload['expenseId'], pushed.payload['paidBy']), ('expense.created', 'y1', 'b2'));
      final o = (await db.select(db.outbox).get()).single;
      expect((o.groupId, o.type), ('g1', 'expense.deleted'));
      expect(jsonDecode(o.payloadJson), {
        'expenseId': 'x1',
        'movedTo': {'groupId': 'g2', 'expenseId': 'y1'},
      });
      expect((await db.getExpense('x1'))!.deleted, isTrue);
      expect(sync.later, containsAll(['g1', 'g2']));
    });

    test('offline: nothing changes', () async {
      final moved = remapForMove(e, source, target, id: 'y1', sameCurrency: false)!;
      await expectLater(LocalWrites(db, sync).moveExpense('g1', e, 'g2', moved),
          throwsA(isA<MoveException>().having((x) => x.message, 'message', "Couldn't move it. Try again when you're online")));
      expect(await db.select(db.outbox).get(), isEmpty);
      expect((await db.getExpense('x1'))!.deleted, isFalse);
    });
  });

  /// The edit form of Rome's Taxi (EUR) with a friend group with Ben in [friendCurrency]; returns the API.
  Future<FakeApi> openForm(WidgetTester t, {String friendCurrency = 'EUR'}) async {
    Money.loadFromJson(File('../shared/currencies.json').readAsStringSync());
    Categories.loadFromJson(File('../shared/categories.json').readAsStringSync());
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final api = FakeApi(db)
      ..onPush = (g, events) => PushResult(seqByClientId: {for (final x in events) x.clientId: 4}, latestSeq: 4);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await t.runAsync(() async {
      await db.saveSession(const SessionRow(id: 1, accessToken: 'a', refreshToken: 'r', userId: 'u-anna', displayName: 'Anna'));
      await db.upsertGroup(const GroupRow(
          type: 'other', deleted: false, kind: 'group', id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'a1', simplifyDebts: true));
      await GroupStateStore(db).save('g1', GroupState(name: 'Rome', defaultCurrency: 'EUR', members: source, expenses: [
        Expense(id: 'x1', description: 'Taxi', amount: 2000, currency: 'EUR', paidBy: 'a1', date: '2026-10-11',
            shares: [s('a1', 1000), s('a2', 1000)]),
      ]), 0);
      await db.upsertGroup(GroupRow(
          type: 'other', deleted: false, kind: 'friend', id: 'gf', name: 'Anna & Ben', defaultCurrency: friendCurrency, latestSeq: 3, myMemberId: 'f1',
          simplifyDebts: true));
      await GroupStateStore(db).save('gf', GroupState(name: 'Anna & Ben', defaultCurrency: friendCurrency, kind: 'friend', members: const [
        Member(id: 'f1', name: 'Anna', userId: 'u-anna'),
        Member(id: 'f2', name: 'Ben', userId: 'u-ben'),
      ]), 3);
    });
    final router = GoRouter(initialLocation: '/edit', routes: [
      GoRoute(path: '/edit', builder: (_, _) => const ExpenseFormScreen(groupId: 'g1', expenseId: 'x1')),
      GoRoute(path: '/groups/:id', builder: (_, st) => Text('group ${st.pathParameters['id']}')),
    ]);
    t.view.physicalSize = const Size(800, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
        apiProvider.overrideWithValue(api),
        syncProvider.overrideWithValue(NoSync(db, api)),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await settleForm(t);
    return api;
  }

  testWidgets('editing: With → a friend moves the expense on Save', (t) async {
    final api = await openForm(t);
    expect(find.text('With Rome'), findsOneWidget);
    await t.tap(find.byKey(const Key('with')));
    await settleForm(t);
    await t.tap(find.byKey(const Key('with-u-ben')));
    await settleForm(t);
    expect(find.text('Moves to Non-group · Ben on Save'), findsOneWidget);
    await t.tap(find.widgetWithText(FilledButton, 'Save'));
    await settleForm(t);
    expect(find.text('group gf'), findsOneWidget);
    final pushed = api.pushes.single.single;
    expect([for (final x in (pushed.payload['shares'] as List)) x['memberId']], ['f1', 'f2']);
    expect(pushed.payload['fxRateToDefault'], isNull); // same currency
    final db = api.db;
    final o = (await t.runAsync(() => db.select(db.outbox).get()))!.single;
    expect((jsonDecode(o.payloadJson) as Map)['movedTo'], {'groupId': 'gf', 'expenseId': pushed.payload['expenseId']});
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 10));
  });

  testWidgets(
      "a retry after a failed move sends the same event plus an update with what was edited in between; another "
      "default currency gets the day's rate", (t) async {
    final api = await openForm(t, friendCurrency: 'USD');
    api.onFx = (_) => const FxTable(date: '2026-10-11', rates: {'EUR': 1, 'USD': 1.1});
    final ok = api.onPush!;
    api.onPush = (_, _) => throw const ApiException(code: 'NETWORK', message: 'timeout'); // stored, answer lost
    await t.tap(find.byKey(const Key('with')));
    await settleForm(t);
    await t.tap(find.byKey(const Key('with-u-ben')));
    await settleForm(t);
    await t.tap(find.widgetWithText(FilledButton, 'Save'));
    await settleForm(t);
    expect(find.text("Couldn't move it. Try again when you're online"), findsOneWidget);
    expect(api.pushes.single, hasLength(1)); // a first try: the create alone
    api.onPush = ok;
    await t.enterText(find.byKey(const Key('description')), 'Cab');
    await settleForm(t);
    await t.tap(find.widgetWithText(FilledButton, 'Save'));
    await settleForm(t);
    expect(find.text('group gf'), findsOneWidget);
    final first = api.pushes.first.single;
    final [second, update] = api.pushes.last;
    expect(second.clientId, first.clientId);
    expect(second.payload['expenseId'], first.payload['expenseId']);
    expect(second.payload['fxRateToDefault'], 1.1); // EUR in a USD friend group: converted, like a new expense
    // If the first try landed, the server drops the create as a duplicate; the update still brings "Cab".
    expect((update.type, update.payload['expenseId']), ('expense.updated', first.payload['expenseId']));
    expect(update.clientId, isNot(first.clientId));
    expect(update.payload['fields'], {...second.payload}..remove('expenseId'));
    expect((update.payload['fields'] as Map)['description'], 'Cab');
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 10));
  });
}

Future<void> settleForm(WidgetTester t) async {
  for (var i = 0; i < 3; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pumpAndSettle();
  }
}
