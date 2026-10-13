import 'dart:io';

import 'package:evensies/core/money.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/features/auth/name_screen.dart';
import 'package:flutter_test/flutter_test.dart';

SessionRow _session(String name) =>
    SessionRow(id: 1, accessToken: 'a', refreshToken: 'r', userId: 'u', displayName: name);

void main() {
  setUpAll(() => Money.loadFromJson(File('assets/currencies.json').readAsStringSync()));

  test('a name is needed when empty or when it is still an email', () {
    expect(needsDisplayName(_session('')), isTrue);
    expect(needsDisplayName(_session('   ')), isTrue);
    expect(needsDisplayName(_session('abc@privaterelay.appleid.com')), isTrue);
    expect(needsDisplayName(_session('Anna')), isFalse);
  });

  test('default currency follows the device locale', () {
    expect(Money.currencyForLocale('ko_KR'), 'KRW');
    expect(Money.currencyForLocale('it_IT'), 'EUR');
    expect(Money.currencyForLocale('ja_JP'), 'JPY');
    expect(Money.currencyForLocale('en_US'), 'USD');
    expect(Money.currencyForLocale('xx'), 'EUR');
  });
}
