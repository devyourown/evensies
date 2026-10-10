// =============================================================================
// REFERENCE IMPLEMENTATION — NOT THE REAL ONE.
//
// Used only when the app is run with `--dart-define=NAIVE_APPLY=true` so the
// app can be exercised end-to-end while `apply_event.dart` is still TODO(효준).
// 효준: your `applyEvent` passes test/hyojun/apply_event_test.dart → DELETE this
// file (and the NAIVE_APPLY branch in sync_service.dart / expense_form).
// =============================================================================
import '../../domain/models.dart';
import '../../domain/split.dart';
import 'event_types.dart';

GroupState applyEventNaive(GroupState s, SyncEvent e) {
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
      return s.copyWith(expenses: [...s.expenses, Expense.fromJson({...p, 'id': id})]);
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
          shares: f['shares'] == null
              ? null
              : (f['shares'] as List).cast<Map<String, dynamic>>().map(Share.fromJson).toList(),
        );
      });
    case EventTypes.expenseDeleted:
      return _mapExpense(s, p['expenseId'] as String, (x) => x.copyWith(deleted: true));
    case EventTypes.paymentCreated:
      final id = p['paymentId'] as String;
      if (s.payment(id) != null) return s;
      return s.copyWith(payments: [...s.payments, Payment.fromJson({...p, 'id': id})]);
    case EventTypes.paymentDeleted:
      final id = p['paymentId'] as String;
      return s.copyWith(payments: [for (final x in s.payments) x.id == id ? x.copyWith(deleted: true) : x]);
    default:
      return s;
  }
}

GroupState _mapMember(GroupState s, String id, Member Function(Member) f) =>
    s.copyWith(members: [for (final m in s.members) m.id == id ? f(m) : m]);

GroupState _mapExpense(GroupState s, String id, Expense Function(Expense) f) =>
    s.copyWith(expenses: [for (final x in s.expenses) x.id == id ? f(x) : x]);

/// Trivial split used by the expense form only under NAIVE_APPLY while computeSplit is TODO(효준).
Map<String, int> naiveSplit({
  required int amount,
  required SplitMode mode,
  required List<String> members,
  Map<String, double>? input,
}) {
  final sorted = [...members]..sort();
  if (mode == SplitMode.exact) return {for (final m in sorted) m: (input?[m] ?? 0).round()};
  final out = <String, int>{
    for (final m in sorted)
      m: mode == SplitMode.percent ? (amount * (input?[m] ?? 0) / 100).floor() : amount ~/ sorted.length,
  };
  var rem = amount - out.values.fold(0, (a, b) => a + b);
  for (final m in sorted) {
    if (rem-- <= 0) break;
    out[m] = out[m]! + 1;
  }
  return out;
}
