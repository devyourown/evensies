import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

@DataClassName('GroupRow')
class Groups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get defaultCurrency => text()();
  TextColumn get inviteCode => text().nullable()();
  IntColumn get latestSeq => integer().withDefault(const Constant(0))();
  TextColumn get myMemberId => text().nullable()();
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
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CommentRow')
class Comments extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get expenseId => text()();
  TextColumn get authorMemberId => text()();
  TextColumn get body => text().named('text')();
  TextColumn get createdAt => text()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
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
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
    tables: [Groups, Members, Expenses, ExpenseShares, Payments, Comments, Activity, Outbox, SyncState, Session])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);
  AppDatabase.open() : super(driftDatabase(name: 'evensies'));

  @override
  int get schemaVersion => 3;

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
        },
      );

  // --- session
  Stream<SessionRow?> watchSession() => select(session).watchSingleOrNull();
  Future<SessionRow?> getSession() => select(session).getSingleOrNull();
  Future<void> saveSession(SessionRow s) => into(session).insertOnConflictUpdate(s);
  Future<void> clearSession() => delete(session).go();

  // --- groups
  Stream<List<GroupRow>> watchGroups() => (select(groups)..orderBy([(g) => OrderingTerm.asc(g.name)])).watch();
  Stream<GroupRow?> watchGroup(String id) => (select(groups)..where((g) => g.id.equals(id))).watchSingleOrNull();
  Future<GroupRow?> getGroup(String id) => (select(groups)..where((g) => g.id.equals(id))).getSingleOrNull();
  Future<void> upsertGroup(GroupRow g) => into(groups).insertOnConflictUpdate(g);

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
  Future<List<OutboxRow>> unsentOutbox(String groupId) =>
      (select(outbox)..where((o) => o.groupId.equals(groupId) & o.sentAt.isNull())..orderBy([(o) => OrderingTerm.asc(o.createdAt)])).get();
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

  Future<void> deleteGroupData(String groupId) => transaction(() async {
        final exps = await (select(expenses)..where((e) => e.groupId.equals(groupId))).get();
        await (delete(expenseShares)..where((s) => s.expenseId.isIn(exps.map((e) => e.id)))).go();
        await (delete(expenses)..where((e) => e.groupId.equals(groupId))).go();
        await (delete(payments)..where((p) => p.groupId.equals(groupId))).go();
        await (delete(comments)..where((c) => c.groupId.equals(groupId))).go();
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
