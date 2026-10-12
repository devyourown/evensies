import 'dart:typed_data';

import 'package:evensies/data/api/api_client.dart';
import 'package:evensies/data/api/dto.dart';
import 'package:evensies/data/db/database.dart';
import 'package:evensies/data/receipts.dart';
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
  Map<String, Object>? prefs;
  final putPrefs = <Map<String, Object>>[];

  @override
  Future<Map<String, Object>> getNotificationPrefs() async => prefs ?? (throw offline);

  @override
  Future<Map<String, Object>> putNotificationPrefs(Map<String, Object> p) async {
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

  /// groupId → memberId → methods; null = unreachable.
  Map<String, Map<String, List<PaymentMethod>>>? methods;

  @override
  Future<Map<String, List<PaymentMethod>>> groupPaymentMethods(String groupId) async =>
      (methods ?? (throw offline))[groupId] ?? const {};

  @override
  Future<Uint8List> avatar(String userId) async => throw offline;

  /// GET /info as received; null = unreachable.
  Map<String, dynamic>? info;
  @override
  Future<Map<String, dynamic>> infoJson() async => info ?? (throw offline);
  @override
  Future<ActivityUnread> activityUnread() async => throw offline;
  @override
  Future<ActivityUnread> activitySeen(int feedId, {String? groupId}) async => throw offline;

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

  /// POST /groups/{id}/attachments/{aid}: (groupId, attachmentId) calls; [onUpload] answers (null = unreachable,
  /// throw an ApiException to refuse).
  final uploads = <(String, String)>[];
  void Function(String groupId, String attachmentId)? onUpload;

  @override
  Future<void> uploadAttachment(String groupId, String attachmentId, Uint8List image, Uint8List thumb) async {
    uploads.add((groupId, attachmentId));
    (onUpload ?? (throw offline))(groupId, attachmentId);
  }

  /// GET …/attachments/{aid}(/thumb): attachmentId → bytes; a missing one is unreachable.
  final downloads = <String, Uint8List>{};

  @override
  Future<Uint8List> attachment(String groupId, String attachmentId, {bool thumb = false}) async =>
      downloads[attachmentId] ?? (throw offline);

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
  final languageUpdates = <String>[];
  bool meOffline = false;

  @override
  Future<UserDto> updateMe({String? displayName, String? homeCurrency, String? language}) async {
    if (language != null) {
      languageUpdates.add(language);
    } else {
      meUpdates.add((displayName: displayName, homeCurrency: homeCurrency));
    }
    if (meOffline) throw offline;
    return UserDto(id: 'u1', displayName: displayName ?? 'Anna', homeCurrency: homeCurrency, language: language);
  }

  /// GET /groups ids; null = unreachable. [groupKinds]: id → kind (default `group`).
  List<String>? groupIds;
  Map<String, String> groupKinds = const {};

  @override
  Future<List<GroupSummaryDto>> listGroups() async => [
        for (final id in groupIds ?? (throw offline))
          GroupSummaryDto(
              id: id, name: id, defaultCurrency: 'EUR', latestSeq: 0, memberCount: 1, kind: groupKinds[id] ?? 'group'),
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

  /// The `notificationsAllowed` of each registration, in order (null = not sent).
  final allowedSent = <bool?>[];
  bool devicesOffline = false;

  @override
  Future<void> registerDevice(String deviceId, String fcmToken, {bool? notificationsAllowed}) async {
    if (devicesOffline) throw offline;
    registered.add((deviceId, fcmToken));
    allowedSent.add(notificationsAllowed);
  }

  @override
  Future<void> unregisterDevice(String deviceId) async {
    if (devicesOffline) throw offline;
    unregistered.add(deviceId);
  }
}

/// Phase 10 endpoints: each records its calls and answers from its field, or throws like an unreachable server when
/// it is null.
class FakeApi10 extends FakeApi6 {
  FakeApi10(super.db);

  /// POST /groups bodies' `type`; [created] answers (null = unreachable).
  final createdTypes = <String?>[];
  GroupDto? created;
  @override
  Future<GroupDto> createGroup(
      {required String id,
      required String name,
      required String defaultCurrency,
      required String memberId,
      required String memberName,
      String? type}) async {
    createdTypes.add(type);
    return created ??
        GroupDto(
            id: id,
            name: name,
            defaultCurrency: defaultCurrency,
            inviteCode: 'ABCDEF',
            latestSeq: 2,
            myMemberId: memberId,
            type: type ?? 'other');
  }

  /// GET /me/blocks; null = unreachable. PUT and DELETE land in [blockCalls] as ('block'|'unblock', userId).
  List<({String userId, String displayName})>? blockList;
  final blockCalls = <(String, String)>[];
  @override
  Future<List<({String userId, String displayName})>> blocks() async => blockList ?? (throw FakeApi.offline);
  @override
  Future<void> block(String userId) async {
    blockCalls.add(('block', userId));
    if (blockList == null) throw FakeApi.offline;
    blockList = [...blockList!, (userId: userId, displayName: userId)];
  }

  @override
  Future<void> unblock(String userId) async {
    blockCalls.add(('unblock', userId));
    if (blockList == null) throw FakeApi.offline;
    blockList = [for (final b in blockList!) if (b.userId != userId) b];
  }

  /// POST …/invite-email: (groupId, memberId, email); [inviteOffline] makes it unreachable.
  final invites10 = <(String, String, String)>[];
  bool inviteOffline = false;
  @override
  Future<void> inviteByEmail(String groupId, String memberId, String email) async {
    if (inviteOffline) throw FakeApi.offline;
    invites10.add((groupId, memberId, email));
  }

  /// POST /me/email and /verify: the addresses asked for, and the account it answers ([emailOffline]: unreachable).
  final emailCodes = <String>[];
  bool emailOffline = false;
  @override
  Future<void> addEmail(String email) async {
    if (emailOffline) throw FakeApi.offline;
    emailCodes.add(email);
  }

  @override
  Future<UserDto> verifyEmail(String email, String code) async {
    if (code != '123456') throw const ApiException(status: 400, code: 'CODE_INVALID', message: 'no');
    return UserDto(id: 'u1', displayName: 'Anna', email: email);
  }

  int emailRemovals = 0;
  @override
  Future<void> removeEmail() async => emailRemovals++;

  int logoutAlls = 0;
  @override
  Future<void> logoutAll() async {
    if (emailOffline) throw FakeApi.offline;
    logoutAlls++;
  }
}

/// Phase 6 endpoints: each answers from its field, or throws like an unreachable server when it is null.
class FakeApi6 extends FakeApi {
  FakeApi6(super.db);

  ActivityUnread? unread;
  final seenCalls = <(int, String?)>[];
  @override
  Future<ActivityUnread> activityUnread() async => unread ?? (throw FakeApi.offline);
  @override
  Future<ActivityUnread> activitySeen(int feedId, {String? groupId}) async {
    seenCalls.add((feedId, groupId));
    return unread ?? (throw FakeApi.offline);
  }

  /// GET /invites/{code}; a missing code is a 404.
  final invites = <String, InvitePreview>{};
  @override
  Future<InvitePreview> invitePreview(String code) async =>
      invites[code] ?? (throw const ApiException(status: 404, code: 'NOT_FOUND', message: 'no'));

  /// POST /invites/{code}/join {memberId}: (code, memberId) calls; answers [joined].
  final joins = <(String, String)>[];
  GroupDto? joined;
  @override
  Future<GroupDto> joinExisting(String code, String memberId) async {
    joins.add((code, memberId));
    return joined ?? (throw FakeApi.offline);
  }

  FriendCode? code;
  int rotations = 0;
  @override
  Future<FriendCode> friendCode() async => code ?? (throw FakeApi.offline);
  @override
  Future<FriendCode> rotateFriendCode() async {
    rotations++;
    return code = (friendCode: 'NEW234', link: 'https://e.test/f/NEW234');
  }

  /// code → display name; a missing code is a 404.
  Map<String, String>? friendNames;
  @override
  Future<String> friendInvite(String code) async {
    final n = friendNames ?? (throw FakeApi.offline);
    return n[code] ?? (throw const ApiException(status: 404, code: 'NOT_FOUND', message: 'no'));
  }

  /// POST /friends bodies; [onAddFriend] answers (null = unreachable).
  final friendCalls = <Map<String, String?>>[];
  GroupDto Function(Map<String, String?> body)? onAddFriend;
  @override
  Future<GroupDto> addFriend(
      {required String id, required String defaultCurrency, String? code, String? userId, String? name}) async {
    final body = {'id': id, 'defaultCurrency': defaultCurrency, 'code': code, 'userId': userId, 'name': name};
    friendCalls.add(body);
    return (onAddFriend ?? (throw FakeApi.offline))(body);
  }

  /// POST /friends/{userId}/remind: the answer, or an error to throw.
  final reminded = <String>[];
  Object? remindResult;
  @override
  Future<Map<String, int>> remind(String userId) async {
    reminded.add(userId);
    final r = remindResult ?? (throw FakeApi.offline);
    if (r is Map<String, int>) return r;
    throw r;
  }

  final avatars = <String, Uint8List>{};
  final avatarUploads = <String>[];
  int avatarDeletes = 0;
  @override
  Future<Uint8List> avatar(String userId) async => avatars[userId] ?? (throw FakeApi.offline);
  @override
  Future<void> putAvatar(Uint8List jpeg) async => avatarUploads.add(String.fromCharCodes(jpeg));
  @override
  Future<void> deleteAvatar() async => avatarDeletes++;
}

/// SyncService that never touches the network from local writes; [later] records syncLater calls.
class NoSync extends SyncService {
  NoSync(AppDatabase db, [ApiClient? api, ReceiptFiles? receipts])
      : super(db: db, api: api ?? FakeApi(db), receipts: receipts);
  final later = <String>[];
  @override
  void syncLater(String groupId) => later.add(groupId);
}
