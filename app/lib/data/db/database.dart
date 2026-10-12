import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../sync/event_types.dart';

part 'database.g.dart';

@DataClassName('GroupRow')
class Groups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get defaultCurrency => text()();
  TextColumn get inviteCode => text().nullable()();
  IntColumn get latestSeq => integer().withDefault(const Constant(0))();
  TextColumn get myMemberId => text().nullable()();
  BoolColumn get simplifyDebts => boolean().withDefault(const Constant(true))();
  /// SplitSpec JSON (docs/API.md), percent or shares only.
  TextColumn get defaultSplitJson => text().nullable()();
  /// `group` or `friend` (docs/API.md 친구): a friend group shows as a person, not in the Groups tab.
  TextColumn get kind => text().withDefault(const Constant('group'))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MemberRow')
class Members extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get name => text()();
  TextColumn get userId => text().nullable()();
  BoolColumn get removed => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ExpenseRow')
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get description => text()();
  IntColumn get amount => integer()();
  TextColumn get currency => text()();
  RealColumn get fxRateToDefault => real().nullable()();
  TextColumn get paidBy => text()();
  TextColumn get date => text()();
  TextColumn get category => text().nullable()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  BoolColumn get refund => boolean().withDefault(const Constant(false))();
  /// SplitSpec JSON (docs/API.md); null for an exact split.
  TextColumn get splitJson => text().nullable()();
  /// Deleted by a move: it counts in the other group now, so it can't be restored (docs/API.md 적용 규칙 13).
  BoolColumn get moved => boolean().withDefault(const Constant(false))();
  /// The repeating series and the number in it (docs/API.md 반복 지출); both null outside a series.
  TextColumn get recurrenceId => text().nullable()();
  IntColumn get occurrence => integer().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ExpenseShareRow')
class ExpenseShares extends Table {
  TextColumn get expenseId => text()();
  TextColumn get memberId => text()();
  IntColumn get amount => integer()();
  @override
  Set<Column> get primaryKey => {expenseId, memberId};
}

/// Who paid (for a refund: received) how much. `Expenses.paidBy` keeps the primary payer.
@DataClassName('ExpensePayerRow')
class ExpensePayers extends Table {
  TextColumn get expenseId => text()();
  TextColumn get memberId => text()();
  IntColumn get amount => integer()();
  @override
  Set<Column> get primaryKey => {expenseId, memberId};
}

@DataClassName('PaymentRow')
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get fromMember => text()();
  TextColumn get toMember => text()();
  IntColumn get amount => integer()();
  TextColumn get currency => text()();
  TextColumn get date => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('confirmed'))();
  /// Deleted by an edit (`replacedBy`): never restored (docs/API.md 적용 규칙 7).
  BoolColumn get replaced => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CommentRow')
class Comments extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  /// Exactly one of the two is set (Phase 6: comments on payments).
  TextColumn get expenseId => text().nullable()();
  TextColumn get paymentId => text().nullable()();
  TextColumn get authorMemberId => text()();
  TextColumn get body => text().named('text')();
  TextColumn get createdAt => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

/// Receipt photos on expenses (docs/API.md 영수증, rule 14), in attach order (rowid). The files are in ReceiptFiles.
@DataClassName('AttachmentRow')
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get expenseId => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

/// Repeating series (docs/API.md 반복 지출, rule 15), in creation order (rowid), stopped ones included.
@DataClassName('RecurrenceRow')
class Recurrences extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get frequency => text()();
  TextColumn get startDate => text()();
  TextColumn get timeZone => text()();
  /// The `expense.created` payload the server repeats, as JSON.
  TextColumn get templateJson => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

/// Receipts taken here and not uploaded yet: SyncService uploads them before it pushes their `attachment.added`.
@DataClassName('PendingUploadRow')
class PendingUploads extends Table {
  TextColumn get attachmentId => text()();
  TextColumn get groupId => text()();
  TextColumn get createdAt => text()();
  @override
  Set<Column> get primaryKey => {attachmentId};
}

/// Offline cache of server activity items (docs/API.md 활동·알림); [json] is the ActivityItem as received.
@DataClassName('ActivityRow')
class Activity extends Table {
  TextColumn get groupId => text()();
  IntColumn get seq => integer()();
  IntColumn get feedId => integer()();
  TextColumn get createdAt => text()();
  TextColumn get json => text()();
  @override
  Set<Column> get primaryKey => {groupId, seq};
}

@DataClassName('OutboxRow')
class Outbox extends Table {
  TextColumn get clientId => text()();
  TextColumn get groupId => text()();
  TextColumn get type => text()();
  TextColumn get payloadJson => text()();
  TextColumn get createdAt => text()();
  TextColumn get sentAt => text().nullable()();
  /// The server's error code once the event was refused on its own (docs/API.md 거부된 이벤트): never pushed or
  /// applied again; the row is deleted after the user was told.
  TextColumn get rejected => text().nullable()();
  @override
  Set<Column> get primaryKey => {clientId};
}

@DataClassName('SyncStateRow')
class SyncState extends Table {
  TextColumn get groupId => text()();
  IntColumn get lastSeq => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {groupId};
}

/// Single row (id = 1).
@DataClassName('SessionRow')
class Session extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get accessToken => text()();
  TextColumn get refreshToken => text()();
  TextColumn get userId => text()();
  TextColumn get displayName => text()();
  /// UserDto.homeCurrency (docs/API.md); null until the user picks one (the app then uses the region's currency).
  TextColumn get homeCurrency => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

/// Rate tables from `GET /fx` (docs/API.md 환율), keyed by the response's `date`. [ratesJson]: units per 1 EUR.
@DataClassName('FxDayRow')
class FxDays extends Table {
  TextColumn get day => text()();
  TextColumn get ratesJson => text()();
  TextColumn get fetchedAt => text()();
  @override
  Set<Column> get primaryKey => {day};
}

@DriftDatabase(tables: [
  Groups,
  Members,
  Expenses,
  ExpenseShares,
  ExpensePayers,
  Payments,
  Comments,
  Attachments,
  PendingUploads,
  Recurrences,
  Activity,
  Outbox,
  SyncState,
  Session,
  FxDays,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  AppDatabase.open() : super(driftDatabase(name: 'evensies'));

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.addColumn(payments, payments.status);
          if (from < 3) {
            await m.addColumn(expenses, expenses.notes);
            await m.createTable(comments);
            await m.createTable(activity);
            // Release 1 skipped comment.* / expense.restored and dropped notes while advancing lastSeq:
            // replay every group from seq 0 (SyncService folds from an empty state then).
            await delete(syncState).go();
          }
          if (from < 4) {
            await m.createTable(expensePayers);
            await m.addColumn(expenses, expenses.refund);
            await m.addColumn(expenses, expenses.splitJson);
            await m.addColumn(groups, groups.simplifyDebts);
            await m.addColumn(groups, groups.defaultSplitJson);
            await m.addColumn(outbox, outbox.rejected);
            // Balances stay right offline until the replay below brings the real payers.
            await customStatement(
                'INSERT INTO expense_payers (expense_id, member_id, amount) SELECT id, paid_by, amount FROM expenses');
            // Older code skipped payers, refund, split and the group settings in pulled events: replay every group.
            await delete(syncState).go();
          }
          if (from < 5) {
            // Event shapes are unchanged (docs/API.md 호환 4단계): no replay.
            await m.createTable(fxDays);
            await m.addColumn(session, session.homeCurrency);
          }
          if (from < 6) {
            // Old events carry no kind, paymentId or movedTo, and their defaults are right (docs/API.md 호환 6단계):
            // no replay.
            await m.addColumn(groups, groups.kind);
            // Rebuilds the table: expense_id becomes nullable. A database from before v3 got today's table above.
            if (from >= 3) await m.alterTable(TableMigration(comments, newColumns: [comments.paymentId]));
          }
          if (from < 7) {
            await m.addColumn(expenses, expenses.moved);
            // Moves pulled by schema 6 left no flag: replay every group (docs/API.md 호환 6단계).
            await delete(syncState).go();
          }
          if (from < 8) {
            await m.createTable(attachments);
            await m.createTable(pendingUploads);
            await m.addColumn(payments, payments.replaced);
            // Older code skipped attachment.* and payment.restored and read itemized splits as none: replay every
            // group (docs/API.md 호환 7단계).
            await delete(syncState).go();
          }
          if (from < 9) {
            await m.createTable(recurrences);
            await m.addColumn(expenses, expenses.recurrenceId);
            await m.addColumn(expenses, expenses.occurrence);
            // Older code skipped recurrence.* and dropped the series keys of expenses: replay every group
            // (docs/API.md 호환 8단계).
            await delete(syncState).go();
          }
        },
      );

  // --- session
  Stream<SessionRow?> watchSession() => select(session).watchSingleOrNull();
  Future<SessionRow?> getSession() => select(session).getSingleOrNull();
  Future<void> saveSession(SessionRow s) => into(session).insertOnConflictUpdate(s);
  Future<void> clearSession() => delete(session).go();

  /// Only the profile columns of [userId]'s session (null = keep): a token refresh landing meanwhile keeps its new
  /// tokens (a whole-row write would put the spent refresh token back and sign the user out).
  Future<void> updateProfile(String userId, {String? displayName, String? homeCurrency}) =>
      (update(session)..where((s) => s.userId.equals(userId))).write(SessionCompanion(
        displayName: displayName == null ? const Value.absent() : Value(displayName),
        homeCurrency: homeCurrency == null ? const Value.absent() : Value(homeCurrency),
      ));

  /// Only the token columns of [userId]'s session: a name saved meanwhile stays, and a session signed out meanwhile
  /// stays gone.
  Future<void> saveTokens(String userId, String accessToken, String refreshToken) =>
      (update(session)..where((s) => s.userId.equals(userId)))
          .write(SessionCompanion(accessToken: Value(accessToken), refreshToken: Value(refreshToken)));

  // --- groups
  /// Every group on this device, friend groups included (the Groups tab filters `kind == 'group'`).
  Stream<List<GroupRow>> watchGroups() => (select(groups)..orderBy([(g) => OrderingTerm.asc(g.name)])).watch();
  Stream<GroupRow?> watchGroup(String id) => (select(groups)..where((g) => g.id.equals(id))).watchSingleOrNull();
  Future<GroupRow?> getGroup(String id) => (select(groups)..where((g) => g.id.equals(id))).getSingleOrNull();
  /// Writes the whole row: an upsert of a data class would skip null columns, so a cleared default split would stay.
  Future<void> upsertGroup(GroupRow g) => into(groups).insert(g, mode: InsertMode.insertOrReplace);

  Stream<List<MemberRow>> watchMembers(String groupId) =>
      (select(members)..where((m) => m.groupId.equals(groupId))).watch();
  Stream<List<ExpenseRow>> watchExpenses(String groupId) => (select(expenses)
        ..where((e) => e.groupId.equals(groupId) & e.deleted.equals(false))
        ..orderBy([(e) => OrderingTerm.desc(e.date)]))
      .watch();
  Future<ExpenseRow?> getExpense(String id) => (select(expenses)..where((e) => e.id.equals(id))).getSingleOrNull();
  Future<List<ExpenseShareRow>> getShares(String expenseId) =>
      (select(expenseShares)..where((s) => s.expenseId.equals(expenseId))).get();

  // --- outbox / sync state
  /// In the order written: rows of one transaction can share a timestamp (an expense and its receipts).
  Future<List<OutboxRow>> unsentOutbox(String groupId) => (select(outbox)
        ..where((o) => o.groupId.equals(groupId) & o.sentAt.isNull() & o.rejected.isNull())
        ..orderBy([(o) => OrderingTerm.asc(o.createdAt), (o) => OrderingTerm.asc(o.rowId)]))
      .get();
  Future<List<OutboxRow>> rejectedOutbox(String groupId) =>
      (select(outbox)..where((o) => o.groupId.equals(groupId) & o.rejected.isNotNull())).get();
  Future<void> markRejected(String clientId, String code) =>
      (update(outbox)..where((o) => o.clientId.equals(clientId))).write(OutboxCompanion(rejected: Value(code)));
  /// Pushed events belong to the server log now. Keeping them would keep a deleted comment's text on this device.
  Future<void> dropSent(List<String> clientIds) => (delete(outbox)..where((o) => o.clientId.isIn(clientIds))).go();

  /// Cached feed rows of comments deleted since (docs/API.md 적용 규칙 8): their text must not stay on this device.
  Future<void> dropDeletedCommentActivity(String groupId) => customStatement(
      "DELETE FROM activity WHERE group_id = ? AND json_extract(json, '\$.commentId') IN "
      '(SELECT id FROM comments WHERE group_id = ? AND deleted = 1)',
      [groupId, groupId]);
  Future<int> lastSeq(String groupId) async =>
      (await (select(syncState)..where((s) => s.groupId.equals(groupId))).getSingleOrNull())?.lastSeq ?? 0;
  Future<void> setLastSeq(String groupId, int seq) =>
      into(syncState).insertOnConflictUpdate(SyncStateRow(groupId: groupId, lastSeq: seq));

  // --- repeating series
  Stream<List<RecurrenceRow>> watchRecurrences(String groupId) =>
      (select(recurrences)..where((r) => r.groupId.equals(groupId))).watch();

  // --- receipts
  /// expenseId → number of its receipts that aren't deleted (the list's receipt icon).
  Stream<Map<String, int>> watchAttachmentCounts(String groupId) =>
      (select(attachments)..where((a) => a.groupId.equals(groupId) & a.deleted.equals(false)))
          .watch()
          .map((rows) {
        final n = <String, int>{};
        for (final r in rows) {
          n[r.expenseId] = (n[r.expenseId] ?? 0) + 1;
        }
        return n;
      });
  Future<AttachmentRow?> getAttachment(String id) =>
      (select(attachments)..where((a) => a.id.equals(id))).getSingleOrNull();
  Future<List<PendingUploadRow>> pendingUploadsOf(String groupId) => (select(pendingUploads)
        ..where((p) => p.groupId.equals(groupId))
        ..orderBy([(p) => OrderingTerm.asc(p.createdAt), (p) => OrderingTerm.asc(p.rowId)]))
      .get();

  /// Receipt [ids] gone for good (refused, never uploaded, removed while pending): their rows, their pending uploads
  /// and their unsent `attachment.added`. Files are ReceiptFiles'.
  Future<void> dropReceipts(List<String> ids) => transaction(() async {
        if (ids.isEmpty) return;
        await (delete(attachments)..where((a) => a.id.isIn(ids))).go();
        await (delete(pendingUploads)..where((p) => p.attachmentId.isIn(ids))).go();
        for (final o in await (select(outbox)..where((o) => o.type.equals(EventTypes.attachmentAdded) & o.sentAt.isNull())).get()) {
          if (ids.contains((jsonDecode(o.payloadJson) as Map)['attachmentId'])) {
            await (delete(outbox)..where((x) => x.clientId.equals(o.clientId))).go();
          }
        }
      });

  /// The group's receipt ids, deleted and pending ones included (their files go with the group).
  Future<List<String>> receiptIds(String groupId) async => [
        for (final a in await (select(attachments)..where((a) => a.groupId.equals(groupId))).get()) a.id,
        for (final p in await (select(pendingUploads)..where((p) => p.groupId.equals(groupId))).get()) p.attachmentId,
      ];

  /// Callers delete the receipt files first ([receiptIds], ReceiptFiles.delete).
  Future<void> deleteGroupData(String groupId) => transaction(() async {
        final exps = await (select(expenses)..where((e) => e.groupId.equals(groupId))).get();
        await (delete(expenseShares)..where((s) => s.expenseId.isIn(exps.map((e) => e.id)))).go();
        await (delete(expensePayers)..where((s) => s.expenseId.isIn(exps.map((e) => e.id)))).go();
        await (delete(expenses)..where((e) => e.groupId.equals(groupId))).go();
        await (delete(payments)..where((p) => p.groupId.equals(groupId))).go();
        await (delete(comments)..where((c) => c.groupId.equals(groupId))).go();
        await (delete(attachments)..where((a) => a.groupId.equals(groupId))).go();
        await (delete(pendingUploads)..where((p) => p.groupId.equals(groupId))).go();
        await (delete(recurrences)..where((r) => r.groupId.equals(groupId))).go();
        await (delete(activity)..where((a) => a.groupId.equals(groupId))).go();
        await (delete(members)..where((m) => m.groupId.equals(groupId))).go();
        await (delete(outbox)..where((o) => o.groupId.equals(groupId))).go();
        await (delete(syncState)..where((s) => s.groupId.equals(groupId))).go();
        await (delete(groups)..where((g) => g.id.equals(groupId))).go();
      });

  Future<void> wipeAll() => transaction(() async {
        for (final t in allTables) {
          await delete(t).go();
        }
      });
}
