import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/ids.dart';
import '../domain/balances.dart' show balancesOf, leaveBlocker;
import '../domain/models.dart';
import 'api/dto.dart';
import 'db/database.dart';
import 'sync/event_types.dart';
import 'sync/group_state_store.dart';
import 'sync/sync_service.dart';

/// Every local change: write drift rows immediately + enqueue the API.md event, then sync in the background.
class LocalWrites {
  final AppDatabase db;
  final SyncService sync;
  LocalWrites(this.db, this.sync);

  Future<void> _enqueue(String groupId, String type, Map<String, dynamic> payload, {String? createdAt}) async {
    await _outbox(groupId, type, payload, createdAt: createdAt);
    sync.syncLater(groupId);
  }

  Future<void> _outbox(String groupId, String type, Map<String, dynamic> payload, {String? createdAt}) =>
      db.into(db.outbox).insert(OutboxCompanion.insert(
            clientId: newId(),
            groupId: groupId,
            type: type,
            payloadJson: jsonEncode(payload),
            createdAt: createdAt ?? nowIsoUtc(),
          ));

  Future<void> createExpense(String groupId, Expense e) async {
    await db.transaction(() async {
      await db.into(db.expenses).insertOnConflictUpdate(expenseRow(groupId, e));
      await _writeLists(e);
    });
    await _enqueue(groupId, EventTypes.expenseCreated, expenseCreatedPayload(e));
  }

  /// [fields] holds only the changed keys (API.md `expense.updated`): `shares`/`payers` as `List<Share>`,
  /// `split` as `SplitSpec?`. When a money field changed the caller sends all six (amount, paidBy, payers, shares,
  /// split, refund).
  Future<void> updateExpense(String groupId, Expense updated, Map<String, dynamic> fields) async {
    if (fields.isEmpty) return;
    await db.transaction(() async {
      // Deleting (and moving) is its own event.
      final row = expenseRow(groupId, updated).copyWith(deleted: const Value.absent(), moved: const Value.absent());
      await db.into(db.expenses).insertOnConflictUpdate(row);
      await _writeLists(updated);
    });
    await _enqueue(groupId, EventTypes.expenseUpdated, {
      'expenseId': updated.id,
      'fields': {
        for (final e in fields.entries)
          e.key: switch (e.value) {
            final List<Share> l => l.map((s) => s.toJson()).toList(),
            final SplitSpec s => s.toJson(),
            final v => v,
          },
      },
    });
  }

  Future<void> _writeLists(Expense e) async {
    await (db.delete(db.expenseShares)..where((s) => s.expenseId.equals(e.id))).go();
    await (db.delete(db.expensePayers)..where((s) => s.expenseId.equals(e.id))).go();
    await db.batch((b) {
      b.insertAll(db.expenseShares, [
        for (final s in e.shares)
          ExpenseSharesCompanion.insert(expenseId: e.id, memberId: s.memberId, amount: s.amount),
      ]);
      b.insertAll(db.expensePayers, [
        for (final p in e.payers)
          ExpensePayersCompanion.insert(expenseId: e.id, memberId: p.memberId, amount: p.amount),
      ]);
    });
  }

  /// [movedTo] marks a move (docs/API.md 지출 옮기기): the expense also becomes moved, which no restore undoes.
  Future<void> deleteExpense(String groupId, String expenseId, {({String groupId, String expenseId})? movedTo}) async {
    await (db.update(db.expenses)..where((e) => e.id.equals(expenseId))).write(ExpensesCompanion(
        deleted: const Value(true), moved: movedTo == null ? const Value.absent() : const Value(true)));
    await _enqueue(groupId, EventTypes.expenseDeleted, {
      'expenseId': expenseId,
      if (movedTo != null) 'movedTo': {'groupId': movedTo.groupId, 'expenseId': movedTo.expenseId},
    });
  }

  /// Moves [e] from [fromGroup] to [toGroup] as [moved] (remapForMove), online only (docs/API.md 지출 옮기기): the new
  /// expense is pushed to [toGroup] directly, and only then the source's delete with movedTo goes into the outbox.
  /// If the push fails nothing has changed ([MoveException]). Pass the same [clientId] (and [moved] id) on a retry, so a
  /// push that reached the server before its answer was lost isn't stored twice; a [retry] also carries an
  /// `expense.updated` with all of [moved]'s values, so an edit made between the tries isn't lost to that dedupe (a
  /// no-op, hidden in Activity, when the first try never landed).
  Future<void> moveExpense(String fromGroup, Expense e, String toGroup, Expense moved,
      {String? clientId, bool retry = false}) async {
    final created = expenseCreatedPayload(moved);
    try {
      await sync.api.pushEvents(toGroup, [
        OutboundEvent(
            clientId: clientId ?? newId(), type: EventTypes.expenseCreated, payload: created, createdAt: nowIsoUtc()),
        if (retry)
          OutboundEvent(
              clientId: newId(),
              type: EventTypes.expenseUpdated,
              payload: {'expenseId': moved.id, 'fields': {...created}..remove('expenseId')},
              createdAt: nowIsoUtc()),
      ]);
    } on ApiException catch (x) {
      throw MoveException(
          x.code == 'NETWORK' ? "Couldn't move it. Try again when you're online" : "Couldn't move it: ${x.message}");
    }
    await deleteExpense(fromGroup, e.id, movedTo: (groupId: toGroup, expenseId: moved.id));
    sync.syncLater(toGroup);
  }

  /// A moved expense stays deleted (rule 13), like on the server.
  Future<void> restoreExpense(String groupId, String expenseId) async {
    await (db.update(db.expenses)..where((e) => e.id.equals(expenseId) & e.moved.equals(false)))
        .write(const ExpensesCompanion(deleted: Value(false)));
    await _enqueue(groupId, EventTypes.expenseRestored, {'expenseId': expenseId});
  }

  /// As my member in the group, on an expense or (Phase 6) a payment: exactly one of [expenseId] and [paymentId].
  /// The payload's createdAt equals the event's (docs/API.md `comment.added`).
  Future<void> addComment(String groupId, String text, {String? expenseId, String? paymentId}) async {
    if ((expenseId == null) == (paymentId == null)) throw ArgumentError('pass expenseId or paymentId');
    final me = (await db.getGroup(groupId))?.myMemberId;
    if (me == null) throw StateError('No member of mine in group $groupId');
    final id = newId();
    final at = nowIsoUtc();
    await db.into(db.comments).insert(CommentsCompanion.insert(
        id: id,
        groupId: groupId,
        expenseId: Value(expenseId),
        paymentId: Value(paymentId),
        authorMemberId: me,
        body: text,
        createdAt: at));
    await _enqueue(
      groupId,
      EventTypes.commentAdded,
      {
        'commentId': id,
        'expenseId': ?expenseId,
        'paymentId': ?paymentId,
        'authorMemberId': me,
        'text': text,
        'createdAt': at,
      },
      createdAt: at,
    );
  }

  /// Blanks the text like the applier (docs/API.md 적용 규칙 8).
  Future<void> deleteComment(String groupId, String commentId) async {
    await (db.update(db.comments)..where((c) => c.id.equals(commentId)))
        .write(const CommentsCompanion(deleted: Value(true), body: Value('')));
    await db.dropDeletedCommentActivity(groupId);
    await _enqueue(groupId, EventTypes.commentDeleted, {'commentId': commentId});
  }

  Future<void> createPayment(String groupId, Payment p) async {
    await _writePayment(groupId, p);
    sync.syncLater(groupId);
  }

  /// An edit (docs/API.md 송금 기록·편집): `payment.deleted` of [oldId] plus `payment.created` of [p] (a new id) in one
  /// local transaction, so they usually go in one push. Comments stay on the old payment.
  Future<void> editPayment(String groupId, String oldId, Payment p) async {
    await db.transaction(() async {
      await (db.update(db.payments)..where((x) => x.id.equals(oldId)))
          .write(const PaymentsCompanion(deleted: Value(true)));
      await _outbox(groupId, EventTypes.paymentDeleted, {'paymentId': oldId});
      await _writePayment(groupId, p);
    });
    sync.syncLater(groupId);
  }

  Future<void> _writePayment(String groupId, Payment p) async {
    await db.into(db.payments).insertOnConflictUpdate(PaymentsCompanion.insert(
          id: p.id,
          groupId: groupId,
          fromMember: p.fromMember,
          toMember: p.toMember,
          amount: p.amount,
          currency: p.currency,
          date: p.date,
          status: Value(p.status),
        ));
    await _outbox(groupId, EventTypes.paymentCreated, {
      'paymentId': p.id,
      'fromMember': p.fromMember,
      'toMember': p.toMember,
      'amount': p.amount,
      'currency': p.currency,
      'date': p.date,
      'status': p.status,
    });
  }

  Future<void> confirmPayment(String groupId, String paymentId) async {
    await (db.update(db.payments)..where((p) => p.id.equals(paymentId)))
        .write(const PaymentsCompanion(status: Value('confirmed')));
    await _enqueue(groupId, EventTypes.paymentConfirmed, {'paymentId': paymentId});
  }

  Future<void> deletePayment(String groupId, String paymentId) async {
    await (db.update(db.payments)..where((p) => p.id.equals(paymentId)))
        .write(const PaymentsCompanion(deleted: Value(true)));
    await _enqueue(groupId, EventTypes.paymentDeleted, {'paymentId': paymentId});
  }

  Future<void> addMember(String groupId, String name) async {
    final id = newId();
    await db.into(db.members).insert(MembersCompanion.insert(id: id, groupId: groupId, name: name));
    await _enqueue(groupId, EventTypes.memberAdded, {'memberId': id, 'name': name, 'userId': null});
  }

  Future<void> removeMember(String groupId, String memberId) async {
    await (db.update(db.members)..where((m) => m.id.equals(memberId)))
        .write(const MembersCompanion(removed: Value(true)));
    await _enqueue(groupId, EventTypes.memberRemoved, {'memberId': memberId});
  }

  /// Convert (docs/API.md 통화 환산): every non-deleted expense in [currency] (not the group's) whose rate is null or 0
  /// gets [rate] (> 0), in one local transaction so it usually goes in one push. Returns each changed expense's previous
  /// rate (null or 0), which [setRates] puts back (Undo).
  Future<Map<String, double?>> convertCurrency(String groupId, String currency, double rate) async {
    if (!(rate > 0) || !rate.isFinite) throw ArgumentError.value(rate, 'rate', 'must be above 0');
    final before = await db.transaction(() async {
      final g = await db.getGroup(groupId);
      if (g == null || g.defaultCurrency == currency) return <String, double?>{};
      final xs = await (db.select(db.expenses)
            ..where((e) =>
                e.groupId.equals(groupId) &
                e.currency.equals(currency) &
                e.deleted.equals(false) &
                (e.fxRateToDefault.isNull() | e.fxRateToDefault.equals(0))))
          .get();
      await _writeRates(groupId, currency, {for (final x in xs) x.id: rate});
      return {for (final x in xs) x.id: x.fxRateToDefault};
    });
    if (before.isNotEmpty) sync.syncLater(groupId);
    return before;
  }

  /// expenseId → rate on expenses in [currency], in one local transaction (Undo of a Convert).
  Future<void> setRates(String groupId, String currency, Map<String, double?> rates) async {
    await db.transaction(() => _writeRates(groupId, currency, rates));
    if (rates.isNotEmpty) sync.syncLater(groupId);
  }

  /// One `expense.updated` each, with the currency next to the rate (docs/API.md: both keys whenever either is sent),
  /// so a concurrent currency change can't end up carrying this rate under per-field LWW.
  /// ponytail: a Convert from a stale device that races a change to a currency with other decimals (JPY→USD) puts the
  /// currency back while the amount stays in the new units. Rare; closing it means sending every money field, which
  /// would also undo other people's split edits.
  Future<void> _writeRates(String groupId, String currency, Map<String, double?> rates) async {
    final at = nowIsoUtc();
    for (final MapEntry(key: id, value: r) in rates.entries) {
      await (db.update(db.expenses)..where((e) => e.id.equals(id))).write(ExpensesCompanion(fxRateToDefault: Value(r)));
      await _outbox(groupId, EventTypes.expenseUpdated, {
        'expenseId': id,
        'fields': {'currency': currency, 'fxRateToDefault': r},
      }, createdAt: at);
    }
  }

  /// Group settings (docs/API.md `group.updated`): only the given keys are sent; [clearDefaultSplit] sends
  /// `"defaultSplit": null`. The currency is applied optimistically; when my event comes back in the pull the app
  /// takes the server's state, which has ignored it if an expense or payment got there first (rule 12).
  Future<void> updateGroup(
    String groupId, {
    String? name,
    String? defaultCurrency,
    bool? simplifyDebts,
    SplitSpec? defaultSplit,
    bool clearDefaultSplit = false,
  }) async {
    final g = await db.getGroup(groupId);
    if (g == null) return;
    final splitKey = defaultSplit != null || clearDefaultSplit;
    await db.upsertGroup(g.copyWith(
      name: name ?? g.name,
      defaultCurrency: defaultCurrency ?? g.defaultCurrency,
      simplifyDebts: simplifyDebts ?? g.simplifyDebts,
      defaultSplitJson: splitKey ? Value(splitToJson(defaultSplit)) : const Value.absent(),
    ));
    await _enqueue(groupId, EventTypes.groupUpdated, {
      'name': ?name,
      'defaultCurrency': ?defaultCurrency,
      'simplifyDebts': ?simplifyDebts,
      if (splitKey) 'defaultSplit': defaultSplit?.toJson(),
    });
  }

  /// Leave the group (docs/API.md 그룹 나가기): online only, not through the outbox. Throws when offline, when
  /// changes are still waiting to sync, or when my balance isn't zero after the sync (it may have pulled new expenses).
  Future<void> leaveGroup(String groupId) async {
    final me = (await db.getGroup(groupId))?.myMemberId;
    if (me == null) throw StateError('No member of mine in group $groupId');
    try {
      await sync.sync(groupId);
      if (await db.getGroup(groupId) == null) return; // already out: removed by someone else (sync dropped it)
      if ((await db.unsentOutbox(groupId)).isNotEmpty) {
        throw const LeaveException('Still syncing. Try again in a moment.');
      }
      final state = await sync.store.load(groupId);
      final why = leaveBlocker(balancesOf(state), me);
      if (why != null) throw LeaveException(why);
      await sync.api.pushEvents(groupId, [
        OutboundEvent(
            clientId: newId(), type: EventTypes.memberRemoved, payload: {'memberId': me}, createdAt: nowIsoUtc()),
      ]);
    } on ApiException catch (e) {
      if (e.code == 'NETWORK') throw const LeaveException('You need to be online to leave');
      rethrow;
    }
    await db.deleteGroupData(groupId);
  }
}

/// `expense.created` payload of [e] (docs/API.md).
Map<String, dynamic> expenseCreatedPayload(Expense e) => {
      'expenseId': e.id,
      'description': e.description,
      'amount': e.amount,
      'currency': e.currency,
      'fxRateToDefault': e.fxRateToDefault,
      'paidBy': e.paidBy,
      'payers': e.payers.map((s) => s.toJson()).toList(),
      'refund': e.refund,
      'split': e.split?.toJson(),
      'date': e.date,
      'category': e.category,
      'notes': e.notes,
      'shares': e.shares.map((s) => s.toJson()).toList(),
    };

/// Status of a payment recorded with "Record a payment" (docs/API.md 송금 기록·편집): `sent` when I pay ([from] is
/// mine) someone linked to another user, so they confirm; else `confirmed`.
String recordedStatus(Member? from, Member? to, String? myUserId) =>
    from?.userId != null && from?.userId == myUserId && to?.userId != null && to?.userId != myUserId
        ? 'sent'
        : 'confirmed';

class MoveException implements Exception {
  final String message;
  const MoveException(this.message);
  @override
  String toString() => message;
}

class LeaveException implements Exception {
  final String message;
  const LeaveException(this.message);
  @override
  String toString() => message;
}
