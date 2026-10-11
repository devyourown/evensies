import 'package:drift/native.dart';
import 'package:evensies/data/api/dto.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/features/auth/auth_service.dart';
import 'package:evensies/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  late AppDatabase db;
  late FakeApi api;
  late ProviderContainer c;
  const saved = SessionRow(id: 1, accessToken: 'a', refreshToken: 'r', userId: 'u1', displayName: 'Anna', homeCurrency: 'EUR');

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    api = FakeApi(db);
    c = ProviderContainer(overrides: [dbProvider.overrideWithValue(db), apiProvider.overrideWithValue(api)]);
    await db.saveSession(saved);
  });
  tearDown(() async {
    c.dispose();
    await db.close();
  });

  test('GET /me writes the name and home currency changed on another phone into the session', () async {
    api.meUser = const UserDto(id: 'u1', displayName: 'Anna Rossi', homeCurrency: 'USD');
    await c.read(authServiceProvider).refreshMe();
    final s = await db.getSession();
    expect((s?.displayName, s?.homeCurrency, s?.accessToken), ('Anna Rossi', 'USD', 'a'));
  });

  test('offline keeps the saved values; a server without homeCurrency keeps the saved one', () async {
    await c.read(authServiceProvider).refreshMe(); // meUser null = unreachable
    expect((await db.getSession())?.displayName, 'Anna');

    api.meUser = const UserDto(id: 'u1', displayName: 'Anna R');
    await c.read(authServiceProvider).refreshMe();
    final s = await db.getSession();
    expect((s?.displayName, s?.homeCurrency), ('Anna R', 'EUR'));
  });

  test('a token refresh landing meanwhile keeps its new tokens (only the profile columns are written)', () async {
    final racing = _RotatingDb();
    final c2 = ProviderContainer(
        overrides: [dbProvider.overrideWithValue(racing), apiProvider.overrideWithValue(FakeApi(racing))]);
    addTearDown(() async {
      c2.dispose();
      await racing.close();
    });
    await racing.saveSession(saved);
    (c2.read(apiProvider) as FakeApi).meUser = const UserDto(id: 'u1', displayName: 'Anna Rossi', homeCurrency: 'USD');
    await c2.read(authServiceProvider).refreshMe();
    final s = await racing.select(racing.session).getSingle();
    expect((s.displayName, s.homeCurrency, s.refreshToken), ('Anna Rossi', 'USD', racing.latest));
  });

  test('signed out: nothing is asked or saved', () async {
    await db.clearSession();
    api.meUser = const UserDto(id: 'u1', displayName: 'Anna');
    await c.read(authServiceProvider).refreshMe();
    expect(await db.getSession(), isNull);
  });
}

/// Every read of the session is followed by a token refresh (ApiClient._refresh) landing right after it.
class _RotatingDb extends AppDatabase {
  _RotatingDb() : super(NativeDatabase.memory());
  var _n = 0;
  String latest = 'r';

  @override
  Future<SessionRow?> getSession() async {
    final s = await super.getSession();
    if (s != null) {
      latest = 'r${++_n}';
      await saveSession(s.copyWith(refreshToken: latest));
    }
    return s;
  }
}
