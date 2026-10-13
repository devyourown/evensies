import 'dart:io';

import 'package:drift/native.dart';
import 'package:evensies/core/env.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/data/api/dto.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/images.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/features/friends/add_friend_screen.dart';
import 'package:evensies/features/groups/join_code_screen.dart';
import 'package:evensies/features/groups/join_screen.dart';
import 'package:evensies/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Adding friends (docs/API.md, Friends): my code, a friend's code, someone not on Evensies; the code box's fallback.
void main() {
  late AppDatabase db;
  late FakeApi6 api;
  late SharedPreferences prefs;

  setUpAll(() => Money.loadFromJson(File('../shared/currencies.json').readAsStringSync()));

  GroupDto friendGroup(String id) => GroupDto(
      id: id, name: 'Anna & Ben', defaultCurrency: 'EUR', inviteCode: 'INV', latestSeq: 3, myMemberId: 'f1', kind: 'friend');

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    api = FakeApi6(db);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await db.saveSession(const SessionRow(
        id: 1, accessToken: 'a', refreshToken: 'r', userId: 'u-anna', displayName: 'Anna', homeCurrency: 'CHF'));
    api.onAddFriend = (_) => friendGroup('gf'); // the canonical friend group
    api.snap = (
      group: friendGroup('gf'),
      state: const GroupState(name: 'Anna & Ben', defaultCurrency: 'EUR', kind: 'friend', members: [
        Member(id: 'f1', name: 'Anna', userId: 'u-anna'),
        Member(id: 'f2', name: 'Ben', userId: 'u-ben'),
      ]),
      latestSeq: 3,
    );
    // The clipboard is empty.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (c) async => c.method == 'Clipboard.getData' ? null : null);
  });
  tearDown(() => db.close());

  Widget app(String initial) => ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          apiProvider.overrideWithValue(api),
          syncProvider.overrideWithValue(NoSync(db, api)),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        // The app's router keeps the session loaded (and with it the home currency); so does this.
        child: Consumer(builder: (_, ref, child) {
          ref.watch(sessionProvider);
          return child!;
        }, child: MaterialApp.router(
          routerConfig: GoRouter(initialLocation: initial, routes: [
            GoRoute(path: '/add', builder: (_, s) => AddFriendScreen(code: s.uri.queryParameters['code'])),
            GoRoute(path: '/code', builder: (_, _) => const JoinCodeScreen()),
            GoRoute(path: '/groups/:id', builder: (_, s) => Text('group ${s.pathParameters['id']}')),
            GoRoute(path: '/friends/:key', builder: (_, s) => Text('friend ${s.pathParameters['key']}')),
            GoRoute(path: '/join/:code', builder: (_, s) => JoinScreen(code: s.pathParameters['code']!)),
          ]),
        )),
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

  void tall(WidgetTester t) {
    t.view.physicalSize = const Size(800, 2000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  testWidgets('my code with its QR, and a new code on Rotate', (t) async {
    tall(t);
    api.code = (friendCode: 'K7P4QX', link: 'https://e.test/f/K7P4QX');
    await t.pumpWidget(app('/add'));
    await settle(t);
    expect(find.text('K7P-4QX'), findsOneWidget);
    expect(find.byKey(const Key('friend-qr')), findsOneWidget);
    await t.tap(find.text('New code'));
    await settle(t);
    await t.tap(find.widgetWithText(FilledButton, 'New code'));
    await settle(t);
    expect(api.rotations, 1);
    expect(find.text('NEW-234'), findsOneWidget);
    await unmount(t);
  });

  testWidgets("offline: my code says it needs a connection", (t) async {
    await t.pumpWidget(app('/add'));
    await settle(t);
    expect(find.text('Your friend link needs a connection'), findsOneWidget);
    await unmount(t);
  });

  testWidgets("a friend's code: preview, then POST /friends {code} in my home currency and their page", (t) async {
    tall(t);
    api.friendNames = {'K7P4QX': 'Ben'};
    await t.pumpWidget(app('/add?code=k7p-4qx')); // a /f/ link lands here
    await settle(t);
    expect(find.byKey(const Key('friend-preview')), findsOneWidget);
    expect(find.text('Ben'), findsOneWidget);
    await t.tap(find.byKey(const Key('friend-add')));
    await settle(t);
    expect(api.friendCalls.single['code'], 'K7P4QX');
    expect(api.friendCalls.single['defaultCurrency'], 'CHF');
    expect(api.friendCalls.single['name'], isNull);
    expect(find.text('group gf'), findsOneWidget); // the friend group opens as the friend's page
    expect((await t.runAsync(() => db.getGroup('gf')))!.kind, 'friend');
    await unmount(t);
  });

  testWidgets('my own code is refused with a clear message', (t) async {
    tall(t);
    api.friendNames = {'K7P4QX': 'Anna'};
    api.onAddFriend = (_) => throw const ApiException(status: 400, code: 'SELF_FRIEND', message: 'x');
    await t.pumpWidget(app('/add?code=K7P4QX'));
    await settle(t);
    await t.tap(find.byKey(const Key('friend-add')));
    await settle(t);
    expect(find.text("That's your own code"), findsOneWidget);
    await unmount(t);
  });

  testWidgets('someone not on Evensies yet: a name (at most 30 characters) makes a placeholder friend', (t) async {
    tall(t);
    await t.pumpWidget(app('/add'));
    await settle(t);
    await t.enterText(find.byKey(const Key('friend-name')), 'x' * 31);
    await t.pump();
    expect(find.text('At most 30 characters'), findsOneWidget);
    await t.enterText(find.byKey(const Key('friend-name')), '  Zoe ');
    await t.pump();
    await t.tap(find.byKey(const Key('friend-add-name')));
    await settle(t);
    expect(api.friendCalls.single['name'], 'Zoe');
    expect(find.text('friend g:gf'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('the code box: a group code first, then a friend code on a 404', (t) async {
    api.friendNames = {'K7P4QX': 'Ben'};
    await t.pumpWidget(app('/code'));
    await settle(t);
    await t.enterText(find.byType(TextField), 'K7P4QX');
    await settle(t);
    expect(find.byKey(const Key('friend-code-preview')), findsOneWidget);
    expect(find.text('Ben · on Evensies'), findsOneWidget);
    await t.tap(find.text('Add Ben as a friend'));
    await settle(t);
    expect(api.friendCalls.single['code'], 'K7P4QX');
    await unmount(t);
  });

  testWidgets("the code box: a placeholder friend's code says who added me, not the friend group's name", (t) async {
    api.invites['ABC234'] = const InvitePreview(groupId: 'gf', name: 'Anna & Carla', memberCount: 2, kind: 'friend', members: [
      InviteMemberDto(id: 'm1', name: 'Anna', linked: true),
      InviteMemberDto(id: 'm2', name: 'Carla', linked: false),
    ]);
    await t.pumpWidget(app('/code'));
    await settle(t);
    await t.enterText(find.byType(TextField), 'ABC234');
    await settle(t);
    expect(find.text('Anna added you as a friend'), findsOneWidget);
    expect(find.textContaining('Anna & Carla'), findsNothing);
    expect(find.textContaining('members'), findsNothing);
    await unmount(t);
  });

  testWidgets("a placeholder friend's invite: claim the placeholder, no new member; then the friend's page", (t) async {
    api.invites['ABC234'] = const InvitePreview(groupId: 'gf', name: 'Anna & Carla', memberCount: 2, kind: 'friend', members: [
      InviteMemberDto(id: 'm1', name: 'Anna', linked: true),
      InviteMemberDto(id: 'm2', name: 'Carla', linked: false),
    ]);
    api.joined = friendGroup('gf');
    await t.pumpWidget(app('/join/ABC234'));
    await settle(t);
    expect(find.text('Anna added you as a friend'), findsOneWidget);
    expect(find.text("I'm Carla"), findsOneWidget);
    expect(find.text('New member name'), findsNothing);
    await t.tap(find.text('Join'));
    await settle(t);
    expect(api.joins, [('ABC234', 'm2')]);
    expect(find.text('group gf'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('a friend code opened as a link: "wants to split expenses with you"', (t) async {
    api.friendNames = {'K7P4QX': 'Ben'};
    await t.pumpWidget(app('/join/K7P4QX'));
    await settle(t);
    expect(find.text('Ben wants to split expenses with you'), findsOneWidget);
    await t.tap(find.text('Add Ben as a friend'));
    await settle(t);
    expect(api.friendCalls.single['code'], 'K7P4QX');
    await unmount(t);
  });

  test('photos: the long edge goes to maxEdge, a smaller image keeps its size', () {
    expect(compressMinEdge(4032, 3024, 512), 384); // 4032 → 512, 3024 → 384
    expect(compressMinEdge(3024, 4032, 512), 384);
    expect(compressMinEdge(10000, 1000, 512), 51); // a panorama: the long edge, not the short one, is bounded
    expect(compressMinEdge(400, 300, 512), 300);
    expect(compressMinEdge(1, 1, 512), 1);
  });
}
