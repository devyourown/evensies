enum SplitMode { equal, exact, percent, shares, adjustment }

/// Codes: SUM_MISMATCH, NEGATIVE_AMOUNT, NO_MEMBERS, INVALID_INPUT, NEGATIVE_SHARE.
class SplitException implements Exception {
  final String code;
  SplitException(this.code);
  @override
  String toString() => 'SplitException($code)';
}

/// Splits the expense [amount] (an integer in minor units) between [members]. The result is memberId → share.
///
/// Rules (checked by shared/split-cases.json):
/// - amount < 0 → SplitException('NEGATIVE_AMOUNT'), empty members → 'NO_MEMBERS'.
/// - equal: amount ~/ n each, and the remainder (amount % n) adds 1 each from the front in **ascending** memberId
///   order (not the order of members: ["c","a","b"], 1001 → a 334, b 334, c 333).
/// - exact: input[memberId] is used as the integer share as is. A sum other than amount → 'SUM_MISMATCH'.
/// - percent: input[memberId] is a percentage (double). Weight w = (pct × 10⁶).round(), W = Σ w.
///   |W − 10⁸| >= 1000 (±0.001%) → 'SUM_MISMATCH'. Each share = amount × w ~/ W (BigInt; dividing by the actual sum
///   means a total above 100 within the tolerance can't push the shares past the amount), and leftover minor units
///   go +1 each only to members with percent > 0, memberId ascending (a 0% member always gets 0).
///   (100, {a:33.33,b:33.33,c:33.34} → a 34, b 33, c 33)
/// - shares: input[memberId] is a share count (>= 0, may be fractional, missing = 0). Negative, NaN or infinite →
///   'INVALID_INPUT'. Weight w = (count × 100).round(), W = Σ w. W == 0 → 'NO_MEMBERS'. Each share = amount × w ~/ W
///   (integer math), leftover minor units +1 each to members with w > 0, memberId ascending.
///   (1000, {a:2, b:1, c:0} → a 667, b 333, c 0)
/// - adjustment: input[memberId] is an adjustment in minor units (may be negative, missing = 0). Not a whole number,
///   NaN or infinite → 'INVALID_INPUT'. base = amount − Σ adjustments. base < 0 → 'NEGATIVE_SHARE'. base is split like
///   equal, then each member's adjustment is added; any member left negative → 'NEGATIVE_SHARE'.
///   (1000, {b:-100} → a 367, b 267, c 366)
/// - input keys not in [members] are ignored. The result always sums to amount and has every member as a key
///   (0 included).
Map<String, int> computeSplit({
  required int amount,
  required SplitMode mode,
  required List<String> members,
  Map<String, double>? input,
}) {
  if (amount < 0) throw SplitException('NEGATIVE_AMOUNT');
  if (members.isEmpty) throw SplitException('NO_MEMBERS');
  final sorted = [...members]..sort();
  double valueOf(String member) => input?[member] ?? 0;

  switch (mode) {
    case SplitMode.equal:
      return _splitEqually(amount, sorted);

    case SplitMode.exact:
      final result = {for (final member in sorted) member: valueOf(member).toInt()};
      if (_sum(result) != amount) throw SplitException('SUM_MISMATCH');
      return result;

    case SplitMode.percent:
      final weights = <String, BigInt>{};
      final totalPercent = sorted.fold(BigInt.from(0), (total, member) {
        weights[member] = BigInt.from((valueOf(member) * 1000000).round());
        return total + weights[member]!;
      });
      if (((totalPercent - BigInt.from(100000000)).abs() >= BigInt.from(1000)) ) throw SplitException('SUM_MISMATCH');
      final result = {for (final member in sorted) member: ((BigInt.from(amount) * weights[member]! ~/ totalPercent)).toInt()};
      _addOneEach(result, sorted.where((member) => valueOf(member) > 0), amount - _sum(result));
      return result;

    case SplitMode.shares:
      final weights = <String, int>{};
      for (final member in sorted) {
        final count = valueOf(member);
        if (!count.isFinite || count.isNegative) throw SplitException('INVALID_INPUT');
        weights[member] = (count * 100).round();
      }
      final totalWeight = _sum(weights);
      if (totalWeight == 0) throw SplitException('NO_MEMBERS');
      final result = {for (final member in sorted) member: amount * weights[member]! ~/ totalWeight};
      _addOneEach(result, sorted.where((member) => weights[member]! > 0), amount - _sum(result));
      return result;

    case SplitMode.adjustment:
      final adjustments = <String, int>{};
      for (final member in sorted) {
        final adjustment = valueOf(member);
        if (!adjustment.isFinite || adjustment != adjustment.truncateToDouble()) throw SplitException('INVALID_INPUT');
        adjustments[member] = adjustment.toInt();
      }
      final base = amount - _sum(adjustments);
      if (base < 0) throw SplitException('NEGATIVE_SHARE');
      final result = _splitEqually(base, sorted);
      for (final member in sorted) {
        result[member] = result[member]! + adjustments[member]!;
        if (result[member]! < 0) throw SplitException('NEGATIVE_SHARE');
      }
      return result;
  }
}

/// [amount] ~/ n each, the remainder +1 each in [sorted] order (memberId ascending).
Map<String, int> _splitEqually(int amount, List<String> sorted) {
  final result = {for (final member in sorted) member: amount ~/ sorted.length};
  _addOneEach(result, sorted, amount % sorted.length);
  return result;
}

/// Adds 1 to the first [count] of [members] (already in memberId order).
void _addOneEach(Map<String, int> result, Iterable<String> members, int count) {
  if (count <= 0) return;
  for (final member in members.take(count)) {
    result[member] = result[member]! + 1;
  }
}

int _sum(Map<String, int> values) => values.values.fold(0, (total, value) => total + value);
