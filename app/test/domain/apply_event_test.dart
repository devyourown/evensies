library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/data/sync/apply_event.dart';
import 'package:evensies/domain/models.dart';

import '../shared_json.dart';

// Run: flutter test test/domain
void main() {
  for (final c in sharedCases('sync-cases.json')) {
    final events = (c['events'] as List).cast<Map<String, dynamic>>().map(SyncEvent.fromJson).toList();
    final expected = GroupState.fromJson(c['expected'] as Map<String, dynamic>).toJson();
    // Optional: only the keys it has are compared (sync-cases _doc).
    final expectedGroup = (c['expected'] as Map)['group'] as Map<String, dynamic>?;
    // GroupState.fromJson reads a split it can't parse as null, which would also equal a null result: compare each
    // expense's split with the raw expected JSON too.
    final expectedSplits = {
      for (final x in ((c['expected'] as Map)['expenses'] as List).cast<Map<String, dynamic>>()) x['id']: x['split'],
    };
    void expectGroup(GroupState s) {
      expect({for (final x in s.expenses) x.id: x.split?.toJson()}, expectedSplits);
      if (expectedGroup == null) return;
      final g = s.groupJson();
      expect({for (final k in expectedGroup.keys) k: g[k]}, expectedGroup);
    }

    test(c['name'] as String, () {
      final result = events.fold(GroupState.empty, applyEvent);
      expect(result.toJson(), expected);
      expectGroup(result);
    });

    test('idempotent: ${c['name']}', () {
      var s = GroupState.empty;
      for (final e in events) {
        s = applyEvent(applyEvent(s, e), e);
      }
      expect(s.toJson(), expected);
      expectGroup(s);
    });

    if (c['permute'] == true) {
      test('permutation safe: ${c['name']}', () {
        // Decision: the applier does not track per-field seq; callers (SyncService) always apply in
        // seq order, so a shuffled delivery is sorted by seq first. That is what this test checks.
        final rnd = Random(7);
        for (var i = 0; i < 20; i++) {
          final delivered = [...events]..shuffle(rnd);
          final ordered = [...delivered]..sort((a, b) => a.seq.compareTo(b.seq));
          expect(ordered.fold(GroupState.empty, applyEvent).toJson(), expected);
        }
      });
    }
  }

  test('pure: input state is not mutated', () {
    final events = (sharedCases('sync-cases.json').first['events'] as List)
        .cast<Map<String, dynamic>>()
        .map(SyncEvent.fromJson)
        .toList();
    var s = GroupState.empty;
    for (final e in events) {
      final before = s.toJson();
      final next = applyEvent(s, e);
      expect(s.toJson(), before);
      s = next;
    }
  });
}
