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

  test('Korean: words spaced out ("합 계", "부 가 세"), 원 and ￦ around prices, name / unit price / qty / amount columns',
      () {
    final d = parseReceipt([
      line('카페 온새미로', 0),
      line('아메리카노 4,500 2 9,000원', 40),
      line('카페라떼 5,000 1 5,000원', 80),
      line('케이크 6,800 2 6,800원', 120), // 6,800 × 2 is not 6,800: the numbers stay
      line('김밥 ￦3,000', 160),
      line('부 가 세 2,164원', 200),
      line('합   계 23,800원', 240),
      line('현금합계 50,000원', 280), // a total word, but cash handed over
    ], decimals: 0);
    expect(d.lines.map((l) => (l.name, l.amount)),
        [('2x 아메리카노', 9000), ('카페라떼', 5000), ('케이크 6,800 2', 6800), ('김밥', 3000)]);
    expect((d.tax, d.total, d.merchant), (0, 23800, '카페 온새미로')); // VAT included
  });

  test('Japanese: ￥ and 円, ※ 軽 外 after the price, ▲ minus, fullwidth digits, quantity lines, 外税, お預り合計', () {
    final d = parseReceipt([
      line('まいにちマート', 0),
      line('おにぎり ￥160※', 40),
      line('緑茶 １４０円軽', 80),
      line('プリン 300円 ※軽', 120),
      line('ヨーグルト ￥２５６', 160),
      line('2個 × @128', 200),
      line('パン ¥150外', 240),
      line('@75 x 2', 280),
      line('半額 ▲75', 320),
      line('外税 8% ￥68', 360),
      line('合 計 ￥９９９', 400),
      line('お預り合計 ￥1,000', 440), // a total word, but cash handed over
      line('お釣り ￥1', 480),
    ], decimals: 0);
    expect(d.lines.map((l) => (l.name, l.amount)),
        [('おにぎり', 160), ('緑茶', 140), ('プリン', 300), ('ヨーグルト', 256), ('パン', 150)]);
    expect((d.tax, d.discount, d.total), (68, 75, 999));
  });

  test('Thai keywords; Latin keywords still match whole words only; Latin columns lose unit price and qty too', () {
    final th = parseReceipt([
      line('ข้าวผัด 120.00', 0),
      line('ค่าบริการ 12.00', 40),
      line('ภาษี 9.24', 80),
      line('รวมทั้งสิ้น 141.24', 120),
    ], decimals: 2);
    expect(th.lines.map((l) => (l.name, l.amount)), [('ข้าวผัด', 12000)]);
    expect((th.tip, th.tax, th.total), (1200, 924, 14124));
    final mixed = parseReceipt([line('ข้าวผัดรวมมิตร 150.00', 0), line('ชาเย็น 40.00', 40), line('ยอดสุทธิ 190.00', 80)],
        decimals: 2); // a dish named with รวม drops out, but is not the total
    expect(mixed.lines.map((l) => (l.name, l.amount)), [('ชาเย็น', 4000)]);
    expect(mixed.total, 19000);
    final en = parseReceipt([
      line('Servicemen Special 9.50', 0),
      line('Totally Tea 4.50', 40),
      line('Beer 4.50 2 9.00', 80),
      line('Total 23.00', 120),
    ], decimals: 2);
    expect(en.lines.map((l) => (l.name, l.amount)),
        [('Servicemen Special', 950), ('Totally Tea', 450), ('2x Beer', 900)]);
    expect((en.tip, en.total), (0, 2300));
  });

  test('receiptCurrency: the sign or code (next to a number) named most; \$ and unknown codes name none', () {
    const known = {'EUR', 'JPY', 'GBP', 'USD'};
    expect(receiptCurrency([line('Ramen ¥1,200', 0), line('Total 1,200円', 40)], known: known), 'JPY');
    expect(receiptCurrency([line('Pie 4.50 GBP', 0), line('TOTAL USD 9.00', 40), line('USD 1.00', 80)], known: known), 'USD');
    expect(receiptCurrency([line('Pie \$4.50', 0), line('TAX 1.00', 40), line('ALL 3', 80)], known: known), isNull);
    expect(receiptCurrency([line('おにぎり ￥160', 0), line('合計 ￥160', 40)], known: known), 'JPY');
    expect(receiptCurrency([line('김밥 3,500원', 0)], known: known), 'KRW');
    expect(receiptCurrency([line('김밥 ￦3,500', 0)], known: known), 'KRW');
  });
}
