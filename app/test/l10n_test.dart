import 'dart:convert';
import 'dart:io';

import 'package:evensies/core/env.dart';
import 'package:evensies/core/l10n.dart';
import 'package:evensies/core/strings.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// docs/API.md 언어·웹: 13 languages, English the source; the ARB files and the shared text table agree.
void main() {
  Map<String, dynamic> arb(String lang) =>
      jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map<String, dynamic>;
  final en = arb('en');
  final keys = {for (final k in en.keys) if (!k.startsWith('@')) k};
  // `{name}` or `{count, plural, …`: a placeholder, not an ICU branch body (`other{…}`, `=1{…}`).
  final placeholder = RegExp(r'(?<![A-Za-z0-9=])\{(\w+)(?=[,}])');
  Set<String> used(String text) => {for (final m in placeholder.allMatches(text)) m[1]!};
  final langs = [for (final l in AppLocalizations.supportedLocales) l.languageCode];

  test('13 languages: the ARB files, the endonyms and the shared table', () {
    expect(langs.toSet(), endonyms.keys.toSet());
    expect(langs, hasLength(13));
    expect(Strings.languages.toSet(), endonyms.keys.toSet());
  });

  test('English: every key has a description and declares its placeholders', () {
    for (final k in keys) {
      final meta = en['@$k'] as Map<String, dynamic>?;
      expect(meta?['description'], isA<String>(), reason: k);
      final declared = ((meta?['placeholders'] as Map?)?.keys ?? const <String>[]).toSet();
      expect(used(en[k] as String), declared, reason: k);
    }
  });

  for (final lang in langs.where((l) => l != 'en')) {
    test('$lang: the same keys and placeholders as English', () {
      final t = arb(lang);
      expect({for (final k in t.keys) if (!k.startsWith('@')) k}, keys..remove('@@locale'));
      for (final k in keys) {
        expect(used(t[k] as String), used(en[k] as String), reason: '$lang $k');
      }
    });
  }

  test("Settings' System (…) names the phone's language, also while another one is picked", () async {
    SharedPreferences.setMockInitialValues({LanguageSetting.key: 'ko'});
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(await SharedPreferences.getInstance()),
      deviceLocalesProvider.overrideWithValue(const [Locale('xx'), Locale('en', 'US'), Locale('ko', 'US')]),
    ]);
    addTearDown(c.dispose);
    expect((c.read(languageProvider), c.read(deviceLanguageProvider)), ('ko', 'en'));
    await c.read(languageSettingProvider.notifier).set(null);
    expect(c.read(languageProvider), 'en');
  });

  test('ko: no particle crutches like 이(가) or 을(를) after a placeholder (strings.json writes 님이 or a noun)', () {
    final crutch = RegExp(r'\((가|이|를|을|는|은|와|과|으|로)\)');
    for (final MapEntry(:key, :value) in arb('ko').entries) {
      if (key.startsWith('@')) continue;
      expect(crutch.hasMatch(value as String), isFalse, reason: '$key: $value');
    }
  });

  testWidgets('keepAll: Korean wraps at spaces only, never inside a word; other languages are left alone', (t) async {
    const sentence = 'Jin님이 ‘Affitto’ 지출을 매달 반복하도록 설정했어요 · 내 확인을 기다리는 중';
    // Where each laid-out line starts, at a width that wraps it several times.
    List<int> starts(String text) {
      final p = TextPainter(
          text: TextSpan(text: text, style: const TextStyle(fontSize: 10)), textDirection: TextDirection.ltr)
        ..layout(maxWidth: 125);
      return [
        for (final m in p.computeLineMetrics()) p.getPositionForOffset(Offset(0, m.baseline - m.ascent + 1)).offset,
      ];
    }

    bool midWord(String text) => starts(text).any((i) => i > 0 && text[i - 1] != ' ');
    expect(midWord(sentence), isTrue); // what Flutter does by itself: "설정|했어요"
    final kept = keepAll(sentence, 'ko');
    expect(starts(kept).length, greaterThan(2));
    expect(midWord(kept), isFalse);
    expect(kept.replaceAll('\u2060', ''), sentence);
    expect(keepAll('Ristorante da Mario', 'it'), 'Ristorante da Mario');
  });

  test('every language loads and renders plurals and selects', () {
    for (final lang in langs) {
      final l = lookupAppLocalizations(Locale(lang));
      expect(l.localeName, lang);
      expect(l.memberCount(3), contains('3'), reason: lang);
      expect(l.seriesRepeatsNext('monthly', 'X'), contains('X'), reason: lang);
      expect(l.itemCount(1), isNotEmpty, reason: lang);
    }
  });

  test('the app copy of the shared table is byte-equal', () {
    expect(File('assets/strings.json').readAsBytesSync(), File('../shared/strings.json').readAsBytesSync());
  });
}
