enum SplitMode { equal, exact, percent, shares, adjustment }

/// Codes: SUM_MISMATCH, NEGATIVE_AMOUNT, NO_MEMBERS, INVALID_INPUT, NEGATIVE_SHARE.
class SplitException implements Exception {
  final String code;
  SplitException(this.code);
  @override
  String toString() => 'SplitException($code)';
}

/// 지출 [amount](최소 단위 정수)를 [members]에게 나눈다. 결과는 memberId → 몫.
///
/// 규칙(shared/split-cases.json이 검증):
/// - amount < 0 → SplitException('NEGATIVE_AMOUNT'), members 비어 있음 → 'NO_MEMBERS'.
/// - equal: amount ~/ n 씩 주고, 나머지(amount % n)는 memberId **오름차순**으로 앞에서부터 1씩 더한다
///   (members 입력 순서가 아님: ["c","a","b"], 1001 → a 334, b 334, c 333).
/// - exact: input[memberId]를 정수 몫으로 그대로 쓴다. 합이 amount와 다르면 'SUM_MISMATCH'.
/// - percent: input[memberId]는 퍼센트(double). 가중치 w = (pct × 10⁶).round(), W = Σ w.
///   |W − 10⁸| >= 1000(±0.001%)이면 'SUM_MISMATCH'. 각 몫 = amount × w ~/ W (BigInt, 실제 합으로 나누므로
///   허용 오차 안에서 100을 넘어도 합이 금액을 넘지 않음), 남는 최소 단위는 percent > 0인 멤버에게만 memberId 오름차순 +1씩
///   (0% 멤버는 항상 0). (100, {a:33.33,b:33.33,c:33.34} → a 34, b 33, c 33)
/// - shares: input[memberId]는 몫 개수(>= 0, 소수 가능, 없으면 0). 음수·NaN·무한 → 'INVALID_INPUT'.
///   가중치 w = (개수 × 100).round(), W = Σ w. W == 0 → 'NO_MEMBERS'. 각 몫 = amount × w ~/ W (정수 계산),
///   남는 최소 단위는 w > 0인 멤버에게 memberId 오름차순 +1씩. (1000, {a:2, b:1, c:0} → a 667, b 333, c 0)
/// - adjustment: input[memberId]는 최소 단위 조정액(음수 가능, 없으면 0). 정수가 아니거나 NaN·무한 → 'INVALID_INPUT'.
///   base = amount − Σ 조정액. base < 0 → 'NEGATIVE_SHARE'. base를 equal처럼 나눈 뒤 각자 조정액을 더하고,
///   결과가 음수인 멤버가 있으면 'NEGATIVE_SHARE'. (1000, {b:-100} → a 367, b 267, c 366)
/// - [members]에 없는 input 키는 무시한다. 결과의 합은 항상 amount, 결과 맵은 모든 member를 키로 가진다(0 포함).
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
