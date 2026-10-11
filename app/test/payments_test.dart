import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:evensies/core/env.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/local_writes.dart';
import 'package:evensies/data/sync/group_state_store.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/features/settle/payment_detail_screen.dart';
import 'package:evensies/features/settle/payment_sheet.dart';
import 'package:evensies/features/settle/settle_screen.dart';
import 'package:evensies/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

/// Record any payment, edit it (delete + create), its detail with comments (docs/API.md 송금 기록·편집).
void main() {
  late AppDatabase db;
  late NoSync sync;
  late SharedPreferences prefs;

  setUpAll(() => Money.loadFromJson(File('../shared/currencies.json').readAsStringSync()));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    sync = NoSync(db);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await db.saveSession(const SessionRow(id: 1, accessToken: 'a', refreshToken: 'r', userId: 'u1', displayName: 'Anna'));
    await db.upsertGroup(const GroupRow(
        kind: 'group', id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'm1', simplifyDebts: true));
    await GroupStateStore(db).save(
        'g1',
        const GroupState(name: 'Rome', defaultCurrency: 'EUR', members: [
          Member(id: 'm1', name: 'Anna', userId: 'u1'),
          Member(id: 'm2', name: 'Ben', userId: 'u2'),
          Member(id: 'm3', name: 'Cara'),
        ], payments: [
          Payment(id: 'p1', fromMember: 'm1', toMember: 'm2', amount: 1000, currency: 'EUR', date: '2026-10-10', status: 'sent'),
        ], comments: [
          Comment(id: 'c1', paymentId: 'p1', authorMemberId: 'm2', text: 'Got it?', createdAt: '2026-10-10T09:00:00Z'),
        ]),
        0);
  });
  tearDown(() => db.close());

  Future<List<(String, Map<String, dynamic>)>> outbox(WidgetTester? t) async {
    Future<List<OutboxRow>> rows() => (db.select(db.outbox)..orderBy([(o) => OrderingTerm.asc(o.rowId)])).get();
    final r = t == null ? await rows() : (await t.runAsync(rows))!;
    return [for (final o in r) (o.type, (jsonDecode(o.payloadJson) as Map).cast<String, dynamic>())];
  }

  test('an edit is payment.deleted plus payment.created with a new id, in one local transaction', () async {
    final w = LocalWrites(db, sync);
    await w.editPayment('g1', 'p1',
        const Payment(id: 'p2', fromMember: 'm1', toMember: 'm2', amount: 1200, currency: 'USD', date: '2026-10-11', status: 'sent'));
    final out = await outbox(null);
    expect(out.map((o) => o.$1), ['payment.deleted', 'payment.created']);
    expect(out[0].$2, {'paymentId': 'p1'});
    expect(out[1].$2, {
      'paymentId': 'p2', 'fromMember': 'm1', 'toMember': 'm2', 'amount': 1200, 'currency': 'USD',
      'date': '2026-10-11', 'status': 'sent',
    });
    final s = await GroupStateStore(db).load('g1');
    expect(s.payment('p1')!.deleted, isTrue);
    expect(s.payment('p2')!.currency, 'USD');
    expect(s.comments.single.paymentId, 'p1'); // comments stay with the old payment
    expect(sync.later, ['g1']);
  });

  test('a recorded payment is sent only when I pay someone on Evensies', () {
    const me = Member(id: 'm1', name: 'Anna', userId: 'u1'), ben = Member(id: 'm2', name: 'Ben', userId: 'u2');
    const cara = Member(id: 'm3', name: 'Cara');
    expect(recordedStatus(me, ben, 'u1'), 'sent');
    expect(recordedStatus(ben, me, 'u1'), 'confirmed'); // I received it
    expect(recordedStatus(me, cara, 'u1'), 'confirmed'); // a placeholder can't confirm
    expect(recordedStatus(ben, cara, 'u1'), 'confirmed'); // between two others
  });

  test('a comment on a payment carries paymentId and no expenseId', () async {
    await LocalWrites(db, sync).addComment('g1', 'Yes, thanks', paymentId: 'p1');
    final (type, p) = (await outbox(null)).single;
    expect(type, 'comment.added');
    expect(p.containsKey('expenseId'), isFalse);
    expect((p['paymentId'], p['authorMemberId'], p['text']), ('p1', 'm1', 'Yes, thanks'));
    expect(p['createdAt'], isA<String>());
    final c = (await db.select(db.comments).get()).last;
    expect((c.paymentId, c.expenseId), ('p1', null));
  });

  Widget app(Widget home) => ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          apiProvider.overrideWithValue(FakeApi(db)),
          syncProvider.overrideWithValue(sync),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(home: home),
      );

  /// The payment page under a parent route, as in the app (Edit replaces it, Delete pops it).
  Widget routed(String paymentId) => ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          apiProvider.overrideWithValue(FakeApi(db)),
          syncProvider.overrideWithValue(sync),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(initialLocation: '/groups/g1/payments/$paymentId', routes: [
            GoRoute(path: '/groups/g1', builder: (_, _) => const Scaffold(body: Text('group')), routes: [
              GoRoute(
                  path: 'payments/:pid',
                  builder: (_, s) => PaymentDetailScreen(groupId: 'g1', paymentId: s.pathParameters['pid']!)),
            ]),
          ]),
        ),
      );

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 3; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pumpAndSettle();
    }
  }

  Future<void> unmount(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 10));
  }

  void tall(WidgetTester t) {
    t.view.physicalSize = const Size(800, 2000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  testWidgets('Record a payment: any two people, any currency; the same two people are refused', (t) async {
    tall(t);
    await t.pumpWidget(app(Scaffold(
        body: Builder(
            builder: (c) =>
                TextButton(onPressed: () => showPaymentSheet(c, groupId: 'g1'), child: const Text('open'))))));
    await settle(t);
    await t.tap(find.text('open'));
    await settle(t);
    expect(find.text('Anna (you)'), findsOneWidget); // From: me by default
    await t.enterText(find.byKey(const Key('payment-amount')), '25');
    await t.pump();
    // To → Anna too: refused.
    await t.tap(find.text('Ben'));
    await settle(t);
    await t.tap(find.text('Anna (you)').last);
    await settle(t);
    expect(find.text('Pick two different people'), findsOneWidget);
    expect(t.widget<FilledButton>(find.byKey(const Key('payment-save'))).enabled, isFalse);
    await t.tap(find.byTooltip('Swap'));
    await settle(t);
    await t.tap(find.text('Anna (you)').last); // To
    await settle(t);
    await t.tap(find.text('Cara').last);
    await settle(t);
    // Another currency: the debt in a non-group currency can be paid in that currency (#76).
    await t.tap(find.byKey(const Key('payment-currency')));
    await t.enterText(find.byKey(const Key('payment-currency')), 'JPY');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await settle(t);
    await t.enterText(find.byKey(const Key('payment-amount')), '2500');
    await t.pump();
    await t.tap(find.byKey(const Key('payment-save')));
    await settle(t);
    expect(find.text('Payment of ¥2,500 recorded'), findsOneWidget);
    final (type, p) = (await outbox(t)).single;
    expect(type, 'payment.created');
    expect((p['fromMember'], p['toMember'], p['amount'], p['currency'], p['status']), ('m1', 'm3', 2500, 'JPY', 'confirmed'));
    await unmount(t);
  });

  testWidgets('the payment page: status, comments, and Edit that says where the comments stay', (t) async {
    tall(t);
    await t.pumpWidget(routed('p1'));
    await settle(t);
    expect(find.text('You paid Ben'), findsOneWidget);
    expect(find.text('€10.00'), findsOneWidget);
    expect(find.text('Waiting for Ben to confirm'), findsOneWidget);
    expect(find.text('Got it?'), findsOneWidget);

    await t.enterText(find.byKey(const Key('comment-input')), 'Sent this morning');
    await t.pump();
    await t.tap(find.byTooltip('Send'));
    await settle(t);
    expect((await outbox(t)).single.$2['paymentId'], 'p1');
    expect(find.text('Sent this morning'), findsOneWidget);

    await t.tap(find.byTooltip('Edit'));
    await settle(t);
    expect(find.text('Edit payment'), findsOneWidget);
    expect(find.byKey(const Key('comments-stay')), findsOneWidget);
    await t.enterText(find.byKey(const Key('payment-amount')), '12');
    await t.pump();
    await t.tap(find.byKey(const Key('payment-save')));
    await settle(t);
    final out = await outbox(t);
    expect(out.skip(1).map((o) => o.$1), ['payment.deleted', 'payment.created']);
    expect((out.last.$2['amount'], out.last.$2['status']), (1200, 'sent')); // I paid Ben: he confirms again
    // The page now shows the new payment, not the old one (deleted by the edit).
    expect(find.text('Deleted payment'), findsNothing);
    expect(find.text('€12.00'), findsOneWidget);
    expect(find.text('Payment updated'), findsOneWidget);
    await t.pageBack();
    await settle(t);
    expect(find.text('group'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('Delete goes back and offers Undo, which records the same payment again under a new id', (t) async {
    tall(t);
    await t.pumpWidget(routed('p1'));
    await settle(t);
    await t.tap(find.byTooltip('Delete'));
    await settle(t);
    await t.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(t);
    expect(find.text('group'), findsOneWidget);
    expect(find.text('Payment deleted'), findsOneWidget);
    await t.tap(find.text('Undo'));
    await settle(t);
    final out = await outbox(t);
    expect(out.map((o) => o.$1), ['payment.deleted', 'payment.created']);
    final p = out.last.$2;
    expect(p['paymentId'], isNot('p1'));
    expect((p['fromMember'], p['toMember'], p['amount'], p['currency'], p['date'], p['status']),
        ('m1', 'm2', 1000, 'EUR', '2026-10-10', 'sent'));
    await unmount(t);
  });

  testWidgets("someone else's payment between two others: no Edit or Delete", (t) async {
    await t.runAsync(() => db.into(db.payments).insert(PaymentsCompanion.insert(
        id: 'p9', groupId: 'g1', fromMember: 'm3', toMember: 'm2', amount: 500, currency: 'EUR', date: '2026-10-11')));
    await t.pumpWidget(app(const PaymentDetailScreen(groupId: 'g1', paymentId: 'p9')));
    await settle(t);
    expect(find.text('Cara paid Ben'), findsOneWidget);
    expect(find.byTooltip('Edit'), findsNothing);
    expect(find.byTooltip('Delete'), findsNothing);
    await unmount(t);
  });

  testWidgets('the largest text size: the payment page and the edit sheet fit', (t) async {
    t.view.physicalSize = const Size(402, 874);
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.textScaleFactorTestValue = 3.12;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await t.pumpWidget(app(const PaymentDetailScreen(groupId: 'g1', paymentId: 'p1'))); // an overflow fails the test
    await settle(t);
    await t.tap(find.byTooltip('Edit'));
    await settle(t);
    expect(find.text('Edit payment'), findsOneWidget);
    await unmount(t);
    await t.pumpWidget(app(const SettleScreen(groupId: 'g1'))); // a transfer card and a waiting one
    await settle(t);
    await t.scrollUntilVisible(find.text('Request'), 200, scrollable: find.byType(Scrollable).first);
    await unmount(t);
  });
}
