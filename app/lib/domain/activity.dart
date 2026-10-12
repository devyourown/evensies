/// Activity feed items (docs/API.md 활동·알림) and their English sentences.
/// The server renders the same sentences for push (shared/activity-cases.json checks both).
library;

import '../core/money.dart';
import 'categories.dart';
import 'recurrence.dart' show frequencyWord;

class ActivityChange {
  final String field;
  final Object? from;
  final Object? to;
  const ActivityChange(this.field, this.from, this.to);
}

class ActivityItem {
  final String? groupId;
  final int? feedId;
  final int seq;
  final String kind;
  final String? createdAt;
  final String? actorMemberId, memberId, expenseId, commentId, paymentId;
  final String? name, description, currency, fromMember, toMember, status, text;

  /// Phase 8: the series (`recurrence_*`, or the expense's after the event) and its schedule (`expense_repeated`,
  /// `recurrence_*`).
  final String? recurrenceId, frequency;
  final int? amount, myDelta;
  /// `expense_added` of a refund.
  final bool refund;
  final List<ActivityChange> changes;

  /// The object as received, kept for the offline cache.
  final Map<String, dynamic> json;

  ActivityItem.fromJson(this.json)
      : groupId = json['groupId'] as String?,
        feedId = (json['feedId'] as num?)?.toInt(),
        seq = (json['seq'] as num).toInt(),
        kind = json['kind'] as String,
        createdAt = json['createdAt'] as String?,
        actorMemberId = json['actorMemberId'] as String?,
        memberId = json['memberId'] as String?,
        expenseId = json['expenseId'] as String?,
        commentId = json['commentId'] as String?,
        paymentId = json['paymentId'] as String?,
        name = json['name'] as String?,
        description = json['description'] as String?,
        currency = json['currency'] as String?,
        fromMember = json['fromMember'] as String?,
        toMember = json['toMember'] as String?,
        status = json['status'] as String?,
        text = json['text'] as String?,
        recurrenceId = json['recurrenceId'] as String?,
        frequency = json['frequency'] as String?,
        amount = (json['amount'] as num?)?.toInt(),
        myDelta = (json['myDelta'] as num?)?.toInt(),
        refund = json['refund'] == true,
        changes = [
          for (final c in ((json['changes'] as List?) ?? const []).cast<Map>())
            ActivityChange(c['field'] as String, c['from'], c['to']),
        ];
}

/// "you owe €15.00" / "you lent €15.00" ("you get back" for a refund) for an added (or repeated) expense I am part
/// of, else null.
String? myDeltaText(ActivityItem item) {
  final d = item.kind == 'expense_added' || item.kind == 'expense_repeated' ? item.myDelta ?? 0 : 0;
  if (d == 0) return null;
  return '${d < 0 ? 'you owe' : item.refund ? 'you get back' : 'you lent'} ${formatMoney(d.abs(), item.currency ?? '')}';
}

/// `category Dining out → General`, each side as [Categories.labelOf] shows a stored value; bare `category` when both
/// show the same (null → `uncategorized.general`).
String _category(Object? from, Object? to) {
  final f = Categories.labelOf(from?.toString()), t = Categories.labelOf(to?.toString());
  return f == t ? 'category' : 'category $f → $t';
}

/// The sentence for [item] as seen by member [me] (docs/API.md "문장"). [names] maps memberId → name.
/// [withDelta] false leaves out the trailing [myDeltaText] (the feed shows it as its own colored line). [count]: the
/// receipts one feed row stands for (app only: "added 3 receipts to …").
String activityText(ActivityItem item, Map<String, String> names, String? me, {bool withDelta = true, int count = 1}) {
  String who(String? id, {bool start = false}) {
    if (id != null && id == me) return start ? 'You' : 'you';
    return (id == null ? null : names[id]) ?? (start ? 'Someone' : 'someone');
  }

  String money(Object? minor, String? currency) => formatMoney((minor as num).toInt(), currency ?? '');
  final a = who(item.actorMemberId, start: true);
  final desc = '“${item.description ?? ''}”';
  final amount = item.amount == null ? '' : money(item.amount, item.currency);
  final receipts = count == 1 ? 'a receipt' : '$count receipts';
  final repeats = frequencyWord(item.frequency);

  /// `expense_updated`'s list of changes (also a series' future, `recurrence_updated`), joined with ", ".
  String changes() {
    final fields = {for (final c in item.changes) c.field: c};
    final fromCurrency = (fields['currency']?.from as String?) ?? item.currency;
    return [
      for (final c in item.changes)
        ?switch (c.field) {
          'description' => 'description “${c.from}” → “${c.to}”',
          'amount' => '${money(c.from, fromCurrency)} → ${money(c.to, item.currency)}',
          'currency' => 'currency ${c.from} → ${c.to}',
          'fxRateToDefault' => 'exchange rate',
          'paidBy' => 'paid by ${who(c.from as String?)} → ${who(c.to as String?)}',
          // The server already leaves out what rule 10 moved along (docs/API.md changes).
          'payers' => 'payers',
          'refund' => c.to == true ? 'refund on' : 'refund off',
          'date' => 'date ${c.from} → ${c.to}',
          'category' => _category(c.from, c.to),
          // A new amount always means a new split, so "split" alone would be noise.
          'shares' => fields.containsKey('amount') ? null : 'split',
          'split' => fields.containsKey('shares') || fields.containsKey('amount') ? null : 'split',
          'notes' => 'notes',
          _ => null,
        },
    ].join(', ');
  }

  switch (item.kind) {
    case 'group_created':
      return '$a created the group “${item.name ?? ''}”';
    case 'group_updated':
      final parts = [
        for (final c in item.changes)
          ?switch (c.field) {
            'name' => 'name “${c.from}” → “${c.to}”',
            'defaultCurrency' => 'currency ${c.from} → ${c.to}',
            'simplifyDebts' => c.to == true ? 'simplify debts on' : 'simplify debts off',
            'defaultSplit' => 'default split',
            _ => null,
          },
      ];
      return '$a changed the group: ${parts.join(', ')}';
    case 'member_added':
      return '$a added ${who(item.memberId)}';
    case 'member_joined':
      return '${who(item.memberId, start: true)} joined';
    case 'member_removed':
      return '$a removed ${who(item.memberId)}';
    case 'member_left':
      return '${who(item.memberId, start: true)} left the group';
    case 'friend_added':
      return '$a added ${who(item.memberId)} as a friend';
    case 'expense_added':
      final mine = withDelta ? myDeltaText(item) : null;
      return '$a added ${item.refund ? 'a refund ' : ''}$desc · $amount${mine == null ? '' : ' · $mine'}';
    case 'expense_updated':
      final parts = changes();
      return parts.isEmpty ? '$a changed $desc' : '$a changed $desc: $parts';
    case 'expense_repeated':
      // Added by the server on its date: no actor (docs/API.md 반복 지출).
      final mine = withDelta ? myDeltaText(item) : null;
      return '${item.refund ? 'A refund $desc' : desc} · $amount was added (repeats $repeats)'
          '${mine == null ? '' : ' · $mine'}';
    case 'recurrence_created':
      return '$a set $desc to repeat $repeats';
    case 'recurrence_updated':
      final parts = changes();
      return parts.isEmpty ? '$a changed future $desc' : '$a changed future $desc: $parts';
    case 'recurrence_deleted':
      return '$a stopped $desc repeating';
    case 'expense_deleted':
      return '$a deleted $desc';
    case 'expense_restored':
      return '$a restored $desc';
    case 'expense_moved':
      return '$a moved $desc to another group';
    case 'comment_added':
      if (item.paymentId != null) {
        return '$a commented on a payment of $amount from ${who(item.fromMember)} to ${who(item.toMember)}: '
            '${item.text ?? ''}';
      }
      return '$a commented on $desc: ${item.text ?? ''}';
    case 'payment_added':
      final waiting = item.status == 'sent' ? ' · waiting for ${who(item.toMember)} to confirm' : '';
      return '${who(item.fromMember, start: true)} paid ${who(item.toMember)} $amount$waiting';
    case 'payment_confirmed':
      return '$a confirmed receiving $amount from ${who(item.fromMember)}';
    case 'payment_deleted':
      return '$a deleted a payment of $amount from ${who(item.fromMember)} to ${who(item.toMember)}';
    case 'payment_edited':
      return '$a edited a payment of $amount from ${who(item.fromMember)} to ${who(item.toMember)}';
    case 'payment_restored':
      return '$a restored a payment of $amount from ${who(item.fromMember)} to ${who(item.toMember)}';
    case 'receipt_added':
      return '$a added $receipts to $desc';
    case 'receipt_removed':
      return '$a removed $receipts from $desc';
    default:
      return '$a made a change';
  }
}
