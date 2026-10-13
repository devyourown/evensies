/// Codes: BAD_RATE, NEGATIVE_AMOUNT, SUM_MISMATCH.
class FxException implements Exception {
  final String code;
  FxException(this.code);
  @override
  String toString() => 'FxException($code)';
}

class ConvertedExpense {
  final int amount;
  final Map<String, int> parts;
  const ConvertedExpense({required this.amount, required this.parts});
}

/// Converts a signed amount in minor units (shared/fx-cases.json, fn "amount"; docs/API.md, Currency conversion).
/// - [rate] = major units of the target per 1 major unit of the source (1 JPY = 0.00616 EUR → 0.00616).
///   Not finite, or <= 0 → FxException('BAD_RATE').
/// - Exact value = amount × R × 10^(toDecimals − fromDecimals), where R is the decimal number that
///   `rate.toString()` prints (Dart's shortest round-trip form, sometimes exponent form such as `7e-7`).
///   Computed exactly with BigInt, never by multiplying doubles: 100 × 0.285 is 28.499999999999996 as a double,
///   but the answer is 29.
/// - Round to the nearest integer; exact halves go away from zero (28.5 → 29, −28.5 → −29),
///   so convertAmount(−x) == −convertAmount(x).
/// - Pure: decimals come in as arguments (Money.digits), automatic rates already arrive rounded to 6 significant digits.
int convertAmount({required int amount, required int fromDecimals, required int toDecimals, required double rate}) {
  _checkRate(rate);
  final (numerator, denominator) = _exactValue(amount, fromDecimals, toDecimals, rate);
  final truncated = numerator ~/ denominator; // toward zero
  final atLeastHalf = numerator.remainder(denominator).abs() * BigInt.two >= denominator;
  if (!atLeastHalf) return truncated.toInt();
  return (truncated + (numerator.isNegative ? -BigInt.one : BigInt.one)).toInt();
}

/// Converts an expense total and its parts (shares, and separately the payer amounts: one call per map)
/// so the converted parts add up to the converted total (shared/fx-cases.json, fn "expense").
/// - Checks, in this order: bad rate → 'BAD_RATE'; amount < 0 or any part < 0 → 'NEGATIVE_AMOUNT';
///   sum(parts) != amount → 'SUM_MISMATCH'.
/// - total = convertAmount(amount, …).
/// - Each part: its exact value as in convertAmount, rounded down.
/// - leftover = total − sum of the rounded-down parts (always between 0 and the number of parts).
///   Give +1 to the `leftover` parts whose dropped fraction is largest; equal fractions → memberId ascending
///   (largest remainder method). A part of 0 has no fraction and never gets +1.
/// - The result has exactly the keys of [parts], and its parts sum to its amount. Input map order does not matter.
ConvertedExpense convertExpense({
  required int amount,
  required Map<String, int> parts,
  required int fromDecimals,
  required int toDecimals,
  required double rate,
}) {
  _checkRate(rate);
  if (amount < 0 || parts.values.any((part) => part < 0)) throw FxException('NEGATIVE_AMOUNT');
  if (parts.values.fold(0, (total, part) => total + part) != amount) throw FxException('SUM_MISMATCH');
  final total = convertAmount(amount: amount, fromDecimals: fromDecimals, toDecimals: toDecimals, rate: rate);

  final converted = <String, int>{}; // each part rounded down
  final dropped = <String, BigInt>{}; // what rounding down cut off; every part shares one denominator, so these compare
  for (final MapEntry(key: member, value: part) in parts.entries) {
    final (numerator, denominator) = _exactValue(part, fromDecimals, toDecimals, rate);
    converted[member] = (numerator ~/ denominator).toInt();
    dropped[member] = numerator.remainder(denominator);
  }
  final leftover = total - converted.values.fold<int>(0, (sum, part) => sum + part);
  final largestDropFirst = [for (final MapEntry(:key, :value) in parts.entries) if (value > 0) key]
    ..sort((a, b) {
      final byDrop = dropped[b]!.compareTo(dropped[a]!);
      return byDrop != 0 ? byDrop : a.compareTo(b);
    });
  for (final member in largestDropFirst.take(leftover)) {
    converted[member] = converted[member]! + 1;
  }
  return ConvertedExpense(amount: total, parts: converted);
}

void _checkRate(double rate) {
  if (!rate.isFinite || rate <= 0) throw FxException('BAD_RATE');
}

/// The exact value of amount × R × 10^(toDecimals − fromDecimals) as a fraction (numerator, denominator > 0),
/// where R is the decimal that `rate.toString()` prints ("0.00616", "1472.81", "1.0", "7e-7", "1.5e-7").
(BigInt, BigInt) _exactValue(int amount, int fromDecimals, int toDecimals, double rate) {
  final text = rate.toString();
  final e = text.indexOf('e');
  final mantissa = e < 0 ? text : text.substring(0, e);
  final dot = mantissa.indexOf('.');
  final digits = BigInt.parse(mantissa.replaceFirst('.', '')); // R = digits × 10^scale
  final exponent = e < 0 ? 0 : int.parse(text.substring(e + 1));
  final scale = exponent - (dot < 0 ? 0 : mantissa.length - dot - 1) + toDecimals - fromDecimals;
  final numerator = BigInt.from(amount) * digits;
  return scale >= 0 ? (numerator * BigInt.from(10).pow(scale), BigInt.one) : (numerator, BigInt.from(10).pow(-scale));
}
