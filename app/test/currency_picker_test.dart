import 'dart:io';

import 'package:evensies/core/currency_picker.dart';
import 'package:evensies/core/money.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    Money.loadFromJson(File('../shared/currencies.json').readAsStringSync());
    Money.names = {'JPY': 'Japanese yen'};
  });

  /// A picker under another text field; returns what onChanged got.
  Future<List<String>> pump(WidgetTester t, {String value = 'EUR', List<String> pinned = const []}) async {
    final picked = <String>[];
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (c, set) => Column(children: [
            const TextField(key: Key('other')),
            CurrencyPicker(value: value, pinned: pinned, onChanged: (v) => set(() => picked.add(value = v))),
          ]),
        ),
      ),
    ));
    return picked;
  }

  final field = find.descendant(of: find.byType(CurrencyPicker), matching: find.byType(TextField));
  String shown(WidgetTester t) => t.widget<TextField>(field).controller!.text;

  testWidgets('a code typed and left by tapping elsewhere is picked, so the field shows what is saved', (t) async {
    final picked = await pump(t);
    await t.tap(field);
    await t.pumpAndSettle();
    expect(shown(t), ''); // typing searches instead of appending to "EUR"
    await t.enterText(field, 'jpy');
    await t.tap(find.byKey(const Key('other')));
    await t.pumpAndSettle();
    expect(picked, ['JPY']);
    expect(shown(t), 'JPY');
  });

  testWidgets('text that is not a code goes back to the saved currency', (t) async {
    final picked = await pump(t);
    await t.tap(field);
    await t.enterText(field, 'ye');
    await t.tap(find.byKey(const Key('other')));
    await t.pumpAndSettle();
    expect(picked, isEmpty);
    expect(shown(t), 'EUR');
  });

  testWidgets('opens at the top with the pinned codes; search by name, Done takes the first match', (t) async {
    final picked = await pump(t, value: 'ZAR', pinned: ['EUR', 'USD']);
    await t.tap(field);
    await t.pumpAndSettle();
    // Not scrolled to ZAR: the pinned codes and the end-of-pinned line stay in view.
    expect(find.text('EUR').hitTestable(), findsOneWidget);
    expect(find.text('All currencies').hitTestable(), findsOneWidget);
    await t.enterText(field, 'yen');
    await t.pumpAndSettle();
    expect(find.text('Japanese yen').hitTestable(), findsOneWidget);
    expect(find.text('All currencies').hitTestable(), findsNothing);
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect(picked, ['JPY']);
    expect(shown(t), 'JPY');
  });
}
