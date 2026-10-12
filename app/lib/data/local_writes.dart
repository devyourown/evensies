import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/ids.dart';
import '../core/snack.dart' show errorForCode;
import '../domain/balances.dart' show balancesOf, leaveBlocker;
import '../domain/models.dart';
import '../domain/recurrence.dart' show Series;
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

  /// [repeat] (a frequency) also starts a series with [e] as its first expense (docs/API.md 반복 지출): the series row
  /// and `recurrence.created` go before the expense and its `expense.created`, in one local transaction.
  Future<void> createExpense(String groupId, Expense e, {String? repeat}) async {
    if (repeat != null) e = e.copyWith(recurrenceId: newId(), occurrence: 0);
    await db.transaction(() async {
      if (repeat != null) await _startSeries(groupId, e, repeat);
      await db.into(db.expenses).insertOnConflictUpdate(expenseRow(groupId, e));
      await _writeLists(e);
      await _outbox(groupId, EventTypes.expenseCreated, expenseCreatedPayload(e));
    });
    sync.syncLater(groupId);
  }

  /// [fields] holds only the changed keys (API.md `expense.updated`): `shares`/`payers` as `List<Share>`,
  /// `split` as `SplitSpec?`. When a money field changed the caller sends all six (amount, paidBy, payers, shares,
  /// split, refund).
  Future<void> updateExpense(String groupId, Expense updated, Map<String, dynamic> fields) async {
    if (fields.isEmpty) return;
    await db.transaction(() => _update(groupId, updated, fields));
    sync.syncLater(groupId);
  }

  Future<void> _update(String groupId, Expense updated, Map<String, dynamic> fields) async {
    // Deleting (and moving) is its own event; the series tag changes only when it is sent.
    final series = fields.containsKey('recurrenceId');
    final row = expenseRow(groupId, updated).copyWith(
      deleted: const Value.absent(),
      moved: const Value.absent(),
      recurrenceId: series ? Value(updated.recurrenceId) : const Value.absent(),
      occurrence: series ? Value(updated.occurrence) : const Value.absent(),
    );
    await db.into(db.expenses).insertOnConflictUpdate(row);
    await _writeLists(updated);
    await _outbox(groupId, EventTypes.expenseUpdated, {'expenseId': updated.id, 'fields': _json(fields)});
  }

  /// Changed fields as event JSON: `List<Share>` and `SplitSpec` encoded, the rest as given.
  static Map<String, dynamic> _json(Map<String, dynamic> fields) => {
        for (final e in fields.entries)
          e.key: switch (e.value) {
            final List<Share> l => l.map((s) => s.toJson()).toList(),
            final SplitSpec s => s.toJson(),
            final v => v,
          },
      };

  /// A new series [frequency] for [e] (its recurrenceId set, occurrence 0): starts on [e]'s date in this device's
  /// time zone, with [e] as template. The row and `recurrence.created`; the caller holds the transaction.
  Future<void> _startSeries(String groupId, Expense e, String frequency) async {
    final r = Recurrence(
        id: e.recurrenceId!, frequency: frequency, startDate: e.date, timeZone: deviceTimeZone(), template: templateOf(e));
    await db.into(db.recurrences).insert(recurrenceRow(groupId, r));
    await _outbox(groupId, EventTypes.recurrenceCreated, {
      'recurrenceId': r.id,
      'frequency': r.frequency,
      'startDate': r.startDate,
      'timeZone': r.timeZone,
      'template': r.template,
    });
  }

  /// Future repeats of series [recurrenceId] (docs/API.md `recurrence.updated`): [fields] as for [updateExpense] (the
  /// changed template keys, never the date) are merged into the local template key by key and sent. Nothing when empty.
  Future<void> updateRecurrence(String groupId, String recurrenceId, Map<String, dynamic> fields) async {
    final f = _json(fields);
    if (f.isEmpty) return;
    await db.transaction(() async {
      final row = await (db.select(db.recurrences)..where((r) => r.id.equals(recurrenceId))).getSingleOrNull();
      if (row != null && !row.deleted) {
        final t = {...(jsonDecode(row.templateJson) as Map).cast<String, dynamic>(), ...f};
        await (db.update(db.recurrences)..where((r) => r.id.equals(recurrenceId)))
            .write(RecurrencesCompanion(templateJson: Value(jsonEncode(t))));
      }
      await _outbox(groupId, EventTypes.recurrenceUpdated, {'recurrenceId': recurrenceId, 'fields': f});
    });
    sync.syncLater(groupId);
  }

  /// Stops series [recurrenceId] for everyone: no more repeats, those already added stay (there is no restart).
  Future<void> stopRecurrence(String groupId, String recurrenceId) async {
    await db.transaction(() => _stop(groupId, recurrenceId));
    sync.syncLater(groupId);
  }

  Future<void> _stop(String groupId, String recurrenceId) async {
    await (db.update(db.recurrences)..where((r) => r.id.equals(recurrenceId)))
        .write(const RecurrencesCompanion(deleted: Value(true)));
    await _outbox(groupId, EventTypes.recurrenceDeleted, {'recurrenceId': recurrenceId});
  }

  /// Restarts the schedule from [e] (a new frequency or date on the latest repeat, or Repeat picked on an expense in no
  /// live series): [stop]'s series stops, a new [frequency] series starts on [e]'s date with [e] as template, and [e]
  /// moves into it as occurrence 0 with its changed [fields] (as for [updateExpense]). One local transaction:
  /// `recurrence.deleted`, `recurrence.created`, then `expense.updated`.
  Future<void> repeatFrom(String groupId, Expense e, String frequency,
      {String? stop, Map<String, dynamic> fields = const {}}) async {
    final next = e.copyWith(recurrenceId: newId(), occurrence: 0);
    await db.transaction(() async {
      if (stop != null) await _stop(groupId, stop);
      await _startSeries(groupId, next, frequency);
      await _update(groupId, next, {...fields, 'recurrenceId': next.recurrenceId, 'occurrence': 0});
    });
    sync.syncLater(groupId);
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
  /// [stopRecurrence] also stops that series in the same transaction ("Delete and stop repeating").
  Future<void> deleteExpense(String groupId, String expenseId,
      {({String groupId, String expenseId})? movedTo, String? stopRecurrence}) async {
    await db.transaction(() async {
      await (db.update(db.expenses)..where((e) => e.id.equals(expenseId))).write(ExpensesCompanion(
          deleted: const Value(true), moved: movedTo == null ? const Value.absent() : const Value(true)));
      await _outbox(groupId, EventTypes.expenseDeleted, {
        'expenseId': expenseId,
        if (movedTo != null) 'movedTo': {'groupId': movedTo.groupId, 'expenseId': movedTo.expenseId},
      });
      if (stopRecurrence != null) await _stop(groupId, stopRecurrence);
    });
    sync.syncLater(groupId);
  }

  /// Moves [e] from [fromGroup] to [toGroup] as [moved] (remapForMove), online only (docs/API.md 지출 옮기기): the new
  /// expense is pushed to [toGroup] directly, and only then the source's delete with movedTo goes into the outbox.
  /// If the push fails nothing has changed ([MoveException]). Pass the same [clientId] (and [moved] id) on a retry, so a
  /// push that reached the server before its answer was lost isn't stored twice; a [retry] also carries an
  /// `expense.updated` with all of [moved]'s values, so an edit made between the tries isn't lost to that dedupe (a
  /// no-op, hidden in Activity, when the first try never landed).
  /// [receipts] (source id → the new id and its `attachment.added` clientId, the same on a retry): each photo is
  /// copied under its new id (downloaded if this device has no copy), uploaded to [toGroup] from that copy, and attached
  /// in the same push; the originals stay on the old expense. One the server no longer has (404: removed meanwhile) is
  /// left out.
  Future<void> moveExpense(String fromGroup, Expense e, String toGroup, Expense moved,
      {String? clientId, bool retry = false, Map<String, ({String id, String clientId})> receipts = const {}}) async {
    final created = expenseCreatedPayload(moved);
    try {
      final attached = <({String id, String clientId})>[];
      for (final MapEntry(key: from, value: to) in receipts.entries) {
        try {
          final (image, thumb) = await sync.receipts.keepCopy(fromGroup, from, to.id);
          await sync.api.uploadAttachment(toGroup, to.id, image, thumb); // a retry of a stored one answers 200
          attached.add(to);
        } on ApiException catch (x) {
          if (x.status != 404 || x.code == 'NETWORK') rethrow;
        }
      }
      await sync.api.pushEvents(toGroup, [
        OutboundEvent(
            clientId: clientId ?? newId(), type: EventTypes.expenseCreated, payload: created, createdAt: nowIsoUtc()),
        if (retry)
          OutboundEvent(
              clientId: newId(),
              type: EventTypes.expenseUpdated,
              payload: {'expenseId': moved.id, 'fields': {...created}..remove('expenseId')},
              createdAt: nowIsoUtc()),
        for (final to in attached)
          OutboundEvent(
              clientId: to.clientId,
              type: EventTypes.attachmentAdded,
              payload: {'attachmentId': to.id, 'expenseId': moved.id},
              createdAt: nowIsoUtc()),
      ]);
    } on ApiException catch (x) {
      final l = sync.l10n;
      throw MoveException(x.code == 'NETWORK' ? l.moveOffline : l.moveFailed(errorForCode(l, x.code)));
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

  /// An edit (docs/API.md 송금 기록·편집): `payment.deleted` of [oldId] with `replacedBy` plus `payment.created` of [p]
  /// (a new id) in one local transaction, so they usually go in one push. The old one can't be restored (rule 7), and
  /// its comments stay on it.
  Future<void> editPayment(String groupId, String oldId, Payment p) async {
    await db.transaction(() async {
      await (db.update(db.payments)..where((x) => x.id.equals(oldId)))
          .write(const PaymentsCompanion(deleted: Value(true), replaced: Value(true)));
      await _outbox(groupId, EventTypes.paymentDeleted, {'paymentId': oldId, 'replacedBy': p.id});
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

  /// Undo of a delete (docs/API.md 삭제한 송금 되살리기): live again with the status it had; an edited (replaced) one
  /// stays deleted, like on the server.
  Future<void> restorePayment(String groupId, String paymentId) async {
    await (db.update(db.payments)..where((p) => p.id.equals(paymentId) & p.replaced.equals(false)))
        .write(const PaymentsCompanion(deleted: Value(false)));
    await _enqueue(groupId, EventTypes.paymentRestored, {'paymentId': paymentId});
  }

  /// A prepared receipt photo ([ReceiptFiles.prepare], id [attachmentId]) on [expenseId] (docs/API.md 영수증): the local
  /// row, its pending upload and `attachment.added` (after the expense's `expense.created` when that is still queued),
  /// in one transaction. Sync uploads the photo before it pushes the event.
  Future<void> attachReceipt(String groupId, String expenseId, String attachmentId) async {
    await db.transaction(() async {
      await db.into(db.attachments)
          .insert(AttachmentsCompanion.insert(id: attachmentId, groupId: groupId, expenseId: expenseId));
      await db.into(db.pendingUploads)
          .insert(PendingUploadsCompanion.insert(attachmentId: attachmentId, groupId: groupId, createdAt: nowIsoUtc()));
      await _outbox(groupId, EventTypes.attachmentAdded, {'attachmentId': attachmentId, 'expenseId': expenseId});
    });
    sync.syncLater(groupId);
  }

  /// Removes a receipt for everyone. Not uploaded yet: its files, rows and unsent `attachment.added` go, and nothing
  /// reaches the server. Uploaded: `attachment.deleted` (the server deletes the files after it commits), and this
  /// device's copy goes.
  Future<void> removeReceipt(String groupId, String attachmentId) async {
    final pending = await (db.select(db.pendingUploads)..where((p) => p.attachmentId.equals(attachmentId))).get();
    if (pending.isNotEmpty) {
      await sync.receipts.delete([attachmentId]);
      await db.dropReceipts([attachmentId]);
      return;
    }
    final row = await db.getAttachment(attachmentId);
    await (db.update(db.attachments)..where((a) => a.id.equals(attachmentId)))
        .write(const AttachmentsCompanion(deleted: Value(true)));
    await _enqueue(groupId, EventTypes.attachmentDeleted, {
      'attachmentId': attachmentId,
      'expenseId': ?row?.expenseId,
    });
    await sync.receipts.delete([attachmentId]);
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
  /// changes are still waiting to sync, or when my balance isn't zero after the sync (it may have pulled new expenses),
  /// or a live repeating expense still has me in it.
  Future<void> leaveGroup(String groupId) async {
    final me = (await db.getGroup(groupId))?.myMemberId;
    if (me == null) throw StateError('No member of mine in group $groupId');
    try {
      await sync.sync(groupId);
      if (await db.getGroup(groupId) == null) return; // already out: removed by someone else (sync dropped it)
      if ((await db.unsentOutbox(groupId)).isNotEmpty) {
        throw LeaveException(sync.l10n.leaveSyncing);
      }
      final state = await sync.store.load(groupId);
      final why = leaveBlocker(sync.l10n, balancesOf(state), me) ?? state.seriesBlocker(sync.l10n, me);
      if (why != null) throw LeaveException(why);
      await sync.api.pushEvents(groupId, [
        OutboundEvent(
            clientId: newId(), type: EventTypes.memberRemoved, payload: {'memberId': me}, createdAt: nowIsoUtc()),
      ]);
    } on ApiException catch (e) {
      if (e.code == 'NETWORK') throw LeaveException(sync.l10n.leaveOffline);
      rethrow;
    }
    await sync.dropGroup(groupId);
  }
}

/// `expense.created` payload of [e] (docs/API.md); the series keys are always there (both null outside a series).
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
      'recurrenceId': e.recurrenceId,
      'occurrence': e.occurrence,
    };

/// What a series made from [e] repeats (docs/API.md 반복 지출 template): its `expense.created` payload without the
/// id, the date and the series keys. Receipts never repeat.
Map<String, dynamic> templateOf(Expense e) => expenseCreatedPayload(e)
  ..remove('expenseId')
  ..remove('date')
  ..remove('recurrenceId')
  ..remove('occurrence');

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
