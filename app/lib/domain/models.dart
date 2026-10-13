/// In-memory group state, shape mirrors `GET /groups/{id}/snapshot` (docs/API.md).
library;

import 'package:flutter/foundation.dart' show mapEquals;

import 'itemized.dart';
import 'split.dart';

class Member {
  final String id;
  final String name;
  final String? userId;
  final bool removed;
  const Member({required this.id, required this.name, this.userId, this.removed = false});

  Member copyWith({String? name, String? userId, bool clearUserId = false, bool? removed}) => Member(
        id: id,
        name: name ?? this.name,
        userId: clearUserId ? null : (userId ?? this.userId),
        removed: removed ?? this.removed,
      );

  factory Member.fromJson(Map<String, dynamic> j) => Member(
        id: j['id'] as String,
        name: j['name'] as String,
        userId: j['userId'] as String?,
        removed: j['removed'] as bool? ?? false,
      );
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'userId': userId, 'removed': removed};
}

class Share {
  final String memberId;
  final int amount;
  const Share({required this.memberId, required this.amount});
  factory Share.fromJson(Map<String, dynamic> j) =>
      Share(memberId: j['memberId'] as String, amount: (j['amount'] as num).toInt());
  Map<String, dynamic> toJson() => {'memberId': memberId, 'amount': amount};
}

/// How an expense was split, so the editor reopens it the same way (docs/API.md "SplitSpec").
/// A hint only: `Expense.shares` holds the amounts. An exact split has no SplitSpec.
class SplitSpec {
  /// Null for itemized: computeSplit has no such mode, the [bill] holds the items instead (docs/API.md, Itemized split).
  final SplitMode? mode;

  /// percent: percent, shares: share count, adjustment: minor units. Null for equal and itemized.
  final Map<String, double>? input;

  /// The receipt lines of an itemized split (Phase 7).
  final ItemizedBill? bill;
  const SplitSpec(SplitMode this.mode, [this.input]) : bill = null;
  const SplitSpec.itemized(ItemizedBill this.bill)
      : mode = null,
        input = null;

  bool get itemized => bill != null;

  static const _modes = {SplitMode.equal, SplitMode.percent, SplitMode.shares, SplitMode.adjustment};

  /// Null for anything this app can't use: not an object, an unknown mode, bad input or a bad bill.
  static SplitSpec? fromJson(Object? j) {
    if (j is! Map) return null;
    if (j['mode'] == 'itemized') {
      if (j['input'] != null) return null;
      final bill = ItemizedBill.fromJson(j['bill']);
      return bill == null ? null : SplitSpec.itemized(bill);
    }
    final mode = SplitMode.values.where((m) => m.name == j['mode'] && _modes.contains(m)).firstOrNull;
    if (mode == null) return null;
    final raw = j['input'];
    if (raw is! Map) return mode == SplitMode.equal ? const SplitSpec(SplitMode.equal) : null;
    final input = <String, double>{};
    for (final e in raw.entries) {
      if (e.key is! String || e.value is! num) return null;
      input[e.key as String] = (e.value as num).toDouble();
    }
    return SplitSpec(mode, mode == SplitMode.equal ? null : input);
  }

  Map<String, dynamic> toJson() => bill != null
      ? {'mode': 'itemized', 'bill': bill!.toJson()}
      : {'mode': mode!.name, if (input != null) 'input': input};

  /// Same mode and numbers (a member missing from [input] counts as 0, docs/API.md SplitSpec), or the same bill.
  @override
  bool operator ==(Object other) =>
      other is SplitSpec &&
      other.mode == mode &&
      other.bill == bill &&
      mapEquals(_nonZero(other.input), _nonZero(input));
  @override
  int get hashCode => Object.hash(mode, bill);

  static Map<String, double> _nonZero(Map<String, double>? m) => {
        for (final e in (m ?? const <String, double>{}).entries)
          if (e.value != 0) e.key: e.value
      };
}

/// Primary payer (docs/API.md rule 10): the largest amount; on a tie the lowest memberId.
String primaryPayer(List<Share> payers) => payers
    .reduce((a, b) => b.amount > a.amount || (b.amount == a.amount && b.memberId.compareTo(a.memberId) < 0) ? b : a)
    .memberId;

class Expense {
  final String id;
  final String description;
  final int amount;
  final String currency;
  final double? fxRateToDefault;

  /// Who paid how much, in the order sent; sums to [amount]. For a refund: who received the money.
  final List<Share> payers;
  final String date; // YYYY-MM-DD
  final String? category;
  final String? notes;
  final bool deleted;

  /// Money that came back (e.g. a hotel refund): reverses the effect on balances.
  final bool refund;
  final SplitSpec? split;
  final List<Share> shares;

  /// Deleted by a move (`expense.deleted` with `movedTo`): it counts in the other group, so it stays deleted (rule 13).
  final bool moved;

  /// The repeating series this expense belongs to and its number in it (0 = the first, added by a person; 1, 2, …
  /// added by the server). Both null outside a series (docs/API.md, Recurring expenses; rule 16).
  final String? recurrenceId;
  final int? occurrence;

  /// Pass [payers], or [paidBy] alone for a single payer of the whole [amount].
  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.currency,
    this.fxRateToDefault,
    String? paidBy,
    List<Share>? payers,
    required this.date,
    this.category,
    this.notes,
    this.deleted = false,
    this.refund = false,
    this.split,
    required this.shares,
    this.moved = false,
    this.recurrenceId,
    this.occurrence,
  }) : payers = payers ?? [Share(memberId: paidBy!, amount: amount)];

  String get paidBy => primaryPayer(payers);

  Expense copyWith({
    String? description,
    int? amount,
    String? currency,
    double? fxRateToDefault,
    bool clearFx = false,
    List<Share>? payers,
    String? date,
    String? category,
    bool clearCategory = false,
    String? notes,
    bool clearNotes = false,
    bool? deleted,
    bool? refund,
    SplitSpec? split,
    bool clearSplit = false,
    List<Share>? shares,
    bool? moved,
    String? recurrenceId,
    int? occurrence,
    bool clearRecurrence = false,
  }) =>
      Expense(
        id: id,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        fxRateToDefault: clearFx ? null : (fxRateToDefault ?? this.fxRateToDefault),
        payers: payers ?? this.payers,
        date: date ?? this.date,
        category: clearCategory ? null : (category ?? this.category),
        notes: clearNotes ? null : (notes ?? this.notes),
        deleted: deleted ?? this.deleted,
        refund: refund ?? this.refund,
        split: clearSplit ? null : (split ?? this.split),
        shares: shares ?? this.shares,
        moved: moved ?? this.moved,
        // clearRecurrence: exactly the given pair, nulls included.
        recurrenceId: clearRecurrence ? recurrenceId : (recurrenceId ?? this.recurrenceId),
        occurrence: clearRecurrence ? occurrence : (occurrence ?? this.occurrence),
      );

  /// Missing `payers` = `[{paidBy, amount}]`, `refund` = false, `split` = null (events and snapshots before Phase 3).
  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] as String,
        description: j['description'] as String,
        amount: (j['amount'] as num).toInt(),
        currency: j['currency'] as String,
        fxRateToDefault: (j['fxRateToDefault'] as num?)?.toDouble(),
        paidBy: j['paidBy'] as String?,
        // Empty is never valid (the server refuses it); read it like a missing key rather than crash on paidBy.
        payers: switch (j['payers']) {
          final List l when l.isNotEmpty => l.cast<Map<String, dynamic>>().map(Share.fromJson).toList(),
          _ => null,
        },
        date: j['date'] as String,
        category: j['category'] as String?,
        notes: j['notes'] as String?,
        deleted: j['deleted'] as bool? ?? false,
        refund: j['refund'] == true,
        split: SplitSpec.fromJson(j['split']),
        shares: (j['shares'] as List).cast<Map<String, dynamic>>().map(Share.fromJson).toList(),
        moved: j['moved'] == true,
        recurrenceId: j['recurrenceId'] as String?,
        occurrence: (j['occurrence'] as num?)?.toInt(),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'currency': currency,
        'fxRateToDefault': fxRateToDefault,
        'paidBy': paidBy,
        'payers': payers.map((s) => s.toJson()).toList(),
        'refund': refund,
        'split': split?.toJson(),
        'date': date,
        'category': category,
        'notes': notes,
        'deleted': deleted,
        'shares': shares.map((s) => s.toJson()).toList(),
        'moved': moved,
        'recurrenceId': recurrenceId,
        'occurrence': occurrence,
      };
}

class Payment {
  final String id;
  final String fromMember;
  final String toMember;
  final int amount;
  final String currency;
  final String date;
  final bool deleted;
  /// 'sent' (waiting for the receiver to confirm) or 'confirmed'. Missing in JSON = confirmed.
  final String status;

  /// Deleted by an edit (`payment.deleted` with `replacedBy`): the new payment counts, so it stays deleted (rule 7).
  final bool replaced;
  const Payment({
    required this.id,
    required this.fromMember,
    required this.toMember,
    required this.amount,
    required this.currency,
    required this.date,
    this.deleted = false,
    this.status = 'confirmed',
    this.replaced = false,
  });
  bool get pending => status == 'sent';
  Payment copyWith({bool? deleted, String? status, bool? replaced}) => Payment(
        id: id,
        fromMember: fromMember,
        toMember: toMember,
        amount: amount,
        currency: currency,
        date: date,
        deleted: deleted ?? this.deleted,
        status: status ?? this.status,
        replaced: replaced ?? this.replaced,
      );
  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: j['id'] as String,
        fromMember: j['fromMember'] as String,
        toMember: j['toMember'] as String,
        amount: (j['amount'] as num).toInt(),
        currency: j['currency'] as String,
        date: j['date'] as String,
        deleted: j['deleted'] as bool? ?? false,
        status: j['status'] as String? ?? 'confirmed',
        replaced: j['replaced'] == true,
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'fromMember': fromMember,
        'toMember': toMember,
        'amount': amount,
        'currency': currency,
        'date': date,
        'deleted': deleted,
        'status': status,
        'replaced': replaced,
      };
}

class Comment {
  final String id;

  /// Exactly one of [expenseId] and [paymentId] is set (docs/API.md `comment.added`, Phase 6 payment comments).
  final String? expenseId;
  final String? paymentId;
  final String authorMemberId;
  final String text;
  final String createdAt; // ISO-8601 UTC
  final bool deleted;
  const Comment({
    required this.id,
    this.expenseId,
    this.paymentId,
    required this.authorMemberId,
    required this.text,
    required this.createdAt,
    this.deleted = false,
  });
  Comment copyWith({bool? deleted, String? text}) => Comment(
        id: id,
        expenseId: expenseId,
        paymentId: paymentId,
        authorMemberId: authorMemberId,
        text: text ?? this.text,
        createdAt: createdAt,
        deleted: deleted ?? this.deleted,
      );

  /// Stored as sent (rule 8): a missing key is null.
  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
        id: j['id'] as String,
        expenseId: j['expenseId'] as String?,
        paymentId: j['paymentId'] as String?,
        authorMemberId: j['authorMemberId'] as String,
        text: j['text'] as String,
        createdAt: j['createdAt'] as String,
        deleted: j['deleted'] as bool? ?? false,
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'expenseId': expenseId,
        'paymentId': paymentId,
        'authorMemberId': authorMemberId,
        'text': text,
        'createdAt': createdAt,
        'deleted': deleted,
      };
}

/// A receipt photo on an expense (docs/API.md, Receipts; rule 14); the files live on the server and in this device's cache.
class Attachment {
  final String id;
  final String expenseId;
  final bool deleted;
  const Attachment({required this.id, required this.expenseId, this.deleted = false});
  factory Attachment.fromJson(Map<String, dynamic> j) => Attachment(
      id: j['id'] as String, expenseId: j['expenseId'] as String, deleted: j['deleted'] as bool? ?? false);
  Map<String, dynamic> toJson() => {'id': id, 'expenseId': expenseId, 'deleted': deleted};
}

/// A repeating expense (docs/API.md, Recurring expenses; rule 15): the server adds [template] as a new expense on each date of
/// the schedule. [template] is the `expense.created` payload without expenseId, date, recurrenceId and occurrence.
class Recurrence {
  final String id;

  /// `weekly`, `biweekly`, `monthly` or `yearly`.
  final String frequency;
  final String startDate; // YYYY-MM-DD, occurrence 0
  final String timeZone;
  final Map<String, dynamic> template;

  /// Stopped: no more repeats (there is no restart).
  final bool deleted;

  /// Days before each repeat that the server emails a reminder (1–7), or null for none (docs/API.md rule 18).
  final int? remindDaysBefore;
  const Recurrence({
    required this.id,
    required this.frequency,
    required this.startDate,
    required this.timeZone,
    required this.template,
    this.deleted = false,
    this.remindDaysBefore,
  });

  /// [remind] replaces remindDaysBefore when given (`(null,)` clears it).
  Recurrence copyWith({Map<String, dynamic>? template, bool? deleted, (int?,)? remind}) => Recurrence(
        id: id,
        frequency: frequency,
        startDate: startDate,
        timeZone: timeZone,
        template: template ?? this.template,
        deleted: deleted ?? this.deleted,
        remindDaysBefore: remind == null ? remindDaysBefore : remind.$1,
      );

  /// The template's description ("Rent"), or null when it has none.
  String? get description => template['description'] as String?;

  factory Recurrence.fromJson(Map<String, dynamic> j) => Recurrence(
        id: j['id'] as String,
        frequency: j['frequency'] as String,
        startDate: j['startDate'] as String,
        timeZone: j['timeZone'] as String,
        template: (j['template'] as Map).cast<String, dynamic>(),
        deleted: j['deleted'] as bool? ?? false,
        remindDaysBefore: (j['remindDaysBefore'] as num?)?.toInt(),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'frequency': frequency,
        'startDate': startDate,
        'timeZone': timeZone,
        'template': template,
        'deleted': deleted,
        'remindDaysBefore': remindDaysBefore,
      };
}

/// Immutable. Lists keep insertion order (same as the server snapshot).
class GroupState {
  final String? name;
  final String? defaultCurrency;

  /// `group` or `friend` (a hidden two-person group, Phase 6). Set by group.created only (rule 13).
  final String kind;

  /// Group settings (docs/API.md rule 11).
  final bool simplifyDebts;
  final SplitSpec? defaultSplit;

  /// Phase 10 (rule 17): `trip`, `home`, `couple` or `other` as sent (the app shows an unknown one as Other), the
  /// current cover photo id, and whether a member deleted the group (deleted for everyone, any member restores it).
  final String type;
  final String? coverImageId;
  final bool deleted;
  final List<Member> members;
  final List<Expense> expenses;
  final List<Payment> payments;
  final List<Comment> comments;

  /// Receipts in attach order, deleted ones included (rule 14).
  final List<Attachment> attachments;

  /// Repeating series in creation order, stopped ones included (rule 15).
  final List<Recurrence> recurrences;
  const GroupState({
    this.name,
    this.defaultCurrency,
    this.kind = 'group',
    this.simplifyDebts = true,
    this.defaultSplit,
    this.type = 'other',
    this.coverImageId,
    this.deleted = false,
    this.members = const [],
    this.expenses = const [],
    this.payments = const [],
    this.comments = const [],
    this.attachments = const [],
    this.recurrences = const [],
  });

  static const empty = GroupState();

  GroupState copyWith({
    String? name,
    String? defaultCurrency,
    String? kind,
    bool? simplifyDebts,
    SplitSpec? defaultSplit,
    bool clearDefaultSplit = false,
    String? type,
    (String?,)? cover,
    bool? deleted,
    List<Member>? members,
    List<Expense>? expenses,
    List<Payment>? payments,
    List<Comment>? comments,
    List<Attachment>? attachments,
    List<Recurrence>? recurrences,
  }) =>
      GroupState(
        name: name ?? this.name,
        defaultCurrency: defaultCurrency ?? this.defaultCurrency,
        kind: kind ?? this.kind,
        simplifyDebts: simplifyDebts ?? this.simplifyDebts,
        defaultSplit: clearDefaultSplit ? null : (defaultSplit ?? this.defaultSplit),
        type: type ?? this.type,
        coverImageId: cover == null ? coverImageId : cover.$1,
        deleted: deleted ?? this.deleted,
        members: members ?? this.members,
        expenses: expenses ?? this.expenses,
        payments: payments ?? this.payments,
        comments: comments ?? this.comments,
        attachments: attachments ?? this.attachments,
        recurrences: recurrences ?? this.recurrences,
      );

  Member? member(String id) => members.where((m) => m.id == id).firstOrNull;
  Expense? expense(String id) => expenses.where((e) => e.id == id).firstOrNull;
  Payment? payment(String id) => payments.where((p) => p.id == id).firstOrNull;
  Comment? comment(String id) => comments.where((c) => c.id == id).firstOrNull;
  Attachment? attachment(String id) => attachments.where((a) => a.id == id).firstOrNull;
  Recurrence? recurrence(String id) => recurrences.where((r) => r.id == id).firstOrNull;

  /// [expenseId]'s receipts that aren't deleted, in attach order.
  List<Attachment> receiptsOf(String expenseId) =>
      [for (final a in attachments) if (a.expenseId == expenseId && !a.deleted) a];
  bool get isFriend => kind == 'friend';

  /// Parses a snapshot or a sync-cases `expected` (its `group` is optional there).
  factory GroupState.fromJson(Map<String, dynamic> j) {
    final g = (j['group'] as Map?) ?? const {};
    return GroupState(
      name: g['name'] as String?,
      defaultCurrency: g['defaultCurrency'] as String?,
      kind: g['kind'] as String? ?? 'group',
      simplifyDebts: g['simplifyDebts'] as bool? ?? true,
      defaultSplit: SplitSpec.fromJson(g['defaultSplit']),
      // Missing before Phase 10 and in older sync-cases `expected`.
      type: g['type'] as String? ?? 'other',
      coverImageId: g['coverImageId'] as String?,
      deleted: g['deleted'] as bool? ?? false,
      members: (j['members'] as List).cast<Map<String, dynamic>>().map(Member.fromJson).toList(),
      expenses: (j['expenses'] as List).cast<Map<String, dynamic>>().map(Expense.fromJson).toList(),
      payments: (j['payments'] as List).cast<Map<String, dynamic>>().map(Payment.fromJson).toList(),
      // Missing in sync-cases `expected` and in pre-Phase-2 snapshots.
      comments: ((j['comments'] as List?) ?? const []).cast<Map<String, dynamic>>().map(Comment.fromJson).toList(),
      // Missing before Phase 7 and in older sync-cases `expected`.
      attachments:
          ((j['attachments'] as List?) ?? const []).cast<Map<String, dynamic>>().map(Attachment.fromJson).toList(),
      // Missing before Phase 8 and in older sync-cases `expected`.
      recurrences:
          ((j['recurrences'] as List?) ?? const []).cast<Map<String, dynamic>>().map(Recurrence.fromJson).toList(),
    );
  }
  Map<String, dynamic> toJson() => {
        'members': members.map((m) => m.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'payments': payments.map((p) => p.toJson()).toList(),
        'comments': comments.map((c) => c.toJson()).toList(),
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'recurrences': recurrences.map((r) => r.toJson()).toList(),
      };

  /// The `group` part (sync-cases `expected.group` compares the keys it has).
  Map<String, dynamic> groupJson() => {
        'name': name,
        'defaultCurrency': defaultCurrency,
        'kind': kind,
        'simplifyDebts': simplifyDebts,
        'defaultSplit': defaultSplit?.toJson(),
        'type': type,
        'coverImageId': coverImageId,
        'deleted': deleted,
      };
}

/// One event as returned by `GET /groups/{id}/events` (docs/API.md).
class SyncEvent {
  final int seq;
  final String clientId;
  final String type;
  final Map<String, dynamic> payload;
  final String? actorUserId;
  final String? createdAt;
  const SyncEvent({
    required this.seq,
    required this.clientId,
    required this.type,
    required this.payload,
    this.actorUserId,
    this.createdAt,
  });
  factory SyncEvent.fromJson(Map<String, dynamic> j) => SyncEvent(
        seq: (j['seq'] as num).toInt(),
        clientId: j['clientId'] as String,
        type: j['type'] as String,
        payload: (j['payload'] as Map).cast<String, dynamic>(),
        actorUserId: j['actorUserId'] as String?,
        createdAt: j['createdAt'] as String?,
      );
}

/// [e] for another group (docs/API.md, Moving expenses), or null when it can't move: every member with a payer or share
/// amount above 0 must be linked to a user who has an active member in [target]. Zero payers and shares are dropped,
/// and `split.input` keeps only the keys that map. An itemized bill's line people map like shares; if one can't, the
/// split is dropped (the shares open as Exact). paidBy follows from the payers (rule 10). The rate stays only when
/// both groups have the same default currency ([sameCurrency]); everything else is kept, with the new id [id].
Expense? remapForMove(Expense e, List<Member> source, List<Member> target, {required String id, required bool sameCurrency}) {
  final userOf = {for (final m in source) m.id: m.userId};
  final memberOf = {
    for (final m in target)
      if (!m.removed && m.userId != null) m.userId!: m.id,
  };
  String? map(String memberId) => memberOf[userOf[memberId]];
  List<Share>? remap(List<Share> list) {
    final out = <Share>[];
    for (final s in list.where((s) => s.amount > 0)) {
      final to = map(s.memberId);
      if (to == null) return null;
      out.add(Share(memberId: to, amount: s.amount));
    }
    return out;
  }

  final payers = remap(e.payers), shares = remap(e.shares);
  if (payers == null || shares == null || payers.isEmpty) return null;
  return Expense(
    id: id,
    description: e.description,
    amount: e.amount,
    currency: e.currency,
    fxRateToDefault: sameCurrency ? e.fxRateToDefault : null,
    payers: payers,
    date: e.date,
    category: e.category,
    notes: e.notes,
    refund: e.refund,
    split: _remapSplit(e.split, map),
    shares: shares,
  );
}

SplitSpec? _remapSplit(SplitSpec? s, String? Function(String) map) {
  if (s == null) return null;
  if (s.bill case final b?) {
    final lines = <ItemLine>[];
    for (final l in b.lines) {
      final ids = [for (final m in l.memberIds) map(m)];
      if (ids.contains(null)) return null;
      lines.add(ItemLine(name: l.name, amount: l.amount, memberIds: ids.cast<String>()));
    }
    return SplitSpec.itemized(ItemizedBill(lines: lines, tax: b.tax, tip: b.tip, discount: b.discount));
  }
  final input = s.input;
  return SplitSpec(s.mode!, input == null ? null : {
    for (final MapEntry(:key, :value) in input.entries)
      ?map(key): value,
  });
}
