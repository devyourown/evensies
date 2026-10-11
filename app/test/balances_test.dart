import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/domain/settlement.dart';
import 'package:evensies/features/group_detail/balances.dart';

Expense x(
  String id, {
  required List<Share> payers,
  required List<Share> shares,
  bool refund = false,
  String cur = 'EUR',
}) => Expense(
  id: id,
  description: id,
  amount: payers.fold(0, (a, p) => a + p.amount),
  currency: cur,
  fxRateToDefault: cur == 'EUR' ? null : 2,
  payers: payers,
  date: '2026-10-11',
  refund: refund,
  shares: shares,
);

Share s(String m, int a) => Share(memberId: m, amount: a);

void main() {
  final state = GroupState(
    defaultCurrency: 'EUR',
    members: const [
      Member(id: 'a', name: 'Anna'),
      Member(id: 'b', name: 'Ben'),
    ],
    expenses: [
      x('plain', payers: [s('a', 1000)], shares: [s('a', 500), s('b', 500)]),
      x('two payers', payers: [s('a', 600), s('b', 400)], shares: [s('a', 500), s('b', 500)]),
      x('refund', payers: [s('a', 200)], shares: [s('a', 100), s('b', 100)], refund: true),
      x('usd', payers: [s('b', 100)], shares: [s('a', 100)], cur: 'USD'),
    ],
  );

  test('lines carry payers and refunds, converted like shares', () {
    final seen = <ExpenseLine>[];
    final r = balancesOf(
      state,
      compute: (m, lines, p) {
        seen.addAll(lines);
        return {for (final id in m) id: 0};
      },
    );
    expect(r.unsupported, 0);
    expect(seen.map((l) => [l.payers, l.refund]).toList(), [
      [
        {'a': 1000},
        false,
      ],
      [
        {'a': 600, 'b': 400},
        false,
      ],
      [
        {'a': 200},
        true,
      ],
      [
        {'b': 200},
        false,
      ],
    ]);
  });

  test('while computeBalances cannot count several payers or refunds, they are left out and counted', () {
    Map<String, int> stub(List<String> m, List<ExpenseLine> lines, List<PaymentLine> p) {
      if (lines.any((l) => l.payers.length != 1 || l.refund)) throw UnimplementedError('TODO(효준)');
      return computeBalances(m, lines, p);
    }

    final r = balancesOf(state, compute: stub);
    expect(r.unsupported, 2);
    expect(r.lines.length, 2);
    expect(r.balances, {'a': 300, 'b': -300}); // plain (+500/-500) and usd (-200/+200)
    expect(r.transfers(simplify: true), const [Transfer(from: 'b', to: 'a', amount: 300)]);
    expect(r.transfers(simplify: false), const [Transfer(from: 'b', to: 'a', amount: 300)]);
  });

  test('a stub that throws for everything gives no balances', () {
    final r = balancesOf(state, compute: (_, _, _) => throw UnimplementedError());
    expect(r.balances, isNull);
    expect(r.transfers(simplify: true), isNull);
  });
}
