import 'dart:ui' show PlatformDispatcher;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/env.dart';
import 'core/money.dart';
import 'data/api/api_client.dart';
import 'data/api/dto.dart';
import 'data/db/database.dart';
import 'data/fx_rates.dart';
import 'data/local_writes.dart';
import 'data/sync/sync_service.dart';

/// Overridden in tests with `AppDatabase(NativeDatabase.memory())`.
final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final apiProvider = Provider<ApiClient>(
    (ref) => ApiClient(db: ref.watch(dbProvider), baseUrl: () => ref.read(serverUrlProvider)));

final syncProvider = Provider<SyncService>((ref) => SyncService(db: ref.watch(dbProvider), api: ref.watch(apiProvider)));

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

/// Offline chip state, mirrored from SyncService.
final offlineProvider = Provider<bool>((ref) {
  final n = ref.watch(syncProvider).offline;
  void listener() => ref.invalidateSelf();
  n.addListener(listener);
  ref.onDispose(() => n.removeListener(listener));
  return n.value;
});
