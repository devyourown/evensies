import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/domain/fx.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/domain/settlement.dart';
import 'package:evensies/features/group_detail/balances.dart';

Expense x(
  String id, {
  required List<Share> payers,
  required List<Share> shares,
  bool refund = false,
  String cur = 'EUR',
  double? rate,
  bool deleted = false,
}) => Expense(
  id: id,
  description: id,
  amount: payers.fold(0, (a, p) => a + p.amount),
  currency: cur,
  fxRateToDefault: rate,
  payers: payers,
  date: '2026-10-11',
  refund: refund,
  deleted: deleted,
  shares: shares,
);

Share s(String m, int a) => Share(memberId: m, amount: a);

Payment pay(String id, String from, String to, int amount, {String cur = 'EUR'}) =>
    Payment(id: id, fromMember: from, toMember: to, amount: amount, currency: cur, date: '2026-10-11');

/// Not Hyojun's rounding: whole-number rates only, so the composition can be tested before his convertExpense lands.
ConvertedExpense times({
  required int amount,
  required Map<String, int> parts,
  required int fromDecimals,
  required int toDecimals,
  required double rate,
}) {
  if (rate != rate.roundToDouble() || fromDecimals != toDecimals) throw FxException('BAD_RATE');
  final k = rate.toInt();
  return ConvertedExpense(amount: amount * k, parts: {for (final e in parts.entries) e.key: e.value * k});
}

GroupState trip({List<Expense> expenses = const [], List<Payment> payments = const [], bool simplify = true}) =>
    GroupState(
      defaultCurrency: 'EUR',
      simplifyDebts: simplify,
      members: const [Member(id: 'a', name: 'Anna'), Member(id: 'b', name: 'Ben'), Member(id: 'c', name: 'Cara')],
      expenses: expenses,
      payments: payments,
    );

void main() {
  setUpAll(() => Money.loadFromJson('{"decimals":{"EUR":2,"USD":2,"JPY":0}}'));

  test('default currency only: one bucket, a stray rate on a EUR expense is ignored', () {
    final r = balancesOf(trip(expenses: [
      x('dinner', payers: [s('a', 3000)], shares: [s('a', 1000), s('b', 1000), s('c', 1000)], rate: 0.5),
    ]))!;
    expect(r.byCurrency, {
      'EUR': {'a': 2000, 'b': -1000, 'c': -1000},
    });
    expect(r.unconverted, isEmpty);
    expect(r.others, isEmpty);
  });

  test('a rated USD expense is converted into EUR (shares and payers), and the bucket sums to 0', () {
    final r = balancesOf(
      trip(expenses: [
        x('taxi', payers: [s('b', 1000)], shares: [s('a', 500), s('b', 500)], cur: 'USD', rate: 2),
        x('lunch', payers: [s('a', 600)], shares: [s('b', 600)]),
      ]),
      convert: times,
    )!;
    expect(r.byCurrency, {
      'EUR': {'a': -400, 'b': 400, 'c': 0},
    });
    expect(r.lines['EUR']!.map((l) => [l.amount, l.payers, l.shares]).toList(), [
      [2000, {'b': 2000}, {'a': 1000, 'b': 1000}],
      [600, {'a': 600}, {'b': 600}],
    ]);
    expect(r.unconverted, isEmpty);
  });

  test('with Hyojun\'s convertExpense, a rated JPY expense lands in EUR and the bucket sums to 0', () {
    final r = balancesOf(trip(expenses: [
      x('ramen', payers: [s('a', 12345)], shares: [s('a', 4115), s('b', 4115), s('c', 4115)], cur: 'JPY', rate: 0.00563349),
    ]))!;
    expect(r.byCurrency.keys, ['EUR']);
    expect(r.balances.values.fold(0, (a, v) => a + v), 0);
  }, skip: fxReady ? null : 'pending: hyojun (convertExpense)');

  test('no rate or rate 0 → its own bucket, counted as unconverted', () {
    final r = balancesOf(
      trip(expenses: [
        x('sushi', payers: [s('a', 3000)], shares: [s('a', 1500), s('b', 1500)], cur: 'JPY'),
        x('tea', payers: [s('b', 600)], shares: [s('a', 600)], cur: 'JPY', rate: 0),
      ]),
      convert: times,
    )!;
    expect(r.byCurrency, {
      'EUR': {'a': 0, 'b': 0, 'c': 0},
      'JPY': {'a': 900, 'b': -900, 'c': 0},
    });
    expect(r.unconverted, {'JPY': 2});
    expect(r.unrated, {'JPY': 2});
    expect(r.others, ['JPY']);
    expect(r.mine('a'), {'JPY': 900});
  });

  test('a legacy USD payment goes to the USD bucket', () {
    final r = balancesOf(trip(
      expenses: [x('hotel', payers: [s('a', 1000)], shares: [s('b', 1000)])],
      payments: [pay('p1', 'b', 'a', 500, cur: 'USD')],
    ))!;
    expect(r.byCurrency['EUR'], {'a': 1000, 'b': -1000, 'c': 0});
    expect(r.byCurrency['USD'], {'a': -500, 'b': 500, 'c': 0});
    expect(r.unconverted, isEmpty);
  });

  test('while convertExpense is a stub, rated expenses stay in their own buckets', () {
    final r = balancesOf(trip(expenses: [
      x('taxi', payers: [s('b', 1000)], shares: [s('a', 1000)], cur: 'USD', rate: 2),
    ]))!;
    expect(r.byCurrency['USD'], {'a': -1000, 'b': 1000, 'c': 0});
    expect(r.unconverted, {'USD': 1});
    expect(r.unrated, isEmpty); // it has a rate: not "without a rate", and Convert has nothing to fill in
  }, skip: fxReady ? 'convertExpense is implemented' : null);

  test('an FxException (e.g. a bad rate) keeps the expense in its own bucket', () {
    final r = balancesOf(
      trip(expenses: [x('odd', payers: [s('b', 1000)], shares: [s('a', 1000)], cur: 'USD', rate: 1.5)]),
      convert: times,
    )!;
    expect(r.unconverted, {'USD': 1});
    expect(r.unrated, isEmpty);
  });

  test('a foreign bucket that nets to zero is dropped; the default one never is; deleted expenses don\'t count', () {
    final r = balancesOf(trip(
      expenses: [
        x('self', payers: [s('a', 3000)], shares: [s('a', 3000)], cur: 'JPY'),
        x('gone', payers: [s('a', 3000)], shares: [s('b', 3000)], cur: 'USD', deleted: true),
      ],
    ))!;
    expect(r.byCurrency.keys, ['EUR']);
    expect(r.unconverted, {'JPY': 1});
    expect(r.others, ['JPY']); // still listed: it can be converted
  });

  test('groupTransfers: per bucket, simplified or pairwise when simplify debts is off', () {
    final expenses = [
      x('e1', payers: [s('a', 1000)], shares: [s('b', 1000)]), // Ben owes Anna 10
      x('e2', payers: [s('b', 1000)], shares: [s('c', 1000)]), // Cara owes Ben 10
      x('y1', payers: [s('c', 500)], shares: [s('a', 500)], cur: 'JPY'),
    ];
    expect(groupTransfers(trip(expenses: expenses)), {
      'EUR': const [Transfer(from: 'c', to: 'a', amount: 1000)],
      'JPY': const [Transfer(from: 'a', to: 'c', amount: 500)],
    });
    expect(groupTransfers(trip(expenses: expenses, simplify: false)), {
      'EUR': const [Transfer(from: 'b', to: 'a', amount: 1000), Transfer(from: 'c', to: 'b', amount: 1000)],
      'JPY': const [Transfer(from: 'a', to: 'c', amount: 500)],
    });
  });

  test('leaving needs zero in every bucket; unconverted expenses alone don\'t block it', () {
    final even = balancesOf(trip(expenses: [x('self', payers: [s('a', 3000)], shares: [s('a', 3000)], cur: 'JPY')]));
    expect(leaveBlocker(even, 'a'), isNull);
    final owed = balancesOf(trip(expenses: [x('sushi', payers: [s('a', 3000)], shares: [s('b', 3000)], cur: 'JPY')]));
    // Phase 6: the JPY bucket settles in JPY, no conversion needed.
    const tail = 'settle up in JPY first';
    expect(leaveBlocker(owed, 'a'), 'You are owed ¥3,000 · $tail');
    expect(leaveBlocker(owed, 'b'), 'You owe ¥3,000 · $tail');
    expect(leaveBlocker(owed, 'c'), isNull);
    final eur = balancesOf(trip(expenses: [x('e1', payers: [s('a', 500)], shares: [s('b', 500)])]));
    expect(leaveBlocker(eur, 'a'), 'You are owed €5.00 · settle up first');
    expect(leaveBlocker(null, 'a'), "Balances can't be computed yet");
  });

  group('Phase 3 lines', () {
    final state = trip(expenses: [
      x('plain', payers: [s('a', 1000)], shares: [s('a', 500), s('b', 500)]),
      x('two payers', payers: [s('a', 600), s('b', 400)], shares: [s('a', 500), s('b', 500)]),
      x('refund', payers: [s('a', 200)], shares: [s('a', 100), s('b', 100)], refund: true),
      x('usd', payers: [s('b', 100)], shares: [s('a', 100)], cur: 'USD', rate: 2),
    ]);

    test('lines carry payers and refunds; payers are converted like shares', () {
      final seen = <ExpenseLine>[];
      final r = balancesOf(state, convert: times, compute: (m, lines, p) {
        seen.addAll(lines);
        return {for (final id in m) id: 0};
      })!;
      expect(r.unsupported, 0);
      expect(seen.map((l) => [l.payers, l.refund]).toList(), [
        [{'a': 1000}, false],
        [{'a': 600, 'b': 400}, false],
        [{'a': 200}, true],
        [{'b': 200}, false],
      ]);
    });

    test('while computeBalances cannot count several payers or refunds, they are left out and counted', () {
      Map<String, int> stub(List<String> m, List<ExpenseLine> lines, List<PaymentLine> p) {
        if (lines.any((l) => l.payers.length != 1 || l.refund)) throw UnimplementedError('stub');
        return computeBalances(m, lines, p);
      }

      final r = balancesOf(state, compute: stub, convert: times)!;
      expect(r.unsupported, 2);
      expect(r.lines['EUR']!.length, 2);
      expect(r.balances, {'a': 300, 'b': -300, 'c': 0}); // plain (+500/-500) and usd (-200/+200)
      expect(r.transfers(simplify: true), {'EUR': const [Transfer(from: 'b', to: 'a', amount: 300)]});
      expect(r.transfers(simplify: false), {'EUR': const [Transfer(from: 'b', to: 'a', amount: 300)]});
      expect(leaveBlocker(r, 'c'), "Some expenses aren't counted in balances yet");
    });

    test('a stub that throws for everything gives no balances', () {
      expect(balancesOf(state, compute: (_, _, _) => throw UnimplementedError()), isNull);
    });
  });
}
