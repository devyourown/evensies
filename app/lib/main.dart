import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/env.dart';
import 'core/money.dart';
import 'core/strings.dart';
import 'domain/categories.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Money.loadFromAssets();
  await Strings.loadFromAssets();
  Categories.loadFromJson(await rootBundle.loadString('assets/categories.json'));
  await initializeDateFormatting(); // every locale's date names (docs/API.md 날짜)
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const EvensiesApp(),
  ));
}
