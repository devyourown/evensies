import 'package:drift/native.dart';
import 'package:evensies/core/env.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/features/lock/app_lock.dart';
import 'package:evensies/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Answers from [answers] in turn (the last one repeats); counts the prompts.
class _FakeAuth implements Authenticator {
  final List<bool> answers;
  var asked = 0;
  _FakeAuth(this.answers);
  @override
  Future<bool> isSupported() async => true;
  @override
  Future<bool> authenticate(String reason) async => answers[(asked++).clamp(0, answers.length - 1)];
}

final _messenger = GlobalKey<ScaffoldMessengerState>();

/// docs/API.md, Appearance and app lock: locked at a cold start, a cover in the background, locked again after 60 s.
void main() {
  test('back after 59 s stays open; after 61 s it locks; covered while away', () {
    var t = DateTime(2026, 10, 11, 10);
    final s = AppLockState(enabled: () => true, clock: () => t);
    expect(s.locked, isTrue); // cold start
    s.unlock();
    expect(s.locked, isFalse);

    s.lifecycle(AppLifecycleState.inactive);
    s.lifecycle(AppLifecycleState.paused);
    expect((s.locked, s.covered), (false, true));
    t = t.add(const Duration(seconds: 59));
    s.lifecycle(AppLifecycleState.resumed);
    expect((s.locked, s.covered), (false, false));

    s.lifecycle(AppLifecycleState.hidden);
    t = t.add(const Duration(seconds: 61));
    s.lifecycle(AppLifecycleState.resumed);
    expect((s.locked, s.covered), (true, false));
  });

  test('off: never locked nor covered', () {
    final s = AppLockState(enabled: () => false);
    s.lifecycle(AppLifecycleState.paused);
    expect((s.locked, s.covered), (false, false));
  });

  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<(ProviderContainer, SharedPreferences)> container(_FakeAuth auth, {bool on = false}) async {
    SharedPreferences.setMockInitialValues({if (on) AppLockSetting.key: true});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
      apiProvider.overrideWithValue(FakeApi(db)),
      sharedPreferencesProvider.overrideWithValue(prefs),
      authenticatorProvider.overrideWithValue(auth),
    ]);
    addTearDown(c.dispose);
    return (c, prefs);
  }

  test('turning it on needs one successful check', () async {
    final (c, prefs) = await container(_FakeAuth([false, true]));
    expect(await c.read(appLockProvider.notifier).enable('Unlock Evensies'), isFalse);
    expect((c.read(appLockProvider), prefs.getBool(AppLockSetting.key)), (false, null));
    expect(await c.read(appLockProvider.notifier).enable('Unlock Evensies'), isTrue);
    expect((c.read(appLockProvider), prefs.getBool(AppLockSetting.key)), (true, true));
  });

  Future<(ProviderContainer, SharedPreferences)> gate(WidgetTester t, _FakeAuth auth) async {
    final r = await container(auth, on: true);
    await t.pumpWidget(UncontrolledProviderScope(
      container: r.$1,
      child: MaterialApp(
        scaffoldMessengerKey: _messenger,
        builder: (_, child) => LockGate(child: child!),
        home: const Scaffold(body: Text('balances')),
      ),
    ));
    await t.pumpAndSettle();
    return r;
  }

  testWidgets('a failed check stays locked; Unlock asks again', (t) async {
    final auth = _FakeAuth([false, true]);
    await gate(t, auth);
    expect(auth.asked, 1); // asked once by itself
    expect(find.byType(LockScreen), findsOneWidget);

    await t.tap(find.byKey(const Key('lock-unlock')));
    await t.pumpAndSettle();
    expect(auth.asked, 2);
    expect(find.byType(LockScreen), findsNothing);
    expect(find.text('balances'), findsOneWidget);
  });

  testWidgets('while locked, a screen reader finds nothing behind the lock and snackbars stay off the lock screen',
      (t) async {
    final semantics = t.ensureSemantics();
    await gate(t, _FakeAuth([false, true]));
    expect(find.bySemanticsLabel('balances'), findsNothing);
    _messenger.currentState!.showSnackBar(const SnackBar(content: Text("Couldn't save “Hotel”")));
    await t.pump();
    await t.pump(const Duration(milliseconds: 750));
    expect(find.descendant(of: find.byType(LockScreen), matching: find.byType(SnackBar)), findsNothing);
    expect(find.bySemanticsLabel("Couldn't save “Hotel”"), findsNothing);

    await t.tap(find.byKey(const Key('lock-unlock')));
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel('balances'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Sign out on the lock screen wipes this device and turns the lock off', (t) async {
    await t.runAsync(() =>
        db.saveSession(const SessionRow(id: 1, accessToken: 'a', refreshToken: 'r', userId: 'u', displayName: 'Anna')));
    final (c, prefs) = await gate(t, _FakeAuth([false]));
    await t.tap(find.byKey(const Key('lock-sign-out')));
    await t.pumpAndSettle();
    expect(find.text("Sign out and remove this device's data? Your groups stay on the server."), findsOneWidget);
    expect(find.text('Local data on this device is removed. Changes that have not synced yet will be lost.'),
        findsOneWidget);
    await t.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await t.pumpAndSettle();

    expect(await t.runAsync(db.getSession), isNull);
    expect((c.read(appLockProvider), prefs.getBool(AppLockSetting.key)), (false, null));
    expect(find.byType(LockScreen), findsNothing);
    await t.pumpWidget(const SizedBox());
  });
}
