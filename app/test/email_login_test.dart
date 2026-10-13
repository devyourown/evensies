import 'package:drift/native.dart';
import 'package:evensies/core/env.dart';
import 'package:evensies/data/api/dto.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/features/auth/auth_service.dart';
import 'package:evensies/features/auth/email_code_form.dart';
import 'package:evensies/features/auth/login_screen.dart';
import 'package:evensies/features/settings/account_email_screen.dart';
import 'package:evensies/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Email sign-in and the account email (docs/API.md, Email sign-in and Account email): codes, never passwords.
void main() {
  test('addresses are checked like the server: trimmed, lower-cased, ASCII domain, 254 at most', () {
    expect(normalizeEmail('  Anna@Example.COM '), 'anna@example.com');
    expect(emailValid(' Anna@Example.com '), isTrue);
    expect(emailValid('anna.rossi+trip@mail.example.co.uk'), isTrue);
    expect(emailValid('anna@localhost'), isFalse); // needs a dot
    expect(emailValid('anna rossi@example.com'), isFalse);
    expect(emailValid('anna@exämple.com'), isFalse); // no SMTPUTF8
    expect(emailValid('${'a' * 65}@example.com'), isFalse);
    expect(emailValid('a@${'b' * 250}.com'), isFalse);
  });

  group('the code form', () {
    late List<String> sent;
    late List<(String, String)> verified;
    Object? verifyError;

    setUp(() {
      sent = [];
      verified = [];
      verifyError = null;
    });

    Widget form() => MaterialApp(
          home: Scaffold(
            body: EmailCodeForm(
              onSend: (e) async => sent.add(e),
              onVerify: (e, c) async {
                if (verifyError != null) throw verifyError!;
                verified.add((e, c));
              },
            ),
          ),
        );

    Future<void> toCode(WidgetTester t) async {
      await t.pumpWidget(form());
      expect(t.widget<FilledButton>(find.byKey(const Key('send-code'))).onPressed, isNull);
      await t.enterText(find.byKey(const Key('email-field')), 'anna@');
      await t.pump();
      expect(find.text('Enter a valid email address'), findsOneWidget);
      await t.enterText(find.byKey(const Key('email-field')), ' Anna@Example.com');
      await t.pump();
      await t.tap(find.byKey(const Key('send-code')));
      await t.pump();
    }

    testWidgets('sends the normalized address, takes 6 digits only, and the sixth digit verifies', (t) async {
      await toCode(t);
      expect(sent, ['anna@example.com']);
      expect(find.text('Enter the 6-digit code we sent to anna@example.com. It expires in 10 minutes.'), findsOneWidget);
      await t.enterText(find.byKey(const Key('code-field')), '12a3 4');
      await t.pump();
      expect(t.widget<TextField>(find.byKey(const Key('code-field'))).controller!.text, '1234');
      expect(t.widget<FilledButton>(find.byKey(const Key('verify-code'))).onPressed, isNull);
      expect(verified, isEmpty);
      await t.enterText(find.byKey(const Key('code-field')), '12345678');
      await t.pump();
      expect(t.widget<TextField>(find.byKey(const Key('code-field'))).controller!.text, '123456');
      expect(verified, [('anna@example.com', '123456')]);
      await t.pumpWidget(const SizedBox()); // stops the resend countdown
    });

    testWidgets('Resend unlocks after 30 s; Use a different email goes back', (t) async {
      await toCode(t);
      TextButton resend() => t.widget<TextButton>(find.byKey(const Key('resend-code')));
      expect(resend().onPressed, isNull);
      expect(find.text('Resend code in 30 s'), findsOneWidget);
      await t.pump(const Duration(seconds: 29));
      expect(resend().onPressed, isNull);
      expect(find.text('Resend code in 1 s'), findsOneWidget);
      await t.pump(const Duration(seconds: 1));
      expect(resend().onPressed, isNotNull);
      expect(find.text('Resend code'), findsOneWidget);
      await t.tap(find.byKey(const Key('resend-code')));
      await t.pump();
      expect(sent, ['anna@example.com', 'anna@example.com']);
      expect(find.text('We sent a new code.'), findsOneWidget);
      expect(resend().onPressed, isNull); // 30 s again

      await t.tap(find.byKey(const Key('other-email')));
      await t.pump();
      expect(find.byKey(const Key('email-field')), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 5)); // the snackbar's timer
    });

    testWidgets("a refused code says why in the user's words", (t) async {
      verifyError = const ApiException(status: 400, code: 'CODE_INVALID', message: 'Invalid code');
      await toCode(t);
      await t.enterText(find.byKey(const Key('code-field')), '000000');
      await t.pump();
      expect(find.text('That code is wrong or has expired. Ask for a new one.'), findsOneWidget);
      expect(find.text('Invalid code'), findsNothing);
      await t.pumpWidget(const SizedBox());
    });
  });

  group('screens', () {
    late AppDatabase db;
    late FakeApi10 api;
    late SharedPreferences prefs;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      api = FakeApi10(db);
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });
    tearDown(() => db.close());

    Widget app(Widget home, ServerInfo info) => ProviderScope(
          overrides: [
            dbProvider.overrideWithValue(db),
            apiProvider.overrideWithValue(api),
            sharedPreferencesProvider.overrideWithValue(prefs),
            serverInfoProvider.overrideWith((_) async => info),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(routes: [
              GoRoute(path: '/', builder: (_, _) => const Scaffold(body: Text('home')), routes: [
                GoRoute(path: 'page', builder: (_, _) => home),
                GoRoute(path: 'login/email', builder: (_, _) => const Text('email sign-in')),
              ]),
            ], initialLocation: '/page'),
          ),
        );

    Future<void> settle(WidgetTester t) async {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pumpAndSettle();
    }

    testWidgets('the login screen offers email only when the server sends email, and hides what it lacks', (t) async {
      await t.pumpWidget(app(const LoginScreen(), const ServerInfo(googleLogin: false)));
      await settle(t);
      expect(find.text('Continue with email'), findsNothing);
      expect(find.text('Continue with Google'), findsNothing);

      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(app(const LoginScreen(), const ServerInfo(emailLogin: true)));
      await settle(t);
      expect(find.text('Continue with Google'), findsOneWidget);
      await t.tap(find.text('Continue with email'));
      await settle(t);
      expect(find.text('email sign-in'), findsOneWidget);
    });

    test('/info: the answer is kept per server; offline it falls back to that, else to no email', () async {
      final c = ProviderContainer(overrides: [
        dbProvider.overrideWithValue(db),
        apiProvider.overrideWithValue(api),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ]);
      addTearDown(c.dispose);
      final info = await c.read(serverInfoProvider.future);
      expect((info.emailLogin, info.appleLogin, info.googleLogin, info.supportEmail), (false, true, true, null));

      api.info = {'emailLogin': true, 'appleLogin': false, 'supportEmail': 'help@x.example', 'unknown': 1};
      c.invalidate(serverInfoProvider);
      final online = await c.read(serverInfoProvider.future);
      expect((online.emailLogin, online.appleLogin, online.supportEmail), (true, false, 'help@x.example'));

      api.info = null; // offline again: what this server said last time
      c.invalidate(serverInfoProvider);
      final kept = await c.read(serverInfoProvider.future);
      expect((kept.emailLogin, kept.appleLogin, kept.supportEmail), (true, false, 'help@x.example'));
    });

    testWidgets('Settings → Email: a code sent to the new address saves it on the account', (t) async {
      await db.saveSession(const SessionRow(id: 1, accessToken: 'a', refreshToken: 'r', userId: 'u1', displayName: 'Anna'));
      await t.pumpWidget(app(const AccountEmailScreen(), const ServerInfo(emailLogin: true)));
      await settle(t);
      expect(find.byKey(const Key('remove-email')), findsNothing);
      await t.enterText(find.byKey(const Key('email-field')), 'anna@example.com');
      await t.pump();
      await t.tap(find.byKey(const Key('send-code')));
      await settle(t);
      expect(api.emailCodes, ['anna@example.com']);
      await t.enterText(find.byKey(const Key('code-field')), '123456');
      await settle(t);
      expect(find.text('home'), findsOneWidget); // back to Settings
      expect(find.text('Email saved'), findsOneWidget);
      expect((await t.runAsync(db.getSession))!.email, 'anna@example.com');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 5));
    });

    testWidgets('a bouncing address says so and can be removed', (t) async {
      await db.saveSession(const SessionRow(
          id: 1, accessToken: 'a', refreshToken: 'r', userId: 'u1', displayName: 'Anna',
          email: 'old@example.com', emailBounced: true));
      await t.pumpWidget(app(const AccountEmailScreen(), const ServerInfo(emailLogin: true)));
      await settle(t);
      expect(find.text('Emails to this address bounce — change it or verify it again'), findsOneWidget);
      await t.tap(find.byKey(const Key('remove-email')));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(FilledButton, 'Remove'));
      await settle(t);
      expect(api.emailRemovals, 1);
      expect((await t.runAsync(db.getSession))!.email, isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 5));
    });
  });
}
