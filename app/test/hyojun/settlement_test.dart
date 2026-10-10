@Tags(['hyojun'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tally/domain/settlement.dart';

import '../shared_json.dart';

// 실행: flutter test test/hyojun
void main() {
  for (final c in sharedCases('settlement-cases.json')) {
    final members = (c['members'] as List).cast<String>();
    final expenses = [
      for (final e in (c['expenses'] as List).cast<Map>())
        ExpenseLine(
          paidBy: e['paidBy'] as String,
          amount: e['amount'] as int,
          shares: (e['shares'] as Map).cast<String, int>(),
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

    test('balances: ${c['name']}', () {
      final balances = computeBalances(members, expenses, payments);
      // TODO(효준): expect(balances, expectedBalances);
      fail('TODO(효준) $balances');
    });

    test('transfers: ${c['name']}', () {
      final transfers = simplifyDebts(expectedBalances);
      // TODO(효준): expect(transfers, expectedTransfers);
      fail('TODO(효준) $transfers $expectedTransfers');
    });
  }

  group('properties', () {
    // 무작위 멤버 3~8명, 지출 0~20개로 여러 번 돌려 볼 것 (Random(seed) 고정).
    test('balances sum to zero', () {
      // TODO(효준): computeBalances(...).values.sum == 0
      fail('TODO(효준)');
    });
    test('applying all transfers settles every balance to zero', () {
      // TODO(효준): balances 복사 → 각 Transfer에 대해 from += amount, to -= amount → 모두 0
      fail('TODO(효준)');
    });
    test('transfers.length <= members - 1', () {
      fail('TODO(효준)');
    });
    test('deterministic: same balances → same transfers', () {
      fail('TODO(효준)');
    });
    test('no transfer involves a zero-balance member', () {
      fail('TODO(효준)');
    });
  });
}
