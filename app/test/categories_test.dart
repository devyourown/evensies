import 'dart:io';

import 'package:evensies/domain/categories.dart';
import 'package:evensies/features/categories/category_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shared_json.dart';

void main() {
  setUpAll(() => Categories.loadFromJson(File('../shared/categories.json').readAsStringSync()));
  final cases = loadShared('category-cases.json');

  test('the app asset is a byte-equal copy of shared/categories.json', () {
    expect(File('assets/categories.json').readAsBytesSync(), File('../shared/categories.json').readAsBytesSync());
  });

  test('43 categories under 7 parents; every key has an icon and every icon name exists', () {
    expect((Categories.parents.length, Categories.all.length), (7, 43));
    for (final p in Categories.parents) {
      expect(categoryIcons[p.icon], isNotNull, reason: p.key);
    }
    for (final c in Categories.all) {
      expect(categoryIcons[c.icon], isNotNull, reason: c.key);
      expect(Categories.parent(c.parent), isNotNull, reason: c.key);
    }
  });

  test('labelOf: a parent key or legacy text shows General; the six Other name their parent', () {
    expect(Categories.labelOf('food'), 'General'); // legacy free text that equals a parent key
    expect(Categories.labelOf('home'), 'General');
    expect(Categories.labelOf(null), 'General');
    expect(Categories.labelOf('food.dining_out'), 'Dining out');
    expect(Categories.labelOf('Dining out'), 'Dining out');
    expect(Categories.labelOf('entertainment.other'), 'Entertainment - Other');
    expect(Categories.labelOf('uncategorized.general'), 'General');
    for (final c in Categories.all) {
      expect(resolveCategory(Categories.labelOf(c.key)), c.key, reason: 'every label reads back, like the server CSV');
    }
  });

  test('no folded keyword appears twice', () {
    final seen = <String, String>{};
    for (final c in Categories.all) {
      for (final k in c.keywords) {
        expect(seen[k], isNull, reason: '"$k" in ${c.key} and ${seen[k]}');
        seen[k] = c.key;
      }
    }
  });

  test('fold turns every letter of U+00C0–U+017F into plain a–z', () {
    for (var r = 0xC0; r <= 0x17F; r++) {
      if (r == 0xD7 || r == 0xF7) continue; // × and ÷ are not letters
      final c = String.fromCharCode(r);
      expect(fold(c), matches(RegExp(r'^[a-z]{1,2}$')), reason: 'U+${r.toRadixString(16)} $c');
      expect(fold(c), fold(c.toUpperCase().length == 1 ? c.toUpperCase() : c), reason: 'U+${r.toRadixString(16)} case');
    }
  });

  for (final c in (cases['fold'] as List).cast<Map>()) {
    test('fold ${c['in']}', () => expect(fold(c['in'] as String), c['out']));
  }
  for (final c in (cases['resolve'] as List).cast<Map>()) {
    test('resolve ${c['raw']}', () => expect(resolveCategory(c['raw'] as String?), c['expected']));
  }
  for (final c in (cases['guess'] as List).cast<Map>()) {
    test('guess: ${c['name']}', () {
      final history = [
        for (final h in (c['history'] as List).cast<Map>())
          (description: h['description'] as String, category: h['category'] as String?),
      ];
      expect(guessCategory(c['description'] as String, history: history), c['expected']);
    });
  }
}
