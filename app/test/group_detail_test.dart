import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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

  setUpAll(() => Money.loadFromJson('{"decimals":{"EUR":2}}'));
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
        const GroupRow(
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
    expect(find.text('paid by Anna +1 · you paid for yourself'), findsOneWidget); // paid 100, owes 100
    expect(find.text('refund to Anna · you get back €20.00'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('balances that leave expenses out never read "All settled"', (t) async {
    await t.runAsync(() async {
      await db.upsertGroup(
        const GroupRow(id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'm1', simplifyDebts: true),
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
          ],
        ),
        0,
      );
    });
    await open(t);
    await t.tap(find.text('Balances'));
    await t.pumpAndSettle();
    expect(find.text('All settled'), findsNothing);
    expect(find.text('Balances are incomplete'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('pull to refresh syncs from the empty Expenses list and from Balances', (t) async {
    await t.runAsync(() async {
      await db.upsertGroup(
        const GroupRow(id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'm1', simplifyDebts: true),
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
