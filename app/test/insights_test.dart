import 'dart:io';

import 'package:evensies/core/core_guard.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/domain/balances.dart';
import 'package:evensies/domain/categories.dart';
import 'package:evensies/domain/insights.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/domain/settlement.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shared_json.dart';

Map<String, Object> _json(PeriodTotals t) => {
      'spent': t.spent,
      'youPaid': t.youPaid,
      'yourShare': t.yourShare,
      'paymentsMade': t.paymentsMade,
      'paymentsReceived': t.paymentsReceived,
      'netChange': t.netChange,
      'byCategory': t.byCategory,
      'byMember': {for (final e in t.byMember.entries) e.key: {'paid': e.value.paid, 'share': e.value.share}},
    };

void main() {
  setUpAll(() {
    Categories.loadFromJson(File('../shared/categories.json').readAsStringSync());
    Money.loadFromJson(File('../shared/currencies.json').readAsStringSync());
  });

  group('search (shared/search-cases.json)', () {
    final f = loadShared('search-cases.json');
    final docs = [for (final j in (f['items'] as List).cast<Map<String, dynamic>>()) SearchDoc.fromJson(j)];
    for (final c in sharedCases('search-cases.json')) {
      test(c['name'] as String, () {
        expect(searchDocs(docs, c['query'] as String, category: c['category'] as String?, month: c['month'] as String?),
            c['expected']);
      });
    }
    test('the excerpt is the note or comment holding a term', () {
      final taxi = docs.firstWhere((d) => d.id == 'x2');
      expect(searchExcerpt(taxi, 'airport'), 'to the airport, 4 bags');
      expect(searchExcerpt(taxi, 'ANNA'), 'Anna paid the tip');
      expect(searchExcerpt(taxi, 'taxi'), isNull);
    });
  });

  group('totals (shared/totals-cases.json)', () {
    for (final c in sharedCases('totals-cases.json')) {
      final expenses = [for (final j in (c['expenses'] as List).cast<Map<String, dynamic>>()) Expense.fromJson(j)];
      final payments = [for (final j in (c['payments'] as List).cast<Map<String, dynamic>>()) Payment.fromJson(j)];
      final me = c['me'] as String;
      // Inside the tests: setUpAll loads the taxonomy that byCategory resolves with.
      ({Map<String, PeriodTotals> months, PeriodTotals allTime}) totals() => computeTotals(expenses, payments, me: me);
      final expected = c['expected'] as Map<String, dynamic>;

      test(c['name'] as String, () {
        final r = totals();
        expect({for (final e in r.months.entries) e.key: _json(e.value)}, expected['months']);
        expect(_json(r.allTime), expected['allTime']);
      });

      test('all-time change in my balance equals my balance: ${c['name']}', () {
        final live = expenses.where((e) => !e.deleted);
        final ids = {
          for (final e in live) ...[...e.payers.map((p) => p.memberId), ...e.shares.map((s) => s.memberId)],
          for (final p in payments) ...[p.fromMember, p.toMember],
        }.toList();
        final b = tryCore(() => computeBalances(
              ids,
              [
                for (final e in live)
                  ExpenseLine(
                    payers: paidAmounts(e),
                    amount: e.amount,
                    shares: {for (final s in e.shares) s.memberId: s.amount},
                    refund: e.refund,
                  ),
              ],
              [
                for (final p in payments.where((p) => !p.deleted))
                  PaymentLine(from: p.fromMember, to: p.toMember, amount: p.amount),
              ],
            ));
        expect(b?[me], totals().allTime.netChange);
      }, skip: c['pending'] == null ? null : 'pending: hyojun');
    }
  });

  group('buckets', () {
    test('foreign expenses stay in their own bucket while they cannot be converted; payments by currency', () {
      Share s(String m, int a) => Share(memberId: m, amount: a);
      final state = GroupState(
        defaultCurrency: 'EUR',
        members: const [Member(id: 'a', name: 'Anna'), Member(id: 'b', name: 'Ben')],
        expenses: [
          Expense(id: 'x1', description: 'Dinner', amount: 3000, currency: 'EUR', paidBy: 'a', date: '2026-10-01',
              shares: [s('a', 1500), s('b', 1500)]),
          Expense(id: 'x2', description: 'Ramen', amount: 2000, currency: 'JPY', paidBy: 'b', date: '2026-10-02',
              shares: [s('a', 1000), s('b', 1000)]),
          Expense(id: 'x3', description: 'Gone', amount: 1, currency: 'JPY', paidBy: 'b', date: '2026-10-02',
              deleted: true, shares: [s('a', 1)]),
        ],
        payments: const [
          Payment(id: 'p1', fromMember: 'b', toMember: 'a', amount: 500, currency: 'USD', date: '2026-10-03'),
        ],
      );
      final b = insightBuckets(state);
      expect(b.keys.toList(), ['EUR', 'JPY', 'USD']);
      expect(b['EUR']!.expenses.map((e) => e.id), ['x1']);
      expect(b['JPY']!.expenses.map((e) => e.id), ['x2']);
      expect(b['USD']!.payments.map((p) => p.id), ['p1']);
    });
  });

  group('whoPaysNext', () {
    test('the most negative active balance; a tie goes to the lowest memberId', () {
      expect(whoPaysNext({'a': 500, 'b': -300, 'c': -200}, {'a', 'b', 'c'}), 'b');
      expect(whoPaysNext({'a': 600, 'c': -300, 'b': -300}, {'a', 'b', 'c'}), 'b');
    });
    test('removed members are skipped; nobody owing is null', () {
      expect(whoPaysNext({'a': 500, 'b': -400, 'c': -100}, {'a', 'c'}), 'c');
      expect(whoPaysNext({'a': 0, 'b': 0}, {'a', 'b'}), isNull);
      expect(whoPaysNext(const {}, const {}), isNull);
    });
  });

  test('a date the server let through without a month (+10000-01-01) counts in all time only', () {
    final t = computeTotals([
      Expense(id: 'x1', description: 'Far', amount: 500, currency: 'EUR', paidBy: 'a', date: '+10000-01-01',
          shares: const [Share(memberId: 'a', amount: 500)]),
      Expense(id: 'x2', description: 'Now', amount: 300, currency: 'EUR', paidBy: 'a', date: '2026-10-01',
          shares: const [Share(memberId: 'a', amount: 300)]),
    ], const [], me: 'a');
    expect(t.months.keys, ['2026-10']);
    expect(t.allTime.spent, 800);
    expect(monthOf('+10000-01-01'), isNull);
    expect(monthOf('2026-10-01'), '2026-10');
  });

  test('the share summary lists totals, top categories, other currencies and balances', () {
    final t = computeTotals([
      Expense(id: 'x1', description: 'Dinner', amount: 3000, currency: 'EUR', paidBy: 'a', date: '2026-10-01',
          category: 'food.dining_out', shares: const [Share(memberId: 'a', amount: 1500), Share(memberId: 'b', amount: 1500)]),
      Expense(id: 'x2', description: 'Lidl', amount: 1200, currency: 'EUR', paidBy: 'b', date: '2026-10-02',
          category: 'food.groceries', shares: const [Share(memberId: 'a', amount: 600), Share(memberId: 'b', amount: 600)]),
    ], const [], me: 'a').allTime;
    final jpy = computeTotals([
      Expense(id: 'x3', description: 'Ramen', amount: 2000, currency: 'JPY', paidBy: 'b', date: '2026-10-02',
          shares: const [Share(memberId: 'a', amount: 1000), Share(memberId: 'b', amount: 1000)]),
    ], const [], me: 'a').allTime;
    expect(
      insightsSummary(
        group: 'Rome',
        period: 'All time',
        currency: 'EUR',
        totals: {'EUR': t, 'JPY': jpy},
        names: const {'a': 'Anna', 'b': 'Ben'},
        balances: const {'a': 900, 'b': -900},
      ),
      'Rome · All time\n'
      '\n'
      'Total spent: €42.00\n'
      'You paid: €30.00 · Your share: €21.00\n'
      'Top categories: Dining out €30.00, Groceries €12.00\n'
      '\n'
      'Not converted · JPY\n'
      'Total spent: ¥2,000\n'
      'You paid: ¥0 · Your share: ¥1,000\n'
      '\n'
      'Balances today\n'
      'Anna gets back €9.00\n'
      'Ben owes €9.00\n'
      '\n'
      'Shared from Evensies',
    );
  });
}
