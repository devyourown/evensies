/// Activity feed items (docs/API.md 활동·알림) and their English sentences.
/// The server renders the same sentences for push (shared/activity-cases.json checks both).
library;

import '../core/money.dart';

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
        amount = (json['amount'] as num?)?.toInt(),
        myDelta = (json['myDelta'] as num?)?.toInt(),
        refund = json['refund'] == true,
        changes = [
          for (final c in ((json['changes'] as List?) ?? const []).cast<Map>())
            ActivityChange(c['field'] as String, c['from'], c['to']),
        ];
}

/// "you owe €15.00" / "you lent €15.00" ("you get back" for a refund) for an added expense I am part of, else null.
String? myDeltaText(ActivityItem item) {
  final d = item.kind == 'expense_added' ? item.myDelta ?? 0 : 0;
  if (d == 0) return null;
  return '${d < 0 ? 'you owe' : item.refund ? 'you get back' : 'you lent'} ${formatMoney(d.abs(), item.currency ?? '')}';
}

/// The sentence for [item] as seen by member [me] (docs/API.md "문장"). [names] maps memberId → name.
/// [withDelta] false leaves out the trailing [myDeltaText] (the feed shows it as its own colored line).
String activityText(ActivityItem item, Map<String, String> names, String? me, {bool withDelta = true}) {
  String who(String? id, {bool start = false}) {
    if (id != null && id == me) return start ? 'You' : 'you';
    return (id == null ? null : names[id]) ?? (start ? 'Someone' : 'someone');
  }

  String money(Object? minor, String? currency) => formatMoney((minor as num).toInt(), currency ?? '');
  final a = who(item.actorMemberId, start: true);
  final desc = '“${item.description ?? ''}”';
  final amount = item.amount == null ? '' : money(item.amount, item.currency);

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
    case 'expense_added':
      final mine = withDelta ? myDeltaText(item) : null;
      return '$a added ${item.refund ? 'a refund ' : ''}$desc · $amount${mine == null ? '' : ' · $mine'}';
    case 'expense_updated':
      final fields = {for (final c in item.changes) c.field: c};
      final fromCurrency = (fields['currency']?.from as String?) ?? item.currency;
      final parts = [
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
            'category' => 'category',
            // A new amount always means a new split, so "split" alone would be noise.
            'shares' => fields.containsKey('amount') ? null : 'split',
            'split' => fields.containsKey('shares') || fields.containsKey('amount') ? null : 'split',
            'notes' => 'notes',
            _ => null,
          },
      ];
      return parts.isEmpty ? '$a changed $desc' : '$a changed $desc: ${parts.join(', ')}';
    case 'expense_deleted':
      return '$a deleted $desc';
    case 'expense_restored':
      return '$a restored $desc';
    case 'comment_added':
      return '$a commented on $desc: ${item.text ?? ''}';
    case 'payment_added':
      final waiting = item.status == 'sent' ? ' · waiting for ${who(item.toMember)} to confirm' : '';
      return '${who(item.fromMember, start: true)} paid ${who(item.toMember)} $amount$waiting';
    case 'payment_confirmed':
      return '$a confirmed receiving $amount from ${who(item.fromMember)}';
    case 'payment_deleted':
      return '$a deleted a payment of $amount from ${who(item.fromMember)} to ${who(item.toMember)}';
    default:
      return '$a made a change';
  }
}
