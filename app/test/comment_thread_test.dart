import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/features/expense_form/comment_thread.dart';
import 'package:evensies/providers.dart';

import 'fakes.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.upsertGroup(const GroupRow(id: 'g1', name: 'Rome', defaultCurrency: 'EUR', latestSeq: 0, myMemberId: 'm1', simplifyDebts: true));
    await db.into(db.members).insert(MembersCompanion.insert(id: 'm1', groupId: 'g1', name: 'Anna'));
    await db.into(db.members).insert(MembersCompanion.insert(id: 'm2', groupId: 'g1', name: 'Ben'));
    Future<void> comment(String id, String expense, String author, String text, String at, {bool deleted = false}) =>
        db.into(db.comments).insert(CommentsCompanion.insert(
            id: id,
            groupId: 'g1',
            expenseId: expense,
            authorMemberId: author,
            body: text,
            createdAt: at,
            deleted: Value(deleted)));
    await comment('c1', 'x1', 'm2', 'Is breakfast included?', '2026-10-11T09:00:00Z');
    await comment('c2', 'x1', 'm1', 'Old answer', '2026-10-11T09:01:00Z', deleted: true);
    await comment('c3', 'x1', 'm1', 'Yes', '2026-10-11T09:05:00Z');
    await comment('c4', 'x2', 'm2', 'Other expense', '2026-10-11T09:06:00Z');
  });
  tearDown(() => db.close());

  Widget app() => ProviderScope(
        overrides: [dbProvider.overrideWithValue(db), syncProvider.overrideWithValue(NoSync(db))],
        child: MaterialApp(
          home: Scaffold(
            body: ListView(padding: const EdgeInsets.all(16), children: const [
              CommentThread(groupId: 'g1', expenseId: 'x1'),
            ]),
          ),
        ),
      );

  Future<void> unmount(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 10));
  }

  Future<List<OutboxRow>> outbox() => db.select(db.outbox).get();

  testWidgets('shows live comments of this expense only; delete only on my own', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    expect(find.text('Is breakfast included?'), findsOneWidget);
    expect(find.text('Yes'), findsOneWidget);
    expect(find.text('Old answer'), findsNothing);
    expect(find.text('Other expense'), findsNothing);
    expect(find.textContaining('Ben', findRichText: true), findsOneWidget);
    expect(find.textContaining('You', findRichText: true), findsOneWidget);
    expect(find.byTooltip('Delete comment'), findsOneWidget);
    await unmount(t);
  });

  testWidgets('posting adds the comment as me and enqueues comment.added with the envelope time', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    final send = find.widgetWithIcon(IconButton, Icons.send);
    expect(t.widget<IconButton>(send).onPressed, isNull);

    await t.enterText(find.byKey(const Key('comment-input')), '  Thanks!  ');
    await t.pump();
    await t.tap(send);
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await t.pumpAndSettle();

    expect(find.text('Thanks!'), findsOneWidget);
    final rows = await t.runAsync(outbox);
    expect(rows, hasLength(1));
    expect(rows!.single.type, 'comment.added');
    final p = jsonDecode(rows.single.payloadJson) as Map<String, dynamic>;
    expect(p['expenseId'], 'x1');
    expect(p['authorMemberId'], 'm1');
    expect(p['text'], 'Thanks!');
    expect(p['createdAt'], rows.single.createdAt);
    expect(p['commentId'], isA<String>());
    await unmount(t);
  });

  testWidgets('the limit counts UTF-16 units like the server and says so', (t) async {
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    final send = find.widgetWithIcon(IconButton, Icons.send);
    await t.enterText(find.byKey(const Key('comment-input')), '😀' * 600); // 600 characters, 1200 UTF-16 units
    await t.pump();
    expect(find.text('1200/1000'), findsOneWidget);
    expect(find.text('Too long'), findsOneWidget);
    expect(t.widget<IconButton>(send).onPressed, isNull);

    await t.enterText(find.byKey(const Key('comment-input')), '😀' * 500);
    await t.pump();
    expect(find.text('Too long'), findsNothing);
    expect(t.widget<IconButton>(send).onPressed, isNotNull);
    await unmount(t);
  });

  testWidgets('deleting my comment hides it, blanks its text and enqueues comment.deleted', (t) async {
    await t.runAsync(() async {
      Future<void> cache(int seq, String? commentId) => db.into(db.activity).insert(ActivityCompanion.insert(
          groupId: 'g1', seq: seq, feedId: seq, createdAt: '', json: jsonEncode({'kind': 'comment_added', 'commentId': commentId})));
      await cache(1, 'c1');
      await cache(2, 'c3');
    });
    await t.pumpWidget(app());
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Delete comment'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(FilledButton, 'Delete'));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await t.pumpAndSettle();

    expect(find.text('Yes'), findsNothing);
    final rows = await t.runAsync(outbox);
    expect(rows!.single.type, 'comment.deleted');
    expect(jsonDecode(rows.single.payloadJson), {'commentId': 'c3'});
    // the text leaves this device too: the row and the cached feed item
    final c3 = await t.runAsync(() => (db.select(db.comments)..where((c) => c.id.equals('c3'))).getSingle());
    expect((c3!.deleted, c3.body), (true, ''));
    final cached = await t.runAsync(() => db.select(db.activity).get());
    expect(cached!.map((a) => a.seq), [1]);
    await unmount(t);
  });
}
