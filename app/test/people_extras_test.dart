import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:evensies/core/env.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/data/api/dto.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/images.dart';
import 'package:evensies/domain/activity.dart';
import 'package:evensies/features/activity/activity_screen.dart';
import 'package:evensies/features/settings/settings_screen.dart';
import 'package:evensies/providers.dart';
import 'package:evensies/push.dart';
import 'package:evensies/router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Unread activity (#105), the profile photo, the reminders switch and reminder pushes (docs Phase 6).
void main() {
  late AppDatabase db;
  late FakeApi6 api;
  late SharedPreferences prefs;

  setUpAll(() => Money.loadFromJson(File('../shared/currencies.json').readAsStringSync()));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    api = FakeApi6(db);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await db.saveSession(const SessionRow(id: 1, accessToken: 'a', refreshToken: 'r', userId: 'u1', displayName: 'Anna'));
    await db.upsertGroup(const GroupRow(
        type: 'other', deleted: false, kind: 'group', id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 9, myMemberId: 'm1', simplifyDebts: true));
    await db.into(db.members).insert(MembersCompanion.insert(id: 'm1', groupId: 'g1', name: 'Anna'));
  });
  tearDown(() => db.close());

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

  List<Override> overrides({SyncServiceOverride? sync}) => [
        dbProvider.overrideWithValue(db),
        apiProvider.overrideWithValue(api),
        syncProvider.overrideWithValue(sync ?? NoSync(db, api)),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ];

  group('unread', () {
    testWidgets("a group's first page marks it seen up to its newest feedId; badges show the counts", (t) async {
      api.onActivity = (g, before) => (
            items: [
              ActivityItem.fromJson(
                  {'feedId': 41, 'seq': 3, 'kind': 'member_joined', 'memberId': 'm1', 'createdAt': '2026-10-11T08:00:00Z'}),
              ActivityItem.fromJson(
                  {'feedId': 40, 'seq': 2, 'kind': 'member_joined', 'memberId': 'm1', 'createdAt': '2026-10-11T07:00:00Z'}),
            ],
            nextBefore: null,
          );
      api.unread = const ActivityUnread(total: 0);
      await t.pumpWidget(ProviderScope(
          overrides: overrides(), child: const MaterialApp(home: Scaffold(body: ActivityList(groupId: 'g1')))));
      await settle(t);
      expect(api.seenCalls, [(41, 'g1')]);
      await unmount(t);
    });

    testWidgets('the Home Activity button and the group tab carry the counts; 99+', (t) async {
      api.unread = const ActivityUnread(total: 120, groups: {'g1': 120});
      await t.pumpWidget(ProviderScope(
        overrides: overrides(),
        child: Consumer(builder: (_, ref, _) {
          // What the app does at launch.
          WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(unreadProvider.notifier).refresh());
          return MaterialApp.router(routerConfig: ref.watch(routerProvider));
        }),
      ));
      await settle(t);
      expect(find.descendant(of: find.byKey(const Key('activity-badge')), matching: find.text('99+')), findsOneWidget);
      await t.tap(find.text('Settled up (1)')); // Rome has no expenses
      await settle(t);
      await t.tap(find.text('Rome'));
      await settle(t);
      expect(
          find.descendant(of: find.byKey(const Key('group-activity-badge')), matching: find.text('99+')), findsOneWidget);
      await unmount(t);
    });

    test('reset (sign-out) clears the counts and the icon badge', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('evensies/badge'), (c) async => calls.add(c));
      addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('evensies/badge'), null));
      final c = ProviderContainer(overrides: overrides());
      addTearDown(c.dispose);
      api.unread = const ActivityUnread(total: 2, groups: {'g1': 2});
      await c.read(unreadProvider.notifier).refresh();
      c.read(unreadProvider.notifier).reset();
      await Future<void>.delayed(Duration.zero);
      expect(c.read(unreadProvider), isNull);
      expect([for (final m in calls) (m.method, m.arguments)], [('set', 2), ('set', 0)]);
    });

    test('a server without the endpoint (404) hides the badges; offline keeps them', () async {
      final c = ProviderContainer(overrides: overrides());
      addTearDown(c.dispose);
      api.unread = const ActivityUnread(total: 2, groups: {'g1': 2});
      await c.read(unreadProvider.notifier).refresh();
      expect(c.read(unreadProvider)?.total, 2);
      api.unread = null; // offline
      await c.read(unreadProvider.notifier).refresh();
      expect(c.read(unreadProvider)?.total, 2);
      final old = _Old404(db);
      final c2 = ProviderContainer(overrides: [dbProvider.overrideWithValue(db), apiProvider.overrideWithValue(old)]);
      addTearDown(c2.dispose);
      await c2.read(unreadProvider.notifier).refresh();
      expect(c2.read(unreadProvider), isNull);
    });
  });

  group('settings', () {
    Widget app() => ProviderScope(
          overrides: [
            ...overrides(),
            pickPhotoProvider.overrideWithValue((ImageSource source, {required int maxEdge, required int quality}) async {
              expect((maxEdge, quality), (512, 85));
              return Uint8List.fromList('picked-$source'.codeUnits);
            }),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        );

    testWidgets('tap my picture: choose from library uploads it; Remove deletes it', (t) async {
      // A 1×1 PNG: there is a photo, so Remove is offered.
      api.avatars['u1'] = base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');
      await t.pumpWidget(app());
      await settle(t);
      await t.tap(find.byKey(const Key('my-photo')));
      await settle(t);
      expect(find.text('Take photo'), findsOneWidget);
      await t.tap(find.text('Choose from library'));
      await settle(t);
      expect(api.avatarUploads, ['picked-ImageSource.gallery']);
      await t.tap(find.byKey(const Key('my-photo')));
      await settle(t);
      await t.tap(find.text('Remove photo'));
      await settle(t);
      expect(api.avatarDeletes, 1);
      await unmount(t);
    });

    testWidgets('the reminders switch shows when the server has it, and PUTs it with the others', (t) async {
      api.prefs = {'expenses': true, 'comments': true, 'members': true, 'reminders': true};
      await t.pumpWidget(app());
      await settle(t);
      await t.tap(find.text('Reminders from friends'));
      await settle(t);
      expect(api.putPrefs.single, {'expenses': true, 'comments': true, 'members': true, 'reminders': false});
      await unmount(t);
    });

    testWidgets('an older server without reminders: no switch', (t) async {
      api.prefs = {'expenses': true, 'comments': true, 'members': true};
      await t.pumpWidget(app());
      await settle(t);
      expect(find.text('Reminders from friends'), findsNothing);
      await unmount(t);
    });
  });

  group('push', () {
    late StreamController<RemoteMessage> foreground, opened;
    late _CountingSync sync;
    setUp(() {
      foreground = StreamController<RemoteMessage>.broadcast();
      opened = StreamController<RemoteMessage>.broadcast();
      sync = _CountingSync(db, api);
    });

    Widget app() => ProviderScope(
          overrides: [
            ...overrides(sync: sync),
            routerProvider.overrideWithValue(GoRouter(routes: [
              GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('home')), routes: [
                GoRoute(path: 'friends/:key', builder: (_, s) => Scaffold(body: Text('friend ${s.pathParameters['key']}'))),
                GoRoute(path: 'groups/:id', builder: (_, s) => Scaffold(body: Text('group ${s.pathParameters['id']}'))),
              ]),
            ])),
          ],
          child: _Host((ref) => wirePush(
                ref,
                getToken: () async => null,
                deleteToken: () async {},
                requestPermission: () async => null,
                onTokenRefresh: const Stream.empty(),
                onMessage: foreground.stream,
                onMessageOpenedApp: opened.stream,
                getInitialMessage: () async => null,
              )),
        );

    testWidgets("a reminder opens the sender's friend page", (t) async {
      await t.pumpWidget(app());
      await settle(t);
      opened.add(const RemoteMessage(data: {'type': 'remind', 'fromUserId': 'u-ben'}));
      await settle(t);
      expect(find.text('friend u-ben'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 6));
    });

    testWidgets('a sync push for a group not on this device (a new friend) syncs everything; a known one just it',
        (t) async {
      await t.pumpWidget(app());
      await settle(t);
      foreground.add(const RemoteMessage(data: {'type': 'sync', 'groupId': 'g-new', 'seq': '3'}));
      await settle(t);
      expect(sync.alls, 1);
      expect(sync.later, isEmpty);
      foreground.add(const RemoteMessage(data: {'type': 'sync', 'groupId': 'g1', 'seq': '10'}));
      await settle(t);
      expect(sync.later, ['g1']);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 6));
    });
  });
}

typedef SyncServiceOverride = NoSync;

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

class _CountingSync extends NoSync {
  _CountingSync(super.db, super.api);
  int alls = 0;
  @override
  Future<void> syncAll() async => alls++;
}

/// A server before Phase 6: GET /activity/unread is a 404.
class _Old404 extends FakeApi {
  _Old404(super.db);
  @override
  Future<ActivityUnread> activityUnread() async => throw const ApiException(status: 404, code: 'NETWORK', message: 'x');
}
