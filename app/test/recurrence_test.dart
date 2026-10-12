import 'package:evensies/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/core/ids.dart';
import 'package:evensies/data/fx_rates.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/domain/recurrence.dart';

import 'shared_json.dart';

Expense x(String id, {String? series, int? n, bool deleted = false, String date = '2026-10-01'}) => Expense(
      id: id,
      description: id,
      amount: 100,
      currency: 'EUR',
      paidBy: 'm1',
      date: date,
      deleted: deleted,
      shares: const [Share(memberId: 'm1', amount: 100)],
      recurrenceId: series,
      occurrence: n,
    );

void main() {
  group('shared/recurrence-cases.json', () {
    for (final c in sharedCases('recurrence-cases.json')) {
      final name = c['name'] as String;
      switch (c['kind']) {
        case 'dates':
          test(name, () {
            final dates = (c['dates'] as List).cast<String>();
            expect([for (var n = 0; n < dates.length; n++) occurrenceDate(c['frequency'], c['startDate'], n)], dates);
          });
        case 'next':
          test(name, () {
            final r = firstOccurrenceOnOrAfter(c['frequency'], c['startDate'], c['onOrAfter'],
                minN: (c['minN'] as int?) ?? 1);
            expect((r.n, r.date), (c['n'], c['date']));
          });
        case 'crossRate':
          test(name, () {
            final perEur = {for (final e in (c['perEur'] as Map).entries) e.key as String: (e.value as num).toDouble()};
            expect(crossRate(perEur, c['from'], c['to']), (c['rate'] as num?)?.toDouble());
          });
        case 'dueAt':
          break; // server only: 09:00 in a named zone needs a tz database
        default:
          test(name, () => fail('unknown kind ${c['kind']}'));
      }
    }
  });

  test('deviceTimeZone is ±HH:MM, UTC as +00:00', () {
    expect(deviceTimeZone(Duration.zero), '+00:00');
    expect(deviceTimeZone(const Duration(hours: 5, minutes: 45)), '+05:45');
    expect(deviceTimeZone(const Duration(hours: -10)), '-10:00');
    expect(deviceTimeZone(const Duration(hours: -3, minutes: -30)), '-03:30');
    expect(deviceTimeZone(), matches(RegExp(r'^[+-]\d\d:\d\d$')));
  });

  test('labels and frequency words', () {
    expect([for (final f in [null, ...frequencies]) repeatLabel(AppLocalizationsEn(), f)],
        ['Never', 'Every week', 'Every 2 weeks', 'Every month', 'Every year']);
    expect([for (final f in frequencies) frequencyWord(f)], ['weekly', 'every 2 weeks', 'monthly', 'yearly']);
  });

  group('series helpers', () {
    final s = GroupState(
      expenses: [
        x('x0', series: 'r1', n: 0),
        x('x1', series: 'r1', n: 1),
        x('x2', series: 'r1', n: 2, deleted: true),
        x('y0', series: 'r2', n: 0),
        x('plain'),
      ],
      recurrences: const [
        Recurrence(id: 'r1', frequency: 'monthly', startDate: '2026-09-01', timeZone: '+02:00', template: {
          'description': 'Rent',
          'payers': [
            {'memberId': 'm1', 'amount': 1000}
          ],
          'shares': [
            {'memberId': 'm1', 'amount': 500},
            {'memberId': 'm2', 'amount': 500},
            {'memberId': 'm3', 'amount': 0},
          ],
        }),
        Recurrence(
            id: 'r2',
            frequency: 'weekly',
            startDate: '2026-09-01',
            timeZone: 'Z',
            deleted: true,
            template: {
              'description': 'Cleaner',
              'shares': [
                {'memberId': 'm2', 'amount': 100}
              ],
            }),
      ],
    );

    test('the latest repeat is the live one with the highest occurrence; lastPosted counts deleted ones', () {
      expect(s.latestRepeat('r1')?.id, 'x1');
      expect(s.lastPosted('r1'), 2);
      expect(s.latestRepeat('r9'), isNull);
      expect(s.lastPosted('r9'), 0);
    });

    test('only a series that is here and not stopped is active', () {
      expect([s.isActive('r1'), s.isActive('r2'), s.isActive('r9'), s.isActive(null)], [true, false, false, false]);
    });

    test('seriesWith: live templates where the member pays or owes more than 0', () {
      expect(s.seriesWith('m1').map((r) => r.id), ['r1']);
      expect(s.seriesWith('m2').map((r) => r.id), ['r1']); // r2 is stopped
      expect(s.seriesWith('m3'), isEmpty); // a 0 share
    });

    test('seriesNames names at most three, in order; seriesBlocker names mine', () {
      Recurrence r(String name) =>
          Recurrence(id: name, frequency: 'weekly', startDate: '2026-09-01', timeZone: 'Z', template: {'description': name});
      expect(seriesNames(AppLocalizationsEn(), [r('Rent')]), 'Rent');
      expect(seriesNames(AppLocalizationsEn(), [for (final n in ['Rent', 'Netflix', 'Gym']) r(n)]), 'Rent, Netflix, Gym');
      expect(seriesNames(AppLocalizationsEn(), [for (final n in ['Rent', 'Netflix', 'Gym', 'Water', 'Power']) r(n)]),
          'Rent, Netflix, Gym and 2 more');
      expect(s.seriesBlocker(AppLocalizationsEn(), 'm2'), "You're still in 1 repeating expense (Rent) · edit the latest one or stop it first");
      expect([s.seriesBlocker(AppLocalizationsEn(), 'm3'), s.seriesBlocker(AppLocalizationsEn(), null)], [null, null]);
    });
  });

  test('JSON without the Phase 8 keys reads as no series (older servers and sync-cases)', () {
    final s = GroupState.fromJson({
      'members': const [],
      'expenses': [
        {'id': 'x', 'description': 'd', 'amount': 1, 'currency': 'EUR', 'paidBy': 'm1', 'date': '2026-10-01', 'shares': []}
      ],
      'payments': const [],
    });
    expect(s.recurrences, isEmpty);
    expect((s.expenses.single.recurrenceId, s.expenses.single.occurrence), (null, null));
  });

  test('a move drops the series tag: the series stays in the source group', () {
    final members = [const Member(id: 'm1', name: 'Anna', userId: 'u1')];
    final moved = remapForMove(x('x1', series: 'r1', n: 3), members, members, id: 'y1', sameCurrency: true)!;
    expect((moved.recurrenceId, moved.occurrence), (null, null));
  });
}
