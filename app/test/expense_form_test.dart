import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/core/currency_picker.dart';
import 'package:evensies/core/ids.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/data/api/dto.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/domain/categories.dart';
import 'package:evensies/domain/fx.dart';
import 'package:evensies/features/expense_form/expense_form_screen.dart';
import 'package:evensies/core/env.dart';
import 'package:evensies/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';
import 'shared_json.dart';

void main() {
  late AppDatabase db;
  late FakeApi api;
  late SharedPreferences prefs;

  setUpAll(() {
    Money.loadFromJson('{"decimals":{"EUR":2,"KRW":0,"JPY":0}}');
    Categories.loadFromJson(File('../shared/categories.json').readAsStringSync());
  });

  setUp(() async {
    loadShared('currencies.json'); // fail loudly if the shared dir is missing
    db = AppDatabase(NativeDatabase.memory());
    api = FakeApi(db);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await db.upsertGroup(const GroupRow(id: 'g1', name: 'Trip', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'm1', simplifyDebts: true));
    await db.into(db.members).insert(MembersCompanion.insert(id: 'm1', groupId: 'g1', name: 'Anna'));
    await db.into(db.members).insert(MembersCompanion.insert(id: 'm2', groupId: 'g1', name: 'Ben', userId: const Value(null)));
  });
  tearDown(() => db.close());

  Widget app({String? expenseId}) => ProviderScope(
        overrides: [
      dbProvider.overrideWithValue(db),
      syncProvider.overrideWithValue(NoSync(db)),
      apiProvider.overrideWithValue(api),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
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
    t.view.physicalSize = const Size(800, 2400); // the whole form on screen
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app(expenseId: 'x1'));
    await t.pumpAndSettle();
    expect(find.text('Deleted expense'), findsOneWidget);
    expect(find.text('Pistachio'), findsOneWidget);
    expect(find.text('Comments'), findsNothing); // on the read-only expense screen now
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

  group('categories', () {
    Future<void> guess(WidgetTester t) async {
      await t.pump(const Duration(milliseconds: 350)); // the 300 ms debounce
      await t.pumpAndSettle();
    }

    Map<String, dynamic> sentPayload(List<OutboxRow> rows) => (jsonDecode(rows.single.payloadJson) as Map).cast();
    bool auto() => find.byKey(const Key('category-auto')).evaluate().isNotEmpty;

    testWidgets('typing "Pizza" guesses Dining out, marked auto, and saves its key', (t) async {
      tall(t);
      await t.pumpWidget(app());
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('amount')), '20');
      await t.enterText(find.byKey(const Key('description')), 'Pizza at Luigi');
      await guess(t);
      expect(find.text('Dining out'), findsOneWidget);
      expect(auto(), isTrue);

      // Clearing the description clears the guess.
      await t.enterText(find.byKey(const Key('description')), '');
      await guess(t);
      expect(find.text('Dining out'), findsNothing);
      expect(auto(), isFalse);

      await t.enterText(find.byKey(const Key('description')), 'Pizza');
      await guess(t);
      await t.tap(find.widgetWithText(FilledButton, 'Save'));
      await t.pumpAndSettle();
      expect(sentPayload((await t.runAsync(() => db.select(db.outbox).get()))!)['category'], 'food.dining_out');
      await unmount(t);
    });

    testWidgets('at the largest text size the guessed category keeps its label; Refund wraps', (t) async {
      t.view.physicalSize = const Size(402, 874); // iPhone 16 Pro in points
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = 3.12; // iOS accessibility XXXL body text
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await t.pumpWidget(app());
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('description')), 'Uber');
      await guess(t); // an overflow fails the test
      expect(auto(), isTrue);
      expect(t.getSize(find.text('Taxi')).width, greaterThan(100));
      await unmount(t);
    });

    testWidgets('a picked category stays when the description changes afterwards', (t) async {
      tall(t);
      await t.pumpWidget(app());
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('description')), 'Uber');
      await guess(t);
      expect(find.text('Taxi'), findsOneWidget);
      await t.tap(find.byKey(const Key('category')));
      await t.pumpAndSettle();
      await t.scrollUntilVisible(find.byKey(const Key('category-transportation.hotel')), 100,
          scrollable: find.byType(Scrollable).last);
      await t.tap(find.byKey(const Key('category-transportation.hotel')));
      await t.pumpAndSettle();
      expect(find.text('Hotel'), findsOneWidget);
      expect(auto(), isFalse);

      await t.enterText(find.byKey(const Key('description')), 'Pizza');
      await guess(t);
      expect(find.text('Hotel'), findsOneWidget);
      expect(find.text('Dining out'), findsNothing);
      await unmount(t);
    });

    testWidgets("the group's history wins over keywords", (t) async {
      tall(t);
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
          id: 'x0', groupId: 'g1', description: 'Netflix', amount: 1299, currency: 'EUR', paidBy: 'm1',
          date: '2026-09-01', category: const Value('utilities.tv_phone_internet')));
      await t.pumpWidget(app());
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('description')), 'netflix ');
      await guess(t);
      expect(find.text('TV/Phone/Internet'), findsOneWidget);
      await unmount(t);
    });

    testWidgets('a legacy "Food" shows as General, is not guessed over and saves without a category field', (t) async {
      tall(t);
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
          id: 'x1', groupId: 'g1', description: 'Snacks', amount: 600, currency: 'EUR', paidBy: 'm1',
          date: '2026-10-10', category: const Value('Food')));
      await db.into(db.expenseShares).insert(ExpenseSharesCompanion.insert(expenseId: 'x1', memberId: 'm1', amount: 600));
      await t.pumpWidget(app(expenseId: 'x1'));
      await t.pumpAndSettle();
      expect(find.text('General'), findsOneWidget);
      await t.enterText(find.byKey(const Key('description')), 'Pizza');
      await guess(t);
      expect(find.text('Dining out'), findsNothing);
      await t.tap(find.widgetWithText(FilledButton, 'Save'));
      await t.pumpAndSettle();
      expect(sentPayload((await t.runAsync(() => db.select(db.outbox).get()))!)['fields'], {'description': 'Pizza'});
      expect((await t.runAsync(() => db.getExpense('x1')))!.category, 'Food');
      await unmount(t);
    });

    testWidgets('an expense stored without a category is guessed when its description changes', (t) async {
      tall(t);
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
          id: 'x1', groupId: 'g1', description: 'Stuff', amount: 600, currency: 'EUR', paidBy: 'm1',
          date: '2026-10-10'));
      await db.into(db.expenseShares).insert(ExpenseSharesCompanion.insert(expenseId: 'x1', memberId: 'm1', amount: 600));
      await t.pumpWidget(app(expenseId: 'x1'));
      await t.pumpAndSettle();
      expect(find.text('Category'), findsOneWidget); // nothing guessed on open
      await t.enterText(find.byKey(const Key('description')), 'Train to Rome');
      await guess(t);
      await t.tap(find.widgetWithText(FilledButton, 'Save'));
      await t.pumpAndSettle();
      expect(sentPayload((await t.runAsync(() => db.select(db.outbox).get()))!)['fields'],
          {'description': 'Train to Rome', 'category': 'transportation.bus_train'});
      await unmount(t);
    });
  });

  group('currencies', () {
    const oct10 = FxTable(date: '2026-10-10', rates: {'EUR': 1, 'JPY': 177.51, 'KRW': 1472.81});

    Future<void> settle(WidgetTester t) async {
      for (var i = 0; i < 3; i++) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
        await t.pumpAndSettle();
      }
    }

    Future<void> pick(WidgetTester t, String code) async {
      await t.tap(find.byKey(const Key('currency')));
      await t.pumpAndSettle();
      await t.tap(find.text(code).last);
      await settle(t);
    }

    String fx(WidgetTester t) => t.widget<TextField>(find.byKey(const Key('fx'))).controller!.text;
    String? helper(WidgetTester t) => t.widget<TextField>(find.byKey(const Key('fx'))).decoration!.helperText;
    List<Map<String, dynamic>> sent(List<OutboxRow> rows) =>
        [for (final o in rows) (jsonDecode(o.payloadJson) as Map).cast<String, dynamic>()];

    testWidgets('a foreign currency fills the automatic rate, with its source; a rate of 0 is refused', (t) async {
      tall(t);
      api.onFx = (_) => oct10;
      await t.pumpWidget(app());
      await settle(t);
      expect(find.byKey(const Key('fx')), findsNothing);
      String? hint() => t.widget<TextField>(find.byKey(const Key('amount'))).decoration!.hintText;
      expect(hint(), '0.00');
      await pick(t, 'JPY');
      expect(hint(), '0'); // the currency's decimals, not always 0.00
      expect(fx(t), '0.00563349');
      expect(helper(t), '1 JPY = 0.00563349 EUR (1 EUR = 177.51 JPY) · rate of 10 Oct');
      expect(find.byKey(const Key('fx-auto')), findsNothing);
      expect(find.byKey(const Key('fx-approx')), findsNothing); // no amount yet
      expect(api.fxCalls, [todayIso()]);

      await t.enterText(find.byKey(const Key('amount')), '12345');
      await t.enterText(find.byKey(const Key('description')), 'Ramen');
      await t.pump();
      expect(find.text('≈ €69.55'), findsOneWidget); // shared/fx-cases.json: 12345 JPY at 0.00563349 → 6955
      expect(saveEnabled(t), isTrue);
      await t.enterText(find.byKey(const Key('fx')), '0');
      await t.pump();
      expect(find.text('Enter a rate above 0, or leave it empty'), findsOneWidget);
      expect(saveEnabled(t), isFalse);
      await t.enterText(find.byKey(const Key('fx')), '');
      await t.pump();
      expect(helper(t), 'Empty: this stays under Not converted');
      expect(find.text('Use automatic rate: 0.00563349 (rate of 10 Oct)'), findsOneWidget);
      expect(saveEnabled(t), isTrue); // empty = Not converted
      await t.tap(find.byKey(const Key('fx-auto')));
      await t.pump();
      expect(fx(t), '0.00563349');

      await t.tap(find.widgetWithText(FilledButton, 'Save'));
      await settle(t);
      final out = sent((await t.runAsync(() => db.select(db.outbox).get()))!).single;
      expect((out['currency'], out['fxRateToDefault'], out['amount']), ('JPY', 0.00563349, 12345));
      expect(prefs.getString('lastCurrency.g1'), 'JPY');
      await unmount(t);
    });

    testWidgets('a typed rate survives a date change; the automatic one follows the date', (t) async {
      tall(t);
      api.onFx = (d) => d == todayIso() ? oct10 : const FxTable(date: '2026-10-02', rates: {'EUR': 1, 'JPY': 160});
      await t.pumpWidget(app());
      await settle(t);
      await pick(t, 'JPY');
      Future<void> pickDay(String day) async {
        await t.tap(find.byIcon(Icons.calendar_today_outlined));
        await t.pumpAndSettle();
        await t.tap(find.text(day).last);
        await t.tap(find.text('OK'));
        await settle(t);
      }

      await pickDay('2');
      expect(fx(t), '0.00625');
      expect(helper(t), endsWith('rate of 2 Oct'));
      await t.enterText(find.byKey(const Key('fx')), '0.006');
      await t.pump();
      await pickDay('3');
      expect(api.fxCalls.length, 3);
      expect(fx(t), '0.006');
      expect(helper(t), '1 JPY = 0.006 EUR (1 EUR = 166.667 JPY) · your rate');
      expect(find.text('Use automatic rate: 0.00625 (rate of 2 Oct)'), findsOneWidget);
      await unmount(t);
    });

    testWidgets('offline: the cached table says so; without one there is no automatic rate', (t) async {
      tall(t);
      await t.pumpWidget(app());
      await settle(t);
      await pick(t, 'JPY');
      expect(fx(t), '');
      expect(helper(t), 'No automatic rate. Enter one, or leave it empty to keep this under Not converted.');
      await unmount(t);

      await t.runAsync(() => db.into(db.fxDays).insert(
          const FxDayRow(day: '2026-10-09', ratesJson: '{"EUR":1,"JPY":200}', fetchedAt: '2026-10-09T18:00:00Z')));
      await t.pumpWidget(app());
      await settle(t);
      await pick(t, 'JPY');
      expect(fx(t), '0.005');
      expect(helper(t), endsWith('offline · rate of 9 Oct'));
      await unmount(t);
    });

    testWidgets('a new expense starts in the last currency used in the group', (t) async {
      tall(t);
      api.onFx = (_) => oct10;
      await prefs.setString('lastCurrency.g1', 'KRW');
      await t.pumpWidget(app());
      await settle(t);
      expect(t.widget<CurrencyPicker>(find.byKey(const Key('currency'))).value, 'KRW');
      expect(fx(t), '0.000678974'); // 1 / 1472.81 = 0.00067897421…
      await unmount(t);
    });

    testWidgets('currency and rate travel together: back to EUR sends a null rate; 0 counts as no rate', (t) async {
      tall(t);
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
          id: 'x1', groupId: 'g1', description: 'Sushi', amount: 3000, currency: 'JPY', paidBy: 'm1',
          date: '2026-10-10', fxRateToDefault: const Value(0)));
      await db.into(db.expenseShares).insert(ExpenseSharesCompanion.insert(expenseId: 'x1', memberId: 'm1', amount: 3000));
      api.onFx = (_) => oct10;
      await t.pumpWidget(app(expenseId: 'x1'));
      await settle(t);
      expect(fx(t), ''); // stored 0 = not converted; opening changes nothing, the automatic rate is offered
      expect(find.text('Use automatic rate: 0.00563349 (rate of 10 Oct)'), findsOneWidget);
      await t.enterText(find.byKey(const Key('description')), 'Sushi bar');
      await t.pump();
      await t.tap(find.widgetWithText(FilledButton, 'Save'));
      await settle(t);
      expect(sent((await t.runAsync(() => db.select(db.outbox).get()))!).single['fields'], {'description': 'Sushi bar'});
      await unmount(t);

      await t.runAsync(() => db.delete(db.outbox).go());
      await t.pumpWidget(app(expenseId: 'x1'));
      await settle(t);
      await pick(t, 'EUR');
      await t.enterText(find.byKey(const Key('amount')), '30');
      await t.pump();
      await t.tap(find.widgetWithText(FilledButton, 'Save'));
      await settle(t);
      final f = sent((await t.runAsync(() => db.select(db.outbox).get()))!).single['fields'] as Map;
      expect((f['currency'], f.containsKey('fxRateToDefault'), f['fxRateToDefault']), ('EUR', true, null));
      await unmount(t);
    });
  });
}
