library;

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/domain/settlement.dart';
import 'package:evensies/domain/split.dart';

import '../shared_json.dart';

// 실행: flutter test test/hyojun
void main() {
  for (final c in sharedCases('settlement-cases.json')) {
    final members = (c['members'] as List).cast<String>();
    final expenses = [
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
    final expectedBalances = (c['expectedBalances'] as Map).cast<String, int>();
    final expectedTransfers = [
      for (final t in (c['expectedTransfers'] as List).cast<Map>())
        Transfer(from: t['from'] as String, to: t['to'] as String, amount: t['amount'] as int),
    ];

    // "pending": "hyojun" = needs the TODO(효준) part of computeBalances; reported as skipped until it lands.
    test('balances: ${c['name']}', skip: c['pending'] == null ? null : 'pending: hyojun', () {
      final balances = computeBalances(members, expenses, payments);
      expect(balances, expectedBalances);
    });

    test('transfers: ${c['name']}', () {
      final transfers = simplifyDebts(expectedBalances);
      expect(transfers, expectedTransfers);
    });
  }

  group('properties', () {
    // 무작위 멤버 3~8명, 지출 0~20개, 송금 0~20개. Random(seed) 고정이라 실패가 재현된다.
    final rnd = Random(42);
    (List<String>, List<ExpenseLine>, List<PaymentLine>) randomCase() {
      final n = 3 + rnd.nextInt(6);
      final members = List.generate(n, (i) => 'm$i');
      final expenses = List.generate(rnd.nextInt(21), (_) {
        final amount = rnd.nextInt(10000);
        return ExpenseLine(
          paidBy: members[rnd.nextInt(n)],
          amount: amount,
          shares: computeSplit(amount: amount, mode: SplitMode.equal, members: members),
        );
      });
      final payments = List.generate(rnd.nextInt(21), (_) {
        final i = rnd.nextInt(n);
        final j = (i + 1 + rnd.nextInt(n - 1)) % n; // never equal to i
        return PaymentLine(from: members[i], to: members[j], amount: rnd.nextInt(5000));
      });
      return (members, expenses, payments);
    }

    void forEachCase(void Function(List<String> members, Map<String, int> balances) body) {
      for (var k = 0; k < 200; k++) {
        final (members, expenses, payments) = randomCase();
        body(members, computeBalances(members, expenses, payments));
      }
    }

    test('balances sum to zero', () {
      forEachCase((_, balances) => expect(balances.values.fold(0, (a, b) => a + b), 0));
    });
    test('applying all transfers settles every balance to zero', () {
      forEachCase((_, balances) {
        final left = Map.of(balances);
        for (final t in simplifyDebts(balances)) {
          left[t.from] = left[t.from]! + t.amount;
          left[t.to] = left[t.to]! - t.amount;
        }
        expect(left.values.every((v) => v == 0), isTrue, reason: '$balances → $left');
      });
    });
    test('transfers.length <= members - 1', () {
      forEachCase((members, balances) => expect(simplifyDebts(balances).length, lessThanOrEqualTo(members.length - 1)));
    });
    test('deterministic: same balances → same transfers', () {
      forEachCase((_, balances) {
        final reversed = Map.fromEntries(balances.entries.toList().reversed);
        expect(simplifyDebts(balances), simplifyDebts(reversed));
      });
    });
    // Several payers (from computeSplit(exact)) and refunds. Remove the skip with the TODO(효준) in computeBalances.
    test('balances sum to zero with several payers and refunds', () {
      for (var k = 0; k < 200; k++) {
        final (members, _, payments) = randomCase();
        final lines = List.generate(rnd.nextInt(21), (_) {
          final amount = rnd.nextInt(10000);
          final who = (List.of(members)..shuffle(rnd)).take(1 + rnd.nextInt(members.length)).toList();
          final cut = rnd.nextInt(amount + 1);
          final input = {for (final m in who) m: 0.0}..[who.first] = (amount - cut).toDouble();
          input[who.last] = input[who.last]! + cut;
          return ExpenseLine(
            payers: computeSplit(amount: amount, mode: SplitMode.exact, members: who, input: input),
            amount: amount,
            shares: computeSplit(amount: amount, mode: SplitMode.equal, members: members),
            refund: rnd.nextBool(),
          );
        });
        final balances = computeBalances(members, lines, payments);
        expect(balances.values.fold(0, (a, b) => a + b), 0, reason: '$balances');
      }
    });
    test('no transfer involves a zero-balance member', () {
      forEachCase((_, balances) {
        for (final t in simplifyDebts(balances)) {
          expect(balances[t.from], isNot(0));
          expect(balances[t.to], isNot(0));
          expect(t.amount, greaterThan(0));
        }
      });
    });
  });
}
