import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/ids.dart';
import '../core/money.dart';
import '../domain/balances.dart' show tryFx;
import '../domain/fx.dart';
import 'api/api_client.dart';
import 'api/dto.dart';
import 'db/database.dart';

/// Units of [to] per 1 unit of [from] from a table of units per 1 EUR, rounded to 6 significant digits
/// (docs/API.md fxRateToDefault: 1/177.51 → 0.00563349). Null if either rate is missing or not above 0.
double? crossRate(Map<String, double> perEur, String from, String to) {
  final f = perEur[from], t = perEur[to];
  if (f == null || t == null || !(f > 0) || !(t > 0)) return null;
  return double.parse((t / f).toStringAsPrecision(6));
}

typedef AmountFn = int Function({required int amount, required int fromDecimals, required int toDecimals, required double rate});

/// "≈ H" (docs/API.md, Balances per currency): Σ over [amounts] (currency → minor units) of convertAmount into [home] at
/// crossRate(perEur, X, home). Null when it adds nothing (every non-zero amount is already in [home], or all are zero),
/// or when a rate is missing.
int? approxIn(String home, Map<String, int> amounts, Map<String, double>? perEur, {AmountFn convert = convertAmount}) {
  final nonZero = {for (final e in amounts.entries) if (e.value != 0) e.key: e.value};
  if (perEur == null || nonZero.keys.every((c) => c == home)) return null;
  var sum = 0;
  for (final MapEntry(key: cur, value: v) in nonZero.entries) {
    if (cur == home) {
      sum += v;
      continue;
    }
    final r = crossRate(perEur, cur, home);
    final c = r == null
        ? null
        : tryFx(() => convert(amount: v, fromDecimals: Money.digits(cur), toDecimals: Money.digits(home), rate: r));
    if (c == null) return null;
    sum += c;
  }
  return sum;
}

/// Rate tables (docs/API.md, Exchange rates, app part): the server when online, this device's cache (drift FxDays) otherwise.
/// The app never calls Frankfurter itself.
class FxRates {
  final AppDatabase db;
  final ApiClient api;
  FxRates(this.db, this.api);

  /// Online: the server's table for [date] (YYYY-MM-DD, null = today), stored under its `date`. Offline or on any
  /// error (503, 429 included): the cached table with the greatest day ≤ [date], else the newest one ([FxTable.offline]),
  /// else null (no automatic rate).
  Future<FxTable?> lookup([String? date]) async {
    try {
      final t = await api.fx(date);
      await db.into(db.fxDays).insertOnConflictUpdate(
          FxDayRow(day: t.date, ratesJson: jsonEncode(t.rates), fetchedAt: nowIsoUtc()));
      return t;
    } catch (_) {
      return cached(date);
    }
  }

  Future<FxTable?> cached([String? date]) async {
    FxDayRow? row;
    if (date != null) {
      row = await (db.select(db.fxDays)
            ..where((d) => d.day.isSmallerOrEqualValue(date))
            ..orderBy([(d) => OrderingTerm.desc(d.day)])
            ..limit(1))
          .getSingleOrNull();
    }
    row ??= await _newest().getSingleOrNull();
    return row == null ? null : _table(row, offline: true);
  }

  /// The newest cached table, for the "≈" lines (prefetched at app start).
  Stream<FxTable?> watchLatest() => _newest().watchSingleOrNull().map((r) => r == null ? null : _table(r));

  Selectable<FxDayRow> _newest() =>
      db.select(db.fxDays)
        ..orderBy([(d) => OrderingTerm.desc(d.day)])
        ..limit(1);

  static FxTable _table(FxDayRow r, {bool offline = false}) =>
      FxTable.fromJson({'date': r.day, 'rates': jsonDecode(r.ratesJson)}, offline: offline);
}
