import 'package:drift/native.dart';
import 'package:evensies/core/env.dart';
import 'package:evensies/data/api/dto.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/features/auth/auth_service.dart';
import 'package:evensies/features/auth/name_screen.dart';
import 'package:evensies/providers.dart';
import 'package:evensies/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// The store reviewers' sign-in (docs/API.md POST /auth/review): a username and password, offered only when the
/// server's `GET /info` says reviewLogin.
class _Api extends FakeApi10 {
  _Api(super.db);
  final calls = <(String, String)>[];
  Object? error;

  @override
  Future<AuthResponse> authReview(String username, String password) async {
    calls.add((username, password));
    if (error != null) throw error!;
    return const AuthResponse(accessToken: 'a', refreshToken: 'r', user: UserDto(id: 'u-review', displayName: ''));
  }
}

void main() {
  late AppDatabase db;
  late _Api api;
  late SharedPreferences prefs;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    api = _Api(db);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });
  tearDown(() => db.close());

  test('/info: reviewLogin only when the server says true; old servers and the fallback hide it', () {
    expect(ServerInfo.fallback.reviewLogin, isFalse);
    expect(ServerInfo.fromJson({}).reviewLogin, isFalse);
    expect(ServerInfo.fromJson({'reviewLogin': false}).reviewLogin, isFalse);
    expect(ServerInfo.fromJson({'reviewLogin': true}).reviewLogin, isTrue);
  });

  // The real router: signed out it shows the login screen, and a sign-in goes where Apple's and Google's go.
  Widget app(ServerInfo info) => ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          apiProvider.overrideWithValue(api),
          syncProvider.overrideWithValue(NoSync(db, api)),
          sharedPreferencesProvider.overrideWithValue(prefs),
          serverInfoProvider.overrideWith((_) async => info),
        ],
        child: Consumer(builder: (_, ref, _) => MaterialApp.router(routerConfig: ref.watch(routerProvider))),
      );

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 3; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pumpAndSettle();
    }
  }

  Future<void> unmount(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 10)); // drift closes its query streams on a timer
  }

  Future<void> openDialog(WidgetTester t) async {
    await t.pumpWidget(app(const ServerInfo(reviewLogin: true)));
    await settle(t);
    await t.tap(find.text('Demo sign-in'));
    await settle(t);
  }

  Future<void> type(WidgetTester t, String username, String password) async {
    await t.enterText(find.byKey(const Key('review-username')), username);
    await t.enterText(find.byKey(const Key('review-password')), password);
    await t.pump();
  }

  testWidgets('the button shows only when the server enables it', (t) async {
    await t.pumpWidget(app(const ServerInfo()));
    await settle(t);
    expect(find.text('Continue with Google'), findsOneWidget); // the login screen
    expect(find.text('Demo sign-in'), findsNothing);

    await unmount(t);
    await t.pumpWidget(app(const ServerInfo(reviewLogin: true)));
    await settle(t);
    expect(find.byKey(const Key('login-review')), findsOneWidget);
    await unmount(t);
  });

  testWidgets('Enter signs in with the typed values; the first time the name screen comes next', (t) async {
    await openDialog(t);
    expect(t.widget<FilledButton>(find.byKey(const Key('review-submit'))).onPressed, isNull);
    final password = t.widget<TextField>(find.byKey(const Key('review-password')));
    expect((password.obscureText, password.autofillHints), (true, null));
    await type(t, ' play-reviewer ', 'test-review-password-0123456789');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await settle(t);
    expect(api.calls, [('play-reviewer', 'test-review-password-0123456789')]);
    expect((await t.runAsync(db.getSession))!.userId, 'u-review');
    expect(find.byType(NameScreen), findsOneWidget);
    expect(find.text('Demo sign-in'), findsNothing); // the dialog went with the login screen
    await unmount(t);
  });

  testWidgets("a wrong username or password says so, never which; 429 asks to wait; the dialog stays", (t) async {
    await openDialog(t);
    api.error = const ApiException(status: 401, code: 'UNAUTHORIZED', message: 'Unauthorized');
    await type(t, 'play-reviewer', 'wrong-review-password-000000000');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await settle(t);
    expect(find.text('Wrong username or password'), findsOneWidget);
    expect(find.text('Unauthorized'), findsNothing);

    api.error = const ApiException(status: 429, code: 'RATE_LIMITED', message: 'Too many requests');
    await t.testTextInput.receiveAction(TextInputAction.done); // the password field kept the focus
    await settle(t);
    expect(find.text('Too many tries. Wait a minute and try again.'), findsOneWidget);
    expect(find.text('Wrong username or password'), findsNothing);

    api.error = FakeApi.offline;
    await t.tap(find.byKey(const Key('review-submit')));
    await settle(t);
    expect(find.text('You are offline. Try again later.'), findsOneWidget);

    // Turned off on the server after /info was read: no "doesn't exist" on a sign-in.
    api.error = const ApiException(status: 404, code: 'NOT_FOUND', message: 'No such endpoint');
    await t.tap(find.byKey(const Key('review-submit')));
    await settle(t);
    expect(find.text('Something went wrong. Try again.'), findsOneWidget);
    expect(find.text("That doesn't exist any more."), findsNothing);
    expect(api.calls, hasLength(4));
    expect(await t.runAsync(db.getSession), isNull);
    expect(find.byKey(const Key('review-username')), findsOneWidget);
    await unmount(t);
  });
}
