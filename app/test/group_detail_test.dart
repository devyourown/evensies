import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/sync/group_state_store.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/features/group_detail/group_detail_screen.dart';
import 'package:evensies/providers.dart';

import 'fakes.dart';

void main() {
  late AppDatabase db;

  setUpAll(() => Money.loadFromJson('{"decimals":{"EUR":2},"symbols":{"EUR":"€","USD":"\$","GBP":"£","JPY":"¥","KRW":"₩"}}'));
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> open(WidgetTester t, {NoSync? sync}) async {
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          dbProvider.overrideWithValue(db),
          apiProvider.overrideWithValue(FakeApi(db)),
          syncProvider.overrideWithValue(sync ?? NoSync(db)),
        ],
        child: const MaterialApp(home: GroupDetailScreen(groupId: 'g1')),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pumpAndSettle();
    }
  }

  Future<void> unmount(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 10));
  }

  Share s(String m, int a) => Share(memberId: m, amount: a);

  testWidgets('tiles name several payers and refunds; my part uses what I paid minus my share', (t) async {
    await t.runAsync(() async {
      await db.upsertGroup(
        const GroupRow(kind: 'group', 
          id: 'g1',
          name: 'Rome',
          defaultCurrency: 'EUR',
          latestSeq: 0,
          myMemberId: 'm2',
          simplifyDebts: true,
        ),
      );
      await GroupStateStore(db).save(
        'g1',
        GroupState(
          name: 'Rome',
          defaultCurrency: 'EUR',
          members: const [
            Member(id: 'm1', name: 'Anna'),
            Member(id: 'm2', name: 'Ben'),
            Member(id: 'm3', name: 'Cara'),
          ],
          expenses: [
            Expense(
              id: 'x1',
              description: 'Hotel',
              amount: 30000,
              currency: 'EUR',
              payers: [s('m1', 20000), s('m2', 10000)],
              date: '2026-10-11',
              shares: [s('m1', 10000), s('m2', 10000), s('m3', 10000)],
            ),
            Expense(
              id: 'x2',
              description: 'Deposit back',
              amount: 6000,
              currency: 'EUR',
              paidBy: 'm1',
              refund: true,
              date: '2026-10-11',
              shares: [s('m1', 2000), s('m2', 2000), s('m3', 2000)],
            ),
          ],
        ),
        0,
      );
    });
    await open(t);
    expect(find.text('2 people paid €300.00 · you paid for yourself'), findsOneWidget); // paid 100, owes 100 (#107)
    expect(find.text('refund to Anna · you get back €20.00'), findsOneWidget);
    await unmount(t);
  });

  Future<void> seedMine() => db
      .upsertGroup(const GroupRow(kind: 'group', 
          id: 'g1', name: 'Flat 3B', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'm1', simplifyDebts: true))
      .then((_) => GroupStateStore(db).save(
            'g1',
            GroupState(
              name: 'Flat 3B',
              defaultCurrency: 'EUR',
              members: const [Member(id: 'm1', name: 'Maya'), Member(id: 'm2', name: 'Leo')],
              expenses: [
                Expense(id: 'x1', description: 'Coffee beans', amount: 1280, currency: 'EUR', paidBy: 'm1',
                    date: '2026-10-04', category: 'food.groceries', shares: [s('m1', 640), s('m2', 640)]),
                Expense(id: 'x2', description: 'Hotel refund', amount: 4000, currency: 'EUR', paidBy: 'm1',
                    refund: true, date: '2026-10-03', shares: [s('m2', 4000)]),
                Expense(id: 'x3', description: 'Netflix subscription', amount: 1599, currency: 'USD', paidBy: 'm2',
                    date: '2026-10-02', shares: [s('m1', 800), s('m2', 799)]),
              ],
            ),
            0,
          ));

  testWidgets('my own payments read "you", like the detail screen (#13)', (t) async {
    await t.runAsync(seedMine);
    await open(t);
    expect(find.text('you paid €12.80 · you lent €6.40'), findsOneWidget);
    expect(find.text('refund to you · you owe €40.00'), findsOneWidget);
    expect(find.text('Leo paid \$15.99 · you borrowed \$8.00'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('expense rows fit at the largest text size: the amount moves under the text', (t) async {
    t.view.physicalSize = const Size(402, 874); // iPhone 16 Pro in points
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.textScaleFactorTestValue = 3.12; // iOS accessibility XXXL body text
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await t.runAsync(() async {
      await seedMine();
      await db.into(db.payments).insert(PaymentsCompanion.insert(
          id: 'p1', groupId: 'g1', fromMember: 'm1', toMember: 'm2', amount: 500, currency: 'EUR', date: '2026-10-05'));
    });
    await open(t); // an overflow fails the test
    expect(t.getSize(find.text('Coffee beans')).width, greaterThan(200)); // not "Cof..."
    expect(find.text('€12.80'), findsOneWidget);
    expect(t.renderObject<RenderParagraph>(find.text('You paid Leo')).didExceedMaxLines, isFalse); // not "You …"
    expect(find.text('€5.00'), findsOneWidget);
    expect(t.widget<TabBar>(find.byType(TabBar)).isScrollable, isTrue); // not "Expe / Bala / Acti"
    for (final tab in ['Expenses', 'Balances']) {
      expect(t.renderObject<RenderParagraph>(find.text(tab)).didExceedMaxLines, isFalse);
    }
    await t.ensureVisible(find.text('Balances')); // the tabs scroll
    await t.pumpAndSettle();
    await t.tap(find.text('Balances'));
    await t.pumpAndSettle(); // "gets back €…" wraps under the name
    expect(find.text('gets back'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('balances that leave expenses out never read "All settled"', (t) async {
    await t.runAsync(() async {
      await db.upsertGroup(
        const GroupRow(kind: 'group', id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'm1', simplifyDebts: true),
      );
      await GroupStateStore(db).save(
        'g1',
        GroupState(
          name: 'Rome',
          defaultCurrency: 'EUR',
          members: const [Member(id: 'm1', name: 'Anna'), Member(id: 'm2', name: 'Ben')],
          expenses: [
            Expense(
              id: 'x1',
              description: 'Taxi',
              amount: 1000,
              currency: 'USD', // no fx rate: not counted
              paidBy: 'm1',
              date: '2026-10-11',
              shares: [s('m2', 1000)],
            ),
            // Has a rate (e.g. filled in automatically): never "without a rate", though it can't count in EUR yet.
            Expense(
              id: 'x2',
              description: 'Coffee',
              amount: 500,
              currency: 'USD',
              fxRateToDefault: 0.9,
              paidBy: 'm1',
              date: '2026-10-11',
              shares: [s('m1', 500)],
            ),
          ],
        ),
        0,
      );
    });
    await open(t);
    await t.tap(find.text('Balances'));
    await t.pumpAndSettle();
    expect(find.text('All settled'), findsNothing);
    expect(find.text('Nothing owed in EUR'), findsOneWidget);
    // Not hidden any more: its own section, in its own currency (docs/API.md 통화별 잔액).
    expect(find.text('Not converted · USD'), findsOneWidget);
    expect(find.text('1 expense without a rate to EUR'), findsOneWidget);
    expect(find.text('gets back'), findsOneWidget);
    expect(find.text(r'$10.00'), findsNWidgets(2));
    expect(find.byKey(const Key('convert-USD')), findsOneWidget);
    await unmount(t);
  });

  testWidgets('a foreign expense tile: warning and the code without a rate, ≈ with one',
      (t) async {
    await t.runAsync(() async {
      await db.upsertGroup(
        const GroupRow(kind: 'group', id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'm1', simplifyDebts: true),
      );
      await GroupStateStore(db).save(
        'g1',
        GroupState(
          name: 'Rome',
          defaultCurrency: 'EUR',
          members: const [Member(id: 'm1', name: 'Anna')],
          expenses: [
            for (final (id, rate) in [('x1', null), ('x2', 0.5)])
              Expense(id: id, description: id, amount: 1000, currency: 'USD', fxRateToDefault: rate, paidBy: 'm1',
                  date: '2026-10-11', shares: [s('m1', 1000)]),
          ],
        ),
        0,
      );
    });
    await open(t);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('an expense with a receipt shows a receipt mark; a removed receipt does not count', (t) async {
    await t.runAsync(() async {
      await db.upsertGroup(
        const GroupRow(kind: 'group', id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'm1', simplifyDebts: true),
      );
      await GroupStateStore(db).save(
        'g1',
        GroupState(
          name: 'Rome',
          defaultCurrency: 'EUR',
          members: const [Member(id: 'm1', name: 'Anna')],
          expenses: [
            for (final id in ['x1', 'x2'])
              Expense(id: id, description: id, amount: 1000, currency: 'EUR', paidBy: 'm1', date: '2026-10-11',
                  shares: [s('m1', 1000)]),
          ],
          attachments: const [Attachment(id: 'a1', expenseId: 'x1'), Attachment(id: 'a2', expenseId: 'x2', deleted: true)],
        ),
        0,
      );
    });
    await open(t);
    expect(find.byKey(const Key('receipt-mark')), findsOneWidget);
    await unmount(t);
  });

  testWidgets('pull to refresh syncs from the empty Expenses list and from Balances', (t) async {
    await t.runAsync(() async {
      await db.upsertGroup(
        const GroupRow(kind: 'group', id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'm1', simplifyDebts: true),
      );
      await GroupStateStore(db).save(
        'g1',
        const GroupState(name: 'Rome', defaultCurrency: 'EUR', members: [Member(id: 'm1', name: 'Anna')]),
        0,
      );
    });
    final sync = _SyncSpy(db);
    await open(t, sync: sync);
    await t.fling(find.text('No expenses yet'), const Offset(0, 400), 1000);
    await t.pumpAndSettle();
    expect(sync.synced, ['g1']);
    await t.tap(find.text('Balances'));
    await t.pumpAndSettle();
    await t.fling(find.text('All settled'), const Offset(0, 400), 1000);
    await t.pumpAndSettle();
    expect(sync.synced, ['g1', 'g1']);
    await unmount(t);
  }, variant: const TargetPlatformVariant({TargetPlatform.iOS, TargetPlatform.android}));

  testWidgets('Balances names who should pay next: the most owed among members still in the group', (t) async {
    Future<void> seed(String me) => t.runAsync(() async {
          await db.upsertGroup(GroupRow(kind: 'group', 
              id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: me, simplifyDebts: true));
          await GroupStateStore(db).save(
            'g1',
            GroupState(
              name: 'Rome',
              defaultCurrency: 'EUR',
              members: const [
                Member(id: 'm1', name: 'Anna'),
                Member(id: 'm2', name: 'Ben'),
                Member(id: 'm3', name: 'Cara'),
                Member(id: 'm4', name: 'Dan', removed: true),
              ],
              expenses: [
                Expense(id: 'x1', description: 'Hotel', amount: 9000, currency: 'EUR', paidBy: 'm1', date: '2026-10-11',
                    shares: [s('m2', 4000), s('m3', 1000), s('m4', 4000)]),
              ],
            ),
            0,
          );
        });
    await seed('m1');
    await open(t);
    await t.tap(find.text('Balances'));
    await t.pumpAndSettle();
    expect(find.text('Ben should pay next (owes €40.00, the most)'), findsOneWidget); // Dan left: skipped
    await unmount(t);

    await seed('m2');
    await open(t);
    await t.tap(find.text('Balances'));
    await t.pumpAndSettle();
    expect(find.text('You should pay next (you owe €40.00, the most)'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('opening a group on this device pulls it: repeats added by the server show without a push', (t) async {
    final sync = NoSync(db);
    await open(t, sync: sync);
    expect(sync.later, isEmpty); // not on this device: nothing to pull into
    await unmount(t);
    await t.runAsync(() => db.upsertGroup(const GroupRow(
        kind: 'group', id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'm1', simplifyDebts: true)));
    await open(t, sync: sync);
    expect(sync.later, ['g1']);
    await unmount(t);
  });

  testWidgets('a group that is not on the device (left, removed) says so instead of loading forever', (t) async {
    await open(t);
    expect(find.text("This group isn't on this device"), findsOneWidget);
    expect(find.text('Back to groups'), findsOneWidget);
    await unmount(t);
  });
}

class _SyncSpy extends NoSync {
  _SyncSpy(super.db);
  final synced = <String>[];
  @override
  Future<void> sync(String groupId) async => synced.add(groupId);
}
