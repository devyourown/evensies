import 'package:drift/native.dart';
import 'package:evensies/core/env.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/features/settings/settings_screen.dart';
import 'package:evensies/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Phase 11 (docs/API.md 공식 서버만): a release build talks only to the official server.
void main() {
  testWidgets('a release build has no Server field; debug (or the dart-define) has it', (t) async {
    t.view.physicalSize = const Size(800, 4000); // the whole Settings list is built
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    Future<void> open(bool allowCustom) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await t.pumpWidget(ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          apiProvider.overrideWithValue(FakeApi(db)),
          syncProvider.overrideWithValue(NoSync(db)),
          sharedPreferencesProvider.overrideWithValue(prefs),
          allowCustomServerProvider.overrideWithValue(allowCustom),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pumpAndSettle();
    }

    Future<void> unmount() async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(milliseconds: 10));
    }

    await open(false);
    expect(find.text('Server URL'), findsNothing);
    await unmount();
    await open(true);
    expect(find.text('Server URL'), findsOneWidget);
    await unmount();
  });

  test('ServerUrl: a stored server only where the field is shown; the stored value is kept', () async {
    SharedPreferences.setMockInitialValues({'serverUrl': 'http://my.server'});
    final prefs = await SharedPreferences.getInstance();
    ProviderContainer container(bool allowCustom) {
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        allowCustomServerProvider.overrideWithValue(allowCustom),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    expect(container(true).read(serverUrlProvider), 'http://my.server');
    expect(container(false).read(serverUrlProvider), Env.defaultServerUrl);
    expect(Env.defaultServerUrl, 'https://evensies.nariinfo.dev'); // no dart-define in tests
    expect(prefs.getString('serverUrl'), 'http://my.server');
  });
}
