import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

/// Currency → decimal digits and display symbol, from shared/currencies.json (copied to assets/).
abstract final class Money {
  static Map<String, int> decimals = const {};

  /// Codes with a shared symbol (docs/API.md 문장 금액 표기); null when the JSON has no `symbols` (tests that load
  /// only decimals keep intl's symbol for every code).
  static Map<String, String>? symbols;

  /// English names (`names` in the JSON, e.g. JPY → Japanese yen) for the picker's search; null when it has none.
  static Map<String, String>? names;

  static Future<void> loadFromAssets() async =>
      loadFromJson(await rootBundle.loadString('assets/currencies.json'));

  static void loadFromJson(String json) {
    final j = jsonDecode(json) as Map;
    decimals = (j['decimals'] as Map).cast<String, int>();
    symbols = (j['symbols'] as Map?)?.cast<String, String>();
    names = (j['names'] as Map?)?.cast<String, String>();
  }

  static int digits(String currency) => decimals[currency] ?? 2;
  static List<String> get currencies => decimals.keys.toList()..sort();

  /// Currency of a locale like `ko_KR` (→ KRW), if we support it; otherwise EUR.
  static String currencyForLocale(String locale) {
    try {
      final c = NumberFormat.simpleCurrency(locale: locale).currencyName;
      if (c != null && decimals.containsKey(c)) return c;
    } catch (_) {}
    return 'EUR';
  }
}

/// `€30.00`, `₩15,000`; a code without a shared symbol (Phase 4's new codes) shows the code: `ZAR1,234.56`.
String formatMoney(int minor, String currency) {
  final d = Money.digits(currency);
  final noSymbol = Money.symbols != null && !Money.symbols!.containsKey(currency);
  final f = noSymbol
      ? NumberFormat.currency(name: currency, symbol: currency, decimalDigits: d)
      : NumberFormat.simpleCurrency(name: currency, decimalDigits: d);
  return f.format(minor / _pow10(d));
}

/// "12.34" EUR → 1234, "1,234" KRW → 1234. Comma is a grouping separator. Null if invalid.
int? parseMoney(String text, String currency) {
  final d = Money.digits(currency);
  final t = text.trim().replaceAll(',', '').replaceAll(RegExp(r'[^\d.\-]'), '');
  if (t.isEmpty || !RegExp(r'^-?\d*(\.\d*)?$').hasMatch(t) || t == '.' || t == '-') return null;
  final neg = t.startsWith('-');
  final parts = t.replaceFirst('-', '').split('.');
  final whole = parts[0].isEmpty ? '0' : parts[0];
  var frac = parts.length > 1 ? parts[1] : '';
  if (frac.length > d) return null;
  frac = frac.padRight(d, '0');
  final v = int.tryParse('$whole$frac');
  if (v == null) return null;
  return neg ? -v : v;
}

int _pow10(int d) {
  var r = 1;
  for (var i = 0; i < d; i++) {
    r *= 10;
  }
  return r;
}
