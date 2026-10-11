/// Response shapes from docs/API.md.
library;

import '../../domain/activity.dart';
import '../../domain/models.dart';

typedef ActivityPage = ({List<ActivityItem> items, int? nextBefore});

class UserDto {
  final String id;
  final String displayName;
  const UserDto({required this.id, required this.displayName});
  factory UserDto.fromJson(Map<String, dynamic> j) =>
      UserDto(id: j['id'] as String, displayName: j['displayName'] as String);
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
      );
}

class GroupSummaryDto {
  final String id;
  final String name;
  final String defaultCurrency;
  final int latestSeq;
  final int memberCount;
  const GroupSummaryDto({
    required this.id,
    required this.name,
    required this.defaultCurrency,
    required this.latestSeq,
    required this.memberCount,
  });
  factory GroupSummaryDto.fromJson(Map<String, dynamic> j) => GroupSummaryDto(
        id: j['id'] as String,
        name: j['name'] as String,
        defaultCurrency: j['defaultCurrency'] as String,
        latestSeq: (j['latestSeq'] as num).toInt(),
        memberCount: (j['memberCount'] as num).toInt(),
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
  const InvitePreview({required this.groupId, required this.name, required this.memberCount, required this.members});
  factory InvitePreview.fromJson(Map<String, dynamic> j) => InvitePreview(
        groupId: j['groupId'] as String,
        name: j['name'] as String,
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
