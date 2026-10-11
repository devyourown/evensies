import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/models.dart';
import '../db/database.dart';

/// GroupState ⇄ drift rows. `save` rewrites the group's rows wholesale.
/// ponytail: full rewrite per sync; diff rows if groups get thousands of expenses.
class GroupStateStore {
  final AppDatabase db;
  GroupStateStore(this.db);

  Future<GroupState> load(String groupId) async {
    final g = await db.getGroup(groupId);
    final ms = await (db.select(db.members)..where((m) => m.groupId.equals(groupId))).get();
    final xs = await (db.select(db.expenses)..where((e) => e.groupId.equals(groupId))).get();
    // Rows come back in insert order (= the order sent), not in primary-key order: payers keep the order sent.
    final shares = await (db.select(db.expenseShares)
          ..where((s) => s.expenseId.isIn(xs.map((e) => e.id)))
          ..orderBy([(s) => OrderingTerm.asc(s.rowId)]))
        .get();
    final payers = await (db.select(db.expensePayers)
          ..where((s) => s.expenseId.isIn(xs.map((e) => e.id)))
          ..orderBy([(s) => OrderingTerm.asc(s.rowId)]))
        .get();
    final ps = await (db.select(db.payments)..where((p) => p.groupId.equals(groupId))).get();
    final cs = await (db.select(db.comments)..where((c) => c.groupId.equals(groupId))).get();
    return GroupState(
      name: g?.name,
      defaultCurrency: g?.defaultCurrency,
      simplifyDebts: g?.simplifyDebts ?? true,
      defaultSplit: splitFromJson(g?.defaultSplitJson),
      members: [for (final m in ms) Member(id: m.id, name: m.name, userId: m.userId, removed: m.removed)],
      expenses: [
        for (final e in xs)
          Expense(
            id: e.id,
            description: e.description,
            amount: e.amount,
            currency: e.currency,
            fxRateToDefault: e.fxRateToDefault,
            paidBy: e.paidBy, // rows written without payers (tests, or before the v4 backfill)
            payers: [
              for (final p in payers.where((p) => p.expenseId == e.id)) Share(memberId: p.memberId, amount: p.amount)
            ].nonEmpty,
            date: e.date,
            category: e.category,
            notes: e.notes,
            deleted: e.deleted,
            refund: e.refund,
            split: splitFromJson(e.splitJson),
            shares: [
              for (final s in shares.where((s) => s.expenseId == e.id)) Share(memberId: s.memberId, amount: s.amount)
            ],
          ),
      ],
      payments: [
        for (final p in ps)
          Payment(
            id: p.id,
            fromMember: p.fromMember,
            toMember: p.toMember,
            amount: p.amount,
            currency: p.currency,
            date: p.date,
            deleted: p.deleted,
            status: p.status,
          ),
      ],
      comments: [
        for (final c in cs)
          Comment(
            id: c.id,
            expenseId: c.expenseId,
            authorMemberId: c.authorMemberId,
            text: c.body,
            createdAt: c.createdAt,
            deleted: c.deleted,
          ),
      ],
    );
  }

  Future<void> save(String groupId, GroupState s, int latestSeq) => db.transaction(() async {
        final g = await db.getGroup(groupId);
        if (g != null) {
          await db.upsertGroup(g.copyWith(
            name: s.name ?? g.name,
            defaultCurrency: s.defaultCurrency ?? g.defaultCurrency,
            simplifyDebts: s.simplifyDebts,
            defaultSplitJson: Value(splitToJson(s.defaultSplit)),
            latestSeq: latestSeq,
          ));
        }
        final oldExps = await (db.select(db.expenses)..where((e) => e.groupId.equals(groupId))).get();
        await (db.delete(db.expenseShares)..where((x) => x.expenseId.isIn(oldExps.map((e) => e.id)))).go();
        await (db.delete(db.expensePayers)..where((x) => x.expenseId.isIn(oldExps.map((e) => e.id)))).go();
        await (db.delete(db.expenses)..where((e) => e.groupId.equals(groupId))).go();
        await (db.delete(db.payments)..where((p) => p.groupId.equals(groupId))).go();
        await (db.delete(db.comments)..where((c) => c.groupId.equals(groupId))).go();
        await (db.delete(db.members)..where((m) => m.groupId.equals(groupId))).go();
        await db.batch((b) {
          b.insertAll(db.members, [
            for (final m in s.members)
              MembersCompanion.insert(
                  id: m.id, groupId: groupId, name: m.name, userId: Value(m.userId), removed: Value(m.removed)),
          ]);
          b.insertAll(db.expenses, [for (final e in s.expenses) expenseRow(groupId, e)]);
          b.insertAll(db.expenseShares, [
            for (final e in s.expenses)
              for (final sh in e.shares)
                ExpenseSharesCompanion.insert(expenseId: e.id, memberId: sh.memberId, amount: sh.amount),
          ]);
          b.insertAll(db.expensePayers, [
            for (final e in s.expenses)
              for (final p in e.payers)
                ExpensePayersCompanion.insert(expenseId: e.id, memberId: p.memberId, amount: p.amount),
          ]);
          b.insertAll(db.payments, [
            for (final p in s.payments)
              PaymentsCompanion.insert(
                id: p.id,
                groupId: groupId,
                fromMember: p.fromMember,
                toMember: p.toMember,
                amount: p.amount,
                currency: p.currency,
                date: p.date,
                deleted: Value(p.deleted),
                status: Value(p.status),
              ),
          ]);
          b.insertAll(db.comments, [
            for (final c in s.comments)
              CommentsCompanion.insert(
                id: c.id,
                groupId: groupId,
                expenseId: c.expenseId,
                authorMemberId: c.authorMemberId,
                body: c.text,
                createdAt: c.createdAt,
                deleted: Value(c.deleted),
              ),
          ]);
        });
        await db.dropDeletedCommentActivity(groupId);
        await db.setLastSeq(groupId, latestSeq);
      });
}

/// The drift row of [e] (payers and shares live in their own tables).
ExpensesCompanion expenseRow(String groupId, Expense e) => ExpensesCompanion.insert(
      id: e.id,
      groupId: groupId,
      description: e.description,
      amount: e.amount,
      currency: e.currency,
      fxRateToDefault: Value(e.fxRateToDefault),
      paidBy: e.paidBy,
      date: e.date,
      category: Value(e.category),
      notes: Value(e.notes),
      deleted: Value(e.deleted),
      refund: Value(e.refund),
      splitJson: Value(splitToJson(e.split)),
    );

SplitSpec? splitFromJson(String? json) => json == null ? null : SplitSpec.fromJson(jsonDecode(json));
String? splitToJson(SplitSpec? s) => s == null ? null : jsonEncode(s.toJson());

extension<T> on List<T> {
  List<T>? get nonEmpty => isEmpty ? null : this;
}
