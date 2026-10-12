import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/core/ids.dart';
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

final rent = Expense(
  id: 'x0',
  description: 'Rent',
  amount: 120000,
  currency: 'EUR',
  paidBy: 'm1',
  date: '2026-10-01',
  category: 'home.rent',
  shares: const [Share(memberId: 'm1', amount: 60000), Share(memberId: 'm2', amount: 60000)],
);

void main() {
  late AppDatabase db;
  late FakeApi api;
  late SyncService sync;
  late LocalWrites writes;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    api = FakeApi(db);
    sync = _Manual(db, api);
    writes = LocalWrites(db, sync);
    await db.upsertGroup(const GroupRow(
        kind: 'group', id: 'g1', name: 'Flat', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'm1', simplifyDebts: true));
    await db.into(db.members).insert(MembersCompanion.insert(id: 'm1', groupId: 'g1', name: 'Anna'));
    await db.into(db.members).insert(MembersCompanion.insert(id: 'm2', groupId: 'g1', name: 'Ben'));
  });
  tearDown(() => db.close());

  Future<List<(String, Map<String, dynamic>)>> outbox() async => [
        for (final o in await db.unsentOutbox('g1')) (o.type, (jsonDecode(o.payloadJson) as Map).cast<String, dynamic>())
      ];
  Future<GroupState> local() => sync.store.load('g1');

  /// Starts "Rent" monthly; returns the series id.
  Future<String> start() async {
    await writes.createExpense('g1', rent, repeat: 'monthly');
    return (await local()).recurrences.single.id;
  }

  test('a new repeating expense: recurrence.created, then expense.created as occurrence 0, the template is the '
      'payload without id, date and series keys', () async {
    final rid = await start();
    final [(t1, created), (t2, expense)] = await outbox();
    expect((t1, t2), ('recurrence.created', 'expense.created'));
    expect(created['recurrenceId'], rid);
    expect(created['frequency'], 'monthly');
    expect(created['startDate'], '2026-10-01');
    expect(created['timeZone'], matches(RegExp(r'^[+-]\d\d:\d\d$')));
    expect(created['template'], {...expense}..removeWhere((k, _) => ['expenseId', 'date', 'recurrenceId', 'occurrence'].contains(k)));
    expect((created['template'] as Map).keys, containsAll(['payers', 'refund', 'split', 'category', 'notes', 'shares']));
    expect((expense['recurrenceId'], expense['occurrence']), (rid, 0));

    final s = await local();
    expect((s.expense('x0')!.recurrenceId, s.expense('x0')!.occurrence), (rid, 0));
    expect(s.recurrence(rid)!.template['description'], 'Rent');
  });

  test('a plain expense always sends both series keys as null', () async {
    await writes.createExpense('g1', rent);
    final (type, p) = (await outbox()).single;
    expect(type, 'expense.created');
    expect(p, containsPair('recurrenceId', null));
    expect(p, containsPair('occurrence', null));
  });

  test('an edit without the series keys keeps the tag; updateRecurrence merges the changed fields into the template',
      () async {
    final rid = await start();
    await writes.updateExpense('g1', rent.copyWith(description: 'Rent + parking'), {'description': 'Rent + parking'});
    final shares = [const Share(memberId: 'm1', amount: 65000), const Share(memberId: 'm2', amount: 65000)];
    await writes.updateRecurrence('g1', rid, {'amount': 130000, 'shares': shares});
    await writes.updateRecurrence('g1', rid, {}); // nothing to send

    final s = await local();
    expect(s.expense('x0')!.recurrenceId, rid);
    expect(s.recurrence(rid)!.template['amount'], 130000);
    expect(s.recurrence(rid)!.template['shares'], [
      {'memberId': 'm1', 'amount': 65000},
      {'memberId': 'm2', 'amount': 65000}
    ]);
    expect(s.recurrence(rid)!.template['description'], 'Rent'); // not sent to the series
    final out = await outbox();
    expect(out.map((o) => o.$1), ['recurrence.created', 'expense.created', 'expense.updated', 'recurrence.updated']);
    expect(out.last.$2, {
      'recurrenceId': rid,
      'fields': {
        'amount': 130000,
        'shares': [
          {'memberId': 'm1', 'amount': 65000},
          {'memberId': 'm2', 'amount': 65000}
        ]
      }
    });
  });

  test('repeatFrom stops the old series, starts one on the expense date and moves the expense into it', () async {
    final old = await start();
    await db.delete(db.outbox).go();
    final moved = rent.copyWith(date: '2026-10-15', amount: 130000);
    await writes.repeatFrom('g1', moved, 'weekly', stop: old, fields: {'date': '2026-10-15'});

    final s = await local();
    final now = s.recurrences.last;
    expect(s.recurrence(old)!.deleted, isTrue);
    expect((now.frequency, now.startDate, now.deleted, now.template['amount']), ('weekly', '2026-10-15', false, 130000));
    expect((s.expense('x0')!.recurrenceId, s.expense('x0')!.occurrence, s.expense('x0')!.date), (now.id, 0, '2026-10-15'));
    final out = await outbox();
    expect(out.map((o) => o.$1), ['recurrence.deleted', 'recurrence.created', 'expense.updated']);
    expect(out[0].$2, {'recurrenceId': old});
    expect(out[2].$2, {
      'expenseId': 'x0',
      'fields': {'date': '2026-10-15', 'recurrenceId': now.id, 'occurrence': 0}
    });
  });

  test('stop, and delete and stop in one transaction', () async {
    final rid = await start();
    await db.delete(db.outbox).go();
    await writes.deleteExpense('g1', 'x0', stopRecurrence: rid);
    expect((await outbox()).map((o) => o.$1), ['expense.deleted', 'recurrence.deleted']);
    final s = await local();
    expect((s.expense('x0')!.deleted, s.expense('x0')!.recurrenceId, s.recurrence(rid)!.deleted), (true, rid, true));

    await db.delete(db.outbox).go();
    await writes.stopRecurrence('g1', rid);
    final (type, p) = (await outbox()).single;
    expect(type, 'recurrence.deleted');
    expect(p, {'recurrenceId': rid});
  });

  test('unsentOutbox keeps the written order when timestamps tie', () async {
    for (final id in ['c', 'a', 'b']) {
      await db.into(db.outbox).insert(OutboxCompanion.insert(
          clientId: id, groupId: 'g1', type: 't$id', payloadJson: '{}', createdAt: '2026-10-11T09:00:00Z'));
    }
    expect([for (final o in await db.unsentOutbox('g1')) o.clientId], ['c', 'a', 'b']);
  });

  test('nowIsoUtc always has six fraction digits, so a whole millisecond sorts before later microseconds', () {
    final whole = nowIsoUtc(DateTime.utc(2026, 10, 11, 9, 0, 0, 123));
    final later = nowIsoUtc(DateTime.utc(2026, 10, 11, 9, 0, 0, 123, 45));
    expect(whole, '2026-10-11T09:00:00.123000Z');
    expect(later, '2026-10-11T09:00:00.123045Z');
    expect(whole.compareTo(later), lessThan(0));
    expect(DateTime.parse(whole), DateTime.utc(2026, 10, 11, 9, 0, 0, 123));
  });

  test('the store keeps series in creation order with their templates, and the expense tags', () async {
    final s = GroupState(
      members: const [Member(id: 'm1', name: 'Anna')],
      expenses: [rent.copyWith(recurrenceId: 'r2', occurrence: 3)],
      recurrences: const [
        Recurrence(id: 'r2', frequency: 'yearly', startDate: '2026-02-28', timeZone: 'Europe/Rome', template: {
          'description': 'Insurance',
          'fxRateToDefault': null,
          'split': {'mode': 'equal'}
        }),
        Recurrence(
            id: 'r1', frequency: 'biweekly', startDate: '2026-10-01', timeZone: '+02:00', deleted: true, template: {}),
      ],
    );
    await sync.store.save('g1', s, 9);
    expect((await local()).toJson(), s.toJson());
  });

  test('sync folds pulled series and a repeat added by the server (no actor)', () async {
    api.events = [
      SyncEvent(seq: 1, clientId: 'e1', type: 'recurrence.created', payload: {
        'recurrenceId': 'r1',
        'frequency': 'monthly',
        'startDate': '2026-09-01',
        'timeZone': '+02:00',
        'template': {
          'description': 'Rent',
          'amount': 1000,
          'currency': 'EUR',
          'paidBy': 'm1',
          'shares': [
            {'memberId': 'm1', 'amount': 1000}
          ]
        },
      }),
      SyncEvent(seq: 2, clientId: 'e2', type: 'expense.created', createdAt: '2026-10-01T07:00:00Z', payload: {
        'expenseId': 'x1',
        'description': 'Rent',
        'amount': 1000,
        'currency': 'EUR',
        'paidBy': 'm1',
        'date': '2026-10-01',
        'recurrenceId': 'r1',
        'occurrence': 1,
        'shares': [
          {'memberId': 'm1', 'amount': 1000}
        ],
      }),
    ];
    await sync.sync('g1');
    final s = await local();
    expect(s.recurrence('r1')!.frequency, 'monthly');
    expect((s.expense('x1')!.recurrenceId, s.expense('x1')!.occurrence), ('r1', 1));
  });

  test('a refused series is named after its template; a limit reads as the series cap', () async {
    await start();
    final told = <String>[];
    sync.rejections.listen(told.add);
    var seq = 0;
    api.onPush = (_, events) {
      if (events.any((e) => e.type == 'recurrence.created')) {
        throw const ApiException(status: 409, code: 'LIMIT_EXCEEDED', message: 'no');
      }
      return PushResult(seqByClientId: {for (final e in events) e.clientId: ++seq}, latestSeq: seq);
    };
    api.snap = (
      group: const GroupDto(
          id: 'g1', name: 'Flat', defaultCurrency: 'EUR', inviteCode: 'ABC', latestSeq: 1, myMemberId: 'm1'),
      state: GroupState(members: const [Member(id: 'm1', name: 'Anna')], expenses: [rent]),
      latestSeq: 1,
    );
    await sync.sync('g1');
    await pumpEventQueue();
    // The expense went through on its own (the server dropped the unknown series): not "Couldn't save", which would
    // get it added twice.
    expect(told, ["“Rent” was saved but won't repeat: a group can have at most 100 repeating expenses"]);
    expect((await local()).recurrences, isEmpty); // rebuilt from the server: the expense stays, without a series
  });

  test('a series refused together with its first expense reads as not saved', () async {
    await start();
    final told = <String>[];
    sync.rejections.listen(told.add);
    api.onPush = (_, _) => throw const ApiException(status: 400, code: 'SUM_MISMATCH', message: 'no');
    api.snap = (
      group: const GroupDto(
          id: 'g1', name: 'Flat', defaultCurrency: 'EUR', inviteCode: 'ABC', latestSeq: 0, myMemberId: 'm1'),
      state: const GroupState(members: [Member(id: 'm1', name: 'Anna')]),
      latestSeq: 0,
    );
    await sync.sync('g1');
    await pumpEventQueue();
    expect(told, [
      "Couldn't save repeating “Rent”: the split doesn't add up",
      "Couldn't save the new expense “Rent”: the split doesn't add up",
    ]);
  });
}
