import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/core/currency_picker.dart';
import 'package:evensies/core/env.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/data/api/dto.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/features/auth/auth_service.dart';
import 'package:evensies/features/settings/settings_screen.dart';
import 'package:evensies/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  late AppDatabase db;
  late FakeApi api;

  setUpAll(() => Money.loadFromJson('{"decimals":{"EUR":2,"USD":2,"JPY":0},"symbols":{"EUR":"€","USD":"\$","GBP":"£","JPY":"¥","KRW":"₩"}}'));

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    api = FakeApi(db);
  });
  tearDown(() => db.close());

  Future<Widget> app() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
        apiProvider.overrideWithValue(api),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    );
  }

  Future<void> settle(WidgetTester t) async {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 10));
  }

  bool? switchValue(WidgetTester t, String label) => t.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, label)).value;

  testWidgets('switches mirror the server prefs and PUT the full object', (t) async {
    api.prefs = {'expenses': true, 'comments': true, 'members': false};
    await t.pumpWidget(await app());
    await settle(t);
    expect(switchValue(t, 'Expenses and payments'), isTrue);
    expect(switchValue(t, 'Members and group changes'), isFalse);

    await t.tap(find.text('Comments'));
    await settle(t);
    expect(api.putPrefs, [
      {'expenses': true, 'comments': false, 'members': false}
    ]);
    expect(switchValue(t, 'Comments'), isFalse);

    api.prefs = null; // the next PUT fails → the switch flips back
    await t.tap(find.text('Members and group changes'));
    await settle(t);
    expect(api.putPrefs.last, {'expenses': true, 'comments': false, 'members': true});
    expect(switchValue(t, 'Members and group changes'), isFalse);
    await unmount(t);
  });

  testWidgets('offline: switches are disabled with a retry', (t) async {
    await t.pumpWidget(await app());
    await settle(t);
    expect(t.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Comments')).onChanged, isNull);
    expect(find.text('Notification settings need a connection'), findsOneWidget);

    api.prefs = {'expenses': true, 'comments': true, 'members': true};
    await t.tap(find.text('Retry'));
    await settle(t);
    expect(t.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Comments')).onChanged, isNotNull);
    await unmount(t);
  });

  testWidgets('home currency: the region\'s until picked, saved with PATCH /me; offline keeps the saved one', (t) async {
    await t.runAsync(() => db.saveSession(
        const SessionRow(id: 1, accessToken: 'a', refreshToken: 'r', userId: 'u1', displayName: 'Anna')));
    await t.pumpWidget(await app());
    await settle(t);
    String shown() => t.widget<CurrencyPicker>(find.descendant(
        of: find.byKey(const Key('home-currency')), matching: find.byType(CurrencyPicker))).value;
    expect(shown(), 'USD'); // en_US in tests
    expect(find.text('From your region · balances also show ≈ in it'), findsOneWidget);

    await t.tap(find.descendant(of: find.byKey(const Key('home-currency')), matching: find.byType(TextField)));
    await t.pumpAndSettle();
    await t.tap(find.text('JPY').last);
    await settle(t);
    expect(api.meUpdates, [(displayName: null, homeCurrency: 'JPY')]);
    expect((await t.runAsync(db.getSession))!.homeCurrency, 'JPY');
    expect(shown(), 'JPY');
    expect(find.text('Balances also show ≈ in it'), findsOneWidget);

    api.meOffline = true;
    await t.tap(find.descendant(of: find.byKey(const Key('home-currency')), matching: find.byType(TextField)));
    await t.pumpAndSettle();
    await t.tap(find.text('EUR').last);
    await settle(t);
    expect(find.text('Changing your home currency needs a connection.'), findsOneWidget);
    expect((await t.runAsync(db.getSession))!.homeCurrency, 'JPY');
    expect(shown(), 'JPY');
    await unmount(t);
  });

  test('signing in keeps the home currency saved on the account (another phone set it)', () async {
    api.signInAs = const UserDto(id: 'u1', displayName: 'Anna', homeCurrency: 'JPY');
    final c = ProviderContainer(overrides: [dbProvider.overrideWithValue(db), apiProvider.overrideWithValue(api)]);
    addTearDown(c.dispose);
    await c.read(authServiceProvider).dev('Anna');
    expect((await db.getSession())!.homeCurrency, 'JPY');
  });
}
