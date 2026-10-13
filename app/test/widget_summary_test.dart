import 'dart:convert';
import 'dart:io';

import 'package:evensies/core/money.dart';
import 'package:evensies/domain/overview.dart';
import 'package:evensies/features/home_widget/widget_summary.dart';
import 'package:evensies/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// docs/API.md, Home screen widget: the payload Dart writes for the native widgets.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final de = lookupAppLocalizations(const Locale('de'));
  final now = DateTime(2026, 10, 11, 10, 42);
  const perEur = {'EUR': 1.0, 'USD': 1.1, 'GBP': 0.85, 'JPY': 160.0, 'KRW': 1450.0, 'CHF': 0.95};

  setUpAll(() async {
    Money.loadFromJson(File('../shared/currencies.json').readAsStringSync());
    await initializeDateFormatting();
  });
  tearDown(() => Money.lang = 'en');

  Map<String, Object?> summary(Overview o, {AppLocalizations? l, Map<String, double>? rates, bool signedIn = true}) =>
      widgetSummary(l ?? en,
          signedIn: signedIn, overview: o, home: 'EUR', perEur: rates, now: now, locale: (l ?? en).localeName);

  List<String> amounts(Map<String, Object?> p) => [for (final x in p['lines']! as List) (x as Map)['amount'] as String];

  test('golden, en: owed and owing in one currency each, without rates', () {
    final p = summary(const Overview(owedToMe: {'EUR': 4210}, iOwe: {'KRW': 12000}));
    expect(p, {
      'v': 1,
      'total': null,
      'lines': [
        {'text': 'You are owed', 'amount': '€42.10', 'tone': 'owed'},
        {'text': 'You owe', 'amount': '₩12,000', 'tone': 'owe'},
      ],
      'empty': null,
      'updated': 'Updated Oct 11 10:42\u202fAM', // intl's narrow space before AM
    });
  });

  test('golden, de: the same in German notation', () {
    Money.lang = 'de';
    final p = summary(const Overview(owedToMe: {'EUR': 4210}, iOwe: {'KRW': 12000}), l: de);
    expect(jsonDecode(jsonEncode(p)), {
      'v': 1,
      'total': null,
      'lines': [
        {'text': 'Du bekommst', 'amount': '42,10 €', 'tone': 'owed'},
        {'text': 'Du schuldest', 'amount': '12.000 ₩', 'tone': 'owe'},
      ],
      'empty': null,
      'updated': 'Aktualisiert 11. Okt. 10:42',
    });
  });

  test('nets per currency, zeros dropped', () {
    final p = summary(const Overview(owedToMe: {'EUR': 5000, 'USD': 1000}, iOwe: {'EUR': 2000, 'USD': 1000}));
    expect(p['lines'], [
      {'text': 'You are owed', 'amount': '€30.00', 'tone': 'owed'},
    ]);
  });

  test('several currencies that convert: a ≈ total in the home currency, and still the lines per currency', () {
    final p = summary(const Overview(owedToMe: {'EUR': 1000, 'USD': 1100}), rates: perEur);
    expect(p['total'], {'text': 'You are owed', 'amount': '≈ €20.00', 'tone': 'owed'});
    expect(amounts(p), ['€10.00', '\$11.00']); // the medium widget shows them under the total
    final owe = summary(const Overview(owedToMe: {'EUR': 1000}, iOwe: {'USD': 3300}), rates: perEur);
    expect(owe['total'], {'text': 'You owe', 'amount': '≈ €20.00', 'tone': 'owe'});
    expect(summary(const Overview(owedToMe: {'EUR': 1000, 'USD': 1100}))['total'], isNull); // no rates
  });

  test('a converted total of zero, or no rates: largest first, at most 4', () {
    final zero = summary(const Overview(owedToMe: {'EUR': 1000}, iOwe: {'USD': 1100}), rates: perEur);
    expect(zero['total'], isNull);
    expect(amounts(zero), ['€10.00', '\$11.00']);

    const five = Overview(owedToMe: {'EUR': 100, 'GBP': 10000, 'JPY': 500000}, iOwe: {'USD': 2000, 'CHF': 50});
    expect(amounts(summary(five, rates: const {'EUR': 1.0, 'GBP': 0.85, 'USD': 1.1, 'CHF': 0.95})), [
      '£100.00', // the ones with a rate by size
      '\$20.00',
      '€1.00',
      'CHF 0.50',
    ]); // JPY (no rate) is the fifth: left out
    expect(summary(five)['lines'], hasLength(4)); // no rates at all: by code
  });

  test('signed out and settled: no lines, one sentence', () {
    final out = summary(const Overview(owedToMe: {'EUR': 100}), signedIn: false);
    expect(out['lines'], isEmpty);
    expect(out['empty'], 'Sign in to see your balance');
    expect(out['updated'], isNull); // no stale time on a signed-out widget
    final even = summary(const Overview(owedToMe: {'EUR': 100}, iOwe: {'EUR': 100}));
    expect(even['lines'], isEmpty);
    expect(even['empty'], 'All settled up');
    expect(summary(Overview.empty, l: de)['empty'], 'Alles ausgeglichen');
  });

  test('the writer saves only new content, never on the web', () async {
    final saved = <String>[];
    final w = WidgetWriter(save: (j) async => saved.add(j), web: false);
    final a = summary(const Overview(owedToMe: {'EUR': 100}));
    await w.write(a);
    await w.write({...a, 'updated': 'Updated Oct 11 10:43 AM'}); // only the time changed
    expect(saved, hasLength(1));
    await w.write(summary(const Overview(owedToMe: {'EUR': 200})));
    expect(saved, hasLength(2));
    expect(jsonDecode(saved.last)['lines'][0]['amount'], '€2.00');

    final web = <String>[];
    await WidgetWriter(save: (j) async => web.add(j), web: true).write(a);
    expect(web, isEmpty);
  });

  test("the iOS widget extension carries the app's version (an install refuses an extension without one)", () {
    final plist = File('ios/EvensiesWidget/Info.plist').readAsStringSync();
    expect(plist, contains('<key>CFBundleShortVersionString</key>\n\t<string>\$(FLUTTER_BUILD_NAME)</string>'));
    expect(plist, contains('<key>CFBundleVersion</key>\n\t<string>\$(FLUTTER_BUILD_NUMBER)</string>'));
    // Defined by Generated.xcconfig, which the widget's own xcconfig includes (not Flutter/Debug.xcconfig: pods).
    expect(File('ios/EvensiesWidget/EvensiesWidget.xcconfig').readAsStringSync(),
        contains('#include "../Flutter/Generated.xcconfig"'));
    final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    final widget = [
      for (final m in RegExp(r'isa = XCBuildConfiguration;(.*?)name = \w+;', dotAll: true).allMatches(pbx))
        if (m[1]!.contains('INFOPLIST_FILE = EvensiesWidget/Info.plist')) m[1]!,
    ];
    expect(widget, hasLength(3)); // Debug, Release, Profile
    for (final c in widget) {
      expect(c, contains('/* EvensiesWidget.xcconfig */;'));
    }
  });

  test('a failed save is tried again next time', () async {
    var fail = true;
    final saved = <String>[];
    final w = WidgetWriter(save: (j) async {
      if (fail) throw StateError('no widget here');
      saved.add(j);
    }, web: false);
    final a = summary(const Overview(owedToMe: {'EUR': 100}));
    await w.write(a);
    fail = false;
    await w.write(a);
    expect(saved, hasLength(1));
  });
}
