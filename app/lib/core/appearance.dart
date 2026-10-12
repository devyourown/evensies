import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'env.dart';

/// Settings → Appearance: System, Light or Dark (prefs `themeMode`; docs/API.md 화면 모양).
class ThemeModeSetting extends Notifier<ThemeMode> {
  static const key = 'themeMode';
  @override
  ThemeMode build() => ThemeMode.values.asNameMap()[ref.read(sharedPreferencesProvider).getString(key)] ?? ThemeMode.system;

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeSetting, ThemeMode>(ThemeModeSetting.new);
