import 'package:evensies/data/api/api_client.dart';
import 'package:evensies/data/api/dto.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/sync/sync_service.dart';
import 'package:evensies/domain/models.dart';
import 'package:evensies/domain/payment_methods.dart';

/// ApiClient with canned answers; anything not set throws like an unreachable server.
class FakeApi extends ApiClient {
  FakeApi(AppDatabase db) : super(db: db, baseUrl: () => 'http://fake.test');

  static const offline = ApiException(code: 'NETWORK', message: 'offline');

  /// (groupId, before) → page. Calls are recorded in [activityCalls], their expenseId in [activityExpenseIds].
  ActivityPage Function(String? groupId, int? before)? onActivity;
  final activityCalls = <(String?, int?)>[];
  final activityExpenseIds = <String?>[];
  List<SyncEvent> events = const [];

  @override
  Future<ActivityPage> activity({String? groupId, int? before, int limit = 50, String? expenseId}) async {
    activityCalls.add((groupId, before));
    activityExpenseIds.add(expenseId);
    final f = onActivity;
    if (f == null) throw offline;
    return f(groupId, before);
  }

  @override
  Future<({List<SyncEvent> events, int latestSeq})> pullEvents(String groupId, {required int after, int limit = 500}) async {
    final page = events.where((e) => e.seq > after).toList();
    return (events: page, latestSeq: events.isEmpty ? 0 : events.last.seq);
  }

  /// Server state for GET snapshot; null = unreachable.
  ({GroupDto group, GroupState state, int latestSeq})? snap;

  @override
  Future<({GroupDto group, GroupState state, int latestSeq})> snapshot(String groupId) async => snap ?? (throw offline);

  /// Server-side notification prefs; null = unreachable. PUT bodies land in [putPrefs].
  Map<String, bool>? prefs;
  final putPrefs = <Map<String, bool>>[];

  @override
  Future<Map<String, bool>> getNotificationPrefs() async => prefs ?? (throw offline);

  @override
  Future<Map<String, bool>> putNotificationPrefs(Map<String, bool> p) async {
    putPrefs.add(p);
    if (prefs == null) throw offline;
    return prefs = p;
  }

  /// POST events; null = unreachable. Every call's batch lands in [pushes].
  PushResult Function(String groupId, List<OutboundEvent> events)? onPush;
  final pushes = <List<OutboundEvent>>[];

  @override
  Future<PushResult> pushEvents(String groupId, List<OutboundEvent> events) async {
    pushes.add(events);
    final f = onPush;
    if (f == null) throw offline;
    return f(groupId, events);
  }

  @override
  Future<Map<String, List<PaymentMethod>>> groupPaymentMethods(String groupId) async => throw offline;

  /// GET /fx: date (null = today) → table; null = unreachable. Asked dates land in [fxCalls].
  FxTable Function(String? date)? onFx;
  final fxCalls = <String?>[];

  @override
  Future<FxTable> fx([String? date]) async {
    fxCalls.add(date);
    final f = onFx;
    if (f == null) throw offline;
    return f(date);
  }

  /// The account POST /auth/dev signs in as.
  UserDto signInAs = const UserDto(id: 'u1', displayName: 'Anna');

  @override
  Future<AuthResponse> authDev(String name) async => AuthResponse(accessToken: 'a', refreshToken: 'r', user: signInAs);

  /// GET /me; null = unreachable.
  UserDto? meUser;

  @override
  Future<UserDto> me() async => meUser ?? (throw offline);

  /// PATCH /me bodies; [meOffline] makes it unreachable.
  final meUpdates = <({String? displayName, String? homeCurrency})>[];
  bool meOffline = false;

  @override
  Future<UserDto> updateMe({String? displayName, String? homeCurrency}) async {
    meUpdates.add((displayName: displayName, homeCurrency: homeCurrency));
    if (meOffline) throw offline;
    return UserDto(id: 'u1', displayName: displayName ?? 'Anna', homeCurrency: homeCurrency);
  }

  /// GET /groups ids; null = unreachable.
  List<String>? groupIds;

  @override
  Future<List<GroupSummaryDto>> listGroups() async => [
        for (final id in groupIds ?? (throw offline))
          GroupSummaryDto(id: id, name: id, defaultCurrency: 'EUR', latestSeq: 0, memberCount: 1),
      ];

  /// GET /groups/{id}: a status to fail with (403, 404), or null to answer 200; [groupCode] overrides the server's
  /// code (e.g. 'NETWORK' for a proxy's answer).
  int? groupStatus;
  String? groupCode;

  @override
  Future<GroupDto> getGroup(String id) async {
    if (groupStatus != null) {
      throw ApiException(
          status: groupStatus, code: groupCode ?? (groupStatus == 404 ? 'NOT_FOUND' : 'FORBIDDEN'), message: 'no');
    }
    return GroupDto(id: id, name: id, defaultCurrency: 'EUR', inviteCode: 'ABC', latestSeq: 0, myMemberId: 'm1');
  }

  /// POST /devices (deviceId, fcmToken) and DELETE /devices ids; [devicesOffline] makes both unreachable.
  final registered = <(String, String)>[];
  final unregistered = <String>[];
  bool devicesOffline = false;

  @override
  Future<void> registerDevice(String deviceId, String fcmToken) async {
    if (devicesOffline) throw offline;
    registered.add((deviceId, fcmToken));
  }

  @override
  Future<void> unregisterDevice(String deviceId) async {
    if (devicesOffline) throw offline;
    unregistered.add(deviceId);
  }
}

/// SyncService that never touches the network from local writes; [later] records syncLater calls.
class NoSync extends SyncService {
  NoSync(AppDatabase db) : super(db: db, api: FakeApi(db));
  final later = <String>[];
  @override
  void syncLater(String groupId) => later.add(groupId);
}
