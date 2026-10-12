import 'dart:convert';
import 'dart:io';

import 'package:evensies/domain/itemized.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/domain/split.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fixture = jsonDecode(File('test/fixtures/itemized-cases.json').readAsStringSync()) as Map<String, dynamic>;

  group('test/fixtures/itemized-cases.json', () {
    for (final c in (fixture['cases'] as List).cast<Map<String, dynamic>>()) {
      test(c['name'] as String, () {
        final bill = ItemizedBill.fromJson(c['bill'])!;
        if (c['error'] case final String code) {
          expect(() => computeItemizedSplit(bill), throwsA(isA<SplitException>().having((e) => e.code, 'code', code)));
          return;
        }
        final shares = computeItemizedSplit(bill);
        expect(shares, (c['expected'] as Map).cast<String, int>());
        expect(itemizedTotal(bill), c['expectedTotal']);
        expect(shares.values.fold(0, (a, b) => a + b), c['expectedTotal']);
      });
    }
  });

  test('percentOf rounds halves up', () {
    for (final c in (fixture['percentOf'] as List).cast<Map<String, dynamic>>()) {
      expect(percentOf(c['subtotal'] as int, c['pct'] as num), c['expected'], reason: '$c');
    }
  });

  test('a bill round-trips with tax, tip and discount always written', () {
    final spec = SplitSpec.fromJson({
      'mode': 'itemized',
      'bill': {
        'lines': [
          {'name': 'Fries', 'amount': 700, 'memberIds': ['m2', 'm1']},
        ],
      },
    })!;
    expect(spec.itemized, isTrue);
    expect(spec.toJson(), {
      'mode': 'itemized',
      'bill': {
        'lines': [
          {'name': 'Fries', 'amount': 700, 'memberIds': ['m2', 'm1']},
        ],
        'tax': 0,
        'tip': 0,
        'discount': 0,
      },
    });
    expect(SplitSpec.fromJson(spec.toJson()), spec);
    // A bad shape, or input next to the bill, reads as no split.
    expect(SplitSpec.fromJson({'mode': 'itemized'}), isNull);
    expect(SplitSpec.fromJson({'mode': 'itemized', 'bill': {'lines': [{'name': 'x', 'amount': 1}]}}), isNull);
    expect(SplitSpec.fromJson({'mode': 'itemized', 'input': {'m1': 1}, 'bill': {'lines': []}}), isNull);
  });

  test('remapForMove maps the line people like shares, and drops the split when one has no member there', () {
    const source = [
      Member(id: 'a1', name: 'Anna', userId: 'u1'),
      Member(id: 'a2', name: 'Ben', userId: 'u2'),
      Member(id: 'a3', name: 'Kid'),
    ];
    const target = [Member(id: 'b1', name: 'Anna', userId: 'u1'), Member(id: 'b2', name: 'Ben', userId: 'u2')];
    Expense dinner(List<String> waterPeople) => Expense(
          id: 'x1',
          description: 'Dinner',
          amount: 1000,
          currency: 'EUR',
          paidBy: 'a1',
          date: '2026-10-11',
          split: SplitSpec.itemized(ItemizedBill(lines: [
            const ItemLine(name: 'Pizza', amount: 1000, memberIds: ['a1', 'a2']),
            ItemLine(name: 'Water', amount: 0, memberIds: waterPeople),
          ], tip: 0)),
          shares: const [Share(memberId: 'a1', amount: 500), Share(memberId: 'a2', amount: 500)],
        );
    final moved = remapForMove(dinner(['a2']), source, target, id: 'y1', sameCurrency: true)!;
    expect(moved.split!.bill!.lines.map((l) => l.memberIds).toList(), [
      ['b1', 'b2'],
      ['b2'],
    ]);
    // The kid only drank water (a zero share, dropped), but sits on a line: no bill there.
    final kid = remapForMove(dinner(['a3']), source, target, id: 'y2', sameCurrency: true)!;
    expect(kid.split, isNull);
    expect(kid.shares.map((s) => s.memberId), ['b1', 'b2']);
  });
}
