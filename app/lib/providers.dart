import 'dart:ui' show PlatformDispatcher;

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/env.dart';
import 'core/money.dart';
import 'data/api/api_client.dart';
import 'data/api/dto.dart';
import 'data/db/database.dart';
import 'data/fx_rates.dart';
import 'data/local_writes.dart';
import 'data/receipts.dart';
import 'data/sync/sync_service.dart';

/// Overridden in tests with `AppDatabase(NativeDatabase.memory())`.
final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final apiProvider = Provider<ApiClient>(
    (ref) => ApiClient(db: ref.watch(dbProvider), baseUrl: () => ref.read(serverUrlProvider)));

final syncProvider = Provider<SyncService>((ref) =>
    SyncService(db: ref.watch(dbProvider), api: ref.watch(apiProvider), receipts: ref.watch(receiptFilesProvider)));

final localWritesProvider = Provider<LocalWrites>((ref) => LocalWrites(ref.watch(dbProvider), ref.watch(syncProvider)));

final sessionProvider = StreamProvider<SessionRow?>((ref) => ref.watch(dbProvider).watchSession());

final fxRatesProvider = Provider<FxRates>((ref) => FxRates(ref.watch(dbProvider), ref.watch(apiProvider)));

/// The newest cached rate table (prefetched at app start), for the "≈" lines; null until one was fetched.
final latestFxProvider = StreamProvider<FxTable?>((ref) => ref.watch(fxRatesProvider).watchLatest());

/// The user's display currency (docs/API.md homeCurrency): the saved one, else the phone region's.
final homeCurrencyProvider = Provider<String>((ref) =>
    ref.watch(sessionProvider).value?.homeCurrency ??
    Money.currencyForLocale(PlatformDispatcher.instance.locale.toString()));

final groupsProvider = StreamProvider<List<GroupRow>>((ref) => ref.watch(dbProvider).watchGroups());
final groupProvider = StreamProvider.family<GroupRow?, String>((ref, id) => ref.watch(dbProvider).watchGroup(id));
final membersProvider =
    StreamProvider.family<List<MemberRow>, String>((ref, id) => ref.watch(dbProvider).watchMembers(id));
final expensesProvider =
    StreamProvider.family<List<ExpenseRow>, String>((ref, id) => ref.watch(dbProvider).watchExpenses(id));
final paymentsProvider = StreamProvider.family<List<PaymentRow>, String>((ref, id) {
  final db = ref.watch(dbProvider);
  return (db.select(db.payments)..where((p) => p.groupId.equals(id) & p.deleted.equals(false))).watch();
});
final commentsProvider = StreamProvider.family<List<CommentRow>, String>((ref, id) {
  final db = ref.watch(dbProvider);
  return (db.select(db.comments)..where((c) => c.groupId.equals(id))).watch();
});

/// expenseId → its receipts that aren't deleted (docs/API.md 영수증); also makes the group state re-read on a change.
final attachmentCountsProvider =
    StreamProvider.family<Map<String, int>, String>((ref, id) => ref.watch(dbProvider).watchAttachmentCounts(id));

/// The group's repeating series rows (docs/API.md 반복 지출); also makes the group state re-read on a change.
final recurrencesProvider =
    StreamProvider.family<List<RecurrenceRow>, String>((ref, id) => ref.watch(dbProvider).watchRecurrences(id));

/// Ids of the group's series that aren't stopped: their expenses show the repeat mark.
final activeSeriesProvider = Provider.family<Set<String>, String>((ref, id) => {
      for (final r in ref.watch(recurrencesProvider(id)).value ?? const <RecurrenceRow>[])
        if (!r.deleted) r.id,
    });

/// Whether the expense was deleted by a move (docs/API.md 지출 옮기기): restoring it would count it in both groups, so
/// the app offers no Restore (and the appliers ignore one, rule 13).
final movedAwayProvider = StreamProvider.family<bool, ({String groupId, String expenseId})>((ref, k) {
  final db = ref.watch(dbProvider);
  return (db.select(db.expenses)..where((e) => e.id.equals(k.expenseId)))
      .watchSingleOrNull()
      .map((r) => r?.moved ?? false);
});

/// Offline chip state, mirrored from SyncService.
final offlineProvider = Provider<bool>((ref) {
  final n = ref.watch(syncProvider).offline;
  void listener() => ref.invalidateSelf();
  n.addListener(listener);
  ref.onDispose(() => n.removeListener(listener));
  return n.value;
});

/// A user's profile photo through the API (token refresh included), kept until the app comes back to the front; null
/// when there is none, it isn't visible to me, or the server can't be reached (initials then). Mine is invalidated
/// after a change.
final avatarProvider = FutureProvider.family<Uint8List?, String>((ref, userId) async {
  try {
    return await ref.read(apiProvider).avatar(userId);
  } catch (_) {
    return null;
  }
});

/// Unread activity (docs/API.md 읽지 않은 활동); null when unknown or when the server has no such endpoint (badges
/// hidden). Online only: a failed refresh keeps what is shown.
class UnreadNotifier extends Notifier<ActivityUnread?> {
  static const _badge = MethodChannel('evensies/badge');

  @override
  ActivityUnread? build() => null;

  Future<void> refresh() => _run(() => ref.read(apiProvider).activityUnread());

  /// Signed out or another account: no counts, and no icon badge left from the previous account.
  void reset() {
    state = null;
    _badge.invokeMethod('set', 0).catchError((_) => null);
  }

  /// After the first page of a feed: marks it seen up to [feedId] ([groupId] for a group's tab).
  Future<void> seen(int feedId, {String? groupId}) =>
      _run(() => ref.read(apiProvider).activitySeen(feedId, groupId: groupId));

  Future<void> _run(Future<ActivityUnread> Function() f) async {
    try {
      final u = await f();
      state = u;
      // iOS app icon; no-op elsewhere (Android launchers count the notifications).
      await _badge.invokeMethod('set', u.total).catchError((_) => null);
    } on ApiException catch (e) {
      if (e.status == 404) state = null; // a server before Phase 6
    } catch (_) {}
  }
}

final unreadProvider = NotifierProvider<UnreadNotifier, ActivityUnread?>(UnreadNotifier.new);

/// "3", or "99+" past 99.
String badgeLabel(int n) => n > 99 ? '99+' : '$n';
