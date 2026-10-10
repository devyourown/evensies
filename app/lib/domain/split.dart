enum SplitMode { equal, exact, percent }

/// Codes: SUM_MISMATCH, NEGATIVE_AMOUNT, NO_MEMBERS.
class SplitException implements Exception {
  final String code;
  SplitException(this.code);
  @override
  String toString() => 'SplitException($code)';
}

/// 지출 [amount](최소 단위 정수)를 [members]에게 나눈다. 결과는 memberId → 몫.
///
/// TODO(효준): 본문 구현. 규칙(shared/split-cases.json이 검증):
/// - amount < 0 → SplitException('NEGATIVE_AMOUNT'), members 비어 있음 → 'NO_MEMBERS'.
/// - equal: amount ~/ n 씩 주고, 나머지(amount % n)는 memberId **오름차순**으로 앞에서부터 1씩 더한다
///   (members 입력 순서가 아님: ["c","a","b"], 1001 → a 334, b 334, c 333).
/// - exact: input[memberId]를 정수 몫으로 그대로 쓴다. 합이 amount와 다르면 'SUM_MISMATCH'.
/// - percent: input[memberId]는 퍼센트(double). 합이 100(±0.001)이 아니면 'SUM_MISMATCH'.
///   각 몫 = (amount * pct / 100).floor(), 남는 최소 단위는 equal과 같은 규칙으로 memberId 오름차순 +1씩.
///   (100, {a:33.33,b:33.33,c:33.34} → a 34, b 33, c 33)
/// - 결과의 합은 항상 amount. 결과 맵은 모든 member를 키로 가진다(0 포함).
Map<String, int> computeSplit({
  required int amount,
  required SplitMode mode,
  required List<String> members,
  Map<String, double>? input,
}) {
  throw UnimplementedError('TODO(효준)');
}
