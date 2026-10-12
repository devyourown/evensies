import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:evensies/core/env.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/receipts.dart';
import 'package:evensies/data/sync/group_state_store.dart';
import 'package:evensies/domain/itemized.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/domain/receipt_parser.dart';
import 'package:evensies/domain/split.dart';
import 'package:evensies/features/expense_form/expense_form_screen.dart';
import 'package:evensies/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// A 1×1 PNG: what the receipt photo files hold here (Image.file must be able to read them).
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');

/// The expense form's Items mode and receipts (docs/API.md 항목별 분할, 영수증).
void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late Directory tmp;
  late ReceiptFiles files;
  final picks = <bool>[]; // scan flag of each pick
  Object? pickError; // thrown by the next pick (the camera refused)
  List<OcrLine>? scanned; // what the phone reads on a scanned photo; null = the diner below

  setUpAll(() => Money.loadFromJson('{"decimals":{"EUR":2,"JPY":0},"symbols":{"EUR":"€","JPY":"¥"}}'));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    tmp = Directory.systemTemp.createTempSync('items');
    files = ReceiptFiles(FakeApi(db), supportDir: () async => '${tmp.path}/s', cacheDir: () async => '${tmp.path}/c');
    picks.clear();
    pickError = null;
    scanned = null;
    await db.upsertGroup(const GroupRow(
        type: 'other', deleted: false, kind: 'group', id: 'g1', name: 'Trip', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'm1', simplifyDebts: true));
    for (final (id, name) in [('m1', 'Anna'), ('m2', 'Ben'), ('m3', 'Cara')]) {
      await db.into(db.members).insert(MembersCompanion.insert(id: id, groupId: 'g1', name: name));
    }
  });
  tearDown(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  /// A scanned receipt: what the phone's text recognition would give.
  const diner = [
    OcrLine(text: "JOE'S DINER", left: 20, top: 0, right: 200, bottom: 30),
    OcrLine(text: 'Burger', left: 20, top: 40, right: 100, bottom: 70),
    OcrLine(text: '14.50', left: 300, top: 40, right: 380, bottom: 70),
    OcrLine(text: 'Salad', left: 20, top: 80, right: 100, bottom: 110),
    OcrLine(text: '11.00', left: 300, top: 80, right: 380, bottom: 110),
    OcrLine(text: 'Tax', left: 20, top: 120, right: 100, bottom: 150),
    OcrLine(text: '2.27', left: 300, top: 120, right: 380, bottom: 150),
    OcrLine(text: 'TOTAL', left: 20, top: 160, right: 100, bottom: 190),
    OcrLine(text: '27.77', left: 300, top: 160, right: 380, bottom: 190),
  ];

  Widget app({String? expenseId}) => ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          apiProvider.overrideWithValue(FakeApi(db)), // no rates: offline
          syncProvider.overrideWithValue(NoSync(db, null, files)),
          sharedPreferencesProvider.overrideWithValue(prefs),
          receiptFilesProvider.overrideWithValue(files),
          receiptFileProvider.overrideWith((ref, k) async => null), // thumbnails: "Available when online"
          pickReceiptProvider.overrideWithValue((source, {required scan}) async {
            if (pickError case final e?) throw e;
            picks.add(scan);
            final id = 'r${picks.length}';
            for (final thumb in [false, true]) {
              // sync: no real async IO inside the test's fake time
              File('${tmp.path}/s/pending_attachments/$id${thumb ? '_thumb' : ''}.jpg')
                ..parent.createSync(recursive: true)
                ..writeAsBytesSync(_png);
            }
            return (id: id, lines: scan ? scanned ?? diner : null);
          }),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(initialLocation: '/e', routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: Text('home')),
              routes: [GoRoute(path: 'e', builder: (_, _) => ExpenseFormScreen(groupId: 'g1', expenseId: expenseId))],
            ),
          ]),
        ),
      );

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 3; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pumpAndSettle();
    }
  }

  Future<void> open(WidgetTester t, {String? expenseId}) async {
    t.view.physicalSize = const Size(800, 3200);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app(expenseId: expenseId));
    await settle(t);
  }

  Future<void> unmount(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 10));
  }

  Future<List<Map<String, dynamic>>> outbox(WidgetTester t) async => [
        for (final o in (await t.runAsync(() => db.select(db.outbox).get()))!)
          {'type': o.type, ...(jsonDecode(o.payloadJson) as Map).cast<String, dynamic>()},
      ];

  String selectedMode(WidgetTester t) => [
        for (final m in [...SplitMode.values.map((m) => m.name), 'itemized'])
          if (t.widget<ChoiceChip>(find.ancestor(of: find.byKey(Key('mode-$m')), matching: find.byType(ChoiceChip))).selected)
            m,
      ].single;

  Finder inLine(int i, Finder f) => find.descendant(of: find.byKey(const Key('item-line')).at(i), matching: f);

  Future<void> save(WidgetTester t) async {
    await t.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(t);
  }

  const bill = ItemizedBill(lines: [
    ItemLine(name: 'Pizza', amount: 2000, memberIds: ['m1']),
    ItemLine(name: 'Wine', amount: 1500, memberIds: ['m1', 'm2']),
  ], tip: 350);

  Future<void> seed(WidgetTester t, List<Share> shares, {int amount = 3850}) => t.runAsync(() => GroupStateStore(db).save(
      'g1',
      GroupState(
        name: 'Trip',
        defaultCurrency: 'EUR',
        members: const [Member(id: 'm1', name: 'Anna'), Member(id: 'm2', name: 'Ben'), Member(id: 'm3', name: 'Cara')],
        expenses: [
          Expense(
              id: 'x1',
              description: 'Dinner',
              amount: amount,
              currency: 'EUR',
              paidBy: 'm1',
              date: '2026-10-11',
              split: const SplitSpec.itemized(bill),
              shares: shares),
        ],
      ),
      0));

  testWidgets('Items: the amount is the total, read-only; Save sends the bill with the shares of everyone on a line',
      (t) async {
    await open(t);
    await t.enterText(find.byKey(const Key('description')), 'Dinner');
    await t.tap(find.byKey(const Key('mode-itemized')));
    await settle(t);
    await t.enterText(inLine(0, find.byKey(const Key('item-name'))), 'Pizza');
    await t.enterText(inLine(0, find.byKey(const Key('item-amount'))), '20');
    await t.tap(inLine(0, find.byKey(const Key('item-person-m1'))));
    await t.tap(find.byKey(const Key('itemize-add')));
    await t.pump();
    await t.enterText(inLine(1, find.byKey(const Key('item-name'))), 'Wine');
    await t.enterText(inLine(1, find.byKey(const Key('item-amount'))), '15');
    await t.tap(inLine(1, find.byKey(const Key('item-person-m1'))));
    await t.tap(inLine(1, find.byKey(const Key('item-person-m2'))));
    await t.enterText(find.descendant(of: find.byKey(const Key('itemize-tip')), matching: find.byKey(const Key('extra-field'))), '3.50');
    await t.pump();
    await t.tap(find.byKey(const Key('itemize-done')));
    await settle(t);

    expect(selectedMode(t), 'itemized');
    final amount = t.widget<TextField>(find.byKey(const Key('amount')));
    expect(amount.controller!.text, '38.50');
    expect(amount.readOnly, isTrue);
    expect(find.text('2 items'), findsOneWidget);
    // Anna 20.00 + 7.50, Ben 7.50; the tip by subtotal: 2.75 and 0.75.
    expect(find.text('Anna €30.25 · Ben €8.25'), findsOneWidget);
    await save(t);
    final e = (await outbox(t)).single;
    expect(e['amount'], 3850);
    expect(e['split'], {'mode': 'itemized', 'bill': bill.toJson()});
    expect(e['shares'], [
      {'memberId': 'm1', 'amount': 3025},
      {'memberId': 'm2', 'amount': 825},
    ]);
    await unmount(t);
  });

  testWidgets('an itemized expense reopens in Items; switching to Exact sends split null with the money fields',
      (t) async {
    await seed(t, const [Share(memberId: 'm1', amount: 3025), Share(memberId: 'm2', amount: 825)]);
    await open(t, expenseId: 'x1');
    expect(selectedMode(t), 'itemized');
    expect(find.text('2 items'), findsOneWidget);
    await t.tap(find.byKey(const Key('mode-exact')));
    await t.pump();
    await t.enterText(find.byKey(const Key('share-m1')), '30');
    await t.enterText(find.byKey(const Key('share-m2')), '8.50');
    await t.pump();
    await save(t);
    final f = ((await outbox(t)).single['fields'] as Map).cast<String, dynamic>();
    expect(f.containsKey('split'), isTrue);
    expect(f['split'], isNull);
    expect(f['shares'], [
      {'memberId': 'm1', 'amount': 3000},
      {'memberId': 'm2', 'amount': 850},
      {'memberId': 'm3', 'amount': 0},
    ]);
    await unmount(t);
  });

  testWidgets('a bill that no longer gives the stored shares reopens in Exact', (t) async {
    await seed(t, const [Share(memberId: 'm1', amount: 1925), Share(memberId: 'm2', amount: 1925)]);
    await open(t, expenseId: 'x1');
    expect(selectedMode(t), 'exact');
    await unmount(t);
  });

  testWidgets('Scan: the items, tax and total from the photo, the shop as the description, the photo attached on Save',
      (t) async {
    await open(t);
    await t.tap(find.byKey(const Key('scan-receipt')));
    await settle(t);
    await t.tap(find.text('Choose from library'));
    await settle(t);
    expect(picks, [true]);
    expect(find.text('Items'), findsWidgets);
    expect(t.widget<Text>(find.byKey(const Key('itemize-total'))).data, '€27.77');
    expect(find.byKey(const Key('itemize-mismatch')), findsNothing); // the items add up to the printed total
    await t.tap(find.byKey(const Key('itemize-everyone')));
    await t.pump();
    await t.tap(find.byKey(const Key('itemize-done')));
    await settle(t);

    expect(t.widget<TextField>(find.byKey(const Key('description'))).controller!.text, "JOE'S DINER");
    expect(find.byKey(const Key('new-receipt-r1')), findsOneWidget);
    await save(t);
    final out = await outbox(t);
    expect(out.map((o) => o['type']), ['expense.created', 'attachment.added']);
    expect(out.last['attachmentId'], 'r1');
    expect(out.last['expenseId'], out.first['expenseId']);
    expect(((out.first['split'] as Map)['bill'] as Map)['tax'], 227);
    expect((await t.runAsync(() => db.pendingUploadsOf('g1')))!.single.attachmentId, 'r1');
    await unmount(t);
  });

  testWidgets('Cancel on the scanned items keeps what was read: the shop, the total, and the items for Items', (t) async {
    await open(t);
    await t.tap(find.byKey(const Key('scan-receipt')));
    await settle(t);
    await t.tap(find.text('Choose from library'));
    await settle(t);
    await t.tap(find.byType(CloseButton));
    await settle(t);
    expect(t.widget<TextField>(find.byKey(const Key('description'))).controller!.text, "JOE'S DINER");
    expect(t.widget<TextField>(find.byKey(const Key('amount'))).controller!.text, '27.77');
    expect(selectedMode(t), 'equal');
    await t.tap(find.byKey(const Key('mode-itemized')));
    await settle(t);
    expect(find.byKey(const Key('item-line')), findsNWidgets(2));
    expect(t.widget<Text>(find.byKey(const Key('itemize-total'))).data, '€27.77');
    await unmount(t);
  });

  testWidgets('a receipt in another currency reads nothing here: it offers that currency and reads it there',
      (t) async {
    scanned = const [
      OcrLine(text: 'SUSHI KAN', left: 20, top: 0, right: 200, bottom: 30),
      OcrLine(text: 'Nigiri set', left: 20, top: 40, right: 100, bottom: 70),
      OcrLine(text: '¥1,800', left: 300, top: 40, right: 380, bottom: 70),
      OcrLine(text: 'Miso soup', left: 20, top: 80, right: 100, bottom: 110),
      OcrLine(text: '¥400', left: 300, top: 80, right: 380, bottom: 110),
      OcrLine(text: 'TOTAL', left: 20, top: 120, right: 100, bottom: 150),
      OcrLine(text: '¥2,200', left: 300, top: 120, right: 380, bottom: 150),
    ];
    await open(t);
    await t.tap(find.byKey(const Key('scan-receipt')));
    await settle(t);
    await t.tap(find.text('Choose from library'));
    await settle(t);
    expect(find.text('This receipt looks like JPY'), findsOneWidget);
    await t.tap(find.text('Switch to JPY'));
    await settle(t);
    expect(find.byKey(const Key('item-line')), findsNWidgets(2));
    await t.tap(find.byKey(const Key('itemize-everyone')));
    await t.pump();
    await t.tap(find.byKey(const Key('itemize-done')));
    await settle(t);
    await t.enterText(find.byKey(const Key('description')), 'Sushi');
    await save(t);
    final e = (await outbox(t)).first;
    expect((e['currency'], e['amount']), ('JPY', 2200));
    await unmount(t);
  });

  testWidgets('a refused camera says how to allow it, never the raw error', (t) async {
    await open(t);
    pickError = PlatformException(code: 'camera_access_denied', message: 'The user did not allow camera access.');
    await t.tap(find.byKey(const Key('add-receipt')));
    await settle(t);
    await t.tap(find.text('Take photo'));
    await settle(t);
    expect(find.text('Evensies has no access. Allow it in the Settings app.'), findsOneWidget);
    expect(find.textContaining('PlatformException'), findsNothing);
    await unmount(t);
  });

  testWidgets('a photo added and the form left without saving is deleted', (t) async {
    await open(t);
    await t.tap(find.byKey(const Key('add-receipt')));
    await settle(t);
    await t.tap(find.text('Take photo'));
    await settle(t);
    expect(picks, [false]);
    expect(find.byKey(const Key('new-receipt-r1')), findsOneWidget);
    await unmount(t);
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    expect(await t.runAsync(() => files.pending('r1')), isNull);
    expect(await outbox(t), isEmpty);
  });
}
