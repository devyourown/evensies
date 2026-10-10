// Sanity check for the NAIVE_APPLY reference applier. Delete together with apply_event_naive.dart.
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/data/sync/apply_event_naive.dart';
import 'package:tally/domain/models.dart';

import 'shared_json.dart';

void main() {
  for (final c in sharedCases('sync-cases.json')) {
    test('naive: ${c['name']}', () {
      final events = (c['events'] as List).cast<Map<String, dynamic>>().map(SyncEvent.fromJson).toList();
      var s = GroupState.empty;
      for (final e in events) {
        s = applyEventNaive(s, e);
        s = applyEventNaive(s, e); // idempotent
      }
      expect(s.toJson(), GroupState.fromJson(c['expected'] as Map<String, dynamic>).toJson());
    });
  }
}
