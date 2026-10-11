import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/data/api/dto.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/sync/apply_event.dart';
import 'package:evensies/data/sync/sync_service.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/domain/split.dart';

import 'fakes.dart';

SyncEvent ev(int seq, String type, Map<String, dynamic> payload) =>
    SyncEvent(seq: seq, clientId: 'e$seq', type: type, payload: payload);

final _log = [
  ev(1, 'member.added', {'memberId': 'm1', 'name': 'Anna', 'userId': null}),
  ev(2, 'expense.created', {
    'expenseId': 'x1',
    'description': 'Dinner',
    'amount': 2000,
    'currency': 'EUR',
    'fxRateToDefault': null,
    'paidBy': 'm1',
    'date': '2026-10-10',
    'category': null,
    'notes': 'Table 12',
    'shares': [
      {'memberId': 'm1', 'amount': 2000}
    ],
  }),
  ev(3, 'comment.added', {
    'commentId': 'c1',
    'expenseId': 'x1',
    'authorMemberId': 'm1',
    'text': 'Paid cash',
    'createdAt': '2026-10-11T09:00:00Z',
  }),
];

void main() {
  // Tables as release 1 created them (unchanged until schema 4).
  void v1Tables(dynamic raw) {
    raw.execute('CREATE TABLE "groups" ("id" TEXT NOT NULL, "name" TEXT NOT NULL, "default_currency" TEXT NOT NULL, '
        '"invite_code" TEXT NULL, "latest_seq" INTEGER NOT NULL DEFAULT 0, "my_member_id" TEXT NULL, PRIMARY KEY ("id"))');
    raw.execute('CREATE TABLE "outbox" ("client_id" TEXT NOT NULL, "group_id" TEXT NOT NULL, "type" TEXT NOT NULL, '
        '"payload_json" TEXT NOT NULL, "created_at" TEXT NOT NULL, "sent_at" TEXT NULL, PRIMARY KEY ("client_id"))');
    raw.execute('CREATE TABLE "sync_state" ("group_id" TEXT NOT NULL, "last_seq" INTEGER NOT NULL DEFAULT 0, '
        'PRIMARY KEY ("group_id"))');
    raw.execute('CREATE TABLE "session" ("id" INTEGER NOT NULL DEFAULT 1, "access_token" TEXT NOT NULL, '
        '"refresh_token" TEXT NOT NULL, "user_id" TEXT NOT NULL, "display_name" TEXT NOT NULL, PRIMARY KEY ("id"))');
    raw.execute("INSERT INTO groups (id, name, default_currency) VALUES ('g1', 'Rome', 'EUR')");
    raw.execute("INSERT INTO sync_state VALUES ('g1', 57)");
    raw.execute("INSERT INTO session VALUES (1, 'a', 'r', 'u1', 'Anna')");
  }

  // The comments table as schema 3 created it (expense_id NOT NULL, no payment_id).
  // Expenses as schema 4 left them (5 and 6 kept them).
  void v4Expenses(dynamic raw) {
    raw.execute('CREATE TABLE "expenses" ("id" TEXT NOT NULL, "group_id" TEXT NOT NULL, "description" TEXT NOT NULL, '
        '"amount" INTEGER NOT NULL, "currency" TEXT NOT NULL, "fx_rate_to_default" REAL NULL, "paid_by" TEXT NOT NULL, '
        '"date" TEXT NOT NULL, "category" TEXT NULL, "deleted" INTEGER NOT NULL DEFAULT 0 CHECK ("deleted" IN (0, 1)), '
        '"notes" TEXT NULL, "refund" INTEGER NOT NULL DEFAULT 0 CHECK ("refund" IN (0, 1)), "split_json" TEXT NULL, '
        'PRIMARY KEY ("id"))');
    raw.execute("INSERT INTO expenses (id, group_id, description, amount, currency, paid_by, date) "
        "VALUES ('x1', 'g1', 'Dinner', 2000, 'EUR', 'm1', '2026-10-10')");
  }

  void v3Comments(dynamic raw) => raw.execute('CREATE TABLE "comments" ("id" TEXT NOT NULL, "group_id" TEXT NOT NULL, '
      '"expense_id" TEXT NOT NULL, "author_member_id" TEXT NOT NULL, "text" TEXT NOT NULL, "created_at" TEXT NOT NULL, '
      '"deleted" INTEGER NOT NULL DEFAULT 0 CHECK ("deleted" IN (0, 1)), PRIMARY KEY ("id"))');

  test('schema 5 → 7 adds the group kind, payment comments and the moved flag, keeps comments, replays', () async {
    final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
      v1Tables(raw);
      v4Expenses(raw);
      v3Comments(raw);
      raw.execute('ALTER TABLE groups ADD COLUMN "simplify_debts" INTEGER NOT NULL DEFAULT 1 CHECK ("simplify_debts" IN (0, 1))');
      raw.execute('ALTER TABLE groups ADD COLUMN "default_split_json" TEXT NULL');
      raw.execute("INSERT INTO comments (id, group_id, expense_id, author_member_id, text, created_at) "
          "VALUES ('c1', 'g1', 'x1', 'm1', 'Paid cash', '2026-10-11T09:00:00Z')");
      raw.execute('PRAGMA user_version = 5');
    }));
    addTearDown(db.close);

    expect((await db.getGroup('g1'))!.kind, 'group');
    final c = await db.select(db.comments).getSingle();
    expect((c.id, c.expenseId, c.paymentId, c.body), ('c1', 'x1', null, 'Paid cash'));
    // expense_id is nullable now: a payment comment fits.
    await db.into(db.comments).insert(CommentsCompanion.insert(
        id: 'c2', groupId: 'g1', paymentId: const Value('p1'), authorMemberId: 'm1', body: 'Thanks', createdAt: 'z'));
    expect((await db.select(db.comments).get()).length, 2);
    expect((await db.getExpense('x1'))!.moved, isFalse);
    expect(await db.lastSeq('g1'), 0); // schema 6 stored no moved flag: replay
  });

  test('schema 4 → 5 adds the rate cache and the home currency, keeps the session', () async {
    final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
      v1Tables(raw);
      v4Expenses(raw);
      v3Comments(raw);
      raw.execute('PRAGMA user_version = 4');
    }));
    addTearDown(db.close);

    final s = (await db.getSession())!;
    expect((s.userId, s.displayName, s.homeCurrency), ('u1', 'Anna', null));
    expect(await db.select(db.fxDays).get(), isEmpty);
  });

  test('schema 2 → 4 keeps rows, adds notes/comments/activity and resets lastSeq', () async {
    final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
      v1Tables(raw);
      raw.execute('CREATE TABLE "expenses" ("id" TEXT NOT NULL, "group_id" TEXT NOT NULL, "description" TEXT NOT NULL, '
          '"amount" INTEGER NOT NULL, "currency" TEXT NOT NULL, "fx_rate_to_default" REAL NULL, "paid_by" TEXT NOT NULL, '
          '"date" TEXT NOT NULL, "category" TEXT NULL, "deleted" INTEGER NOT NULL DEFAULT 0 CHECK ("deleted" IN (0, 1)), '
          'PRIMARY KEY ("id"))');
      raw.execute("INSERT INTO expenses (id, group_id, description, amount, currency, paid_by, date) "
          "VALUES ('x1', 'g1', 'Dinner', 2000, 'EUR', 'm1', '2026-10-10')");
      raw.execute('PRAGMA user_version = 2');
    }));
    addTearDown(db.close);

    final x = await db.getExpense('x1');
    expect(x!.description, 'Dinner');
    expect(x.notes, isNull);
    expect(await db.lastSeq('g1'), 0);
    expect(await db.select(db.comments).get(), isEmpty);
    expect(await db.select(db.activity).get(), isEmpty);
  });

  test('schema 3 → 4 backfills payers from paid_by, defaults the new columns and resets lastSeq', () async {
    final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
      v1Tables(raw);
      raw.execute('CREATE TABLE "expenses" ("id" TEXT NOT NULL, "group_id" TEXT NOT NULL, "description" TEXT NOT NULL, '
          '"amount" INTEGER NOT NULL, "currency" TEXT NOT NULL, "fx_rate_to_default" REAL NULL, "paid_by" TEXT NOT NULL, '
          '"date" TEXT NOT NULL, "category" TEXT NULL, "deleted" INTEGER NOT NULL DEFAULT 0 CHECK ("deleted" IN (0, 1)), '
          '"notes" TEXT NULL, PRIMARY KEY ("id"))');
      v3Comments(raw);
      raw.execute("INSERT INTO expenses (id, group_id, description, amount, currency, paid_by, date) "
          "VALUES ('x1', 'g1', 'Dinner', 2000, 'EUR', 'm1', '2026-10-10')");
      raw.execute("INSERT INTO outbox VALUES ('c1', 'g1', 'expense.deleted', '{}', '2026-10-11T00:00:00Z', NULL)");
      raw.execute('PRAGMA user_version = 3');
    }));
    addTearDown(db.close);

    final p = await db.select(db.expensePayers).getSingle();
    expect((p.expenseId, p.memberId, p.amount), ('x1', 'm1', 2000));
    final x = (await db.getExpense('x1'))!;
    expect((x.refund, x.splitJson), (false, null));
    final g = (await db.getGroup('g1'))!;
    expect((g.simplifyDebts, g.defaultSplitJson), (true, null));
    expect((await db.unsentOutbox('g1')).single.rejected, isNull);
    expect(await db.lastSeq('g1'), 0);
  });

  group('pull', () {
    late AppDatabase db;
    late FakeApi api;
    late SyncService sync;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      api = FakeApi(db)..events = _log;
      sync = SyncService(db: db, api: api);
      await db.upsertGroup(const GroupRow(kind: 'group', id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 3, myMemberId: 'm1', simplifyDebts: true));
      // What release 1 stored for that log: no notes, no comment.
      await sync.store.save(
        'g1',
        GroupState(
          members: const [Member(id: 'm1', name: 'Anna')],
          expenses: [Expense.fromJson({..._log[1].payload, 'id': 'x1'}).copyWith(clearNotes: true)],
        ),
        3,
      );
    });
    tearDown(() => db.close());

    test('from lastSeq 0 folds the whole log from empty, so notes and comments come back', () async {
      await db.setLastSeq('g1', 0);
      await sync.sync('g1');
      final s = await sync.store.load('g1');
      expect(s.expense('x1')!.notes, 'Table 12');
      expect(s.comments.single.text, 'Paid cash');
      expect(await db.lastSeq('g1'), 3);
    });

    test('a pulled restore takes the server state, not my optimistic edit of the deleted row', () async {
      // Case A: offline I edited x1 to 3000 while Ben deleted it; the server ignored my update (rule 3),
      // then someone restored x1. My stored row still holds my edit.
      final mine = Expense.fromJson({..._log[1].payload, 'id': 'x1'}).copyWith(amount: 3000);
      await sync.store.save('g1', GroupState(members: const [Member(id: 'm1', name: 'Anna')], expenses: [mine]), 3);
      final server = Expense.fromJson({..._log[1].payload, 'id': 'x1'});
      api
        ..events = [
          ..._log,
          ev(4, 'expense.deleted', {'expenseId': 'x1'}),
          ev(5, 'expense.updated', {
            'expenseId': 'x1',
            'fields': {'amount': 3000}
          }),
          ev(6, 'expense.restored', {'expenseId': 'x1'}),
        ]
        ..snap = (
          group: const GroupDto(
              id: 'g1', name: 'Rome', defaultCurrency: 'EUR', inviteCode: 'ABC', latestSeq: 6, myMemberId: 'm1', simplifyDebts: true),
          state: GroupState(members: const [Member(id: 'm1', name: 'Anna')], expenses: [server]),
          latestSeq: 6,
        );
      await sync.sync('g1');
      final x = (await sync.store.load('g1')).expense('x1')!;
      expect(x.deleted, isFalse);
      expect(x.amount, 2000);
      expect(await db.lastSeq('g1'), 6);
    });

    test('a restore whose snapshot fails falls back to a full replay next time', () async {
      final mine = Expense.fromJson({..._log[1].payload, 'id': 'x1'}).copyWith(amount: 3000);
      await sync.store.save('g1', GroupState(members: const [Member(id: 'm1', name: 'Anna')], expenses: [mine]), 3);
      api.events = [..._log, ev(4, 'expense.restored', {'expenseId': 'x1'})]; // no snap: unreachable
      await expectLater(sync.sync('g1'), throwsA(isA<ApiException>()));
      expect(await db.lastSeq('g1'), 0);
      await sync.sync('g1');
      expect((await sync.store.load('g1')).expense('x1')!.amount, 2000);
    });

    test('a pulled comment.deleted blanks the text and drops its cached feed row', () async {
      await db.setLastSeq('g1', 0);
      api.events = [..._log, ev(4, 'comment.deleted', {'commentId': 'c1'})];
      Future<void> cache(int seq, Map<String, dynamic> item) => db.into(db.activity).insert(
          ActivityCompanion.insert(groupId: 'g1', seq: seq, feedId: seq, createdAt: '', json: jsonEncode(item)));
      await cache(3, {'kind': 'comment_added', 'commentId': 'c1', 'text': 'Paid cash'});
      await cache(2, {'kind': 'expense_added', 'commentId': null, 'expenseId': 'x1'});
      await sync.sync('g1');
      final c = (await sync.store.load('g1')).comments.single;
      expect((c.deleted, c.text), (true, ''));
      expect((await db.select(db.activity).get()).map((a) => a.seq), [2]);
    });

    test('from lastSeq > 0 folds over the stored state', () async {
      await db.setLastSeq('g1', 2);
      await sync.sync('g1');
      final s = await sync.store.load('g1');
      expect(s.expense('x1')!.notes, isNull); // not replayed
      expect(s.members.single.name, 'Anna');
      expect(s.comments.single.id, 'c1');
    });
  });

  test('created entities start live whatever "deleted" the payload carries (like the Kotlin applier)', () {
    var s = GroupState.empty;
    for (final e in [
      ev(1, 'expense.created', {..._log[1].payload, 'deleted': true}),
      ev(2, 'comment.added', {..._log[2].payload, 'deleted': 'x'}),
      ev(3, 'payment.created', {
        'paymentId': 'p1',
        'fromMember': 'm1',
        'toMember': 'm2',
        'amount': 500,
        'currency': 'EUR',
        'date': '2026-10-11',
        'deleted': true,
      }),
    ]) {
      s = applyEvent(s, e);
    }
    expect(s.expense('x1')!.deleted, isFalse);
    expect(s.comments.single.deleted, isFalse);
    expect(s.payment('p1')!.deleted, isFalse);
  });

  test('store round-trips notes and comment tombstones', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.upsertGroup(const GroupRow(kind: 'group', id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 0, simplifyDebts: true));
    final sync = SyncService(db: db, api: FakeApi(db));
    final s = GroupState(
      expenses: [Expense.fromJson({..._log[1].payload, 'id': 'x1'})],
      comments: const [Comment(id: 'c1', expenseId: 'x1', authorMemberId: 'm1', text: 't', createdAt: 'z', deleted: true)],
    );
    await sync.store.save('g1', s, 3);
    final back = await sync.store.load('g1');
    expect(back.toJson()['expenses'], s.toJson()['expenses']);
    expect(back.toJson()['comments'], s.toJson()['comments']);
    expect((await db.select(db.comments).getSingle()).deleted, isTrue);
    expect(back.expense('x1')!.notes, 'Table 12');
  });

  test('store round-trips payers, refund, split and the group settings; a pulled null clears the default split',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.upsertGroup(
        const GroupRow(kind: 'group', id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 0, simplifyDebts: true));
    final api = FakeApi(db);
    final sync = SyncService(db: db, api: api);
    final s = GroupState(
      name: 'Rome',
      defaultCurrency: 'EUR',
      simplifyDebts: false,
      defaultSplit: const SplitSpec(SplitMode.shares, {'m1': 2, 'm2': 1}),
      members: const [Member(id: 'm1', name: 'Anna'), Member(id: 'm2', name: 'Ben')],
      expenses: [
        Expense(
          id: 'x1',
          description: 'Hotel',
          amount: 3000,
          currency: 'EUR',
          payers: const [Share(memberId: 'm2', amount: 1000), Share(memberId: 'm1', amount: 2000)],
          date: '2026-10-11',
          refund: true,
          split: const SplitSpec(SplitMode.equal),
          shares: const [Share(memberId: 'm1', amount: 1500), Share(memberId: 'm2', amount: 1500)],
        ),
      ],
    );
    await sync.store.save('g1', s, 3);
    final back = await sync.store.load('g1');
    expect(back.groupJson(), s.groupJson());
    final x = back.expense('x1')!;
    expect(x.paidBy, 'm1');
    expect({for (final p in x.payers) p.memberId: p.amount}, {'m1': 2000, 'm2': 1000});
    expect((x.refund, x.split), (true, const SplitSpec(SplitMode.equal)));
    expect((await db.getExpense('x1'))!.paidBy, 'm1'); // the primary payer, for old readers

    api.events = [ev(4, 'group.updated', {'defaultSplit': null, 'simplifyDebts': true})];
    await sync.sync('g1');
    final g = (await db.getGroup('g1'))!;
    expect((g.defaultSplitJson, g.simplifyDebts), (null, true));
  });
}
