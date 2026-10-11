import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/domain/activity.dart';

import 'shared_json.dart';

void main() {
  setUpAll(() => Money.loadFromJson(File('../shared/currencies.json').readAsStringSync()));
  final golden = loadShared('activity-cases.json');

  group('shared/activity-cases.json: expected items → texts', () {
    for (final c in (golden['cases'] as List).cast<Map<String, dynamic>>()) {
      test(c['name'] as String, () {
        final names = (c['names'] as Map).cast<String, String>();
        final items = (c['expected'] as List).cast<Map<String, dynamic>>().map(ActivityItem.fromJson);
        expect([for (final i in items) activityText(i, names, c['me'] as String)], c['texts']);
      });
    }
  });

  test('shared/activity-cases.json: money', () {
    for (final m in (golden['money'] as List).cast<Map<String, dynamic>>()) {
      expect(formatMoney(m['minor'] as int, m['currency'] as String), m['text']);
    }
  });

  test('formatMoney starts with the shared symbol for every currency', () {
    final symbols = (loadShared('currencies.json')['symbols'] as Map).cast<String, String>();
    expect(symbols.keys.toSet(), Money.decimals.keys.toSet());
    for (final e in symbols.entries) {
      final f = formatMoney(123456, e.key);
      expect(f.startsWith(e.value), isTrue, reason: '${e.key}: $f');
      expect(RegExp(r'\d').hasMatch(f.substring(e.value.length, e.value.length + 1)), isTrue, reason: '${e.key}: $f');
    }
  });

  test('missing keys default to null and changes to []', () {
    final i = ActivityItem.fromJson(jsonDecode('{"seq":3,"kind":"member_joined","memberId":"m2"}') as Map<String, dynamic>);
    expect(i.actorMemberId, isNull);
    expect(i.changes, isEmpty);
    expect(activityText(i, const {}, null), 'Someone joined');
  });

  test('unknown kind still renders', () {
    final i = ActivityItem.fromJson({'seq': 1, 'kind': 'future_thing', 'actorMemberId': 'm1'});
    expect(activityText(i, const {'m1': 'Anna'}, 'm2'), 'Anna made a change');
  });
}
