import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// The text both sides render from one table (shared/strings.json, copied to assets/; docs/API.md 언어·웹): activity
/// sentences, category labels, frequency words and the money notation. `en` is the source and the fallback, leaf by
/// leaf: a missing language or key renders the `en` one.
abstract final class Strings {
  static Map<String, dynamic> _table = const {};

  static Future<void> loadFromAssets() async => loadFromJson(await rootBundle.loadString('assets/strings.json'));

  static void loadFromJson(String json) => _table = jsonDecode(json) as Map<String, dynamic>;

  /// The languages the table has (`en ko nl …`).
  static List<String> get languages => [for (final k in _table.keys) if (!k.startsWith('_')) k];

  /// The leaf at [path] in [lang], else in `en`, else null. A path, not a dotted key: category keys hold dots.
  static Object? lookup(String lang, List<String> path) {
    Object? walk(String l) {
      Object? n = _table[l];
      for (final p in path) {
        if (n is! Map) return null;
        n = n[p];
      }
      return n is Map ? null : n;
    }

    return walk(lang) ?? walk('en');
  }

  static String text(String lang, List<String> path) => lookup(lang, path) as String? ?? '';

  /// [template] with each `{name}` replaced in one left-to-right pass (a value's own `{A}` stays as typed); an unknown
  /// placeholder stays. A template that starts with a placeholder in [capitalize] gets that value's first letter
  /// upper-cased (`words.you` / `words.someone` at the start of a sentence; names never change).
  static String fill(String template, Map<String, String> values, {Set<String> capitalize = const {}}) {
    var first = true;
    return template.replaceAllMapped(_placeholder, (m) {
      final v = values[m[1]];
      final atStart = first && m.start == 0;
      first = false;
      if (v == null) return m[0]!;
      return atStart && capitalize.contains(m[1]) && v.isNotEmpty ? v[0].toUpperCase() + v.substring(1) : v;
    });
  }

  static final _placeholder = RegExp(r'\{([A-Za-z]+)\}');
}
