import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/features/group_settings/group_settings_screen.dart';
import 'package:evensies/features/settle/settle_screen.dart';
import 'package:evensies/providers.dart';

import 'fakes.dart';

void main() {
  late AppDatabase db;

  setUpAll(() => Money.loadFromJson('{"decimals":{"EUR":2,"USD":2}}'));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.upsertGroup(
      const GroupRow(
        id: 'g1',
        name: 'Rome',
        defaultCurrency: 'EUR',
        latestSeq: 0,
        myMemberId: 'm1',
        simplifyDebts: true,
      ),
    );
    for (final (id, name) in [('m1', 'Anna'), ('m2', 'Ben'), ('m3', 'Cara')]) {
      await db.into(db.members).insert(MembersCompanion.insert(id: id, groupId: 'g1', name: name));
    }
  });
  tearDown(() => db.close());

  Widget app(Widget home) => ProviderScope(
    overrides: [
      dbProvider.overrideWithValue(db),
      apiProvider.overrideWithValue(FakeApi(db)),
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

  Future<void> open(WidgetTester t, [Widget home = const GroupSettingsScreen(groupId: 'g1')]) async {
    t.view.physicalSize = const Size(800, 2000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app(home));
    await settle(t);
  }

  Future<void> unmount(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 10));
  }

  Future<List<Map<String, dynamic>>> sent(WidgetTester t) async => [
    for (final o in (await t.runAsync(() => db.select(db.outbox).get()))!)
      (jsonDecode(o.payloadJson) as Map).cast<String, dynamic>(),
  ];

  /// Anna paid [amount] for Ben alone.
  Future<void> expense(WidgetTester t, String id, int amount, {bool deleted = false, String forWhom = 'm2'}) =>
      t.runAsync(() async {
        await db
            .into(db.expenses)
            .insert(
              ExpensesCompanion.insert(
                id: id,
                groupId: 'g1',
                description: id,
                amount: amount,
                currency: 'EUR',
                paidBy: 'm1',
                date: '2026-10-11',
                deleted: Value(deleted),
              ),
            );
        await db
            .into(db.expenseShares)
            .insert(ExpenseSharesCompanion.insert(expenseId: id, memberId: forWhom, amount: amount));
      });

  ListTile tile(WidgetTester t, String key) => t.widget<ListTile>(find.byKey(Key(key)));

  testWidgets('currency can change while the group is empty, and is locked by any expense, deleted ones too', (
    t,
  ) async {
    await open(t);
    expect(find.text('Balances and payments use it'), findsOneWidget);
    await t.tap(find.byKey(const Key('currency')));
    await settle(t);
    await t.tap(find.text('USD').last);
    await settle(t);
    expect(await sent(t), [
      {'defaultCurrency': 'USD'},
    ]);
    expect((await t.runAsync(() => db.getGroup('g1')))!.defaultCurrency, 'USD');
    await unmount(t);

    await t.runAsync(
      () => db
          .into(db.payments)
          .insert(
            PaymentsCompanion.insert(
              id: 'p1',
              groupId: 'g1',
              fromMember: 'm2',
              toMember: 'm1',
              amount: 500,
              currency: 'USD',
              date: '2026-10-11',
            ),
          ),
    );
    await open(t);
    expect(find.text("Can't change after the first expense or payment"), findsOneWidget);
    await unmount(t);

    await t.runAsync(() => db.delete(db.payments).go());
    await expense(t, 'x1', 500, deleted: true);
    await open(t);
    expect(find.text("Can't change after the first expense or payment"), findsOneWidget);
    expect(t.widget<DropdownButton<String>>(find.byKey(const Key('currency'))).onChanged, isNull);
    await unmount(t);
  });

  testWidgets('simplify debts switch sends only that key', (t) async {
    await open(t);
    expect(find.textContaining('Combines debts so the group needs fewer payments'), findsOneWidget);
    await t.tap(find.byKey(const Key('simplify')));
    await settle(t);
    expect(await sent(t), [
      {'simplifyDebts': false},
    ]);
    expect(t.widget<SwitchListTile>(find.byKey(const Key('simplify'))).value, isFalse);
    await unmount(t);
  });

  testWidgets('leave is enabled only with a zero balance', (t) async {
    await expense(t, 'x1', 500);
    await open(t);
    expect(tile(t, 'leave').enabled, isFalse);
    expect(find.text('You are owed €5.00 · settle up first'), findsOneWidget);
    await unmount(t);

    await expense(t, 'x2', 500, forWhom: 'm1'); // Anna paid for herself: still owed 5
    await t.runAsync(
      () => db
          .into(db.payments)
          .insert(
            PaymentsCompanion.insert(
              id: 'p1',
              groupId: 'g1',
              fromMember: 'm2',
              toMember: 'm1',
              amount: 500,
              currency: 'EUR',
              date: '2026-10-11',
            ),
          ),
    );
    await open(t);
    expect(tile(t, 'leave').enabled, isTrue);
    expect(find.text('Your balance is settled'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('default split: percent saved from the sheet, "Use equal" clears it', (t) async {
    await open(t);
    expect(find.text('Equal · everyone'), findsOneWidget);
    await t.tap(find.byKey(const Key('default-split')));
    await settle(t);
    await t.enterText(find.byKey(const Key('share-m1')), '60');
    await t.pump();
    expect(t.widget<FilledButton>(find.byKey(const Key('save-split'))).enabled, isFalse);
    await t.enterText(find.byKey(const Key('share-m2')), '40');
    await t.pump();
    await t.tap(find.byKey(const Key('save-split')));
    await settle(t);
    expect(await sent(t), [
      {
        'defaultSplit': {
          'mode': 'percent',
          'input': {'m1': 60, 'm2': 40, 'm3': 0},
        },
      },
    ]);
    expect(find.text('Percent · Anna 60%, Ben 40%'), findsOneWidget);

    await t.tap(find.byKey(const Key('default-split')));
    await settle(t);
    expect(t.widget<TextField>(find.byKey(const Key('share-m1'))).controller!.text, '60'); // reopens with it
    await t.tap(find.byKey(const Key('use-equal')));
    await settle(t);
    expect((await sent(t)).last, {'defaultSplit': null});
    expect(find.text('Equal · everyone'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('rename sends the name', (t) async {
    await open(t);
    await t.tap(find.byKey(const Key('rename')));
    await settle(t);
    await t.enterText(find.byKey(const Key('name')), 'Rome 2026');
    await t.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(t);
    expect(await sent(t), [
      {'name': 'Rome 2026'},
    ]);
    expect(find.text('Rome 2026'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('rename counts UTF-16 units like the server: 51 emoji (102 units) cannot be saved, 50 can', (t) async {
    await open(t);
    await t.tap(find.byKey(const Key('rename')));
    await settle(t);
    bool canSave() => t.widget<FilledButton>(find.byKey(const Key('save-name'))).enabled;
    await t.enterText(find.byKey(const Key('name')), '😀' * 51);
    await t.pump();
    expect(find.text('102/100'), findsOneWidget);
    expect(find.text('Too long'), findsOneWidget);
    expect(canSave(), isFalse);
    await t.enterText(find.byKey(const Key('name')), '😀' * 50);
    await t.pump();
    expect(find.text('100/100'), findsOneWidget);
    expect(canSave(), isTrue);
    await t.tap(find.byKey(const Key('save-name')));
    await settle(t);
    expect(await sent(t), [
      {'name': '😀' * 50},
    ]);
    await unmount(t);
  });

  testWidgets('settle up lists debts as recorded when simplify debts is off', (t) async {
    await expense(t, 'x1', 1000); // Ben owes Anna 10
    await t.runAsync(() async {
      await db
          .into(db.expenses)
          .insert(
            ExpensesCompanion.insert(
              id: 'x2',
              groupId: 'g1',
              description: 'x2',
              amount: 1000,
              currency: 'EUR',
              paidBy: 'm2',
              date: '2026-10-11',
            ),
          );
      await db
          .into(db.expenseShares)
          .insert(ExpenseSharesCompanion.insert(expenseId: 'x2', memberId: 'm3', amount: 1000));
    }); // Cara owes Ben 10
    await open(t, const SettleScreen(groupId: 'g1'));
    expect(find.text('1 transfer settles everything'), findsOneWidget); // Cara → Anna
    await unmount(t);

    await t.runAsync(
      () => (db.update(
        db.groups,
      )..where((g) => g.id.equals('g1'))).write(const GroupsCompanion(simplifyDebts: Value(false))),
    );
    await open(t, const SettleScreen(groupId: 'g1'));
    expect(find.text('Debts as recorded · simplify debts is off'), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(2)); // Ben → Anna, Cara → Ben
    await unmount(t);
  });

  test('describeSplit names people with a share in member order, not people who left', () {
    const state = GroupState(
      members: [
        Member(id: 'm1', name: 'Anna'),
        Member(id: 'm2', name: 'Ben'),
        Member(id: 'm3', name: 'Cara', removed: true),
      ],
    );
    expect(describeSplit(null, state), 'Equal · everyone');
    expect(
      describeSplit(
        SplitSpec.fromJson({
          'mode': 'shares',
          'input': {'m3': 1, 'm2': 1.5, 'gone': 3, 'm1': 2},
        }),
        state,
      ),
      'Shares · Anna 2, Ben 1.5',
    );
  });

  testWidgets('a default split that no longer adds up after someone left says so', (t) async {
    await t.runAsync(() async {
      await (db.update(db.groups)..where((g) => g.id.equals('g1'))).write(
        const GroupsCompanion(defaultSplitJson: Value('{"mode":"percent","input":{"m3":25,"m2":25,"m1":50}}')),
      );
    });
    await open(t);
    expect(find.text('Percent · Anna 50%, Ben 25%, Cara 25%'), findsOneWidget);
    expect(find.byKey(const Key('split-stale')), findsNothing);
    await unmount(t);

    await t.runAsync(
      () =>
          (db.update(db.members)..where((m) => m.id.equals('m3'))).write(const MembersCompanion(removed: Value(true))),
    );
    await open(t);
    expect(find.text('Percent · Anna 50%, Ben 25%'), findsOneWidget);
    expect(find.text('No longer adds up · tap to fix'), findsOneWidget);
    await unmount(t);
  });
}
