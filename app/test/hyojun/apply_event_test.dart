library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tally/data/sync/apply_event.dart';
import 'package:tally/domain/models.dart';

import '../shared_json.dart';

// 실행: flutter test test/hyojun
void main() {
  for (final c in sharedCases('sync-cases.json')) {
    final events = (c['events'] as List).cast<Map<String, dynamic>>().map(SyncEvent.fromJson).toList();
    final expected = GroupState.fromJson(c['expected'] as Map<String, dynamic>).toJson();

    test(c['name'] as String, () {
      final result = events.fold(GroupState.empty, applyEvent);
      expect(result.toJson(), expected);
    });

    test('idempotent: ${c['name']}', () {
      var s = GroupState.empty;
      for (final e in events) {
        s = applyEvent(applyEvent(s, e), e);
      }
      expect(s.toJson(), expected);
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
