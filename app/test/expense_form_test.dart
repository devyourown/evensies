import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/features/expense_form/expense_form_screen.dart';
import 'package:evensies/providers.dart';

import 'fakes.dart';
import 'shared_json.dart';

void main() {
  late AppDatabase db;

  setUpAll(() => Money.loadFromJson('{"decimals":{"EUR":2,"KRW":0}}'));

  setUp(() async {
    loadShared('currencies.json'); // fail loudly if the shared dir is missing
    db = AppDatabase(NativeDatabase.memory());
    await db.upsertGroup(const GroupRow(id: 'g1', name: 'Trip', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'm1', simplifyDebts: true));
    await db.into(db.members).insert(MembersCompanion.insert(id: 'm1', groupId: 'g1', name: 'Anna'));
    await db.into(db.members).insert(MembersCompanion.insert(id: 'm2', groupId: 'g1', name: 'Ben', userId: const Value(null)));
  });
  tearDown(() => db.close());

  Widget app({String? expenseId}) => ProviderScope(
        overrides: [dbProvider.overrideWithValue(db), syncProvider.overrideWithValue(NoSync(db))],
        child: MaterialApp(home: ExpenseFormScreen(groupId: 'g1', expenseId: expenseId)),
      );

  // Dispose the tree inside the test so drift's stream-cancel timers fire before teardown.
  Future<void> unmount(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 10));
  }

  void tall(WidgetTester t) {
    t.view.physicalSize = const Size(800, 3000); // the whole form on screen
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  bool saveEnabled(WidgetTester t) => t.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save')).enabled;

  testWidgets('renders and enables Save after amount + description', (t) async {
    tall(t);
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    expect(find.text('New expense'), findsOneWidget);
    expect(saveEnabled(t), isFalse);

    await t.enterText(find.byKey(const Key('amount')), '12.50');
    await t.pump();
    expect(saveEnabled(t), isFalse);

    await t.enterText(find.byKey(const Key('description')), 'Pizza');
    await t.pump();
    expect(saveEnabled(t), isTrue);
    await unmount(t);
  });

  testWidgets('notes count UTF-16 units like the server, so emoji cannot slip past the counter', (t) async {
    t.view.physicalSize = const Size(800, 2400); // Save on screen
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('amount')), '5');
    await t.enterText(find.byKey(const Key('description')), 'Cake');
    await t.enterText(find.byKey(const Key('notes')), '🎂' * 251); // 251 characters, 502 UTF-16 units
    await t.pump();
    expect(find.text('Too long'), findsOneWidget);
    expect(find.text('502/500'), findsOneWidget);
    expect(saveEnabled(t), isFalse);

    await t.enterText(find.byKey(const Key('notes')), '🎂' * 250);
    await t.pump();
    expect(find.text('Too long'), findsNothing);
    expect(saveEnabled(t), isTrue);
    await unmount(t);
  });

  testWidgets('description stops at 200 UTF-16 units like the server', (t) async {
    t.view.physicalSize = const Size(800, 2400); // Save on screen
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('amount')), '5');
    await t.enterText(find.byKey(const Key('description')), '🎂' * 101); // 202 UTF-16 units
    await t.pump();
    expect(find.text('Too long'), findsOneWidget);
    expect(saveEnabled(t), isFalse);

    await t.enterText(find.byKey(const Key('description')), '🎂' * 100);
    await t.pump();
    expect(find.text('Too long'), findsNothing);
    expect(saveEnabled(t), isTrue);
    await unmount(t);
  });

  testWidgets('exact mode shows one field per member', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    expect(find.byKey(const Key('share-m1')), findsNothing);

    await t.tap(find.text('Exact'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('share-m1')), findsOneWidget);
    expect(find.byKey(const Key('share-m2')), findsOneWidget);
    await unmount(t);
  });

  testWidgets('a deleted expense shows its notes, cannot be saved and can be restored', (t) async {
    await db.into(db.expenses).insert(ExpensesCompanion.insert(
        id: 'x1',
        groupId: 'g1',
        description: 'Gelato',
        amount: 600,
        currency: 'EUR',
        paidBy: 'm1',
        date: '2026-10-10',
        notes: const Value('Pistachio'),
        deleted: const Value(true)));
    t.view.physicalSize = const Size(800, 2400); // whole form incl. comments on screen
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app(expenseId: 'x1'));
    await t.pumpAndSettle();
    expect(find.text('Deleted expense'), findsOneWidget);
    expect(find.text('Pistachio'), findsOneWidget);
    expect(find.text('Comments'), findsOneWidget);
    expect(saveEnabled(t), isFalse);
    expect(find.byTooltip('Delete'), findsNothing);
    bool paidBy(String name) => t.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, name)).selected;
    await t.tap(find.widgetWithText(ChoiceChip, 'Ben'), warnIfMissed: false); // read-only while deleted
    await t.pump();
    expect(paidBy('Anna'), isTrue);

    // A sync changed the row meanwhile: Restore shows the stored values, not what the form had.
    await t.runAsync(() => (db.update(db.expenses)..where((e) => e.id.equals('x1')))
        .write(const ExpensesCompanion(description: Value('Gelato x2'))));
    await t.tap(find.widgetWithText(FilledButton, 'Restore'));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await t.pumpAndSettle();
    expect(find.text('Edit expense'), findsOneWidget);
    expect(find.text('Gelato x2'), findsOneWidget);
    expect(saveEnabled(t), isTrue);
    await t.tap(find.widgetWithText(ChoiceChip, 'Ben'));
    await t.pump();
    expect(paidBy('Ben'), isTrue);
    expect((await t.runAsync(() => db.getExpense('x1')))!.deleted, isFalse);
    final out = (await t.runAsync(() => db.select(db.outbox).get()))!;
    expect(out.single.type, 'expense.restored');
    expect(jsonDecode(out.single.payloadJson), {'expenseId': 'x1'});
    await unmount(t);
  });

  testWidgets('the software keyboard does not cover the comment composer', (t) async {
    await db.into(db.expenses).insert(ExpensesCompanion.insert(
        id: 'x1', groupId: 'g1', description: 'Hotel', amount: 600, currency: 'EUR', paidBy: 'm1', date: '2026-10-10'));
    t.view.physicalSize = const Size(390, 844); // iPhone 13–16 in points
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app(expenseId: 'x1'));
    await t.pumpAndSettle();
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
    await t.enterText(input, 'Breakfast included');
    await t.pumpAndSettle();
    expect(t.getRect(input).bottom, lessThanOrEqualTo(844 - keyboard));
    await unmount(t);
  });
}
