// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $GroupsTable extends Groups with TableInfo<$GroupsTable, GroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultCurrencyMeta = const VerificationMeta(
    'defaultCurrency',
  );
  @override
  late final GeneratedColumn<String> defaultCurrency = GeneratedColumn<String>(
    'default_currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inviteCodeMeta = const VerificationMeta(
    'inviteCode',
  );
  @override
  late final GeneratedColumn<String> inviteCode = GeneratedColumn<String>(
    'invite_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latestSeqMeta = const VerificationMeta(
    'latestSeq',
  );
  @override
  late final GeneratedColumn<int> latestSeq = GeneratedColumn<int>(
    'latest_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _myMemberIdMeta = const VerificationMeta(
    'myMemberId',
  );
  @override
  late final GeneratedColumn<String> myMemberId = GeneratedColumn<String>(
    'my_member_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _simplifyDebtsMeta = const VerificationMeta(
    'simplifyDebts',
  );
  @override
  late final GeneratedColumn<bool> simplifyDebts = GeneratedColumn<bool>(
    'simplify_debts',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("simplify_debts" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _defaultSplitJsonMeta = const VerificationMeta(
    'defaultSplitJson',
  );
  @override
  late final GeneratedColumn<String> defaultSplitJson = GeneratedColumn<String>(
    'default_split_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('group'),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('other'),
  );
  static const VerificationMeta _coverImageIdMeta = const VerificationMeta(
    'coverImageId',
  );
  @override
  late final GeneratedColumn<String> coverImageId = GeneratedColumn<String>(
    'cover_image_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    defaultCurrency,
    inviteCode,
    latestSeq,
    myMemberId,
    simplifyDebts,
    defaultSplitJson,
    kind,
    type,
    coverImageId,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('default_currency')) {
      context.handle(
        _defaultCurrencyMeta,
        defaultCurrency.isAcceptableOrUnknown(
          data['default_currency']!,
          _defaultCurrencyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultCurrencyMeta);
    }
    if (data.containsKey('invite_code')) {
      context.handle(
        _inviteCodeMeta,
        inviteCode.isAcceptableOrUnknown(data['invite_code']!, _inviteCodeMeta),
      );
    }
    if (data.containsKey('latest_seq')) {
      context.handle(
        _latestSeqMeta,
        latestSeq.isAcceptableOrUnknown(data['latest_seq']!, _latestSeqMeta),
      );
    }
    if (data.containsKey('my_member_id')) {
      context.handle(
        _myMemberIdMeta,
        myMemberId.isAcceptableOrUnknown(
          data['my_member_id']!,
          _myMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('simplify_debts')) {
      context.handle(
        _simplifyDebtsMeta,
        simplifyDebts.isAcceptableOrUnknown(
          data['simplify_debts']!,
          _simplifyDebtsMeta,
        ),
      );
    }
    if (data.containsKey('default_split_json')) {
      context.handle(
        _defaultSplitJsonMeta,
        defaultSplitJson.isAcceptableOrUnknown(
          data['default_split_json']!,
          _defaultSplitJsonMeta,
        ),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('cover_image_id')) {
      context.handle(
        _coverImageIdMeta,
        coverImageId.isAcceptableOrUnknown(
          data['cover_image_id']!,
          _coverImageIdMeta,
        ),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      defaultCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_currency'],
      )!,
      inviteCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invite_code'],
      ),
      latestSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}latest_seq'],
      )!,
      myMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}my_member_id'],
      ),
      simplifyDebts: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}simplify_debts'],
      )!,
      defaultSplitJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_split_json'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      coverImageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_image_id'],
      ),
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $GroupsTable createAlias(String alias) {
    return $GroupsTable(attachedDatabase, alias);
  }
}

class GroupRow extends DataClass implements Insertable<GroupRow> {
  final String id;
  final String name;
  final String defaultCurrency;
  final String? inviteCode;
  final int latestSeq;
  final String? myMemberId;
  final bool simplifyDebts;

  /// SplitSpec JSON (docs/API.md), percent or shares only.
  final String? defaultSplitJson;

  /// `group` or `friend` (docs/API.md, Friends): a friend group shows as a person, not in the Groups tab.
  final String kind;

  /// Phase 10 (docs/API.md rule 17): the group type as sent, the cover photo id, and deleted for everyone.
  final String type;
  final String? coverImageId;
  final bool deleted;
  const GroupRow({
    required this.id,
    required this.name,
    required this.defaultCurrency,
    this.inviteCode,
    required this.latestSeq,
    this.myMemberId,
    required this.simplifyDebts,
    this.defaultSplitJson,
    required this.kind,
    required this.type,
    this.coverImageId,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['default_currency'] = Variable<String>(defaultCurrency);
    if (!nullToAbsent || inviteCode != null) {
      map['invite_code'] = Variable<String>(inviteCode);
    }
    map['latest_seq'] = Variable<int>(latestSeq);
    if (!nullToAbsent || myMemberId != null) {
      map['my_member_id'] = Variable<String>(myMemberId);
    }
    map['simplify_debts'] = Variable<bool>(simplifyDebts);
    if (!nullToAbsent || defaultSplitJson != null) {
      map['default_split_json'] = Variable<String>(defaultSplitJson);
    }
    map['kind'] = Variable<String>(kind);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || coverImageId != null) {
      map['cover_image_id'] = Variable<String>(coverImageId);
    }
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      id: Value(id),
      name: Value(name),
      defaultCurrency: Value(defaultCurrency),
      inviteCode: inviteCode == null && nullToAbsent
          ? const Value.absent()
          : Value(inviteCode),
      latestSeq: Value(latestSeq),
      myMemberId: myMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(myMemberId),
      simplifyDebts: Value(simplifyDebts),
      defaultSplitJson: defaultSplitJson == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultSplitJson),
      kind: Value(kind),
      type: Value(type),
      coverImageId: coverImageId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverImageId),
      deleted: Value(deleted),
    );
  }

  factory GroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      defaultCurrency: serializer.fromJson<String>(json['defaultCurrency']),
      inviteCode: serializer.fromJson<String?>(json['inviteCode']),
      latestSeq: serializer.fromJson<int>(json['latestSeq']),
      myMemberId: serializer.fromJson<String?>(json['myMemberId']),
      simplifyDebts: serializer.fromJson<bool>(json['simplifyDebts']),
      defaultSplitJson: serializer.fromJson<String?>(json['defaultSplitJson']),
      kind: serializer.fromJson<String>(json['kind']),
      type: serializer.fromJson<String>(json['type']),
      coverImageId: serializer.fromJson<String?>(json['coverImageId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'defaultCurrency': serializer.toJson<String>(defaultCurrency),
      'inviteCode': serializer.toJson<String?>(inviteCode),
      'latestSeq': serializer.toJson<int>(latestSeq),
      'myMemberId': serializer.toJson<String?>(myMemberId),
      'simplifyDebts': serializer.toJson<bool>(simplifyDebts),
      'defaultSplitJson': serializer.toJson<String?>(defaultSplitJson),
      'kind': serializer.toJson<String>(kind),
      'type': serializer.toJson<String>(type),
      'coverImageId': serializer.toJson<String?>(coverImageId),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  GroupRow copyWith({
    String? id,
    String? name,
    String? defaultCurrency,
    Value<String?> inviteCode = const Value.absent(),
    int? latestSeq,
    Value<String?> myMemberId = const Value.absent(),
    bool? simplifyDebts,
    Value<String?> defaultSplitJson = const Value.absent(),
    String? kind,
    String? type,
    Value<String?> coverImageId = const Value.absent(),
    bool? deleted,
  }) => GroupRow(
    id: id ?? this.id,
    name: name ?? this.name,
    defaultCurrency: defaultCurrency ?? this.defaultCurrency,
    inviteCode: inviteCode.present ? inviteCode.value : this.inviteCode,
    latestSeq: latestSeq ?? this.latestSeq,
    myMemberId: myMemberId.present ? myMemberId.value : this.myMemberId,
    simplifyDebts: simplifyDebts ?? this.simplifyDebts,
    defaultSplitJson: defaultSplitJson.present
        ? defaultSplitJson.value
        : this.defaultSplitJson,
    kind: kind ?? this.kind,
    type: type ?? this.type,
    coverImageId: coverImageId.present ? coverImageId.value : this.coverImageId,
    deleted: deleted ?? this.deleted,
  );
  GroupRow copyWithCompanion(GroupsCompanion data) {
    return GroupRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      defaultCurrency: data.defaultCurrency.present
          ? data.defaultCurrency.value
          : this.defaultCurrency,
      inviteCode: data.inviteCode.present
          ? data.inviteCode.value
          : this.inviteCode,
      latestSeq: data.latestSeq.present ? data.latestSeq.value : this.latestSeq,
      myMemberId: data.myMemberId.present
          ? data.myMemberId.value
          : this.myMemberId,
      simplifyDebts: data.simplifyDebts.present
          ? data.simplifyDebts.value
          : this.simplifyDebts,
      defaultSplitJson: data.defaultSplitJson.present
          ? data.defaultSplitJson.value
          : this.defaultSplitJson,
      kind: data.kind.present ? data.kind.value : this.kind,
      type: data.type.present ? data.type.value : this.type,
      coverImageId: data.coverImageId.present
          ? data.coverImageId.value
          : this.coverImageId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('defaultCurrency: $defaultCurrency, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('latestSeq: $latestSeq, ')
          ..write('myMemberId: $myMemberId, ')
          ..write('simplifyDebts: $simplifyDebts, ')
          ..write('defaultSplitJson: $defaultSplitJson, ')
          ..write('kind: $kind, ')
          ..write('type: $type, ')
          ..write('coverImageId: $coverImageId, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    defaultCurrency,
    inviteCode,
    latestSeq,
    myMemberId,
    simplifyDebts,
    defaultSplitJson,
    kind,
    type,
    coverImageId,
    deleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.defaultCurrency == this.defaultCurrency &&
          other.inviteCode == this.inviteCode &&
          other.latestSeq == this.latestSeq &&
          other.myMemberId == this.myMemberId &&
          other.simplifyDebts == this.simplifyDebts &&
          other.defaultSplitJson == this.defaultSplitJson &&
          other.kind == this.kind &&
          other.type == this.type &&
          other.coverImageId == this.coverImageId &&
          other.deleted == this.deleted);
}

class GroupsCompanion extends UpdateCompanion<GroupRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> defaultCurrency;
  final Value<String?> inviteCode;
  final Value<int> latestSeq;
  final Value<String?> myMemberId;
  final Value<bool> simplifyDebts;
  final Value<String?> defaultSplitJson;
  final Value<String> kind;
  final Value<String> type;
  final Value<String?> coverImageId;
  final Value<bool> deleted;
  final Value<int> rowid;
  const GroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.defaultCurrency = const Value.absent(),
    this.inviteCode = const Value.absent(),
    this.latestSeq = const Value.absent(),
    this.myMemberId = const Value.absent(),
    this.simplifyDebts = const Value.absent(),
    this.defaultSplitJson = const Value.absent(),
    this.kind = const Value.absent(),
    this.type = const Value.absent(),
    this.coverImageId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupsCompanion.insert({
    required String id,
    required String name,
    required String defaultCurrency,
    this.inviteCode = const Value.absent(),
    this.latestSeq = const Value.absent(),
    this.myMemberId = const Value.absent(),
    this.simplifyDebts = const Value.absent(),
    this.defaultSplitJson = const Value.absent(),
    this.kind = const Value.absent(),
    this.type = const Value.absent(),
    this.coverImageId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       defaultCurrency = Value(defaultCurrency);
  static Insertable<GroupRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? defaultCurrency,
    Expression<String>? inviteCode,
    Expression<int>? latestSeq,
    Expression<String>? myMemberId,
    Expression<bool>? simplifyDebts,
    Expression<String>? defaultSplitJson,
    Expression<String>? kind,
    Expression<String>? type,
    Expression<String>? coverImageId,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (defaultCurrency != null) 'default_currency': defaultCurrency,
      if (inviteCode != null) 'invite_code': inviteCode,
      if (latestSeq != null) 'latest_seq': latestSeq,
      if (myMemberId != null) 'my_member_id': myMemberId,
      if (simplifyDebts != null) 'simplify_debts': simplifyDebts,
      if (defaultSplitJson != null) 'default_split_json': defaultSplitJson,
      if (kind != null) 'kind': kind,
      if (type != null) 'type': type,
      if (coverImageId != null) 'cover_image_id': coverImageId,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? defaultCurrency,
    Value<String?>? inviteCode,
    Value<int>? latestSeq,
    Value<String?>? myMemberId,
    Value<bool>? simplifyDebts,
    Value<String?>? defaultSplitJson,
    Value<String>? kind,
    Value<String>? type,
    Value<String?>? coverImageId,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return GroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      inviteCode: inviteCode ?? this.inviteCode,
      latestSeq: latestSeq ?? this.latestSeq,
      myMemberId: myMemberId ?? this.myMemberId,
      simplifyDebts: simplifyDebts ?? this.simplifyDebts,
      defaultSplitJson: defaultSplitJson ?? this.defaultSplitJson,
      kind: kind ?? this.kind,
      type: type ?? this.type,
      coverImageId: coverImageId ?? this.coverImageId,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (defaultCurrency.present) {
      map['default_currency'] = Variable<String>(defaultCurrency.value);
    }
    if (inviteCode.present) {
      map['invite_code'] = Variable<String>(inviteCode.value);
    }
    if (latestSeq.present) {
      map['latest_seq'] = Variable<int>(latestSeq.value);
    }
    if (myMemberId.present) {
      map['my_member_id'] = Variable<String>(myMemberId.value);
    }
    if (simplifyDebts.present) {
      map['simplify_debts'] = Variable<bool>(simplifyDebts.value);
    }
    if (defaultSplitJson.present) {
      map['default_split_json'] = Variable<String>(defaultSplitJson.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (coverImageId.present) {
      map['cover_image_id'] = Variable<String>(coverImageId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('defaultCurrency: $defaultCurrency, ')
          ..write('inviteCode: $inviteCode, ')
          ..write('latestSeq: $latestSeq, ')
          ..write('myMemberId: $myMemberId, ')
          ..write('simplifyDebts: $simplifyDebts, ')
          ..write('defaultSplitJson: $defaultSplitJson, ')
          ..write('kind: $kind, ')
          ..write('type: $type, ')
          ..write('coverImageId: $coverImageId, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MembersTable extends Members with TableInfo<$MembersTable, MemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _removedMeta = const VerificationMeta(
    'removed',
  );
  @override
  late final GeneratedColumn<bool> removed = GeneratedColumn<bool>(
    'removed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("removed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, groupId, name, userId, removed];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'members';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemberRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('removed')) {
      context.handle(
        _removedMeta,
        removed.isAcceptableOrUnknown(data['removed']!, _removedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemberRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      removed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}removed'],
      )!,
    );
  }

  @override
  $MembersTable createAlias(String alias) {
    return $MembersTable(attachedDatabase, alias);
  }
}

class MemberRow extends DataClass implements Insertable<MemberRow> {
  final String id;
  final String groupId;
  final String name;
  final String? userId;
  final bool removed;
  const MemberRow({
    required this.id,
    required this.groupId,
    required this.name,
    this.userId,
    required this.removed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['removed'] = Variable<bool>(removed);
    return map;
  }

  MembersCompanion toCompanion(bool nullToAbsent) {
    return MembersCompanion(
      id: Value(id),
      groupId: Value(groupId),
      name: Value(name),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      removed: Value(removed),
    );
  }

  factory MemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemberRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      name: serializer.fromJson<String>(json['name']),
      userId: serializer.fromJson<String?>(json['userId']),
      removed: serializer.fromJson<bool>(json['removed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'name': serializer.toJson<String>(name),
      'userId': serializer.toJson<String?>(userId),
      'removed': serializer.toJson<bool>(removed),
    };
  }

  MemberRow copyWith({
    String? id,
    String? groupId,
    String? name,
    Value<String?> userId = const Value.absent(),
    bool? removed,
  }) => MemberRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    name: name ?? this.name,
    userId: userId.present ? userId.value : this.userId,
    removed: removed ?? this.removed,
  );
  MemberRow copyWithCompanion(MembersCompanion data) {
    return MemberRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      name: data.name.present ? data.name.value : this.name,
      userId: data.userId.present ? data.userId.value : this.userId,
      removed: data.removed.present ? data.removed.value : this.removed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemberRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('userId: $userId, ')
          ..write('removed: $removed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, groupId, name, userId, removed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemberRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.name == this.name &&
          other.userId == this.userId &&
          other.removed == this.removed);
}

class MembersCompanion extends UpdateCompanion<MemberRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> name;
  final Value<String?> userId;
  final Value<bool> removed;
  final Value<int> rowid;
  const MembersCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.name = const Value.absent(),
    this.userId = const Value.absent(),
    this.removed = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembersCompanion.insert({
    required String id,
    required String groupId,
    required String name,
    this.userId = const Value.absent(),
    this.removed = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       name = Value(name);
  static Insertable<MemberRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? name,
    Expression<String>? userId,
    Expression<bool>? removed,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (name != null) 'name': name,
      if (userId != null) 'user_id': userId,
      if (removed != null) 'removed': removed,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembersCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? name,
    Value<String?>? userId,
    Value<bool>? removed,
    Value<int>? rowid,
  }) {
    return MembersCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      removed: removed ?? this.removed,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (removed.present) {
      map['removed'] = Variable<bool>(removed.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembersCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('name: $name, ')
          ..write('userId: $userId, ')
          ..write('removed: $removed, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses
    with TableInfo<$ExpensesTable, ExpenseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fxRateToDefaultMeta = const VerificationMeta(
    'fxRateToDefault',
  );
  @override
  late final GeneratedColumn<double> fxRateToDefault = GeneratedColumn<double>(
    'fx_rate_to_default',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paidByMeta = const VerificationMeta('paidBy');
  @override
  late final GeneratedColumn<String> paidBy = GeneratedColumn<String>(
    'paid_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _refundMeta = const VerificationMeta('refund');
  @override
  late final GeneratedColumn<bool> refund = GeneratedColumn<bool>(
    'refund',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("refund" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _splitJsonMeta = const VerificationMeta(
    'splitJson',
  );
  @override
  late final GeneratedColumn<String> splitJson = GeneratedColumn<String>(
    'split_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _movedMeta = const VerificationMeta('moved');
  @override
  late final GeneratedColumn<bool> moved = GeneratedColumn<bool>(
    'moved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("moved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _recurrenceIdMeta = const VerificationMeta(
    'recurrenceId',
  );
  @override
  late final GeneratedColumn<String> recurrenceId = GeneratedColumn<String>(
    'recurrence_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurrenceMeta = const VerificationMeta(
    'occurrence',
  );
  @override
  late final GeneratedColumn<int> occurrence = GeneratedColumn<int>(
    'occurrence',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    description,
    amount,
    currency,
    fxRateToDefault,
    paidBy,
    date,
    category,
    deleted,
    notes,
    refund,
    splitJson,
    moved,
    recurrenceId,
    occurrence,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('fx_rate_to_default')) {
      context.handle(
        _fxRateToDefaultMeta,
        fxRateToDefault.isAcceptableOrUnknown(
          data['fx_rate_to_default']!,
          _fxRateToDefaultMeta,
        ),
      );
    }
    if (data.containsKey('paid_by')) {
      context.handle(
        _paidByMeta,
        paidBy.isAcceptableOrUnknown(data['paid_by']!, _paidByMeta),
      );
    } else if (isInserting) {
      context.missing(_paidByMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('refund')) {
      context.handle(
        _refundMeta,
        refund.isAcceptableOrUnknown(data['refund']!, _refundMeta),
      );
    }
    if (data.containsKey('split_json')) {
      context.handle(
        _splitJsonMeta,
        splitJson.isAcceptableOrUnknown(data['split_json']!, _splitJsonMeta),
      );
    }
    if (data.containsKey('moved')) {
      context.handle(
        _movedMeta,
        moved.isAcceptableOrUnknown(data['moved']!, _movedMeta),
      );
    }
    if (data.containsKey('recurrence_id')) {
      context.handle(
        _recurrenceIdMeta,
        recurrenceId.isAcceptableOrUnknown(
          data['recurrence_id']!,
          _recurrenceIdMeta,
        ),
      );
    }
    if (data.containsKey('occurrence')) {
      context.handle(
        _occurrenceMeta,
        occurrence.isAcceptableOrUnknown(data['occurrence']!, _occurrenceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      fxRateToDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fx_rate_to_default'],
      ),
      paidBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paid_by'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      refund: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}refund'],
      )!,
      splitJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}split_json'],
      ),
      moved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}moved'],
      )!,
      recurrenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_id'],
      ),
      occurrence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurrence'],
      ),
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class ExpenseRow extends DataClass implements Insertable<ExpenseRow> {
  final String id;
  final String groupId;
  final String description;
  final int amount;
  final String currency;
  final double? fxRateToDefault;
  final String paidBy;
  final String date;
  final String? category;
  final bool deleted;
  final String? notes;
  final bool refund;

  /// SplitSpec JSON (docs/API.md); null for an exact split.
  final String? splitJson;

  /// Deleted by a move: it counts in the other group now, so it can't be restored (docs/API.md rule 13).
  final bool moved;

  /// The repeating series and the number in it (docs/API.md, Recurring expenses); both null outside a series.
  final String? recurrenceId;
  final int? occurrence;
  const ExpenseRow({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.currency,
    this.fxRateToDefault,
    required this.paidBy,
    required this.date,
    this.category,
    required this.deleted,
    this.notes,
    required this.refund,
    this.splitJson,
    required this.moved,
    this.recurrenceId,
    this.occurrence,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['description'] = Variable<String>(description);
    map['amount'] = Variable<int>(amount);
    map['currency'] = Variable<String>(currency);
    if (!nullToAbsent || fxRateToDefault != null) {
      map['fx_rate_to_default'] = Variable<double>(fxRateToDefault);
    }
    map['paid_by'] = Variable<String>(paidBy);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['deleted'] = Variable<bool>(deleted);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['refund'] = Variable<bool>(refund);
    if (!nullToAbsent || splitJson != null) {
      map['split_json'] = Variable<String>(splitJson);
    }
    map['moved'] = Variable<bool>(moved);
    if (!nullToAbsent || recurrenceId != null) {
      map['recurrence_id'] = Variable<String>(recurrenceId);
    }
    if (!nullToAbsent || occurrence != null) {
      map['occurrence'] = Variable<int>(occurrence);
    }
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      groupId: Value(groupId),
      description: Value(description),
      amount: Value(amount),
      currency: Value(currency),
      fxRateToDefault: fxRateToDefault == null && nullToAbsent
          ? const Value.absent()
          : Value(fxRateToDefault),
      paidBy: Value(paidBy),
      date: Value(date),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      deleted: Value(deleted),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      refund: Value(refund),
      splitJson: splitJson == null && nullToAbsent
          ? const Value.absent()
          : Value(splitJson),
      moved: Value(moved),
      recurrenceId: recurrenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceId),
      occurrence: occurrence == null && nullToAbsent
          ? const Value.absent()
          : Value(occurrence),
    );
  }

  factory ExpenseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      description: serializer.fromJson<String>(json['description']),
      amount: serializer.fromJson<int>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      fxRateToDefault: serializer.fromJson<double?>(json['fxRateToDefault']),
      paidBy: serializer.fromJson<String>(json['paidBy']),
      date: serializer.fromJson<String>(json['date']),
      category: serializer.fromJson<String?>(json['category']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      notes: serializer.fromJson<String?>(json['notes']),
      refund: serializer.fromJson<bool>(json['refund']),
      splitJson: serializer.fromJson<String?>(json['splitJson']),
      moved: serializer.fromJson<bool>(json['moved']),
      recurrenceId: serializer.fromJson<String?>(json['recurrenceId']),
      occurrence: serializer.fromJson<int?>(json['occurrence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'description': serializer.toJson<String>(description),
      'amount': serializer.toJson<int>(amount),
      'currency': serializer.toJson<String>(currency),
      'fxRateToDefault': serializer.toJson<double?>(fxRateToDefault),
      'paidBy': serializer.toJson<String>(paidBy),
      'date': serializer.toJson<String>(date),
      'category': serializer.toJson<String?>(category),
      'deleted': serializer.toJson<bool>(deleted),
      'notes': serializer.toJson<String?>(notes),
      'refund': serializer.toJson<bool>(refund),
      'splitJson': serializer.toJson<String?>(splitJson),
      'moved': serializer.toJson<bool>(moved),
      'recurrenceId': serializer.toJson<String?>(recurrenceId),
      'occurrence': serializer.toJson<int?>(occurrence),
    };
  }

  ExpenseRow copyWith({
    String? id,
    String? groupId,
    String? description,
    int? amount,
    String? currency,
    Value<double?> fxRateToDefault = const Value.absent(),
    String? paidBy,
    String? date,
    Value<String?> category = const Value.absent(),
    bool? deleted,
    Value<String?> notes = const Value.absent(),
    bool? refund,
    Value<String?> splitJson = const Value.absent(),
    bool? moved,
    Value<String?> recurrenceId = const Value.absent(),
    Value<int?> occurrence = const Value.absent(),
  }) => ExpenseRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    description: description ?? this.description,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    fxRateToDefault: fxRateToDefault.present
        ? fxRateToDefault.value
        : this.fxRateToDefault,
    paidBy: paidBy ?? this.paidBy,
    date: date ?? this.date,
    category: category.present ? category.value : this.category,
    deleted: deleted ?? this.deleted,
    notes: notes.present ? notes.value : this.notes,
    refund: refund ?? this.refund,
    splitJson: splitJson.present ? splitJson.value : this.splitJson,
    moved: moved ?? this.moved,
    recurrenceId: recurrenceId.present ? recurrenceId.value : this.recurrenceId,
    occurrence: occurrence.present ? occurrence.value : this.occurrence,
  );
  ExpenseRow copyWithCompanion(ExpensesCompanion data) {
    return ExpenseRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      description: data.description.present
          ? data.description.value
          : this.description,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      fxRateToDefault: data.fxRateToDefault.present
          ? data.fxRateToDefault.value
          : this.fxRateToDefault,
      paidBy: data.paidBy.present ? data.paidBy.value : this.paidBy,
      date: data.date.present ? data.date.value : this.date,
      category: data.category.present ? data.category.value : this.category,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      notes: data.notes.present ? data.notes.value : this.notes,
      refund: data.refund.present ? data.refund.value : this.refund,
      splitJson: data.splitJson.present ? data.splitJson.value : this.splitJson,
      moved: data.moved.present ? data.moved.value : this.moved,
      recurrenceId: data.recurrenceId.present
          ? data.recurrenceId.value
          : this.recurrenceId,
      occurrence: data.occurrence.present
          ? data.occurrence.value
          : this.occurrence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('fxRateToDefault: $fxRateToDefault, ')
          ..write('paidBy: $paidBy, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('deleted: $deleted, ')
          ..write('notes: $notes, ')
          ..write('refund: $refund, ')
          ..write('splitJson: $splitJson, ')
          ..write('moved: $moved, ')
          ..write('recurrenceId: $recurrenceId, ')
          ..write('occurrence: $occurrence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    description,
    amount,
    currency,
    fxRateToDefault,
    paidBy,
    date,
    category,
    deleted,
    notes,
    refund,
    splitJson,
    moved,
    recurrenceId,
    occurrence,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.description == this.description &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.fxRateToDefault == this.fxRateToDefault &&
          other.paidBy == this.paidBy &&
          other.date == this.date &&
          other.category == this.category &&
          other.deleted == this.deleted &&
          other.notes == this.notes &&
          other.refund == this.refund &&
          other.splitJson == this.splitJson &&
          other.moved == this.moved &&
          other.recurrenceId == this.recurrenceId &&
          other.occurrence == this.occurrence);
}

class ExpensesCompanion extends UpdateCompanion<ExpenseRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> description;
  final Value<int> amount;
  final Value<String> currency;
  final Value<double?> fxRateToDefault;
  final Value<String> paidBy;
  final Value<String> date;
  final Value<String?> category;
  final Value<bool> deleted;
  final Value<String?> notes;
  final Value<bool> refund;
  final Value<String?> splitJson;
  final Value<bool> moved;
  final Value<String?> recurrenceId;
  final Value<int?> occurrence;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.description = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.fxRateToDefault = const Value.absent(),
    this.paidBy = const Value.absent(),
    this.date = const Value.absent(),
    this.category = const Value.absent(),
    this.deleted = const Value.absent(),
    this.notes = const Value.absent(),
    this.refund = const Value.absent(),
    this.splitJson = const Value.absent(),
    this.moved = const Value.absent(),
    this.recurrenceId = const Value.absent(),
    this.occurrence = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    required String groupId,
    required String description,
    required int amount,
    required String currency,
    this.fxRateToDefault = const Value.absent(),
    required String paidBy,
    required String date,
    this.category = const Value.absent(),
    this.deleted = const Value.absent(),
    this.notes = const Value.absent(),
    this.refund = const Value.absent(),
    this.splitJson = const Value.absent(),
    this.moved = const Value.absent(),
    this.recurrenceId = const Value.absent(),
    this.occurrence = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       description = Value(description),
       amount = Value(amount),
       currency = Value(currency),
       paidBy = Value(paidBy),
       date = Value(date);
  static Insertable<ExpenseRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? description,
    Expression<int>? amount,
    Expression<String>? currency,
    Expression<double>? fxRateToDefault,
    Expression<String>? paidBy,
    Expression<String>? date,
    Expression<String>? category,
    Expression<bool>? deleted,
    Expression<String>? notes,
    Expression<bool>? refund,
    Expression<String>? splitJson,
    Expression<bool>? moved,
    Expression<String>? recurrenceId,
    Expression<int>? occurrence,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (description != null) 'description': description,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (fxRateToDefault != null) 'fx_rate_to_default': fxRateToDefault,
      if (paidBy != null) 'paid_by': paidBy,
      if (date != null) 'date': date,
      if (category != null) 'category': category,
      if (deleted != null) 'deleted': deleted,
      if (notes != null) 'notes': notes,
      if (refund != null) 'refund': refund,
      if (splitJson != null) 'split_json': splitJson,
      if (moved != null) 'moved': moved,
      if (recurrenceId != null) 'recurrence_id': recurrenceId,
      if (occurrence != null) 'occurrence': occurrence,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? description,
    Value<int>? amount,
    Value<String>? currency,
    Value<double?>? fxRateToDefault,
    Value<String>? paidBy,
    Value<String>? date,
    Value<String?>? category,
    Value<bool>? deleted,
    Value<String?>? notes,
    Value<bool>? refund,
    Value<String?>? splitJson,
    Value<bool>? moved,
    Value<String?>? recurrenceId,
    Value<int?>? occurrence,
    Value<int>? rowid,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      fxRateToDefault: fxRateToDefault ?? this.fxRateToDefault,
      paidBy: paidBy ?? this.paidBy,
      date: date ?? this.date,
      category: category ?? this.category,
      deleted: deleted ?? this.deleted,
      notes: notes ?? this.notes,
      refund: refund ?? this.refund,
      splitJson: splitJson ?? this.splitJson,
      moved: moved ?? this.moved,
      recurrenceId: recurrenceId ?? this.recurrenceId,
      occurrence: occurrence ?? this.occurrence,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (fxRateToDefault.present) {
      map['fx_rate_to_default'] = Variable<double>(fxRateToDefault.value);
    }
    if (paidBy.present) {
      map['paid_by'] = Variable<String>(paidBy.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (refund.present) {
      map['refund'] = Variable<bool>(refund.value);
    }
    if (splitJson.present) {
      map['split_json'] = Variable<String>(splitJson.value);
    }
    if (moved.present) {
      map['moved'] = Variable<bool>(moved.value);
    }
    if (recurrenceId.present) {
      map['recurrence_id'] = Variable<String>(recurrenceId.value);
    }
    if (occurrence.present) {
      map['occurrence'] = Variable<int>(occurrence.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('fxRateToDefault: $fxRateToDefault, ')
          ..write('paidBy: $paidBy, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('deleted: $deleted, ')
          ..write('notes: $notes, ')
          ..write('refund: $refund, ')
          ..write('splitJson: $splitJson, ')
          ..write('moved: $moved, ')
          ..write('recurrenceId: $recurrenceId, ')
          ..write('occurrence: $occurrence, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpenseSharesTable extends ExpenseShares
    with TableInfo<$ExpenseSharesTable, ExpenseShareRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpenseSharesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
    'expense_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [expenseId, memberId, amount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_shares';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseShareRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {expenseId, memberId};
  @override
  ExpenseShareRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseShareRow(
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
    );
  }

  @override
  $ExpenseSharesTable createAlias(String alias) {
    return $ExpenseSharesTable(attachedDatabase, alias);
  }
}

class ExpenseShareRow extends DataClass implements Insertable<ExpenseShareRow> {
  final String expenseId;
  final String memberId;
  final int amount;
  const ExpenseShareRow({
    required this.expenseId,
    required this.memberId,
    required this.amount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['expense_id'] = Variable<String>(expenseId);
    map['member_id'] = Variable<String>(memberId);
    map['amount'] = Variable<int>(amount);
    return map;
  }

  ExpenseSharesCompanion toCompanion(bool nullToAbsent) {
    return ExpenseSharesCompanion(
      expenseId: Value(expenseId),
      memberId: Value(memberId),
      amount: Value(amount),
    );
  }

  factory ExpenseShareRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseShareRow(
      expenseId: serializer.fromJson<String>(json['expenseId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      amount: serializer.fromJson<int>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'expenseId': serializer.toJson<String>(expenseId),
      'memberId': serializer.toJson<String>(memberId),
      'amount': serializer.toJson<int>(amount),
    };
  }

  ExpenseShareRow copyWith({
    String? expenseId,
    String? memberId,
    int? amount,
  }) => ExpenseShareRow(
    expenseId: expenseId ?? this.expenseId,
    memberId: memberId ?? this.memberId,
    amount: amount ?? this.amount,
  );
  ExpenseShareRow copyWithCompanion(ExpenseSharesCompanion data) {
    return ExpenseShareRow(
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseShareRow(')
          ..write('expenseId: $expenseId, ')
          ..write('memberId: $memberId, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(expenseId, memberId, amount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseShareRow &&
          other.expenseId == this.expenseId &&
          other.memberId == this.memberId &&
          other.amount == this.amount);
}

class ExpenseSharesCompanion extends UpdateCompanion<ExpenseShareRow> {
  final Value<String> expenseId;
  final Value<String> memberId;
  final Value<int> amount;
  final Value<int> rowid;
  const ExpenseSharesCompanion({
    this.expenseId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.amount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpenseSharesCompanion.insert({
    required String expenseId,
    required String memberId,
    required int amount,
    this.rowid = const Value.absent(),
  }) : expenseId = Value(expenseId),
       memberId = Value(memberId),
       amount = Value(amount);
  static Insertable<ExpenseShareRow> custom({
    Expression<String>? expenseId,
    Expression<String>? memberId,
    Expression<int>? amount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (expenseId != null) 'expense_id': expenseId,
      if (memberId != null) 'member_id': memberId,
      if (amount != null) 'amount': amount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpenseSharesCompanion copyWith({
    Value<String>? expenseId,
    Value<String>? memberId,
    Value<int>? amount,
    Value<int>? rowid,
  }) {
    return ExpenseSharesCompanion(
      expenseId: expenseId ?? this.expenseId,
      memberId: memberId ?? this.memberId,
      amount: amount ?? this.amount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseSharesCompanion(')
          ..write('expenseId: $expenseId, ')
          ..write('memberId: $memberId, ')
          ..write('amount: $amount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensePayersTable extends ExpensePayers
    with TableInfo<$ExpensePayersTable, ExpensePayerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensePayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
    'expense_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [expenseId, memberId, amount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_payers';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpensePayerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {expenseId, memberId};
  @override
  ExpensePayerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpensePayerRow(
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
    );
  }

  @override
  $ExpensePayersTable createAlias(String alias) {
    return $ExpensePayersTable(attachedDatabase, alias);
  }
}

class ExpensePayerRow extends DataClass implements Insertable<ExpensePayerRow> {
  final String expenseId;
  final String memberId;
  final int amount;
  const ExpensePayerRow({
    required this.expenseId,
    required this.memberId,
    required this.amount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['expense_id'] = Variable<String>(expenseId);
    map['member_id'] = Variable<String>(memberId);
    map['amount'] = Variable<int>(amount);
    return map;
  }

  ExpensePayersCompanion toCompanion(bool nullToAbsent) {
    return ExpensePayersCompanion(
      expenseId: Value(expenseId),
      memberId: Value(memberId),
      amount: Value(amount),
    );
  }

  factory ExpensePayerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpensePayerRow(
      expenseId: serializer.fromJson<String>(json['expenseId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      amount: serializer.fromJson<int>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'expenseId': serializer.toJson<String>(expenseId),
      'memberId': serializer.toJson<String>(memberId),
      'amount': serializer.toJson<int>(amount),
    };
  }

  ExpensePayerRow copyWith({
    String? expenseId,
    String? memberId,
    int? amount,
  }) => ExpensePayerRow(
    expenseId: expenseId ?? this.expenseId,
    memberId: memberId ?? this.memberId,
    amount: amount ?? this.amount,
  );
  ExpensePayerRow copyWithCompanion(ExpensePayersCompanion data) {
    return ExpensePayerRow(
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpensePayerRow(')
          ..write('expenseId: $expenseId, ')
          ..write('memberId: $memberId, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(expenseId, memberId, amount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpensePayerRow &&
          other.expenseId == this.expenseId &&
          other.memberId == this.memberId &&
          other.amount == this.amount);
}

class ExpensePayersCompanion extends UpdateCompanion<ExpensePayerRow> {
  final Value<String> expenseId;
  final Value<String> memberId;
  final Value<int> amount;
  final Value<int> rowid;
  const ExpensePayersCompanion({
    this.expenseId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.amount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensePayersCompanion.insert({
    required String expenseId,
    required String memberId,
    required int amount,
    this.rowid = const Value.absent(),
  }) : expenseId = Value(expenseId),
       memberId = Value(memberId),
       amount = Value(amount);
  static Insertable<ExpensePayerRow> custom({
    Expression<String>? expenseId,
    Expression<String>? memberId,
    Expression<int>? amount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (expenseId != null) 'expense_id': expenseId,
      if (memberId != null) 'member_id': memberId,
      if (amount != null) 'amount': amount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensePayersCompanion copyWith({
    Value<String>? expenseId,
    Value<String>? memberId,
    Value<int>? amount,
    Value<int>? rowid,
  }) {
    return ExpensePayersCompanion(
      expenseId: expenseId ?? this.expenseId,
      memberId: memberId ?? this.memberId,
      amount: amount ?? this.amount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensePayersCompanion(')
          ..write('expenseId: $expenseId, ')
          ..write('memberId: $memberId, ')
          ..write('amount: $amount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTable extends Payments
    with TableInfo<$PaymentsTable, PaymentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromMemberMeta = const VerificationMeta(
    'fromMember',
  );
  @override
  late final GeneratedColumn<String> fromMember = GeneratedColumn<String>(
    'from_member',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toMemberMeta = const VerificationMeta(
    'toMember',
  );
  @override
  late final GeneratedColumn<String> toMember = GeneratedColumn<String>(
    'to_member',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('confirmed'),
  );
  static const VerificationMeta _replacedMeta = const VerificationMeta(
    'replaced',
  );
  @override
  late final GeneratedColumn<bool> replaced = GeneratedColumn<bool>(
    'replaced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("replaced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    fromMember,
    toMember,
    amount,
    currency,
    date,
    deleted,
    status,
    replaced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<PaymentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('from_member')) {
      context.handle(
        _fromMemberMeta,
        fromMember.isAcceptableOrUnknown(data['from_member']!, _fromMemberMeta),
      );
    } else if (isInserting) {
      context.missing(_fromMemberMeta);
    }
    if (data.containsKey('to_member')) {
      context.handle(
        _toMemberMeta,
        toMember.isAcceptableOrUnknown(data['to_member']!, _toMemberMeta),
      );
    } else if (isInserting) {
      context.missing(_toMemberMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('replaced')) {
      context.handle(
        _replacedMeta,
        replaced.isAcceptableOrUnknown(data['replaced']!, _replacedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PaymentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PaymentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      fromMember: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_member'],
      )!,
      toMember: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_member'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      replaced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}replaced'],
      )!,
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }
}

class PaymentRow extends DataClass implements Insertable<PaymentRow> {
  final String id;
  final String groupId;
  final String fromMember;
  final String toMember;
  final int amount;
  final String currency;
  final String date;
  final bool deleted;
  final String status;

  /// Deleted by an edit (`replacedBy`): never restored (docs/API.md rule 7).
  final bool replaced;
  const PaymentRow({
    required this.id,
    required this.groupId,
    required this.fromMember,
    required this.toMember,
    required this.amount,
    required this.currency,
    required this.date,
    required this.deleted,
    required this.status,
    required this.replaced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['from_member'] = Variable<String>(fromMember);
    map['to_member'] = Variable<String>(toMember);
    map['amount'] = Variable<int>(amount);
    map['currency'] = Variable<String>(currency);
    map['date'] = Variable<String>(date);
    map['deleted'] = Variable<bool>(deleted);
    map['status'] = Variable<String>(status);
    map['replaced'] = Variable<bool>(replaced);
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      groupId: Value(groupId),
      fromMember: Value(fromMember),
      toMember: Value(toMember),
      amount: Value(amount),
      currency: Value(currency),
      date: Value(date),
      deleted: Value(deleted),
      status: Value(status),
      replaced: Value(replaced),
    );
  }

  factory PaymentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PaymentRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      fromMember: serializer.fromJson<String>(json['fromMember']),
      toMember: serializer.fromJson<String>(json['toMember']),
      amount: serializer.fromJson<int>(json['amount']),
      currency: serializer.fromJson<String>(json['currency']),
      date: serializer.fromJson<String>(json['date']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      status: serializer.fromJson<String>(json['status']),
      replaced: serializer.fromJson<bool>(json['replaced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'fromMember': serializer.toJson<String>(fromMember),
      'toMember': serializer.toJson<String>(toMember),
      'amount': serializer.toJson<int>(amount),
      'currency': serializer.toJson<String>(currency),
      'date': serializer.toJson<String>(date),
      'deleted': serializer.toJson<bool>(deleted),
      'status': serializer.toJson<String>(status),
      'replaced': serializer.toJson<bool>(replaced),
    };
  }

  PaymentRow copyWith({
    String? id,
    String? groupId,
    String? fromMember,
    String? toMember,
    int? amount,
    String? currency,
    String? date,
    bool? deleted,
    String? status,
    bool? replaced,
  }) => PaymentRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    fromMember: fromMember ?? this.fromMember,
    toMember: toMember ?? this.toMember,
    amount: amount ?? this.amount,
    currency: currency ?? this.currency,
    date: date ?? this.date,
    deleted: deleted ?? this.deleted,
    status: status ?? this.status,
    replaced: replaced ?? this.replaced,
  );
  PaymentRow copyWithCompanion(PaymentsCompanion data) {
    return PaymentRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      fromMember: data.fromMember.present
          ? data.fromMember.value
          : this.fromMember,
      toMember: data.toMember.present ? data.toMember.value : this.toMember,
      amount: data.amount.present ? data.amount.value : this.amount,
      currency: data.currency.present ? data.currency.value : this.currency,
      date: data.date.present ? data.date.value : this.date,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      status: data.status.present ? data.status.value : this.status,
      replaced: data.replaced.present ? data.replaced.value : this.replaced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PaymentRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('fromMember: $fromMember, ')
          ..write('toMember: $toMember, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('date: $date, ')
          ..write('deleted: $deleted, ')
          ..write('status: $status, ')
          ..write('replaced: $replaced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    fromMember,
    toMember,
    amount,
    currency,
    date,
    deleted,
    status,
    replaced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PaymentRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.fromMember == this.fromMember &&
          other.toMember == this.toMember &&
          other.amount == this.amount &&
          other.currency == this.currency &&
          other.date == this.date &&
          other.deleted == this.deleted &&
          other.status == this.status &&
          other.replaced == this.replaced);
}

class PaymentsCompanion extends UpdateCompanion<PaymentRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> fromMember;
  final Value<String> toMember;
  final Value<int> amount;
  final Value<String> currency;
  final Value<String> date;
  final Value<bool> deleted;
  final Value<String> status;
  final Value<bool> replaced;
  final Value<int> rowid;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.fromMember = const Value.absent(),
    this.toMember = const Value.absent(),
    this.amount = const Value.absent(),
    this.currency = const Value.absent(),
    this.date = const Value.absent(),
    this.deleted = const Value.absent(),
    this.status = const Value.absent(),
    this.replaced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PaymentsCompanion.insert({
    required String id,
    required String groupId,
    required String fromMember,
    required String toMember,
    required int amount,
    required String currency,
    required String date,
    this.deleted = const Value.absent(),
    this.status = const Value.absent(),
    this.replaced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       fromMember = Value(fromMember),
       toMember = Value(toMember),
       amount = Value(amount),
       currency = Value(currency),
       date = Value(date);
  static Insertable<PaymentRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? fromMember,
    Expression<String>? toMember,
    Expression<int>? amount,
    Expression<String>? currency,
    Expression<String>? date,
    Expression<bool>? deleted,
    Expression<String>? status,
    Expression<bool>? replaced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (fromMember != null) 'from_member': fromMember,
      if (toMember != null) 'to_member': toMember,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (date != null) 'date': date,
      if (deleted != null) 'deleted': deleted,
      if (status != null) 'status': status,
      if (replaced != null) 'replaced': replaced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PaymentsCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? fromMember,
    Value<String>? toMember,
    Value<int>? amount,
    Value<String>? currency,
    Value<String>? date,
    Value<bool>? deleted,
    Value<String>? status,
    Value<bool>? replaced,
    Value<int>? rowid,
  }) {
    return PaymentsCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      fromMember: fromMember ?? this.fromMember,
      toMember: toMember ?? this.toMember,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      deleted: deleted ?? this.deleted,
      status: status ?? this.status,
      replaced: replaced ?? this.replaced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (fromMember.present) {
      map['from_member'] = Variable<String>(fromMember.value);
    }
    if (toMember.present) {
      map['to_member'] = Variable<String>(toMember.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (replaced.present) {
      map['replaced'] = Variable<bool>(replaced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('fromMember: $fromMember, ')
          ..write('toMember: $toMember, ')
          ..write('amount: $amount, ')
          ..write('currency: $currency, ')
          ..write('date: $date, ')
          ..write('deleted: $deleted, ')
          ..write('status: $status, ')
          ..write('replaced: $replaced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CommentsTable extends Comments
    with TableInfo<$CommentsTable, CommentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CommentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
    'expense_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentIdMeta = const VerificationMeta(
    'paymentId',
  );
  @override
  late final GeneratedColumn<String> paymentId = GeneratedColumn<String>(
    'payment_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorMemberIdMeta = const VerificationMeta(
    'authorMemberId',
  );
  @override
  late final GeneratedColumn<String> authorMemberId = GeneratedColumn<String>(
    'author_member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    expenseId,
    paymentId,
    authorMemberId,
    body,
    createdAt,
    deleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'comments';
  @override
  VerificationContext validateIntegrity(
    Insertable<CommentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    }
    if (data.containsKey('payment_id')) {
      context.handle(
        _paymentIdMeta,
        paymentId.isAcceptableOrUnknown(data['payment_id']!, _paymentIdMeta),
      );
    }
    if (data.containsKey('author_member_id')) {
      context.handle(
        _authorMemberIdMeta,
        authorMemberId.isAcceptableOrUnknown(
          data['author_member_id']!,
          _authorMemberIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_authorMemberIdMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['text']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CommentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CommentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_id'],
      ),
      paymentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_id'],
      ),
      authorMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_member_id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $CommentsTable createAlias(String alias) {
    return $CommentsTable(attachedDatabase, alias);
  }
}

class CommentRow extends DataClass implements Insertable<CommentRow> {
  final String id;
  final String groupId;

  /// Exactly one of the two is set (Phase 6: comments on payments).
  final String? expenseId;
  final String? paymentId;
  final String authorMemberId;
  final String body;
  final String createdAt;
  final bool deleted;
  const CommentRow({
    required this.id,
    required this.groupId,
    this.expenseId,
    this.paymentId,
    required this.authorMemberId,
    required this.body,
    required this.createdAt,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    if (!nullToAbsent || expenseId != null) {
      map['expense_id'] = Variable<String>(expenseId);
    }
    if (!nullToAbsent || paymentId != null) {
      map['payment_id'] = Variable<String>(paymentId);
    }
    map['author_member_id'] = Variable<String>(authorMemberId);
    map['text'] = Variable<String>(body);
    map['created_at'] = Variable<String>(createdAt);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  CommentsCompanion toCompanion(bool nullToAbsent) {
    return CommentsCompanion(
      id: Value(id),
      groupId: Value(groupId),
      expenseId: expenseId == null && nullToAbsent
          ? const Value.absent()
          : Value(expenseId),
      paymentId: paymentId == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentId),
      authorMemberId: Value(authorMemberId),
      body: Value(body),
      createdAt: Value(createdAt),
      deleted: Value(deleted),
    );
  }

  factory CommentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CommentRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      expenseId: serializer.fromJson<String?>(json['expenseId']),
      paymentId: serializer.fromJson<String?>(json['paymentId']),
      authorMemberId: serializer.fromJson<String>(json['authorMemberId']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'expenseId': serializer.toJson<String?>(expenseId),
      'paymentId': serializer.toJson<String?>(paymentId),
      'authorMemberId': serializer.toJson<String>(authorMemberId),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<String>(createdAt),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  CommentRow copyWith({
    String? id,
    String? groupId,
    Value<String?> expenseId = const Value.absent(),
    Value<String?> paymentId = const Value.absent(),
    String? authorMemberId,
    String? body,
    String? createdAt,
    bool? deleted,
  }) => CommentRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    expenseId: expenseId.present ? expenseId.value : this.expenseId,
    paymentId: paymentId.present ? paymentId.value : this.paymentId,
    authorMemberId: authorMemberId ?? this.authorMemberId,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
    deleted: deleted ?? this.deleted,
  );
  CommentRow copyWithCompanion(CommentsCompanion data) {
    return CommentRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      paymentId: data.paymentId.present ? data.paymentId.value : this.paymentId,
      authorMemberId: data.authorMemberId.present
          ? data.authorMemberId.value
          : this.authorMemberId,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CommentRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('expenseId: $expenseId, ')
          ..write('paymentId: $paymentId, ')
          ..write('authorMemberId: $authorMemberId, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    expenseId,
    paymentId,
    authorMemberId,
    body,
    createdAt,
    deleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CommentRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.expenseId == this.expenseId &&
          other.paymentId == this.paymentId &&
          other.authorMemberId == this.authorMemberId &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.deleted == this.deleted);
}

class CommentsCompanion extends UpdateCompanion<CommentRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String?> expenseId;
  final Value<String?> paymentId;
  final Value<String> authorMemberId;
  final Value<String> body;
  final Value<String> createdAt;
  final Value<bool> deleted;
  final Value<int> rowid;
  const CommentsCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.paymentId = const Value.absent(),
    this.authorMemberId = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CommentsCompanion.insert({
    required String id,
    required String groupId,
    this.expenseId = const Value.absent(),
    this.paymentId = const Value.absent(),
    required String authorMemberId,
    required String body,
    required String createdAt,
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       authorMemberId = Value(authorMemberId),
       body = Value(body),
       createdAt = Value(createdAt);
  static Insertable<CommentRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? expenseId,
    Expression<String>? paymentId,
    Expression<String>? authorMemberId,
    Expression<String>? body,
    Expression<String>? createdAt,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (expenseId != null) 'expense_id': expenseId,
      if (paymentId != null) 'payment_id': paymentId,
      if (authorMemberId != null) 'author_member_id': authorMemberId,
      if (body != null) 'text': body,
      if (createdAt != null) 'created_at': createdAt,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CommentsCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String?>? expenseId,
    Value<String?>? paymentId,
    Value<String>? authorMemberId,
    Value<String>? body,
    Value<String>? createdAt,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return CommentsCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      expenseId: expenseId ?? this.expenseId,
      paymentId: paymentId ?? this.paymentId,
      authorMemberId: authorMemberId ?? this.authorMemberId,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (paymentId.present) {
      map['payment_id'] = Variable<String>(paymentId.value);
    }
    if (authorMemberId.present) {
      map['author_member_id'] = Variable<String>(authorMemberId.value);
    }
    if (body.present) {
      map['text'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CommentsCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('expenseId: $expenseId, ')
          ..write('paymentId: $paymentId, ')
          ..write('authorMemberId: $authorMemberId, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, AttachmentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
    'expense_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [id, groupId, expenseId, deleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttachmentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttachmentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_id'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class AttachmentRow extends DataClass implements Insertable<AttachmentRow> {
  final String id;
  final String groupId;
  final String expenseId;
  final bool deleted;
  const AttachmentRow({
    required this.id,
    required this.groupId,
    required this.expenseId,
    required this.deleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['expense_id'] = Variable<String>(expenseId);
    map['deleted'] = Variable<bool>(deleted);
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      groupId: Value(groupId),
      expenseId: Value(expenseId),
      deleted: Value(deleted),
    );
  }

  factory AttachmentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      expenseId: serializer.fromJson<String>(json['expenseId']),
      deleted: serializer.fromJson<bool>(json['deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'expenseId': serializer.toJson<String>(expenseId),
      'deleted': serializer.toJson<bool>(deleted),
    };
  }

  AttachmentRow copyWith({
    String? id,
    String? groupId,
    String? expenseId,
    bool? deleted,
  }) => AttachmentRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    expenseId: expenseId ?? this.expenseId,
    deleted: deleted ?? this.deleted,
  );
  AttachmentRow copyWithCompanion(AttachmentsCompanion data) {
    return AttachmentRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('expenseId: $expenseId, ')
          ..write('deleted: $deleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, groupId, expenseId, deleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.expenseId == this.expenseId &&
          other.deleted == this.deleted);
}

class AttachmentsCompanion extends UpdateCompanion<AttachmentRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> expenseId;
  final Value<bool> deleted;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String id,
    required String groupId,
    required String expenseId,
    this.deleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       expenseId = Value(expenseId);
  static Insertable<AttachmentRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? expenseId,
    Expression<bool>? deleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (expenseId != null) 'expense_id': expenseId,
      if (deleted != null) 'deleted': deleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? expenseId,
    Value<bool>? deleted,
    Value<int>? rowid,
  }) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      expenseId: expenseId ?? this.expenseId,
      deleted: deleted ?? this.deleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('expenseId: $expenseId, ')
          ..write('deleted: $deleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingUploadsTable extends PendingUploads
    with TableInfo<$PendingUploadsTable, PendingUploadRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingUploadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attachmentIdMeta = const VerificationMeta(
    'attachmentId',
  );
  @override
  late final GeneratedColumn<String> attachmentId = GeneratedColumn<String>(
    'attachment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [attachmentId, groupId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_uploads';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingUploadRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attachment_id')) {
      context.handle(
        _attachmentIdMeta,
        attachmentId.isAcceptableOrUnknown(
          data['attachment_id']!,
          _attachmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attachmentIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {attachmentId};
  @override
  PendingUploadRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingUploadRow(
      attachmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingUploadsTable createAlias(String alias) {
    return $PendingUploadsTable(attachedDatabase, alias);
  }
}

class PendingUploadRow extends DataClass
    implements Insertable<PendingUploadRow> {
  final String attachmentId;
  final String groupId;
  final String createdAt;
  const PendingUploadRow({
    required this.attachmentId,
    required this.groupId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attachment_id'] = Variable<String>(attachmentId);
    map['group_id'] = Variable<String>(groupId);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  PendingUploadsCompanion toCompanion(bool nullToAbsent) {
    return PendingUploadsCompanion(
      attachmentId: Value(attachmentId),
      groupId: Value(groupId),
      createdAt: Value(createdAt),
    );
  }

  factory PendingUploadRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingUploadRow(
      attachmentId: serializer.fromJson<String>(json['attachmentId']),
      groupId: serializer.fromJson<String>(json['groupId']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attachmentId': serializer.toJson<String>(attachmentId),
      'groupId': serializer.toJson<String>(groupId),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  PendingUploadRow copyWith({
    String? attachmentId,
    String? groupId,
    String? createdAt,
  }) => PendingUploadRow(
    attachmentId: attachmentId ?? this.attachmentId,
    groupId: groupId ?? this.groupId,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingUploadRow copyWithCompanion(PendingUploadsCompanion data) {
    return PendingUploadRow(
      attachmentId: data.attachmentId.present
          ? data.attachmentId.value
          : this.attachmentId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingUploadRow(')
          ..write('attachmentId: $attachmentId, ')
          ..write('groupId: $groupId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(attachmentId, groupId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingUploadRow &&
          other.attachmentId == this.attachmentId &&
          other.groupId == this.groupId &&
          other.createdAt == this.createdAt);
}

class PendingUploadsCompanion extends UpdateCompanion<PendingUploadRow> {
  final Value<String> attachmentId;
  final Value<String> groupId;
  final Value<String> createdAt;
  final Value<int> rowid;
  const PendingUploadsCompanion({
    this.attachmentId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingUploadsCompanion.insert({
    required String attachmentId,
    required String groupId,
    required String createdAt,
    this.rowid = const Value.absent(),
  }) : attachmentId = Value(attachmentId),
       groupId = Value(groupId),
       createdAt = Value(createdAt);
  static Insertable<PendingUploadRow> custom({
    Expression<String>? attachmentId,
    Expression<String>? groupId,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (groupId != null) 'group_id': groupId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingUploadsCompanion copyWith({
    Value<String>? attachmentId,
    Value<String>? groupId,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return PendingUploadsCompanion(
      attachmentId: attachmentId ?? this.attachmentId,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attachmentId.present) {
      map['attachment_id'] = Variable<String>(attachmentId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingUploadsCompanion(')
          ..write('attachmentId: $attachmentId, ')
          ..write('groupId: $groupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurrencesTable extends Recurrences
    with TableInfo<$RecurrencesTable, RecurrenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeZoneMeta = const VerificationMeta(
    'timeZone',
  );
  @override
  late final GeneratedColumn<String> timeZone = GeneratedColumn<String>(
    'time_zone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateJsonMeta = const VerificationMeta(
    'templateJson',
  );
  @override
  late final GeneratedColumn<String> templateJson = GeneratedColumn<String>(
    'template_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _remindDaysBeforeMeta = const VerificationMeta(
    'remindDaysBefore',
  );
  @override
  late final GeneratedColumn<int> remindDaysBefore = GeneratedColumn<int>(
    'remind_days_before',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    frequency,
    startDate,
    timeZone,
    templateJson,
    deleted,
    remindDaysBefore,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurrences';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurrenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('time_zone')) {
      context.handle(
        _timeZoneMeta,
        timeZone.isAcceptableOrUnknown(data['time_zone']!, _timeZoneMeta),
      );
    } else if (isInserting) {
      context.missing(_timeZoneMeta);
    }
    if (data.containsKey('template_json')) {
      context.handle(
        _templateJsonMeta,
        templateJson.isAcceptableOrUnknown(
          data['template_json']!,
          _templateJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateJsonMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('remind_days_before')) {
      context.handle(
        _remindDaysBeforeMeta,
        remindDaysBefore.isAcceptableOrUnknown(
          data['remind_days_before']!,
          _remindDaysBeforeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurrenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurrenceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      timeZone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone'],
      )!,
      templateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_json'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      remindDaysBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remind_days_before'],
      ),
    );
  }

  @override
  $RecurrencesTable createAlias(String alias) {
    return $RecurrencesTable(attachedDatabase, alias);
  }
}

class RecurrenceRow extends DataClass implements Insertable<RecurrenceRow> {
  final String id;
  final String groupId;
  final String frequency;
  final String startDate;
  final String timeZone;

  /// The `expense.created` payload the server repeats, as JSON.
  final String templateJson;
  final bool deleted;

  /// Days before each repeat the server emails a reminder (rule 18), null for none.
  final int? remindDaysBefore;
  const RecurrenceRow({
    required this.id,
    required this.groupId,
    required this.frequency,
    required this.startDate,
    required this.timeZone,
    required this.templateJson,
    required this.deleted,
    this.remindDaysBefore,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['frequency'] = Variable<String>(frequency);
    map['start_date'] = Variable<String>(startDate);
    map['time_zone'] = Variable<String>(timeZone);
    map['template_json'] = Variable<String>(templateJson);
    map['deleted'] = Variable<bool>(deleted);
    if (!nullToAbsent || remindDaysBefore != null) {
      map['remind_days_before'] = Variable<int>(remindDaysBefore);
    }
    return map;
  }

  RecurrencesCompanion toCompanion(bool nullToAbsent) {
    return RecurrencesCompanion(
      id: Value(id),
      groupId: Value(groupId),
      frequency: Value(frequency),
      startDate: Value(startDate),
      timeZone: Value(timeZone),
      templateJson: Value(templateJson),
      deleted: Value(deleted),
      remindDaysBefore: remindDaysBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(remindDaysBefore),
    );
  }

  factory RecurrenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurrenceRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      frequency: serializer.fromJson<String>(json['frequency']),
      startDate: serializer.fromJson<String>(json['startDate']),
      timeZone: serializer.fromJson<String>(json['timeZone']),
      templateJson: serializer.fromJson<String>(json['templateJson']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      remindDaysBefore: serializer.fromJson<int?>(json['remindDaysBefore']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'frequency': serializer.toJson<String>(frequency),
      'startDate': serializer.toJson<String>(startDate),
      'timeZone': serializer.toJson<String>(timeZone),
      'templateJson': serializer.toJson<String>(templateJson),
      'deleted': serializer.toJson<bool>(deleted),
      'remindDaysBefore': serializer.toJson<int?>(remindDaysBefore),
    };
  }

  RecurrenceRow copyWith({
    String? id,
    String? groupId,
    String? frequency,
    String? startDate,
    String? timeZone,
    String? templateJson,
    bool? deleted,
    Value<int?> remindDaysBefore = const Value.absent(),
  }) => RecurrenceRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    frequency: frequency ?? this.frequency,
    startDate: startDate ?? this.startDate,
    timeZone: timeZone ?? this.timeZone,
    templateJson: templateJson ?? this.templateJson,
    deleted: deleted ?? this.deleted,
    remindDaysBefore: remindDaysBefore.present
        ? remindDaysBefore.value
        : this.remindDaysBefore,
  );
  RecurrenceRow copyWithCompanion(RecurrencesCompanion data) {
    return RecurrenceRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      timeZone: data.timeZone.present ? data.timeZone.value : this.timeZone,
      templateJson: data.templateJson.present
          ? data.templateJson.value
          : this.templateJson,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      remindDaysBefore: data.remindDaysBefore.present
          ? data.remindDaysBefore.value
          : this.remindDaysBefore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurrenceRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('frequency: $frequency, ')
          ..write('startDate: $startDate, ')
          ..write('timeZone: $timeZone, ')
          ..write('templateJson: $templateJson, ')
          ..write('deleted: $deleted, ')
          ..write('remindDaysBefore: $remindDaysBefore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    frequency,
    startDate,
    timeZone,
    templateJson,
    deleted,
    remindDaysBefore,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurrenceRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.frequency == this.frequency &&
          other.startDate == this.startDate &&
          other.timeZone == this.timeZone &&
          other.templateJson == this.templateJson &&
          other.deleted == this.deleted &&
          other.remindDaysBefore == this.remindDaysBefore);
}

class RecurrencesCompanion extends UpdateCompanion<RecurrenceRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> frequency;
  final Value<String> startDate;
  final Value<String> timeZone;
  final Value<String> templateJson;
  final Value<bool> deleted;
  final Value<int?> remindDaysBefore;
  final Value<int> rowid;
  const RecurrencesCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.frequency = const Value.absent(),
    this.startDate = const Value.absent(),
    this.timeZone = const Value.absent(),
    this.templateJson = const Value.absent(),
    this.deleted = const Value.absent(),
    this.remindDaysBefore = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurrencesCompanion.insert({
    required String id,
    required String groupId,
    required String frequency,
    required String startDate,
    required String timeZone,
    required String templateJson,
    this.deleted = const Value.absent(),
    this.remindDaysBefore = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       frequency = Value(frequency),
       startDate = Value(startDate),
       timeZone = Value(timeZone),
       templateJson = Value(templateJson);
  static Insertable<RecurrenceRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? frequency,
    Expression<String>? startDate,
    Expression<String>? timeZone,
    Expression<String>? templateJson,
    Expression<bool>? deleted,
    Expression<int>? remindDaysBefore,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (frequency != null) 'frequency': frequency,
      if (startDate != null) 'start_date': startDate,
      if (timeZone != null) 'time_zone': timeZone,
      if (templateJson != null) 'template_json': templateJson,
      if (deleted != null) 'deleted': deleted,
      if (remindDaysBefore != null) 'remind_days_before': remindDaysBefore,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurrencesCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? frequency,
    Value<String>? startDate,
    Value<String>? timeZone,
    Value<String>? templateJson,
    Value<bool>? deleted,
    Value<int?>? remindDaysBefore,
    Value<int>? rowid,
  }) {
    return RecurrencesCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      timeZone: timeZone ?? this.timeZone,
      templateJson: templateJson ?? this.templateJson,
      deleted: deleted ?? this.deleted,
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (timeZone.present) {
      map['time_zone'] = Variable<String>(timeZone.value);
    }
    if (templateJson.present) {
      map['template_json'] = Variable<String>(templateJson.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (remindDaysBefore.present) {
      map['remind_days_before'] = Variable<int>(remindDaysBefore.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurrencesCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('frequency: $frequency, ')
          ..write('startDate: $startDate, ')
          ..write('timeZone: $timeZone, ')
          ..write('templateJson: $templateJson, ')
          ..write('deleted: $deleted, ')
          ..write('remindDaysBefore: $remindDaysBefore, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActivityTable extends Activity
    with TableInfo<$ActivityTable, ActivityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActivityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedIdMeta = const VerificationMeta('feedId');
  @override
  late final GeneratedColumn<int> feedId = GeneratedColumn<int>(
    'feed_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [groupId, seq, feedId, createdAt, json];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'activity';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActivityRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('feed_id')) {
      context.handle(
        _feedIdMeta,
        feedId.isAcceptableOrUnknown(data['feed_id']!, _feedIdMeta),
      );
    } else if (isInserting) {
      context.missing(_feedIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, seq};
  @override
  ActivityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActivityRow(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      feedId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}feed_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $ActivityTable createAlias(String alias) {
    return $ActivityTable(attachedDatabase, alias);
  }
}

class ActivityRow extends DataClass implements Insertable<ActivityRow> {
  final String groupId;
  final int seq;
  final int feedId;
  final String createdAt;
  final String json;
  const ActivityRow({
    required this.groupId,
    required this.seq,
    required this.feedId,
    required this.createdAt,
    required this.json,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['seq'] = Variable<int>(seq);
    map['feed_id'] = Variable<int>(feedId);
    map['created_at'] = Variable<String>(createdAt);
    map['json'] = Variable<String>(json);
    return map;
  }

  ActivityCompanion toCompanion(bool nullToAbsent) {
    return ActivityCompanion(
      groupId: Value(groupId),
      seq: Value(seq),
      feedId: Value(feedId),
      createdAt: Value(createdAt),
      json: Value(json),
    );
  }

  factory ActivityRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActivityRow(
      groupId: serializer.fromJson<String>(json['groupId']),
      seq: serializer.fromJson<int>(json['seq']),
      feedId: serializer.fromJson<int>(json['feedId']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'seq': serializer.toJson<int>(seq),
      'feedId': serializer.toJson<int>(feedId),
      'createdAt': serializer.toJson<String>(createdAt),
      'json': serializer.toJson<String>(json),
    };
  }

  ActivityRow copyWith({
    String? groupId,
    int? seq,
    int? feedId,
    String? createdAt,
    String? json,
  }) => ActivityRow(
    groupId: groupId ?? this.groupId,
    seq: seq ?? this.seq,
    feedId: feedId ?? this.feedId,
    createdAt: createdAt ?? this.createdAt,
    json: json ?? this.json,
  );
  ActivityRow copyWithCompanion(ActivityCompanion data) {
    return ActivityRow(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      seq: data.seq.present ? data.seq.value : this.seq,
      feedId: data.feedId.present ? data.feedId.value : this.feedId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActivityRow(')
          ..write('groupId: $groupId, ')
          ..write('seq: $seq, ')
          ..write('feedId: $feedId, ')
          ..write('createdAt: $createdAt, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(groupId, seq, feedId, createdAt, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActivityRow &&
          other.groupId == this.groupId &&
          other.seq == this.seq &&
          other.feedId == this.feedId &&
          other.createdAt == this.createdAt &&
          other.json == this.json);
}

class ActivityCompanion extends UpdateCompanion<ActivityRow> {
  final Value<String> groupId;
  final Value<int> seq;
  final Value<int> feedId;
  final Value<String> createdAt;
  final Value<String> json;
  final Value<int> rowid;
  const ActivityCompanion({
    this.groupId = const Value.absent(),
    this.seq = const Value.absent(),
    this.feedId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActivityCompanion.insert({
    required String groupId,
    required int seq,
    required int feedId,
    required String createdAt,
    required String json,
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       seq = Value(seq),
       feedId = Value(feedId),
       createdAt = Value(createdAt),
       json = Value(json);
  static Insertable<ActivityRow> custom({
    Expression<String>? groupId,
    Expression<int>? seq,
    Expression<int>? feedId,
    Expression<String>? createdAt,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (seq != null) 'seq': seq,
      if (feedId != null) 'feed_id': feedId,
      if (createdAt != null) 'created_at': createdAt,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActivityCompanion copyWith({
    Value<String>? groupId,
    Value<int>? seq,
    Value<int>? feedId,
    Value<String>? createdAt,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return ActivityCompanion(
      groupId: groupId ?? this.groupId,
      seq: seq ?? this.seq,
      feedId: feedId ?? this.feedId,
      createdAt: createdAt ?? this.createdAt,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (feedId.present) {
      map['feed_id'] = Variable<int>(feedId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActivityCompanion(')
          ..write('groupId: $groupId, ')
          ..write('seq: $seq, ')
          ..write('feedId: $feedId, ')
          ..write('createdAt: $createdAt, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<String> sentAt = GeneratedColumn<String>(
    'sent_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rejectedMeta = const VerificationMeta(
    'rejected',
  );
  @override
  late final GeneratedColumn<String> rejected = GeneratedColumn<String>(
    'rejected',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientId,
    groupId,
    type,
    payloadJson,
    createdAt,
    sentAt,
    rejected,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    }
    if (data.containsKey('rejected')) {
      context.handle(
        _rejectedMeta,
        rejected.isAcceptableOrUnknown(data['rejected']!, _rejectedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientId};
  @override
  OutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxRow(
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sent_at'],
      ),
      rejected: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rejected'],
      ),
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxRow extends DataClass implements Insertable<OutboxRow> {
  final String clientId;
  final String groupId;
  final String type;
  final String payloadJson;
  final String createdAt;
  final String? sentAt;

  /// The server's error code once the event was refused on its own (docs/API.md, Rejected events): never pushed or
  /// applied again; the row is deleted after the user was told.
  final String? rejected;
  const OutboxRow({
    required this.clientId,
    required this.groupId,
    required this.type,
    required this.payloadJson,
    required this.createdAt,
    this.sentAt,
    this.rejected,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_id'] = Variable<String>(clientId);
    map['group_id'] = Variable<String>(groupId);
    map['type'] = Variable<String>(type);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || sentAt != null) {
      map['sent_at'] = Variable<String>(sentAt);
    }
    if (!nullToAbsent || rejected != null) {
      map['rejected'] = Variable<String>(rejected);
    }
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      clientId: Value(clientId),
      groupId: Value(groupId),
      type: Value(type),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      sentAt: sentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sentAt),
      rejected: rejected == null && nullToAbsent
          ? const Value.absent()
          : Value(rejected),
    );
  }

  factory OutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxRow(
      clientId: serializer.fromJson<String>(json['clientId']),
      groupId: serializer.fromJson<String>(json['groupId']),
      type: serializer.fromJson<String>(json['type']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      sentAt: serializer.fromJson<String?>(json['sentAt']),
      rejected: serializer.fromJson<String?>(json['rejected']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientId': serializer.toJson<String>(clientId),
      'groupId': serializer.toJson<String>(groupId),
      'type': serializer.toJson<String>(type),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<String>(createdAt),
      'sentAt': serializer.toJson<String?>(sentAt),
      'rejected': serializer.toJson<String?>(rejected),
    };
  }

  OutboxRow copyWith({
    String? clientId,
    String? groupId,
    String? type,
    String? payloadJson,
    String? createdAt,
    Value<String?> sentAt = const Value.absent(),
    Value<String?> rejected = const Value.absent(),
  }) => OutboxRow(
    clientId: clientId ?? this.clientId,
    groupId: groupId ?? this.groupId,
    type: type ?? this.type,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
    sentAt: sentAt.present ? sentAt.value : this.sentAt,
    rejected: rejected.present ? rejected.value : this.rejected,
  );
  OutboxRow copyWithCompanion(OutboxCompanion data) {
    return OutboxRow(
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      type: data.type.present ? data.type.value : this.type,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
      rejected: data.rejected.present ? data.rejected.value : this.rejected,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxRow(')
          ..write('clientId: $clientId, ')
          ..write('groupId: $groupId, ')
          ..write('type: $type, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('sentAt: $sentAt, ')
          ..write('rejected: $rejected')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientId,
    groupId,
    type,
    payloadJson,
    createdAt,
    sentAt,
    rejected,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxRow &&
          other.clientId == this.clientId &&
          other.groupId == this.groupId &&
          other.type == this.type &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.sentAt == this.sentAt &&
          other.rejected == this.rejected);
}

class OutboxCompanion extends UpdateCompanion<OutboxRow> {
  final Value<String> clientId;
  final Value<String> groupId;
  final Value<String> type;
  final Value<String> payloadJson;
  final Value<String> createdAt;
  final Value<String?> sentAt;
  final Value<String?> rejected;
  final Value<int> rowid;
  const OutboxCompanion({
    this.clientId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.type = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.rejected = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxCompanion.insert({
    required String clientId,
    required String groupId,
    required String type,
    required String payloadJson,
    required String createdAt,
    this.sentAt = const Value.absent(),
    this.rejected = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientId = Value(clientId),
       groupId = Value(groupId),
       type = Value(type),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<OutboxRow> custom({
    Expression<String>? clientId,
    Expression<String>? groupId,
    Expression<String>? type,
    Expression<String>? payloadJson,
    Expression<String>? createdAt,
    Expression<String>? sentAt,
    Expression<String>? rejected,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientId != null) 'client_id': clientId,
      if (groupId != null) 'group_id': groupId,
      if (type != null) 'type': type,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (sentAt != null) 'sent_at': sentAt,
      if (rejected != null) 'rejected': rejected,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxCompanion copyWith({
    Value<String>? clientId,
    Value<String>? groupId,
    Value<String>? type,
    Value<String>? payloadJson,
    Value<String>? createdAt,
    Value<String?>? sentAt,
    Value<String?>? rejected,
    Value<int>? rowid,
  }) {
    return OutboxCompanion(
      clientId: clientId ?? this.clientId,
      groupId: groupId ?? this.groupId,
      type: type ?? this.type,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      sentAt: sentAt ?? this.sentAt,
      rejected: rejected ?? this.rejected,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<String>(sentAt.value);
    }
    if (rejected.present) {
      map['rejected'] = Variable<String>(rejected.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('clientId: $clientId, ')
          ..write('groupId: $groupId, ')
          ..write('type: $type, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('sentAt: $sentAt, ')
          ..write('rejected: $rejected, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeqMeta = const VerificationMeta(
    'lastSeq',
  );
  @override
  late final GeneratedColumn<int> lastSeq = GeneratedColumn<int>(
    'last_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [groupId, lastSeq];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('last_seq')) {
      context.handle(
        _lastSeqMeta,
        lastSeq.isAcceptableOrUnknown(data['last_seq']!, _lastSeqMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      lastSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seq'],
      )!,
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final String groupId;
  final int lastSeq;
  const SyncStateRow({required this.groupId, required this.lastSeq});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['last_seq'] = Variable<int>(lastSeq);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(groupId: Value(groupId), lastSeq: Value(lastSeq));
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      groupId: serializer.fromJson<String>(json['groupId']),
      lastSeq: serializer.fromJson<int>(json['lastSeq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'lastSeq': serializer.toJson<int>(lastSeq),
    };
  }

  SyncStateRow copyWith({String? groupId, int? lastSeq}) => SyncStateRow(
    groupId: groupId ?? this.groupId,
    lastSeq: lastSeq ?? this.lastSeq,
  );
  SyncStateRow copyWithCompanion(SyncStateCompanion data) {
    return SyncStateRow(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      lastSeq: data.lastSeq.present ? data.lastSeq.value : this.lastSeq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('groupId: $groupId, ')
          ..write('lastSeq: $lastSeq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(groupId, lastSeq);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.groupId == this.groupId &&
          other.lastSeq == this.lastSeq);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<String> groupId;
  final Value<int> lastSeq;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.groupId = const Value.absent(),
    this.lastSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String groupId,
    this.lastSeq = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId);
  static Insertable<SyncStateRow> custom({
    Expression<String>? groupId,
    Expression<int>? lastSeq,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (lastSeq != null) 'last_seq': lastSeq,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? groupId,
    Value<int>? lastSeq,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      groupId: groupId ?? this.groupId,
      lastSeq: lastSeq ?? this.lastSeq,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (lastSeq.present) {
      map['last_seq'] = Variable<int>(lastSeq.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('groupId: $groupId, ')
          ..write('lastSeq: $lastSeq, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionTable extends Session with TableInfo<$SessionTable, SessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _accessTokenMeta = const VerificationMeta(
    'accessToken',
  );
  @override
  late final GeneratedColumn<String> accessToken = GeneratedColumn<String>(
    'access_token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refreshTokenMeta = const VerificationMeta(
    'refreshToken',
  );
  @override
  late final GeneratedColumn<String> refreshToken = GeneratedColumn<String>(
    'refresh_token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homeCurrencyMeta = const VerificationMeta(
    'homeCurrency',
  );
  @override
  late final GeneratedColumn<String> homeCurrency = GeneratedColumn<String>(
    'home_currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailBouncedMeta = const VerificationMeta(
    'emailBounced',
  );
  @override
  late final GeneratedColumn<bool> emailBounced = GeneratedColumn<bool>(
    'email_bounced',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("email_bounced" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accessToken,
    refreshToken,
    userId,
    displayName,
    homeCurrency,
    email,
    emailBounced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('access_token')) {
      context.handle(
        _accessTokenMeta,
        accessToken.isAcceptableOrUnknown(
          data['access_token']!,
          _accessTokenMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accessTokenMeta);
    }
    if (data.containsKey('refresh_token')) {
      context.handle(
        _refreshTokenMeta,
        refreshToken.isAcceptableOrUnknown(
          data['refresh_token']!,
          _refreshTokenMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_refreshTokenMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('home_currency')) {
      context.handle(
        _homeCurrencyMeta,
        homeCurrency.isAcceptableOrUnknown(
          data['home_currency']!,
          _homeCurrencyMeta,
        ),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('email_bounced')) {
      context.handle(
        _emailBouncedMeta,
        emailBounced.isAcceptableOrUnknown(
          data['email_bounced']!,
          _emailBouncedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      accessToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_token'],
      )!,
      refreshToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refresh_token'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      homeCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_currency'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      emailBounced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}email_bounced'],
      ),
    );
  }

  @override
  $SessionTable createAlias(String alias) {
    return $SessionTable(attachedDatabase, alias);
  }
}

class SessionRow extends DataClass implements Insertable<SessionRow> {
  final int id;
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String displayName;

  /// UserDto.homeCurrency (docs/API.md); null until the user picks one (the app then uses the region's currency).
  final String? homeCurrency;

  /// UserDto.email / emailBounced (Phase 10): the verified account address, shown only in Settings.
  final String? email;
  final bool? emailBounced;
  const SessionRow({
    required this.id,
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.displayName,
    this.homeCurrency,
    this.email,
    this.emailBounced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['access_token'] = Variable<String>(accessToken);
    map['refresh_token'] = Variable<String>(refreshToken);
    map['user_id'] = Variable<String>(userId);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || homeCurrency != null) {
      map['home_currency'] = Variable<String>(homeCurrency);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || emailBounced != null) {
      map['email_bounced'] = Variable<bool>(emailBounced);
    }
    return map;
  }

  SessionCompanion toCompanion(bool nullToAbsent) {
    return SessionCompanion(
      id: Value(id),
      accessToken: Value(accessToken),
      refreshToken: Value(refreshToken),
      userId: Value(userId),
      displayName: Value(displayName),
      homeCurrency: homeCurrency == null && nullToAbsent
          ? const Value.absent()
          : Value(homeCurrency),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      emailBounced: emailBounced == null && nullToAbsent
          ? const Value.absent()
          : Value(emailBounced),
    );
  }

  factory SessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionRow(
      id: serializer.fromJson<int>(json['id']),
      accessToken: serializer.fromJson<String>(json['accessToken']),
      refreshToken: serializer.fromJson<String>(json['refreshToken']),
      userId: serializer.fromJson<String>(json['userId']),
      displayName: serializer.fromJson<String>(json['displayName']),
      homeCurrency: serializer.fromJson<String?>(json['homeCurrency']),
      email: serializer.fromJson<String?>(json['email']),
      emailBounced: serializer.fromJson<bool?>(json['emailBounced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'accessToken': serializer.toJson<String>(accessToken),
      'refreshToken': serializer.toJson<String>(refreshToken),
      'userId': serializer.toJson<String>(userId),
      'displayName': serializer.toJson<String>(displayName),
      'homeCurrency': serializer.toJson<String?>(homeCurrency),
      'email': serializer.toJson<String?>(email),
      'emailBounced': serializer.toJson<bool?>(emailBounced),
    };
  }

  SessionRow copyWith({
    int? id,
    String? accessToken,
    String? refreshToken,
    String? userId,
    String? displayName,
    Value<String?> homeCurrency = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<bool?> emailBounced = const Value.absent(),
  }) => SessionRow(
    id: id ?? this.id,
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    userId: userId ?? this.userId,
    displayName: displayName ?? this.displayName,
    homeCurrency: homeCurrency.present ? homeCurrency.value : this.homeCurrency,
    email: email.present ? email.value : this.email,
    emailBounced: emailBounced.present ? emailBounced.value : this.emailBounced,
  );
  SessionRow copyWithCompanion(SessionCompanion data) {
    return SessionRow(
      id: data.id.present ? data.id.value : this.id,
      accessToken: data.accessToken.present
          ? data.accessToken.value
          : this.accessToken,
      refreshToken: data.refreshToken.present
          ? data.refreshToken.value
          : this.refreshToken,
      userId: data.userId.present ? data.userId.value : this.userId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      homeCurrency: data.homeCurrency.present
          ? data.homeCurrency.value
          : this.homeCurrency,
      email: data.email.present ? data.email.value : this.email,
      emailBounced: data.emailBounced.present
          ? data.emailBounced.value
          : this.emailBounced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionRow(')
          ..write('id: $id, ')
          ..write('accessToken: $accessToken, ')
          ..write('refreshToken: $refreshToken, ')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('homeCurrency: $homeCurrency, ')
          ..write('email: $email, ')
          ..write('emailBounced: $emailBounced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accessToken,
    refreshToken,
    userId,
    displayName,
    homeCurrency,
    email,
    emailBounced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionRow &&
          other.id == this.id &&
          other.accessToken == this.accessToken &&
          other.refreshToken == this.refreshToken &&
          other.userId == this.userId &&
          other.displayName == this.displayName &&
          other.homeCurrency == this.homeCurrency &&
          other.email == this.email &&
          other.emailBounced == this.emailBounced);
}

class SessionCompanion extends UpdateCompanion<SessionRow> {
  final Value<int> id;
  final Value<String> accessToken;
  final Value<String> refreshToken;
  final Value<String> userId;
  final Value<String> displayName;
  final Value<String?> homeCurrency;
  final Value<String?> email;
  final Value<bool?> emailBounced;
  const SessionCompanion({
    this.id = const Value.absent(),
    this.accessToken = const Value.absent(),
    this.refreshToken = const Value.absent(),
    this.userId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.homeCurrency = const Value.absent(),
    this.email = const Value.absent(),
    this.emailBounced = const Value.absent(),
  });
  SessionCompanion.insert({
    this.id = const Value.absent(),
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String displayName,
    this.homeCurrency = const Value.absent(),
    this.email = const Value.absent(),
    this.emailBounced = const Value.absent(),
  }) : accessToken = Value(accessToken),
       refreshToken = Value(refreshToken),
       userId = Value(userId),
       displayName = Value(displayName);
  static Insertable<SessionRow> custom({
    Expression<int>? id,
    Expression<String>? accessToken,
    Expression<String>? refreshToken,
    Expression<String>? userId,
    Expression<String>? displayName,
    Expression<String>? homeCurrency,
    Expression<String>? email,
    Expression<bool>? emailBounced,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accessToken != null) 'access_token': accessToken,
      if (refreshToken != null) 'refresh_token': refreshToken,
      if (userId != null) 'user_id': userId,
      if (displayName != null) 'display_name': displayName,
      if (homeCurrency != null) 'home_currency': homeCurrency,
      if (email != null) 'email': email,
      if (emailBounced != null) 'email_bounced': emailBounced,
    });
  }

  SessionCompanion copyWith({
    Value<int>? id,
    Value<String>? accessToken,
    Value<String>? refreshToken,
    Value<String>? userId,
    Value<String>? displayName,
    Value<String?>? homeCurrency,
    Value<String?>? email,
    Value<bool?>? emailBounced,
  }) {
    return SessionCompanion(
      id: id ?? this.id,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      homeCurrency: homeCurrency ?? this.homeCurrency,
      email: email ?? this.email,
      emailBounced: emailBounced ?? this.emailBounced,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (accessToken.present) {
      map['access_token'] = Variable<String>(accessToken.value);
    }
    if (refreshToken.present) {
      map['refresh_token'] = Variable<String>(refreshToken.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (homeCurrency.present) {
      map['home_currency'] = Variable<String>(homeCurrency.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (emailBounced.present) {
      map['email_bounced'] = Variable<bool>(emailBounced.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionCompanion(')
          ..write('id: $id, ')
          ..write('accessToken: $accessToken, ')
          ..write('refreshToken: $refreshToken, ')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('homeCurrency: $homeCurrency, ')
          ..write('email: $email, ')
          ..write('emailBounced: $emailBounced')
          ..write(')'))
        .toString();
  }
}

class $FxDaysTable extends FxDays with TableInfo<$FxDaysTable, FxDayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FxDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratesJsonMeta = const VerificationMeta(
    'ratesJson',
  );
  @override
  late final GeneratedColumn<String> ratesJson = GeneratedColumn<String>(
    'rates_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<String> fetchedAt = GeneratedColumn<String>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [day, ratesJson, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fx_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<FxDayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('rates_json')) {
      context.handle(
        _ratesJsonMeta,
        ratesJson.isAcceptableOrUnknown(data['rates_json']!, _ratesJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_ratesJsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  FxDayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FxDayRow(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      ratesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rates_json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $FxDaysTable createAlias(String alias) {
    return $FxDaysTable(attachedDatabase, alias);
  }
}

class FxDayRow extends DataClass implements Insertable<FxDayRow> {
  final String day;
  final String ratesJson;
  final String fetchedAt;
  const FxDayRow({
    required this.day,
    required this.ratesJson,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<String>(day);
    map['rates_json'] = Variable<String>(ratesJson);
    map['fetched_at'] = Variable<String>(fetchedAt);
    return map;
  }

  FxDaysCompanion toCompanion(bool nullToAbsent) {
    return FxDaysCompanion(
      day: Value(day),
      ratesJson: Value(ratesJson),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory FxDayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FxDayRow(
      day: serializer.fromJson<String>(json['day']),
      ratesJson: serializer.fromJson<String>(json['ratesJson']),
      fetchedAt: serializer.fromJson<String>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<String>(day),
      'ratesJson': serializer.toJson<String>(ratesJson),
      'fetchedAt': serializer.toJson<String>(fetchedAt),
    };
  }

  FxDayRow copyWith({String? day, String? ratesJson, String? fetchedAt}) =>
      FxDayRow(
        day: day ?? this.day,
        ratesJson: ratesJson ?? this.ratesJson,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  FxDayRow copyWithCompanion(FxDaysCompanion data) {
    return FxDayRow(
      day: data.day.present ? data.day.value : this.day,
      ratesJson: data.ratesJson.present ? data.ratesJson.value : this.ratesJson,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FxDayRow(')
          ..write('day: $day, ')
          ..write('ratesJson: $ratesJson, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, ratesJson, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FxDayRow &&
          other.day == this.day &&
          other.ratesJson == this.ratesJson &&
          other.fetchedAt == this.fetchedAt);
}

class FxDaysCompanion extends UpdateCompanion<FxDayRow> {
  final Value<String> day;
  final Value<String> ratesJson;
  final Value<String> fetchedAt;
  final Value<int> rowid;
  const FxDaysCompanion({
    this.day = const Value.absent(),
    this.ratesJson = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FxDaysCompanion.insert({
    required String day,
    required String ratesJson,
    required String fetchedAt,
    this.rowid = const Value.absent(),
  }) : day = Value(day),
       ratesJson = Value(ratesJson),
       fetchedAt = Value(fetchedAt);
  static Insertable<FxDayRow> custom({
    Expression<String>? day,
    Expression<String>? ratesJson,
    Expression<String>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (ratesJson != null) 'rates_json': ratesJson,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FxDaysCompanion copyWith({
    Value<String>? day,
    Value<String>? ratesJson,
    Value<String>? fetchedAt,
    Value<int>? rowid,
  }) {
    return FxDaysCompanion(
      day: day ?? this.day,
      ratesJson: ratesJson ?? this.ratesJson,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (ratesJson.present) {
      map['rates_json'] = Variable<String>(ratesJson.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<String>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FxDaysCompanion(')
          ..write('day: $day, ')
          ..write('ratesJson: $ratesJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GroupsTable groups = $GroupsTable(this);
  late final $MembersTable members = $MembersTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $ExpenseSharesTable expenseShares = $ExpenseSharesTable(this);
  late final $ExpensePayersTable expensePayers = $ExpensePayersTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  late final $CommentsTable comments = $CommentsTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $PendingUploadsTable pendingUploads = $PendingUploadsTable(this);
  late final $RecurrencesTable recurrences = $RecurrencesTable(this);
  late final $ActivityTable activity = $ActivityTable(this);
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $SessionTable session = $SessionTable(this);
  late final $FxDaysTable fxDays = $FxDaysTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    groups,
    members,
    expenses,
    expenseShares,
    expensePayers,
    payments,
    comments,
    attachments,
    pendingUploads,
    recurrences,
    activity,
    outbox,
    syncState,
    session,
    fxDays,
  ];
}

typedef $$GroupsTableCreateCompanionBuilder =
    GroupsCompanion Function({
      required String id,
      required String name,
      required String defaultCurrency,
      Value<String?> inviteCode,
      Value<int> latestSeq,
      Value<String?> myMemberId,
      Value<bool> simplifyDebts,
      Value<String?> defaultSplitJson,
      Value<String> kind,
      Value<String> type,
      Value<String?> coverImageId,
      Value<bool> deleted,
      Value<int> rowid,
    });
typedef $$GroupsTableUpdateCompanionBuilder =
    GroupsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> defaultCurrency,
      Value<String?> inviteCode,
      Value<int> latestSeq,
      Value<String?> myMemberId,
      Value<bool> simplifyDebts,
      Value<String?> defaultSplitJson,
      Value<String> kind,
      Value<String> type,
      Value<String?> coverImageId,
      Value<bool> deleted,
      Value<int> rowid,
    });

class $$GroupsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultCurrency => $composableBuilder(
    column: $table.defaultCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get latestSeq => $composableBuilder(
    column: $table.latestSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get myMemberId => $composableBuilder(
    column: $table.myMemberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get simplifyDebts => $composableBuilder(
    column: $table.simplifyDebts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultSplitJson => $composableBuilder(
    column: $table.defaultSplitJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverImageId => $composableBuilder(
    column: $table.coverImageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultCurrency => $composableBuilder(
    column: $table.defaultCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get latestSeq => $composableBuilder(
    column: $table.latestSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get myMemberId => $composableBuilder(
    column: $table.myMemberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get simplifyDebts => $composableBuilder(
    column: $table.simplifyDebts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultSplitJson => $composableBuilder(
    column: $table.defaultSplitJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverImageId => $composableBuilder(
    column: $table.coverImageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get defaultCurrency => $composableBuilder(
    column: $table.defaultCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inviteCode => $composableBuilder(
    column: $table.inviteCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get latestSeq =>
      $composableBuilder(column: $table.latestSeq, builder: (column) => column);

  GeneratedColumn<String> get myMemberId => $composableBuilder(
    column: $table.myMemberId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get simplifyDebts => $composableBuilder(
    column: $table.simplifyDebts,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultSplitJson => $composableBuilder(
    column: $table.defaultSplitJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get coverImageId => $composableBuilder(
    column: $table.coverImageId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$GroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupsTable,
          GroupRow,
          $$GroupsTableFilterComposer,
          $$GroupsTableOrderingComposer,
          $$GroupsTableAnnotationComposer,
          $$GroupsTableCreateCompanionBuilder,
          $$GroupsTableUpdateCompanionBuilder,
          (GroupRow, BaseReferences<_$AppDatabase, $GroupsTable, GroupRow>),
          GroupRow,
          PrefetchHooks Function()
        > {
  $$GroupsTableTableManager(_$AppDatabase db, $GroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> defaultCurrency = const Value.absent(),
                Value<String?> inviteCode = const Value.absent(),
                Value<int> latestSeq = const Value.absent(),
                Value<String?> myMemberId = const Value.absent(),
                Value<bool> simplifyDebts = const Value.absent(),
                Value<String?> defaultSplitJson = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> coverImageId = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupsCompanion(
                id: id,
                name: name,
                defaultCurrency: defaultCurrency,
                inviteCode: inviteCode,
                latestSeq: latestSeq,
                myMemberId: myMemberId,
                simplifyDebts: simplifyDebts,
                defaultSplitJson: defaultSplitJson,
                kind: kind,
                type: type,
                coverImageId: coverImageId,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String defaultCurrency,
                Value<String?> inviteCode = const Value.absent(),
                Value<int> latestSeq = const Value.absent(),
                Value<String?> myMemberId = const Value.absent(),
                Value<bool> simplifyDebts = const Value.absent(),
                Value<String?> defaultSplitJson = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> coverImageId = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupsCompanion.insert(
                id: id,
                name: name,
                defaultCurrency: defaultCurrency,
                inviteCode: inviteCode,
                latestSeq: latestSeq,
                myMemberId: myMemberId,
                simplifyDebts: simplifyDebts,
                defaultSplitJson: defaultSplitJson,
                kind: kind,
                type: type,
                coverImageId: coverImageId,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupsTable,
      GroupRow,
      $$GroupsTableFilterComposer,
      $$GroupsTableOrderingComposer,
      $$GroupsTableAnnotationComposer,
      $$GroupsTableCreateCompanionBuilder,
      $$GroupsTableUpdateCompanionBuilder,
      (GroupRow, BaseReferences<_$AppDatabase, $GroupsTable, GroupRow>),
      GroupRow,
      PrefetchHooks Function()
    >;
typedef $$MembersTableCreateCompanionBuilder =
    MembersCompanion Function({
      required String id,
      required String groupId,
      required String name,
      Value<String?> userId,
      Value<bool> removed,
      Value<int> rowid,
    });
typedef $$MembersTableUpdateCompanionBuilder =
    MembersCompanion Function({
      Value<String> id,
      Value<String> groupId,
      Value<String> name,
      Value<String?> userId,
      Value<bool> removed,
      Value<int> rowid,
    });

class $$MembersTableFilterComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get removed => $composableBuilder(
    column: $table.removed,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MembersTableOrderingComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get removed => $composableBuilder(
    column: $table.removed,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<bool> get removed =>
      $composableBuilder(column: $table.removed, builder: (column) => column);
}

class $$MembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MembersTable,
          MemberRow,
          $$MembersTableFilterComposer,
          $$MembersTableOrderingComposer,
          $$MembersTableAnnotationComposer,
          $$MembersTableCreateCompanionBuilder,
          $$MembersTableUpdateCompanionBuilder,
          (MemberRow, BaseReferences<_$AppDatabase, $MembersTable, MemberRow>),
          MemberRow,
          PrefetchHooks Function()
        > {
  $$MembersTableTableManager(_$AppDatabase db, $MembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<bool> removed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion(
                id: id,
                groupId: groupId,
                name: name,
                userId: userId,
                removed: removed,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required String name,
                Value<String?> userId = const Value.absent(),
                Value<bool> removed = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion.insert(
                id: id,
                groupId: groupId,
                name: name,
                userId: userId,
                removed: removed,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MembersTable,
      MemberRow,
      $$MembersTableFilterComposer,
      $$MembersTableOrderingComposer,
      $$MembersTableAnnotationComposer,
      $$MembersTableCreateCompanionBuilder,
      $$MembersTableUpdateCompanionBuilder,
      (MemberRow, BaseReferences<_$AppDatabase, $MembersTable, MemberRow>),
      MemberRow,
      PrefetchHooks Function()
    >;
typedef $$ExpensesTableCreateCompanionBuilder =
    ExpensesCompanion Function({
      required String id,
      required String groupId,
      required String description,
      required int amount,
      required String currency,
      Value<double?> fxRateToDefault,
      required String paidBy,
      required String date,
      Value<String?> category,
      Value<bool> deleted,
      Value<String?> notes,
      Value<bool> refund,
      Value<String?> splitJson,
      Value<bool> moved,
      Value<String?> recurrenceId,
      Value<int?> occurrence,
      Value<int> rowid,
    });
typedef $$ExpensesTableUpdateCompanionBuilder =
    ExpensesCompanion Function({
      Value<String> id,
      Value<String> groupId,
      Value<String> description,
      Value<int> amount,
      Value<String> currency,
      Value<double?> fxRateToDefault,
      Value<String> paidBy,
      Value<String> date,
      Value<String?> category,
      Value<bool> deleted,
      Value<String?> notes,
      Value<bool> refund,
      Value<String?> splitJson,
      Value<bool> moved,
      Value<String?> recurrenceId,
      Value<int?> occurrence,
      Value<int> rowid,
    });

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fxRateToDefault => $composableBuilder(
    column: $table.fxRateToDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paidBy => $composableBuilder(
    column: $table.paidBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get refund => $composableBuilder(
    column: $table.refund,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get splitJson => $composableBuilder(
    column: $table.splitJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get moved => $composableBuilder(
    column: $table.moved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceId => $composableBuilder(
    column: $table.recurrenceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurrence => $composableBuilder(
    column: $table.occurrence,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fxRateToDefault => $composableBuilder(
    column: $table.fxRateToDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paidBy => $composableBuilder(
    column: $table.paidBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get refund => $composableBuilder(
    column: $table.refund,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get splitJson => $composableBuilder(
    column: $table.splitJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get moved => $composableBuilder(
    column: $table.moved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceId => $composableBuilder(
    column: $table.recurrenceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurrence => $composableBuilder(
    column: $table.occurrence,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get fxRateToDefault => $composableBuilder(
    column: $table.fxRateToDefault,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paidBy =>
      $composableBuilder(column: $table.paidBy, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get refund =>
      $composableBuilder(column: $table.refund, builder: (column) => column);

  GeneratedColumn<String> get splitJson =>
      $composableBuilder(column: $table.splitJson, builder: (column) => column);

  GeneratedColumn<bool> get moved =>
      $composableBuilder(column: $table.moved, builder: (column) => column);

  GeneratedColumn<String> get recurrenceId => $composableBuilder(
    column: $table.recurrenceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get occurrence => $composableBuilder(
    column: $table.occurrence,
    builder: (column) => column,
  );
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTable,
          ExpenseRow,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (
            ExpenseRow,
            BaseReferences<_$AppDatabase, $ExpensesTable, ExpenseRow>,
          ),
          ExpenseRow,
          PrefetchHooks Function()
        > {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<double?> fxRateToDefault = const Value.absent(),
                Value<String> paidBy = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> refund = const Value.absent(),
                Value<String?> splitJson = const Value.absent(),
                Value<bool> moved = const Value.absent(),
                Value<String?> recurrenceId = const Value.absent(),
                Value<int?> occurrence = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                groupId: groupId,
                description: description,
                amount: amount,
                currency: currency,
                fxRateToDefault: fxRateToDefault,
                paidBy: paidBy,
                date: date,
                category: category,
                deleted: deleted,
                notes: notes,
                refund: refund,
                splitJson: splitJson,
                moved: moved,
                recurrenceId: recurrenceId,
                occurrence: occurrence,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required String description,
                required int amount,
                required String currency,
                Value<double?> fxRateToDefault = const Value.absent(),
                required String paidBy,
                required String date,
                Value<String?> category = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> refund = const Value.absent(),
                Value<String?> splitJson = const Value.absent(),
                Value<bool> moved = const Value.absent(),
                Value<String?> recurrenceId = const Value.absent(),
                Value<int?> occurrence = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion.insert(
                id: id,
                groupId: groupId,
                description: description,
                amount: amount,
                currency: currency,
                fxRateToDefault: fxRateToDefault,
                paidBy: paidBy,
                date: date,
                category: category,
                deleted: deleted,
                notes: notes,
                refund: refund,
                splitJson: splitJson,
                moved: moved,
                recurrenceId: recurrenceId,
                occurrence: occurrence,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTable,
      ExpenseRow,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (ExpenseRow, BaseReferences<_$AppDatabase, $ExpensesTable, ExpenseRow>),
      ExpenseRow,
      PrefetchHooks Function()
    >;
typedef $$ExpenseSharesTableCreateCompanionBuilder =
    ExpenseSharesCompanion Function({
      required String expenseId,
      required String memberId,
      required int amount,
      Value<int> rowid,
    });
typedef $$ExpenseSharesTableUpdateCompanionBuilder =
    ExpenseSharesCompanion Function({
      Value<String> expenseId,
      Value<String> memberId,
      Value<int> amount,
      Value<int> rowid,
    });

class $$ExpenseSharesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpenseSharesTable> {
  $$ExpenseSharesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get expenseId => $composableBuilder(
    column: $table.expenseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpenseSharesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpenseSharesTable> {
  $$ExpenseSharesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get expenseId => $composableBuilder(
    column: $table.expenseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpenseSharesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpenseSharesTable> {
  $$ExpenseSharesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get expenseId =>
      $composableBuilder(column: $table.expenseId, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);
}

class $$ExpenseSharesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpenseSharesTable,
          ExpenseShareRow,
          $$ExpenseSharesTableFilterComposer,
          $$ExpenseSharesTableOrderingComposer,
          $$ExpenseSharesTableAnnotationComposer,
          $$ExpenseSharesTableCreateCompanionBuilder,
          $$ExpenseSharesTableUpdateCompanionBuilder,
          (
            ExpenseShareRow,
            BaseReferences<_$AppDatabase, $ExpenseSharesTable, ExpenseShareRow>,
          ),
          ExpenseShareRow,
          PrefetchHooks Function()
        > {
  $$ExpenseSharesTableTableManager(_$AppDatabase db, $ExpenseSharesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpenseSharesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpenseSharesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpenseSharesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> expenseId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpenseSharesCompanion(
                expenseId: expenseId,
                memberId: memberId,
                amount: amount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String expenseId,
                required String memberId,
                required int amount,
                Value<int> rowid = const Value.absent(),
              }) => ExpenseSharesCompanion.insert(
                expenseId: expenseId,
                memberId: memberId,
                amount: amount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpenseSharesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpenseSharesTable,
      ExpenseShareRow,
      $$ExpenseSharesTableFilterComposer,
      $$ExpenseSharesTableOrderingComposer,
      $$ExpenseSharesTableAnnotationComposer,
      $$ExpenseSharesTableCreateCompanionBuilder,
      $$ExpenseSharesTableUpdateCompanionBuilder,
      (
        ExpenseShareRow,
        BaseReferences<_$AppDatabase, $ExpenseSharesTable, ExpenseShareRow>,
      ),
      ExpenseShareRow,
      PrefetchHooks Function()
    >;
typedef $$ExpensePayersTableCreateCompanionBuilder =
    ExpensePayersCompanion Function({
      required String expenseId,
      required String memberId,
      required int amount,
      Value<int> rowid,
    });
typedef $$ExpensePayersTableUpdateCompanionBuilder =
    ExpensePayersCompanion Function({
      Value<String> expenseId,
      Value<String> memberId,
      Value<int> amount,
      Value<int> rowid,
    });

class $$ExpensePayersTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensePayersTable> {
  $$ExpensePayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get expenseId => $composableBuilder(
    column: $table.expenseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExpensePayersTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensePayersTable> {
  $$ExpensePayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get expenseId => $composableBuilder(
    column: $table.expenseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExpensePayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensePayersTable> {
  $$ExpensePayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get expenseId =>
      $composableBuilder(column: $table.expenseId, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);
}

class $$ExpensePayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensePayersTable,
          ExpensePayerRow,
          $$ExpensePayersTableFilterComposer,
          $$ExpensePayersTableOrderingComposer,
          $$ExpensePayersTableAnnotationComposer,
          $$ExpensePayersTableCreateCompanionBuilder,
          $$ExpensePayersTableUpdateCompanionBuilder,
          (
            ExpensePayerRow,
            BaseReferences<_$AppDatabase, $ExpensePayersTable, ExpensePayerRow>,
          ),
          ExpensePayerRow,
          PrefetchHooks Function()
        > {
  $$ExpensePayersTableTableManager(_$AppDatabase db, $ExpensePayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensePayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensePayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensePayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> expenseId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensePayersCompanion(
                expenseId: expenseId,
                memberId: memberId,
                amount: amount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String expenseId,
                required String memberId,
                required int amount,
                Value<int> rowid = const Value.absent(),
              }) => ExpensePayersCompanion.insert(
                expenseId: expenseId,
                memberId: memberId,
                amount: amount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExpensePayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensePayersTable,
      ExpensePayerRow,
      $$ExpensePayersTableFilterComposer,
      $$ExpensePayersTableOrderingComposer,
      $$ExpensePayersTableAnnotationComposer,
      $$ExpensePayersTableCreateCompanionBuilder,
      $$ExpensePayersTableUpdateCompanionBuilder,
      (
        ExpensePayerRow,
        BaseReferences<_$AppDatabase, $ExpensePayersTable, ExpensePayerRow>,
      ),
      ExpensePayerRow,
      PrefetchHooks Function()
    >;
typedef $$PaymentsTableCreateCompanionBuilder =
    PaymentsCompanion Function({
      required String id,
      required String groupId,
      required String fromMember,
      required String toMember,
      required int amount,
      required String currency,
      required String date,
      Value<bool> deleted,
      Value<String> status,
      Value<bool> replaced,
      Value<int> rowid,
    });
typedef $$PaymentsTableUpdateCompanionBuilder =
    PaymentsCompanion Function({
      Value<String> id,
      Value<String> groupId,
      Value<String> fromMember,
      Value<String> toMember,
      Value<int> amount,
      Value<String> currency,
      Value<String> date,
      Value<bool> deleted,
      Value<String> status,
      Value<bool> replaced,
      Value<int> rowid,
    });

class $$PaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fromMember => $composableBuilder(
    column: $table.fromMember,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toMember => $composableBuilder(
    column: $table.toMember,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get replaced => $composableBuilder(
    column: $table.replaced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fromMember => $composableBuilder(
    column: $table.fromMember,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toMember => $composableBuilder(
    column: $table.toMember,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get replaced => $composableBuilder(
    column: $table.replaced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get fromMember => $composableBuilder(
    column: $table.fromMember,
    builder: (column) => column,
  );

  GeneratedColumn<String> get toMember =>
      $composableBuilder(column: $table.toMember, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get replaced =>
      $composableBuilder(column: $table.replaced, builder: (column) => column);
}

class $$PaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentsTable,
          PaymentRow,
          $$PaymentsTableFilterComposer,
          $$PaymentsTableOrderingComposer,
          $$PaymentsTableAnnotationComposer,
          $$PaymentsTableCreateCompanionBuilder,
          $$PaymentsTableUpdateCompanionBuilder,
          (
            PaymentRow,
            BaseReferences<_$AppDatabase, $PaymentsTable, PaymentRow>,
          ),
          PaymentRow,
          PrefetchHooks Function()
        > {
  $$PaymentsTableTableManager(_$AppDatabase db, $PaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> fromMember = const Value.absent(),
                Value<String> toMember = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> replaced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentsCompanion(
                id: id,
                groupId: groupId,
                fromMember: fromMember,
                toMember: toMember,
                amount: amount,
                currency: currency,
                date: date,
                deleted: deleted,
                status: status,
                replaced: replaced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required String fromMember,
                required String toMember,
                required int amount,
                required String currency,
                required String date,
                Value<bool> deleted = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<bool> replaced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PaymentsCompanion.insert(
                id: id,
                groupId: groupId,
                fromMember: fromMember,
                toMember: toMember,
                amount: amount,
                currency: currency,
                date: date,
                deleted: deleted,
                status: status,
                replaced: replaced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentsTable,
      PaymentRow,
      $$PaymentsTableFilterComposer,
      $$PaymentsTableOrderingComposer,
      $$PaymentsTableAnnotationComposer,
      $$PaymentsTableCreateCompanionBuilder,
      $$PaymentsTableUpdateCompanionBuilder,
      (PaymentRow, BaseReferences<_$AppDatabase, $PaymentsTable, PaymentRow>),
      PaymentRow,
      PrefetchHooks Function()
    >;
typedef $$CommentsTableCreateCompanionBuilder =
    CommentsCompanion Function({
      required String id,
      required String groupId,
      Value<String?> expenseId,
      Value<String?> paymentId,
      required String authorMemberId,
      required String body,
      required String createdAt,
      Value<bool> deleted,
      Value<int> rowid,
    });
typedef $$CommentsTableUpdateCompanionBuilder =
    CommentsCompanion Function({
      Value<String> id,
      Value<String> groupId,
      Value<String?> expenseId,
      Value<String?> paymentId,
      Value<String> authorMemberId,
      Value<String> body,
      Value<String> createdAt,
      Value<bool> deleted,
      Value<int> rowid,
    });

class $$CommentsTableFilterComposer
    extends Composer<_$AppDatabase, $CommentsTable> {
  $$CommentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expenseId => $composableBuilder(
    column: $table.expenseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentId => $composableBuilder(
    column: $table.paymentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorMemberId => $composableBuilder(
    column: $table.authorMemberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CommentsTableOrderingComposer
    extends Composer<_$AppDatabase, $CommentsTable> {
  $$CommentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expenseId => $composableBuilder(
    column: $table.expenseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentId => $composableBuilder(
    column: $table.paymentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorMemberId => $composableBuilder(
    column: $table.authorMemberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CommentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CommentsTable> {
  $$CommentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get expenseId =>
      $composableBuilder(column: $table.expenseId, builder: (column) => column);

  GeneratedColumn<String> get paymentId =>
      $composableBuilder(column: $table.paymentId, builder: (column) => column);

  GeneratedColumn<String> get authorMemberId => $composableBuilder(
    column: $table.authorMemberId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$CommentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CommentsTable,
          CommentRow,
          $$CommentsTableFilterComposer,
          $$CommentsTableOrderingComposer,
          $$CommentsTableAnnotationComposer,
          $$CommentsTableCreateCompanionBuilder,
          $$CommentsTableUpdateCompanionBuilder,
          (
            CommentRow,
            BaseReferences<_$AppDatabase, $CommentsTable, CommentRow>,
          ),
          CommentRow,
          PrefetchHooks Function()
        > {
  $$CommentsTableTableManager(_$AppDatabase db, $CommentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CommentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CommentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CommentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String?> expenseId = const Value.absent(),
                Value<String?> paymentId = const Value.absent(),
                Value<String> authorMemberId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CommentsCompanion(
                id: id,
                groupId: groupId,
                expenseId: expenseId,
                paymentId: paymentId,
                authorMemberId: authorMemberId,
                body: body,
                createdAt: createdAt,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                Value<String?> expenseId = const Value.absent(),
                Value<String?> paymentId = const Value.absent(),
                required String authorMemberId,
                required String body,
                required String createdAt,
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CommentsCompanion.insert(
                id: id,
                groupId: groupId,
                expenseId: expenseId,
                paymentId: paymentId,
                authorMemberId: authorMemberId,
                body: body,
                createdAt: createdAt,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CommentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CommentsTable,
      CommentRow,
      $$CommentsTableFilterComposer,
      $$CommentsTableOrderingComposer,
      $$CommentsTableAnnotationComposer,
      $$CommentsTableCreateCompanionBuilder,
      $$CommentsTableUpdateCompanionBuilder,
      (CommentRow, BaseReferences<_$AppDatabase, $CommentsTable, CommentRow>),
      CommentRow,
      PrefetchHooks Function()
    >;
typedef $$AttachmentsTableCreateCompanionBuilder =
    AttachmentsCompanion Function({
      required String id,
      required String groupId,
      required String expenseId,
      Value<bool> deleted,
      Value<int> rowid,
    });
typedef $$AttachmentsTableUpdateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<String> id,
      Value<String> groupId,
      Value<String> expenseId,
      Value<bool> deleted,
      Value<int> rowid,
    });

class $$AttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expenseId => $composableBuilder(
    column: $table.expenseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expenseId => $composableBuilder(
    column: $table.expenseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get expenseId =>
      $composableBuilder(column: $table.expenseId, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);
}

class $$AttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentsTable,
          AttachmentRow,
          $$AttachmentsTableFilterComposer,
          $$AttachmentsTableOrderingComposer,
          $$AttachmentsTableAnnotationComposer,
          $$AttachmentsTableCreateCompanionBuilder,
          $$AttachmentsTableUpdateCompanionBuilder,
          (
            AttachmentRow,
            BaseReferences<_$AppDatabase, $AttachmentsTable, AttachmentRow>,
          ),
          AttachmentRow,
          PrefetchHooks Function()
        > {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> expenseId = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion(
                id: id,
                groupId: groupId,
                expenseId: expenseId,
                deleted: deleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required String expenseId,
                Value<bool> deleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion.insert(
                id: id,
                groupId: groupId,
                expenseId: expenseId,
                deleted: deleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentsTable,
      AttachmentRow,
      $$AttachmentsTableFilterComposer,
      $$AttachmentsTableOrderingComposer,
      $$AttachmentsTableAnnotationComposer,
      $$AttachmentsTableCreateCompanionBuilder,
      $$AttachmentsTableUpdateCompanionBuilder,
      (
        AttachmentRow,
        BaseReferences<_$AppDatabase, $AttachmentsTable, AttachmentRow>,
      ),
      AttachmentRow,
      PrefetchHooks Function()
    >;
typedef $$PendingUploadsTableCreateCompanionBuilder =
    PendingUploadsCompanion Function({
      required String attachmentId,
      required String groupId,
      required String createdAt,
      Value<int> rowid,
    });
typedef $$PendingUploadsTableUpdateCompanionBuilder =
    PendingUploadsCompanion Function({
      Value<String> attachmentId,
      Value<String> groupId,
      Value<String> createdAt,
      Value<int> rowid,
    });

class $$PendingUploadsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingUploadsTable> {
  $$PendingUploadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingUploadsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingUploadsTable> {
  $$PendingUploadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingUploadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingUploadsTable> {
  $$PendingUploadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get attachmentId => $composableBuilder(
    column: $table.attachmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingUploadsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingUploadsTable,
          PendingUploadRow,
          $$PendingUploadsTableFilterComposer,
          $$PendingUploadsTableOrderingComposer,
          $$PendingUploadsTableAnnotationComposer,
          $$PendingUploadsTableCreateCompanionBuilder,
          $$PendingUploadsTableUpdateCompanionBuilder,
          (
            PendingUploadRow,
            BaseReferences<
              _$AppDatabase,
              $PendingUploadsTable,
              PendingUploadRow
            >,
          ),
          PendingUploadRow,
          PrefetchHooks Function()
        > {
  $$PendingUploadsTableTableManager(
    _$AppDatabase db,
    $PendingUploadsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingUploadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingUploadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingUploadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> attachmentId = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingUploadsCompanion(
                attachmentId: attachmentId,
                groupId: groupId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String attachmentId,
                required String groupId,
                required String createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingUploadsCompanion.insert(
                attachmentId: attachmentId,
                groupId: groupId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingUploadsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingUploadsTable,
      PendingUploadRow,
      $$PendingUploadsTableFilterComposer,
      $$PendingUploadsTableOrderingComposer,
      $$PendingUploadsTableAnnotationComposer,
      $$PendingUploadsTableCreateCompanionBuilder,
      $$PendingUploadsTableUpdateCompanionBuilder,
      (
        PendingUploadRow,
        BaseReferences<_$AppDatabase, $PendingUploadsTable, PendingUploadRow>,
      ),
      PendingUploadRow,
      PrefetchHooks Function()
    >;
typedef $$RecurrencesTableCreateCompanionBuilder =
    RecurrencesCompanion Function({
      required String id,
      required String groupId,
      required String frequency,
      required String startDate,
      required String timeZone,
      required String templateJson,
      Value<bool> deleted,
      Value<int?> remindDaysBefore,
      Value<int> rowid,
    });
typedef $$RecurrencesTableUpdateCompanionBuilder =
    RecurrencesCompanion Function({
      Value<String> id,
      Value<String> groupId,
      Value<String> frequency,
      Value<String> startDate,
      Value<String> timeZone,
      Value<String> templateJson,
      Value<bool> deleted,
      Value<int?> remindDaysBefore,
      Value<int> rowid,
    });

class $$RecurrencesTableFilterComposer
    extends Composer<_$AppDatabase, $RecurrencesTable> {
  $$RecurrencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeZone => $composableBuilder(
    column: $table.timeZone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateJson => $composableBuilder(
    column: $table.templateJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remindDaysBefore => $composableBuilder(
    column: $table.remindDaysBefore,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecurrencesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurrencesTable> {
  $$RecurrencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeZone => $composableBuilder(
    column: $table.timeZone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateJson => $composableBuilder(
    column: $table.templateJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remindDaysBefore => $composableBuilder(
    column: $table.remindDaysBefore,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecurrencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurrencesTable> {
  $$RecurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get timeZone =>
      $composableBuilder(column: $table.timeZone, builder: (column) => column);

  GeneratedColumn<String> get templateJson => $composableBuilder(
    column: $table.templateJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<int> get remindDaysBefore => $composableBuilder(
    column: $table.remindDaysBefore,
    builder: (column) => column,
  );
}

class $$RecurrencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurrencesTable,
          RecurrenceRow,
          $$RecurrencesTableFilterComposer,
          $$RecurrencesTableOrderingComposer,
          $$RecurrencesTableAnnotationComposer,
          $$RecurrencesTableCreateCompanionBuilder,
          $$RecurrencesTableUpdateCompanionBuilder,
          (
            RecurrenceRow,
            BaseReferences<_$AppDatabase, $RecurrencesTable, RecurrenceRow>,
          ),
          RecurrenceRow,
          PrefetchHooks Function()
        > {
  $$RecurrencesTableTableManager(_$AppDatabase db, $RecurrencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurrencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurrencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> timeZone = const Value.absent(),
                Value<String> templateJson = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int?> remindDaysBefore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurrencesCompanion(
                id: id,
                groupId: groupId,
                frequency: frequency,
                startDate: startDate,
                timeZone: timeZone,
                templateJson: templateJson,
                deleted: deleted,
                remindDaysBefore: remindDaysBefore,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required String frequency,
                required String startDate,
                required String timeZone,
                required String templateJson,
                Value<bool> deleted = const Value.absent(),
                Value<int?> remindDaysBefore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurrencesCompanion.insert(
                id: id,
                groupId: groupId,
                frequency: frequency,
                startDate: startDate,
                timeZone: timeZone,
                templateJson: templateJson,
                deleted: deleted,
                remindDaysBefore: remindDaysBefore,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurrencesTable,
      RecurrenceRow,
      $$RecurrencesTableFilterComposer,
      $$RecurrencesTableOrderingComposer,
      $$RecurrencesTableAnnotationComposer,
      $$RecurrencesTableCreateCompanionBuilder,
      $$RecurrencesTableUpdateCompanionBuilder,
      (
        RecurrenceRow,
        BaseReferences<_$AppDatabase, $RecurrencesTable, RecurrenceRow>,
      ),
      RecurrenceRow,
      PrefetchHooks Function()
    >;
typedef $$ActivityTableCreateCompanionBuilder =
    ActivityCompanion Function({
      required String groupId,
      required int seq,
      required int feedId,
      required String createdAt,
      required String json,
      Value<int> rowid,
    });
typedef $$ActivityTableUpdateCompanionBuilder =
    ActivityCompanion Function({
      Value<String> groupId,
      Value<int> seq,
      Value<int> feedId,
      Value<String> createdAt,
      Value<String> json,
      Value<int> rowid,
    });

class $$ActivityTableFilterComposer
    extends Composer<_$AppDatabase, $ActivityTable> {
  $$ActivityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get feedId => $composableBuilder(
    column: $table.feedId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActivityTableOrderingComposer
    extends Composer<_$AppDatabase, $ActivityTable> {
  $$ActivityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get feedId => $composableBuilder(
    column: $table.feedId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActivityTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActivityTable> {
  $$ActivityTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<int> get feedId =>
      $composableBuilder(column: $table.feedId, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$ActivityTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActivityTable,
          ActivityRow,
          $$ActivityTableFilterComposer,
          $$ActivityTableOrderingComposer,
          $$ActivityTableAnnotationComposer,
          $$ActivityTableCreateCompanionBuilder,
          $$ActivityTableUpdateCompanionBuilder,
          (
            ActivityRow,
            BaseReferences<_$AppDatabase, $ActivityTable, ActivityRow>,
          ),
          ActivityRow,
          PrefetchHooks Function()
        > {
  $$ActivityTableTableManager(_$AppDatabase db, $ActivityTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActivityTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActivityTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActivityTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> groupId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int> feedId = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActivityCompanion(
                groupId: groupId,
                seq: seq,
                feedId: feedId,
                createdAt: createdAt,
                json: json,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupId,
                required int seq,
                required int feedId,
                required String createdAt,
                required String json,
                Value<int> rowid = const Value.absent(),
              }) => ActivityCompanion.insert(
                groupId: groupId,
                seq: seq,
                feedId: feedId,
                createdAt: createdAt,
                json: json,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActivityTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActivityTable,
      ActivityRow,
      $$ActivityTableFilterComposer,
      $$ActivityTableOrderingComposer,
      $$ActivityTableAnnotationComposer,
      $$ActivityTableCreateCompanionBuilder,
      $$ActivityTableUpdateCompanionBuilder,
      (ActivityRow, BaseReferences<_$AppDatabase, $ActivityTable, ActivityRow>),
      ActivityRow,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder =
    OutboxCompanion Function({
      required String clientId,
      required String groupId,
      required String type,
      required String payloadJson,
      required String createdAt,
      Value<String?> sentAt,
      Value<String?> rejected,
      Value<int> rowid,
    });
typedef $$OutboxTableUpdateCompanionBuilder =
    OutboxCompanion Function({
      Value<String> clientId,
      Value<String> groupId,
      Value<String> type,
      Value<String> payloadJson,
      Value<String> createdAt,
      Value<String?> sentAt,
      Value<String?> rejected,
      Value<int> rowid,
    });

class $$OutboxTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rejected => $composableBuilder(
    column: $table.rejected,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rejected => $composableBuilder(
    column: $table.rejected,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);

  GeneratedColumn<String> get rejected =>
      $composableBuilder(column: $table.rejected, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTable,
          OutboxRow,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxRow, BaseReferences<_$AppDatabase, $OutboxTable, OutboxRow>),
          OutboxRow,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientId = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> sentAt = const Value.absent(),
                Value<String?> rejected = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion(
                clientId: clientId,
                groupId: groupId,
                type: type,
                payloadJson: payloadJson,
                createdAt: createdAt,
                sentAt: sentAt,
                rejected: rejected,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientId,
                required String groupId,
                required String type,
                required String payloadJson,
                required String createdAt,
                Value<String?> sentAt = const Value.absent(),
                Value<String?> rejected = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxCompanion.insert(
                clientId: clientId,
                groupId: groupId,
                type: type,
                payloadJson: payloadJson,
                createdAt: createdAt,
                sentAt: sentAt,
                rejected: rejected,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTable,
      OutboxRow,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxRow, BaseReferences<_$AppDatabase, $OutboxTable, OutboxRow>),
      OutboxRow,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder =
    SyncStateCompanion Function({
      required String groupId,
      Value<int> lastSeq,
      Value<int> rowid,
    });
typedef $$SyncStateTableUpdateCompanionBuilder =
    SyncStateCompanion Function({
      Value<String> groupId,
      Value<int> lastSeq,
      Value<int> rowid,
    });

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSeq => $composableBuilder(
    column: $table.lastSeq,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSeq => $composableBuilder(
    column: $table.lastSeq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<int> get lastSeq =>
      $composableBuilder(column: $table.lastSeq, builder: (column) => column);
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTable,
          SyncStateRow,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateRow,
            BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRow>,
          ),
          SyncStateRow,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> groupId = const Value.absent(),
                Value<int> lastSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion(
                groupId: groupId,
                lastSeq: lastSeq,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupId,
                Value<int> lastSeq = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion.insert(
                groupId: groupId,
                lastSeq: lastSeq,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTable,
      SyncStateRow,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateRow,
        BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRow>,
      ),
      SyncStateRow,
      PrefetchHooks Function()
    >;
typedef $$SessionTableCreateCompanionBuilder =
    SessionCompanion Function({
      Value<int> id,
      required String accessToken,
      required String refreshToken,
      required String userId,
      required String displayName,
      Value<String?> homeCurrency,
      Value<String?> email,
      Value<bool?> emailBounced,
    });
typedef $$SessionTableUpdateCompanionBuilder =
    SessionCompanion Function({
      Value<int> id,
      Value<String> accessToken,
      Value<String> refreshToken,
      Value<String> userId,
      Value<String> displayName,
      Value<String?> homeCurrency,
      Value<String?> email,
      Value<bool?> emailBounced,
    });

class $$SessionTableFilterComposer
    extends Composer<_$AppDatabase, $SessionTable> {
  $$SessionTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refreshToken => $composableBuilder(
    column: $table.refreshToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get homeCurrency => $composableBuilder(
    column: $table.homeCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get emailBounced => $composableBuilder(
    column: $table.emailBounced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionTable> {
  $$SessionTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refreshToken => $composableBuilder(
    column: $table.refreshToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homeCurrency => $composableBuilder(
    column: $table.homeCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get emailBounced => $composableBuilder(
    column: $table.emailBounced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionTable> {
  $$SessionTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => column,
  );

  GeneratedColumn<String> get refreshToken => $composableBuilder(
    column: $table.refreshToken,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get homeCurrency => $composableBuilder(
    column: $table.homeCurrency,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<bool> get emailBounced => $composableBuilder(
    column: $table.emailBounced,
    builder: (column) => column,
  );
}

class $$SessionTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionTable,
          SessionRow,
          $$SessionTableFilterComposer,
          $$SessionTableOrderingComposer,
          $$SessionTableAnnotationComposer,
          $$SessionTableCreateCompanionBuilder,
          $$SessionTableUpdateCompanionBuilder,
          (
            SessionRow,
            BaseReferences<_$AppDatabase, $SessionTable, SessionRow>,
          ),
          SessionRow,
          PrefetchHooks Function()
        > {
  $$SessionTableTableManager(_$AppDatabase db, $SessionTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> accessToken = const Value.absent(),
                Value<String> refreshToken = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> homeCurrency = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<bool?> emailBounced = const Value.absent(),
              }) => SessionCompanion(
                id: id,
                accessToken: accessToken,
                refreshToken: refreshToken,
                userId: userId,
                displayName: displayName,
                homeCurrency: homeCurrency,
                email: email,
                emailBounced: emailBounced,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String accessToken,
                required String refreshToken,
                required String userId,
                required String displayName,
                Value<String?> homeCurrency = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<bool?> emailBounced = const Value.absent(),
              }) => SessionCompanion.insert(
                id: id,
                accessToken: accessToken,
                refreshToken: refreshToken,
                userId: userId,
                displayName: displayName,
                homeCurrency: homeCurrency,
                email: email,
                emailBounced: emailBounced,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionTable,
      SessionRow,
      $$SessionTableFilterComposer,
      $$SessionTableOrderingComposer,
      $$SessionTableAnnotationComposer,
      $$SessionTableCreateCompanionBuilder,
      $$SessionTableUpdateCompanionBuilder,
      (SessionRow, BaseReferences<_$AppDatabase, $SessionTable, SessionRow>),
      SessionRow,
      PrefetchHooks Function()
    >;
typedef $$FxDaysTableCreateCompanionBuilder =
    FxDaysCompanion Function({
      required String day,
      required String ratesJson,
      required String fetchedAt,
      Value<int> rowid,
    });
typedef $$FxDaysTableUpdateCompanionBuilder =
    FxDaysCompanion Function({
      Value<String> day,
      Value<String> ratesJson,
      Value<String> fetchedAt,
      Value<int> rowid,
    });

class $$FxDaysTableFilterComposer
    extends Composer<_$AppDatabase, $FxDaysTable> {
  $$FxDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ratesJson => $composableBuilder(
    column: $table.ratesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FxDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $FxDaysTable> {
  $$FxDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ratesJson => $composableBuilder(
    column: $table.ratesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FxDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $FxDaysTable> {
  $$FxDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get ratesJson =>
      $composableBuilder(column: $table.ratesJson, builder: (column) => column);

  GeneratedColumn<String> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$FxDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FxDaysTable,
          FxDayRow,
          $$FxDaysTableFilterComposer,
          $$FxDaysTableOrderingComposer,
          $$FxDaysTableAnnotationComposer,
          $$FxDaysTableCreateCompanionBuilder,
          $$FxDaysTableUpdateCompanionBuilder,
          (FxDayRow, BaseReferences<_$AppDatabase, $FxDaysTable, FxDayRow>),
          FxDayRow,
          PrefetchHooks Function()
        > {
  $$FxDaysTableTableManager(_$AppDatabase db, $FxDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FxDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FxDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FxDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> day = const Value.absent(),
                Value<String> ratesJson = const Value.absent(),
                Value<String> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FxDaysCompanion(
                day: day,
                ratesJson: ratesJson,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String day,
                required String ratesJson,
                required String fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => FxDaysCompanion.insert(
                day: day,
                ratesJson: ratesJson,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FxDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FxDaysTable,
      FxDayRow,
      $$FxDaysTableFilterComposer,
      $$FxDaysTableOrderingComposer,
      $$FxDaysTableAnnotationComposer,
      $$FxDaysTableCreateCompanionBuilder,
      $$FxDaysTableUpdateCompanionBuilder,
      (FxDayRow, BaseReferences<_$AppDatabase, $FxDaysTable, FxDayRow>),
      FxDayRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db, _db.groups);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db, _db.members);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$ExpenseSharesTableTableManager get expenseShares =>
      $$ExpenseSharesTableTableManager(_db, _db.expenseShares);
  $$ExpensePayersTableTableManager get expensePayers =>
      $$ExpensePayersTableTableManager(_db, _db.expensePayers);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
  $$CommentsTableTableManager get comments =>
      $$CommentsTableTableManager(_db, _db.comments);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$PendingUploadsTableTableManager get pendingUploads =>
      $$PendingUploadsTableTableManager(_db, _db.pendingUploads);
  $$RecurrencesTableTableManager get recurrences =>
      $$RecurrencesTableTableManager(_db, _db.recurrences);
  $$ActivityTableTableManager get activity =>
      $$ActivityTableTableManager(_db, _db.activity);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$SessionTableTableManager get session =>
      $$SessionTableTableManager(_db, _db.session);
  $$FxDaysTableTableManager get fxDays =>
      $$FxDaysTableTableManager(_db, _db.fxDays);
}
