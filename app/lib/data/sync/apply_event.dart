import '../../domain/models.dart';
import 'event_types.dart';

/// 순수 함수: [state]에 [event]를 적용한 새 GroupState를 돌려준다. 입력은 바꾸지 않는다.
///
/// docs/API.md 적용 규칙 1~9 (shared/sync-cases.json이 검증). 이벤트는 seq 순서로 적용한다;
/// 필드 단위 LWW는 그 순서에서 자연히 성립하므로 적용기는 seq를 기억하지 않는다.
/// 1. 순수·멱등: 같은 이벤트를 두 번 적용해도 한 번 적용과 같다.
/// 2. 수정 vs 수정: 필드 단위로 seq 큰 쪽이 이긴다 (seq 순서대로 적용하면 자연히 성립. `expense.updated`의
///    payload.fields에 있는 키만 덮어쓴다. fields에 `shares`가 있으면 shares 전체를 교체).
/// 3. 삭제 vs 수정: deleted=true인 지출·송금에 오는 `updated`는 무시한다. 되살리는 것은 `expense.restored`뿐이고,
///    삭제된 동안 무시된 `updated`는 복원 뒤에도 돌아오지 않는다.
/// 4. 없는 대상에 오는 `updated`·`deleted`·`restored`·`linked`·`removed`·`confirmed`·`comment.deleted`는 무시한다.
/// 5. `member.removed`는 removed=true만 표시한다(목록에서 빼지 않는다).
/// 6. `payment.confirmed`는 status를 confirmed로 바꾼다. 없거나 삭제된 송금이면 무시.
/// 7. `expense.restored`는 deleted=false로 되돌린다(살아 있는 지출이면 그대로). 삭제·복원은 seq 순서상 나중 것이 이긴다.
/// 8. `comment.added`는 commentId가 처음일 때만 뒤에 추가한다(삭제된 댓글 포함, 있으면 무시).
///    `comment.deleted`는 deleted=true로 표시하고 text를 ''로 비운다. 지출 존재 여부는 보지 않는다(서버 검증).
/// 9. `expense.created`에 notes가 없으면 null. `expense.updated`에서 notes·category·fxRateToDefault의 null은 지우기,
///    나머지 키의 null은 무시.
///
/// 이벤트별 payload(docs/API.md):
///   group.created {name, defaultCurrency} → state.name/defaultCurrency
///   group.updated {name?, defaultCurrency?} → 있는 키만
///   member.added {memberId, name, userId|null} → 이미 있으면 그대로(멱등), 없으면 뒤에 추가
///   member.linked {memberId, userId}
///   member.removed {memberId}
///   expense.created {expenseId, description, amount, currency, fxRateToDefault, paidBy, date, category, notes?, shares}
///     → 이미 있으면 그대로(멱등), 없으면 뒤에 추가
///   expense.updated {expenseId, fields:{...}}   expense.deleted {expenseId}   expense.restored {expenseId}
///   comment.added {commentId, expenseId, authorMemberId, text, createdAt}   comment.deleted {commentId}
///   payment.created {paymentId, fromMember, toMember, amount, currency, date, status?}   payment.deleted {paymentId}
///   payment.confirmed {paymentId}
///   모르는 type → state 그대로.
/// Created entities always start live: a `deleted` key in the payload is ignored (like Kotlin; the server does not validate it).
GroupState applyEvent(GroupState s, SyncEvent e) {
  final p = e.payload;
  switch (e.type) {
    case EventTypes.groupCreated:
      return s.copyWith(name: p['name'] as String?, defaultCurrency: p['defaultCurrency'] as String?);
    case EventTypes.groupUpdated:
      return s.copyWith(name: p['name'] as String?, defaultCurrency: p['defaultCurrency'] as String?);
    case EventTypes.memberAdded:
      final id = p['memberId'] as String;
      if (s.member(id) != null) return s;
      return s.copyWith(members: [
        ...s.members,
        Member(id: id, name: p['name'] as String, userId: p['userId'] as String?),
      ]);
    case EventTypes.memberLinked:
      return _mapMember(s, p['memberId'] as String, (m) => m.copyWith(userId: p['userId'] as String?));
    case EventTypes.memberRemoved:
      return _mapMember(s, p['memberId'] as String, (m) => m.copyWith(removed: true));
    case EventTypes.expenseCreated:
      final id = p['expenseId'] as String;
      if (s.expense(id) != null) return s;
      return s.copyWith(expenses: [...s.expenses, Expense.fromJson({...p, 'id': id, 'deleted': false})]);
    case EventTypes.expenseUpdated:
      final f = (p['fields'] as Map).cast<String, dynamic>();
      return _mapExpense(s, p['expenseId'] as String, (x) {
        if (x.deleted) return x;
        return x.copyWith(
          description: f['description'] as String?,
          amount: (f['amount'] as num?)?.toInt(),
          currency: f['currency'] as String?,
          fxRateToDefault: (f['fxRateToDefault'] as num?)?.toDouble(),
          clearFx: f.containsKey('fxRateToDefault') && f['fxRateToDefault'] == null,
          paidBy: f['paidBy'] as String?,
          date: f['date'] as String?,
          category: f['category'] as String?,
          clearCategory: f.containsKey('category') && f['category'] == null,
          notes: f['notes'] as String?,
          clearNotes: f.containsKey('notes') && f['notes'] == null,
          shares: f['shares'] == null
              ? null
              : (f['shares'] as List).cast<Map<String, dynamic>>().map(Share.fromJson).toList(),
        );
      });
    case EventTypes.expenseDeleted:
      return _mapExpense(s, p['expenseId'] as String, (x) => x.copyWith(deleted: true));
    case EventTypes.expenseRestored:
      return _mapExpense(s, p['expenseId'] as String, (x) => x.copyWith(deleted: false));
    case EventTypes.commentAdded:
      final id = p['commentId'] as String;
      if (s.comment(id) != null) return s;
      return s.copyWith(comments: [...s.comments, Comment.fromJson({...p, 'id': id, 'deleted': false})]);
    case EventTypes.commentDeleted:
      final id = p['commentId'] as String;
      return s.copyWith(comments: [for (final c in s.comments) c.id == id ? c.copyWith(deleted: true, text: '') : c]);
    case EventTypes.paymentCreated:
      final id = p['paymentId'] as String;
      if (s.payment(id) != null) return s;
      return s.copyWith(payments: [...s.payments, Payment.fromJson({...p, 'id': id, 'deleted': false})]);
    case EventTypes.paymentDeleted:
      final id = p['paymentId'] as String;
      return s.copyWith(payments: [for (final x in s.payments) x.id == id ? x.copyWith(deleted: true) : x]);
    case EventTypes.paymentConfirmed:
      final id = p['paymentId'] as String;
      return s.copyWith(payments: [
        for (final x in s.payments) x.id == id && !x.deleted ? x.copyWith(status: 'confirmed') : x,
      ]);
    default:
      return s;
  }
}

GroupState _mapMember(GroupState s, String id, Member Function(Member) f) =>
    s.copyWith(members: [for (final m in s.members) m.id == id ? f(m) : m]);

GroupState _mapExpense(GroupState s, String id, Expense Function(Expense) f) =>
    s.copyWith(expenses: [for (final x in s.expenses) x.id == id ? f(x) : x]);
