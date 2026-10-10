import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tally/core/money.dart';
import 'package:tally/data/db/database.dart';
import 'package:tally/features/expense_form/expense_form_screen.dart';
import 'package:tally/providers.dart';

import 'shared_json.dart';

void main() {
  late AppDatabase db;

  setUpAll(() => Money.loadFromJson('{"decimals":{"EUR":2,"KRW":0}}'));

  setUp(() async {
    loadShared('currencies.json'); // fail loudly if the shared dir is missing
    db = AppDatabase(NativeDatabase.memory());
    await db.upsertGroup(const GroupRow(id: 'g1', name: 'Trip', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'm1'));
    await db.into(db.members).insert(MembersCompanion.insert(id: 'm1', groupId: 'g1', name: 'Anna'));
    await db.into(db.members).insert(MembersCompanion.insert(id: 'm2', groupId: 'g1', name: 'Ben', userId: const Value(null)));
  });
  tearDown(() => db.close());

  Widget app() => ProviderScope(
        overrides: [dbProvider.overrideWithValue(db)],
        child: const MaterialApp(home: ExpenseFormScreen(groupId: 'g1')),
      );

  // Dispose the tree inside the test so drift's stream-cancel timers fire before teardown.
  Future<void> unmount(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 10));
  }

  bool saveEnabled(WidgetTester t) => t.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save')).enabled;

  testWidgets('renders and enables Save after amount + description', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    expect(find.text('New expense'), findsOneWidget);
    expect(saveEnabled(t), isFalse);

    await t.enterText(find.byKey(const Key('amount')), '12.50');
    await t.pump();
    expect(saveEnabled(t), isFalse);

    await t.enterText(find.byKey(const Key('description')), 'Pizza');
    await t.pump();
    expect(saveEnabled(t), isTrue);
    await unmount(t);
  });

  testWidgets('exact mode shows one field per member', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    expect(find.byKey(const Key('share-m1')), findsNothing);

    await t.tap(find.text('Exact'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('share-m1')), findsOneWidget);
    expect(find.byKey(const Key('share-m2')), findsOneWidget);
    await unmount(t);
  });
}
