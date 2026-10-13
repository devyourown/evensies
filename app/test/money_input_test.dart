import 'dart:io';

import 'package:evensies/core/money.dart';
import 'package:flutter_test/flutter_test.dart';

/// docs/API.md, Amount input: what a person types in each language → minor units, or null.
void main() {
  setUpAll(() => Money.loadFromJson(File('../shared/currencies.json').readAsStringSync()));

  const cases = [
    ('en', 'EUR', '1,234.56', 123456),
    ('de', 'EUR', '1.234,56', 123456),
    ('de', 'EUR', '12,5', 1250),
    ('de', 'EUR', '12.50', 1250),
    ('de', 'EUR', '12.345', 1234500),
    ('en', 'EUR', '12.345', null),
    ('fr', 'EUR', '1 234,56', 123456),
    ('en', 'KRW', '1,234', 1234),
    ('ko', 'KRW', '12.3', null),
    ('en', 'KWD', '1,234', 1234000),
    ('de', 'KWD', '1,234', 1234),
    ('en', 'EUR', '1.2.3', null),
    ('de', 'EUR', '12,', 1200),
    ('de', 'EUR', '-10,00', -1000),
    ('en', 'EUR', '12.50', 1250),
    ('en', 'EUR', '12', 1200),
    ('de', 'EUR', '1.234.567', 123456700),
    ('en', 'EUR', '1.234,56', 123456), // lenient: not 3 digits after the last separator
    ('sv', 'EUR', '1 234,56', 123456),
    ('de', 'CHF', "1'234.50", 123450),
    ('en', 'EUR', '€12.50', 1250),
    ('en', 'EUR', '', null),
    ('en', 'EUR', '-', null),
    ('en', 'EUR', 'abc', null),
  ];
  for (final (lang, currency, text, minor) in cases) {
    test('$lang $currency "$text" → $minor', () => expect(parseMoney(text, currency, lang: lang), minor));
  }

  test('parseDecimal: the last separator is the decimal mark', () {
    expect(parseDecimal('1,0842'), 1.0842);
    expect(parseDecimal('33,33'), 33.33);
    expect(parseDecimal('1.234,5'), 1234.5);
    expect(parseDecimal('1,234.5'), 1234.5);
    expect(parseDecimal('2'), 2);
    expect(parseDecimal('1.2.3'), isNull);
    expect(parseDecimal(''), isNull);
    expect(parseDecimal('.'), isNull);
  });

  test('inputAmount writes the language\'s decimal mark and no grouping', () {
    expect(inputAmount(1250, 'EUR', lang: 'de'), '12,50');
    expect(inputAmount(123456, 'EUR', lang: 'en'), '1234.56');
    expect(inputAmount(15000, 'KRW', lang: 'ko'), '15000');
    expect(inputAmount(5, 'EUR', lang: 'en'), '0.05');
    expect(inputAmount(-1000, 'EUR', lang: 'de'), '-10,00');
    for (final lang in ['en', 'de', 'fr', 'sv']) {
      expect(parseMoney(inputAmount(123456, 'EUR', lang: lang), 'EUR', lang: lang), 123456, reason: lang);
    }
  });
}
