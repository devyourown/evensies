/// Activity feed items (docs/API.md 활동·알림) and their sentences in each language (shared/strings.json).
/// The server renders the same sentences for push (shared/activity-cases.json checks both).
library;

import '../core/money.dart';
import '../core/strings.dart';
import 'categories.dart';

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

/// The delta phrase for an added (or repeated) expense I am part of, else null: "you owe €15.00" / "you lent
/// €15.00" ("you get back" for a refund), in [lang] (default [Money.lang]).
String? myDeltaText(ActivityItem item, {String? lang}) {
  final l = lang ?? Money.lang;
  final d = item.kind == 'expense_added' || item.kind == 'expense_repeated' ? item.myDelta ?? 0 : 0;
  if (d == 0) return null;
  final key = d < 0 ? 'owe' : (item.refund ? 'getBack' : 'lent');
  return Strings.fill(Strings.text(l, ['suffix', key]), {'amount': formatMoney(d.abs(), item.currency ?? '', lang: l)});
}

/// Template key per kind (docs/API.md 문장 만들기 1): refunds, payment comments, several receipts and a friend group's
/// delete/restore ([friend]: `friend_deleted`, `friend_restored`, its name is internal) have their own.
String _templateKey(ActivityItem item, int count, bool friend) {
  final k = switch (item.kind) {
    'expense_added' || 'expense_repeated' when item.refund => '${item.kind}_refund',
    'comment_added' when item.paymentId != null => 'comment_added_payment',
    'group_deleted' || 'group_restored' when friend => item.kind.replaceFirst('group_', 'friend_'),
    'receipt_added' || 'receipt_removed' when count >= 2 => item.kind.replaceFirst('receipt_', 'receipts_'),
    _ => item.kind,
  };
  return Strings.lookup('en', ['activity', k, 'other']) == null ? 'unknown' : k;
}

/// The sentence for [item] as seen by member [me] in [lang] (docs/API.md 문장 만들기), from shared/strings.json.
/// [names] maps memberId → name. [withDelta] false leaves out the trailing [myDeltaText] (the feed shows it as its own
/// colored line). [count]: the receipts one feed row stands for (app only: "added 3 receipts to …"). [friend]: the item's
/// group is a friend group.
String activityText(ActivityItem item, Map<String, String> names, String? me,
    {bool withDelta = true, int count = 1, String? lang, bool friend = false}) {
  final l = lang ?? Money.lang;
  final you = Strings.text(l, const ['words', 'you']), someone = Strings.text(l, const ['words', 'someone']);
  final cap = <String>{};

  /// A member as the sentence names them, noting [slot] as capitalizable when the value is a word, not a name.
  String who(String? id, [String? slot]) {
    final n = id == null ? null : (id == me ? you : names[id] ?? someone);
    if (slot != null && (n == null || id == me || !names.containsKey(id))) cap.add(slot);
    return n ?? someone;
  }

  String money(Object? minor, String? currency) => formatMoney((minor as num).toInt(), currency ?? '', lang: l);
  String change(String key, [Map<String, String> v = const {}]) => Strings.fill(Strings.text(l, ['changes', key]), v);

  /// `{changes}`: the labels in order joined with `changes.joiner`; `changes.other` once for unknown fields, and for
  /// an empty list.
  String changes() {
    final fields = {for (final c in item.changes) c.field: c};
    final fromCurrency = (fields['currency']?.from as String?) ?? item.currency;
    var other = false;
    final parts = <String>[];
    for (final c in item.changes) {
      final f = '${c.from}', t = '${c.to}';
      final label = switch ((item.kind, c.field)) {
        ('group_updated', 'name') => change('name', {'from': f, 'to': t}),
        ('group_updated', 'defaultCurrency') => change('currency', {'from': f, 'to': t}),
        ('group_updated', 'simplifyDebts') => change(c.to == true ? 'simplifyDebtsOn' : 'simplifyDebtsOff'),
        ('group_updated', 'defaultSplit') => change('defaultSplit'),
        // Phase 10: an unknown type reads as Other, like the app shows it.
        ('group_updated', 'type') => change('type', {'to': _groupType(c.to, l)}),
        ('group_updated', 'coverImageId') => change('coverImageId'),
        ('group_updated', _) => '',
        (_, 'description') => change('description', {'from': f, 'to': t}),
        (_, 'amount') => change('amount', {'from': money(c.from, fromCurrency), 'to': money(c.to, item.currency)}),
        (_, 'currency') => change('currency', {'from': f, 'to': t}),
        (_, 'fxRateToDefault') => change('fxRateToDefault'),
        (_, 'paidBy') => change('paidBy', {'from': who(c.from as String?), 'to': who(c.to as String?)}),
        // The server already leaves out what rule 10 moved along (docs/API.md changes).
        (_, 'payers') => change('payers'),
        (_, 'refund') => change(c.to == true ? 'refundOn' : 'refundOff'),
        (_, 'date') => change('date', {'from': f, 'to': t}),
        (_, 'category') => _category(c.from, c.to, l, change),
        // A new amount always means a new split, so "split" alone would be noise.
        (_, 'shares') => fields.containsKey('amount') ? null : change('split'),
        (_, 'split') => fields.containsKey('shares') || fields.containsKey('amount') ? null : change('split'),
        (_, 'notes') => change('notes'),
        _ => '',
      };
      if (label == '') {
        other = true;
      } else if (label != null) {
        parts.add(label);
      }
    }
    if (other || parts.isEmpty) parts.add(change('other'));
    return parts.join(Strings.text(l, const ['changes', 'joiner']));
  }

  final key = _templateKey(item, count, friend);
  final subject = switch (item.kind) {
    'member_joined' || 'member_left' => item.memberId,
    'payment_added' => item.fromMember,
    _ => item.actorMemberId,
  };
  final object = switch (item.kind) {
    'member_added' || 'member_removed' || 'friend_added' => item.memberId,
    'payment_added' => item.toMember,
    'payment_confirmed' => item.fromMember,
    _ => null,
  };
  bool has(String variant) => Strings.lookup('en', ['activity', key, variant]) != null;
  final variant = me != null && subject == me && has('self')
      ? 'self'
      : me != null && object == me && has('you')
          ? 'you'
          : 'other';
  final template = Strings.text(l, ['activity', key, variant]);
  final usesChanges = template.contains('{changes}');
  var text = Strings.fill(
    template,
    {
      'A': who(item.actorMemberId, 'A'),
      'member': who(item.memberId, 'member'),
      'from': who(item.fromMember, 'from'),
      'to': who(item.toMember, 'to'),
      'name': item.name ?? '',
      'description': item.description ?? '',
      'text': item.text ?? '',
      'amount': item.amount == null ? '' : money(item.amount, item.currency),
      'frequency': Strings.lookup(l, ['words', 'frequency', item.frequency ?? '']) as String? ?? item.frequency ?? '',
      if (usesChanges) 'changes': changes(),
      'n': '$count',
    },
    capitalize: cap,
  );
  final dot = Strings.text(l, const ['words', 'dot']);
  final mine = withDelta ? myDeltaText(item, lang: l) : null;
  if (mine != null) text = '$text$dot$mine';
  if (item.kind == 'payment_added' && item.status == 'sent') {
    final w = Strings.text(l, ['suffix', 'waiting', me != null && item.toMember == me ? 'you' : 'other']);
    text = '$text$dot${Strings.fill(w, {'to': who(item.toMember)})}';
  }
  return text;
}

/// `category Dining out → General`, each side as [Categories.labelOf] shows a stored value; bare `category` when both
/// show the same (null → `uncategorized.general`).
String _category(Object? from, Object? to, String lang, String Function(String, [Map<String, String>]) change) {
  final f = Categories.labelOf(from?.toString(), lang: lang), t = Categories.labelOf(to?.toString(), lang: lang);
  return f == t ? change('categorySame') : change('category', {'from': f, 'to': t});
}

/// `words.groupType`: Trip / Home / Couple / Other.
String _groupType(Object? type, String lang) =>
    Strings.lookup(lang, ['words', 'groupType', '$type']) as String? ?? Strings.text(lang, const ['words', 'groupType', 'other']);
