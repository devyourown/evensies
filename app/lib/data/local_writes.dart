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
    await db.into(db.outbox).insert(OutboxCompanion.insert(
          clientId: newId(),
          groupId: groupId,
          type: type,
          payloadJson: jsonEncode(payload),
          createdAt: createdAt ?? nowIsoUtc(),
        ));
    sync.syncLater(groupId);
  }

  Future<void> createExpense(String groupId, Expense e) async {
    await db.transaction(() async {
      await db.into(db.expenses).insertOnConflictUpdate(expenseRow(groupId, e));
      await _writeLists(e);
    });
    await _enqueue(groupId, EventTypes.expenseCreated, {
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
    });
  }

  /// [fields] holds only the changed keys (API.md `expense.updated`): `shares`/`payers` as `List<Share>`,
  /// `split` as `SplitSpec?`. When a money field changed the caller sends all six (amount, paidBy, payers, shares,
  /// split, refund).
  Future<void> updateExpense(String groupId, Expense updated, Map<String, dynamic> fields) async {
    if (fields.isEmpty) return;
    await db.transaction(() async {
      final row = expenseRow(groupId, updated).copyWith(deleted: const Value.absent()); // deleting is its own event
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

  Future<void> deleteExpense(String groupId, String expenseId) async {
    await (db.update(db.expenses)..where((e) => e.id.equals(expenseId)))
        .write(const ExpensesCompanion(deleted: Value(true)));
    await _enqueue(groupId, EventTypes.expenseDeleted, {'expenseId': expenseId});
  }

  Future<void> restoreExpense(String groupId, String expenseId) async {
    await (db.update(db.expenses)..where((e) => e.id.equals(expenseId)))
        .write(const ExpensesCompanion(deleted: Value(false)));
    await _enqueue(groupId, EventTypes.expenseRestored, {'expenseId': expenseId});
  }

  /// As my member in the group; the payload's createdAt equals the event's (docs/API.md `comment.added`).
  Future<void> addComment(String groupId, String expenseId, String text) async {
    final me = (await db.getGroup(groupId))?.myMemberId;
    if (me == null) throw StateError('No member of mine in group $groupId');
    final id = newId();
    final at = nowIsoUtc();
    await db.into(db.comments).insert(CommentsCompanion.insert(
        id: id, groupId: groupId, expenseId: expenseId, authorMemberId: me, body: text, createdAt: at));
    await _enqueue(
      groupId,
      EventTypes.commentAdded,
      {'commentId': id, 'expenseId': expenseId, 'authorMemberId': me, 'text': text, 'createdAt': at},
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
    await _enqueue(groupId, EventTypes.paymentCreated, {
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
      final why = leaveBlocker(balancesOf(state), me, state.defaultCurrency ?? '');
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

class LeaveException implements Exception {
  final String message;
  const LeaveException(this.message);
  @override
  String toString() => message;
}
