import 'dart:io';

import 'package:drift/native.dart';
import 'package:evensies/core/env.dart';
import 'package:evensies/core/l10n.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/sync/group_state_store.dart';
import 'package:evensies/domain/categories.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/features/auth/login_screen.dart';
import 'package:evensies/features/expense_form/expense_form_screen.dart';
import 'package:evensies/features/group_detail/group_detail_screen.dart';
import 'package:evensies/features/group_settings/group_settings_screen.dart';
import 'package:evensies/features/groups/groups_screen.dart';
import 'package:evensies/features/insights/insights_screen.dart';
import 'package:evensies/features/settings/settings_screen.dart';
import 'package:evensies/features/settle/settle_screen.dart';
import 'package:evensies/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Every language on a small phone with larger text (320×640, ×1.3): no overflow and no exception on the screens
/// with the most words. ponytail: the design's list without search, itemize and the friend page (login, groups and
/// friends tabs, group detail with both tabs, group settings, settle, insights, the expense form in Shares mode with
/// 4 members, settings); add a screen here when one overflows in review.
void main() {
  late AppDatabase db;

  setUpAll(() async {
    Money.loadFromJson(File('../shared/currencies.json').readAsStringSync());
    Categories.loadFromJson(File('../shared/categories.json').readAsStringSync());
    await initializeDateFormatting();
  });
  tearDownAll(() {
    Money.lang = 'en';
    Intl.defaultLocale = null;
  });

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.saveSession(
        const SessionRow(id: 1, accessToken: 'a', refreshToken: 'r', userId: 'u1', displayName: 'Anna Maria'));
    await db.upsertGroup(const GroupRow(
        kind: 'group', id: 'g1', name: 'Summer trip', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'm1',
        simplifyDebts: true));
    const names = ['Anna Maria', 'Benedikt', 'Carolina', 'Dmitri'];
    for (var i = 0; i < names.length; i++) {
      await db.into(db.members).insert(MembersCompanion.insert(id: 'm${i + 1}', groupId: 'g1', name: names[i]));
    }
    Share s(String m, int a) => Share(memberId: m, amount: a);
    await GroupStateStore(db).save(
      'g1',
      GroupState(
        name: 'Summer trip',
        defaultCurrency: 'EUR',
        members: [for (var i = 0; i < names.length; i++) Member(id: 'm${i + 1}', name: names[i])],
        expenses: [
          Expense(
            id: 'x1',
            description: 'Hotel',
            amount: 123456,
            currency: 'EUR',
            paidBy: 'm2',
            date: '2026-10-11',
            shares: [s('m1', 30864), s('m2', 30864), s('m3', 30864), s('m4', 30864)],
          ),
        ],
      ),
      0,
    );
  });
  tearDown(() => db.close());

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets('${locale.languageCode}: small screen, large text', (t) async {
      t.view.physicalSize = const Size(320, 640);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      applyLanguage(locale.languageCode, const []);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      Future<void> show(Widget screen) async {
        await t.pumpWidget(ProviderScope(
          overrides: [
            dbProvider.overrideWithValue(db),
            apiProvider.overrideWithValue(FakeApi(db)),
            syncProvider.overrideWithValue(NoSync(db)),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (c, child) =>
                MediaQuery(data: MediaQuery.of(c).copyWith(textScaler: const TextScaler.linear(1.3)), child: child!),
            home: screen,
          ),
        ));
        for (var i = 0; i < 3; i++) {
          await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
          await t.pumpAndSettle();
        }
      }

      await show(const LoginScreen());
      await show(const SettingsScreen());
      await show(const GroupsScreen());
      await show(const GroupsScreen(tab: 'friends'));
      await show(const GroupSettingsScreen(groupId: 'g1'));
      await show(const SettleScreen(groupId: 'g1'));
      await show(const InsightsScreen(groupId: 'g1'));

      await show(const GroupDetailScreen(groupId: 'g1'));
      final l = lookupAppLocalizations(locale);
      await t.tap(find.widgetWithText(Tab, l.balances));
      await t.pumpAndSettle();

      await show(const ExpenseFormScreen(groupId: 'g1'));
      final shares = find.byKey(const Key('mode-shares'));
      await t.ensureVisible(shares);
      await t.pumpAndSettle();
      await t.tap(shares);
      await t.pumpAndSettle();
      await t.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await t.pumpAndSettle();

      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(milliseconds: 10));
    });
  }
}
