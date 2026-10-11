import 'dart:async';

import 'package:drift/native.dart';
import 'package:evensies/core/env.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/features/auth/auth_service.dart';
import 'package:evensies/providers.dart';
import 'package:evensies/push.dart';
import 'package:evensies/router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// push.dart through [wirePush] with fake FCM calls and streams (Firebase itself cannot run in tests).
void main() {
  late AppDatabase db;
  late FakeApi api;
  late NoSync sync;
  late SharedPreferences prefs;
  late StreamController<String> tokenRefresh;
  late StreamController<RemoteMessage> foreground;
  late StreamController<RemoteMessage> opened;
  late int permissionAsks;
  late int tokenDeletes; // successful deleteToken calls
  late bool fcmOffline;

  const session = SessionRow(id: 1, accessToken: 'a', refreshToken: 'r', userId: 'u1', displayName: 'Anna');
  const rome = GroupRow(kind: 'group', id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'm1', simplifyDebts: true);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    api = FakeApi(db);
    sync = NoSync(db);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tokenRefresh = StreamController<String>.broadcast();
    foreground = StreamController<RemoteMessage>.broadcast();
    opened = StreamController<RemoteMessage>.broadcast();
    permissionAsks = 0;
    tokenDeletes = 0;
    fcmOffline = false;
  });
  tearDown(() => db.close());

  Widget app({RemoteMessage? initial}) => ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          apiProvider.overrideWithValue(api),
          syncProvider.overrideWithValue(sync),
          sharedPreferencesProvider.overrideWithValue(prefs),
          routerProvider.overrideWithValue(GoRouter(routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: Text('home')),
              routes: [
                GoRoute(
                  path: 'groups/:id',
                  builder: (_, s) => Scaffold(body: Text('${s.pathParameters['id']} ${s.uri.queryParameters['tab']}')),
                ),
              ],
            ),
          ])),
        ],
        child: _Host((ref) => wirePush(
              ref,
              getToken: () async => 'tok-1',
              deleteToken: () async => fcmOffline ? throw Exception('offline') : tokenDeletes++,
              requestPermission: () async => permissionAsks++,
              onTokenRefresh: tokenRefresh.stream,
              onMessage: foreground.stream,
              onMessageOpenedApp: opened.stream,
              getInitialMessage: () async => initial,
            )),
      );

  Future<void> settle(WidgetTester t) async {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pumpAndSettle();
  }

  // Also past the banner's 5-second timer.
  Future<void> unmount(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 6));
  }

  testWidgets('registers the token once someone signs in, and again when FCM rotates it', (t) async {
    await t.pumpWidget(app());
    await settle(t);
    expect(api.registered, isEmpty);

    await t.runAsync(() => db.saveSession(session));
    await settle(t);
    final deviceId = prefs.getString(deviceIdKey);
    expect(api.registered, [(deviceId, 'tok-1')]);

    tokenRefresh.add('tok-2');
    await settle(t);
    expect(api.registered.last, (deviceId, 'tok-2'));
    await unmount(t);
  });

  testWidgets('asks for permission when the first group appears, then registers again', (t) async {
    await t.runAsync(() => db.saveSession(session));
    await t.pumpWidget(app());
    await settle(t);
    expect(permissionAsks, 0);
    expect(api.registered, hasLength(1));

    await t.runAsync(() => db.upsertGroup(rome));
    await settle(t);
    expect(permissionAsks, 1);
    expect(api.registered, hasLength(2));
    await unmount(t);
  });

  testWidgets('a launch that already has groups never prompts', (t) async {
    await t.runAsync(() async {
      await db.saveSession(session);
      await db.upsertGroup(rome);
    });
    await t.pumpWidget(app());
    await settle(t);
    await t.runAsync(() => db.upsertGroup(rome.copyWith(id: 'g2')));
    await settle(t);
    expect(permissionAsks, 0);
    await unmount(t);
  });

  testWidgets('in the foreground: a banner with the same title/body whose View opens the activity tab', (t) async {
    await t.runAsync(() async {
      await db.saveSession(session);
      await db.upsertGroup(rome);
    });
    await t.pumpWidget(app());
    await settle(t);

    foreground.add(const RemoteMessage(data: {'type': 'sync', 'groupId': 'g1', 'seq': '7'}));
    await settle(t);
    expect(sync.later, ['g1']);
    expect(find.byType(MaterialBanner), findsNothing); // data only: just sync

    foreground.add(const RemoteMessage(
      data: {'type': 'sync', 'groupId': 'g1', 'seq': '8'},
      notification: RemoteNotification(title: 'Rome', body: 'Ben added “Dinner” · €30.00'),
    ));
    await settle(t);
    expect(sync.later, ['g1', 'g1']);
    expect(find.text('Rome'), findsOneWidget);
    expect(find.text('Ben added “Dinner” · €30.00'), findsOneWidget);

    await t.tap(find.text('View'));
    await settle(t);
    expect(find.text('g1 activity'), findsOneWidget);
    expect(find.byType(MaterialBanner), findsNothing);
    await unmount(t);
  });

  testWidgets('the banner hides itself after a few seconds', (t) async {
    await t.pumpWidget(app());
    await settle(t);
    foreground.add(const RemoteMessage(data: {'groupId': 'g1'}, notification: RemoteNotification(title: 'Rome', body: 'x')));
    await settle(t);
    expect(find.text('Rome'), findsOneWidget);
    await t.pump(const Duration(seconds: 6));
    await t.pumpAndSettle();
    expect(find.text('Rome'), findsNothing);
    await unmount(t);
  });

  testWidgets('a tapped notification opens its group activity, at launch and while running', (t) async {
    await t.runAsync(() => db.saveSession(session));
    await t.pumpWidget(app(initial: const RemoteMessage(data: {'type': 'sync', 'groupId': 'g2', 'seq': '3'})));
    await settle(t);
    expect(find.text('g2 activity'), findsOneWidget);

    opened.add(const RemoteMessage(data: {'type': 'sync', 'groupId': 'g1', 'seq': '4'}));
    await settle(t);
    expect(find.text('g1 activity'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('losing the session deletes the FCM token, so the server drops the device row at its next send',
      (t) async {
    await t.runAsync(() => db.saveSession(session));
    await t.pumpWidget(app());
    await settle(t);
    expect(tokenDeletes, 0);

    await t.runAsync(() => db.clearSession()); // same path as a failed token refresh
    await settle(t);
    expect(tokenDeletes, 1);
    expect(prefs.getBool(tokenToDeleteKey), isNull);
    await unmount(t);
  });

  testWidgets('offline, the deletion is retried on resume and at the next launch while still signed out', (t) async {
    void resume() => t.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    await t.runAsync(() => db.saveSession(session));
    await t.pumpWidget(app());
    await settle(t);
    fcmOffline = true;
    await t.runAsync(() => db.clearSession());
    await settle(t);
    expect(tokenDeletes, 0);
    expect(prefs.getBool(tokenToDeleteKey), isTrue);

    fcmOffline = false;
    resume();
    await settle(t);
    expect(tokenDeletes, 1);
    expect(prefs.getBool(tokenToDeleteKey), isNull);
    await unmount(t);

    await prefs.setBool(tokenToDeleteKey, true); // failed again before the app was closed
    await t.pumpWidget(app());
    await settle(t);
    expect(tokenDeletes, 2);
    expect(prefs.getBool(tokenToDeleteKey), isNull);
    await unmount(t);

    // Someone signed in meanwhile: POST /devices moves the token to them instead.
    await prefs.setBool(tokenToDeleteKey, true);
    await t.runAsync(() => db.saveSession(session));
    await t.pumpWidget(app());
    await settle(t);
    expect(tokenDeletes, 2);
    expect(api.registered, isNotEmpty);
    await unmount(t);
  });

  group('sign-out', () {
    ProviderContainer container() => ProviderContainer(overrides: [
          dbProvider.overrideWithValue(db),
          apiProvider.overrideWithValue(api),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ]);

    test('unregisters this phone, then wipes the session', () async {
      await prefs.setString(deviceIdKey, 'd1');
      await db.saveSession(session);
      final c = container();
      addTearDown(c.dispose);
      await c.read(authServiceProvider).logout();
      expect(api.unregistered, ['d1']);
      expect(await db.getSession(), isNull);
    });

    test('offline still signs out', () async {
      await prefs.setString(deviceIdKey, 'd1');
      await db.saveSession(session);
      api.devicesOffline = true;
      final c = container();
      addTearDown(c.dispose);
      await c.read(authServiceProvider).logout();
      expect(await db.getSession(), isNull);
    });
  });
}

class _Host extends ConsumerStatefulWidget {
  final void Function(WidgetRef ref) init;
  const _Host(this.init);
  @override
  ConsumerState<_Host> createState() => _HostState();
}

class _HostState extends ConsumerState<_Host> {
  @override
  void initState() {
    super.initState();
    widget.init(ref);
  }

  @override
  Widget build(BuildContext context) =>
      MaterialApp.router(scaffoldMessengerKey: scaffoldMessengerKey, routerConfig: ref.watch(routerProvider));
}
