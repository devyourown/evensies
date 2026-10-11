import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:evensies/data/api/api_client.dart';
import 'package:evensies/data/api/dto.dart';
import 'package:evensies/data/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

/// A server whose access token 'a1' has expired and whose refresh tokens work once (rotation, like the real one).
class _Server implements HttpClientAdapter {
  final refreshTokens = {'r1'};
  var refreshes = 0;

  /// Status for /auth/refresh instead of the normal answer; null = normal. -1 = no answer (offline).
  int? refreshStatus;

  /// Runs before any answer (e.g. another request saving new tokens meanwhile).
  Future<void> Function()? meanwhile;

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? body, Future<void>? cancel) async {
    await Future<void>.delayed(const Duration(milliseconds: 5)); // both requests are in flight before either 401
    await meanwhile?.call();
    ResponseBody json(Object? v, [int status = 200]) => ResponseBody.fromString(jsonEncode(v), status, headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        });
    if (o.path == '/auth/refresh') {
      refreshes++;
      if (refreshStatus == -1) throw DioException.connectionError(requestOptions: o, reason: 'offline');
      final token = (jsonDecode(await utf8.decodeStream(body!)) as Map)['refreshToken'];
      if (refreshStatus != null || !refreshTokens.remove(token)) return json({'code': 'UNAUTHORIZED', 'message': ''}, 401);
      refreshTokens.add('r2');
      return json({'accessToken': 'a2', 'refreshToken': 'r2'});
    }
    if (o.headers['Authorization'] != 'Bearer a2') return json({'code': 'UNAUTHORIZED', 'message': ''}, 401);
    return switch (o.path) {
      '/groups' => json([]),
      '/fx' => json({'date': '2026-10-10', 'base': 'EUR', 'rates': {'EUR': 1}}),
      _ => json(null, 404),
    };
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late AppDatabase db;
  late _Server server;
  late ApiClient api;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    server = _Server();
    api = ApiClient(db: db, baseUrl: () => 'http://fake.test', dio: Dio()..httpClientAdapter = server);
    await db.saveSession(
        const SessionRow(id: 1, accessToken: 'a1', refreshToken: 'r1', userId: 'u1', displayName: 'Anna'));
  });
  tearDown(() => db.close());

  test('two requests that both get 401 share one refresh and both go through (no sign-out)', () async {
    await Future.wait([api.listGroups(), api.fx()]); // app start: sync and the rate prefetch
    expect(server.refreshes, 1);
    final s = await db.getSession();
    expect((s?.accessToken, s?.refreshToken), ('a2', 'r2'));

    // A request that went out with the old token while another refreshed retries with the new one, no refresh.
    await db.saveSession(s!.copyWith(accessToken: 'a1'));
    server.meanwhile = () async {
      server.meanwhile = null;
      await db.saveSession(s);
    };
    await api.listGroups();
    expect(server.refreshes, 1);
  });

  test('a refresh keeps a name saved while it was in flight', () async {
    var calls = 0;
    server.meanwhile = () async {
      if (++calls == 2) await db.updateProfile('u1', displayName: 'Anna B'); // call 2 = /auth/refresh
    };
    await api.listGroups();
    final s = await db.getSession();
    expect((s?.displayName, s?.accessToken, s?.refreshToken), ('Anna B', 'a2', 'r2'));
  });

  test('a refused refresh token signs out; an offline refresh does not', () async {
    server.refreshStatus = -1;
    await expectLater(api.listGroups(), throwsA(isA<ApiException>()));
    expect(await db.getSession(), isNotNull);

    server.refreshStatus = 401;
    await expectLater(Future.wait([api.listGroups(), api.fx()]), throwsA(isA<ApiException>()));
    expect(server.refreshes, 2); // offline once, then one shared refusal
    expect(await db.getSession(), isNull);
  });
}
