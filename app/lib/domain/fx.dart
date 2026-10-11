import '../core/core_guard.dart';

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

/// Converts a signed amount in minor units (shared/fx-cases.json, fn "amount"; docs/API.md 통화 환산).
/// - [rate] = major units of the target per 1 major unit of the source (1 JPY = 0.00616 EUR → 0.00616).
///   Not finite, or <= 0 → FxException('BAD_RATE').
/// - Exact value = amount × R × 10^(toDecimals − fromDecimals), where R is the decimal number that
///   `rate.toString()` prints (Dart's shortest round-trip form, sometimes exponent form such as `7e-7`).
///   Compute it exactly (e.g. BigInt numerator and power-of-ten denominator). Never multiply doubles:
///   100 × 0.285 is 28.499999999999996 as a double, but the answer is 29.
/// - Round to the nearest integer; exact halves go away from zero (28.5 → 29, −28.5 → −29),
///   so convertAmount(−x) == −convertAmount(x).
/// - Pure: decimals come in as arguments (Money.digits), automatic rates already arrive rounded to 6 significant digits.
/// TODO(효준): until then it throws UnimplementedError; callers go through tryCore / [fxReady].
int convertAmount({required int amount, required int fromDecimals, required int toDecimals, required double rate}) =>
    throw UnimplementedError('TODO(효준): convertAmount');

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
/// TODO(효준): until then it throws UnimplementedError; callers go through tryCore and keep the expense
/// in its own currency's bucket (docs/API.md 통화 환산).
ConvertedExpense convertExpense({
  required int amount,
  required Map<String, int> parts,
  required int fromDecimals,
  required int toDecimals,
  required double rate,
}) =>
    throw UnimplementedError('TODO(효준): convertExpense');

/// False while Hyojun's functions are stubs: Convert and every "≈" line are hidden, foreign expenses stay per currency.
bool get fxReady => tryCore(() => convertAmount(amount: 0, fromDecimals: 2, toDecimals: 2, rate: 1)) != null;
