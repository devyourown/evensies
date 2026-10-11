import 'package:evensies/data/api/api_client.dart';
import 'package:evensies/data/api/dto.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/sync/sync_service.dart';
import 'package:evensies/domain/models.dart';

/// ApiClient with canned answers; anything not set throws like an unreachable server.
class FakeApi extends ApiClient {
  FakeApi(AppDatabase db) : super(db: db, baseUrl: () => 'http://fake.test');

  static const offline = ApiException(code: 'NETWORK', message: 'offline');

  /// (groupId, before) → page. Calls are recorded in [activityCalls].
  ActivityPage Function(String? groupId, int? before)? onActivity;
  final activityCalls = <(String?, int?)>[];
  List<SyncEvent> events = const [];

  @override
  Future<ActivityPage> activity({String? groupId, int? before, int limit = 50}) async {
    activityCalls.add((groupId, before));
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

  @override
  Future<PushResult> pushEvents(String groupId, List<OutboundEvent> events) async => throw offline;

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
