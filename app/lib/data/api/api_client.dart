import 'dart:io';

import 'package:dio/dio.dart';

import '../../domain/activity.dart';
import '../../domain/models.dart';
import '../../domain/payment_methods.dart';
import '../db/database.dart';
import 'dto.dart';

/// Typed client for every endpoint in docs/API.md. Bearer token from the session table;
/// a 401 triggers one refresh + retry.
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

  Future<void> _onError(DioException e, ErrorInterceptorHandler h) async {
    final o = e.requestOptions;
    if (e.response?.statusCode == 401 && o.extra['retried'] != true && o.extra['noAuth'] != true) {
      final s = await db.getSession();
      if (s != null) {
        try {
          final r = await _dio.post<Map<String, dynamic>>('/auth/refresh',
              data: {'refreshToken': s.refreshToken}, options: Options(extra: {'noAuth': true}));
          await db.saveSession(s.copyWith(
              accessToken: r.data!['accessToken'] as String, refreshToken: r.data!['refreshToken'] as String));
          o.extra['retried'] = true;
          return h.resolve(await _dio.fetch(o));
        } catch (_) {
          await db.clearSession();
        }
      }
    }
    h.next(e);
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
  Future<UserDto> updateMe(String displayName) =>
      _call(() => _dio.patch('/me', data: {'displayName': displayName}), (d) => UserDto.fromJson(_map(d)));
  Future<void> deleteMe() => _call(() => _dio.delete('/me'), (_) {});
  Future<void> registerDevice(String deviceId, String fcmToken) =>
      _call(() => _dio.post('/devices', data: {'deviceId': deviceId, 'fcmToken': fcmToken}), (_) {});
  Future<void> unregisterDevice(String deviceId) => _call(() => _dio.delete('/devices/$deviceId'), (_) {});

  // --- notification prefs: {"expenses","comments","members"} → bool (docs/API.md 알림 설정)
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
  Future<ActivityPage> activity({String? groupId, int? before, int limit = 50}) => _call(
      () => _dio.get(groupId == null ? '/activity' : '/groups/$groupId/activity',
          queryParameters: {'before': ?before, 'limit': limit}),
      _page);

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
