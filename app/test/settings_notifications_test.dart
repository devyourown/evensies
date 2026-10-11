import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/core/env.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/features/settings/settings_screen.dart';
import 'package:evensies/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  late AppDatabase db;
  late FakeApi api;

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
}
