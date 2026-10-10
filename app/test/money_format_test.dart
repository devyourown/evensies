import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/core/money.dart';

void main() {
  setUpAll(() => Money.loadFromJson(File('../shared/currencies.json').readAsStringSync()));

  String digitsOf(String s) => s.replaceAll(RegExp(r'[^\d.]'), '');

  test('EUR 1234 formats with two decimals', () => expect(digitsOf(formatMoney(1234, 'EUR')), '12.34'));
  test('KRW 1234 formats with no decimals', () => expect(digitsOf(formatMoney(1234, 'KRW')), '1234'));
  test('USD 5 formats as 0.05', () => expect(digitsOf(formatMoney(5, 'USD')), '0.05'));
  test('parse "12.34" EUR → 1234', () => expect(parseMoney('12.34', 'EUR'), 1234));
  test('parse "12" EUR → 1200', () => expect(parseMoney('12', 'EUR'), 1200));
  test('parse "12.5" EUR → 1250', () => expect(parseMoney('12.5', 'EUR'), 1250));
  test('parse "1,234" KRW → 1234', () => expect(parseMoney('1,234', 'KRW'), 1234));
  test('parse too many decimals → null', () => expect(parseMoney('12.345', 'EUR'), isNull));
  test('parse decimals for KRW → null', () => expect(parseMoney('12.3', 'KRW'), isNull));
  test('parse invalid → null', () {
    expect(parseMoney('abc', 'EUR'), isNull);
    expect(parseMoney('', 'EUR'), isNull);
    expect(parseMoney('1.2.3', 'EUR'), isNull);
  });
}
