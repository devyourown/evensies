/// Expense categories (docs/API.md, Categories): the taxonomy from shared/categories.json (copied to assets/),
/// folding, resolving a stored value to a key, and guessing a key from a description. Names per language come from
/// shared/strings.json; matching stays on the English labels.
library;

import 'dart:convert';

import '../core/money.dart';
import '../core/strings.dart';

/// What a null, a blank, a parent key and any legacy free text resolve to.
const generalCategory = 'uncategorized.general';

class Category {
  final String key;
  final String label;

  /// A Material icon name; the parent's when the category has none (`*.other`, General).
  final String icon;

  /// Folded, in file order.
  final List<String> keywords;
  const Category({required this.key, required this.label, required this.icon, this.keywords = const []});

  String get parent => key.substring(0, key.indexOf('.'));
}

class CategoryParent {
  final String key;
  final String label;
  final String icon;
  const CategoryParent({required this.key, required this.label, required this.icon});
}

/// Loaded once at startup (like Money); empty until then, so everything resolves to General.
abstract final class Categories {
  static List<CategoryParent> parents = const [];

  /// Every category in file order (= picker order = guess tie-break order).
  static List<Category> all = const [];
  static Map<String, Category> _byKey = const {};
  static Map<String, CategoryParent> _parents = const {};

  /// Lowercased [labelOf] → key, for labels that appear once: the six "Other" only as "Entertainment - Other" (the
  /// server's CSV label), so a bare "Other" is none of them.
  static Map<String, String> _byLabel = const {};

  static void loadFromJson(String json) {
    final j = jsonDecode(json) as Map;
    parents = [
      for (final p in (j['parents'] as List).cast<Map>())
        CategoryParent(key: p['key'] as String, label: p['label'] as String, icon: p['icon'] as String),
    ];
    _parents = {for (final p in parents) p.key: p};
    all = [
      for (final c in (j['categories'] as List).cast<Map>())
        Category(
          key: c['key'] as String,
          label: c['label'] as String,
          icon: c['icon'] as String? ?? _parents[(c['key'] as String).split('.').first]!.icon,
          keywords: [for (final k in ((c['keywords'] as List?) ?? const []).cast<String>()) fold(k)],
        ),
    ];
    _byKey = {for (final c in all) c.key: c};
    final labels = {for (final c in all) c.key: englishLabelOf(c.key).toLowerCase()};
    final counts = <String, int>{};
    for (final l in labels.values) {
      counts.update(l, (n) => n + 1, ifAbsent: () => 1);
    }
    _byLabel = {
      for (final MapEntry(:key, value: l) in labels.entries)
        if (counts[l] == 1) l: key,
    };
  }

  static Category? byKey(String? key) => _byKey[key];
  static CategoryParent? parent(String key) => _parents[key];
  static List<Category> under(String parentKey) => [for (final c in all) if (c.parent == parentKey) c];

  /// The category [raw] shows as (General for null and legacy values). Null only before loading.
  static Category? of(String? raw) => _byKey[resolveCategory(raw)];

  /// What a stored value shows as in [lang] (default [Money.lang]): "Dining out"; the six "Other" as
  /// `words.categoryOther` ("Entertainment - Other"); General for null and legacy text, a parent key included. A
  /// parent key's own name is [nameOf].
  static String labelOf(String? raw, {String? lang}) {
    final l = lang ?? Money.lang;
    final c = of(raw);
    if (c == null) return nameOf(generalCategory, l);
    return c.key.endsWith('.other')
        ? Strings.fill(Strings.text(l, const ['words', 'categoryOther']), {'parent': nameOf(c.parent, l)})
        : nameOf(c.key, l);
  }

  /// A category or parent key's name in [lang] (shared/strings.json `categories`), else its English label.
  static String nameOf(String key, [String? lang]) =>
      Strings.lookup(lang ?? Money.lang, ['categories', key]) as String? ??
      _byKey[key]?.label ??
      _parents[key]?.label ??
      (key == generalCategory ? 'General' : key);

  /// The English label (CSV export, Splitwise import, legacy values): "Entertainment - Other" for the six "Other".
  static String englishLabelOf(String? raw) {
    final c = of(raw);
    if (c == null) return 'General';
    return c.key.endsWith('.other') ? '${_parents[c.parent]?.label} - ${c.label}' : c.label;
  }
}

/// A stored value → a key of `categories[]` (docs/API.md, Category rules): the key itself, a label that appears once
/// (case-insensitive, "Entertainment - Other" for the six "Other"), anything else General.
String resolveCategory(String? raw) {
  final t = raw?.trim() ?? '';
  if (Categories._byKey.containsKey(t)) return t;
  return Categories._byLabel[t.toLowerCase()] ?? generalCategory;
}

// U+00C0–U+017F after lowercasing → base letter (the canonical decomposition's first letter, or the contract's list:
// ø→o, ł→l, đ/ð→d, ı→i, ħ→h, ŧ→t, ĸ→k, ŀ→l, ŉ/ŋ→n, ſ→s); '?' entries are in [_multi] or uppercase (never looked up).
const _base = 'aaaaaa?ceeeeiiiidnooooo×ouuuuy??aaaaaa?ceeeeiiiidnooooo÷ouuuuy?yaaaaaaccccccccddddeeeeeeeeeegggggggghhhh'
    'iiiiiiiiii??jjkkkllllllllllnnnnnnnnnoooooo??rrrrrrssssssssttttttuuuuuuuuuuuuwwyyyzzzzzzs';
const _multi = {'ß': 'ss', 'æ': 'ae', 'œ': 'oe', 'þ': 'th', 'ĳ': 'ij'};

/// Lowercase, combining marks U+0300–U+036F removed, Latin-1 Supplement and Latin Extended-A letters to their base
/// letter (`é→e`, `ß→ss`, `ø→o`); everything else (spaces, `×`, Han, Hangul) unchanged.
String fold(String s) {
  final b = StringBuffer();
  for (final r in s.toLowerCase().runes) {
    if (r >= 0x300 && r <= 0x36F) continue;
    if (r >= 0xC0 && r <= 0x17F) {
      final c = String.fromCharCode(r);
      b.write(_multi[c] ?? _base[r - 0xC0]);
    } else {
      b.writeCharCode(r);
    }
  }
  return b.toString();
}

final _split = RegExp(r'[^\p{L}\p{N}]+', unicode: true);
/// Scripts written without spaces between words: their keywords match anywhere in the text.
final noSpaceScript = RegExp(r'[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}\p{Script=Hangul}\p{Script=Thai}]',
    unicode: true);
final _spaces = RegExp(r'\s+');

List<String> _tokens(String folded) => folded.split(_split).where((t) => t.isNotEmpty).toList();
int _len(String s) => s.runes.length;

/// A key for [description], or null (docs/API.md, Category rules, `guessCategory`): the last [history] entry (oldest
/// first) with the same normalized description and a known key; otherwise the best keyword match.
/// ponytail: scans every keyword per call (~400); fine behind the form's 300 ms debounce.
String? guessCategory(String description, {List<({String description, String? category})> history = const []}) {
  String n(String s) => fold(s).trim().replaceAll(_spaces, ' ');
  final d = n(description);
  if (d.isEmpty) return null;
  String? fromHistory;
  for (final h in history) {
    if (Categories._byKey.containsKey(h.category) && n(h.description) == d) fromHistory = h.category;
  }
  if (fromHistory != null) return fromHistory;

  final folded = fold(description);
  final tokens = _tokens(folded);
  String? best;
  var bestScore = 0;
  var bestExact = false;
  for (final c in Categories.all) {
    for (final k in c.keywords) {
      int score;
      bool exact;
      if (noSpaceScript.hasMatch(k)) {
        if (!folded.contains(k)) continue;
        score = _len(k);
        exact = true;
      } else {
        final kt = _tokens(k);
        final m = _match(tokens, kt);
        if (m == null) continue;
        score = kt.fold(0, (a, t) => a + _len(t));
        exact = m;
      }
      // File order, then keyword order, break ties: only a strictly better match replaces the best so far.
      if (score > bestScore || (score == bestScore && exact && !bestExact)) {
        best = c.key;
        bestScore = score;
        bestExact = exact;
      }
    }
  }
  return best;
}

/// True for an exact match of [kt] in [tokens], false for a prefix match on its last token, null for none.
bool? _match(List<String> tokens, List<String> kt) {
  if (kt.isEmpty) return null;
  final last = kt.length - 1;
  bool? found;
  for (var i = 0; i + last < tokens.length; i++) {
    var ok = true;
    for (var j = 0; j < last && ok; j++) {
      ok = tokens[i + j] == kt[j];
    }
    if (!ok) continue;
    final t = tokens[i + last], k = kt[last];
    if (t == k) return true;
    if (_len(k) >= 4 && t.startsWith(k) && _len(t) - _len(k) <= 2) found = false;
  }
  return found;
}
