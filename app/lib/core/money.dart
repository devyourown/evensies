import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

/// Currency → decimal digits, from shared/currencies.json (copied to assets/).
abstract final class Money {
  static Map<String, int> decimals = const {};

  static Future<void> loadFromAssets() async =>
      loadFromJson(await rootBundle.loadString('assets/currencies.json'));

  static void loadFromJson(String json) {
    decimals = ((jsonDecode(json) as Map)['decimals'] as Map).cast<String, int>();
  }

  static int digits(String currency) => decimals[currency] ?? 2;
  static List<String> get currencies => decimals.keys.toList()..sort();
}

String formatMoney(int minor, String currency) {
  final d = Money.digits(currency);
  final f = NumberFormat.simpleCurrency(name: currency, decimalDigits: d);
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
