import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/domain/activity.dart';
import 'package:evensies/domain/categories.dart';

import 'shared_json.dart';

void main() {
  setUpAll(() {
    Money.loadFromJson(File('../shared/currencies.json').readAsStringSync());
    Categories.loadFromJson(File('../shared/categories.json').readAsStringSync()); // category change labels
  });
  final golden = loadShared('activity-cases.json');

  group('shared/activity-cases.json: expected items → texts', () {
    for (final c in (golden['cases'] as List).cast<Map<String, dynamic>>()) {
      test(c['name'] as String, () {
        final names = (c['names'] as Map).cast<String, String>();
        final items = (c['expected'] as List).cast<Map<String, dynamic>>().map(ActivityItem.fromJson);
        // A friend group (seq 1 group.created kind "friend") has its own delete/restore sentences.
        final friend = (((c['events'] as List).first as Map)['payload'] as Map)['kind'] == 'friend';
        expect([for (final i in items) activityText(i, names, c['me'] as String, friend: friend)], c['texts']);
      });
    }
  });

  test('shared/activity-cases.json: money', () {
    for (final m in (golden['money'] as List).cast<Map<String, dynamic>>()) {
      expect(formatMoney(m['minor'] as int, m['currency'] as String, lang: m['lang'] as String? ?? 'en'), m['text'],
          reason: '$m');
    }
  });

  group('shared/activity-cases.json: localized sentences (one item; batches and reminders are the server\'s)', () {
    for (final c in (golden['localized'] as List).cast<Map<String, dynamic>>()) {
      final items = (c['items'] as List?)?.cast<Map<String, dynamic>>();
      test(c['name'] as String, () {
        final names = (c['names'] as Map).cast<String, String>();
        expect(activityText(ActivityItem.fromJson(items!.single), names, c['me'] as String, lang: c['lang'] as String),
            c['text']);
      }, skip: items?.length == 1 ? null : 'server only');
    }
  });

  test('formatMoney starts with the shared symbol for every currency', () {
    final symbols = (loadShared('currencies.json')['symbols'] as Map).cast<String, String>();
    expect(Money.decimals.keys.toSet().containsAll(symbols.keys), isTrue); // codes without a symbol show the ISO code (Phase 4)
    for (final e in symbols.entries) {
      final f = formatMoney(123456, e.key);
      expect(f.startsWith(e.value), isTrue, reason: '${e.key}: $f');
      // A symbol ending in a Latin letter is followed by a no-break space (docs/API.md 금액 표기).
      expect(RegExp('^\u00a0?\\d').hasMatch(f.substring(e.value.length)), isTrue, reason: '${e.key}: $f');
    }
  });

  test("a friend group's delete and restore don't name the internal group", () {
    ActivityItem i(String kind, String actor) =>
        ActivityItem.fromJson({'seq': 9, 'kind': kind, 'actorMemberId': actor, 'name': 'Anna & Ben'});
    const names = {'m1': 'Anna', 'm2': 'Ben'};
    expect(activityText(i('group_deleted', 'm1'), names, 'm2', friend: true), 'Anna deleted your non-group expenses');
    expect(activityText(i('group_restored', 'm2'), names, 'm2', friend: true), 'You restored these non-group expenses');
    expect(activityText(i('group_deleted', 'm1'), names, 'm2'), 'Anna deleted the group “Anna & Ben”');
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

  test('Phase 10: group deleted and restored, and the type and cover changes (unknown type reads Other)', () {
    String text(Map<String, dynamic> j, {String me = 'm1', String lang = 'en'}) =>
        activityText(ActivityItem.fromJson({'seq': 1, 'actorMemberId': 'm2', ...j}), const {'m2': 'Ben'}, me, lang: lang);
    expect(text({'kind': 'group_deleted', 'name': 'Rome'}), 'Ben deleted the group “Rome”');
    expect(text({'kind': 'group_restored', 'name': 'Rome'}), 'Ben restored the group “Rome”');
    expect(text({'kind': 'group_deleted', 'name': 'Rome'}, me: 'm2'), 'You deleted the group “Rome”');
    expect(
        text({
          'kind': 'group_updated',
          'changes': [
            {'field': 'type', 'from': 'other', 'to': 'trip'}
          ]
        }),
        'Ben changed the group: type Trip');
    expect(
        text({
          'kind': 'group_updated',
          'changes': [
            {'field': 'coverImageId', 'from': null, 'to': 'c1'},
            {'field': 'type', 'from': 'trip', 'to': 'boat'},
          ]
        }),
        'Ben changed the group: cover photo, type Other');
    expect(text({'kind': 'group_restored', 'name': 'Roma'}, lang: 'ko'), 'Ben님이 ‘Roma’ 그룹을 복원했어요');
  });
}
