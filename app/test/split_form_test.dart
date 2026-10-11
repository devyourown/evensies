import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:evensies/core/money.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/sync/group_state_store.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/domain/split.dart';
import 'package:evensies/features/expense_form/expense_form_screen.dart';
import 'package:evensies/features/expense_form/split_editor.dart';
import 'package:evensies/core/env.dart';
import 'package:evensies/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  late AppDatabase db;
  late FakeApi api;
  late SharedPreferences prefs;

  setUpAll(() => Money.loadFromJson('{"decimals":{"EUR":2,"KRW":0}}'));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    api = FakeApi(db);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await db.upsertGroup(
      const GroupRow(
        id: 'g1',
        name: 'Trip',
        defaultCurrency: 'EUR',
        latestSeq: 0,
        myMemberId: 'm1',
        simplifyDebts: true,
      ),
    );
    for (final (id, name) in [('m1', 'Anna'), ('m2', 'Ben'), ('m3', 'Cara')]) {
      await db.into(db.members).insert(MembersCompanion.insert(id: id, groupId: 'g1', name: name));
    }
  });
  tearDown(() => db.close());

  Widget app({String? expenseId}) => ProviderScope(
    overrides: [
      dbProvider.overrideWithValue(db),
      syncProvider.overrideWithValue(NoSync(db)),
      apiProvider.overrideWithValue(api),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: '/e',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: Text('home')),
            routes: [
              GoRoute(
                path: 'e',
                builder: (_, _) => ExpenseFormScreen(groupId: 'g1', expenseId: expenseId),
              ),
            ],
          ),
        ],
      ),
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

  bool saveEnabled(WidgetTester t) => t.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save')).enabled;

  Future<void> save(WidgetTester t) async {
    await t.tap(find.widgetWithText(FilledButton, 'Save'));
    await settle(t);
  }

  Future<List<Map<String, dynamic>>> outbox(WidgetTester t) async => [
    for (final o in (await t.runAsync(() => db.select(db.outbox).get()))!)
      {'type': o.type, ...(jsonDecode(o.payloadJson) as Map).cast<String, dynamic>()},
  ];

  Future<void> fill(WidgetTester t, String amount, String description) async {
    await t.enterText(find.byKey(const Key('amount')), amount);
    await t.enterText(find.byKey(const Key('description')), description);
    await t.pump();
  }

  String status(WidgetTester t, String key) => t.widget<Text>(find.byKey(Key(key))).data!;

  Future<void> seed(WidgetTester t, Expense e) => t.runAsync(
    () => GroupStateStore(db).save(
      'g1',
      GroupState(
        name: 'Trip',
        defaultCurrency: 'EUR',
        members: const [
          Member(id: 'm1', name: 'Anna'),
          Member(id: 'm2', name: 'Ben'),
          Member(id: 'm3', name: 'Cara'),
        ],
        expenses: [e],
      ),
      0,
    ),
  );

  Expense hotel({required List<Share> shares, SplitSpec? split, List<Share>? payers, int amount = 1000}) => Expense(
    id: 'x1',
    description: 'Hotel',
    amount: amount,
    currency: 'EUR',
    payers: payers ?? [Share(memberId: 'm1', amount: amount)],
    date: '2026-10-11',
    split: split,
    shares: shares,
  );

  Share s(String m, int a) => Share(memberId: m, amount: a);

  testWidgets('several payers: the "left to assign" line gates Save; payers and the primary payer are sent', (t) async {
    await open(t);
    await fill(t, '30', 'Hotel');
    await t.tap(find.byKey(const Key('several-payers')));
    await t.pump();
    expect(t.widget<TextField>(find.byKey(const Key('payer-m1'))).controller!.text, '30'); // starts from the payer
    await t.enterText(find.byKey(const Key('payer-m1')), '20');
    await t.pump();
    expect(status(t, 'payers-status'), '€10.00 left to assign');
    expect(saveEnabled(t), isFalse);
    await t.enterText(find.byKey(const Key('payer-m2')), '12');
    await t.pump();
    expect(status(t, 'payers-status'), 'over by: €2.00');
    expect(saveEnabled(t), isFalse);
    await t.enterText(find.byKey(const Key('payer-m2')), '10');
    await t.pump();
    expect(status(t, 'payers-status'), 'Adds up');
    expect(saveEnabled(t), isTrue);
    await save(t);
    final e = (await outbox(t)).single;
    expect(e['type'], 'expense.created');
    expect(e['paidBy'], 'm1');
    expect(e['payers'], [
      {'memberId': 'm1', 'amount': 2000},
      {'memberId': 'm2', 'amount': 1000},
    ]);
    expect(e['refund'], false);
    expect(e['split'], {'mode': 'equal'});
    expect(e['shares'], [
      {'memberId': 'm1', 'amount': 1000},
      {'memberId': 'm2', 'amount': 1000},
      {'memberId': 'm3', 'amount': 1000},
    ]);
    expect(find.text('home'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('equal with an unticked member: only the ticked people are in shares', (t) async {
    await open(t);
    await fill(t, '10', 'Taxi');
    await t.tap(find.byKey(const Key('tick-m3')));
    await t.pump();
    expect(status(t, 'split-status'), 'Split equally between 2 people · €5.00 each');
    expect(find.text('€5.00'), findsNWidgets(2)); // live amounts
    await save(t);
    final e = (await outbox(t)).single;
    expect(e['shares'], [
      {'memberId': 'm1', 'amount': 500},
      {'memberId': 'm2', 'amount': 500},
    ]);
    expect(e['split'], {'mode': 'equal'});
    await unmount(t);
  });

  testWidgets('everyone unticked cannot be saved', (t) async {
    await open(t);
    await fill(t, '10', 'Taxi');
    for (final m in ['m1', 'm2', 'm3']) {
      await t.tap(find.byKey(Key('tick-$m')));
    }
    await t.pump();
    expect(status(t, 'split-status'), 'Pick at least one person');
    expect(saveEnabled(t), isFalse);
    await unmount(t);
  });

  testWidgets('full-amount chips show only with two active members and set payer and split in one tap', (t) async {
    await open(t);
    expect(find.byKey(const Key('full-they-owe')), findsNothing);
    await unmount(t);

    await t.runAsync(
      () =>
          (db.update(db.members)..where((m) => m.id.equals('m3'))).write(const MembersCompanion(removed: Value(true))),
    );
    await open(t);
    expect(find.text('Ben owes the full amount'), findsOneWidget);
    expect(find.text('I owe Ben the full amount'), findsOneWidget);
    await fill(t, '40', 'Tickets');
    await t.tap(find.text('I owe Ben the full amount'));
    await t.pump();
    expect(t.widget<ChoiceChip>(find.byKey(const Key('full-i-owe'))).selected, isTrue);
    expect(t.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Ben')).selected, isTrue); // paid by Ben
    await save(t);
    final e = (await outbox(t)).single;
    expect(e['payers'], [
      {'memberId': 'm2', 'amount': 4000},
    ]);
    expect(e['shares'], [
      {'memberId': 'm1', 'amount': 4000},
    ]);
    await unmount(t);
  });

  testWidgets('Shares and ± are enabled only once computeSplit supports them', (t) async {
    await open(t);
    final seg = t.widget<SegmentedButton<SplitMode>>(find.byType(SegmentedButton<SplitMode>));
    for (final m in [SplitMode.shares, SplitMode.adjustment]) {
      expect(seg.segments.firstWhere((x) => x.value == m).enabled, splitModeReady(m), reason: m.name);
    }
    await fill(t, '10', 'Taxi');
    await t.tap(find.text('Shares'));
    await t.pump();
    if (!splitModeReady(SplitMode.shares)) {
      expect(find.byKey(const Key('tick-m1')), findsOneWidget); // still equal
      expect(saveEnabled(t), isTrue);
    }
    await unmount(t);
  });

  testWidgets('percent works today, with the live amount per row', (t) async {
    await open(t);
    await fill(t, '10', 'Taxi');
    await t.tap(find.text('%'));
    await t.pump();
    await t.enterText(find.byKey(const Key('share-m1')), '50');
    await t.pump();
    expect(status(t, 'split-status'), 'remaining: 50%');
    expect(saveEnabled(t), isFalse);
    await t.enterText(find.byKey(const Key('share-m2')), '50');
    await t.pump();
    expect(status(t, 'split-status'), 'Adds up');
    expect(t.widget<Text>(find.byKey(const Key('live-m1'))).data, '€5.00');
    await save(t);
    final e = (await outbox(t)).single;
    expect(e['split'], {
      'mode': 'percent',
      'input': {'m1': 50, 'm2': 50, 'm3': 0},
    });
    expect(e['shares'], [
      {'memberId': 'm1', 'amount': 500},
      {'memberId': 'm2', 'amount': 500},
      {'memberId': 'm3', 'amount': 0},
    ]);
    await unmount(t);
  });

  testWidgets('editing reopens in the stored mode with the numbers that were typed', (t) async {
    await seed(
      t,
      hotel(
        shares: [s('m1', 600), s('m2', 400), s('m3', 0)],
        split: const SplitSpec(SplitMode.percent, {'m1': 60, 'm2': 40, 'm3': 0}),
        payers: [s('m1', 700), s('m2', 300)],
      ),
    );
    await open(t, expenseId: 'x1');
    final seg = t.widget<SegmentedButton<SplitMode>>(find.byType(SegmentedButton<SplitMode>));
    expect(seg.selected, {SplitMode.percent});
    expect(t.widget<TextField>(find.byKey(const Key('share-m1'))).controller!.text, '60');
    expect(t.widget<TextField>(find.byKey(const Key('share-m2'))).controller!.text, '40');
    expect(t.widget<ChoiceChip>(find.byKey(const Key('several-payers'))).selected, isTrue);
    expect(t.widget<TextField>(find.byKey(const Key('payer-m1'))).controller!.text, '7.00');
    expect(saveEnabled(t), isTrue);
    await unmount(t);
  });

  testWidgets('an equal split reopens with the same people ticked', (t) async {
    await seed(t, hotel(shares: [s('m1', 500), s('m2', 500)], split: const SplitSpec(SplitMode.equal)));
    await open(t, expenseId: 'x1');
    expect(t.widget<CheckboxListTile>(find.byKey(const Key('tick-m1'))).value, isTrue);
    expect(t.widget<CheckboxListTile>(find.byKey(const Key('tick-m3'))).value, isFalse);
    await unmount(t);
  });

  testWidgets('a split that no longer gives the stored shares reopens as exact', (t) async {
    await seed(
      t,
      hotel(
        shares: [s('m1', 500), s('m2', 500), s('m3', 0)],
        split: const SplitSpec(SplitMode.percent, {'m1': 60, 'm2': 40, 'm3': 0}),
      ),
    );
    await open(t, expenseId: 'x1');
    final seg = t.widget<SegmentedButton<SplitMode>>(find.byType(SegmentedButton<SplitMode>));
    expect(seg.selected, {SplitMode.exact});
    expect(t.widget<TextField>(find.byKey(const Key('share-m1'))).controller!.text, '5.00');
    await unmount(t);
  });

  testWidgets('a percent default split pre-fills new expenses; one that cannot be computed falls back to equal', (
    t,
  ) async {
    await t.runAsync(
      () => (db.update(db.groups)..where((g) => g.id.equals('g1'))).write(
        const GroupsCompanion(defaultSplitJson: Value('{"mode":"percent","input":{"m1":50,"m2":30,"m3":20}}')),
      ),
    );
    await open(t);
    expect(t.widget<SegmentedButton<SplitMode>>(find.byType(SegmentedButton<SplitMode>)).selected, {SplitMode.percent});
    expect(t.widget<TextField>(find.byKey(const Key('share-m2'))).controller!.text, '30');
    await unmount(t);

    // Someone with 20% left: no longer 100 → equal.
    await t.runAsync(
      () =>
          (db.update(db.members)..where((m) => m.id.equals('m3'))).write(const MembersCompanion(removed: Value(true))),
    );
    await open(t);
    expect(t.widget<SegmentedButton<SplitMode>>(find.byType(SegmentedButton<SplitMode>)).selected, {SplitMode.equal});
    expect(find.byKey(const Key('default-note')), findsOneWidget);
    await unmount(t);
  });

  testWidgets('a stored split the editor reopens as exact is kept unless the shares change', (t) async {
    // A shares split saved as it is sends nothing; a percent that no longer gives the stored shares opens as exact.
    await seed(
      t,
      hotel(
        shares: [s('m1', 500), s('m2', 250), s('m3', 250)],
        split: const SplitSpec(SplitMode.shares, {'m1': 2, 'm2': 1, 'm3': 1}),
      ),
    );
    await open(t, expenseId: 'x1');
    await save(t);
    expect(await outbox(t), isEmpty); // nothing changed: no event at all
    await unmount(t);

    await seed(
      t,
      hotel(
        shares: [s('m1', 500), s('m2', 500), s('m3', 0)],
        split: const SplitSpec(SplitMode.percent, {'m1': 60, 'm2': 40, 'm3': 0}),
      ),
    );
    await open(t, expenseId: 'x1');
    expect(t.widget<SegmentedButton<SplitMode>>(find.byType(SegmentedButton<SplitMode>)).selected, {SplitMode.exact});
    await t.enterText(find.byKey(const Key('description')), 'Hotel Roma');
    await t.pump();
    await save(t);
    expect((await outbox(t)).single['fields'], {'description': 'Hotel Roma'});
    final kept = (await t.runAsync(() => GroupStateStore(db).load('g1')))!.expense('x1')!;
    expect(kept.split, const SplitSpec(SplitMode.percent, {'m1': 60, 'm2': 40, 'm3': 0}));
    await unmount(t);

    await open(t, expenseId: 'x1');
    await t.enterText(find.byKey(const Key('share-m1')), '6.00');
    await t.enterText(find.byKey(const Key('share-m2')), '4.00');
    await t.pump();
    await save(t);
    final f = (await outbox(t)).last['fields'] as Map;
    expect((f.containsKey('split'), f['split']), (true, null)); // a real exact edit drops the stored split
    await unmount(t);
  });

  testWidgets('a refund hides the full-amount chips (their labels would be backwards)', (t) async {
    await t.runAsync(
      () =>
          (db.update(db.members)..where((m) => m.id.equals('m3'))).write(const MembersCompanion(removed: Value(true))),
    );
    await open(t);
    expect(find.byKey(const Key('full-they-owe')), findsOneWidget);
    await t.tap(find.byKey(const Key('refund')));
    await t.pump();
    expect(find.byKey(const Key('full-they-owe')), findsNothing);
    expect(find.byKey(const Key('full-i-owe')), findsNothing);
    await unmount(t);
  });

  testWidgets('a description-only edit sends only the description; a money edit sends all six money fields', (t) async {
    await seed(
      t,
      hotel(amount: 900, shares: [s('m1', 300), s('m2', 300), s('m3', 300)], split: const SplitSpec(SplitMode.equal)),
    );
    await open(t, expenseId: 'x1');
    await t.enterText(find.byKey(const Key('description')), 'Hotel Roma');
    await t.pump();
    await save(t);
    expect((await outbox(t)).single['fields'], {'description': 'Hotel Roma'});
    await unmount(t);

    await open(t, expenseId: 'x1');
    await t.enterText(find.byKey(const Key('amount')), '12');
    await t.pump();
    await save(t);
    expect((await outbox(t)).last['fields'], {
      'amount': 1200,
      'paidBy': 'm1',
      'payers': [
        {'memberId': 'm1', 'amount': 1200},
      ],
      'shares': [
        {'memberId': 'm1', 'amount': 400},
        {'memberId': 'm2', 'amount': 400},
        {'memberId': 'm3', 'amount': 400},
      ],
      'split': {'mode': 'equal'},
      'refund': false,
    });
    await unmount(t);
  });

  testWidgets('a refund relabels the sections and is sent', (t) async {
    await open(t);
    await fill(t, '60', 'Hotel deposit back');
    await t.tap(find.byKey(const Key('refund')));
    await t.pump();
    expect(find.text('Received by'), findsOneWidget);
    expect(find.text('Split back to'), findsOneWidget);
    await save(t);
    expect((await outbox(t)).single['refund'], true);
    await unmount(t);
  });

  testWidgets('an exact expense without a share for someone shown still sends only the description', (t) async {
    await seed(t, hotel(shares: [s('m1', 600), s('m2', 400)])); // split null, Cara not in shares
    await open(t, expenseId: 'x1');
    expect(t.widget<SegmentedButton<SplitMode>>(find.byType(SegmentedButton<SplitMode>)).selected, {SplitMode.exact});
    await t.enterText(find.byKey(const Key('description')), 'Hotel Roma');
    await t.pump();
    await save(t);
    expect((await outbox(t)).single['fields'], {'description': 'Hotel Roma'});
    await unmount(t);
  });

  testWidgets('no stored split (saved before Phase 3) with equal shares reopens as equal and stays without a split', (
    t,
  ) async {
    await seed(t, hotel(shares: [s('m1', 500), s('m2', 500), s('m3', 0)])); // split null
    await open(t, expenseId: 'x1');
    expect(t.widget<SegmentedButton<SplitMode>>(find.byType(SegmentedButton<SplitMode>)).selected, {SplitMode.equal});
    expect(t.widget<CheckboxListTile>(find.byKey(const Key('tick-m2'))).value, isTrue);
    expect(t.widget<CheckboxListTile>(find.byKey(const Key('tick-m3'))).value, isFalse);
    await t.enterText(find.byKey(const Key('description')), 'Hotel Roma');
    await t.pump();
    await save(t);
    expect((await outbox(t)).single['fields'], {'description': 'Hotel Roma'}); // no `split: equal`, no money fields
    expect((await t.runAsync(() => GroupStateStore(db).load('g1')))!.expense('x1')!.split, isNull);
    await unmount(t);
  });
}
