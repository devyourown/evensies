import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/domain/settlement.dart';
import 'package:evensies/domain/split.dart';

import 'shared_json.dart';

void main() {
  group('shared/settlement-cases.json expectedPairwise', () {
    for (final c in sharedCases('settlement-cases.json').where((c) => c['expectedPairwise'] != null)) {
      test(c['name'] as String, () {
        final lines = [
          for (final e in (c['expenses'] as List).cast<Map>())
            ExpenseLine(
              paidBy: e['paidBy'] as String?,
              payers: (e['payers'] as Map?)?.cast<String, int>(),
              amount: e['amount'] as int,
              shares: (e['shares'] as Map).cast<String, int>(),
              refund: e['refund'] == true,
            ),
        ];
        final payments = [
          for (final p in (c['payments'] as List).cast<Map>())
            PaymentLine(from: p['from'] as String, to: p['to'] as String, amount: p['amount'] as int),
        ];
        final expected = [
          for (final t in (c['expectedPairwise'] as List).cast<Map>())
            Transfer(from: t['from'] as String, to: t['to'] as String, amount: t['amount'] as int),
        ];
        expect(pairwiseDebts((c['members'] as List).cast<String>(), lines, payments), expected);
      });
    }
  });

  test('properties: settles every balance, one transfer per pair, sorted, deterministic', () {
    final rnd = Random(3);
    for (var k = 0; k < 200; k++) {
      final n = 2 + rnd.nextInt(5);
      final members = List.generate(n, (i) => 'm$i');
      final lines = List.generate(rnd.nextInt(12), (_) {
        final amount = rnd.nextInt(10000);
        final who = (List.of(members)..shuffle(rnd)).take(1 + rnd.nextInt(n)).toList();
        return ExpenseLine(
          paidBy: members[rnd.nextInt(n)],
          amount: amount,
          shares: computeSplit(amount: amount, mode: SplitMode.equal, members: who),
        );
      });
      final payments = List.generate(rnd.nextInt(6), (_) {
        final i = rnd.nextInt(n);
        return PaymentLine(from: members[i], to: members[(i + 1 + rnd.nextInt(n - 1)) % n], amount: rnd.nextInt(3000));
      });
      final balances = computeBalances(members, lines, payments);
      final debts = pairwiseDebts(members, lines, payments);
      final left = Map.of(balances);
      for (final t in debts) {
        expect(t.amount, greaterThan(0));
        left[t.from] = left[t.from]! + t.amount;
        left[t.to] = left[t.to]! - t.amount;
      }
      expect(left.values.every((v) => v == 0), isTrue, reason: '$balances → $left');
      final pairs = debts.map((t) => ([t.from, t.to]..sort()).join('|')).toList();
      expect(pairs.toSet().length, pairs.length);
      expect(debts, [...debts]..sort((a, b) => a.from == b.from ? a.to.compareTo(b.to) : a.from.compareTo(b.from)));
      expect(pairwiseDebts(members, lines.reversed.toList(), payments.reversed.toList()), debts);
    }
  });
}
