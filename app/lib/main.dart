import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/env.dart';
import 'core/l10n.dart';
import 'core/money.dart';
import 'core/strings.dart';
import 'data/db/database.dart';
import 'domain/categories.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The web: a pushed page (a group, an expense, members) shows its own address, so a reload stays on it. Every
  // pushed path is a real nested route under '/' (router.dart), so the address always deep-links back to that page.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  await Money.loadFromAssets();
  await Strings.loadFromAssets();
  Categories.loadFromJson(await rootBundle.loadString('assets/categories.json'));
  await initializeDateFormatting(); // every locale's date names (docs/API.md, Languages and web: dates)
  final prefs = await SharedPreferences.getInstance();
  final AppDatabase? db;
  try {
    db = await AppDatabase.openChecked();
  } on TabInUse {
    return runApp(const _NoStorage(otherTab: true));
  }
  if (db == null) return runApp(const _NoStorage());
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs), dbProvider.overrideWithValue(db)],
    child: const EvensiesApp(),
  ));
}

/// The browser can't open the app's database at all, or [otherTab] has it: say so, rather than a sign-in that does
/// nothing.
class _NoStorage extends StatelessWidget {
  final bool otherTab;
  const _NoStorage({this.otherTab = false});
  @override
  Widget build(BuildContext context) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(otherTab ? context.l.browserOtherTab : context.l.browserNoStorage, textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      );
}
