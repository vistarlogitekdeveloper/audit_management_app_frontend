// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AuditPlansTable extends AuditPlans
    with TableInfo<$AuditPlansTable, AuditPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientTempIdMeta = const VerificationMeta(
    'clientTempId',
  );
  @override
  late final GeneratedColumn<String> clientTempId = GeneratedColumn<String>(
    'client_temp_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientTempId,
    deviceId,
    isSynced,
    isDeleted,
    updatedAt,
    id,
    name,
    description,
    status,
    startDate,
    endDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_temp_id')) {
      context.handle(
        _clientTempIdMeta,
        clientTempId.isAcceptableOrUnknown(
          data['client_temp_id']!,
          _clientTempIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientTempIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientTempId};
  @override
  AuditPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditPlan(
      clientTempId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_temp_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      ),
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
    );
  }

  @override
  $AuditPlansTable createAlias(String alias) {
    return $AuditPlansTable(attachedDatabase, alias);
  }
}

class AuditPlan extends DataClass implements Insertable<AuditPlan> {
  final String clientTempId;
  final String deviceId;
  final bool isSynced;
  final bool isDeleted;
  final DateTime updatedAt;
  final String? id;
  final String name;
  final String? description;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  const AuditPlan({
    required this.clientTempId,
    required this.deviceId,
    required this.isSynced,
    required this.isDeleted,
    required this.updatedAt,
    this.id,
    required this.name,
    this.description,
    required this.status,
    this.startDate,
    this.endDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_temp_id'] = Variable<String>(clientTempId);
    map['device_id'] = Variable<String>(deviceId);
    map['is_synced'] = Variable<bool>(isSynced);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    return map;
  }

  AuditPlansCompanion toCompanion(bool nullToAbsent) {
    return AuditPlansCompanion(
      clientTempId: Value(clientTempId),
      deviceId: Value(deviceId),
      isSynced: Value(isSynced),
      isDeleted: Value(isDeleted),
      updatedAt: Value(updatedAt),
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      status: Value(status),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
    );
  }

  factory AuditPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditPlan(
      clientTempId: serializer.fromJson<String>(json['clientTempId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      id: serializer.fromJson<String?>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      status: serializer.fromJson<String>(json['status']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientTempId': serializer.toJson<String>(clientTempId),
      'deviceId': serializer.toJson<String>(deviceId),
      'isSynced': serializer.toJson<bool>(isSynced),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'id': serializer.toJson<String?>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'status': serializer.toJson<String>(status),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
    };
  }

  AuditPlan copyWith({
    String? clientTempId,
    String? deviceId,
    bool? isSynced,
    bool? isDeleted,
    DateTime? updatedAt,
    Value<String?> id = const Value.absent(),
    String? name,
    Value<String?> description = const Value.absent(),
    String? status,
    Value<DateTime?> startDate = const Value.absent(),
    Value<DateTime?> endDate = const Value.absent(),
  }) => AuditPlan(
    clientTempId: clientTempId ?? this.clientTempId,
    deviceId: deviceId ?? this.deviceId,
    isSynced: isSynced ?? this.isSynced,
    isDeleted: isDeleted ?? this.isDeleted,
    updatedAt: updatedAt ?? this.updatedAt,
    id: id.present ? id.value : this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    status: status ?? this.status,
    startDate: startDate.present ? startDate.value : this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
  );
  AuditPlan copyWithCompanion(AuditPlansCompanion data) {
    return AuditPlan(
      clientTempId: data.clientTempId.present
          ? data.clientTempId.value
          : this.clientTempId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      status: data.status.present ? data.status.value : this.status,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditPlan(')
          ..write('clientTempId: $clientTempId, ')
          ..write('deviceId: $deviceId, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientTempId,
    deviceId,
    isSynced,
    isDeleted,
    updatedAt,
    id,
    name,
    description,
    status,
    startDate,
    endDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditPlan &&
          other.clientTempId == this.clientTempId &&
          other.deviceId == this.deviceId &&
          other.isSynced == this.isSynced &&
          other.isDeleted == this.isDeleted &&
          other.updatedAt == this.updatedAt &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.status == this.status &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate);
}

class AuditPlansCompanion extends UpdateCompanion<AuditPlan> {
  final Value<String> clientTempId;
  final Value<String> deviceId;
  final Value<bool> isSynced;
  final Value<bool> isDeleted;
  final Value<DateTime> updatedAt;
  final Value<String?> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> status;
  final Value<DateTime?> startDate;
  final Value<DateTime?> endDate;
  final Value<int> rowid;
  const AuditPlansCompanion({
    this.clientTempId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditPlansCompanion.insert({
    required String clientTempId,
    required String deviceId,
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    required DateTime updatedAt,
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required String status,
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientTempId = Value(clientTempId),
       deviceId = Value(deviceId),
       updatedAt = Value(updatedAt),
       name = Value(name),
       status = Value(status);
  static Insertable<AuditPlan> custom({
    Expression<String>? clientTempId,
    Expression<String>? deviceId,
    Expression<bool>? isSynced,
    Expression<bool>? isDeleted,
    Expression<DateTime>? updatedAt,
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? status,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientTempId != null) 'client_temp_id': clientTempId,
      if (deviceId != null) 'device_id': deviceId,
      if (isSynced != null) 'is_synced': isSynced,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditPlansCompanion copyWith({
    Value<String>? clientTempId,
    Value<String>? deviceId,
    Value<bool>? isSynced,
    Value<bool>? isDeleted,
    Value<DateTime>? updatedAt,
    Value<String?>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? status,
    Value<DateTime?>? startDate,
    Value<DateTime?>? endDate,
    Value<int>? rowid,
  }) {
    return AuditPlansCompanion(
      clientTempId: clientTempId ?? this.clientTempId,
      deviceId: deviceId ?? this.deviceId,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientTempId.present) {
      map['client_temp_id'] = Variable<String>(clientTempId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditPlansCompanion(')
          ..write('clientTempId: $clientTempId, ')
          ..write('deviceId: $deviceId, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditQuestionsTable extends AuditQuestions
    with TableInfo<$AuditQuestionsTable, AuditQuestion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditQuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientTempIdMeta = const VerificationMeta(
    'clientTempId',
  );
  @override
  late final GeneratedColumn<String> clientTempId = GeneratedColumn<String>(
    'client_temp_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _auditPlanIdMeta = const VerificationMeta(
    'auditPlanId',
  );
  @override
  late final GeneratedColumn<String> auditPlanId = GeneratedColumn<String>(
    'audit_plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionTextMeta = const VerificationMeta(
    'questionText',
  );
  @override
  late final GeneratedColumn<String> questionText = GeneratedColumn<String>(
    'question_text',
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isRequiredMeta = const VerificationMeta(
    'isRequired',
  );
  @override
  late final GeneratedColumn<bool> isRequired = GeneratedColumn<bool>(
    'is_required',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_required" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientTempId,
    deviceId,
    isSynced,
    isDeleted,
    updatedAt,
    id,
    auditPlanId,
    questionText,
    category,
    isRequired,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditQuestion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_temp_id')) {
      context.handle(
        _clientTempIdMeta,
        clientTempId.isAcceptableOrUnknown(
          data['client_temp_id']!,
          _clientTempIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientTempIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('audit_plan_id')) {
      context.handle(
        _auditPlanIdMeta,
        auditPlanId.isAcceptableOrUnknown(
          data['audit_plan_id']!,
          _auditPlanIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_auditPlanIdMeta);
    }
    if (data.containsKey('question_text')) {
      context.handle(
        _questionTextMeta,
        questionText.isAcceptableOrUnknown(
          data['question_text']!,
          _questionTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionTextMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('is_required')) {
      context.handle(
        _isRequiredMeta,
        isRequired.isAcceptableOrUnknown(data['is_required']!, _isRequiredMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientTempId};
  @override
  AuditQuestion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditQuestion(
      clientTempId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_temp_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      auditPlanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audit_plan_id'],
      )!,
      questionText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_text'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      isRequired: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_required'],
      )!,
    );
  }

  @override
  $AuditQuestionsTable createAlias(String alias) {
    return $AuditQuestionsTable(attachedDatabase, alias);
  }
}

class AuditQuestion extends DataClass implements Insertable<AuditQuestion> {
  final String clientTempId;
  final String deviceId;
  final bool isSynced;
  final bool isDeleted;
  final DateTime updatedAt;
  final String? id;
  final String auditPlanId;
  final String questionText;
  final String category;
  final bool isRequired;
  const AuditQuestion({
    required this.clientTempId,
    required this.deviceId,
    required this.isSynced,
    required this.isDeleted,
    required this.updatedAt,
    this.id,
    required this.auditPlanId,
    required this.questionText,
    required this.category,
    required this.isRequired,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_temp_id'] = Variable<String>(clientTempId);
    map['device_id'] = Variable<String>(deviceId);
    map['is_synced'] = Variable<bool>(isSynced);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['audit_plan_id'] = Variable<String>(auditPlanId);
    map['question_text'] = Variable<String>(questionText);
    map['category'] = Variable<String>(category);
    map['is_required'] = Variable<bool>(isRequired);
    return map;
  }

  AuditQuestionsCompanion toCompanion(bool nullToAbsent) {
    return AuditQuestionsCompanion(
      clientTempId: Value(clientTempId),
      deviceId: Value(deviceId),
      isSynced: Value(isSynced),
      isDeleted: Value(isDeleted),
      updatedAt: Value(updatedAt),
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      auditPlanId: Value(auditPlanId),
      questionText: Value(questionText),
      category: Value(category),
      isRequired: Value(isRequired),
    );
  }

  factory AuditQuestion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditQuestion(
      clientTempId: serializer.fromJson<String>(json['clientTempId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      id: serializer.fromJson<String?>(json['id']),
      auditPlanId: serializer.fromJson<String>(json['auditPlanId']),
      questionText: serializer.fromJson<String>(json['questionText']),
      category: serializer.fromJson<String>(json['category']),
      isRequired: serializer.fromJson<bool>(json['isRequired']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientTempId': serializer.toJson<String>(clientTempId),
      'deviceId': serializer.toJson<String>(deviceId),
      'isSynced': serializer.toJson<bool>(isSynced),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'id': serializer.toJson<String?>(id),
      'auditPlanId': serializer.toJson<String>(auditPlanId),
      'questionText': serializer.toJson<String>(questionText),
      'category': serializer.toJson<String>(category),
      'isRequired': serializer.toJson<bool>(isRequired),
    };
  }

  AuditQuestion copyWith({
    String? clientTempId,
    String? deviceId,
    bool? isSynced,
    bool? isDeleted,
    DateTime? updatedAt,
    Value<String?> id = const Value.absent(),
    String? auditPlanId,
    String? questionText,
    String? category,
    bool? isRequired,
  }) => AuditQuestion(
    clientTempId: clientTempId ?? this.clientTempId,
    deviceId: deviceId ?? this.deviceId,
    isSynced: isSynced ?? this.isSynced,
    isDeleted: isDeleted ?? this.isDeleted,
    updatedAt: updatedAt ?? this.updatedAt,
    id: id.present ? id.value : this.id,
    auditPlanId: auditPlanId ?? this.auditPlanId,
    questionText: questionText ?? this.questionText,
    category: category ?? this.category,
    isRequired: isRequired ?? this.isRequired,
  );
  AuditQuestion copyWithCompanion(AuditQuestionsCompanion data) {
    return AuditQuestion(
      clientTempId: data.clientTempId.present
          ? data.clientTempId.value
          : this.clientTempId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      id: data.id.present ? data.id.value : this.id,
      auditPlanId: data.auditPlanId.present
          ? data.auditPlanId.value
          : this.auditPlanId,
      questionText: data.questionText.present
          ? data.questionText.value
          : this.questionText,
      category: data.category.present ? data.category.value : this.category,
      isRequired: data.isRequired.present
          ? data.isRequired.value
          : this.isRequired,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditQuestion(')
          ..write('clientTempId: $clientTempId, ')
          ..write('deviceId: $deviceId, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('auditPlanId: $auditPlanId, ')
          ..write('questionText: $questionText, ')
          ..write('category: $category, ')
          ..write('isRequired: $isRequired')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientTempId,
    deviceId,
    isSynced,
    isDeleted,
    updatedAt,
    id,
    auditPlanId,
    questionText,
    category,
    isRequired,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditQuestion &&
          other.clientTempId == this.clientTempId &&
          other.deviceId == this.deviceId &&
          other.isSynced == this.isSynced &&
          other.isDeleted == this.isDeleted &&
          other.updatedAt == this.updatedAt &&
          other.id == this.id &&
          other.auditPlanId == this.auditPlanId &&
          other.questionText == this.questionText &&
          other.category == this.category &&
          other.isRequired == this.isRequired);
}

class AuditQuestionsCompanion extends UpdateCompanion<AuditQuestion> {
  final Value<String> clientTempId;
  final Value<String> deviceId;
  final Value<bool> isSynced;
  final Value<bool> isDeleted;
  final Value<DateTime> updatedAt;
  final Value<String?> id;
  final Value<String> auditPlanId;
  final Value<String> questionText;
  final Value<String> category;
  final Value<bool> isRequired;
  final Value<int> rowid;
  const AuditQuestionsCompanion({
    this.clientTempId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.auditPlanId = const Value.absent(),
    this.questionText = const Value.absent(),
    this.category = const Value.absent(),
    this.isRequired = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditQuestionsCompanion.insert({
    required String clientTempId,
    required String deviceId,
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    required DateTime updatedAt,
    this.id = const Value.absent(),
    required String auditPlanId,
    required String questionText,
    required String category,
    this.isRequired = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientTempId = Value(clientTempId),
       deviceId = Value(deviceId),
       updatedAt = Value(updatedAt),
       auditPlanId = Value(auditPlanId),
       questionText = Value(questionText),
       category = Value(category);
  static Insertable<AuditQuestion> custom({
    Expression<String>? clientTempId,
    Expression<String>? deviceId,
    Expression<bool>? isSynced,
    Expression<bool>? isDeleted,
    Expression<DateTime>? updatedAt,
    Expression<String>? id,
    Expression<String>? auditPlanId,
    Expression<String>? questionText,
    Expression<String>? category,
    Expression<bool>? isRequired,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientTempId != null) 'client_temp_id': clientTempId,
      if (deviceId != null) 'device_id': deviceId,
      if (isSynced != null) 'is_synced': isSynced,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (id != null) 'id': id,
      if (auditPlanId != null) 'audit_plan_id': auditPlanId,
      if (questionText != null) 'question_text': questionText,
      if (category != null) 'category': category,
      if (isRequired != null) 'is_required': isRequired,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditQuestionsCompanion copyWith({
    Value<String>? clientTempId,
    Value<String>? deviceId,
    Value<bool>? isSynced,
    Value<bool>? isDeleted,
    Value<DateTime>? updatedAt,
    Value<String?>? id,
    Value<String>? auditPlanId,
    Value<String>? questionText,
    Value<String>? category,
    Value<bool>? isRequired,
    Value<int>? rowid,
  }) {
    return AuditQuestionsCompanion(
      clientTempId: clientTempId ?? this.clientTempId,
      deviceId: deviceId ?? this.deviceId,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
      id: id ?? this.id,
      auditPlanId: auditPlanId ?? this.auditPlanId,
      questionText: questionText ?? this.questionText,
      category: category ?? this.category,
      isRequired: isRequired ?? this.isRequired,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientTempId.present) {
      map['client_temp_id'] = Variable<String>(clientTempId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (auditPlanId.present) {
      map['audit_plan_id'] = Variable<String>(auditPlanId.value);
    }
    if (questionText.present) {
      map['question_text'] = Variable<String>(questionText.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (isRequired.present) {
      map['is_required'] = Variable<bool>(isRequired.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditQuestionsCompanion(')
          ..write('clientTempId: $clientTempId, ')
          ..write('deviceId: $deviceId, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('auditPlanId: $auditPlanId, ')
          ..write('questionText: $questionText, ')
          ..write('category: $category, ')
          ..write('isRequired: $isRequired, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditResponsesTable extends AuditResponses
    with TableInfo<$AuditResponsesTable, AuditResponse> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditResponsesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientTempIdMeta = const VerificationMeta(
    'clientTempId',
  );
  @override
  late final GeneratedColumn<String> clientTempId = GeneratedColumn<String>(
    'client_temp_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _auditPlanIdMeta = const VerificationMeta(
    'auditPlanId',
  );
  @override
  late final GeneratedColumn<String> auditPlanId = GeneratedColumn<String>(
    'audit_plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _questionIdMeta = const VerificationMeta(
    'questionId',
  );
  @override
  late final GeneratedColumn<String> questionId = GeneratedColumn<String>(
    'question_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remarksMeta = const VerificationMeta(
    'remarks',
  );
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
    'remarks',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientTempId,
    deviceId,
    isSynced,
    isDeleted,
    updatedAt,
    id,
    auditPlanId,
    questionId,
    status,
    remarks,
    imagePath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_responses';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditResponse> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_temp_id')) {
      context.handle(
        _clientTempIdMeta,
        clientTempId.isAcceptableOrUnknown(
          data['client_temp_id']!,
          _clientTempIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientTempIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('audit_plan_id')) {
      context.handle(
        _auditPlanIdMeta,
        auditPlanId.isAcceptableOrUnknown(
          data['audit_plan_id']!,
          _auditPlanIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_auditPlanIdMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
        _questionIdMeta,
        questionId.isAcceptableOrUnknown(data['question_id']!, _questionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('remarks')) {
      context.handle(
        _remarksMeta,
        remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientTempId};
  @override
  AuditResponse map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditResponse(
      clientTempId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_temp_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      auditPlanId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audit_plan_id'],
      )!,
      questionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      remarks: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remarks'],
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
    );
  }

  @override
  $AuditResponsesTable createAlias(String alias) {
    return $AuditResponsesTable(attachedDatabase, alias);
  }
}

class AuditResponse extends DataClass implements Insertable<AuditResponse> {
  final String clientTempId;
  final String deviceId;
  final bool isSynced;
  final bool isDeleted;
  final DateTime updatedAt;
  final String? id;
  final String auditPlanId;
  final String questionId;
  final String status;
  final String? remarks;
  final String? imagePath;
  const AuditResponse({
    required this.clientTempId,
    required this.deviceId,
    required this.isSynced,
    required this.isDeleted,
    required this.updatedAt,
    this.id,
    required this.auditPlanId,
    required this.questionId,
    required this.status,
    this.remarks,
    this.imagePath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_temp_id'] = Variable<String>(clientTempId);
    map['device_id'] = Variable<String>(deviceId);
    map['is_synced'] = Variable<bool>(isSynced);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['audit_plan_id'] = Variable<String>(auditPlanId);
    map['question_id'] = Variable<String>(questionId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || remarks != null) {
      map['remarks'] = Variable<String>(remarks);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    return map;
  }

  AuditResponsesCompanion toCompanion(bool nullToAbsent) {
    return AuditResponsesCompanion(
      clientTempId: Value(clientTempId),
      deviceId: Value(deviceId),
      isSynced: Value(isSynced),
      isDeleted: Value(isDeleted),
      updatedAt: Value(updatedAt),
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      auditPlanId: Value(auditPlanId),
      questionId: Value(questionId),
      status: Value(status),
      remarks: remarks == null && nullToAbsent
          ? const Value.absent()
          : Value(remarks),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
    );
  }

  factory AuditResponse.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditResponse(
      clientTempId: serializer.fromJson<String>(json['clientTempId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      id: serializer.fromJson<String?>(json['id']),
      auditPlanId: serializer.fromJson<String>(json['auditPlanId']),
      questionId: serializer.fromJson<String>(json['questionId']),
      status: serializer.fromJson<String>(json['status']),
      remarks: serializer.fromJson<String?>(json['remarks']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientTempId': serializer.toJson<String>(clientTempId),
      'deviceId': serializer.toJson<String>(deviceId),
      'isSynced': serializer.toJson<bool>(isSynced),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'id': serializer.toJson<String?>(id),
      'auditPlanId': serializer.toJson<String>(auditPlanId),
      'questionId': serializer.toJson<String>(questionId),
      'status': serializer.toJson<String>(status),
      'remarks': serializer.toJson<String?>(remarks),
      'imagePath': serializer.toJson<String?>(imagePath),
    };
  }

  AuditResponse copyWith({
    String? clientTempId,
    String? deviceId,
    bool? isSynced,
    bool? isDeleted,
    DateTime? updatedAt,
    Value<String?> id = const Value.absent(),
    String? auditPlanId,
    String? questionId,
    String? status,
    Value<String?> remarks = const Value.absent(),
    Value<String?> imagePath = const Value.absent(),
  }) => AuditResponse(
    clientTempId: clientTempId ?? this.clientTempId,
    deviceId: deviceId ?? this.deviceId,
    isSynced: isSynced ?? this.isSynced,
    isDeleted: isDeleted ?? this.isDeleted,
    updatedAt: updatedAt ?? this.updatedAt,
    id: id.present ? id.value : this.id,
    auditPlanId: auditPlanId ?? this.auditPlanId,
    questionId: questionId ?? this.questionId,
    status: status ?? this.status,
    remarks: remarks.present ? remarks.value : this.remarks,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
  );
  AuditResponse copyWithCompanion(AuditResponsesCompanion data) {
    return AuditResponse(
      clientTempId: data.clientTempId.present
          ? data.clientTempId.value
          : this.clientTempId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      id: data.id.present ? data.id.value : this.id,
      auditPlanId: data.auditPlanId.present
          ? data.auditPlanId.value
          : this.auditPlanId,
      questionId: data.questionId.present
          ? data.questionId.value
          : this.questionId,
      status: data.status.present ? data.status.value : this.status,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditResponse(')
          ..write('clientTempId: $clientTempId, ')
          ..write('deviceId: $deviceId, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('auditPlanId: $auditPlanId, ')
          ..write('questionId: $questionId, ')
          ..write('status: $status, ')
          ..write('remarks: $remarks, ')
          ..write('imagePath: $imagePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientTempId,
    deviceId,
    isSynced,
    isDeleted,
    updatedAt,
    id,
    auditPlanId,
    questionId,
    status,
    remarks,
    imagePath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditResponse &&
          other.clientTempId == this.clientTempId &&
          other.deviceId == this.deviceId &&
          other.isSynced == this.isSynced &&
          other.isDeleted == this.isDeleted &&
          other.updatedAt == this.updatedAt &&
          other.id == this.id &&
          other.auditPlanId == this.auditPlanId &&
          other.questionId == this.questionId &&
          other.status == this.status &&
          other.remarks == this.remarks &&
          other.imagePath == this.imagePath);
}

class AuditResponsesCompanion extends UpdateCompanion<AuditResponse> {
  final Value<String> clientTempId;
  final Value<String> deviceId;
  final Value<bool> isSynced;
  final Value<bool> isDeleted;
  final Value<DateTime> updatedAt;
  final Value<String?> id;
  final Value<String> auditPlanId;
  final Value<String> questionId;
  final Value<String> status;
  final Value<String?> remarks;
  final Value<String?> imagePath;
  final Value<int> rowid;
  const AuditResponsesCompanion({
    this.clientTempId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.auditPlanId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.status = const Value.absent(),
    this.remarks = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditResponsesCompanion.insert({
    required String clientTempId,
    required String deviceId,
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    required DateTime updatedAt,
    this.id = const Value.absent(),
    required String auditPlanId,
    required String questionId,
    required String status,
    this.remarks = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientTempId = Value(clientTempId),
       deviceId = Value(deviceId),
       updatedAt = Value(updatedAt),
       auditPlanId = Value(auditPlanId),
       questionId = Value(questionId),
       status = Value(status);
  static Insertable<AuditResponse> custom({
    Expression<String>? clientTempId,
    Expression<String>? deviceId,
    Expression<bool>? isSynced,
    Expression<bool>? isDeleted,
    Expression<DateTime>? updatedAt,
    Expression<String>? id,
    Expression<String>? auditPlanId,
    Expression<String>? questionId,
    Expression<String>? status,
    Expression<String>? remarks,
    Expression<String>? imagePath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientTempId != null) 'client_temp_id': clientTempId,
      if (deviceId != null) 'device_id': deviceId,
      if (isSynced != null) 'is_synced': isSynced,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (id != null) 'id': id,
      if (auditPlanId != null) 'audit_plan_id': auditPlanId,
      if (questionId != null) 'question_id': questionId,
      if (status != null) 'status': status,
      if (remarks != null) 'remarks': remarks,
      if (imagePath != null) 'image_path': imagePath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditResponsesCompanion copyWith({
    Value<String>? clientTempId,
    Value<String>? deviceId,
    Value<bool>? isSynced,
    Value<bool>? isDeleted,
    Value<DateTime>? updatedAt,
    Value<String?>? id,
    Value<String>? auditPlanId,
    Value<String>? questionId,
    Value<String>? status,
    Value<String?>? remarks,
    Value<String?>? imagePath,
    Value<int>? rowid,
  }) {
    return AuditResponsesCompanion(
      clientTempId: clientTempId ?? this.clientTempId,
      deviceId: deviceId ?? this.deviceId,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
      id: id ?? this.id,
      auditPlanId: auditPlanId ?? this.auditPlanId,
      questionId: questionId ?? this.questionId,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      imagePath: imagePath ?? this.imagePath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientTempId.present) {
      map['client_temp_id'] = Variable<String>(clientTempId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (auditPlanId.present) {
      map['audit_plan_id'] = Variable<String>(auditPlanId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<String>(questionId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditResponsesCompanion(')
          ..write('clientTempId: $clientTempId, ')
          ..write('deviceId: $deviceId, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('auditPlanId: $auditPlanId, ')
          ..write('questionId: $questionId, ')
          ..write('status: $status, ')
          ..write('remarks: $remarks, ')
          ..write('imagePath: $imagePath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ActionPlansTable extends ActionPlans
    with TableInfo<$ActionPlansTable, ActionPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActionPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientTempIdMeta = const VerificationMeta(
    'clientTempId',
  );
  @override
  late final GeneratedColumn<String> clientTempId = GeneratedColumn<String>(
    'client_temp_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _auditResponseIdMeta = const VerificationMeta(
    'auditResponseId',
  );
  @override
  late final GeneratedColumn<String> auditResponseId = GeneratedColumn<String>(
    'audit_response_id',
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
  static const VerificationMeta _assignedToMeta = const VerificationMeta(
    'assignedTo',
  );
  @override
  late final GeneratedColumn<String> assignedTo = GeneratedColumn<String>(
    'assigned_to',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientTempId,
    deviceId,
    isSynced,
    isDeleted,
    updatedAt,
    id,
    auditResponseId,
    description,
    assignedTo,
    dueDate,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'action_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActionPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_temp_id')) {
      context.handle(
        _clientTempIdMeta,
        clientTempId.isAcceptableOrUnknown(
          data['client_temp_id']!,
          _clientTempIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientTempIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('audit_response_id')) {
      context.handle(
        _auditResponseIdMeta,
        auditResponseId.isAcceptableOrUnknown(
          data['audit_response_id']!,
          _auditResponseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_auditResponseIdMeta);
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
    if (data.containsKey('assigned_to')) {
      context.handle(
        _assignedToMeta,
        assignedTo.isAcceptableOrUnknown(data['assigned_to']!, _assignedToMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientTempId};
  @override
  ActionPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActionPlan(
      clientTempId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_temp_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      auditResponseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audit_response_id'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      assignedTo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assigned_to'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $ActionPlansTable createAlias(String alias) {
    return $ActionPlansTable(attachedDatabase, alias);
  }
}

class ActionPlan extends DataClass implements Insertable<ActionPlan> {
  final String clientTempId;
  final String deviceId;
  final bool isSynced;
  final bool isDeleted;
  final DateTime updatedAt;
  final String? id;
  final String auditResponseId;
  final String description;
  final String? assignedTo;
  final DateTime? dueDate;
  final String status;
  const ActionPlan({
    required this.clientTempId,
    required this.deviceId,
    required this.isSynced,
    required this.isDeleted,
    required this.updatedAt,
    this.id,
    required this.auditResponseId,
    required this.description,
    this.assignedTo,
    this.dueDate,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_temp_id'] = Variable<String>(clientTempId);
    map['device_id'] = Variable<String>(deviceId);
    map['is_synced'] = Variable<bool>(isSynced);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['audit_response_id'] = Variable<String>(auditResponseId);
    map['description'] = Variable<String>(description);
    if (!nullToAbsent || assignedTo != null) {
      map['assigned_to'] = Variable<String>(assignedTo);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  ActionPlansCompanion toCompanion(bool nullToAbsent) {
    return ActionPlansCompanion(
      clientTempId: Value(clientTempId),
      deviceId: Value(deviceId),
      isSynced: Value(isSynced),
      isDeleted: Value(isDeleted),
      updatedAt: Value(updatedAt),
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      auditResponseId: Value(auditResponseId),
      description: Value(description),
      assignedTo: assignedTo == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedTo),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      status: Value(status),
    );
  }

  factory ActionPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActionPlan(
      clientTempId: serializer.fromJson<String>(json['clientTempId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      id: serializer.fromJson<String?>(json['id']),
      auditResponseId: serializer.fromJson<String>(json['auditResponseId']),
      description: serializer.fromJson<String>(json['description']),
      assignedTo: serializer.fromJson<String?>(json['assignedTo']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientTempId': serializer.toJson<String>(clientTempId),
      'deviceId': serializer.toJson<String>(deviceId),
      'isSynced': serializer.toJson<bool>(isSynced),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'id': serializer.toJson<String?>(id),
      'auditResponseId': serializer.toJson<String>(auditResponseId),
      'description': serializer.toJson<String>(description),
      'assignedTo': serializer.toJson<String?>(assignedTo),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'status': serializer.toJson<String>(status),
    };
  }

  ActionPlan copyWith({
    String? clientTempId,
    String? deviceId,
    bool? isSynced,
    bool? isDeleted,
    DateTime? updatedAt,
    Value<String?> id = const Value.absent(),
    String? auditResponseId,
    String? description,
    Value<String?> assignedTo = const Value.absent(),
    Value<DateTime?> dueDate = const Value.absent(),
    String? status,
  }) => ActionPlan(
    clientTempId: clientTempId ?? this.clientTempId,
    deviceId: deviceId ?? this.deviceId,
    isSynced: isSynced ?? this.isSynced,
    isDeleted: isDeleted ?? this.isDeleted,
    updatedAt: updatedAt ?? this.updatedAt,
    id: id.present ? id.value : this.id,
    auditResponseId: auditResponseId ?? this.auditResponseId,
    description: description ?? this.description,
    assignedTo: assignedTo.present ? assignedTo.value : this.assignedTo,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    status: status ?? this.status,
  );
  ActionPlan copyWithCompanion(ActionPlansCompanion data) {
    return ActionPlan(
      clientTempId: data.clientTempId.present
          ? data.clientTempId.value
          : this.clientTempId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      id: data.id.present ? data.id.value : this.id,
      auditResponseId: data.auditResponseId.present
          ? data.auditResponseId.value
          : this.auditResponseId,
      description: data.description.present
          ? data.description.value
          : this.description,
      assignedTo: data.assignedTo.present
          ? data.assignedTo.value
          : this.assignedTo,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActionPlan(')
          ..write('clientTempId: $clientTempId, ')
          ..write('deviceId: $deviceId, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('auditResponseId: $auditResponseId, ')
          ..write('description: $description, ')
          ..write('assignedTo: $assignedTo, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientTempId,
    deviceId,
    isSynced,
    isDeleted,
    updatedAt,
    id,
    auditResponseId,
    description,
    assignedTo,
    dueDate,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActionPlan &&
          other.clientTempId == this.clientTempId &&
          other.deviceId == this.deviceId &&
          other.isSynced == this.isSynced &&
          other.isDeleted == this.isDeleted &&
          other.updatedAt == this.updatedAt &&
          other.id == this.id &&
          other.auditResponseId == this.auditResponseId &&
          other.description == this.description &&
          other.assignedTo == this.assignedTo &&
          other.dueDate == this.dueDate &&
          other.status == this.status);
}

class ActionPlansCompanion extends UpdateCompanion<ActionPlan> {
  final Value<String> clientTempId;
  final Value<String> deviceId;
  final Value<bool> isSynced;
  final Value<bool> isDeleted;
  final Value<DateTime> updatedAt;
  final Value<String?> id;
  final Value<String> auditResponseId;
  final Value<String> description;
  final Value<String?> assignedTo;
  final Value<DateTime?> dueDate;
  final Value<String> status;
  final Value<int> rowid;
  const ActionPlansCompanion({
    this.clientTempId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.id = const Value.absent(),
    this.auditResponseId = const Value.absent(),
    this.description = const Value.absent(),
    this.assignedTo = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActionPlansCompanion.insert({
    required String clientTempId,
    required String deviceId,
    this.isSynced = const Value.absent(),
    this.isDeleted = const Value.absent(),
    required DateTime updatedAt,
    this.id = const Value.absent(),
    required String auditResponseId,
    required String description,
    this.assignedTo = const Value.absent(),
    this.dueDate = const Value.absent(),
    required String status,
    this.rowid = const Value.absent(),
  }) : clientTempId = Value(clientTempId),
       deviceId = Value(deviceId),
       updatedAt = Value(updatedAt),
       auditResponseId = Value(auditResponseId),
       description = Value(description),
       status = Value(status);
  static Insertable<ActionPlan> custom({
    Expression<String>? clientTempId,
    Expression<String>? deviceId,
    Expression<bool>? isSynced,
    Expression<bool>? isDeleted,
    Expression<DateTime>? updatedAt,
    Expression<String>? id,
    Expression<String>? auditResponseId,
    Expression<String>? description,
    Expression<String>? assignedTo,
    Expression<DateTime>? dueDate,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientTempId != null) 'client_temp_id': clientTempId,
      if (deviceId != null) 'device_id': deviceId,
      if (isSynced != null) 'is_synced': isSynced,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (id != null) 'id': id,
      if (auditResponseId != null) 'audit_response_id': auditResponseId,
      if (description != null) 'description': description,
      if (assignedTo != null) 'assigned_to': assignedTo,
      if (dueDate != null) 'due_date': dueDate,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActionPlansCompanion copyWith({
    Value<String>? clientTempId,
    Value<String>? deviceId,
    Value<bool>? isSynced,
    Value<bool>? isDeleted,
    Value<DateTime>? updatedAt,
    Value<String?>? id,
    Value<String>? auditResponseId,
    Value<String>? description,
    Value<String?>? assignedTo,
    Value<DateTime?>? dueDate,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return ActionPlansCompanion(
      clientTempId: clientTempId ?? this.clientTempId,
      deviceId: deviceId ?? this.deviceId,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
      id: id ?? this.id,
      auditResponseId: auditResponseId ?? this.auditResponseId,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientTempId.present) {
      map['client_temp_id'] = Variable<String>(clientTempId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (auditResponseId.present) {
      map['audit_response_id'] = Variable<String>(auditResponseId.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (assignedTo.present) {
      map['assigned_to'] = Variable<String>(assignedTo.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActionPlansCompanion(')
          ..write('clientTempId: $clientTempId, ')
          ..write('deviceId: $deviceId, ')
          ..write('isSynced: $isSynced, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('id: $id, ')
          ..write('auditResponseId: $auditResponseId, ')
          ..write('description: $description, ')
          ..write('assignedTo: $assignedTo, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AuditPlansTable auditPlans = $AuditPlansTable(this);
  late final $AuditQuestionsTable auditQuestions = $AuditQuestionsTable(this);
  late final $AuditResponsesTable auditResponses = $AuditResponsesTable(this);
  late final $ActionPlansTable actionPlans = $ActionPlansTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    auditPlans,
    auditQuestions,
    auditResponses,
    actionPlans,
  ];
}

typedef $$AuditPlansTableCreateCompanionBuilder =
    AuditPlansCompanion Function({
      required String clientTempId,
      required String deviceId,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      required DateTime updatedAt,
      Value<String?> id,
      required String name,
      Value<String?> description,
      required String status,
      Value<DateTime?> startDate,
      Value<DateTime?> endDate,
      Value<int> rowid,
    });
typedef $$AuditPlansTableUpdateCompanionBuilder =
    AuditPlansCompanion Function({
      Value<String> clientTempId,
      Value<String> deviceId,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      Value<DateTime> updatedAt,
      Value<String?> id,
      Value<String> name,
      Value<String?> description,
      Value<String> status,
      Value<DateTime?> startDate,
      Value<DateTime?> endDate,
      Value<int> rowid,
    });

class $$AuditPlansTableFilterComposer
    extends Composer<_$AppDatabase, $AuditPlansTable> {
  $$AuditPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientTempId => $composableBuilder(
    column: $table.clientTempId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditPlansTable> {
  $$AuditPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientTempId => $composableBuilder(
    column: $table.clientTempId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditPlansTable> {
  $$AuditPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientTempId => $composableBuilder(
    column: $table.clientTempId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);
}

class $$AuditPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditPlansTable,
          AuditPlan,
          $$AuditPlansTableFilterComposer,
          $$AuditPlansTableOrderingComposer,
          $$AuditPlansTableAnnotationComposer,
          $$AuditPlansTableCreateCompanionBuilder,
          $$AuditPlansTableUpdateCompanionBuilder,
          (
            AuditPlan,
            BaseReferences<_$AppDatabase, $AuditPlansTable, AuditPlan>,
          ),
          AuditPlan,
          PrefetchHooks Function()
        > {
  $$AuditPlansTableTableManager(_$AppDatabase db, $AuditPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientTempId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditPlansCompanion(
                clientTempId: clientTempId,
                deviceId: deviceId,
                isSynced: isSynced,
                isDeleted: isDeleted,
                updatedAt: updatedAt,
                id: id,
                name: name,
                description: description,
                status: status,
                startDate: startDate,
                endDate: endDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientTempId,
                required String deviceId,
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                required DateTime updatedAt,
                Value<String?> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                required String status,
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditPlansCompanion.insert(
                clientTempId: clientTempId,
                deviceId: deviceId,
                isSynced: isSynced,
                isDeleted: isDeleted,
                updatedAt: updatedAt,
                id: id,
                name: name,
                description: description,
                status: status,
                startDate: startDate,
                endDate: endDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditPlansTable,
      AuditPlan,
      $$AuditPlansTableFilterComposer,
      $$AuditPlansTableOrderingComposer,
      $$AuditPlansTableAnnotationComposer,
      $$AuditPlansTableCreateCompanionBuilder,
      $$AuditPlansTableUpdateCompanionBuilder,
      (AuditPlan, BaseReferences<_$AppDatabase, $AuditPlansTable, AuditPlan>),
      AuditPlan,
      PrefetchHooks Function()
    >;
typedef $$AuditQuestionsTableCreateCompanionBuilder =
    AuditQuestionsCompanion Function({
      required String clientTempId,
      required String deviceId,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      required DateTime updatedAt,
      Value<String?> id,
      required String auditPlanId,
      required String questionText,
      required String category,
      Value<bool> isRequired,
      Value<int> rowid,
    });
typedef $$AuditQuestionsTableUpdateCompanionBuilder =
    AuditQuestionsCompanion Function({
      Value<String> clientTempId,
      Value<String> deviceId,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      Value<DateTime> updatedAt,
      Value<String?> id,
      Value<String> auditPlanId,
      Value<String> questionText,
      Value<String> category,
      Value<bool> isRequired,
      Value<int> rowid,
    });

class $$AuditQuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $AuditQuestionsTable> {
  $$AuditQuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientTempId => $composableBuilder(
    column: $table.clientTempId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get auditPlanId => $composableBuilder(
    column: $table.auditPlanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionText => $composableBuilder(
    column: $table.questionText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRequired => $composableBuilder(
    column: $table.isRequired,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditQuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditQuestionsTable> {
  $$AuditQuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientTempId => $composableBuilder(
    column: $table.clientTempId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get auditPlanId => $composableBuilder(
    column: $table.auditPlanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionText => $composableBuilder(
    column: $table.questionText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRequired => $composableBuilder(
    column: $table.isRequired,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditQuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditQuestionsTable> {
  $$AuditQuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientTempId => $composableBuilder(
    column: $table.clientTempId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get auditPlanId => $composableBuilder(
    column: $table.auditPlanId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get questionText => $composableBuilder(
    column: $table.questionText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get isRequired => $composableBuilder(
    column: $table.isRequired,
    builder: (column) => column,
  );
}

class $$AuditQuestionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditQuestionsTable,
          AuditQuestion,
          $$AuditQuestionsTableFilterComposer,
          $$AuditQuestionsTableOrderingComposer,
          $$AuditQuestionsTableAnnotationComposer,
          $$AuditQuestionsTableCreateCompanionBuilder,
          $$AuditQuestionsTableUpdateCompanionBuilder,
          (
            AuditQuestion,
            BaseReferences<_$AppDatabase, $AuditQuestionsTable, AuditQuestion>,
          ),
          AuditQuestion,
          PrefetchHooks Function()
        > {
  $$AuditQuestionsTableTableManager(
    _$AppDatabase db,
    $AuditQuestionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditQuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditQuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditQuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientTempId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> id = const Value.absent(),
                Value<String> auditPlanId = const Value.absent(),
                Value<String> questionText = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<bool> isRequired = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditQuestionsCompanion(
                clientTempId: clientTempId,
                deviceId: deviceId,
                isSynced: isSynced,
                isDeleted: isDeleted,
                updatedAt: updatedAt,
                id: id,
                auditPlanId: auditPlanId,
                questionText: questionText,
                category: category,
                isRequired: isRequired,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientTempId,
                required String deviceId,
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                required DateTime updatedAt,
                Value<String?> id = const Value.absent(),
                required String auditPlanId,
                required String questionText,
                required String category,
                Value<bool> isRequired = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditQuestionsCompanion.insert(
                clientTempId: clientTempId,
                deviceId: deviceId,
                isSynced: isSynced,
                isDeleted: isDeleted,
                updatedAt: updatedAt,
                id: id,
                auditPlanId: auditPlanId,
                questionText: questionText,
                category: category,
                isRequired: isRequired,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditQuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditQuestionsTable,
      AuditQuestion,
      $$AuditQuestionsTableFilterComposer,
      $$AuditQuestionsTableOrderingComposer,
      $$AuditQuestionsTableAnnotationComposer,
      $$AuditQuestionsTableCreateCompanionBuilder,
      $$AuditQuestionsTableUpdateCompanionBuilder,
      (
        AuditQuestion,
        BaseReferences<_$AppDatabase, $AuditQuestionsTable, AuditQuestion>,
      ),
      AuditQuestion,
      PrefetchHooks Function()
    >;
typedef $$AuditResponsesTableCreateCompanionBuilder =
    AuditResponsesCompanion Function({
      required String clientTempId,
      required String deviceId,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      required DateTime updatedAt,
      Value<String?> id,
      required String auditPlanId,
      required String questionId,
      required String status,
      Value<String?> remarks,
      Value<String?> imagePath,
      Value<int> rowid,
    });
typedef $$AuditResponsesTableUpdateCompanionBuilder =
    AuditResponsesCompanion Function({
      Value<String> clientTempId,
      Value<String> deviceId,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      Value<DateTime> updatedAt,
      Value<String?> id,
      Value<String> auditPlanId,
      Value<String> questionId,
      Value<String> status,
      Value<String?> remarks,
      Value<String?> imagePath,
      Value<int> rowid,
    });

class $$AuditResponsesTableFilterComposer
    extends Composer<_$AppDatabase, $AuditResponsesTable> {
  $$AuditResponsesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientTempId => $composableBuilder(
    column: $table.clientTempId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get auditPlanId => $composableBuilder(
    column: $table.auditPlanId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditResponsesTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditResponsesTable> {
  $$AuditResponsesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientTempId => $composableBuilder(
    column: $table.clientTempId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get auditPlanId => $composableBuilder(
    column: $table.auditPlanId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remarks => $composableBuilder(
    column: $table.remarks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditResponsesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditResponsesTable> {
  $$AuditResponsesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientTempId => $composableBuilder(
    column: $table.clientTempId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get auditPlanId => $composableBuilder(
    column: $table.auditPlanId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get questionId => $composableBuilder(
    column: $table.questionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);
}

class $$AuditResponsesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditResponsesTable,
          AuditResponse,
          $$AuditResponsesTableFilterComposer,
          $$AuditResponsesTableOrderingComposer,
          $$AuditResponsesTableAnnotationComposer,
          $$AuditResponsesTableCreateCompanionBuilder,
          $$AuditResponsesTableUpdateCompanionBuilder,
          (
            AuditResponse,
            BaseReferences<_$AppDatabase, $AuditResponsesTable, AuditResponse>,
          ),
          AuditResponse,
          PrefetchHooks Function()
        > {
  $$AuditResponsesTableTableManager(
    _$AppDatabase db,
    $AuditResponsesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditResponsesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditResponsesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditResponsesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientTempId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> id = const Value.absent(),
                Value<String> auditPlanId = const Value.absent(),
                Value<String> questionId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> remarks = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditResponsesCompanion(
                clientTempId: clientTempId,
                deviceId: deviceId,
                isSynced: isSynced,
                isDeleted: isDeleted,
                updatedAt: updatedAt,
                id: id,
                auditPlanId: auditPlanId,
                questionId: questionId,
                status: status,
                remarks: remarks,
                imagePath: imagePath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientTempId,
                required String deviceId,
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                required DateTime updatedAt,
                Value<String?> id = const Value.absent(),
                required String auditPlanId,
                required String questionId,
                required String status,
                Value<String?> remarks = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditResponsesCompanion.insert(
                clientTempId: clientTempId,
                deviceId: deviceId,
                isSynced: isSynced,
                isDeleted: isDeleted,
                updatedAt: updatedAt,
                id: id,
                auditPlanId: auditPlanId,
                questionId: questionId,
                status: status,
                remarks: remarks,
                imagePath: imagePath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditResponsesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditResponsesTable,
      AuditResponse,
      $$AuditResponsesTableFilterComposer,
      $$AuditResponsesTableOrderingComposer,
      $$AuditResponsesTableAnnotationComposer,
      $$AuditResponsesTableCreateCompanionBuilder,
      $$AuditResponsesTableUpdateCompanionBuilder,
      (
        AuditResponse,
        BaseReferences<_$AppDatabase, $AuditResponsesTable, AuditResponse>,
      ),
      AuditResponse,
      PrefetchHooks Function()
    >;
typedef $$ActionPlansTableCreateCompanionBuilder =
    ActionPlansCompanion Function({
      required String clientTempId,
      required String deviceId,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      required DateTime updatedAt,
      Value<String?> id,
      required String auditResponseId,
      required String description,
      Value<String?> assignedTo,
      Value<DateTime?> dueDate,
      required String status,
      Value<int> rowid,
    });
typedef $$ActionPlansTableUpdateCompanionBuilder =
    ActionPlansCompanion Function({
      Value<String> clientTempId,
      Value<String> deviceId,
      Value<bool> isSynced,
      Value<bool> isDeleted,
      Value<DateTime> updatedAt,
      Value<String?> id,
      Value<String> auditResponseId,
      Value<String> description,
      Value<String?> assignedTo,
      Value<DateTime?> dueDate,
      Value<String> status,
      Value<int> rowid,
    });

class $$ActionPlansTableFilterComposer
    extends Composer<_$AppDatabase, $ActionPlansTable> {
  $$ActionPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientTempId => $composableBuilder(
    column: $table.clientTempId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get auditResponseId => $composableBuilder(
    column: $table.auditResponseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assignedTo => $composableBuilder(
    column: $table.assignedTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActionPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $ActionPlansTable> {
  $$ActionPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientTempId => $composableBuilder(
    column: $table.clientTempId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get auditResponseId => $composableBuilder(
    column: $table.auditResponseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assignedTo => $composableBuilder(
    column: $table.assignedTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActionPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $ActionPlansTable> {
  $$ActionPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientTempId => $composableBuilder(
    column: $table.clientTempId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get auditResponseId => $composableBuilder(
    column: $table.auditResponseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get assignedTo => $composableBuilder(
    column: $table.assignedTo,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$ActionPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ActionPlansTable,
          ActionPlan,
          $$ActionPlansTableFilterComposer,
          $$ActionPlansTableOrderingComposer,
          $$ActionPlansTableAnnotationComposer,
          $$ActionPlansTableCreateCompanionBuilder,
          $$ActionPlansTableUpdateCompanionBuilder,
          (
            ActionPlan,
            BaseReferences<_$AppDatabase, $ActionPlansTable, ActionPlan>,
          ),
          ActionPlan,
          PrefetchHooks Function()
        > {
  $$ActionPlansTableTableManager(_$AppDatabase db, $ActionPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActionPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActionPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActionPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientTempId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> id = const Value.absent(),
                Value<String> auditResponseId = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String?> assignedTo = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActionPlansCompanion(
                clientTempId: clientTempId,
                deviceId: deviceId,
                isSynced: isSynced,
                isDeleted: isDeleted,
                updatedAt: updatedAt,
                id: id,
                auditResponseId: auditResponseId,
                description: description,
                assignedTo: assignedTo,
                dueDate: dueDate,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientTempId,
                required String deviceId,
                Value<bool> isSynced = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                required DateTime updatedAt,
                Value<String?> id = const Value.absent(),
                required String auditResponseId,
                required String description,
                Value<String?> assignedTo = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                required String status,
                Value<int> rowid = const Value.absent(),
              }) => ActionPlansCompanion.insert(
                clientTempId: clientTempId,
                deviceId: deviceId,
                isSynced: isSynced,
                isDeleted: isDeleted,
                updatedAt: updatedAt,
                id: id,
                auditResponseId: auditResponseId,
                description: description,
                assignedTo: assignedTo,
                dueDate: dueDate,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActionPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ActionPlansTable,
      ActionPlan,
      $$ActionPlansTableFilterComposer,
      $$ActionPlansTableOrderingComposer,
      $$ActionPlansTableAnnotationComposer,
      $$ActionPlansTableCreateCompanionBuilder,
      $$ActionPlansTableUpdateCompanionBuilder,
      (
        ActionPlan,
        BaseReferences<_$AppDatabase, $ActionPlansTable, ActionPlan>,
      ),
      ActionPlan,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AuditPlansTableTableManager get auditPlans =>
      $$AuditPlansTableTableManager(_db, _db.auditPlans);
  $$AuditQuestionsTableTableManager get auditQuestions =>
      $$AuditQuestionsTableTableManager(_db, _db.auditQuestions);
  $$AuditResponsesTableTableManager get auditResponses =>
      $$AuditResponsesTableTableManager(_db, _db.auditResponses);
  $$ActionPlansTableTableManager get actionPlans =>
      $$ActionPlansTableTableManager(_db, _db.actionPlans);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appDatabaseHash() => r'4c20f914a3c547001c20f44f1138a1d70037da2d';

/// See also [appDatabase].
@ProviderFor(appDatabase)
final appDatabaseProvider = AutoDisposeProvider<AppDatabase>.internal(
  appDatabase,
  name: r'appDatabaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appDatabaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AppDatabaseRef = AutoDisposeProviderRef<AppDatabase>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
