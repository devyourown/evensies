import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/data/api/dto.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/local_writes.dart';
import 'package:evensies/core/currency_picker.dart';
import 'package:evensies/core/env.dart';
import 'package:evensies/features/group_detail/convert_sheet.dart';
import 'package:evensies/features/groups/create_group_dialog.dart';
import 'package:evensies/features/groups/groups_screen.dart';
import 'package:evensies/features/settle/settle_screen.dart';
import 'package:evensies/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  late AppDatabase db;
  late FakeApi api;
  late NoSync sync;

  setUpAll(() => Money.loadFromJson('{"decimals":{"EUR":2,"JPY":0,"USD":2},"symbols":{"EUR":"€","JPY":"¥","USD":"\$"}}'));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    api = FakeApi(db);
    sync = NoSync(db);
    await db.upsertGroup(
        const GroupRow(kind: 'group', type: 'other', deleted: false, id: 'g1', name: 'Tokyo', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'm1', simplifyDebts: true));
    for (final (id, name) in [('m1', 'Anna'), ('m2', 'Ben')]) {
      await db.into(db.members).insert(MembersCompanion.insert(id: id, groupId: 'g1', name: name));
    }
  });
  tearDown(() => db.close());

  /// Anna paid [amount] for Ben.
  Future<void> expense(String id, int amount, String cur, {double? rate, bool deleted = false}) async {
    await db.into(db.expenses).insert(ExpensesCompanion.insert(
        id: id,
        groupId: 'g1',
        description: id,
        amount: amount,
        currency: cur,
        paidBy: 'm1',
        date: '2026-10-10',
        fxRateToDefault: Value(rate),
        deleted: Value(deleted)));
    await db.into(db.expenseShares).insert(ExpenseSharesCompanion.insert(expenseId: id, memberId: 'm2', amount: amount));
    await db.into(db.expensePayers).insert(ExpensePayersCompanion.insert(expenseId: id, memberId: 'm1', amount: amount));
  }

  Future<List<Map<String, dynamic>>> sent() async =>
      [for (final o in await db.select(db.outbox).get()) (jsonDecode(o.payloadJson) as Map).cast<String, dynamic>()];

  test('convert writes the rate into every live JPY expense without one, as one transaction, one sync', () async {
    await expense('a', 1000, 'JPY');
    await expense('b', 2000, 'JPY', rate: 0);
    await expense('c', 3000, 'JPY', rate: 0.006); // has a rate: left alone
    await expense('d', 4000, 'JPY', deleted: true);
    await expense('e', 500, 'USD');
    final writes = LocalWrites(db, sync);
    final before = await writes.convertCurrency('g1', 'JPY', 0.00563349);
    expect(before, {'a': null, 'b': 0});
    // The currency travels with the rate (docs/API.md: both keys), so a concurrent currency change can't keep it.
    expect(await sent(), [
      {'expenseId': 'a', 'fields': {'currency': 'JPY', 'fxRateToDefault': 0.00563349}},
      {'expenseId': 'b', 'fields': {'currency': 'JPY', 'fxRateToDefault': 0.00563349}},
    ]);
    expect([for (final id in 'abcde'.split('')) (await db.getExpense(id))!.fxRateToDefault],
        [0.00563349, 0.00563349, 0.006, null, null]);
    expect(sync.later, ['g1']);
    expect(await writes.convertCurrency('g1', 'EUR', 1), isEmpty); // the group currency is never converted
    expect(() => writes.convertCurrency('g1', 'JPY', 0), throwsArgumentError);

    // Undo puts the previous rates back, the same way.
    await writes.setRates('g1', 'JPY', before);
    expect([for (final id in 'ab'.split('')) (await db.getExpense(id))!.fxRateToDefault], [null, 0]);
    expect((await sent()).skip(2), [
      {'expenseId': 'a', 'fields': {'currency': 'JPY', 'fxRateToDefault': null}},
      {'expenseId': 'b', 'fields': {'currency': 'JPY', 'fxRateToDefault': 0}},
    ]);
  });

  Widget app(Widget home, {SharedPreferences? prefs}) => ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          apiProvider.overrideWithValue(api),
          syncProvider.overrideWithValue(sync),
          if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
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

  testWidgets('the Convert sheet prefills today\'s rate, shows count and total, and converts', (t) async {
    await t.runAsync(() async {
      await expense('a', 1000, 'JPY');
      await expense('b', 2345, 'JPY');
    });
    api.onFx = (_) => const FxTable(date: '2026-10-10', rates: {'EUR': 1, 'JPY': 177.51});
    await t.pumpWidget(app(Scaffold(
        body: Builder(
            builder: (c) => TextButton(
                onPressed: () => showConvertSheet(c, groupId: 'g1', currencies: ['JPY']), child: const Text('open'))))));
    await t.tap(find.text('open'));
    await settle(t);
    expect(find.text('Convert to EUR'), findsNWidgets(2)); // title and button
    expect(find.text('¥3,345 · 2 expenses'), findsOneWidget);
    expect(find.text('rate of Oct 10'), findsOneWidget);
    expect(t.widget<TextField>(find.byKey(const Key('convert-rate-JPY'))).controller!.text, '0.00563349');
    await t.enterText(find.byKey(const Key('convert-rate-JPY')), '0');
    await t.pump();
    expect(t.widget<FilledButton>(find.byKey(const Key('convert'))).enabled, isFalse);
    await t.enterText(find.byKey(const Key('convert-rate-JPY')), '0.0056');
    await t.pump();
    await t.tap(find.byKey(const Key('convert')));
    await settle(t);
    expect((await t.runAsync(sent))!.map((p) => p['fields']), [
      {'currency': 'JPY', 'fxRateToDefault': 0.0056},
      {'currency': 'JPY', 'fxRateToDefault': 0.0056},
    ]);
    // The snackbar's Undo takes both rates back out.
    await t.tap(find.text('Undo'));
    await settle(t);
    expect((await t.runAsync(sent))!.skip(2).map((p) => p['fields']), [
      {'currency': 'JPY', 'fxRateToDefault': null},
      {'currency': 'JPY', 'fxRateToDefault': null},
    ]);
    await unmount(t);
  });

  testWidgets('Settle up settles a JPY bucket in JPY, under its own header (Phase 6, #76)', (t) async {
    await t.runAsync(() async {
      await expense('eur', 1000, 'EUR');
      await expense('jpy', 3000, 'JPY');
    });
    await t.pumpWidget(app(const SettleScreen(groupId: 'g1')));
    await settle(t);
    expect(find.text('€10.00'), findsOneWidget);
    expect(find.text('¥3,000'), findsOneWidget);
    expect(find.text('Not converted · JPY · settles in JPY'), findsOneWidget);
    expect(find.text('1 transfer settles the EUR balance'), findsOneWidget); // not the yen
    // Ben pays the yen in yen: the card opens "Record a payment" prefilled in JPY.
    await t.tap(find.text('¥3,000'));
    await settle(t);
    expect(find.text('Record a payment'), findsWidgets);
    await t.tap(find.byKey(const Key('payment-save')));
    await settle(t);
    final p = (await t.runAsync(() => db.select(db.payments).getSingle()))!;
    expect((p.fromMember, p.toMember, p.amount, p.currency), ('m2', 'm1', 3000, 'JPY'));
    await unmount(t);
  });

  testWidgets('the Convert sheet says when payments in that currency stay in it', (t) async {
    await t.runAsync(() async {
      await expense('jpy', 3000, 'JPY');
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: 'p1', groupId: 'g1', fromMember: 'm2', toMember: 'm1', amount: 1000, currency: 'JPY', date: '2026-10-11'));
    });
    await t.pumpWidget(app(Builder(
        builder: (c) => TextButton(
            onPressed: () => showConvertSheet(c, groupId: 'g1', currencies: ['JPY']), child: const Text('open')))));
    await t.tap(find.text('open'));
    await settle(t);
    expect(find.byKey(const Key('payments-stay-JPY')), findsOneWidget);
    await unmount(t);
  });

  testWidgets('the groups list names my balance in each currency', (t) async {
    await t.runAsync(() async {
      await expense('eur', 1000, 'EUR'); // Anna is owed €10
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
          id: 'jpy', groupId: 'g1', description: 'jpy', amount: 3000, currency: 'JPY', paidBy: 'm2', date: '2026-10-10'));
      await db.into(db.expenseShares).insert(ExpenseSharesCompanion.insert(expenseId: 'jpy', memberId: 'm1', amount: 3000));
    });
    await t.pumpWidget(app(const GroupsScreen()));
    await settle(t);
    // One line per currency, each in its own colour (a long single line was cut off after the first).
    final text = t.widget<Text>(find.textContaining('You are owed €10.00\nYou owe ¥3,000'));
    final cs = Theme.of(t.element(find.byType(GroupsScreen))).colorScheme;
    final colors = {
      for (final s in (text.textSpan! as TextSpan).children!.whereType<TextSpan>())
        if (s.text != null) s.text!: s.style?.color,
    };
    expect(colors['You are owed €10.00'], cs.primary);
    expect(colors['You owe ¥3,000'], cs.error);
    expect(text.maxLines, isNull);
    await unmount(t);
  });

  testWidgets('a new group starts in the home currency when none was used before', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await t.runAsync(() => db.saveSession(const SessionRow(
        id: 1, accessToken: 'a', refreshToken: 'r', userId: 'u1', displayName: 'Anna', homeCurrency: 'JPY')));
    await t.pumpWidget(app(
      // The app's router keeps the session loaded; so does this.
      Consumer(builder: (c, ref, _) {
        ref.watch(sessionProvider);
        return TextButton(onPressed: () => showCreateGroupDialog(c), child: const Text('new'));
      }),
      prefs: prefs,
    ));
    await settle(t);
    await t.tap(find.text('new'));
    await settle(t);
    expect(t.widget<CurrencyPicker>(find.byKey(const Key('group-currency'))).value, 'JPY');
    await unmount(t);
  });
}
