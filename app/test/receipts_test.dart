import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:evensies/data/api/dto.dart';
import 'package:evensies/data/blob_store.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/local_writes.dart';
import 'package:evensies/data/receipts.dart';
import 'package:evensies/data/sync/group_state_store.dart';
import 'package:evensies/domain/itemized.dart';
import 'package:evensies/domain/models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

SyncEvent ev(int seq, String type, Map<String, dynamic> payload) =>
    SyncEvent(seq: seq, clientId: 'e$seq', type: type, payload: payload);

/// A server whose receipts are all gone (removed by someone else).
class _Api404 extends FakeApi {
  _Api404(super.db);
  @override
  Future<Uint8List> attachment(String groupId, String attachmentId, {bool thumb = false}) async =>
      throw const ApiException(status: 404, code: 'NOT_FOUND', message: 'No such receipt');
}

/// A second browser tab: its memory has none of tab A's photos, which stay claimed while tab A is open.
class _OtherTab extends ReceiptFiles {
  _OtherTab(super.api, {super.supportDir, super.cacheDir});
  bool otherTabOpen = true;
  @override
  Future<bool> inAnotherTab(String id) async => otherTabOpen;
}

/// Receipts end to end on this device (docs/API.md, Receipts): local writes, the upload before the push, the hold-back, the
/// files, and what a refusal removes.
void main() {
  late AppDatabase db;
  late FakeApi api;
  late NoSync sync;
  late LocalWrites w;
  late ReceiptFiles files;
  late Directory tmp;

  const dinner = {
    'expenseId': 'x1',
    'description': 'Dinner',
    'amount': 1000,
    'currency': 'EUR',
    'fxRateToDefault': null,
    'paidBy': 'm1',
    'date': '2026-10-11',
    'category': null,
    'shares': [
      {'memberId': 'm1', 'amount': 1000}
    ],
  };

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    api = FakeApi(db);
    tmp = Directory.systemTemp.createTempSync('receipts');
    files = ReceiptFiles(api, supportDir: () async => '${tmp.path}/support', cacheDir: () async => '${tmp.path}/cache');
    sync = NoSync(db, api, files);
    w = LocalWrites(db, sync);
    await db.upsertGroup(const GroupRow(
        type: 'other', deleted: false, kind: 'group', id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 2, myMemberId: 'm1', simplifyDebts: true));
    await GroupStateStore(db).save(
        'g1',
        GroupState(members: const [Member(id: 'm1', name: 'Anna')], expenses: [Expense.fromJson({...dinner, 'id': 'x1'})]),
        2);
    api.onPush = (_, events) => PushResult(seqByClientId: {for (final e in events) e.clientId: 3}, latestSeq: 3);
  });
  tearDown(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  /// A prepared photo, as ReceiptFiles.prepare leaves it.
  Future<void> photo(String id) async {
    for (final thumb in [false, true]) {
      await files.store.write(BlobArea.pending, '$id${thumb ? '_thumb' : ''}.jpg', [0xff, 0xd8, thumb ? 1 : 2]);
    }
  }

  Future<List<String>> outboxTypes() async => [
        for (final o in await (db.select(db.outbox)..orderBy([(o) => OrderingTerm.asc(o.rowId)])).get()) o.type,
      ];

  test('a pending upload holds back its attachment.added and what comes after; once uploaded, both go', () async {
    await w.updateExpense('g1', Expense.fromJson({...dinner, 'id': 'x1', 'description': 'Dinner out'}),
        {'description': 'Dinner out'});
    await photo('a1');
    await w.attachReceipt('g1', 'x1', 'a1');
    await w.addComment('g1', 'Mine was the pasta', expenseId: 'x1');
    expect((await GroupStateStore(db).load('g1')).receiptsOf('x1').single.id, 'a1'); // shown at once

    await sync.sync('g1'); // the upload fails (offline): only the update goes
    expect(api.uploads, [('g1', 'a1')]);
    expect(api.pushes.map((b) => [for (final e in b) e.type]), [
      ['expense.updated'],
    ]);
    expect(await outboxTypes(), ['attachment.added', 'comment.added']);
    expect(await files.pending('a1'), isNotNull);

    api.onUpload = (_, _) {}; // back online: uploaded, then pushed in order
    await sync.sync('g1');
    expect(api.pushes.last.map((e) => (e.type, e.payload['attachmentId'])), [
      ('attachment.added', 'a1'),
      ('comment.added', null),
    ]);
    expect(api.pushes.last.first.payload, {'attachmentId': 'a1', 'expenseId': 'x1'});
    expect(await outboxTypes(), isEmpty);
    expect(await db.pendingUploadsOf('g1'), isEmpty);
    expect(await files.pending('a1'), isNull);
    expect(await files.cached('a1', thumb: true), [0xff, 0xd8, 1]);
  });

  test('a missing photo file drops the receipt and its event without asking the server', () async {
    await w.attachReceipt('g1', 'x1', 'a1'); // no files
    await sync.sync('g1');
    expect(api.uploads, isEmpty);
    expect(await outboxTypes(), isEmpty);
    expect(await db.select(db.attachments).get(), isEmpty);
  });

  test("the web: another tab's sync skips a receipt whose photo is in an open tab's memory, and drops it once that tab "
      'closes', () async {
    // Tab A picked the photo (its memory = its own folders); tab B shares the database but not the photo.
    final tabB = _OtherTab(api, supportDir: () async => '${tmp.path}/b/support', cacheDir: () async => '${tmp.path}/b/cache');
    final syncB = NoSync(db, api, tabB);
    await photo('a1');
    await w.attachReceipt('g1', 'x1', 'a1');
    await w.addComment('g1', 'Mine was the pasta', expenseId: 'x1');
    await sync.sync('g1'); // tab A: the upload fails (offline), both stay

    await syncB.sync('g1'); // tab A is still open: B neither uploads nor drops, and holds back the events after it
    expect(api.uploads, [('g1', 'a1')]);
    expect(await outboxTypes(), ['attachment.added', 'comment.added']);
    expect(await db.pendingUploadsOf('g1'), hasLength(1));

    tabB.otherTabOpen = false; // tab A closed: its photo is gone with it
    await syncB.sync('g1');
    expect(api.uploads, [('g1', 'a1')]);
    expect(await outboxTypes(), isEmpty);
    expect(await db.select(db.attachments).get(), isEmpty);
  });

  test('removing a receipt still waiting to upload sends nothing; removing an uploaded one sends its expense', () async {
    await photo('a1');
    await w.attachReceipt('g1', 'x1', 'a1');
    await w.removeReceipt('g1', 'a1');
    expect(await outboxTypes(), isEmpty);
    expect(await db.select(db.attachments).get(), isEmpty);
    expect(await db.pendingUploadsOf('g1'), isEmpty);
    expect(await files.pending('a1'), isNull);

    // Uploaded earlier: only the cached copy is here.
    await db.into(db.attachments).insert(AttachmentsCompanion.insert(id: 'a2', groupId: 'g1', expenseId: 'x1'));
    await files.store.write(BlobArea.cache, 'a2.jpg', [1]);
    await w.removeReceipt('g1', 'a2');
    final o = (await db.select(db.outbox).get()).single;
    expect(o.type, 'attachment.deleted');
    expect(jsonDecode(o.payloadJson), {'attachmentId': 'a2', 'expenseId': 'x1'});
    expect((await db.getAttachment('a2'))!.deleted, isTrue);
    expect(await files.cached('a2'), isNull);
  });

  test('a refused photo (400) is dropped with its event, and the user is told', () async {
    final told = <String>[];
    final sub = sync.rejections.listen(told.add);
    await photo('a1');
    await w.attachReceipt('g1', 'x1', 'a1');
    api.onUpload = (_, _) => throw const ApiException(status: 400, code: 'NOT_JPEG', message: 'no');
    await sync.sync('g1');
    await pumpEventQueue();
    expect(told, ["Couldn't save the receipt on “Dinner”: the server refused it"]);
    expect(await outboxTypes(), isEmpty);
    expect(await db.select(db.attachments).get(), isEmpty);
    expect(await files.pending('a1'), isNull);
    await sub.cancel();
  });

  test('a refused attachment.added goes with its row and files; the reasons are the receipt ones', () async {
    final told = <String>[];
    final sub = sync.rejections.listen(told.add);
    await photo('a1');
    await w.attachReceipt('g1', 'x1', 'a1');
    api
      ..onUpload = (_, _) {}
      ..onPush = (_, _) {
        throw const ApiException(status: 409, code: 'LIMIT_EXCEEDED', message: 'full');
      }
      ..snap = (
        group: const GroupDto(id: 'g1', name: 'Rome', defaultCurrency: 'EUR', inviteCode: 'ABC', latestSeq: 2, myMemberId: 'm1'),
        state: GroupState(members: const [Member(id: 'm1', name: 'Anna')], expenses: [Expense.fromJson({...dinner, 'id': 'x1'})]),
        latestSeq: 2,
      );
    await sync.sync('g1');
    await pumpEventQueue();
    expect(told, ["Couldn't save the receipt on “Dinner”: an expense can have at most 10 receipts"]);
    expect(await db.select(db.attachments).get(), isEmpty);
    expect(await files.cached('a1'), isNull);
    expect(await outboxTypes(), isEmpty);
    await sub.cancel();
  });

  test('a replay from seq 0 keeps the receipt of an event still held back', () async {
    await db.setLastSeq('g1', 0);
    await photo('a1');
    await w.attachReceipt('g1', 'x1', 'a1');
    api.events = [
      ev(1, 'member.added', {'memberId': 'm1', 'name': 'Anna', 'userId': null}),
      ev(2, 'expense.created', dinner),
    ];
    await sync.sync('g1'); // upload offline: held back
    expect((await GroupStateStore(db).load('g1')).receiptsOf('x1').map((a) => a.id), ['a1']);
    expect(await db.lastSeq('g1'), 2);
  });

  test('the store round-trips receipts, a replaced payment and an itemized split', () async {
    final s = GroupState(
      members: const [Member(id: 'm1', name: 'Anna'), Member(id: 'm2', name: 'Ben')],
      expenses: [
        Expense.fromJson({...dinner, 'id': 'x1'}).copyWith(
          split: const SplitSpec.itemized(ItemizedBill(lines: [
            ItemLine(name: 'Pasta', amount: 1000, memberIds: ['m2', 'm1'])
          ], tip: 0)),
        ),
      ],
      payments: const [
        Payment(id: 'p1', fromMember: 'm2', toMember: 'm1', amount: 500, currency: 'EUR', date: 'd', deleted: true, replaced: true),
      ],
      attachments: const [Attachment(id: 'a2', expenseId: 'x1'), Attachment(id: 'a1', expenseId: 'x1', deleted: true)],
    );
    await GroupStateStore(db).save('g1', s, 5);
    final back = await GroupStateStore(db).load('g1');
    expect(back.toJson()['attachments'], s.toJson()['attachments']); // attach order kept
    expect(back.payment('p1')!.replaced, isTrue);
    expect(back.expense('x1')!.split, s.expense('x1')!.split);
  });

  test('a receipt shows from the cache, else the pending file, else a download into the cache', () async {
    await expectLater(files.file('g1', 'a1'), throwsA(isA<ApiException>())); // nowhere, offline
    api.downloads['a1'] = Uint8List.fromList([7]);
    expect(await files.file('g1', 'a1'), [7]);
    expect(await files.cached('a1'), [7]); // kept
    await photo('a3');
    expect(await files.file('g1', 'a3', thumb: true), [0xff, 0xd8, 1]);
    expect(await files.cached('a3', thumb: true), isNull); // the pending one, not a copy
  });

  test("a receipt someone else removed goes from this device's cache too", () async {
    for (final thumb in [false, true]) {
      await files.store.write(BlobArea.cache, 'a1${thumb ? '_thumb' : ''}.jpg', [1]);
    }
    await GroupStateStore(db).save(
        'g1',
        GroupState(
          members: const [Member(id: 'm1', name: 'Anna')],
          expenses: [Expense.fromJson({...dinner, 'id': 'x1'})],
          attachments: const [Attachment(id: 'a1', expenseId: 'x1')],
        ),
        3);
    api.events = [
      ev(1, 'member.added', {'memberId': 'm1', 'name': 'Anna', 'userId': null}),
      ev(2, 'expense.created', dinner),
      ev(3, 'attachment.added', {'attachmentId': 'a1', 'expenseId': 'x1'}),
      ev(4, 'attachment.deleted', {'attachmentId': 'a1'}),
    ];
    await sync.sync('g1');
    expect((await GroupStateStore(db).load('g1')).attachment('a1')!.deleted, isTrue);
    for (final thumb in [false, true]) {
      expect(await files.cached('a1', thumb: thumb), isNull);
    }
  });

  test('moving an expense uploads its receipts to the other group under new ids and attaches them in the push',
      () async {
    await photo('a1'); // still pending here: the move reads the local file
    final moved = Expense.fromJson({...dinner, 'id': 'y1'});
    // The source's own upload finishes while the move uploads: its pending files move to the cache meanwhile.
    api.onUpload = (_, _) {
      for (final t in ['', '_thumb']) {
        Directory('${tmp.path}/cache/attachments').createSync(recursive: true);
        File('${tmp.path}/support/pending_attachments/a1$t.jpg').renameSync('${tmp.path}/cache/attachments/a1$t.jpg');
      }
    };
    const ids = {'a1': (id: 'b1', clientId: 'c-b1')};
    await w.moveExpense('g1', Expense.fromJson({...dinner, 'id': 'x1'}), 'g2', moved, clientId: 'c-y1', receipts: ids);
    expect(api.uploads, [('g2', 'b1')]);
    expect(api.pushes.single.map((e) => (e.type, e.clientId, e.payload['attachmentId'], e.payload['expenseId'])), [
      ('expense.created', 'c-y1', null, 'y1'),
      ('attachment.added', 'c-b1', 'b1', 'y1'),
    ]);
    expect(await files.cached('b1'), [0xff, 0xd8, 2]); // shown there without a download
    expect(await outboxTypes(), ['expense.deleted']);

    // A retry (the answer was lost) sends the same clientIds, so the server stores nothing twice.
    api.onUpload = (_, _) {};
    await w.moveExpense('g1', Expense.fromJson({...dinner, 'id': 'x1'}), 'g2', moved,
        clientId: 'c-y1', retry: true, receipts: ids);
    expect([for (final e in api.pushes.last) if (e.type == 'attachment.added') e.clientId], ['c-b1']);
  });

  test('a move leaves out a receipt the server no longer has (404), and still moves the expense', () async {
    final gone = _Api404(db)..onPush = api.onPush;
    final goneFiles =
        ReceiptFiles(gone, supportDir: () async => '${tmp.path}/support', cacheDir: () async => '${tmp.path}/cache');
    await LocalWrites(db, NoSync(db, gone, goneFiles)).moveExpense(
        'g1', Expense.fromJson({...dinner, 'id': 'x1'}), 'g2', Expense.fromJson({...dinner, 'id': 'y1'}),
        receipts: {'a9': (id: 'b9', clientId: 'c-b9')});
    expect(gone.uploads, isEmpty);
    expect(gone.pushes.single.map((e) => e.type), ['expense.created']);
    expect(await outboxTypes(), ['expense.deleted']);
  });

  test('recognizeLines asks the platform (Vision on iOS, ML Kit on Android) for the lines and their boxes', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('evensies/ocr');
    final asked = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (c) async {
      asked.add(c);
      return [
        {'text': 'Burger', 'left': 20, 'top': 40.5, 'right': 100, 'bottom': 70},
      ];
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    final lines = await recognizeLines('/tmp/r.jpg', script: 'korean');
    expect(asked.single.method, 'recognize');
    expect(asked.single.arguments, {'path': '/tmp/r.jpg', 'script': 'korean'});
    expect((lines.single.text, lines.single.top, lines.single.right), ('Burger', 40.5, 100.0));
  });

  test('recognizeCjk: of the Korean and the Japanese reading, the one that adds up to its total; null if no items',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('evensies/ocr');
    final asked = <String>[];
    // The Korean model reads a Japanese receipt as Hangul noise: items, but not adding up to the "total".
    var readings = {
      'korean': ['카페 100', '하하 200', '합계 999'],
      'japanese': ['バナナ 198', 'ヨーグルト 256', '合計 454'],
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (c) async {
      final script = (c.arguments as Map)['script'] as String;
      asked.add(script);
      return [
        for (final (i, t) in readings[script]!.indexed) {'text': t, 'left': 0, 'top': i * 40, 'right': 300, 'bottom': i * 40 + 30},
      ];
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
    expect((await recognizeCjk(files, 'r1'))!.map((l) => l.text), readings['japanese']);
    expect(asked, ['korean', 'japanese']);
    readings = {'korean': ['TOTAL'], 'japanese': ['TOTAL']};
    expect(await recognizeCjk(files, 'r1'), isNull); // a Latin receipt read badly stays as it was
  });

  test("the script hint: the expense's currency (KRW, JPY) first, else the app's language", () {
    expect([ocrScript('KRW', 'en'), ocrScript('JPY', 'ko'), ocrScript('EUR', 'ko'), ocrScript('USD', 'ja')],
        ['korean', 'japanese', 'korean', 'japanese']);
    expect([ocrScript('EUR', 'en'), ocrScript('', 'th')], ['latin', 'latin']);
  });
}
