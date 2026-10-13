import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/domain/fx.dart';

import '../shared_json.dart';

// Run: flutter test test/domain
void main() {
  for (final c in sharedCases('fx-cases.json')) {
    test(c['name'] as String, () {
      final rate = (c['rate'] as num).toDouble();
      final from = c['fromDecimals'] as int, to = c['toDecimals'] as int;
      Object run() => c['fn'] == 'amount'
          ? convertAmount(amount: c['amount'] as int, fromDecimals: from, toDecimals: to, rate: rate)
          : convertExpense(
              amount: c['amount'] as int,
              parts: (c['parts'] as Map).cast<String, int>(),
              fromDecimals: from,
              toDecimals: to,
              rate: rate);

      if (c['error'] != null) {
        expect(run, throwsA(isA<FxException>().having((e) => e.code, 'code', c['error'])));
      } else if (c['fn'] == 'amount') {
        expect(run(), c['expected']);
      } else {
        final r = run() as ConvertedExpense;
        final want = c['expected'] as Map;
        expect(r.amount, want['amount']);
        expect(r.parts, (want['parts'] as Map).cast<String, int>());
      }
    });
  }
}
