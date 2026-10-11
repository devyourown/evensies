import 'dart:io';

import 'package:evensies/core/money.dart';
import 'package:evensies/domain/balances.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/domain/overview.dart';
import 'package:evensies/domain/settlement.dart';
import 'package:flutter_test/flutter_test.dart';

import 'shared_json.dart';

GroupState stateOf(Map<String, dynamic> g) => GroupState.fromJson({
      'group': {'name': g['id'], 'defaultCurrency': g['defaultCurrency'], 'kind': g['kind'], 'simplifyDebts': ?g['simplifyDebts']},
      'members': g['members'],
      'expenses': g['expenses'],
      'payments': g['payments'],
    });

void main() {
  setUpAll(() => Money.loadFromJson(File('../shared/currencies.json').readAsStringSync()));

  group('shared/overview-cases.json', () {
    for (final c in sharedCases('overview-cases.json')) {
      test(c['name'] as String, skip: c['pending'] == null ? null : 'pending: hyojun', () {
        final me = c['me'] as String;
        final groups = (c['groups'] as List).cast<Map<String, dynamic>>();
        final states = {for (final g in groups) g['id'] as String: stateOf(g)};
        final ledgers = [
          for (final MapEntry(key: id, value: s) in states.entries) GroupLedger.of(groupId: id, state: s, myUserId: me)!,
        ];
        final o = computeOverview(ledgers);
        final e = c['expected'] as Map<String, dynamic>;
        expect(o.people, e['people']);
        expect(o.byGroup, e['byGroup']);
        expect(o.owedToMe, e['owedToMe']);
        expect(o.iOwe, e['iOwe']);

        // Invariant: per currency, owedToMe − iOwe = the sum of my members' balances over every group.
        final mine = <String, int>{};
        for (final s in states.values) {
          final res = balancesOf(s)!;
          for (final MapEntry(key: cur, value: b) in res.byCurrency.entries) {
            for (final m in s.members.where((m) => m.userId == me)) {
              mine[cur] = (mine[cur] ?? 0) + (b[m.id] ?? 0);
            }
          }
        }
        for (final cur in {...mine.keys, ...o.owedToMe.keys, ...o.iOwe.keys}) {
          expect((o.owedToMe[cur] ?? 0) - (o.iOwe[cur] ?? 0), mine[cur] ?? 0, reason: cur);
        }
      });
    }
  });

  test('a group without a member of mine has no ledger', () {
    const s = GroupState(defaultCurrency: 'EUR', members: [Member(id: 'm1', name: 'Ben', userId: 'u-ben')]);
    expect(GroupLedger.of(groupId: 'g', state: s, myUserId: 'u-anna'), isNull);
  });

  group('people', () {
    GroupState g(String kind, List<Member> members, {List<Expense> expenses = const []}) =>
        GroupState(defaultCurrency: 'EUR', kind: kind, members: members, expenses: expenses);
    Expense x(String paidBy, String owes, int amount) => Expense(
        id: 'x$paidBy$owes', description: 'x', amount: amount, currency: 'EUR', paidBy: paidBy, date: '2026-10-11',
        shares: [Share(memberId: owes, amount: amount)]);

    final groups = [
      (id: 'g2', name: 'Rome', state: g('group', const [
        Member(id: 'r1', name: 'Anna', userId: 'me'),
        Member(id: 'r2', name: 'Benny', userId: 'u-ben'),
        Member(id: 'r3', name: 'Carlo'), // placeholder, settled: hidden
        Member(id: 'r4', name: 'Dana'), // placeholder with a balance: shown, subtitle Rome
      ], expenses: [x('r1', 'r4', 500)])),
      (id: 'g9', name: 'Anna & Ben', state: g('friend', const [
        Member(id: 'f1', name: 'Anna', userId: 'me'),
        Member(id: 'f2', name: 'Ben', userId: 'u-ben'),
      ])),
      (id: 'g5', name: 'Anna & Ben', state: g('friend', const [
        Member(id: 'h1', name: 'Anna', userId: 'me'),
        Member(id: 'h2', name: 'Ben B.', userId: 'u-ben'), // a second friend group: merged, the smallest id names him
      ])),
      (id: 'g7', name: 'Anna & Eva', state: g('friend', const [
        Member(id: 'e1', name: 'Anna', userId: 'me'),
        Member(id: 'e2', name: 'Eva'), // placeholder friend: shown while settled
      ])),
      (id: 'g8', name: 'Others', state: g('group', const [Member(id: 'o1', name: 'Zed', userId: 'u-zed')])),
    ];
    final o = computeOverview([
      for (final x in groups) ?GroupLedger.of(groupId: x.id, state: x.state, myUserId: 'me'),
    ]);
    final people = peopleOf(groups, o, 'me');

    test('everyone I share a group with, friend groups merged, placeholders by rule', () {
      expect([for (final p in people) p.key], ['u-ben', 'm:r4', 'g:g7']);
      final ben = people.first;
      expect((ben.name, ben.userId, ben.settled), ('Ben B.', 'u-ben', true));
      expect(ben.friendGroups, ['g5', 'g9']);
      final dana = people[1];
      expect((dana.name, dana.groupId), ('Dana', 'g2'));
      expect(dana.net, {'EUR': 500});
      expect((people[2].name, people[2].userId), ('Eva', null));
      expect(people[2].friendGroups, ['g7']);
    });
  });

  group('row text', () {
    test('one currency', () {
      expect(personBalanceText({'EUR': 1200}, null), 'owes you €12.00');
      expect(personBalanceText({'USD': -500}, null), 'you owe \$5.00');
      expect(personBalanceText({}, null), 'settled up');
    });
    test('several currencies: the largest at the latest rates, unknown rates last, ties by code', () {
      const rates = {'EUR': 1.0, 'USD': 1.25, 'JPY': 160.0};
      expect(largestCurrency({'EUR': 1000, 'JPY': -320000}, rates), 'JPY'); // ¥320,000 = €2,000
      expect(largestCurrency({'EUR': 1000, 'USD': 1200}, rates), 'EUR'); // $12 = €9.60
      expect(largestCurrency({'EUR': 1000, 'USD': 1250}, rates), 'EUR'); // equal: by code
      expect(largestCurrency({'KRW': 999999, 'EUR': 1}, rates), 'EUR'); // no KRW rate: last
      expect(largestCurrency({'USD': 1, 'EUR': 1}, null), 'EUR');
      expect(personBalanceText({'EUR': 1000, 'JPY': -320000}, rates), 'you owe ¥320,000*');
    });
  });

  group('settle with a friend', () {
    // Across a friend group (they owe me) and a trip (I owe them), plus a USD bucket.
    const friend = GroupLedger(groupId: 'gf', myMemberId: 'f1', personOf: {'f1': 'me', 'f2': 'u-ben'}, transfers: {
      'EUR': [Transfer(from: 'f2', to: 'f1', amount: 400)],
      'USD': [Transfer(from: 'f1', to: 'f2', amount: 700)],
    });
    const trip = GroupLedger(groupId: 'gt', myMemberId: 't1', personOf: {'t1': 'me', 't2': 'u-ben', 't3': 'u-cara'}, transfers: {
      'EUR': [Transfer(from: 't1', to: 't2', amount: 1000), Transfer(from: 't3', to: 't1', amount: 50)],
    });
    final lines = friendLines([friend, trip], 'u-ben');
    var n = 0;
    String id() => 'p${++n}';

    test('lines are only the transfers between me and that person', () {
      expect(lines.map((l) => (l.groupId, l.currency, l.iPay, l.transfer.amount)),
          [('gf', 'EUR', false, 400), ('gf', 'USD', true, 700), ('gt', 'EUR', true, 1000)]);
      expect(netByCurrency(lines), {'EUR': -600, 'USD': -700});
    });

    test('one payment per line; the offset line where no money moves is confirmed', () {
      final ps = settlePayments(lines, 'u-ben', 'EUR', date: '2026-10-11', newId: id);
      expect(ps.map((p) => (p.groupId, p.payment.fromMember, p.payment.toMember, p.payment.amount, p.payment.status)),
          [('gf', 'f2', 'f1', 400, 'confirmed'), ('gt', 't1', 't2', 1000, 'sent')]);
      expect(ps.every((p) => p.payment.currency == 'EUR' && p.payment.date == '2026-10-11'), isTrue);
    });

    test('a currency only in an unconverted bucket is settled in that currency', () {
      final ps = settlePayments(lines, 'u-ben', 'USD', date: '2026-10-11', newId: id);
      expect(ps.single.payment.currency, 'USD');
      expect(ps.single.payment.status, 'sent');
    });

    test('a placeholder never gets "sent", and what I receive is confirmed', () {
      const pf = GroupLedger(groupId: 'gp', myMemberId: 'a', personOf: {'a': 'me', 'b': 'g:gp'}, transfers: {
        'JPY': [Transfer(from: 'a', to: 'b', amount: 1500)],
      });
      expect(settlePayments(friendLines([pf], 'g:gp'), 'g:gp', 'JPY', date: 'd', newId: id).single.payment.status,
          'confirmed');
      expect(settlePayments(lines, 'u-ben', 'EUR', date: 'd', newId: id).first.payment.status, 'confirmed');
    });
  });
}
