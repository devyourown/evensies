import 'dart:convert';

import 'package:drift/native.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/data/api/api_client.dart';
import 'package:evensies/data/api/dto.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/local_writes.dart';
import 'package:evensies/data/sync/sync_service.dart';
import 'package:evensies/domain/models.dart';

import 'fakes.dart';

/// Real sync, run only when the test calls it.
class _Manual extends SyncService {
  _Manual(AppDatabase db, FakeApi api) : super(db: db, api: api);
  @override
  void syncLater(String groupId) {}
}

Expense x(String id, int amount) => Expense(
  id: id,
  description: id,
  amount: amount,
  currency: 'EUR',
  paidBy: 'm1',
  date: '2026-10-11',
  shares: [Share(memberId: 'm1', amount: amount)],
);

void main() {
  setUpAll(() => Money.loadFromJson('{"decimals":{"EUR":2},"symbols":{"EUR":"€"}}'));
  late AppDatabase db;
  late FakeApi api;
  late SyncService sync;
  late LocalWrites writes;
  late List<String> told;
  const dto = GroupDto(
    id: 'g1',
    name: 'Rome',
    defaultCurrency: 'EUR',
    inviteCode: 'ABC',
    latestSeq: 5,
    myMemberId: 'm1',
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    api = FakeApi(db);
    sync = _Manual(db, api);
    writes = LocalWrites(db, sync);
    told = [];
    sync.rejections.listen(told.add);
    await db.upsertGroup(
      const GroupRow(kind: 'group', 
        id: 'g1',
        name: 'Rome',
        defaultCurrency: 'EUR',
        latestSeq: 2,
        myMemberId: 'm1',
        simplifyDebts: true,
      ),
    );
    await db.into(db.members).insert(MembersCompanion.insert(id: 'm1', groupId: 'g1', name: 'Anna'));
    await db.setLastSeq('g1', 2);
    for (final e in [x('x1', 100), x('x2', 200), x('x3', 300)]) {
      await writes.createExpense('g1', e);
    }
  });
  tearDown(() => db.close());

  String expenseOf(OutboundEvent e) => e.payload['expenseId'] as String;

  /// The server refuses x2 with [status]/[code] and takes the rest; [down] events can't be sent at all.
  void server({int status = 400, String code = 'PAYERS_SUM_MISMATCH', Set<String> down = const {}}) {
    var seq = 2;
    api.onPush = (_, events) {
      if (events.any((e) => expenseOf(e) == 'x2')) throw ApiException(status: status, code: code, message: 'no');
      if (events.any((e) => down.contains(expenseOf(e)))) throw FakeApi.offline;
      return PushResult(seqByClientId: {for (final e in events) e.clientId: ++seq}, latestSeq: seq);
    };
    api.snap = (
      group: dto,
      state: GroupState(
        members: const [Member(id: 'm1', name: 'Anna')],
        expenses: [x('x1', 100), x('x3', 300)],
      ),
      latestSeq: 5,
    );
  }

  Future<List<String>> localExpenses() async => [for (final e in (await sync.store.load('g1')).expenses) e.id];

  test('a refused batch is re-sent one by one: the bad event is dropped and told, the rest is stored', () async {
    server();
    await sync.sync('g1');
    expect(
      [for (final b in api.pushes) b.map(expenseOf).toList()],
      [
        ['x1', 'x2', 'x3'],
        ['x1'],
        ['x2'],
        ['x3'],
      ],
    );
    expect(await db.select(db.outbox).get(), isEmpty);
    expect(told, ["Couldn't save the new expense “x2”: the payers don't add up"]);
    expect(await localExpenses(), ['x1', 'x3']); // rebuilt from the snapshot: x2's optimistic row is gone
    expect(await db.lastSeq('g1'), 5);
    expect(sync.offline.value, isFalse);
  });

  test('a network error mid-way stops the pass; unsent events stay and are re-applied on the rebuilt state', () async {
    server(down: {'x3'});
    await expectLater(sync.sync('g1'), throwsA(isA<ApiException>()));
    expect([for (final o in await db.select(db.outbox).get()) jsonDecode(o.payloadJson)['expenseId']], ['x3']);
    expect(told, ["Couldn't save the new expense “x2”: the payers don't add up"]);
    expect(await localExpenses(), ['x1', 'x3']);
    expect(sync.offline.value, isTrue);
  });

  test('a 403 while the group still answers is a refusal of that event', () async {
    server(status: 403, code: 'FORBIDDEN');
    await sync.sync('g1');
    expect(told, ["Couldn't save the new expense “x2”: you're not allowed to make that change"]);
    expect(await localExpenses(), ['x1', 'x3']);
  });

  test('a 403 when I am out of the group drops its local data without a message', () async {
    server(status: 403, code: 'FORBIDDEN');
    api.groupStatus = 403;
    await sync.sync('g1');
    expect(await db.getGroup('g1'), isNull);
    expect(await db.select(db.outbox).get(), isEmpty);
    expect(await db.select(db.expenses).get(), isEmpty);
    expect(told, isEmpty);
    expect(sync.offline.value, isFalse);
  });

  test('a rejected row left by a crash is told and cleaned at the next sync', () async {
    server();
    final rows = await db.unsentOutbox('g1');
    await db.markRejected(rows[1].clientId, 'SUM_MISMATCH');
    api.onPush = (_, events) => PushResult(seqByClientId: {for (final e in events) e.clientId: 9}, latestSeq: 9);
    await sync.sync('g1');
    expect(api.pushes.single.map(expenseOf), ['x1', 'x3']); // never sent again
    expect(told, ["Couldn't save the new expense “x2”: the split doesn't add up"]);
    expect(await db.select(db.outbox).get(), isEmpty);
  });

  test('a 400 or 403 without the server\'s error body (proxy, captive portal) drops nothing', () async {
    api
      ..groupStatus = 403
      ..groupCode = 'NETWORK';
    for (final status in [400, 403]) {
      api.onPush = (_, _) => throw ApiException(status: status, code: 'NETWORK', message: 'blocked');
      await expectLater(sync.sync('g1'), throwsA(isA<ApiException>()));
      expect(api.pushes.last.length, 3, reason: '$status: no one-by-one pass');
    }
    expect(await db.getGroup('g1'), isNotNull);
    expect(await db.unsentOutbox('g1'), hasLength(3));
    expect(await localExpenses(), ['x1', 'x2', 'x3']);
    expect(told, isEmpty);
  });

  test('a long offline outbox goes up in batches the rate limit (120 a minute) can take', () async {
    for (var i = 4; i <= 150; i++) {
      await writes.createExpense('g1', x('x$i', i));
    }
    var seq = 2;
    api.onPush = (_, events) {
      if (events.length > 120) throw const ApiException(status: 429, code: 'RATE_LIMITED', message: 'slow down');
      return PushResult(seqByClientId: {for (final e in events) e.clientId: ++seq}, latestSeq: seq);
    };
    await sync.sync('g1');
    expect(api.pushes.map((b) => b.length), [100, 50]);
    expect(await db.select(db.outbox).get(), isEmpty);
  });

  test('a pulled currency change takes the server state: my unpushed expense must not lock it out locally', () async {
    // Anna switched the empty group to USD (seq 3) before my offline expenses reached the server (seq 4–6).
    var seq = 3;
    api
      ..onPush = ((_, events) => PushResult(seqByClientId: {for (final e in events) e.clientId: ++seq}, latestSeq: seq))
      ..events = [
        SyncEvent(seq: 3, clientId: 'e3', type: 'group.updated', payload: const {'defaultCurrency': 'USD'}),
      ]
      ..snap = (
        group: const GroupDto(
          id: 'g1',
          name: 'Rome',
          defaultCurrency: 'USD',
          inviteCode: 'ABC',
          latestSeq: 6,
          myMemberId: 'm1',
        ),
        state: GroupState(
          defaultCurrency: 'USD',
          members: const [Member(id: 'm1', name: 'Anna')],
          expenses: [x('x1', 100), x('x2', 200), x('x3', 300)],
        ),
        latestSeq: 6,
      );
    await sync.sync('g1');
    expect((await db.getGroup('g1'))!.defaultCurrency, 'USD');
    expect(await localExpenses(), ['x1', 'x2', 'x3']);
    expect(await db.lastSeq('g1'), 6);
  });

  test('unknown codes read "the server refused it"; receipts have their own reasons', () {
    expect(rejectionReason(AppLocalizationsEn(), 'VALIDATION'), 'the server refused it');
    expect(rejectionReason(AppLocalizationsEn(), 'ATTACHMENT_NOT_UPLOADED', 'attachment.added'), "the photo didn't upload");
    expect(rejectionReason(AppLocalizationsEn(), 'LIMIT_EXCEEDED', 'attachment.added'), 'an expense can have at most 10 receipts');
    expect(rejectionReason(AppLocalizationsEn(), 'LIMIT_EXCEEDED', 'member.added'), 'the group is full');
  });

  test('syncAll drops groups missing from GET /groups (left or removed elsewhere)', () async {
    await db
        .into(db.session)
        .insert(SessionCompanion.insert(accessToken: 'a', refreshToken: 'r', userId: 'u1', displayName: 'Anna'));
    api.groupIds = [];
    await sync.syncAll();
    expect(await db.getGroup('g1'), isNull);
    expect(await db.select(db.members).get(), isEmpty);
  });

  test("syncAll fixes the kind of a friend group stored before schema v6 (it read 'group')", () async {
    await db
        .into(db.session)
        .insert(SessionCompanion.insert(accessToken: 'a', refreshToken: 'r', userId: 'u1', displayName: 'Anna'));
    expect((await db.getGroup('g1'))!.kind, 'group');
    api.groupIds = ['g1'];
    api.groupKinds = {'g1': 'friend'};
    await sync.syncAll();
    expect((await db.getGroup('g1'))!.kind, 'friend');
    await sync.store.save('g1', await sync.store.load('g1'), 2); // a later sync keeps it
    expect((await db.getGroup('g1'))!.kind, 'friend');
  });

  testWidgets('offline: syncAll every 30 s until the server answers again, then stop', (t) async {
    final s = _CountingAll(db, api);
    final stop = s.retryWhileOffline();
    await t.pump(const Duration(seconds: 31));
    expect(s.alls, 0); // online: no timer
    s.offline.value = true;
    await t.pump(const Duration(seconds: 31));
    await t.pump(const Duration(seconds: 30));
    expect(s.alls, 2);
    s.offline.value = false;
    await t.pump(const Duration(seconds: 90));
    expect(s.alls, 2);
    s.offline.value = true;
    stop();
    await t.pump(const Duration(seconds: 90));
    expect(s.alls, 2);
  });

  group('leave', () {
    setUp(() async {
      api.onPush = (_, events) => PushResult(seqByClientId: {for (final e in events) e.clientId: 9}, latestSeq: 9);
      await db.delete(db.outbox).go();
    });

    test('syncs, sends member.removed for my member directly and forgets the group', () async {
      await writes.leaveGroup('g1');
      final sent = api.pushes.single.single;
      expect(
        [sent.type, sent.payload],
        [
          'member.removed',
          {'memberId': 'm1'},
        ],
      );
      expect(await db.getGroup('g1'), isNull);
      expect(await db.select(db.expenses).get(), isEmpty);
    });

    test('checks my balance again after the sync: a pulled expense I owe for blocks leaving', () async {
      api.events = [
        SyncEvent(seq: 3, clientId: 'e3', type: 'member.added', payload: const {'memberId': 'm2', 'name': 'Cara'}),
        SyncEvent(seq: 4, clientId: 'e4', type: 'expense.created', payload: {
          ...x('d1', 5000).toJson()..remove('id'),
          'expenseId': 'd1',
          'paidBy': 'm2',
          'payers': [
            {'memberId': 'm2', 'amount': 5000},
          ],
        }),
      ];
      await expectLater(
        writes.leaveGroup('g1'),
        throwsA(isA<LeaveException>().having((e) => e.message, 'message', 'You owe €50.00 · settle up first')),
      );
      expect(api.pushes, isEmpty);
      expect(await db.getGroup('g1'), isNotNull);
    });

    test('a live repeating expense with me in it blocks leaving: it would keep adding my share', () async {
      api.events = [
        SyncEvent(seq: 3, clientId: 'e3', type: 'member.added', payload: const {'memberId': 'm2', 'name': 'Cara'}),
        SyncEvent(seq: 4, clientId: 'e4', type: 'recurrence.created', payload: const {
          'recurrenceId': 'r1',
          'frequency': 'weekly',
          'startDate': '2026-10-01',
          'timeZone': '+00:00',
          'template': {
            'description': 'Gym',
            'amount': 3000,
            'currency': 'EUR',
            'paidBy': 'm2',
            'shares': [
              {'memberId': 'm1', 'amount': 1500},
              {'memberId': 'm2', 'amount': 1500},
            ],
          },
        }),
      ];
      await expectLater(
        writes.leaveGroup('g1'),
        throwsA(isA<LeaveException>().having((e) => e.message, 'message',
            "You're still in 1 repeating expense (Gym) · edit the latest one or stop it first")),
      );
      expect(api.pushes, isEmpty);
      expect(await db.getGroup('g1'), isNotNull);
    });

    test('needs a connection', () async {
      api.onPush = null;
      await writes.createExpense('g1', x('x4', 400)); // something to push, so sync goes online
      await expectLater(
        writes.leaveGroup('g1'),
        throwsA(isA<LeaveException>().having((e) => e.message, 'message', 'You need to be online to leave')),
      );
      expect(await db.getGroup('g1'), isNotNull);
    });
  });
}

class _CountingAll extends SyncService {
  _CountingAll(AppDatabase db, ApiClient api) : super(db: db, api: api);
  int alls = 0;
  @override
  Future<void> syncAll() async => alls++;
}
