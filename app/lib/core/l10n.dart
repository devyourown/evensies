import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../l10n/app_localizations_en.dart';
import 'env.dart';
import 'money.dart';

export '../l10n/app_localizations.dart' show AppLocalizations, lookupAppLocalizations;

final _en = AppLocalizationsEn();

extension L10nContext on BuildContext {
  /// The UI text in the app's language. English for a widget shown without the app's localizations (widget tests that
  /// pump a bare `MaterialApp`).
  AppLocalizations get l => Localizations.of<AppLocalizations>(this, AppLocalizations) ?? _en;
}

/// Each language's own name, for Settings → Language (docs/API.md, App language). Not translated.
const endonyms = {
  'en': 'English',
  'ko': '한국어',
  'nl': 'Nederlands',
  'fr': 'Français',
  'de': 'Deutsch',
  'id': 'Bahasa Indonesia',
  'it': 'Italiano',
  'ja': '日本語',
  'pl': 'Polski',
  'pt': 'Português (Brasil)',
  'es': 'Español',
  'sv': 'Svenska',
  'th': 'ไทย',
};

/// Settings → Language: one of [endonyms]' codes, or null for the phone's language (prefs `language`).
class LanguageSetting extends Notifier<String?> {
  static const key = 'language';
  @override
  String? build() {
    final v = ref.read(sharedPreferencesProvider).getString(key);
    return endonyms.containsKey(v) ? v : null;
  }

  Future<void> set(String? code) async {
    state = code;
    final p = ref.read(sharedPreferencesProvider);
    await (code == null ? p.remove(key) : p.setString(key, code));
  }
}

final languageSettingProvider = NotifierProvider<LanguageSetting, String?>(LanguageSetting.new);

/// The phone's language list; invalidated when it changes (the app's `didChangeLocales`).
final deviceLocalesProvider = Provider<List<Locale>>((_) => PlatformDispatcher.instance.locales);

/// The phone's language: the first one we have, else English (Settings' "System (…)").
final deviceLanguageProvider = Provider<String>((ref) {
  for (final l in ref.watch(deviceLocalesProvider)) {
    if (endonyms.containsKey(l.languageCode)) return l.languageCode;
  }
  return 'en';
});

/// The UI language: the setting, else the phone's.
final languageProvider =
    Provider<String>((ref) => ref.watch(languageSettingProvider) ?? ref.watch(deviceLanguageProvider));

/// [text] as Korean readers expect it to wrap, at spaces only (CSS `word-break: keep-all`): Flutter breaks between any
/// two Hangul syllables, even inside a word, so for `ko` a U+2060 WORD JOINER goes between a syllable and the character
/// next to it within a word. Display only: never in text that is shared or sent. A word too long for a line still
/// breaks. ponytail: the feed, dialogs, snackbars, the lock screen and Settings; other ARB text wraps per syllable
/// until Flutter has keep-all.
String keepAll(String text, String lang) {
  if (lang != 'ko') return text;
  bool hangul(int c) => c >= 0xAC00 && c <= 0xD7A3;
  bool space(int c) => c == 0x20 || c == 0x0A || c == 0x09 || c == 0xA0 || c == 0x3000;
  final b = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final c = text.codeUnitAt(i);
    if (i > 0) {
      final p = text.codeUnitAt(i - 1);
      if (!space(p) && !space(c) && (hangul(p) || hangul(c))) b.writeCharCode(0x2060);
    }
    b.writeCharCode(c);
  }
  return b.toString();
}

/// Money and dates follow [lang]: amounts in its notation; dates in the phone's region when it speaks the same language
/// (`de_AT`), else in [lang] (docs/API.md, Languages and web: dates).
void applyLanguage(String lang, List<Locale> device) {
  Money.lang = lang;
  final same = device.where((l) => l.languageCode == lang).firstOrNull;
  final tag = same == null || same.countryCode == null ? lang : '${lang}_${same.countryCode}';
  Intl.defaultLocale = Intl.verifiedLocale(tag, DateFormat.localeExists, onFailure: (_) => lang);
}
