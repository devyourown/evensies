import 'dart:convert';
import 'dart:io';

import 'package:evensies/domain/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

OcrLine line(String text, double top) => OcrLine(text: text, left: 20, top: top, right: 300, bottom: top + 30);

void main() {
  group('test/fixtures/receipts', () {
    for (final f in Directory('test/fixtures/receipts').listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path))) {
      final c = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      test(c['name'] as String, () {
        final lines = (c['lines'] as List).cast<Map<String, dynamic>>().map(OcrLine.fromJson).toList();
        expect(parseReceipt(lines, decimals: c['decimals'] as int).toJson(), c['expected']);
      });
    }
  });

  test('no lines, or nothing priced: an empty draft', () {
    expect(parseReceipt(const [], decimals: 2).toJson()['lines'], isEmpty);
    final d = parseReceipt([line('Hello', 0), line('World', 40)], decimals: 2);
    expect(d.lines, isEmpty);
    expect((d.total, d.merchant), (null, 'Hello'));
  });

  test('without a total word the largest price is the total; prices need the currency\'s decimals', () {
    final d = parseReceipt([line('Pizza 9.50', 0), line('Beer 4.50', 40), line('14.00', 80), line('Table 12', 120)],
        decimals: 2);
    expect(d.lines.map((l) => (l.name, l.amount)), [('Pizza', 950), ('Beer', 450)]);
    expect(d.total, 1400);
  });

  test('a long first row is no merchant', () {
    final d = parseReceipt([line('A' * 41, 0), line('Coffee 3.00', 40)], decimals: 2);
    expect(d.merchant, isNull);
  });

  test('receiptCurrency: the sign or code (next to a number) named most; \$ and unknown codes name none', () {
    const known = {'EUR', 'JPY', 'GBP', 'USD'};
    expect(receiptCurrency([line('Ramen ¥1,200', 0), line('Total 1,200円', 40)], known: known), 'JPY');
    expect(receiptCurrency([line('Pie 4.50 GBP', 0), line('TOTAL USD 9.00', 40), line('USD 1.00', 80)], known: known), 'USD');
    expect(receiptCurrency([line('Pie \$4.50', 0), line('TAX 1.00', 40), line('ALL 3', 80)], known: known), isNull);
  });
}
