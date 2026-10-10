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
  const Payment({
    required this.id,
    required this.fromMember,
    required this.toMember,
    required this.amount,
    required this.currency,
    required this.date,
    this.deleted = false,
  });
  Payment copyWith({bool? deleted}) => Payment(
        id: id,
        fromMember: fromMember,
        toMember: toMember,
        amount: amount,
        currency: currency,
        date: date,
        deleted: deleted ?? this.deleted,
      );
  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: j['id'] as String,
        fromMember: j['fromMember'] as String,
        toMember: j['toMember'] as String,
        amount: (j['amount'] as num).toInt(),
        currency: j['currency'] as String,
        date: j['date'] as String,
        deleted: j['deleted'] as bool? ?? false,
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'fromMember': fromMember,
        'toMember': toMember,
        'amount': amount,
        'currency': currency,
        'date': date,
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
  const GroupState({
    this.name,
    this.defaultCurrency,
    this.members = const [],
    this.expenses = const [],
    this.payments = const [],
  });

  static const empty = GroupState();

  GroupState copyWith({
    String? name,
    String? defaultCurrency,
    List<Member>? members,
    List<Expense>? expenses,
    List<Payment>? payments,
  }) =>
      GroupState(
        name: name ?? this.name,
        defaultCurrency: defaultCurrency ?? this.defaultCurrency,
        members: members ?? this.members,
        expenses: expenses ?? this.expenses,
        payments: payments ?? this.payments,
      );

  Member? member(String id) => members.where((m) => m.id == id).firstOrNull;
  Expense? expense(String id) => expenses.where((e) => e.id == id).firstOrNull;
  Payment? payment(String id) => payments.where((p) => p.id == id).firstOrNull;

  /// Parses the `members/expenses/payments` part of a snapshot or of a sync-cases `expected`.
  factory GroupState.fromJson(Map<String, dynamic> j) => GroupState(
        name: (j['group'] as Map?)?['name'] as String?,
        defaultCurrency: (j['group'] as Map?)?['defaultCurrency'] as String?,
        members: (j['members'] as List).cast<Map<String, dynamic>>().map(Member.fromJson).toList(),
        expenses: (j['expenses'] as List).cast<Map<String, dynamic>>().map(Expense.fromJson).toList(),
        payments: (j['payments'] as List).cast<Map<String, dynamic>>().map(Payment.fromJson).toList(),
      );
  Map<String, dynamic> toJson() => {
        'members': members.map((m) => m.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'payments': payments.map((p) => p.toJson()).toList(),
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
