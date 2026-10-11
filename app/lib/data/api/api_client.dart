import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../domain/activity.dart';
import '../../domain/models.dart';
import '../../domain/payment_methods.dart';
import '../db/database.dart';
import 'dto.dart';

/// Typed client for every endpoint in docs/API.md. Bearer token from the session table;
/// a 401 triggers one refresh (shared by concurrent requests) + retry.
class ApiClient {
  final AppDatabase db;
  final String Function() baseUrl;
  late final Dio _dio;

  ApiClient({required this.db, required this.baseUrl, Dio? dio}) {
    _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 30)));
    _dio.interceptors.add(InterceptorsWrapper(onRequest: _onRequest, onError: _onError));
  }

  Future<void> _onRequest(RequestOptions o, RequestInterceptorHandler h) async {
    o.baseUrl = baseUrl();
    if (o.extra['noAuth'] != true) {
      final s = await db.getSession();
      if (s != null) o.headers['Authorization'] = 'Bearer ${s.accessToken}';
    }
    h.next(o);
  }

  /// The refresh in flight: every 401 waits for this one, since a refresh token works only once (rotation).
  Future<bool>? _refreshing;

  Future<void> _onError(DioException e, ErrorInterceptorHandler h) async {
    final o = e.requestOptions;
    if (e.response?.statusCode == 401 && o.extra['retried'] != true && o.extra['noAuth'] != true) {
      final s = await db.getSession();
      // A token other than the one this request went with means another request already refreshed it.
      if (s != null &&
          (o.headers['Authorization'] != 'Bearer ${s.accessToken}' ||
              await (_refreshing ??= _refresh(s).whenComplete(() => _refreshing = null)))) {
        o.extra['retried'] = true;
        try {
          return h.resolve(await _dio.fetch(o));
        } on DioException catch (retry) {
          return h.next(retry);
        }
      }
    }
    h.next(e);
  }

  /// False if it failed. Signs out only when the server refused [s]'s refresh token and nothing replaced it meanwhile
  /// (not when offline).
  Future<bool> _refresh(SessionRow s) async {
    try {
      final r = await _dio.post<Map<String, dynamic>>('/auth/refresh',
          data: {'refreshToken': s.refreshToken}, options: Options(extra: {'noAuth': true}));
      await db.saveTokens(s.userId, r.data!['accessToken'] as String, r.data!['refreshToken'] as String);
      return true;
    } on DioException catch (x) {
      if (x.response?.statusCode == 401 && (await db.getSession())?.refreshToken == s.refreshToken) {
        await db.clearSession();
      }
      return false;
    }
  }

  Future<T> _call<T>(Future<Response<dynamic>> Function() f, T Function(dynamic) parse) async {
    try {
      return parse((await f()).data);
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map && body['code'] != null) {
        throw ApiException(
            status: e.response?.statusCode, code: body['code'] as String, message: body['message'] as String? ?? '');
      }
      throw ApiException(
          status: e.response?.statusCode, code: 'NETWORK', message: e.message ?? 'Network error');
    } on TimeoutException {
      throw const ApiException(code: 'NETWORK', message: 'Timed out');
    }
  }

  Map<String, dynamic> _map(dynamic d) => (d as Map).cast<String, dynamic>();

  // --- auth
  Future<AuthResponse> authApple(String idToken, {String? displayName}) => _call(
      () => _dio.post('/auth/apple',
          data: {'idToken': idToken, 'displayName': ?displayName}, options: Options(extra: {'noAuth': true})),
      (d) => AuthResponse.fromJson(_map(d)));
  Future<AuthResponse> authGoogle(String idToken, {String? displayName}) => _call(
      () => _dio.post('/auth/google',
          data: {'idToken': idToken, 'displayName': ?displayName}, options: Options(extra: {'noAuth': true})),
      (d) => AuthResponse.fromJson(_map(d)));
  Future<AuthResponse> authDev(String name) => _call(
      () => _dio.post('/auth/dev', data: {'name': name}, options: Options(extra: {'noAuth': true})),
      (d) => AuthResponse.fromJson(_map(d)));
  Future<UserDto> me() => _call(() => _dio.get('/me'), (d) => UserDto.fromJson(_map(d)));
  /// Only the given keys are sent (docs/API.md PATCH /me); at least one is needed.
  Future<UserDto> updateMe({String? displayName, String? homeCurrency}) => _call(
      () => _dio.patch('/me', data: {'displayName': ?displayName, 'homeCurrency': ?homeCurrency}),
      (d) => UserDto.fromJson(_map(d)));

  /// Rates per 1 EUR for [date] (YYYY-MM-DD; null = today). Gives up after 3 s so the form falls back to the cache.
  Future<FxTable> fx([String? date]) => _call(
      () => _dio.get('/fx', queryParameters: {'date': ?date}).timeout(const Duration(seconds: 3)),
      (d) => FxTable.fromJson(_map(d)));
  Future<void> deleteMe() => _call(() => _dio.delete('/me'), (_) {});
  Future<void> registerDevice(String deviceId, String fcmToken) =>
      _call(() => _dio.post('/devices', data: {'deviceId': deviceId, 'fcmToken': fcmToken}), (_) {});
  Future<void> unregisterDevice(String deviceId) => _call(() => _dio.delete('/devices/$deviceId'), (_) {});

  // --- notification prefs: {"expenses","comments","members","reminders"?} → bool (docs/API.md 알림 설정)
  Map<String, bool> _prefs(dynamic d) => _map(d).cast<String, bool>();
  Future<Map<String, bool>> getNotificationPrefs() => _call(() => _dio.get('/me/notifications'), _prefs);
  Future<Map<String, bool>> putNotificationPrefs(Map<String, bool> prefs) =>
      _call(() => _dio.put('/me/notifications', data: prefs), _prefs);

  // --- activity: newest first; only nextBefore == null means the end (pages can be short or empty).
  ActivityPage _page(dynamic d) {
    final m = _map(d);
    return (
      items: (m['items'] as List).map((e) => ActivityItem.fromJson(_map(e))).toList(),
      nextBefore: (m['nextBefore'] as num?)?.toInt(),
    );
  }

  /// One group's feed ([before] = seq), or every group of mine when [groupId] is null ([before] = feedId).
  /// [expenseId] keeps one expense's events (its history, Phase 5); a server before Phase 5 ignores it, so callers
  /// filter the items too.
  Future<ActivityPage> activity({String? groupId, int? before, int limit = 50, String? expenseId}) => _call(
      () => _dio.get(groupId == null ? '/activity' : '/groups/$groupId/activity',
          queryParameters: {'before': ?before, 'limit': limit, 'expenseId': ?expenseId?.toLowerCase()}),
      _page);

  /// Unread feed items per group (docs/API.md 읽지 않은 활동).
  Future<ActivityUnread> activityUnread() =>
      _call(() => _dio.get('/activity/unread'), (d) => ActivityUnread.fromJson(_map(d)));

  /// Marks the feed seen up to [feedId], in [groupId] or in every group of mine.
  Future<ActivityUnread> activitySeen(int feedId, {String? groupId}) => _call(
      () => _dio.post('/activity/seen', data: {'feedId': feedId, 'groupId': ?groupId}),
      (d) => ActivityUnread.fromJson(_map(d)));

  // --- friends (docs/API.md 친구)
  FriendCode _friendCode(dynamic d) =>
      (friendCode: _map(d)['friendCode'] as String, link: _map(d)['link'] as String);
  Future<FriendCode> friendCode() => _call(() => _dio.get('/me/friend-code'), _friendCode);
  Future<FriendCode> rotateFriendCode() => _call(() => _dio.post('/me/friend-code/rotate'), _friendCode);

  /// The display name behind a friend code (no auth).
  Future<String> friendInvite(String code) => _call(
      () => _dio.get('/friend-invites/$code', options: Options(extra: {'noAuth': true})),
      (d) => _map(d)['displayName'] as String);

  /// Exactly one of [code], [userId], [name]; [id] makes retries idempotent. Returns the (canonical) friend group.
  Future<GroupDto> addFriend(
          {required String id, required String defaultCurrency, String? code, String? userId, String? name}) =>
      _call(
          () => _dio.post('/friends', data: {
                'id': id,
                'defaultCurrency': defaultCurrency,
                'code': ?code,
                'userId': ?userId,
                'name': ?name,
              }),
          (d) => GroupDto.fromJson(_map(d)));

  /// What [userId] owes me, per currency (sorted by code).
  Future<Map<String, int>> remind(String userId) => _call(
      () => _dio.post('/friends/$userId/remind'),
      (d) => {
            for (final a in (_map(d)['amounts'] as List).cast<Map>())
              a['currency'] as String: (a['amount'] as num).toInt(),
          });

  // --- profile photo (docs/API.md 프로필 사진)
  Future<void> putAvatar(File jpeg) => _call(
        () async => _dio.put('/me/avatar',
            data: FormData.fromMap({'file': await MultipartFile.fromFile(jpeg.path, filename: 'avatar.jpg')})),
        (_) {},
      );
  Future<void> deleteAvatar() => _call(() => _dio.delete('/me/avatar'), (_) {});
  Future<Uint8List> avatar(String userId) => _call(
      () => _dio.get('/users/$userId/avatar', options: Options(responseType: ResponseType.bytes)),
      (d) => Uint8List.fromList(d as List<int>));

  // --- payment methods
  List<PaymentMethod> _methods(dynamic d) => (d as List).map((e) => PaymentMethod.fromJson(_map(e))).toList();
  Future<List<PaymentMethod>> getMyPaymentMethods() => _call(() => _dio.get('/me/payment-methods'), _methods);
  Future<List<PaymentMethod>> putMyPaymentMethods(List<PaymentMethod> ms) => _call(
      () => _dio.put('/me/payment-methods', data: ms.map((m) => m.toJson()).toList()), _methods);
  /// memberId → that linked member's methods.
  Future<Map<String, List<PaymentMethod>>> groupPaymentMethods(String groupId) =>
      _call(() => _dio.get('/groups/$groupId/payment-methods'),
          (d) => {for (final e in _map(d).entries) e.key: _methods(e.value)});

  // --- groups
  Future<GroupDto> createGroup({
    required String id,
    required String name,
    required String defaultCurrency,
    required String memberId,
    required String memberName,
  }) =>
      _call(
          () => _dio.post('/groups', data: {
                'id': id,
                'name': name,
                'defaultCurrency': defaultCurrency,
                'memberId': memberId,
                'memberName': memberName,
              }),
          (d) => GroupDto.fromJson(_map(d)));
  Future<List<GroupSummaryDto>> listGroups() => _call(() => _dio.get('/groups'),
      (d) => (d as List).map((e) => GroupSummaryDto.fromJson(_map(e))).toList());
  Future<GroupDto> getGroup(String id) => _call(() => _dio.get('/groups/$id'), (d) => GroupDto.fromJson(_map(d)));
  Future<String> rotateInvite(String id) =>
      _call(() => _dio.post('/groups/$id/invite/rotate'), (d) => _map(d)['inviteCode'] as String);
  Future<InvitePreview> invitePreview(String code) => _call(
      () => _dio.get('/invites/$code', options: Options(extra: {'noAuth': true})),
      (d) => InvitePreview.fromJson(_map(d)));
  Future<GroupDto> joinExisting(String code, String memberId) => _call(
      () => _dio.post('/invites/$code/join', data: {'memberId': memberId}), (d) => GroupDto.fromJson(_map(d)));
  Future<GroupDto> joinNew(String code, {required String newMemberId, required String name}) => _call(
      () => _dio.post('/invites/$code/join', data: {'newMemberId': newMemberId, 'name': name}),
      (d) => GroupDto.fromJson(_map(d)));

  // --- sync
  Future<PushResult> pushEvents(String groupId, List<OutboundEvent> events) => _call(
      () => _dio.post('/groups/$groupId/events', data: events.map((e) => e.toJson()).toList()),
      (d) => PushResult.fromJson(_map(d)));
  Future<({List<SyncEvent> events, int latestSeq})> pullEvents(String groupId, {required int after, int limit = 500}) =>
      _call(() => _dio.get('/groups/$groupId/events', queryParameters: {'after': after, 'limit': limit}), (d) {
        final m = _map(d);
        return (
          events: (m['events'] as List).map((e) => SyncEvent.fromJson(_map(e))).toList(),
          latestSeq: (m['latestSeq'] as num).toInt(),
        );
      });
  Future<({GroupDto group, GroupState state, int latestSeq})> snapshot(String groupId) =>
      _call(() => _dio.get('/groups/$groupId/snapshot'), (d) {
        final m = _map(d);
        return (
          group: GroupDto.fromJson(_map(m['group'])),
          state: GroupState.fromJson(m),
          latestSeq: (m['latestSeq'] as num).toInt(),
        );
      });

  // --- export / import
  Future<String> export(String groupId, String format) => _call(
      () => _dio.get('/groups/$groupId/export',
          queryParameters: {'format': format}, options: Options(responseType: ResponseType.plain)),
      (d) => d as String);
  Future<({int imported, int latestSeq})> importSplitwise(String groupId, File csv) => _call(
        () async => _dio.post('/groups/$groupId/import/splitwise',
            data: FormData.fromMap({'file': await MultipartFile.fromFile(csv.path, filename: 'splitwise.csv')})),
        (d) => (imported: (_map(d)['imported'] as num).toInt(), latestSeq: (_map(d)['latestSeq'] as num).toInt()),
      );
}
