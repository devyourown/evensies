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
/// - percent: input[memberId]는 퍼센트(double). 합이 100(±0.001)이 아니면 'SUM_MISMATCH'.
///   각 몫 = (amount * pct / 100).floor(), 남는 최소 단위는 equal과 같은 규칙으로 memberId 오름차순 +1씩.
///   (100, {a:33.33,b:33.33,c:33.34} → a 34, b 33, c 33)
/// - 결과의 합은 항상 amount. 결과 맵은 모든 member를 키로 가진다(0 포함).
///
/// Phase 3 — TODO(효준) (docs/API.md "SplitSpec", cases marked "pending": "hyojun" in shared/split-cases.json):
/// - percent: unchanged, except that leftover minor units go only to members whose percent is > 0
///   (memberId ascending). A 0% member always gets 0. Today a 0% member can be charged 1 cent.
/// - shares: input[memberId] is a share count (>= 0, may be fractional, missing = 0).
///   Negative, NaN or infinite → 'INVALID_INPUT'. Weights w = (count * 100).round(), W = Σ w over [members].
///   W == 0 → 'NO_MEMBERS'. Each share = amount * w ~/ W (integer math, no doubles).
///   Leftover = amount − Σ shares: +1 each to members with w > 0, memberId ascending (always fewer than them).
///   (1000, {a:2, b:1, c:0} → a 667, b 333, c 0)
/// - adjustment: input[memberId] is an adjustment in minor units (may be negative, missing = 0).
///   Not a whole number, NaN or infinite → 'INVALID_INPUT'. base = amount − Σ adj over [members].
///   base < 0 → 'NEGATIVE_SHARE'. Split base exactly like equal over all [members], then add each member's adj.
///   Any result < 0 → 'NEGATIVE_SHARE'. (1000, {b:-100} → a 367, b 267, c 366)
/// - shares/adjustment: input keys not in [members] are ignored.
/// - Always: the result has every member as a key (0 included) and sums to amount.
/// Until then shares/adjustment throw UnimplementedError; callers go through tryCore/implemented (core/core_guard.dart).
Map<String, int> computeSplit({
  required int amount,
  required SplitMode mode,
  required List<String> members,
  Map<String, double>? input,
}) {
  if (amount < 0) throw SplitException('NEGATIVE_AMOUNT');
  if (members.isEmpty) throw SplitException('NO_MEMBERS');
  Map<String, int> result =  <String, int>{};
  if (SplitMode.equal == mode) {
    int quotient =  amount ~/ members.length;
    int remainder = amount % members.length;
    List<String> sorted = [...members]..sort();
    for (final member in sorted) {
      result.putIfAbsent(member, () => (quotient));
    }
    _giveRemainder(result, sorted, remainder);
  } else if (SplitMode.exact == mode) {
    for (final memberId in members) {
      result.putIfAbsent(memberId, () => input?[memberId]?.toInt() ?? 0);
    }
    final total = result.values.reduce((value, element) => value + element);
    if (amount != total) throw SplitException('SUM_MISMATCH');
  } else if (SplitMode.percent == mode) {
    final totalPercent = input?.values.fold(0.0, (value, element) => value + element) ?? 0;
    if ((totalPercent - 100).abs() >= 0.001) throw SplitException('SUM_MISMATCH');
    final sorted = [...members]..sort();
    for (final member in sorted) {
      int quotient = (amount * (input?[member] ?? 0) / 100).floor();
      result.putIfAbsent(member, () => quotient);
    }
    final k = amount - result.values.reduce((value, element) => value + element);
    // TODO(효준): the leftover goes only to members whose percent is > 0 (see the doc comment above).
    _giveRemainder(result, sorted, k);
  } else {
    throw UnimplementedError('TODO(효준): ${mode.name}');
  }
  return result;
}

void _giveRemainder(Map<String,int> result, List<String> sorted, int k) {
  for (final (index, member) in sorted.indexed) {
    result.update(member, (v) => index < k ? v+1 : v);
  }
}