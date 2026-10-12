import '../../domain/models.dart';
import 'event_types.dart';

/// 순수 함수: [state]에 [event]를 적용한 새 GroupState를 돌려준다. 입력은 바꾸지 않는다.
///
/// docs/API.md 적용 규칙 1~18 (shared/sync-cases.json이 검증). 이벤트는 seq 순서로 적용한다;
/// 필드 단위 LWW는 그 순서에서 자연히 성립하므로 적용기는 seq를 기억하지 않는다.
/// 1. 순수·멱등: 같은 이벤트를 두 번 적용해도 한 번 적용과 같다.
/// 2. 수정 vs 수정: 필드 단위로 seq 큰 쪽이 이긴다 (seq 순서대로 적용하면 자연히 성립. `expense.updated`의
///    payload.fields에 있는 키만 덮어쓴다. fields에 `shares`가 있으면 shares 전체를 교체).
/// 3. 삭제 vs 수정: deleted=true인 지출·송금에 오는 `updated`는 무시한다. 되살리는 것은 `expense.restored`뿐이고,
///    삭제된 동안 무시된 `updated`는 복원 뒤에도 돌아오지 않는다.
/// 4. 없는 대상에 오는 `updated`·`deleted`·`restored`·`linked`·`removed`·`confirmed`·`comment.deleted`(Phase 8:
///    `recurrence.updated`·`recurrence.deleted` too)는 무시한다.
/// 5. `member.removed`는 removed=true만 표시한다(목록에서 빼지 않는다).
/// 6. `payment.confirmed`는 status를 confirmed로 바꾼다. 없거나 삭제된 송금이면 무시.
/// 7. `expense.restored`는 deleted=false로 되돌린다(살아 있는 지출이면 그대로). 삭제·복원은 seq 순서상 나중 것이 이긴다.
///    Phase 7: `payment.restored` does the same for a payment (status kept). `payment.deleted` with a string
///    `replacedBy` (an edit) also sets replaced (never cleared), and a replaced payment ignores `payment.restored`.
/// 8. `comment.added`는 commentId가 처음일 때만 뒤에 추가한다(삭제된 댓글 포함, 있으면 무시).
///    `comment.deleted`는 deleted=true로 표시하고 text를 ''로 비운다. 지출 존재 여부는 보지 않는다(서버 검증).
///    Phase 6: expenseId and paymentId are stored as sent (a payment comment has expenseId null).
/// 9. `expense.created`에 notes가 없으면 null. `expense.updated`에서 notes·category·fxRateToDefault의 null은 지우기,
///    나머지 키의 null은 무시. Phase 3: `split` is cleared by null too; a null `payers`/`refund` is ignored.
/// 10. Payers are the source of truth; paidBy is always re-derived as the primary payer (largest amount, a tie goes
///    to the lowest memberId; Expense.paidBy). created: missing/null payers → [{paidBy, amount}], refund → false,
///    split → null. updated payers: (a) fields.payers replaces them, (b) else fields.paidBy → [{paidBy, amount after
///    this update}], (c) else fields.amount with exactly one payer moves that payer to it, (d) else unchanged.
///    refund changes only to a boolean. split: the key's value if present (null clears), else null when shares or
///    amount is present (non-null), else unchanged.
/// 11. group.updated: absent keys stay, simplifyDebts takes a boolean, "defaultSplit": null clears it.
///    group.created leaves both at their defaults (true / null).
/// 12. Once the state has any expense or payment (deleted ones too) group.updated's defaultCurrency is ignored;
///    the event's other keys still apply.
/// 13. group.created sets kind ("group" when missing or not a string); nothing changes it afterwards (a `kind` in
///    group.updated is ignored). expense.deleted with a movedTo object also sets moved (never cleared), and
///    expense.restored on a moved expense is ignored: it counts in the other group now.
/// 14. Receipts: attachment.added appends {id, expenseId, deleted: false} unless the id is already there (a re-add
///    after a delete stays deleted) or the expense is unknown (a deleted expense still gets it). attachment.deleted
///    sets deleted on a known id and never reads its expenseId. Deleting or moving an expense keeps its receipts.
/// 15. Repeating series: recurrence.created appends {id, frequency, startDate, timeZone, template as sent, deleted:
///    false} unless the id is already there (stopped ones too). recurrence.updated on a known, live series replaces
///    each template key in fields with the value sent (null stored as null, lists whole, no rule-10 derivation);
///    recurrence.deleted sets deleted. Series events never change expenses.
/// 16. Expenses carry recurrenceId and occurrence (missing = null): expense.created reads them, expense.updated sets
///    each key it has (null clears). The applier never checks the series; delete, restore and move keep the tag.
/// 17. Group type, cover, deleted: group.created sets type (missing or not a string: "other"), a string type in
///    group.updated replaces it; a present coverImageId replaces the cover (null clears), a missing one keeps it.
///    group.deleted sets deleted and group.restored clears it (the later in seq order wins); neither touches members,
///    expenses or payments, and events after a delete apply as usual.
/// 18. Repeating series carry remindDaysBefore (missing = null): recurrence.created reads it, a recurrence.updated with
///    the key (a sibling of fields) sets it on a known, live series (null clears).
///
/// 이벤트별 payload(docs/API.md):
///   group.created {name, defaultCurrency, kind?, type?} → state.name/defaultCurrency/kind/type
///   group.updated {name?, defaultCurrency?, simplifyDebts?, defaultSplit?, type?, coverImageId?} → 있는 키만 (11, 12, 17)
///   group.deleted {}   group.restored {}
///   member.added {memberId, name, userId|null} → 이미 있으면 그대로(멱등), 없으면 뒤에 추가
///   member.linked {memberId, userId}
///   member.removed {memberId}
///   expense.created {expenseId, description, amount, currency, fxRateToDefault, paidBy, payers?, refund?, split?, date,
///     category, notes?, shares}
///     → 이미 있으면 그대로(멱등), 없으면 뒤에 추가
///   expense.updated {expenseId, fields:{...}}   expense.deleted {expenseId, movedTo?}   expense.restored {expenseId}
///   comment.added {commentId, expenseId?, paymentId?, authorMemberId, text, createdAt}   comment.deleted {commentId}
///   payment.created {paymentId, fromMember, toMember, amount, currency, date, status?}
///   payment.deleted {paymentId, replacedBy?}   payment.confirmed {paymentId}   payment.restored {paymentId}
///   attachment.added {attachmentId, expenseId}   attachment.deleted {attachmentId, expenseId?}
///   recurrence.created {recurrenceId, frequency, startDate, timeZone, template, remindDaysBefore?}
///   recurrence.updated {recurrenceId, fields, remindDaysBefore?}   recurrence.deleted {recurrenceId}
///   모르는 type → state 그대로.
/// Created entities always start live: a `deleted` key in the payload is ignored (like Kotlin; the server does not
/// validate it), and so are `moved` on an expense and `replaced` on a payment (only expense.deleted / payment.deleted
/// set those).
GroupState applyEvent(GroupState s, SyncEvent e) {
  final p = e.payload;
  switch (e.type) {
    case EventTypes.groupCreated:
      return s.copyWith(
        name: p['name'] as String?,
        defaultCurrency: p['defaultCurrency'] as String?,
        kind: p['kind'] is String ? p['kind'] as String : 'group',
        type: p['type'] is String ? p['type'] as String : 'other',
      );
    case EventTypes.groupUpdated:
      final locked = s.expenses.isNotEmpty || s.payments.isNotEmpty;
      return s.copyWith(
        name: p['name'] as String?,
        defaultCurrency: locked ? null : p['defaultCurrency'] as String?,
        simplifyDebts: p['simplifyDebts'] is bool ? p['simplifyDebts'] as bool : null,
        defaultSplit: SplitSpec.fromJson(p['defaultSplit']),
        clearDefaultSplit: p.containsKey('defaultSplit') && SplitSpec.fromJson(p['defaultSplit']) == null,
        type: p['type'] is String ? p['type'] as String : null,
        cover: p.containsKey('coverImageId') ? (p['coverImageId'] as String?,) : null,
      );
    case EventTypes.groupDeleted:
      return s.copyWith(deleted: true);
    case EventTypes.groupRestored:
      return s.copyWith(deleted: false);
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
      return s.copyWith(expenses: [...s.expenses, Expense.fromJson({...p, 'id': id, 'deleted': false, 'moved': false})]);
    case EventTypes.expenseUpdated:
      final f = (p['fields'] as Map).cast<String, dynamic>();
      List<Share>? list(Object? v) => (v as List?)?.cast<Map<String, dynamic>>().map(Share.fromJson).toList();
      return _mapExpense(s, p['expenseId'] as String, (x) {
        if (x.deleted) return x;
        final amount = (f['amount'] as num?)?.toInt() ?? x.amount;
        final paidBy = f['paidBy'] as String?;
        final payers = (f['payers'] is List && (f['payers'] as List).isNotEmpty ? list(f['payers']) : null) ??
            (paidBy != null
                ? [Share(memberId: paidBy, amount: amount)]
                : (f['amount'] != null && x.payers.length == 1)
                    ? [Share(memberId: x.payers.single.memberId, amount: amount)]
                    : null);
        final splitKey = f.containsKey('split');
        final clearSplit =
            splitKey ? SplitSpec.fromJson(f['split']) == null : (f['shares'] != null || f['amount'] != null);
        return x.copyWith(
          description: f['description'] as String?,
          amount: amount,
          currency: f['currency'] as String?,
          fxRateToDefault: (f['fxRateToDefault'] as num?)?.toDouble(),
          clearFx: f.containsKey('fxRateToDefault') && f['fxRateToDefault'] == null,
          payers: payers,
          date: f['date'] as String?,
          category: f['category'] as String?,
          clearCategory: f.containsKey('category') && f['category'] == null,
          notes: f['notes'] as String?,
          clearNotes: f.containsKey('notes') && f['notes'] == null,
          refund: f['refund'] is bool ? f['refund'] as bool : null,
          split: splitKey ? SplitSpec.fromJson(f['split']) : null,
          clearSplit: clearSplit,
          shares: list(f['shares']),
          // Rule 16: each key present is set, null clears it.
          recurrenceId: f.containsKey('recurrenceId') ? f['recurrenceId'] as String? : x.recurrenceId,
          occurrence: f.containsKey('occurrence') ? (f['occurrence'] as num?)?.toInt() : x.occurrence,
          clearRecurrence: true,
        );
      });
    case EventTypes.expenseDeleted:
      return _mapExpense(
          s, p['expenseId'] as String, (x) => x.copyWith(deleted: true, moved: x.moved || p['movedTo'] is Map));
    case EventTypes.expenseRestored:
      return _mapExpense(s, p['expenseId'] as String, (x) => x.moved ? x : x.copyWith(deleted: false));
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
      return s.copyWith(
          payments: [...s.payments, Payment.fromJson({...p, 'id': id, 'deleted': false, 'replaced': false})]);
    case EventTypes.paymentDeleted:
      final id = p['paymentId'] as String;
      return s.copyWith(payments: [
        for (final x in s.payments)
          x.id == id ? x.copyWith(deleted: true, replaced: x.replaced || p['replacedBy'] is String) : x,
      ]);
    case EventTypes.paymentRestored:
      final id = p['paymentId'] as String;
      return s.copyWith(payments: [for (final x in s.payments) x.id == id && !x.replaced ? x.copyWith(deleted: false) : x]);
    case EventTypes.attachmentAdded:
      final id = p['attachmentId'] as String, expenseId = p['expenseId'] as String;
      if (s.attachment(id) != null || s.expense(expenseId) == null) return s;
      return s.copyWith(attachments: [...s.attachments, Attachment(id: id, expenseId: expenseId)]);
    case EventTypes.attachmentDeleted:
      final id = p['attachmentId'] as String;
      return s.copyWith(attachments: [
        for (final a in s.attachments) a.id == id ? Attachment(id: a.id, expenseId: a.expenseId, deleted: true) : a,
      ]);
    case EventTypes.recurrenceCreated:
      final id = p['recurrenceId'] as String;
      if (s.recurrence(id) != null) return s;
      return s.copyWith(recurrences: [
        ...s.recurrences,
        Recurrence(
          id: id,
          frequency: p['frequency'] as String,
          startDate: p['startDate'] as String,
          timeZone: p['timeZone'] as String,
          template: (p['template'] as Map).cast<String, dynamic>(),
          remindDaysBefore: (p['remindDaysBefore'] as num?)?.toInt(),
        ),
      ]);
    case EventTypes.recurrenceUpdated:
      final id = p['recurrenceId'] as String;
      final f = (p['fields'] as Map).cast<String, dynamic>();
      final remind = p.containsKey('remindDaysBefore') ? ((p['remindDaysBefore'] as num?)?.toInt(),) : null;
      return s.copyWith(recurrences: [
        for (final r in s.recurrences)
          r.id == id && !r.deleted ? r.copyWith(template: {...r.template, ...f}, remind: remind) : r,
      ]);
    case EventTypes.recurrenceDeleted:
      final id = p['recurrenceId'] as String;
      return s.copyWith(recurrences: [for (final r in s.recurrences) r.id == id ? r.copyWith(deleted: true) : r]);
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
