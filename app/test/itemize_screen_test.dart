import 'package:evensies/core/money.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/domain/itemized.dart';
import 'package:evensies/features/itemize/itemize_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Itemize screen (docs/API.md, Itemized split): lines and people, "All", Done only once every line has a person,
/// tax/tip/discount as an amount or a %, live totals and the printed-total warning.
void main() {
  setUpAll(() => Money.loadFromJson('{"decimals":{"EUR":2},"symbols":{"EUR":"€"}}'));

  const members = [
    MemberRow(id: 'm1', groupId: 'g1', name: 'Anna', removed: false),
    MemberRow(id: 'm2', groupId: 'g1', name: 'Ben', removed: false),
    MemberRow(id: 'm3', groupId: 'g1', name: 'Cara', removed: true),
  ];

  /// Opens the screen; the returned function gives what it popped.
  Future<ItemizedBill? Function()> open(WidgetTester t,
      {ItemizedBill? bill, int? printed, bool printedTip = true, String? me}) async {
    t.view.physicalSize = const Size(800, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    ItemizedBill? result;
    var done = false;
    await t.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result = await showItemize(context,
                  members: members, currency: 'EUR', bill: bill, printedTotal: printed, printedTip: printedTip, me: me);
              done = true;
            },
            child: const Text('go'),
          ),
        ),
      ),
    ));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    return () => done ? result : throw StateError('still open');
  }

  Finder inLine(int i, Finder f) => find.descendant(of: find.byKey(const Key('item-line')).at(i), matching: f);
  bool doneEnabled(WidgetTester t) => t.widget<FilledButton>(find.byKey(const Key('itemize-done'))).enabled;
  String text(WidgetTester t, String key) => t.widget<Text>(find.byKey(Key(key))).data!;

  testWidgets('Each person: me first as You, then the others in the group order', (t) async {
    await open(t,
        me: 'm2',
        bill: const ItemizedBill(lines: [
          ItemLine(name: 'Pizza', amount: 1000, memberIds: ['m1', 'm2'])
        ]));
    double y(Finder f) => t.getCenter(f).dy;
    expect(y(find.text('You')), y(find.byKey(const Key('itemize-person-m2'))));
    expect(y(find.text('You')), lessThan(y(find.byKey(const Key('itemize-person-m1')))));
  });

  testWidgets('a scanned draft: give people, All, the rest to everyone; Done once every line has someone', (t) async {
    final result = await open(t,
        bill: const ItemizedBill(lines: [
          ItemLine(name: 'Burger', amount: 1450, memberIds: []),
          ItemLine(name: 'Salad', amount: 1100, memberIds: []),
          ItemLine(name: 'Fries', amount: 700, memberIds: []),
        ], tax: 284),
        printed: 3600);
    expect(find.byKey(const Key('item-line')), findsNWidgets(3));
    expect(doneEnabled(t), isFalse);
    expect(text(t, 'itemize-problem'), '3 items without a person');
    expect(find.text('Cara'), findsNothing); // removed: not offered for new lines

    await t.tap(inLine(0, find.byKey(const Key('item-person-m1'))));
    await t.tap(inLine(1, find.byKey(const Key('item-person-m2'))));
    await t.pump();
    expect(text(t, 'itemize-problem'), '1 item without a person');
    await t.tap(inLine(2, find.byKey(const Key('item-all'))));
    await t.pump();
    expect(doneEnabled(t), isTrue);
    expect(text(t, 'itemize-subtotal'), '€32.50');
    expect(text(t, 'itemize-total'), '€35.34');
    expect(text(t, 'itemize-mismatch'), 'Receipt says €36.00 · items differ by €0.66');
    // Tax spread by subtotal: Anna 18.00 (+1.57), Ben 14.50 (+1.27).
    expect(text(t, 'itemize-person-m1'), '€19.58');
    expect(text(t, 'itemize-person-m2'), '€15.76');

    await t.tap(find.byKey(const Key('itemize-done')));
    await t.pumpAndSettle();
    final bill = result()!;
    expect(bill.lines.map((l) => '${l.name} ${l.amount} ${([...l.memberIds]..sort()).join(',')}'), [
      'Burger 1450 m1',
      'Salad 1100 m2',
      'Fries 700 m1,m2',
    ]);
    expect((bill.tax, bill.tip, bill.discount), (284, 0, 0));
  });

  testWidgets('a tip the receipt did not print is no mismatch; one it printed still is', (t) async {
    const bill = ItemizedBill(lines: [
      ItemLine(name: 'Pizza', amount: 1000, memberIds: ['m1'])
    ]);
    Future<void> tip(String v) async {
      await t.enterText(
          find.descendant(of: find.byKey(const Key('itemize-tip')), matching: find.byKey(const Key('extra-field'))), v);
      await t.pump();
    }

    await open(t, bill: bill, printed: 1000, printedTip: false);
    await tip('2');
    expect(text(t, 'itemize-total'), '€12.00');
    expect(find.byKey(const Key('itemize-mismatch')), findsNothing);

    await t.pumpWidget(const SizedBox());
    await open(t, bill: bill, printed: 1100);
    await tip('2');
    expect(text(t, 'itemize-mismatch'), 'Receipt says €11.00 · items differ by €1.00');
  });

  testWidgets('"Give the rest to everyone", a tip in % follows the subtotal, swiping removes a line', (t) async {
    final result = await open(t);
    await t.enterText(inLine(0, find.byKey(const Key('item-name'))), 'Pizza');
    await t.enterText(inLine(0, find.byKey(const Key('item-amount'))), '20');
    await t.tap(find.byKey(const Key('itemize-add')));
    await t.pump();
    await t.enterText(inLine(1, find.byKey(const Key('item-name'))), 'Wine');
    await t.enterText(inLine(1, find.byKey(const Key('item-amount'))), '10');
    await t.pump();
    await t.tap(find.byKey(const Key('itemize-everyone')));
    await t.pump();
    expect(find.byKey(const Key('itemize-everyone')), findsNothing);

    final tip = find.byKey(const Key('itemize-tip'));
    await t.tap(find.descendant(of: tip, matching: find.text('%')));
    await t.pump();
    await t.enterText(find.descendant(of: tip, matching: find.byKey(const Key('extra-field'))), '10');
    await t.pump();
    expect(t.widget<Text>(find.descendant(of: tip, matching: find.byKey(const Key('extra-amount')))).data, '€3.00');
    expect(text(t, 'itemize-total'), '€33.00');
    await t.enterText(inLine(1, find.byKey(const Key('item-amount'))), '15');
    await t.pump();
    expect(t.widget<Text>(find.descendant(of: tip, matching: find.byKey(const Key('extra-amount')))).data, '€3.50');
    expect(text(t, 'itemize-total'), '€38.50');

    FocusManager.instance.primaryFocus?.unfocus();
    await t.pumpAndSettle();
    await t.drag(find.byKey(const Key('item-line')).at(1), const Offset(-600, 0));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('item-line')), findsOneWidget);
    expect(text(t, 'itemize-total'), '€22.00'); // 10 % of €20.00
    await t.tap(find.byKey(const Key('itemize-done')));
    await t.pumpAndSettle();
    final bill = result()!;
    expect((bill.lines.single.name, bill.tip), ('Pizza', 200)); // stored as the amount
  });

  testWidgets('a removed member already on a line stays, by name; a discount too big is no bill', (t) async {
    await open(t,
        bill: const ItemizedBill(lines: [
          ItemLine(name: 'Beer', amount: 500, memberIds: ['m3']),
        ]));
    expect(find.text('Cara (left)'), findsOneWidget);
    expect(doneEnabled(t), isTrue);
    await t.enterText(find.descendant(of: find.byKey(const Key('itemize-discount')), matching: find.byKey(const Key('extra-field'))), '6');
    await t.pump();
    expect(text(t, 'itemize-problem'), 'The discount is more than the bill');
    expect(doneEnabled(t), isFalse);
  });
}
