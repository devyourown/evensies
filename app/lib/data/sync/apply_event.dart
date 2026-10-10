import '../../domain/models.dart';

/// 순수 함수: [state]에 [event]를 적용한 새 GroupState를 돌려준다. 입력은 바꾸지 않는다.
///
/// TODO(효준): 본문 구현. docs/API.md 적용 규칙 1~5 (shared/sync-cases.json이 검증):
/// 1. 순수·멱등: 같은 이벤트를 두 번 적용해도 한 번 적용과 같다.
/// 2. 수정 vs 수정: 필드 단위로 seq 큰 쪽이 이긴다 (seq 순서대로 적용하면 자연히 성립. `expense.updated`의
///    payload.fields에 있는 키만 덮어쓴다. fields에 `shares`가 있으면 shares 전체를 교체).
/// 3. 삭제 vs 수정: deleted=true인 지출·송금에 오는 `updated`는 무시한다.
/// 4. 없는 대상에 오는 `updated`·`deleted`·`linked`·`removed`는 무시한다.
/// 5. `member.removed`는 removed=true만 표시한다(목록에서 빼지 않는다).
///
/// 이벤트별 payload(docs/API.md):
///   group.created {name, defaultCurrency} → state.name/defaultCurrency
///   group.updated {name?, defaultCurrency?} → 있는 키만
///   member.added {memberId, name, userId|null} → 이미 있으면 그대로(멱등), 없으면 뒤에 추가
///   member.linked {memberId, userId}
///   member.removed {memberId}
///   expense.created {expenseId, description, amount, currency, fxRateToDefault, paidBy, date, category, shares}
///     → 이미 있으면 그대로(멱등), 없으면 뒤에 추가
///   expense.updated {expenseId, fields:{...}}   expense.deleted {expenseId}
///   payment.created {paymentId, fromMember, toMember, amount, currency, date}   payment.deleted {paymentId}
///   모르는 type → state 그대로.
GroupState applyEvent(GroupState state, SyncEvent event) {
  throw UnimplementedError('TODO(효준)');
}
