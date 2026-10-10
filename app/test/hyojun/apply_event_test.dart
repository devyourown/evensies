@Tags(['hyojun'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tally/data/sync/apply_event.dart';
import 'package:tally/domain/models.dart';

import '../shared_json.dart';

// 실행: flutter test test/hyojun
// 통과하면 lib/data/sync/apply_event_naive.dart 와 test/apply_event_naive_test.dart 를 지운다.
void main() {
  for (final c in sharedCases('sync-cases.json')) {
    final events = (c['events'] as List).cast<Map<String, dynamic>>().map(SyncEvent.fromJson).toList();
    final expected = GroupState.fromJson(c['expected'] as Map<String, dynamic>).toJson();

    test(c['name'] as String, () {
      final result = events.fold(GroupState.empty, applyEvent);
      // TODO(효준): expect(result.toJson(), expected);
      fail('TODO(효준) $result $expected');
    });

    test('idempotent: ${c['name']}', () {
      // TODO(효준): 각 이벤트를 두 번씩 적용해도 expected와 같다.
      fail('TODO(효준)');
    });

    if (c['permute'] == true) {
      test('permutation safe: ${c['name']}', () {
        // TODO(효준): events를 여러 순서로 섞어(또는 모든 순열) 적용 → 매번 expected와 같다.
        // 주의: 필드 단위 LWW는 seq 기준이므로, 적용 순서가 seq 순서가 아닐 때도 seq가 큰 쪽이 이기려면
        // 적용기가 필드별 마지막 seq를 기억하거나, 적용 전에 seq로 정렬해야 한다. 어느 쪽을 택할지 결정하고 여기에 적어 둘 것.
        fail('TODO(효준)');
      });
    }
  }

  test('pure: input state is not mutated', () {
    // TODO(효준): 적용 전 state.toJson()과 적용 후 같은 객체의 toJson()이 같다.
    fail('TODO(효준)');
  });
}
