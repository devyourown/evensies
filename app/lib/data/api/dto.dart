/// Response shapes from docs/API.md.
library;

import '../../domain/activity.dart';
import '../../domain/models.dart';

typedef ActivityPage = ({List<ActivityItem> items, int? nextBefore});

class UserDto {
  final String id;
  final String displayName;

  /// Null until the user picks one, and from servers before Phase 4 (no key).
  final String? homeCurrency;

  /// The language the server writes to this user in (push, reminders); null = English or a server before Phase 9.
  final String? language;

  /// The verified account email (Phase 10; never shown to other members), and whether mail to it bounces.
  final String? email;
  final bool emailBounced;
  const UserDto(
      {required this.id,
      required this.displayName,
      this.homeCurrency,
      this.language,
      this.email,
      this.emailBounced = false});
  factory UserDto.fromJson(Map<String, dynamic> j) => UserDto(
      id: j['id'] as String,
      displayName: j['displayName'] as String,
      homeCurrency: j['homeCurrency'] as String?,
      language: j['language'] as String?,
      email: j['email'] as String?,
      emailBounced: j['emailBounced'] == true);
}

/// `GET /info` (docs/API.md 9단계, 10단계): the sign-in buttons and whether this server sends email. Offline or a
/// server before Phase 10: [fallback] (no email, Apple and Google as built in).
class ServerInfo {
  final String? appleServicesId, googleWebClientId;
  final bool devLogin;
  final bool emailLogin, appleLogin, googleLogin;

  /// The operator's contact address (Help & feedback, Report); null when not set.
  final String? supportEmail;
  const ServerInfo({
    this.appleServicesId,
    this.googleWebClientId,
    this.devLogin = false,
    this.emailLogin = false,
    this.appleLogin = true,
    this.googleLogin = true,
    this.supportEmail,
  });
  static const fallback = ServerInfo();
  factory ServerInfo.fromJson(Map<String, dynamic> j) => ServerInfo(
      appleServicesId: j['appleServicesId'] as String?,
      googleWebClientId: j['googleWebClientId'] as String?,
      devLogin: j['devLogin'] == true,
      emailLogin: j['emailLogin'] == true,
      appleLogin: j['appleLogin'] != false,
      googleLogin: j['googleLogin'] != false,
      supportEmail: switch (j['supportEmail']) { final String s when s.isNotEmpty => s, _ => null });
}

/// `GET /fx` (docs/API.md 환율): [rates] = units per 1 EUR; [date] = the latest quote date in it.
class FxTable {
  final String date;
  final Map<String, double> rates;

  /// True when the table came from this device's cache because the server couldn't answer.
  final bool offline;
  const FxTable({required this.date, required this.rates, this.offline = false});
  factory FxTable.fromJson(Map<String, dynamic> j, {bool offline = false}) => FxTable(
        date: j['date'] as String,
        rates: {for (final e in (j['rates'] as Map).entries) e.key as String: (e.value as num).toDouble()},
        offline: offline,
      );
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final UserDto user;
  const AuthResponse({required this.accessToken, required this.refreshToken, required this.user});
  factory AuthResponse.fromJson(Map<String, dynamic> j) => AuthResponse(
        accessToken: j['accessToken'] as String,
        refreshToken: j['refreshToken'] as String,
        user: UserDto.fromJson((j['user'] as Map).cast()),
      );
}

class GroupDto {
  final String id;
  final String name;
  final String defaultCurrency;
  final String inviteCode;
  final String? createdAt;
  final int latestSeq;
  final String myMemberId;
  final bool simplifyDebts;
  final SplitSpec? defaultSplit;

  /// `group` or `friend` (Phase 6); a server before it leaves the key out.
  final String kind;

  /// Phase 10: the group type, the cover photo id and deleted for everyone (defaults for an older server).
  final String type;
  final String? coverImageId;
  final bool deleted;
  const GroupDto({
    required this.id,
    required this.name,
    required this.defaultCurrency,
    required this.inviteCode,
    this.createdAt,
    required this.latestSeq,
    required this.myMemberId,
    this.simplifyDebts = true,
    this.defaultSplit,
    this.kind = 'group',
    this.type = 'other',
    this.coverImageId,
    this.deleted = false,
  });

  /// `simplifyDebts`/`defaultSplit` default to true/null when a server before Phase 3 leaves them out.
  factory GroupDto.fromJson(Map<String, dynamic> j) => GroupDto(
        id: j['id'] as String,
        name: j['name'] as String,
        defaultCurrency: j['defaultCurrency'] as String,
        inviteCode: j['inviteCode'] as String,
        createdAt: j['createdAt'] as String?,
        latestSeq: (j['latestSeq'] as num).toInt(),
        myMemberId: j['myMemberId'] as String,
        simplifyDebts: j['simplifyDebts'] as bool? ?? true,
        defaultSplit: SplitSpec.fromJson(j['defaultSplit']),
        kind: j['kind'] as String? ?? 'group',
        type: j['type'] as String? ?? 'other',
        coverImageId: j['coverImageId'] as String?,
        deleted: j['deleted'] == true,
      );
}

class GroupSummaryDto {
  final String id;
  final String name;
  final String defaultCurrency;
  final int latestSeq;
  final int memberCount;
  final String kind;
  const GroupSummaryDto({
    required this.id,
    required this.name,
    required this.defaultCurrency,
    required this.latestSeq,
    required this.memberCount,
    this.kind = 'group',
  });
  factory GroupSummaryDto.fromJson(Map<String, dynamic> j) => GroupSummaryDto(
        id: j['id'] as String,
        name: j['name'] as String,
        defaultCurrency: j['defaultCurrency'] as String,
        latestSeq: (j['latestSeq'] as num).toInt(),
        memberCount: (j['memberCount'] as num).toInt(),
        kind: j['kind'] as String? ?? 'group',
      );
}

class InviteMemberDto {
  final String id;
  final String name;
  final bool linked;
  const InviteMemberDto({required this.id, required this.name, required this.linked});
}

class InvitePreview {
  final String groupId;
  final String name;
  final int memberCount;
  final List<InviteMemberDto> members;

  /// `friend`: a placeholder friend's invite (claim only; a new member gets 409).
  final String kind;
  const InvitePreview(
      {required this.groupId, required this.name, required this.memberCount, required this.members, this.kind = 'group'});
  factory InvitePreview.fromJson(Map<String, dynamic> j) => InvitePreview(
        groupId: j['groupId'] as String,
        name: j['name'] as String,
        kind: j['kind'] as String? ?? 'group',
        memberCount: (j['memberCount'] as num).toInt(),
        members: (j['members'] as List)
            .cast<Map>()
            .map((m) => InviteMemberDto(id: m['id'] as String, name: m['name'] as String, linked: m['linked'] as bool))
            .toList(),
      );
}

class OutboundEvent {
  final String clientId;
  final String type;
  final Map<String, dynamic> payload;
  final String createdAt;
  const OutboundEvent({required this.clientId, required this.type, required this.payload, required this.createdAt});
  Map<String, dynamic> toJson() => {'clientId': clientId, 'type': type, 'payload': payload, 'createdAt': createdAt};
}

class PushResult {
  final Map<String, int> seqByClientId;
  final int latestSeq;
  const PushResult({required this.seqByClientId, required this.latestSeq});
  factory PushResult.fromJson(Map<String, dynamic> j) => PushResult(
        seqByClientId: {
          for (final r in (j['results'] as List).cast<Map>()) r['clientId'] as String: (r['seq'] as num).toInt(),
        },
        latestSeq: (j['latestSeq'] as num).toInt(),
      );
}

class ApiException implements Exception {
  final int? status;
  final String code;
  final String message;
  const ApiException({this.status, required this.code, required this.message});
  @override
  String toString() => message;
}

/// `GET /me/friend-code` (docs/API.md 친구).
typedef FriendCode = ({String friendCode, String link});

/// `GET /activity/unread` (docs/API.md 읽지 않은 활동): groupId → count, zeros left out.
class ActivityUnread {
  final int total;
  final Map<String, int> groups;
  const ActivityUnread({required this.total, this.groups = const {}});
  factory ActivityUnread.fromJson(Map<String, dynamic> j) => ActivityUnread(
        total: (j['total'] as num).toInt(),
        groups: {for (final e in ((j['groups'] as Map?) ?? const {}).entries) e.key as String: (e.value as num).toInt()},
      );
}
