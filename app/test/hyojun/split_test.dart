// ignore_for_file: unused_element, unused_local_variable
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:tally/domain/split.dart';

import '../shared_json.dart';

// 실행: flutter test test/hyojun   (CI는 --exclude-tags hyojun 으로 이 파일을 건너뛴다)
void main() {
  for (final c in sharedCases('split-cases.json')) {
    test(c['name'] as String, () {
      final mode = SplitMode.values.byName(c['mode'] as String);
      final members = (c['members'] as List).cast<String>();
      final input = (c['input'] as Map?)?.map((k, v) => MapEntry(k as String, (v as num).toDouble()));
      Map<String, int> run() => computeSplit(amount: c['amount'] as int, mode: mode, members: members, input: input);

      if (c['error'] != null) {
        expect(run, throwsA(isA<SplitException>().having((e) => e.code, 'code', c['error'])));
      } else {
        expect(run(), (c['expected'] as Map).cast<String, int>());
      }
    });
  }

  group('properties', () {
    test('shares always sum to amount (equal)', () {
      // TODO(효준): for amount in 0..1000, members ['c','a','b'] → computeSplit(...).values.sum == amount
      final members = ['c', 'a', 'b'];
      for (var amount = 0; amount <= 1000; amount++) {
        expect(computeSplit(amount: amount, mode: SplitMode.equal, members: members).values.reduce((value, element) => value + element), amount);
      }
    });
    test('remainder goes to lowest member ids first', () {
      // TODO(효준): amount 1002, members ['b','c','a'] → a 334, b 334, c 334 / amount 1001 → a 334, b 334, c 333
      final result = computeSplit(amount: 1002, mode: SplitMode.equal, members: ['b', 'c', 'a']);
      expect(result['a'], 334);
      expect(result['b'], 334);
      expect(result['c'], 334);
      final second = computeSplit(amount: 1001, mode: SplitMode.equal, members: ['b', 'c', 'a']);
      expect(second['a'], 334);
      expect(second['b'], 334);
      expect(second['c'], 333);
    });
    test('deterministic: same input twice gives same output', () {
      // TODO(효준): call twice with members in different order, expect equal maps
      final first = computeSplit(amount: 1002, mode: SplitMode.equal, members: ['b', 'c', 'a']);
      final second = computeSplit(amount: 1002, mode: SplitMode.equal, members: ['a', 'b', 'c']);
      expect(first, second);
    });
  });
}
