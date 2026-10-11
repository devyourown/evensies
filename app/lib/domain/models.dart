/// In-memory group state, shape mirrors `GET /groups/{id}/snapshot` (docs/API.md).
library;

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

class Expense {
  final String id;
  final String description;
  final int amount;
  final String currency;
  final double? fxRateToDefault;
  final String paidBy;
  final String date; // YYYY-MM-DD
  final String? category;
  final String? notes;
  final bool deleted;
  final List<Share> shares;
  const Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.currency,
    this.fxRateToDefault,
    required this.paidBy,
    required this.date,
    this.category,
    this.notes,
    this.deleted = false,
    required this.shares,
  });

  Expense copyWith({
    String? description,
    int? amount,
    String? currency,
    double? fxRateToDefault,
    bool clearFx = false,
    String? paidBy,
    String? date,
    String? category,
    bool clearCategory = false,
    String? notes,
    bool clearNotes = false,
    bool? deleted,
    List<Share>? shares,
  }) =>
      Expense(
        id: id,
        description: description ?? this.description,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        fxRateToDefault: clearFx ? null : (fxRateToDefault ?? this.fxRateToDefault),
        paidBy: paidBy ?? this.paidBy,
        date: date ?? this.date,
        category: clearCategory ? null : (category ?? this.category),
        notes: clearNotes ? null : (notes ?? this.notes),
        deleted: deleted ?? this.deleted,
        shares: shares ?? this.shares,
      );

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] as String,
        description: j['description'] as String,
        amount: (j['amount'] as num).toInt(),
        currency: j['currency'] as String,
        fxRateToDefault: (j['fxRateToDefault'] as num?)?.toDouble(),
        paidBy: j['paidBy'] as String,
        date: j['date'] as String,
        category: j['category'] as String?,
        notes: j['notes'] as String?,
        deleted: j['deleted'] as bool? ?? false,
        shares: (j['shares'] as List).cast<Map<String, dynamic>>().map(Share.fromJson).toList(),
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'currency': currency,
        'fxRateToDefault': fxRateToDefault,
        'paidBy': paidBy,
        'date': date,
        'category': category,
        'notes': notes,
        'deleted': deleted,
        'shares': shares.map((s) => s.toJson()).toList(),
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
  const Payment({
    required this.id,
    required this.fromMember,
    required this.toMember,
    required this.amount,
    required this.currency,
    required this.date,
    this.deleted = false,
    this.status = 'confirmed',
  });
  bool get pending => status == 'sent';
  Payment copyWith({bool? deleted, String? status}) => Payment(
        id: id,
        fromMember: fromMember,
        toMember: toMember,
        amount: amount,
        currency: currency,
        date: date,
        deleted: deleted ?? this.deleted,
        status: status ?? this.status,
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
      };
}

class Comment {
  final String id;
  final String expenseId;
  final String authorMemberId;
  final String text;
  final String createdAt; // ISO-8601 UTC
  final bool deleted;
  const Comment({
    required this.id,
    required this.expenseId,
    required this.authorMemberId,
    required this.text,
    required this.createdAt,
    this.deleted = false,
  });
  Comment copyWith({bool? deleted, String? text}) => Comment(
        id: id,
        expenseId: expenseId,
        authorMemberId: authorMemberId,
        text: text ?? this.text,
        createdAt: createdAt,
        deleted: deleted ?? this.deleted,
      );
  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
        id: j['id'] as String,
        expenseId: j['expenseId'] as String,
        authorMemberId: j['authorMemberId'] as String,
        text: j['text'] as String,
        createdAt: j['createdAt'] as String,
        deleted: j['deleted'] as bool? ?? false,
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'expenseId': expenseId,
        'authorMemberId': authorMemberId,
        'text': text,
        'createdAt': createdAt,
        'deleted': deleted,
      };
}

/// Immutable. Lists keep insertion order (same as the server snapshot).
class GroupState {
  final String? name;
  final String? defaultCurrency;
  final List<Member> members;
  final List<Expense> expenses;
  final List<Payment> payments;
  final List<Comment> comments;
  const GroupState({
    this.name,
    this.defaultCurrency,
    this.members = const [],
    this.expenses = const [],
    this.payments = const [],
    this.comments = const [],
  });

  static const empty = GroupState();

  GroupState copyWith({
    String? name,
    String? defaultCurrency,
    List<Member>? members,
    List<Expense>? expenses,
    List<Payment>? payments,
    List<Comment>? comments,
  }) =>
      GroupState(
        name: name ?? this.name,
        defaultCurrency: defaultCurrency ?? this.defaultCurrency,
        members: members ?? this.members,
        expenses: expenses ?? this.expenses,
        payments: payments ?? this.payments,
        comments: comments ?? this.comments,
      );

  Member? member(String id) => members.where((m) => m.id == id).firstOrNull;
  Expense? expense(String id) => expenses.where((e) => e.id == id).firstOrNull;
  Payment? payment(String id) => payments.where((p) => p.id == id).firstOrNull;
  Comment? comment(String id) => comments.where((c) => c.id == id).firstOrNull;

  /// Parses the `members/expenses/payments/comments` part of a snapshot or of a sync-cases `expected`.
  factory GroupState.fromJson(Map<String, dynamic> j) => GroupState(
        name: (j['group'] as Map?)?['name'] as String?,
        defaultCurrency: (j['group'] as Map?)?['defaultCurrency'] as String?,
        members: (j['members'] as List).cast<Map<String, dynamic>>().map(Member.fromJson).toList(),
        expenses: (j['expenses'] as List).cast<Map<String, dynamic>>().map(Expense.fromJson).toList(),
        payments: (j['payments'] as List).cast<Map<String, dynamic>>().map(Payment.fromJson).toList(),
        // Missing in sync-cases `expected` and in pre-Phase-2 snapshots.
        comments: ((j['comments'] as List?) ?? const []).cast<Map<String, dynamic>>().map(Comment.fromJson).toList(),
      );
  Map<String, dynamic> toJson() => {
        'members': members.map((m) => m.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'payments': payments.map((p) => p.toJson()).toList(),
        'comments': comments.map((c) => c.toJson()).toList(),
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
