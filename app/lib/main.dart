import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/env.dart';
import 'core/money.dart';
import 'domain/categories.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Money.loadFromAssets();
  Categories.loadFromJson(await rootBundle.loadString('assets/categories.json'));
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: const EvensiesApp(),
  ));
}
