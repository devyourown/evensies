import 'package:evensies/core/text_limits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// docs/API.md, Event types and payloads: names are at most 100 UTF-16 units, counted after trimming.
void main() {
  test('fitsLimit: exactly max fits, max + 1 does not', () {
    expect(fitsLimit('a' * 100, 100), isTrue);
    expect(fitsLimit('a' * 101, 100), isFalse);
  });

  test('fitsLimit: leading and trailing spaces are not counted', () {
    expect(fitsLimit('  ${'a' * 100}  ', 100), isTrue);
    expect(fitsLimit(' \n${'a' * 101}\t ', 100), isFalse);
  });

  test('fitsLimit: an emoji counts as 2 UTF-16 units', () {
    expect(fitsLimit('😀' * 50, 100), isTrue);
    expect(fitsLimit('${'😀' * 50}a', 100), isFalse);
  });

  /// The decoration [limitedDecoration] gives for [text] with max 100, built in a bare `MaterialApp` (English).
  Future<InputDecoration> decoration(WidgetTester t, String text) async {
    late InputDecoration d;
    await t.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      d = limitedDecoration(context, const InputDecoration(labelText: 'Name'), text, 100);
      return const SizedBox();
    })));
    return d;
  }

  testWidgets('limitedDecoration: no counter at max - 20, a counter from max - 19', (t) async {
    expect((await decoration(t, 'a' * 80)).counterText, isNull);
    expect((await decoration(t, 'a' * 81)).counterText, '81/100');
  });

  testWidgets('limitedDecoration: no error at max, "Too long" at max + 1', (t) async {
    final atMax = await decoration(t, 'a' * 100);
    expect(atMax.counterText, '100/100');
    expect(atMax.errorText, isNull);
    final over = await decoration(t, 'a' * 101);
    expect(over.counterText, '101/100');
    expect(over.errorText, 'Too long');
  });

  testWidgets('limitedDecoration: counts the trimmed text and keeps the rest of the decoration', (t) async {
    final d = await decoration(t, '   ${'a' * 81}   ');
    expect(d.counterText, '81/100');
    expect(d.labelText, 'Name');
  });
}
