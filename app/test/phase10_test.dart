import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:evensies/core/cover.dart';
import 'package:evensies/core/env.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/data/api/dto.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/images.dart';
import 'package:evensies/data/local_writes.dart';
import 'package:evensies/data/sync/group_state_store.dart';
import 'package:evensies/data/sync/sync_service.dart';
import 'package:evensies/domain/activity.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/features/auth/auth_service.dart' show infoProvider;
import 'package:evensies/features/auth/login_screen.dart';
import 'package:evensies/features/expense_form/expense_form_screen.dart';
import 'package:evensies/features/friends/friend_settle_screen.dart';
import 'package:evensies/features/friends/home_data.dart';
import 'package:evensies/features/groups/join_screen.dart';
import 'package:evensies/features/groups/wide_layout.dart';
import 'package:evensies/features/search/search_screen.dart' show searchIndexProvider;
import 'package:evensies/providers.dart';
import 'package:evensies/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Phase 10 through the app's router (docs/API.md: group and friend deletion, Blocking, web layout): deleted groups leave every list
/// and come back, delete friend, block, the email features hidden without email, and the wide web layout.
void main() {
  late AppDatabase db;
  late FakeApi10 api;
  late NoSync sync;
  late SharedPreferences prefs;

  setUpAll(() => Money.loadFromJson(File('../shared/currencies.json').readAsStringSync()));

  Share s(String m, int a) => Share(memberId: m, amount: a);
  Expense x(String id, String paidBy, List<Share> shares) => Expense(
      id: id, description: id, amount: shares.fold(0, (a, s) => a + s.amount), currency: 'EUR', paidBy: paidBy,
      date: '2026-10-11', shares: shares);

  Future<void> addGroup(String id, String name, String kind, String me, List<Member> members,
      {List<Expense> expenses = const [], String type = 'other'}) async {
    await db.upsertGroup(GroupRow(
        type: type, deleted: false, kind: kind, id: id, name: name, defaultCurrency: 'EUR', latestSeq: 0,
        myMemberId: me, simplifyDebts: true, inviteCode: 'INV$id'));
    await GroupStateStore(db).save(
        id, GroupState(name: name, defaultCurrency: 'EUR', kind: kind, type: type, members: members, expenses: expenses), 0);
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    api = FakeApi10(db);
    sync = NoSync(db, api);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await db.saveSession(const SessionRow(
        id: 1, accessToken: 'a', refreshToken: 'r', userId: 'u-anna', displayName: 'Anna', homeCurrency: 'EUR'));
    // Rome: Ben paid the hotel, I owe Ben €30.
    await addGroup('g-rome', 'Rome', 'group', 'r1', const [
      Member(id: 'r1', name: 'Anna', userId: 'u-anna'),
      Member(id: 'r2', name: 'Ben', userId: 'u-ben'),
    ], expenses: [x('hotel', 'r2', [s('r1', 3000), s('r2', 3000)])], type: 'trip');
    // Non-group with Cara: I paid the taxi, Cara owes me €10.
    await addGroup('g-cara', 'Anna & Cara', 'friend', 'f1', const [
      Member(id: 'f1', name: 'Anna', userId: 'u-anna'),
      Member(id: 'f2', name: 'Cara', userId: 'u-cara'),
    ], expenses: [x('taxi', 'f1', [s('f1', 1000), s('f2', 1000)])]);
  });
  tearDown(() async {
    debugWideLayout = false;
    await db.close();
  });

  Widget app({bool email = false, String? support, List<Override> overrides = const []}) => ProviderScope(
        overrides: [
          ...overrides,
          dbProvider.overrideWithValue(db),
          apiProvider.overrideWithValue(api),
          syncProvider.overrideWithValue(sync),
          sharedPreferencesProvider.overrideWithValue(prefs),
          infoProvider.overrideWithValue(ServerInfo(emailLogin: email, supportEmail: support)),
        ],
        child: Consumer(builder: (_, ref, _) => MaterialApp.router(routerConfig: ref.watch(routerProvider))),
      );

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 4; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pumpAndSettle();
    }
  }

  Future<void> open(WidgetTester t,
      {Size size = const Size(800, 2000), bool email = false, String? support, List<Override> overrides = const []}) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app(email: email, support: support, overrides: overrides));
    await settle(t);
  }

  Future<void> unmount(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 10));
  }

  ProviderContainer container(WidgetTester t) => ProviderScope.containerOf(t.element(find.byType(Navigator).first));

  Future<List<(String, String)>> outbox(WidgetTester t) async =>
      [for (final o in (await t.runAsync(() => db.select(db.outbox).get()))!) (o.groupId, o.type)];

  testWidgets('a deleted group leaves the groups list, the overall card, search and the widget; Deleted groups restores it',
      (t) async {
    await LocalWrites(db, sync).deleteGroup('g-rome');
    await open(t);
    expect(find.text('Rome'), findsNothing);
    expect(find.text('You owe €30.00'), findsNothing); // the overall card (and the widget, which draws it)
    expect(find.text('You are owed €10.00'), findsOneWidget);
    final c = container(t);
    final home = (await t.runAsync(() => c.read(homeDataProvider.future)))!;
    expect(home.groups.map((g) => g.row.id), ['g-cara']);
    expect(home.overview.iOwe, isEmpty);
    expect((await t.runAsync(() => c.read(searchIndexProvider.future)))!.map((g) => g.group.id), ['g-cara']);
    // Friends tab: Ben shared only Rome.
    c.read(routerProvider).go('/?tab=friends');
    await settle(t);
    expect(find.text('Ben'), findsNothing);
    expect(find.text('Cara'), findsOneWidget);
    expect(await outbox(t), [('g-rome', 'group.deleted')]);

    c.read(routerProvider).go('/settings/deleted');
    await settle(t);
    expect(find.text('Rome'), findsOneWidget);
    await t.tap(find.widgetWithText(FilledButton, 'Restore'));
    await settle(t);
    expect(find.text('Restored “Rome”'), findsOneWidget);
    expect(find.text('No deleted groups'), findsOneWidget);
    expect(await outbox(t), [('g-rome', 'group.deleted'), ('g-rome', 'group.restored')]);
    expect((await t.runAsync(() => db.getGroup('g-rome')))!.deleted, isFalse);
    await unmount(t);
  });

  testWidgets('Delete group in its settings: for everyone, back to the list, Undo restores', (t) async {
    await open(t);
    container(t).read(routerProvider).push('/groups/g-rome/settings');
    await settle(t);
    await t.scrollUntilVisible(find.byKey(const Key('delete-group')), 200, scrollable: find.byType(Scrollable).first);
    await t.tap(find.byKey(const Key('delete-group')));
    await t.pumpAndSettle();
    expect(find.text('Deleted for everyone. Any member can restore it from Settings → Deleted groups.'), findsOneWidget);
    await t.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(t);
    expect(find.text('Deleted “Rome”'), findsOneWidget);
    expect(find.byKey(const Key('overall-card')), findsOneWidget); // the groups list
    await t.tap(find.text('Undo'));
    await settle(t);
    expect(await outbox(t), [('g-rome', 'group.deleted'), ('g-rome', 'group.restored')]);
    expect(find.text('Rome'), findsOneWidget);
    await unmount(t);
  });

  testWidgets("a deleted group's page says so and offers Restore; its activity row too", (t) async {
    await LocalWrites(db, sync).deleteGroup('g-rome');
    api.onActivity = (_, _) => (
          items: [
            ActivityItem.fromJson(const {
              'seq': 5, 'feedId': 5, 'kind': 'group_deleted', 'actorMemberId': 'r2', 'name': 'Rome',
              'createdAt': '2026-10-12T08:00:00Z',
            }),
          ],
          nextBefore: null,
        );
    await open(t);
    container(t).read(routerProvider).push('/groups/g-rome?tab=activity');
    await settle(t);
    expect(find.byKey(const Key('deleted-banner')), findsOneWidget);
    expect(find.text('This group is deleted'), findsOneWidget);
    expect(find.text('Ben deleted the group “Rome”'), findsOneWidget);
    await t.tap(find.byKey(const Key('restore-group-row')));
    await settle(t);
    expect(find.byKey(const Key('deleted-banner')), findsNothing);
    expect((await outbox(t)).last, ('g-rome', 'group.restored'));
    await unmount(t);
  });

  testWidgets('Delete friend waits until the non-group balance is settled: the dialog says it and offers Settle up',
      (t) async {
    await open(t);
    container(t).read(routerProvider).push('/friends/u-cara');
    await settle(t);
    await t.tap(find.byKey(const Key('friend-menu')));
    await t.pumpAndSettle();
    await t.tap(find.text('Delete friend'));
    await t.pumpAndSettle();
    expect(find.text('Settle up first'), findsOneWidget);
    expect(find.textContaining('Cara owes you €10.00'), findsWidgets);
    expect(find.widgetWithText(FilledButton, 'Delete'), findsNothing);
    await t.tap(find.descendant(of: find.byType(AlertDialog), matching: find.widgetWithText(FilledButton, 'Settle up')));
    await settle(t);
    expect(find.byType(FriendSettleScreen), findsOneWidget);
    expect(await outbox(t), isEmpty);
    await unmount(t);
  });

  testWidgets('Delete friend deletes our friend group for both of us, offline too; Undo brings it back', (t) async {
    // Settled up with Cara: the taxi is gone.
    await t.runAsync(() => addGroup('g-cara', 'Anna & Cara', 'friend', 'f1', const [
          Member(id: 'f1', name: 'Anna', userId: 'u-anna'),
          Member(id: 'f2', name: 'Cara', userId: 'u-cara'),
        ]));
    await open(t);
    container(t).read(routerProvider).push('/friends/u-cara');
    await settle(t);
    await t.tap(find.byKey(const Key('friend-menu')));
    await t.pumpAndSettle();
    expect(find.text('Report…'), findsNothing); // no support address on this server
    await t.tap(find.text('Delete friend'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(t);
    expect(find.text('Deleted Cara'), findsOneWidget);
    expect(find.text('Cara'), findsNothing); // the Friends tab: no shared group left
    expect(await outbox(t), [('g-cara', 'group.deleted')]);
    expect(find.byKey(const Key('settled-section')), findsNothing);
    await t.tap(find.text('Undo'));
    await settle(t);
    expect(find.byKey(const Key('settled-section')), findsOneWidget); // Cara, settled up
    expect(await outbox(t), [('g-cara', 'group.deleted'), ('g-cara', 'group.restored')]);
    await unmount(t);
  });

  testWidgets('Block and Unblock from the friend page (online); Report… writes to the support address', (t) async {
    api.blockList = const [];
    await open(t, support: 'help@evensies.example');
    container(t).read(routerProvider).push('/friends/u-cara');
    await settle(t);
    await t.tap(find.byKey(const Key('friend-menu')));
    await t.pumpAndSettle();
    expect(find.text('Report…'), findsOneWidget);
    await t.tap(find.text('Block'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(FilledButton, 'Block'));
    await settle(t);
    expect(api.blockCalls, [('block', 'u-cara')]);
    expect(find.text('Blocked Cara'), findsOneWidget);
    await t.tap(find.byKey(const Key('friend-menu')));
    await t.pumpAndSettle();
    await t.tap(find.text('Unblock'));
    await settle(t);
    expect(api.blockCalls.last, ('unblock', 'u-cara'));
    await unmount(t);
  });

  testWidgets('Report… without a mail app: a sheet with the address and the user id to copy', (t) async {
    await open(t, support: 'help@evensies.example');
    container(t).read(routerProvider).push('/friends/u-cara');
    await settle(t);
    await t.tap(find.byKey(const Key('friend-menu')));
    await t.pumpAndSettle();
    await t.tap(find.text('Report…'));
    await settle(t); // no url_launcher in tests: like a phone without a mail app
    expect(find.byKey(const Key('no-mail-app')), findsOneWidget);
    expect(find.text('help@evensies.example'), findsWidgets);
    expect(find.textContaining('User id: u-cara'), findsOneWidget);
    expect(find.byKey(const Key('copy-mail-address')), findsOneWidget);
    expect(find.byKey(const Key('copy-mail-body')), findsOneWidget);
    await unmount(t);
  });

  testWidgets('without email on the server: no email row, no email field when adding a member', (t) async {
    await open(t);
    container(t).read(routerProvider).push('/settings');
    await settle(t);
    expect(find.byKey(const Key('account-email')), findsNothing);
    expect(find.byKey(const Key('blocked-people')), findsOneWidget);
    container(t).read(routerProvider).push('/groups/g-rome/members');
    await settle(t);
    await t.tap(find.text('Add placeholder member'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('member-email')), findsNothing);
    await unmount(t);
  });

  testWidgets('with email: Add email in Settings, and an invite from Add member (offline: the member stays)', (t) async {
    await open(t, email: true);
    container(t).read(routerProvider).push('/settings');
    await settle(t);
    expect(find.text('Add email'), findsOneWidget);
    container(t).read(routerProvider).push('/groups/g-rome/members');
    await settle(t);
    await t.tap(find.text('Add placeholder member'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('member-name')), 'Dario');
    await t.enterText(find.byKey(const Key('member-email')), 'dario@');
    await t.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(t.widget<FilledButton>(find.byKey(const Key('add-member'))).onPressed, isNull);
    await t.enterText(find.byKey(const Key('member-email')), ' Dario@Example.com ');
    await t.pump();
    await t.tap(find.byKey(const Key('add-member')));
    await settle(t);
    // The push before the invite fails offline: the member is kept and the invite waits.
    expect(find.text('Member added. Inviting by email needs a connection — try again from the member list.'), findsOneWidget);
    expect(find.text('Dario'), findsOneWidget);
    expect(api.invites10, isEmpty);

    await t.pump(const Duration(seconds: 5)); // the snackbar goes
    await t.pumpAndSettle();
    api.onPush = (_, events) =>
        PushResult(seqByClientId: {for (final (i, e) in events.indexed) e.clientId: 10 + i}, latestSeq: 20);
    final dario = (await t.runAsync(() => db.select(db.members).get()))!.firstWhere((m) => m.name == 'Dario');
    await t.tap(find.byKey(Key('member-menu-${dario.id}')));
    await t.pumpAndSettle();
    await t.tap(find.text('Invite by email…'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('invite-email')), 'dario@example.com');
    await t.pump();
    await t.tap(find.byKey(const Key('send-invite')));
    await settle(t);
    expect(api.invites10, [('g-rome', dario.id, 'dario@example.com')]);
    expect(find.text('Invite sent to dario@example.com'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('a new group with a type sends it; the list shows the type band', (t) async {
    await open(t);
    container(t).read(routerProvider).push('/?tab=groups');
    await settle(t);
    await t.tap(find.byTooltip('New group'));
    await t.pumpAndSettle();
    await t.tap(find.text('New group').last);
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('group-name')), 'Lisbon');
    await t.tap(find.byKey(const Key('type-home')));
    await t.pump();
    await t.tap(find.widgetWithText(FilledButton, 'Create'));
    await settle(t);
    expect(api.createdTypes, ['home']);
    final row = (await t.runAsync(() => db.select(db.groups).get()))!.firstWhere((g) => g.name == 'Lisbon');
    expect(row.type, 'home');
    await unmount(t);
  });

  testWidgets('group header: the type icon by the name on a band; light status bar icons over a cover photo', (t) async {
    // A 1×1 PNG stands in for the cover.
    final png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGNQcEgAAAFEAMELjZZCAAAAAElFTkSuQmCC');
    await open(t, overrides: [coverProvider.overrideWith((ref, k) async => k.coverId == 'cov1' ? png : null)]);
    container(t).read(routerProvider).push('/groups/g-rome');
    await settle(t);
    AppBar bar() => t.widget<AppBar>(find.byType(AppBar));
    // Light mode: the trip band is a light colour, so dark status bar icons; the icon is in the title, not the band.
    expect(find.byKey(const Key('header-type-icon')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('cover-band')), matching: find.byType(Icon)), findsNothing);
    expect(bar().systemOverlayStyle?.statusBarIconBrightness, Brightness.dark);

    await t.runAsync(() => (db.update(db.groups)..where((g) => g.id.equals('g-rome')))
        .write(const GroupsCompanion(coverImageId: Value('cov1'))));
    await settle(t);
    expect(find.byKey(const Key('cover-image')), findsOneWidget);
    expect(find.byKey(const Key('header-type-icon')), findsNothing);
    expect(bar().systemOverlayStyle?.statusBarIconBrightness, Brightness.light);
    expect(bar().systemOverlayStyle?.statusBarBrightness, Brightness.dark);
    await unmount(t);
  });

  testWidgets('Change cover while offline says so before the photo picker opens', (t) async {
    var picked = 0;
    await open(t, overrides: [
      pickPhotoProvider.overrideWithValue((ImageSource source, {required int maxEdge, required int quality}) async {
        picked++;
        return null;
      }),
    ]);
    sync.offline.value = true;
    container(t).read(routerProvider).push('/groups/g-rome/settings');
    await settle(t);
    await t.tap(find.byKey(const Key('cover')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('cover-choose')));
    await t.pumpAndSettle();
    expect(find.text('Changing the cover needs a connection.'), findsOneWidget);
    expect(picked, 0);
    await unmount(t);
  });

  testWidgets('group settings: the type chips send group.updated {type}', (t) async {
    await open(t);
    container(t).read(routerProvider).push('/groups/g-rome/settings');
    await settle(t);
    expect(t.widget<ChoiceChip>(find.byKey(const Key('type-trip'))).selected, isTrue);
    await t.tap(find.byKey(const Key('type-couple')));
    await settle(t);
    final o = (await t.runAsync(() => db.select(db.outbox).get()))!.single;
    expect(o.type, 'group.updated');
    expect(jsonDecode(o.payloadJson), {'type': 'couple'});
    expect((await t.runAsync(() => db.getGroup('g-rome')))!.type, 'couple');
    await unmount(t);
  });

  group('the wide web layout (1024 px and up)', () {
    testWidgets('groups and friends on the left, the page in the middle, its balances on the right', (t) async {
      debugWideLayout = true; // before the router is built
      final semantics = t.ensureSemantics();
      await open(t, size: const Size(1400, 900));
      expect(find.byKey(const Key('nav-dashboard')), findsOneWidget);
      // Screen readers reach the sidebar too: the page's modal barrier blocks only what is behind it.
      expect(find.semantics.byLabel(RegExp('^Rome')), findsOne);
      expect(find.semantics.byPredicate((n) => n.label.contains('Cara')), findsAny);
      expect(find.semantics.byPredicate((n) => n.tooltip == 'Settings'), findsOne);
      semantics.dispose();
      expect(find.byKey(const Key('nav-group-g-rome')), findsOneWidget);
      expect(find.byKey(const Key('nav-person-u-cara')), findsOneWidget);
      expect(find.text('Dashboard'), findsWidgets); // the middle shows the dashboard, not the groups list again
      expect(find.text('Owes you'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await t.tap(find.byKey(const Key('nav-group-g-rome')));
      await settle(t);
      expect(find.byKey(const Key('wide-group-summary')), findsOneWidget);
      expect(find.text('GROUP BALANCES'), findsOneWidget);
      expect(find.byKey(const Key('wide-settle')), findsOneWidget);
      expect(t.widget<ListTile>(find.byKey(const Key('nav-group-g-rome'))).selected, isTrue);
      // The sidebar is the navigation and its Add expense the only one: no back arrow, no FAB in the middle.
      expect(find.byType(BackButton), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      await t.tap(find.byKey(const Key('nav-add-expense')));
      await settle(t);
      expect(t.widget<ExpenseFormScreen>(find.byType(ExpenseFormScreen)).groupId, 'g-rome');
      Navigator.of(t.element(find.byType(ExpenseFormScreen))).pop();
      await settle(t);

      await t.tap(find.byKey(const Key('nav-person-u-cara')));
      await settle(t);
      expect(find.byKey(const Key('wide-friend-summary')), findsOneWidget);
      expect(find.text('Cara owes you €10.00'), findsWidgets);

      // All expenses (Splitwise's sidebar entry): every group's, newest first, before anything is typed.
      await t.tap(find.byKey(const Key('nav-all-expenses')));
      await settle(t);
      expect(t.widget<ListTile>(find.byKey(const Key('nav-all-expenses'))).selected, isTrue);
      expect(find.text('2 expenses'), findsOneWidget);
      expect(find.text('hotel'), findsOneWidget);
      expect(find.text('taxi'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      await unmount(t);
    });

    testWidgets("a fresh sign-in's first sync shows a spinner, not 'All settled up' and 'No groups yet'", (t) async {
      debugWideLayout = true;
      await open(t, size: const Size(1400, 900));
      sync.firstLoad.value = true;
      await t.pump();
      await t.pump(); // the provider, then the shell
      expect(find.byKey(const Key('nav-dashboard')), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      sync.firstLoad.value = false;
      await settle(t);
      expect(find.byKey(const Key('nav-dashboard')), findsOneWidget);
      await unmount(t);
    });

    testWidgets('a narrow window keeps the one column', (t) async {
      debugWideLayout = true;
      await open(t, size: const Size(800, 1200));
      expect(find.byKey(const Key('nav-dashboard')), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
      await unmount(t);
    });
  });

  testWidgets('a reload waits for the saved session instead of flashing the sign-in page', (t) async {
    final session = StreamController<SessionRow?>();
    addTearDown(session.close);
    await open(t, overrides: [sessionProvider.overrideWith((_) => session.stream)]);
    expect(find.byType(LoginScreen), findsNothing); // still loading: no redirect yet
    session.add(null);
    await settle(t);
    expect(find.byType(LoginScreen), findsOneWidget);
    await unmount(t);
  });

  test('SyncService.firstLoad is up only while a fresh sign-in lists its groups, not on later rounds', () async {
    final fresh = AppDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);
    await fresh.saveSession(const SessionRow(
        id: 1, accessToken: 'a', refreshToken: 'r', userId: 'u-nia', displayName: 'Nia', homeCurrency: 'EUR'));
    final slow = _SlowList(fresh);
    final s = SyncService(db: fresh, api: slow);
    final seen = <bool>[];
    s.firstLoad.addListener(() => seen.add(s.firstLoad.value));
    final first = s.syncAll();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(s.firstLoad.value, isTrue);
    slow.gate.complete();
    await first;
    await s.syncAll(); // a resume or the web's poll, still no groups: the empty state
    expect(seen, [true, false]);
  });

  testWidgets("an email invite's link preselects its placeholder while unlinked; the user still confirms", (t) async {
    api.invites['K7P4QX'] = const InvitePreview(groupId: 'g-x', name: 'Lisbon', memberCount: 3, members: [
      InviteMemberDto(id: 'p1', name: 'Anna', linked: true),
      InviteMemberDto(id: 'p2', name: 'Dario', linked: false),
      InviteMemberDto(id: 'p3', name: 'Elsa', linked: false),
    ]);
    Future<String?> picked(String? m) async {
      await t.pumpWidget(ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          apiProvider.overrideWithValue(api),
          syncProvider.overrideWithValue(sync),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(home: JoinScreen(key: UniqueKey(), code: 'K7P4QX', memberId: m)),
      ));
      await settle(t);
      return t.widget<RadioGroup<String>>(find.byType(RadioGroup<String>)).groupValue;
    }

    expect(await picked('p3'), 'p3');
    expect(await picked('p1'), '__new__'); // linked: not offered
    expect(await picked(null), '__new__');
    expect(api.joins, isEmpty);
    await unmount(t);
  });
}

/// GET /groups that answers (no groups) once [gate] opens.
class _SlowList extends FakeApi {
  _SlowList(super.db);
  final gate = Completer<void>();
  @override
  Future<List<GroupSummaryDto>> listGroups() async {
    await gate.future;
    return const [];
  }
}
