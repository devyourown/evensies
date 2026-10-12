import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/data/api/dto.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/fx_rates.dart';

import 'fakes.dart';

void main() {
  setUpAll(() => Money.loadFromJson('{"decimals":{"EUR":2,"USD":2,"JPY":0,"KRW":0},"symbols":{"EUR":"€","USD":"\$","GBP":"£","JPY":"¥","KRW":"₩"}}'));

  test('crossRate: to/from through EUR, 6 significant digits; null without both rates', () {
    const perEur = {'EUR': 1.0, 'JPY': 177.51, 'KRW': 1472.81, 'USD': 1.1217, 'XXX': 0.0};
    expect(crossRate(perEur, 'JPY', 'EUR'), 0.00563349); // 1 / 177.51
    expect(crossRate(perEur, 'EUR', 'JPY'), 177.51);
    expect(crossRate(perEur, 'JPY', 'KRW'), 8.29705); // 1472.81 / 177.51 = 8.2970536…
    expect(crossRate(perEur, 'USD', 'USD'), 1.0);
    expect(crossRate(perEur, 'JPY', 'GBP'), isNull);
    expect(crossRate(perEur, 'XXX', 'EUR'), isNull);
  });

  test('GET /fx parses into units per 1 EUR', () {
    final t = FxTable.fromJson({
      'date': '2026-10-10',
      'base': 'EUR',
      'rates': {'EUR': 1, 'JPY': 177.51},
    });
    expect([t.date, t.rates, t.offline], ['2026-10-10', {'EUR': 1.0, 'JPY': 177.51}, false]);
  });

  group('lookup', () {
    late AppDatabase db;
    late FakeApi api;
    late FxRates fx;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      api = FakeApi(db);
      fx = FxRates(db, api);
    });
    tearDown(() => db.close());

    FxTable table(String date, double jpy) => FxTable(date: date, rates: {'EUR': 1, 'JPY': jpy});

    test('online: the server answer, stored under its date', () async {
      api.onFx = (_) => table('2026-10-09', 170);
      final t = await fx.lookup('2026-10-11');
      expect((t!.date, t.offline), ('2026-10-09', false));
      expect(api.fxCalls, ['2026-10-11']);
      expect((await fx.cached())!.rates['JPY'], 170.0);
    });

    test('offline: the greatest cached day ≤ date, else the newest, else nothing', () async {
      expect(await fx.lookup('2026-10-11'), isNull);
      for (final (d, r) in [('2026-10-01', 160.0), ('2026-10-08', 170.0), ('2026-10-10', 180.0)]) {
        api.onFx = (_) => table(d, r);
        await fx.lookup(d);
      }
      api.onFx = null;
      final mid = (await fx.lookup('2026-10-09'))!;
      expect((mid.date, mid.offline, mid.rates['JPY']), ('2026-10-08', true, 170.0));
      expect((await fx.lookup('2026-09-01'))!.date, '2026-10-10'); // older than every row: the newest
      expect((await fx.lookup())!.date, '2026-10-10');
      expect((await fx.watchLatest().first)!.date, '2026-10-10');
    });
  });

  group('approxIn', () {
    // Not Hyojun's rounding: a stand-in so the sum and the hiding rules are tested apart from convertAmount.
    int conv({required int amount, required int fromDecimals, required int toDecimals, required double rate}) =>
        (amount * rate * [1, 10, 100][toDecimals] / [1, 10, 100][fromDecimals]).round();
    const perEur = {'EUR': 1.0, 'USD': 1.25, 'JPY': 125.0};

    test('sums every bucket in the home currency', () {
      expect(approxIn('USD', {'EUR': 1000, 'JPY': -1250}, perEur, convert: conv), 1250 - 1250);
      expect(approxIn('USD', {'EUR': -1000}, perEur, convert: conv), -1250);
      expect(approxIn('EUR', {'EUR': 500, 'JPY': 1250}, perEur, convert: conv), 1500);
    });

    test('hidden when only the home currency is involved, a rate is missing, or there is no table', () {
      expect(approxIn('EUR', {'EUR': 500, 'JPY': 0}, perEur, convert: conv), isNull);
      expect(approxIn('USD', const {}, perEur, convert: conv), isNull);
      expect(approxIn('GBP', {'EUR': 500}, perEur, convert: conv), isNull);
      expect(approxIn('USD', {'EUR': 500}, null, convert: conv), isNull);
    });

    test('with the real convertAmount', () {
      expect(approxIn('USD', {'EUR': 500}, perEur), isNotNull);
    });
  });
}
