import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

import 'strings.dart';

/// Currency → decimal digits and display symbol, from shared/currencies.json (copied to assets/).
abstract final class Money {
  static Map<String, int> decimals = const {};

  /// Codes with their own symbol (docs/API.md, Money notation); a code without one shows the ISO code.
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

  /// The language amounts are written in (the UI language; docs/API.md, Money notation).
  static String lang = 'en';

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

/// M(x) (docs/API.md, Money notation): |minor| split at the currency's decimals and grouped by 3, with the language's group
/// and decimal characters, placed in its pattern with the symbol (language's, else the shared table's, else the ISO
/// code): `€1,234.56` (en), `1.234,56 €` (de), `CHF 12.50` (U+00A0 after a symbol ending in a Latin letter). A
/// negative amount (a refund in Insights) starts with a minus sign `−€48.00`, as the rest of the app writes one.
/// [lang] defaults to [Money.lang]; built-in `en` defaults cover a table that was never loaded.
String formatMoney(int minor, String currency, {String? lang}) {
  final l = lang ?? Money.lang;
  final d = Money.digits(currency);
  final whole = (minor.abs() ~/ _pow10(d)).toString();
  final group = Strings.lookup(l, const ['money', 'group']) as String? ?? ',';
  final b = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) b.write(group);
    b.write(whole[i]);
  }
  if (d > 0) {
    b.write(Strings.lookup(l, const ['money', 'decimal']) as String? ?? '.');
    b.write((minor.abs() % _pow10(d)).toString().padLeft(d, '0'));
  }
  final s = Strings.lookup(l, ['money', 'symbols', currency]) as String? ?? Money.symbols?[currency] ?? currency;
  final pattern = Strings.lookup(l, const ['money', 'pattern']) as String? ?? '{s}{n}';
  final text = pattern == '{s}{n}' && _endsLatin(s)
      ? '$s $b'
      : Strings.fill(pattern, {'s': s, 'n': b.toString()});
  return minor < 0 ? '−$text' : text;
}

/// A–Z, a–z or U+00C0–U+024F without × and ÷.
bool _endsLatin(String s) {
  if (s.isEmpty) return false;
  final c = s.codeUnitAt(s.length - 1);
  return (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A) || (c >= 0xC0 && c <= 0x24F && c != 0xD7 && c != 0xF7);
}

/// The language's decimal character (`.` in en, `,` in de).
String decimalMark([String? lang]) => Strings.lookup(lang ?? Money.lang, const ['money', 'decimal']) as String? ?? '.';

/// What a person typed → minor units, or null (docs/API.md, Amount input): `12,50` is €12.50 in de, `1,234` is ₩1,234,
/// `12.345` is €12,345.00 in de but null in en. The last separator is the decimal mark when it is the language's or
/// isn't followed by exactly 3 digits; otherwise it groups.
int? parseMoney(String text, String currency, {String? lang}) {
  final d = Money.digits(currency);
  final cleaned = text.replaceAll(RegExp('[\\s  \'’]'), '');
  final neg = cleaned.startsWith('-');
  final t = cleaned.replaceAll(RegExp(r'[^\d.,]'), '');
  if (t.isEmpty) return null;
  final last = t.lastIndexOf(RegExp(r'[.,]'));
  String whole, frac = '';
  if (last < 0) {
    whole = t;
  } else {
    final c = t[last], k = t.length - last - 1, dec = decimalMark(lang);
    if (c != dec && k == 3) {
      if (t.contains(dec)) return null;
      whole = t.replaceAll(c, '');
    } else {
      if (k > d) return null;
      final before = t.substring(0, last);
      if (before.contains(c)) return null;
      whole = before.replaceAll(RegExp(r'[.,]'), '');
      frac = t.substring(last + 1);
    }
  }
  final v = int.tryParse('${whole.isEmpty ? '0' : whole}${frac.padRight(d, '0')}');
  if (v == null) return null;
  return neg ? -v : v;
}

/// A percent, rate or share count in either notation: the last separator is the decimal mark, the other kind groups,
/// and a second decimal mark is null (`1,0842` → 1.0842, `1.234,5` → 1234.5, `1.2.3` → null).
double? parseDecimal(String text) {
  final cleaned = text.replaceAll(RegExp('[\\s  \'’]'), '');
  final neg = cleaned.startsWith('-');
  final t = cleaned.replaceAll(RegExp(r'[^\d.,]'), '');
  if (t.isEmpty) return null;
  final last = t.lastIndexOf(RegExp(r'[.,]'));
  if (last >= 0 && t.substring(0, last).contains(t[last])) return null;
  final n = last < 0 ? t : '${t.substring(0, last).replaceAll(RegExp(r'[.,]'), '')}.${t.substring(last + 1)}';
  final v = double.tryParse(n == '.' ? '' : n);
  return v == null ? null : (neg ? -v : v);
}

/// [minor] as an input field shows it: the language's decimal mark, no grouping (`12,50` in de, `15000` for KRW).
String inputAmount(int minor, String currency, {String? lang}) {
  final d = Money.digits(currency);
  final sign = minor < 0 ? '-' : '';
  if (d == 0) return '$sign${minor.abs()}';
  final s = minor.abs().toString().padLeft(d + 1, '0');
  return '$sign${s.substring(0, s.length - d)}${decimalMark(lang)}${s.substring(s.length - d)}';
}

/// [v] as a field or a line shows a typed number: at most [decimals] decimals, no trailing zeros, the language's
/// decimal mark (`33,3` in de, `2`, `1.0842`). Percentages, shares and rates; money uses [inputAmount].
String numberText(num v, {int decimals = 2, String? lang}) {
  final p = _pow10(decimals);
  final scaled = (v * p).round();
  final frac = (scaled.abs() % p).toString().padLeft(decimals, '0').replaceFirst(RegExp(r'0+$'), '');
  return '${scaled < 0 ? '-' : ''}${scaled.abs() ~/ p}${frac.isEmpty ? '' : '${decimalMark(lang)}$frac'}';
}

int _pow10(int d) {
  var r = 1;
  for (var i = 0; i < d; i++) {
    r *= 10;
  }
  return r;
}
