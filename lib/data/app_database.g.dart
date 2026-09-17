// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalProfilesTable extends LocalProfiles
    with TableInfo<$LocalProfilesTable, LocalProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usualCycleDaysMeta = const VerificationMeta(
    'usualCycleDays',
  );
  @override
  late final GeneratedColumn<int> usualCycleDays = GeneratedColumn<int>(
    'usual_cycle_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usualPeriodDaysMeta = const VerificationMeta(
    'usualPeriodDays',
  );
  @override
  late final GeneratedColumn<int> usualPeriodDays = GeneratedColumn<int>(
    'usual_period_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  @override
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitsMeta = const VerificationMeta('units');
  @override
  late final GeneratedColumn<String> units = GeneratedColumn<String>(
    'units',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _birthYearMeta = const VerificationMeta(
    'birthYear',
  );
  @override
  late final GeneratedColumn<int> birthYear = GeneratedColumn<int>(
    'birth_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _birthMonthMeta = const VerificationMeta(
    'birthMonth',
  );
  @override
  late final GeneratedColumn<int> birthMonth = GeneratedColumn<int>(
    'birth_month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, int> syncState =
      GeneratedColumn<int>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.synced.index),
      ).withConverter<SyncState>($LocalProfilesTable.$convertersyncState);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    name,
    usualCycleDays,
    usualPeriodDays,
    theme,
    units,
    timezone,
    birthYear,
    birthMonth,
    syncState,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('usual_cycle_days')) {
      context.handle(
        _usualCycleDaysMeta,
        usualCycleDays.isAcceptableOrUnknown(
          data['usual_cycle_days']!,
          _usualCycleDaysMeta,
        ),
      );
    }
    if (data.containsKey('usual_period_days')) {
      context.handle(
        _usualPeriodDaysMeta,
        usualPeriodDays.isAcceptableOrUnknown(
          data['usual_period_days']!,
          _usualPeriodDaysMeta,
        ),
      );
    }
    if (data.containsKey('theme')) {
      context.handle(
        _themeMeta,
        theme.isAcceptableOrUnknown(data['theme']!, _themeMeta),
      );
    }
    if (data.containsKey('units')) {
      context.handle(
        _unitsMeta,
        units.isAcceptableOrUnknown(data['units']!, _unitsMeta),
      );
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    }
    if (data.containsKey('birth_year')) {
      context.handle(
        _birthYearMeta,
        birthYear.isAcceptableOrUnknown(data['birth_year']!, _birthYearMeta),
      );
    }
    if (data.containsKey('birth_month')) {
      context.handle(
        _birthMonthMeta,
        birthMonth.isAcceptableOrUnknown(data['birth_month']!, _birthMonthMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  LocalProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProfile(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      usualCycleDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}usual_cycle_days'],
      ),
      usualPeriodDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}usual_period_days'],
      ),
      theme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme'],
      ),
      units: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}units'],
      ),
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      ),
      birthYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}birth_year'],
      ),
      birthMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}birth_month'],
      ),
      syncState: $LocalProfilesTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalProfilesTable createAlias(String alias) {
    return $LocalProfilesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, int, int> $convertersyncState =
      const EnumIndexConverter<SyncState>(SyncState.values);
}

class LocalProfile extends DataClass implements Insertable<LocalProfile> {
  final String userId;
  final String? name;
  final int? usualCycleDays;
  final int? usualPeriodDays;
  final String? theme;
  final String? units;
  final String? timezone;
  final int? birthYear;
  final int? birthMonth;
  final SyncState syncState;
  final DateTime updatedAt;
  const LocalProfile({
    required this.userId,
    this.name,
    this.usualCycleDays,
    this.usualPeriodDays,
    this.theme,
    this.units,
    this.timezone,
    this.birthYear,
    this.birthMonth,
    required this.syncState,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    if (!nullToAbsent || usualCycleDays != null) {
      map['usual_cycle_days'] = Variable<int>(usualCycleDays);
    }
    if (!nullToAbsent || usualPeriodDays != null) {
      map['usual_period_days'] = Variable<int>(usualPeriodDays);
    }
    if (!nullToAbsent || theme != null) {
      map['theme'] = Variable<String>(theme);
    }
    if (!nullToAbsent || units != null) {
      map['units'] = Variable<String>(units);
    }
    if (!nullToAbsent || timezone != null) {
      map['timezone'] = Variable<String>(timezone);
    }
    if (!nullToAbsent || birthYear != null) {
      map['birth_year'] = Variable<int>(birthYear);
    }
    if (!nullToAbsent || birthMonth != null) {
      map['birth_month'] = Variable<int>(birthMonth);
    }
    {
      map['sync_state'] = Variable<int>(
        $LocalProfilesTable.$convertersyncState.toSql(syncState),
      );
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalProfilesCompanion toCompanion(bool nullToAbsent) {
    return LocalProfilesCompanion(
      userId: Value(userId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      usualCycleDays: usualCycleDays == null && nullToAbsent
          ? const Value.absent()
          : Value(usualCycleDays),
      usualPeriodDays: usualPeriodDays == null && nullToAbsent
          ? const Value.absent()
          : Value(usualPeriodDays),
      theme: theme == null && nullToAbsent
          ? const Value.absent()
          : Value(theme),
      units: units == null && nullToAbsent
          ? const Value.absent()
          : Value(units),
      timezone: timezone == null && nullToAbsent
          ? const Value.absent()
          : Value(timezone),
      birthYear: birthYear == null && nullToAbsent
          ? const Value.absent()
          : Value(birthYear),
      birthMonth: birthMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(birthMonth),
      syncState: Value(syncState),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProfile(
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String?>(json['name']),
      usualCycleDays: serializer.fromJson<int?>(json['usualCycleDays']),
      usualPeriodDays: serializer.fromJson<int?>(json['usualPeriodDays']),
      theme: serializer.fromJson<String?>(json['theme']),
      units: serializer.fromJson<String?>(json['units']),
      timezone: serializer.fromJson<String?>(json['timezone']),
      birthYear: serializer.fromJson<int?>(json['birthYear']),
      birthMonth: serializer.fromJson<int?>(json['birthMonth']),
      syncState: $LocalProfilesTable.$convertersyncState.fromJson(
        serializer.fromJson<int>(json['syncState']),
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String?>(name),
      'usualCycleDays': serializer.toJson<int?>(usualCycleDays),
      'usualPeriodDays': serializer.toJson<int?>(usualPeriodDays),
      'theme': serializer.toJson<String?>(theme),
      'units': serializer.toJson<String?>(units),
      'timezone': serializer.toJson<String?>(timezone),
      'birthYear': serializer.toJson<int?>(birthYear),
      'birthMonth': serializer.toJson<int?>(birthMonth),
      'syncState': serializer.toJson<int>(
        $LocalProfilesTable.$convertersyncState.toJson(syncState),
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalProfile copyWith({
    String? userId,
    Value<String?> name = const Value.absent(),
    Value<int?> usualCycleDays = const Value.absent(),
    Value<int?> usualPeriodDays = const Value.absent(),
    Value<String?> theme = const Value.absent(),
    Value<String?> units = const Value.absent(),
    Value<String?> timezone = const Value.absent(),
    Value<int?> birthYear = const Value.absent(),
    Value<int?> birthMonth = const Value.absent(),
    SyncState? syncState,
    DateTime? updatedAt,
  }) => LocalProfile(
    userId: userId ?? this.userId,
    name: name.present ? name.value : this.name,
    usualCycleDays: usualCycleDays.present
        ? usualCycleDays.value
        : this.usualCycleDays,
    usualPeriodDays: usualPeriodDays.present
        ? usualPeriodDays.value
        : this.usualPeriodDays,
    theme: theme.present ? theme.value : this.theme,
    units: units.present ? units.value : this.units,
    timezone: timezone.present ? timezone.value : this.timezone,
    birthYear: birthYear.present ? birthYear.value : this.birthYear,
    birthMonth: birthMonth.present ? birthMonth.value : this.birthMonth,
    syncState: syncState ?? this.syncState,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalProfile copyWithCompanion(LocalProfilesCompanion data) {
    return LocalProfile(
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      usualCycleDays: data.usualCycleDays.present
          ? data.usualCycleDays.value
          : this.usualCycleDays,
      usualPeriodDays: data.usualPeriodDays.present
          ? data.usualPeriodDays.value
          : this.usualPeriodDays,
      theme: data.theme.present ? data.theme.value : this.theme,
      units: data.units.present ? data.units.value : this.units,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      birthYear: data.birthYear.present ? data.birthYear.value : this.birthYear,
      birthMonth: data.birthMonth.present
          ? data.birthMonth.value
          : this.birthMonth,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProfile(')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('usualCycleDays: $usualCycleDays, ')
          ..write('usualPeriodDays: $usualPeriodDays, ')
          ..write('theme: $theme, ')
          ..write('units: $units, ')
          ..write('timezone: $timezone, ')
          ..write('birthYear: $birthYear, ')
          ..write('birthMonth: $birthMonth, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    name,
    usualCycleDays,
    usualPeriodDays,
    theme,
    units,
    timezone,
    birthYear,
    birthMonth,
    syncState,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProfile &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.usualCycleDays == this.usualCycleDays &&
          other.usualPeriodDays == this.usualPeriodDays &&
          other.theme == this.theme &&
          other.units == this.units &&
          other.timezone == this.timezone &&
          other.birthYear == this.birthYear &&
          other.birthMonth == this.birthMonth &&
          other.syncState == this.syncState &&
          other.updatedAt == this.updatedAt);
}

class LocalProfilesCompanion extends UpdateCompanion<LocalProfile> {
  final Value<String> userId;
  final Value<String?> name;
  final Value<int?> usualCycleDays;
  final Value<int?> usualPeriodDays;
  final Value<String?> theme;
  final Value<String?> units;
  final Value<String?> timezone;
  final Value<int?> birthYear;
  final Value<int?> birthMonth;
  final Value<SyncState> syncState;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalProfilesCompanion({
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.usualCycleDays = const Value.absent(),
    this.usualPeriodDays = const Value.absent(),
    this.theme = const Value.absent(),
    this.units = const Value.absent(),
    this.timezone = const Value.absent(),
    this.birthYear = const Value.absent(),
    this.birthMonth = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProfilesCompanion.insert({
    required String userId,
    this.name = const Value.absent(),
    this.usualCycleDays = const Value.absent(),
    this.usualPeriodDays = const Value.absent(),
    this.theme = const Value.absent(),
    this.units = const Value.absent(),
    this.timezone = const Value.absent(),
    this.birthYear = const Value.absent(),
    this.birthMonth = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<LocalProfile> custom({
    Expression<String>? userId,
    Expression<String>? name,
    Expression<int>? usualCycleDays,
    Expression<int>? usualPeriodDays,
    Expression<String>? theme,
    Expression<String>? units,
    Expression<String>? timezone,
    Expression<int>? birthYear,
    Expression<int>? birthMonth,
    Expression<int>? syncState,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (usualCycleDays != null) 'usual_cycle_days': usualCycleDays,
      if (usualPeriodDays != null) 'usual_period_days': usualPeriodDays,
      if (theme != null) 'theme': theme,
      if (units != null) 'units': units,
      if (timezone != null) 'timezone': timezone,
      if (birthYear != null) 'birth_year': birthYear,
      if (birthMonth != null) 'birth_month': birthMonth,
      if (syncState != null) 'sync_state': syncState,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProfilesCompanion copyWith({
    Value<String>? userId,
    Value<String?>? name,
    Value<int?>? usualCycleDays,
    Value<int?>? usualPeriodDays,
    Value<String?>? theme,
    Value<String?>? units,
    Value<String?>? timezone,
    Value<int?>? birthYear,
    Value<int?>? birthMonth,
    Value<SyncState>? syncState,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalProfilesCompanion(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      usualCycleDays: usualCycleDays ?? this.usualCycleDays,
      usualPeriodDays: usualPeriodDays ?? this.usualPeriodDays,
      theme: theme ?? this.theme,
      units: units ?? this.units,
      timezone: timezone ?? this.timezone,
      birthYear: birthYear ?? this.birthYear,
      birthMonth: birthMonth ?? this.birthMonth,
      syncState: syncState ?? this.syncState,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (usualCycleDays.present) {
      map['usual_cycle_days'] = Variable<int>(usualCycleDays.value);
    }
    if (usualPeriodDays.present) {
      map['usual_period_days'] = Variable<int>(usualPeriodDays.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (units.present) {
      map['units'] = Variable<String>(units.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (birthYear.present) {
      map['birth_year'] = Variable<int>(birthYear.value);
    }
    if (birthMonth.present) {
      map['birth_month'] = Variable<int>(birthMonth.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<int>(
        $LocalProfilesTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProfilesCompanion(')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('usualCycleDays: $usualCycleDays, ')
          ..write('usualPeriodDays: $usualPeriodDays, ')
          ..write('theme: $theme, ')
          ..write('units: $units, ')
          ..write('timezone: $timezone, ')
          ..write('birthYear: $birthYear, ')
          ..write('birthMonth: $birthMonth, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalCyclesTable extends LocalCycles
    with TableInfo<$LocalCyclesTable, LocalCycle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalCyclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _periodStartMeta = const VerificationMeta(
    'periodStart',
  );
  @override
  late final GeneratedColumn<String> periodStart = GeneratedColumn<String>(
    'period_start',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodEndMeta = const VerificationMeta(
    'periodEnd',
  );
  @override
  late final GeneratedColumn<String> periodEnd = GeneratedColumn<String>(
    'period_end',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, int> syncState =
      GeneratedColumn<int>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.synced.index),
      ).withConverter<SyncState>($LocalCyclesTable.$convertersyncState);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localId,
    userId,
    serverId,
    periodStart,
    periodEnd,
    syncState,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_cycles';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCycle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('period_start')) {
      context.handle(
        _periodStartMeta,
        periodStart.isAcceptableOrUnknown(
          data['period_start']!,
          _periodStartMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_periodStartMeta);
    }
    if (data.containsKey('period_end')) {
      context.handle(
        _periodEndMeta,
        periodEnd.isAcceptableOrUnknown(data['period_end']!, _periodEndMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCycle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCycle(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      periodStart: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_start'],
      )!,
      periodEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_end'],
      ),
      syncState: $LocalCyclesTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalCyclesTable createAlias(String alias) {
    return $LocalCyclesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, int, int> $convertersyncState =
      const EnumIndexConverter<SyncState>(SyncState.values);
}

class LocalCycle extends DataClass implements Insertable<LocalCycle> {
  final int id;
  final String localId;
  final String userId;
  final int? serverId;
  final String periodStart;
  final String? periodEnd;
  final SyncState syncState;
  final DateTime updatedAt;
  const LocalCycle({
    required this.id,
    required this.localId,
    required this.userId,
    this.serverId,
    required this.periodStart,
    this.periodEnd,
    required this.syncState,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['local_id'] = Variable<String>(localId);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['period_start'] = Variable<String>(periodStart);
    if (!nullToAbsent || periodEnd != null) {
      map['period_end'] = Variable<String>(periodEnd);
    }
    {
      map['sync_state'] = Variable<int>(
        $LocalCyclesTable.$convertersyncState.toSql(syncState),
      );
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalCyclesCompanion toCompanion(bool nullToAbsent) {
    return LocalCyclesCompanion(
      id: Value(id),
      localId: Value(localId),
      userId: Value(userId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      periodStart: Value(periodStart),
      periodEnd: periodEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(periodEnd),
      syncState: Value(syncState),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalCycle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCycle(
      id: serializer.fromJson<int>(json['id']),
      localId: serializer.fromJson<String>(json['localId']),
      userId: serializer.fromJson<String>(json['userId']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      periodStart: serializer.fromJson<String>(json['periodStart']),
      periodEnd: serializer.fromJson<String?>(json['periodEnd']),
      syncState: $LocalCyclesTable.$convertersyncState.fromJson(
        serializer.fromJson<int>(json['syncState']),
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localId': serializer.toJson<String>(localId),
      'userId': serializer.toJson<String>(userId),
      'serverId': serializer.toJson<int?>(serverId),
      'periodStart': serializer.toJson<String>(periodStart),
      'periodEnd': serializer.toJson<String?>(periodEnd),
      'syncState': serializer.toJson<int>(
        $LocalCyclesTable.$convertersyncState.toJson(syncState),
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalCycle copyWith({
    int? id,
    String? localId,
    String? userId,
    Value<int?> serverId = const Value.absent(),
    String? periodStart,
    Value<String?> periodEnd = const Value.absent(),
    SyncState? syncState,
    DateTime? updatedAt,
  }) => LocalCycle(
    id: id ?? this.id,
    localId: localId ?? this.localId,
    userId: userId ?? this.userId,
    serverId: serverId.present ? serverId.value : this.serverId,
    periodStart: periodStart ?? this.periodStart,
    periodEnd: periodEnd.present ? periodEnd.value : this.periodEnd,
    syncState: syncState ?? this.syncState,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalCycle copyWithCompanion(LocalCyclesCompanion data) {
    return LocalCycle(
      id: data.id.present ? data.id.value : this.id,
      localId: data.localId.present ? data.localId.value : this.localId,
      userId: data.userId.present ? data.userId.value : this.userId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      periodStart: data.periodStart.present
          ? data.periodStart.value
          : this.periodStart,
      periodEnd: data.periodEnd.present ? data.periodEnd.value : this.periodEnd,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCycle(')
          ..write('id: $id, ')
          ..write('localId: $localId, ')
          ..write('userId: $userId, ')
          ..write('serverId: $serverId, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localId,
    userId,
    serverId,
    periodStart,
    periodEnd,
    syncState,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCycle &&
          other.id == this.id &&
          other.localId == this.localId &&
          other.userId == this.userId &&
          other.serverId == this.serverId &&
          other.periodStart == this.periodStart &&
          other.periodEnd == this.periodEnd &&
          other.syncState == this.syncState &&
          other.updatedAt == this.updatedAt);
}

class LocalCyclesCompanion extends UpdateCompanion<LocalCycle> {
  final Value<int> id;
  final Value<String> localId;
  final Value<String> userId;
  final Value<int?> serverId;
  final Value<String> periodStart;
  final Value<String?> periodEnd;
  final Value<SyncState> syncState;
  final Value<DateTime> updatedAt;
  const LocalCyclesCompanion({
    this.id = const Value.absent(),
    this.localId = const Value.absent(),
    this.userId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.periodStart = const Value.absent(),
    this.periodEnd = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalCyclesCompanion.insert({
    this.id = const Value.absent(),
    required String localId,
    required String userId,
    this.serverId = const Value.absent(),
    required String periodStart,
    this.periodEnd = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : localId = Value(localId),
       userId = Value(userId),
       periodStart = Value(periodStart);
  static Insertable<LocalCycle> custom({
    Expression<int>? id,
    Expression<String>? localId,
    Expression<String>? userId,
    Expression<int>? serverId,
    Expression<String>? periodStart,
    Expression<String>? periodEnd,
    Expression<int>? syncState,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localId != null) 'local_id': localId,
      if (userId != null) 'user_id': userId,
      if (serverId != null) 'server_id': serverId,
      if (periodStart != null) 'period_start': periodStart,
      if (periodEnd != null) 'period_end': periodEnd,
      if (syncState != null) 'sync_state': syncState,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalCyclesCompanion copyWith({
    Value<int>? id,
    Value<String>? localId,
    Value<String>? userId,
    Value<int?>? serverId,
    Value<String>? periodStart,
    Value<String?>? periodEnd,
    Value<SyncState>? syncState,
    Value<DateTime>? updatedAt,
  }) {
    return LocalCyclesCompanion(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      userId: userId ?? this.userId,
      serverId: serverId ?? this.serverId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      syncState: syncState ?? this.syncState,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (periodStart.present) {
      map['period_start'] = Variable<String>(periodStart.value);
    }
    if (periodEnd.present) {
      map['period_end'] = Variable<String>(periodEnd.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<int>(
        $LocalCyclesTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalCyclesCompanion(')
          ..write('id: $id, ')
          ..write('localId: $localId, ')
          ..write('userId: $userId, ')
          ..write('serverId: $serverId, ')
          ..write('periodStart: $periodStart, ')
          ..write('periodEnd: $periodEnd, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalDailyLogsTable extends LocalDailyLogs
    with TableInfo<$LocalDailyLogsTable, LocalDailyLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDailyLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _logDateMeta = const VerificationMeta(
    'logDate',
  );
  @override
  late final GeneratedColumn<String> logDate = GeneratedColumn<String>(
    'log_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _painMeta = const VerificationMeta('pain');
  @override
  late final GeneratedColumn<int> pain = GeneratedColumn<int>(
    'pain',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
    'mood',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _flowMeta = const VerificationMeta('flow');
  @override
  late final GeneratedColumn<String> flow = GeneratedColumn<String>(
    'flow',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dischargeMeta = const VerificationMeta(
    'discharge',
  );
  @override
  late final GeneratedColumn<String> discharge = GeneratedColumn<String>(
    'discharge',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, int> syncState =
      GeneratedColumn<int>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.synced.index),
      ).withConverter<SyncState>($LocalDailyLogsTable.$convertersyncState);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    logDate,
    pain,
    mood,
    flow,
    discharge,
    notes,
    syncState,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_daily_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDailyLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('log_date')) {
      context.handle(
        _logDateMeta,
        logDate.isAcceptableOrUnknown(data['log_date']!, _logDateMeta),
      );
    } else if (isInserting) {
      context.missing(_logDateMeta);
    }
    if (data.containsKey('pain')) {
      context.handle(
        _painMeta,
        pain.isAcceptableOrUnknown(data['pain']!, _painMeta),
      );
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    }
    if (data.containsKey('flow')) {
      context.handle(
        _flowMeta,
        flow.isAcceptableOrUnknown(data['flow']!, _flowMeta),
      );
    }
    if (data.containsKey('discharge')) {
      context.handle(
        _dischargeMeta,
        discharge.isAcceptableOrUnknown(data['discharge']!, _dischargeMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {userId, logDate},
  ];
  @override
  LocalDailyLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDailyLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      logDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}log_date'],
      )!,
      pain: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pain'],
      ),
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mood'],
      ),
      flow: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flow'],
      ),
      discharge: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}discharge'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      syncState: $LocalDailyLogsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalDailyLogsTable createAlias(String alias) {
    return $LocalDailyLogsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, int, int> $convertersyncState =
      const EnumIndexConverter<SyncState>(SyncState.values);
}

class LocalDailyLog extends DataClass implements Insertable<LocalDailyLog> {
  final int id;
  final String userId;
  final String logDate;
  final int? pain;
  final String? mood;
  final String? flow;
  final String? discharge;
  final String? notes;
  final SyncState syncState;
  final DateTime updatedAt;
  const LocalDailyLog({
    required this.id,
    required this.userId,
    required this.logDate,
    this.pain,
    this.mood,
    this.flow,
    this.discharge,
    this.notes,
    required this.syncState,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['log_date'] = Variable<String>(logDate);
    if (!nullToAbsent || pain != null) {
      map['pain'] = Variable<int>(pain);
    }
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<String>(mood);
    }
    if (!nullToAbsent || flow != null) {
      map['flow'] = Variable<String>(flow);
    }
    if (!nullToAbsent || discharge != null) {
      map['discharge'] = Variable<String>(discharge);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['sync_state'] = Variable<int>(
        $LocalDailyLogsTable.$convertersyncState.toSql(syncState),
      );
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalDailyLogsCompanion toCompanion(bool nullToAbsent) {
    return LocalDailyLogsCompanion(
      id: Value(id),
      userId: Value(userId),
      logDate: Value(logDate),
      pain: pain == null && nullToAbsent ? const Value.absent() : Value(pain),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      flow: flow == null && nullToAbsent ? const Value.absent() : Value(flow),
      discharge: discharge == null && nullToAbsent
          ? const Value.absent()
          : Value(discharge),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      syncState: Value(syncState),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalDailyLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDailyLog(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      logDate: serializer.fromJson<String>(json['logDate']),
      pain: serializer.fromJson<int?>(json['pain']),
      mood: serializer.fromJson<String?>(json['mood']),
      flow: serializer.fromJson<String?>(json['flow']),
      discharge: serializer.fromJson<String?>(json['discharge']),
      notes: serializer.fromJson<String?>(json['notes']),
      syncState: $LocalDailyLogsTable.$convertersyncState.fromJson(
        serializer.fromJson<int>(json['syncState']),
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'logDate': serializer.toJson<String>(logDate),
      'pain': serializer.toJson<int?>(pain),
      'mood': serializer.toJson<String?>(mood),
      'flow': serializer.toJson<String?>(flow),
      'discharge': serializer.toJson<String?>(discharge),
      'notes': serializer.toJson<String?>(notes),
      'syncState': serializer.toJson<int>(
        $LocalDailyLogsTable.$convertersyncState.toJson(syncState),
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalDailyLog copyWith({
    int? id,
    String? userId,
    String? logDate,
    Value<int?> pain = const Value.absent(),
    Value<String?> mood = const Value.absent(),
    Value<String?> flow = const Value.absent(),
    Value<String?> discharge = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    SyncState? syncState,
    DateTime? updatedAt,
  }) => LocalDailyLog(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    logDate: logDate ?? this.logDate,
    pain: pain.present ? pain.value : this.pain,
    mood: mood.present ? mood.value : this.mood,
    flow: flow.present ? flow.value : this.flow,
    discharge: discharge.present ? discharge.value : this.discharge,
    notes: notes.present ? notes.value : this.notes,
    syncState: syncState ?? this.syncState,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalDailyLog copyWithCompanion(LocalDailyLogsCompanion data) {
    return LocalDailyLog(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      logDate: data.logDate.present ? data.logDate.value : this.logDate,
      pain: data.pain.present ? data.pain.value : this.pain,
      mood: data.mood.present ? data.mood.value : this.mood,
      flow: data.flow.present ? data.flow.value : this.flow,
      discharge: data.discharge.present ? data.discharge.value : this.discharge,
      notes: data.notes.present ? data.notes.value : this.notes,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDailyLog(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('logDate: $logDate, ')
          ..write('pain: $pain, ')
          ..write('mood: $mood, ')
          ..write('flow: $flow, ')
          ..write('discharge: $discharge, ')
          ..write('notes: $notes, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    logDate,
    pain,
    mood,
    flow,
    discharge,
    notes,
    syncState,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDailyLog &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.logDate == this.logDate &&
          other.pain == this.pain &&
          other.mood == this.mood &&
          other.flow == this.flow &&
          other.discharge == this.discharge &&
          other.notes == this.notes &&
          other.syncState == this.syncState &&
          other.updatedAt == this.updatedAt);
}

class LocalDailyLogsCompanion extends UpdateCompanion<LocalDailyLog> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> logDate;
  final Value<int?> pain;
  final Value<String?> mood;
  final Value<String?> flow;
  final Value<String?> discharge;
  final Value<String?> notes;
  final Value<SyncState> syncState;
  final Value<DateTime> updatedAt;
  const LocalDailyLogsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.logDate = const Value.absent(),
    this.pain = const Value.absent(),
    this.mood = const Value.absent(),
    this.flow = const Value.absent(),
    this.discharge = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalDailyLogsCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String logDate,
    this.pain = const Value.absent(),
    this.mood = const Value.absent(),
    this.flow = const Value.absent(),
    this.discharge = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : userId = Value(userId),
       logDate = Value(logDate);
  static Insertable<LocalDailyLog> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? logDate,
    Expression<int>? pain,
    Expression<String>? mood,
    Expression<String>? flow,
    Expression<String>? discharge,
    Expression<String>? notes,
    Expression<int>? syncState,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (logDate != null) 'log_date': logDate,
      if (pain != null) 'pain': pain,
      if (mood != null) 'mood': mood,
      if (flow != null) 'flow': flow,
      if (discharge != null) 'discharge': discharge,
      if (notes != null) 'notes': notes,
      if (syncState != null) 'sync_state': syncState,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalDailyLogsCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? logDate,
    Value<int?>? pain,
    Value<String?>? mood,
    Value<String?>? flow,
    Value<String?>? discharge,
    Value<String?>? notes,
    Value<SyncState>? syncState,
    Value<DateTime>? updatedAt,
  }) {
    return LocalDailyLogsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      logDate: logDate ?? this.logDate,
      pain: pain ?? this.pain,
      mood: mood ?? this.mood,
      flow: flow ?? this.flow,
      discharge: discharge ?? this.discharge,
      notes: notes ?? this.notes,
      syncState: syncState ?? this.syncState,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (logDate.present) {
      map['log_date'] = Variable<String>(logDate.value);
    }
    if (pain.present) {
      map['pain'] = Variable<int>(pain.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (flow.present) {
      map['flow'] = Variable<String>(flow.value);
    }
    if (discharge.present) {
      map['discharge'] = Variable<String>(discharge.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<int>(
        $LocalDailyLogsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDailyLogsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('logDate: $logDate, ')
          ..write('pain: $pain, ')
          ..write('mood: $mood, ')
          ..write('flow: $flow, ')
          ..write('discharge: $discharge, ')
          ..write('notes: $notes, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalSymptomsTable extends LocalSymptoms
    with TableInfo<$LocalSymptomsTable, LocalSymptom> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSymptomsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _logDateMeta = const VerificationMeta(
    'logDate',
  );
  @override
  late final GeneratedColumn<String> logDate = GeneratedColumn<String>(
    'log_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _symptomTypeMeta = const VerificationMeta(
    'symptomType',
  );
  @override
  late final GeneratedColumn<String> symptomType = GeneratedColumn<String>(
    'symptom_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<int> severity = GeneratedColumn<int>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    logDate,
    symptomType,
    severity,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_symptoms';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSymptom> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('log_date')) {
      context.handle(
        _logDateMeta,
        logDate.isAcceptableOrUnknown(data['log_date']!, _logDateMeta),
      );
    } else if (isInserting) {
      context.missing(_logDateMeta);
    }
    if (data.containsKey('symptom_type')) {
      context.handle(
        _symptomTypeMeta,
        symptomType.isAcceptableOrUnknown(
          data['symptom_type']!,
          _symptomTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_symptomTypeMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalSymptom map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSymptom(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      logDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}log_date'],
      )!,
      symptomType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symptom_type'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}severity'],
      )!,
    );
  }

  @override
  $LocalSymptomsTable createAlias(String alias) {
    return $LocalSymptomsTable(attachedDatabase, alias);
  }
}

class LocalSymptom extends DataClass implements Insertable<LocalSymptom> {
  final int id;
  final String userId;
  final String logDate;
  final String symptomType;
  final int severity;
  const LocalSymptom({
    required this.id,
    required this.userId,
    required this.logDate,
    required this.symptomType,
    required this.severity,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['log_date'] = Variable<String>(logDate);
    map['symptom_type'] = Variable<String>(symptomType);
    map['severity'] = Variable<int>(severity);
    return map;
  }

  LocalSymptomsCompanion toCompanion(bool nullToAbsent) {
    return LocalSymptomsCompanion(
      id: Value(id),
      userId: Value(userId),
      logDate: Value(logDate),
      symptomType: Value(symptomType),
      severity: Value(severity),
    );
  }

  factory LocalSymptom.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSymptom(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      logDate: serializer.fromJson<String>(json['logDate']),
      symptomType: serializer.fromJson<String>(json['symptomType']),
      severity: serializer.fromJson<int>(json['severity']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'logDate': serializer.toJson<String>(logDate),
      'symptomType': serializer.toJson<String>(symptomType),
      'severity': serializer.toJson<int>(severity),
    };
  }

  LocalSymptom copyWith({
    int? id,
    String? userId,
    String? logDate,
    String? symptomType,
    int? severity,
  }) => LocalSymptom(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    logDate: logDate ?? this.logDate,
    symptomType: symptomType ?? this.symptomType,
    severity: severity ?? this.severity,
  );
  LocalSymptom copyWithCompanion(LocalSymptomsCompanion data) {
    return LocalSymptom(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      logDate: data.logDate.present ? data.logDate.value : this.logDate,
      symptomType: data.symptomType.present
          ? data.symptomType.value
          : this.symptomType,
      severity: data.severity.present ? data.severity.value : this.severity,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSymptom(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('logDate: $logDate, ')
          ..write('symptomType: $symptomType, ')
          ..write('severity: $severity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, logDate, symptomType, severity);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSymptom &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.logDate == this.logDate &&
          other.symptomType == this.symptomType &&
          other.severity == this.severity);
}

class LocalSymptomsCompanion extends UpdateCompanion<LocalSymptom> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> logDate;
  final Value<String> symptomType;
  final Value<int> severity;
  const LocalSymptomsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.logDate = const Value.absent(),
    this.symptomType = const Value.absent(),
    this.severity = const Value.absent(),
  });
  LocalSymptomsCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String logDate,
    required String symptomType,
    this.severity = const Value.absent(),
  }) : userId = Value(userId),
       logDate = Value(logDate),
       symptomType = Value(symptomType);
  static Insertable<LocalSymptom> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? logDate,
    Expression<String>? symptomType,
    Expression<int>? severity,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (logDate != null) 'log_date': logDate,
      if (symptomType != null) 'symptom_type': symptomType,
      if (severity != null) 'severity': severity,
    });
  }

  LocalSymptomsCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? logDate,
    Value<String>? symptomType,
    Value<int>? severity,
  }) {
    return LocalSymptomsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      logDate: logDate ?? this.logDate,
      symptomType: symptomType ?? this.symptomType,
      severity: severity ?? this.severity,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (logDate.present) {
      map['log_date'] = Variable<String>(logDate.value);
    }
    if (symptomType.present) {
      map['symptom_type'] = Variable<String>(symptomType.value);
    }
    if (severity.present) {
      map['severity'] = Variable<int>(severity.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSymptomsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('logDate: $logDate, ')
          ..write('symptomType: $symptomType, ')
          ..write('severity: $severity')
          ..write(')'))
        .toString();
  }
}

class $PredictionCacheTable extends PredictionCache
    with TableInfo<$PredictionCacheTable, PredictionCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PredictionCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phaseMeta = const VerificationMeta('phase');
  @override
  late final GeneratedColumn<String> phase = GeneratedColumn<String>(
    'phase',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _predictedNextPeriodMeta =
      const VerificationMeta('predictedNextPeriod');
  @override
  late final GeneratedColumn<String> predictedNextPeriod =
      GeneratedColumn<String>(
        'predicted_next_period',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _daysUntilNextPeriodMeta =
      const VerificationMeta('daysUntilNextPeriod');
  @override
  late final GeneratedColumn<int> daysUntilNextPeriod = GeneratedColumn<int>(
    'days_until_next_period',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _predictionStatusMeta = const VerificationMeta(
    'predictionStatus',
  );
  @override
  late final GeneratedColumn<String> predictionStatus = GeneratedColumn<String>(
    'prediction_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _predictionConfidenceMeta =
      const VerificationMeta('predictionConfidence');
  @override
  late final GeneratedColumn<String> predictionConfidence =
      GeneratedColumn<String>(
        'prediction_confidence',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _averageCycleLengthMeta =
      const VerificationMeta('averageCycleLength');
  @override
  late final GeneratedColumn<double> averageCycleLength =
      GeneratedColumn<double>(
        'average_cycle_length',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _averagePeriodLengthMeta =
      const VerificationMeta('averagePeriodLength');
  @override
  late final GeneratedColumn<double> averagePeriodLength =
      GeneratedColumn<double>(
        'average_period_length',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    phase,
    predictedNextPeriod,
    daysUntilNextPeriod,
    predictionStatus,
    predictionConfidence,
    averageCycleLength,
    averagePeriodLength,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prediction_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<PredictionCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('phase')) {
      context.handle(
        _phaseMeta,
        phase.isAcceptableOrUnknown(data['phase']!, _phaseMeta),
      );
    }
    if (data.containsKey('predicted_next_period')) {
      context.handle(
        _predictedNextPeriodMeta,
        predictedNextPeriod.isAcceptableOrUnknown(
          data['predicted_next_period']!,
          _predictedNextPeriodMeta,
        ),
      );
    }
    if (data.containsKey('days_until_next_period')) {
      context.handle(
        _daysUntilNextPeriodMeta,
        daysUntilNextPeriod.isAcceptableOrUnknown(
          data['days_until_next_period']!,
          _daysUntilNextPeriodMeta,
        ),
      );
    }
    if (data.containsKey('prediction_status')) {
      context.handle(
        _predictionStatusMeta,
        predictionStatus.isAcceptableOrUnknown(
          data['prediction_status']!,
          _predictionStatusMeta,
        ),
      );
    }
    if (data.containsKey('prediction_confidence')) {
      context.handle(
        _predictionConfidenceMeta,
        predictionConfidence.isAcceptableOrUnknown(
          data['prediction_confidence']!,
          _predictionConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('average_cycle_length')) {
      context.handle(
        _averageCycleLengthMeta,
        averageCycleLength.isAcceptableOrUnknown(
          data['average_cycle_length']!,
          _averageCycleLengthMeta,
        ),
      );
    }
    if (data.containsKey('average_period_length')) {
      context.handle(
        _averagePeriodLengthMeta,
        averagePeriodLength.isAcceptableOrUnknown(
          data['average_period_length']!,
          _averagePeriodLengthMeta,
        ),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  PredictionCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PredictionCacheData(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      phase: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phase'],
      ),
      predictedNextPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}predicted_next_period'],
      ),
      daysUntilNextPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days_until_next_period'],
      ),
      predictionStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prediction_status'],
      ),
      predictionConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prediction_confidence'],
      ),
      averageCycleLength: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_cycle_length'],
      ),
      averagePeriodLength: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}average_period_length'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $PredictionCacheTable createAlias(String alias) {
    return $PredictionCacheTable(attachedDatabase, alias);
  }
}

class PredictionCacheData extends DataClass
    implements Insertable<PredictionCacheData> {
  final String userId;
  final String? phase;
  final String? predictedNextPeriod;
  final int? daysUntilNextPeriod;
  final String? predictionStatus;
  final String? predictionConfidence;
  final double? averageCycleLength;
  final double? averagePeriodLength;
  final DateTime fetchedAt;
  const PredictionCacheData({
    required this.userId,
    this.phase,
    this.predictedNextPeriod,
    this.daysUntilNextPeriod,
    this.predictionStatus,
    this.predictionConfidence,
    this.averageCycleLength,
    this.averagePeriodLength,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || phase != null) {
      map['phase'] = Variable<String>(phase);
    }
    if (!nullToAbsent || predictedNextPeriod != null) {
      map['predicted_next_period'] = Variable<String>(predictedNextPeriod);
    }
    if (!nullToAbsent || daysUntilNextPeriod != null) {
      map['days_until_next_period'] = Variable<int>(daysUntilNextPeriod);
    }
    if (!nullToAbsent || predictionStatus != null) {
      map['prediction_status'] = Variable<String>(predictionStatus);
    }
    if (!nullToAbsent || predictionConfidence != null) {
      map['prediction_confidence'] = Variable<String>(predictionConfidence);
    }
    if (!nullToAbsent || averageCycleLength != null) {
      map['average_cycle_length'] = Variable<double>(averageCycleLength);
    }
    if (!nullToAbsent || averagePeriodLength != null) {
      map['average_period_length'] = Variable<double>(averagePeriodLength);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  PredictionCacheCompanion toCompanion(bool nullToAbsent) {
    return PredictionCacheCompanion(
      userId: Value(userId),
      phase: phase == null && nullToAbsent
          ? const Value.absent()
          : Value(phase),
      predictedNextPeriod: predictedNextPeriod == null && nullToAbsent
          ? const Value.absent()
          : Value(predictedNextPeriod),
      daysUntilNextPeriod: daysUntilNextPeriod == null && nullToAbsent
          ? const Value.absent()
          : Value(daysUntilNextPeriod),
      predictionStatus: predictionStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(predictionStatus),
      predictionConfidence: predictionConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(predictionConfidence),
      averageCycleLength: averageCycleLength == null && nullToAbsent
          ? const Value.absent()
          : Value(averageCycleLength),
      averagePeriodLength: averagePeriodLength == null && nullToAbsent
          ? const Value.absent()
          : Value(averagePeriodLength),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory PredictionCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PredictionCacheData(
      userId: serializer.fromJson<String>(json['userId']),
      phase: serializer.fromJson<String?>(json['phase']),
      predictedNextPeriod: serializer.fromJson<String?>(
        json['predictedNextPeriod'],
      ),
      daysUntilNextPeriod: serializer.fromJson<int?>(
        json['daysUntilNextPeriod'],
      ),
      predictionStatus: serializer.fromJson<String?>(json['predictionStatus']),
      predictionConfidence: serializer.fromJson<String?>(
        json['predictionConfidence'],
      ),
      averageCycleLength: serializer.fromJson<double?>(
        json['averageCycleLength'],
      ),
      averagePeriodLength: serializer.fromJson<double?>(
        json['averagePeriodLength'],
      ),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'phase': serializer.toJson<String?>(phase),
      'predictedNextPeriod': serializer.toJson<String?>(predictedNextPeriod),
      'daysUntilNextPeriod': serializer.toJson<int?>(daysUntilNextPeriod),
      'predictionStatus': serializer.toJson<String?>(predictionStatus),
      'predictionConfidence': serializer.toJson<String?>(predictionConfidence),
      'averageCycleLength': serializer.toJson<double?>(averageCycleLength),
      'averagePeriodLength': serializer.toJson<double?>(averagePeriodLength),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  PredictionCacheData copyWith({
    String? userId,
    Value<String?> phase = const Value.absent(),
    Value<String?> predictedNextPeriod = const Value.absent(),
    Value<int?> daysUntilNextPeriod = const Value.absent(),
    Value<String?> predictionStatus = const Value.absent(),
    Value<String?> predictionConfidence = const Value.absent(),
    Value<double?> averageCycleLength = const Value.absent(),
    Value<double?> averagePeriodLength = const Value.absent(),
    DateTime? fetchedAt,
  }) => PredictionCacheData(
    userId: userId ?? this.userId,
    phase: phase.present ? phase.value : this.phase,
    predictedNextPeriod: predictedNextPeriod.present
        ? predictedNextPeriod.value
        : this.predictedNextPeriod,
    daysUntilNextPeriod: daysUntilNextPeriod.present
        ? daysUntilNextPeriod.value
        : this.daysUntilNextPeriod,
    predictionStatus: predictionStatus.present
        ? predictionStatus.value
        : this.predictionStatus,
    predictionConfidence: predictionConfidence.present
        ? predictionConfidence.value
        : this.predictionConfidence,
    averageCycleLength: averageCycleLength.present
        ? averageCycleLength.value
        : this.averageCycleLength,
    averagePeriodLength: averagePeriodLength.present
        ? averagePeriodLength.value
        : this.averagePeriodLength,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  PredictionCacheData copyWithCompanion(PredictionCacheCompanion data) {
    return PredictionCacheData(
      userId: data.userId.present ? data.userId.value : this.userId,
      phase: data.phase.present ? data.phase.value : this.phase,
      predictedNextPeriod: data.predictedNextPeriod.present
          ? data.predictedNextPeriod.value
          : this.predictedNextPeriod,
      daysUntilNextPeriod: data.daysUntilNextPeriod.present
          ? data.daysUntilNextPeriod.value
          : this.daysUntilNextPeriod,
      predictionStatus: data.predictionStatus.present
          ? data.predictionStatus.value
          : this.predictionStatus,
      predictionConfidence: data.predictionConfidence.present
          ? data.predictionConfidence.value
          : this.predictionConfidence,
      averageCycleLength: data.averageCycleLength.present
          ? data.averageCycleLength.value
          : this.averageCycleLength,
      averagePeriodLength: data.averagePeriodLength.present
          ? data.averagePeriodLength.value
          : this.averagePeriodLength,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PredictionCacheData(')
          ..write('userId: $userId, ')
          ..write('phase: $phase, ')
          ..write('predictedNextPeriod: $predictedNextPeriod, ')
          ..write('daysUntilNextPeriod: $daysUntilNextPeriod, ')
          ..write('predictionStatus: $predictionStatus, ')
          ..write('predictionConfidence: $predictionConfidence, ')
          ..write('averageCycleLength: $averageCycleLength, ')
          ..write('averagePeriodLength: $averagePeriodLength, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    phase,
    predictedNextPeriod,
    daysUntilNextPeriod,
    predictionStatus,
    predictionConfidence,
    averageCycleLength,
    averagePeriodLength,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PredictionCacheData &&
          other.userId == this.userId &&
          other.phase == this.phase &&
          other.predictedNextPeriod == this.predictedNextPeriod &&
          other.daysUntilNextPeriod == this.daysUntilNextPeriod &&
          other.predictionStatus == this.predictionStatus &&
          other.predictionConfidence == this.predictionConfidence &&
          other.averageCycleLength == this.averageCycleLength &&
          other.averagePeriodLength == this.averagePeriodLength &&
          other.fetchedAt == this.fetchedAt);
}

class PredictionCacheCompanion extends UpdateCompanion<PredictionCacheData> {
  final Value<String> userId;
  final Value<String?> phase;
  final Value<String?> predictedNextPeriod;
  final Value<int?> daysUntilNextPeriod;
  final Value<String?> predictionStatus;
  final Value<String?> predictionConfidence;
  final Value<double?> averageCycleLength;
  final Value<double?> averagePeriodLength;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const PredictionCacheCompanion({
    this.userId = const Value.absent(),
    this.phase = const Value.absent(),
    this.predictedNextPeriod = const Value.absent(),
    this.daysUntilNextPeriod = const Value.absent(),
    this.predictionStatus = const Value.absent(),
    this.predictionConfidence = const Value.absent(),
    this.averageCycleLength = const Value.absent(),
    this.averagePeriodLength = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PredictionCacheCompanion.insert({
    required String userId,
    this.phase = const Value.absent(),
    this.predictedNextPeriod = const Value.absent(),
    this.daysUntilNextPeriod = const Value.absent(),
    this.predictionStatus = const Value.absent(),
    this.predictionConfidence = const Value.absent(),
    this.averageCycleLength = const Value.absent(),
    this.averagePeriodLength = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<PredictionCacheData> custom({
    Expression<String>? userId,
    Expression<String>? phase,
    Expression<String>? predictedNextPeriod,
    Expression<int>? daysUntilNextPeriod,
    Expression<String>? predictionStatus,
    Expression<String>? predictionConfidence,
    Expression<double>? averageCycleLength,
    Expression<double>? averagePeriodLength,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (phase != null) 'phase': phase,
      if (predictedNextPeriod != null)
        'predicted_next_period': predictedNextPeriod,
      if (daysUntilNextPeriod != null)
        'days_until_next_period': daysUntilNextPeriod,
      if (predictionStatus != null) 'prediction_status': predictionStatus,
      if (predictionConfidence != null)
        'prediction_confidence': predictionConfidence,
      if (averageCycleLength != null)
        'average_cycle_length': averageCycleLength,
      if (averagePeriodLength != null)
        'average_period_length': averagePeriodLength,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PredictionCacheCompanion copyWith({
    Value<String>? userId,
    Value<String?>? phase,
    Value<String?>? predictedNextPeriod,
    Value<int?>? daysUntilNextPeriod,
    Value<String?>? predictionStatus,
    Value<String?>? predictionConfidence,
    Value<double?>? averageCycleLength,
    Value<double?>? averagePeriodLength,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return PredictionCacheCompanion(
      userId: userId ?? this.userId,
      phase: phase ?? this.phase,
      predictedNextPeriod: predictedNextPeriod ?? this.predictedNextPeriod,
      daysUntilNextPeriod: daysUntilNextPeriod ?? this.daysUntilNextPeriod,
      predictionStatus: predictionStatus ?? this.predictionStatus,
      predictionConfidence: predictionConfidence ?? this.predictionConfidence,
      averageCycleLength: averageCycleLength ?? this.averageCycleLength,
      averagePeriodLength: averagePeriodLength ?? this.averagePeriodLength,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (phase.present) {
      map['phase'] = Variable<String>(phase.value);
    }
    if (predictedNextPeriod.present) {
      map['predicted_next_period'] = Variable<String>(
        predictedNextPeriod.value,
      );
    }
    if (daysUntilNextPeriod.present) {
      map['days_until_next_period'] = Variable<int>(daysUntilNextPeriod.value);
    }
    if (predictionStatus.present) {
      map['prediction_status'] = Variable<String>(predictionStatus.value);
    }
    if (predictionConfidence.present) {
      map['prediction_confidence'] = Variable<String>(
        predictionConfidence.value,
      );
    }
    if (averageCycleLength.present) {
      map['average_cycle_length'] = Variable<double>(averageCycleLength.value);
    }
    if (averagePeriodLength.present) {
      map['average_period_length'] = Variable<double>(
        averagePeriodLength.value,
      );
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PredictionCacheCompanion(')
          ..write('userId: $userId, ')
          ..write('phase: $phase, ')
          ..write('predictedNextPeriod: $predictedNextPeriod, ')
          ..write('daysUntilNextPeriod: $daysUntilNextPeriod, ')
          ..write('predictionStatus: $predictionStatus, ')
          ..write('predictionConfidence: $predictionConfidence, ')
          ..write('averageCycleLength: $averageCycleLength, ')
          ..write('averagePeriodLength: $averagePeriodLength, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalHealthContextTable extends LocalHealthContext
    with TableInfo<$LocalHealthContextTable, LocalHealthContextData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalHealthContextTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contraceptionMethodMeta =
      const VerificationMeta('contraceptionMethod');
  @override
  late final GeneratedColumn<String> contraceptionMethod =
      GeneratedColumn<String>(
        'contraception_method',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _contraceptionNoteMeta = const VerificationMeta(
    'contraceptionNote',
  );
  @override
  late final GeneratedColumn<String> contraceptionNote =
      GeneratedColumn<String>(
        'contraception_note',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _pregnancyContextMeta = const VerificationMeta(
    'pregnancyContext',
  );
  @override
  late final GeneratedColumn<String> pregnancyContext = GeneratedColumn<String>(
    'pregnancy_context',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _healthNotesMeta = const VerificationMeta(
    'healthNotes',
  );
  @override
  late final GeneratedColumn<String> healthNotes = GeneratedColumn<String>(
    'health_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, int> syncState =
      GeneratedColumn<int>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.synced.index),
      ).withConverter<SyncState>($LocalHealthContextTable.$convertersyncState);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    contraceptionMethod,
    contraceptionNote,
    pregnancyContext,
    healthNotes,
    syncState,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_health_context';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalHealthContextData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('contraception_method')) {
      context.handle(
        _contraceptionMethodMeta,
        contraceptionMethod.isAcceptableOrUnknown(
          data['contraception_method']!,
          _contraceptionMethodMeta,
        ),
      );
    }
    if (data.containsKey('contraception_note')) {
      context.handle(
        _contraceptionNoteMeta,
        contraceptionNote.isAcceptableOrUnknown(
          data['contraception_note']!,
          _contraceptionNoteMeta,
        ),
      );
    }
    if (data.containsKey('pregnancy_context')) {
      context.handle(
        _pregnancyContextMeta,
        pregnancyContext.isAcceptableOrUnknown(
          data['pregnancy_context']!,
          _pregnancyContextMeta,
        ),
      );
    }
    if (data.containsKey('health_notes')) {
      context.handle(
        _healthNotesMeta,
        healthNotes.isAcceptableOrUnknown(
          data['health_notes']!,
          _healthNotesMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  LocalHealthContextData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalHealthContextData(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      contraceptionMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contraception_method'],
      ),
      contraceptionNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contraception_note'],
      ),
      pregnancyContext: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pregnancy_context'],
      ),
      healthNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}health_notes'],
      ),
      syncState: $LocalHealthContextTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalHealthContextTable createAlias(String alias) {
    return $LocalHealthContextTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, int, int> $convertersyncState =
      const EnumIndexConverter<SyncState>(SyncState.values);
}

class LocalHealthContextData extends DataClass
    implements Insertable<LocalHealthContextData> {
  final String userId;
  final String? contraceptionMethod;
  final String? contraceptionNote;
  final String? pregnancyContext;
  final String? healthNotes;
  final SyncState syncState;
  final DateTime updatedAt;
  const LocalHealthContextData({
    required this.userId,
    this.contraceptionMethod,
    this.contraceptionNote,
    this.pregnancyContext,
    this.healthNotes,
    required this.syncState,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || contraceptionMethod != null) {
      map['contraception_method'] = Variable<String>(contraceptionMethod);
    }
    if (!nullToAbsent || contraceptionNote != null) {
      map['contraception_note'] = Variable<String>(contraceptionNote);
    }
    if (!nullToAbsent || pregnancyContext != null) {
      map['pregnancy_context'] = Variable<String>(pregnancyContext);
    }
    if (!nullToAbsent || healthNotes != null) {
      map['health_notes'] = Variable<String>(healthNotes);
    }
    {
      map['sync_state'] = Variable<int>(
        $LocalHealthContextTable.$convertersyncState.toSql(syncState),
      );
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalHealthContextCompanion toCompanion(bool nullToAbsent) {
    return LocalHealthContextCompanion(
      userId: Value(userId),
      contraceptionMethod: contraceptionMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(contraceptionMethod),
      contraceptionNote: contraceptionNote == null && nullToAbsent
          ? const Value.absent()
          : Value(contraceptionNote),
      pregnancyContext: pregnancyContext == null && nullToAbsent
          ? const Value.absent()
          : Value(pregnancyContext),
      healthNotes: healthNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(healthNotes),
      syncState: Value(syncState),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalHealthContextData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalHealthContextData(
      userId: serializer.fromJson<String>(json['userId']),
      contraceptionMethod: serializer.fromJson<String?>(
        json['contraceptionMethod'],
      ),
      contraceptionNote: serializer.fromJson<String?>(
        json['contraceptionNote'],
      ),
      pregnancyContext: serializer.fromJson<String?>(json['pregnancyContext']),
      healthNotes: serializer.fromJson<String?>(json['healthNotes']),
      syncState: $LocalHealthContextTable.$convertersyncState.fromJson(
        serializer.fromJson<int>(json['syncState']),
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'contraceptionMethod': serializer.toJson<String?>(contraceptionMethod),
      'contraceptionNote': serializer.toJson<String?>(contraceptionNote),
      'pregnancyContext': serializer.toJson<String?>(pregnancyContext),
      'healthNotes': serializer.toJson<String?>(healthNotes),
      'syncState': serializer.toJson<int>(
        $LocalHealthContextTable.$convertersyncState.toJson(syncState),
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalHealthContextData copyWith({
    String? userId,
    Value<String?> contraceptionMethod = const Value.absent(),
    Value<String?> contraceptionNote = const Value.absent(),
    Value<String?> pregnancyContext = const Value.absent(),
    Value<String?> healthNotes = const Value.absent(),
    SyncState? syncState,
    DateTime? updatedAt,
  }) => LocalHealthContextData(
    userId: userId ?? this.userId,
    contraceptionMethod: contraceptionMethod.present
        ? contraceptionMethod.value
        : this.contraceptionMethod,
    contraceptionNote: contraceptionNote.present
        ? contraceptionNote.value
        : this.contraceptionNote,
    pregnancyContext: pregnancyContext.present
        ? pregnancyContext.value
        : this.pregnancyContext,
    healthNotes: healthNotes.present ? healthNotes.value : this.healthNotes,
    syncState: syncState ?? this.syncState,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalHealthContextData copyWithCompanion(LocalHealthContextCompanion data) {
    return LocalHealthContextData(
      userId: data.userId.present ? data.userId.value : this.userId,
      contraceptionMethod: data.contraceptionMethod.present
          ? data.contraceptionMethod.value
          : this.contraceptionMethod,
      contraceptionNote: data.contraceptionNote.present
          ? data.contraceptionNote.value
          : this.contraceptionNote,
      pregnancyContext: data.pregnancyContext.present
          ? data.pregnancyContext.value
          : this.pregnancyContext,
      healthNotes: data.healthNotes.present
          ? data.healthNotes.value
          : this.healthNotes,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalHealthContextData(')
          ..write('userId: $userId, ')
          ..write('contraceptionMethod: $contraceptionMethod, ')
          ..write('contraceptionNote: $contraceptionNote, ')
          ..write('pregnancyContext: $pregnancyContext, ')
          ..write('healthNotes: $healthNotes, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    contraceptionMethod,
    contraceptionNote,
    pregnancyContext,
    healthNotes,
    syncState,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalHealthContextData &&
          other.userId == this.userId &&
          other.contraceptionMethod == this.contraceptionMethod &&
          other.contraceptionNote == this.contraceptionNote &&
          other.pregnancyContext == this.pregnancyContext &&
          other.healthNotes == this.healthNotes &&
          other.syncState == this.syncState &&
          other.updatedAt == this.updatedAt);
}

class LocalHealthContextCompanion
    extends UpdateCompanion<LocalHealthContextData> {
  final Value<String> userId;
  final Value<String?> contraceptionMethod;
  final Value<String?> contraceptionNote;
  final Value<String?> pregnancyContext;
  final Value<String?> healthNotes;
  final Value<SyncState> syncState;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalHealthContextCompanion({
    this.userId = const Value.absent(),
    this.contraceptionMethod = const Value.absent(),
    this.contraceptionNote = const Value.absent(),
    this.pregnancyContext = const Value.absent(),
    this.healthNotes = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalHealthContextCompanion.insert({
    required String userId,
    this.contraceptionMethod = const Value.absent(),
    this.contraceptionNote = const Value.absent(),
    this.pregnancyContext = const Value.absent(),
    this.healthNotes = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<LocalHealthContextData> custom({
    Expression<String>? userId,
    Expression<String>? contraceptionMethod,
    Expression<String>? contraceptionNote,
    Expression<String>? pregnancyContext,
    Expression<String>? healthNotes,
    Expression<int>? syncState,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (contraceptionMethod != null)
        'contraception_method': contraceptionMethod,
      if (contraceptionNote != null) 'contraception_note': contraceptionNote,
      if (pregnancyContext != null) 'pregnancy_context': pregnancyContext,
      if (healthNotes != null) 'health_notes': healthNotes,
      if (syncState != null) 'sync_state': syncState,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalHealthContextCompanion copyWith({
    Value<String>? userId,
    Value<String?>? contraceptionMethod,
    Value<String?>? contraceptionNote,
    Value<String?>? pregnancyContext,
    Value<String?>? healthNotes,
    Value<SyncState>? syncState,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalHealthContextCompanion(
      userId: userId ?? this.userId,
      contraceptionMethod: contraceptionMethod ?? this.contraceptionMethod,
      contraceptionNote: contraceptionNote ?? this.contraceptionNote,
      pregnancyContext: pregnancyContext ?? this.pregnancyContext,
      healthNotes: healthNotes ?? this.healthNotes,
      syncState: syncState ?? this.syncState,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (contraceptionMethod.present) {
      map['contraception_method'] = Variable<String>(contraceptionMethod.value);
    }
    if (contraceptionNote.present) {
      map['contraception_note'] = Variable<String>(contraceptionNote.value);
    }
    if (pregnancyContext.present) {
      map['pregnancy_context'] = Variable<String>(pregnancyContext.value);
    }
    if (healthNotes.present) {
      map['health_notes'] = Variable<String>(healthNotes.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<int>(
        $LocalHealthContextTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalHealthContextCompanion(')
          ..write('userId: $userId, ')
          ..write('contraceptionMethod: $contraceptionMethod, ')
          ..write('contraceptionNote: $contraceptionNote, ')
          ..write('pregnancyContext: $pregnancyContext, ')
          ..write('healthNotes: $healthNotes, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalConditionsTable extends LocalConditions
    with TableInfo<$LocalConditionsTable, LocalCondition> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalConditionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _customLabelMeta = const VerificationMeta(
    'customLabel',
  );
  @override
  late final GeneratedColumn<String> customLabel = GeneratedColumn<String>(
    'custom_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, int> syncState =
      GeneratedColumn<int>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.synced.index),
      ).withConverter<SyncState>($LocalConditionsTable.$convertersyncState);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localId,
    userId,
    serverId,
    code,
    customLabel,
    note,
    isActive,
    isDeleted,
    syncState,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_conditions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalCondition> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('custom_label')) {
      context.handle(
        _customLabelMeta,
        customLabel.isAcceptableOrUnknown(
          data['custom_label']!,
          _customLabelMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
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
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalCondition map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalCondition(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      customLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_label'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      syncState: $LocalConditionsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalConditionsTable createAlias(String alias) {
    return $LocalConditionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, int, int> $convertersyncState =
      const EnumIndexConverter<SyncState>(SyncState.values);
}

class LocalCondition extends DataClass implements Insertable<LocalCondition> {
  final int id;
  final String localId;
  final String userId;
  final int? serverId;
  final String code;
  final String? customLabel;
  final String? note;
  final bool isActive;
  final bool isDeleted;
  final SyncState syncState;
  final DateTime updatedAt;
  const LocalCondition({
    required this.id,
    required this.localId,
    required this.userId,
    this.serverId,
    required this.code,
    this.customLabel,
    this.note,
    required this.isActive,
    required this.isDeleted,
    required this.syncState,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['local_id'] = Variable<String>(localId);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['code'] = Variable<String>(code);
    if (!nullToAbsent || customLabel != null) {
      map['custom_label'] = Variable<String>(customLabel);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['is_deleted'] = Variable<bool>(isDeleted);
    {
      map['sync_state'] = Variable<int>(
        $LocalConditionsTable.$convertersyncState.toSql(syncState),
      );
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalConditionsCompanion toCompanion(bool nullToAbsent) {
    return LocalConditionsCompanion(
      id: Value(id),
      localId: Value(localId),
      userId: Value(userId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      code: Value(code),
      customLabel: customLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(customLabel),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      isActive: Value(isActive),
      isDeleted: Value(isDeleted),
      syncState: Value(syncState),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalCondition.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalCondition(
      id: serializer.fromJson<int>(json['id']),
      localId: serializer.fromJson<String>(json['localId']),
      userId: serializer.fromJson<String>(json['userId']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      code: serializer.fromJson<String>(json['code']),
      customLabel: serializer.fromJson<String?>(json['customLabel']),
      note: serializer.fromJson<String?>(json['note']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      syncState: $LocalConditionsTable.$convertersyncState.fromJson(
        serializer.fromJson<int>(json['syncState']),
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localId': serializer.toJson<String>(localId),
      'userId': serializer.toJson<String>(userId),
      'serverId': serializer.toJson<int?>(serverId),
      'code': serializer.toJson<String>(code),
      'customLabel': serializer.toJson<String?>(customLabel),
      'note': serializer.toJson<String?>(note),
      'isActive': serializer.toJson<bool>(isActive),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'syncState': serializer.toJson<int>(
        $LocalConditionsTable.$convertersyncState.toJson(syncState),
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalCondition copyWith({
    int? id,
    String? localId,
    String? userId,
    Value<int?> serverId = const Value.absent(),
    String? code,
    Value<String?> customLabel = const Value.absent(),
    Value<String?> note = const Value.absent(),
    bool? isActive,
    bool? isDeleted,
    SyncState? syncState,
    DateTime? updatedAt,
  }) => LocalCondition(
    id: id ?? this.id,
    localId: localId ?? this.localId,
    userId: userId ?? this.userId,
    serverId: serverId.present ? serverId.value : this.serverId,
    code: code ?? this.code,
    customLabel: customLabel.present ? customLabel.value : this.customLabel,
    note: note.present ? note.value : this.note,
    isActive: isActive ?? this.isActive,
    isDeleted: isDeleted ?? this.isDeleted,
    syncState: syncState ?? this.syncState,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalCondition copyWithCompanion(LocalConditionsCompanion data) {
    return LocalCondition(
      id: data.id.present ? data.id.value : this.id,
      localId: data.localId.present ? data.localId.value : this.localId,
      userId: data.userId.present ? data.userId.value : this.userId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      code: data.code.present ? data.code.value : this.code,
      customLabel: data.customLabel.present
          ? data.customLabel.value
          : this.customLabel,
      note: data.note.present ? data.note.value : this.note,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalCondition(')
          ..write('id: $id, ')
          ..write('localId: $localId, ')
          ..write('userId: $userId, ')
          ..write('serverId: $serverId, ')
          ..write('code: $code, ')
          ..write('customLabel: $customLabel, ')
          ..write('note: $note, ')
          ..write('isActive: $isActive, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localId,
    userId,
    serverId,
    code,
    customLabel,
    note,
    isActive,
    isDeleted,
    syncState,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalCondition &&
          other.id == this.id &&
          other.localId == this.localId &&
          other.userId == this.userId &&
          other.serverId == this.serverId &&
          other.code == this.code &&
          other.customLabel == this.customLabel &&
          other.note == this.note &&
          other.isActive == this.isActive &&
          other.isDeleted == this.isDeleted &&
          other.syncState == this.syncState &&
          other.updatedAt == this.updatedAt);
}

class LocalConditionsCompanion extends UpdateCompanion<LocalCondition> {
  final Value<int> id;
  final Value<String> localId;
  final Value<String> userId;
  final Value<int?> serverId;
  final Value<String> code;
  final Value<String?> customLabel;
  final Value<String?> note;
  final Value<bool> isActive;
  final Value<bool> isDeleted;
  final Value<SyncState> syncState;
  final Value<DateTime> updatedAt;
  const LocalConditionsCompanion({
    this.id = const Value.absent(),
    this.localId = const Value.absent(),
    this.userId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.code = const Value.absent(),
    this.customLabel = const Value.absent(),
    this.note = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalConditionsCompanion.insert({
    this.id = const Value.absent(),
    required String localId,
    required String userId,
    this.serverId = const Value.absent(),
    required String code,
    this.customLabel = const Value.absent(),
    this.note = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : localId = Value(localId),
       userId = Value(userId),
       code = Value(code);
  static Insertable<LocalCondition> custom({
    Expression<int>? id,
    Expression<String>? localId,
    Expression<String>? userId,
    Expression<int>? serverId,
    Expression<String>? code,
    Expression<String>? customLabel,
    Expression<String>? note,
    Expression<bool>? isActive,
    Expression<bool>? isDeleted,
    Expression<int>? syncState,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localId != null) 'local_id': localId,
      if (userId != null) 'user_id': userId,
      if (serverId != null) 'server_id': serverId,
      if (code != null) 'code': code,
      if (customLabel != null) 'custom_label': customLabel,
      if (note != null) 'note': note,
      if (isActive != null) 'is_active': isActive,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncState != null) 'sync_state': syncState,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalConditionsCompanion copyWith({
    Value<int>? id,
    Value<String>? localId,
    Value<String>? userId,
    Value<int?>? serverId,
    Value<String>? code,
    Value<String?>? customLabel,
    Value<String?>? note,
    Value<bool>? isActive,
    Value<bool>? isDeleted,
    Value<SyncState>? syncState,
    Value<DateTime>? updatedAt,
  }) {
    return LocalConditionsCompanion(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      userId: userId ?? this.userId,
      serverId: serverId ?? this.serverId,
      code: code ?? this.code,
      customLabel: customLabel ?? this.customLabel,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      syncState: syncState ?? this.syncState,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (customLabel.present) {
      map['custom_label'] = Variable<String>(customLabel.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<int>(
        $LocalConditionsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalConditionsCompanion(')
          ..write('id: $id, ')
          ..write('localId: $localId, ')
          ..write('userId: $userId, ')
          ..write('serverId: $serverId, ')
          ..write('code: $code, ')
          ..write('customLabel: $customLabel, ')
          ..write('note: $note, ')
          ..write('isActive: $isActive, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalMedicationsTable extends LocalMedications
    with TableInfo<$LocalMedicationsTable, LocalMedication> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMedicationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
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
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, int> syncState =
      GeneratedColumn<int>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: Constant(SyncState.synced.index),
      ).withConverter<SyncState>($LocalMedicationsTable.$convertersyncState);
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localId,
    userId,
    serverId,
    name,
    note,
    isActive,
    isDeleted,
    syncState,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_medications';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMedication> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
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
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMedication map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMedication(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      syncState: $LocalMedicationsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalMedicationsTable createAlias(String alias) {
    return $LocalMedicationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, int, int> $convertersyncState =
      const EnumIndexConverter<SyncState>(SyncState.values);
}

class LocalMedication extends DataClass implements Insertable<LocalMedication> {
  final int id;
  final String localId;
  final String userId;
  final int? serverId;
  final String name;
  final String? note;
  final bool isActive;
  final bool isDeleted;
  final SyncState syncState;
  final DateTime updatedAt;
  const LocalMedication({
    required this.id,
    required this.localId,
    required this.userId,
    this.serverId,
    required this.name,
    this.note,
    required this.isActive,
    required this.isDeleted,
    required this.syncState,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['local_id'] = Variable<String>(localId);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['is_deleted'] = Variable<bool>(isDeleted);
    {
      map['sync_state'] = Variable<int>(
        $LocalMedicationsTable.$convertersyncState.toSql(syncState),
      );
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalMedicationsCompanion toCompanion(bool nullToAbsent) {
    return LocalMedicationsCompanion(
      id: Value(id),
      localId: Value(localId),
      userId: Value(userId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      name: Value(name),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      isActive: Value(isActive),
      isDeleted: Value(isDeleted),
      syncState: Value(syncState),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalMedication.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMedication(
      id: serializer.fromJson<int>(json['id']),
      localId: serializer.fromJson<String>(json['localId']),
      userId: serializer.fromJson<String>(json['userId']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      name: serializer.fromJson<String>(json['name']),
      note: serializer.fromJson<String?>(json['note']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      syncState: $LocalMedicationsTable.$convertersyncState.fromJson(
        serializer.fromJson<int>(json['syncState']),
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'localId': serializer.toJson<String>(localId),
      'userId': serializer.toJson<String>(userId),
      'serverId': serializer.toJson<int?>(serverId),
      'name': serializer.toJson<String>(name),
      'note': serializer.toJson<String?>(note),
      'isActive': serializer.toJson<bool>(isActive),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'syncState': serializer.toJson<int>(
        $LocalMedicationsTable.$convertersyncState.toJson(syncState),
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalMedication copyWith({
    int? id,
    String? localId,
    String? userId,
    Value<int?> serverId = const Value.absent(),
    String? name,
    Value<String?> note = const Value.absent(),
    bool? isActive,
    bool? isDeleted,
    SyncState? syncState,
    DateTime? updatedAt,
  }) => LocalMedication(
    id: id ?? this.id,
    localId: localId ?? this.localId,
    userId: userId ?? this.userId,
    serverId: serverId.present ? serverId.value : this.serverId,
    name: name ?? this.name,
    note: note.present ? note.value : this.note,
    isActive: isActive ?? this.isActive,
    isDeleted: isDeleted ?? this.isDeleted,
    syncState: syncState ?? this.syncState,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalMedication copyWithCompanion(LocalMedicationsCompanion data) {
    return LocalMedication(
      id: data.id.present ? data.id.value : this.id,
      localId: data.localId.present ? data.localId.value : this.localId,
      userId: data.userId.present ? data.userId.value : this.userId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      name: data.name.present ? data.name.value : this.name,
      note: data.note.present ? data.note.value : this.note,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMedication(')
          ..write('id: $id, ')
          ..write('localId: $localId, ')
          ..write('userId: $userId, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('isActive: $isActive, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localId,
    userId,
    serverId,
    name,
    note,
    isActive,
    isDeleted,
    syncState,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMedication &&
          other.id == this.id &&
          other.localId == this.localId &&
          other.userId == this.userId &&
          other.serverId == this.serverId &&
          other.name == this.name &&
          other.note == this.note &&
          other.isActive == this.isActive &&
          other.isDeleted == this.isDeleted &&
          other.syncState == this.syncState &&
          other.updatedAt == this.updatedAt);
}

class LocalMedicationsCompanion extends UpdateCompanion<LocalMedication> {
  final Value<int> id;
  final Value<String> localId;
  final Value<String> userId;
  final Value<int?> serverId;
  final Value<String> name;
  final Value<String?> note;
  final Value<bool> isActive;
  final Value<bool> isDeleted;
  final Value<SyncState> syncState;
  final Value<DateTime> updatedAt;
  const LocalMedicationsCompanion({
    this.id = const Value.absent(),
    this.localId = const Value.absent(),
    this.userId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.name = const Value.absent(),
    this.note = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalMedicationsCompanion.insert({
    this.id = const Value.absent(),
    required String localId,
    required String userId,
    this.serverId = const Value.absent(),
    required String name,
    this.note = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : localId = Value(localId),
       userId = Value(userId),
       name = Value(name);
  static Insertable<LocalMedication> custom({
    Expression<int>? id,
    Expression<String>? localId,
    Expression<String>? userId,
    Expression<int>? serverId,
    Expression<String>? name,
    Expression<String>? note,
    Expression<bool>? isActive,
    Expression<bool>? isDeleted,
    Expression<int>? syncState,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localId != null) 'local_id': localId,
      if (userId != null) 'user_id': userId,
      if (serverId != null) 'server_id': serverId,
      if (name != null) 'name': name,
      if (note != null) 'note': note,
      if (isActive != null) 'is_active': isActive,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncState != null) 'sync_state': syncState,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalMedicationsCompanion copyWith({
    Value<int>? id,
    Value<String>? localId,
    Value<String>? userId,
    Value<int?>? serverId,
    Value<String>? name,
    Value<String?>? note,
    Value<bool>? isActive,
    Value<bool>? isDeleted,
    Value<SyncState>? syncState,
    Value<DateTime>? updatedAt,
  }) {
    return LocalMedicationsCompanion(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      userId: userId ?? this.userId,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      syncState: syncState ?? this.syncState,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<int>(
        $LocalMedicationsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMedicationsCompanion(')
          ..write('id: $id, ')
          ..write('localId: $localId, ')
          ..write('userId: $userId, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('isActive: $isActive, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalProfilesTable localProfiles = $LocalProfilesTable(this);
  late final $LocalCyclesTable localCycles = $LocalCyclesTable(this);
  late final $LocalDailyLogsTable localDailyLogs = $LocalDailyLogsTable(this);
  late final $LocalSymptomsTable localSymptoms = $LocalSymptomsTable(this);
  late final $PredictionCacheTable predictionCache = $PredictionCacheTable(
    this,
  );
  late final $LocalHealthContextTable localHealthContext =
      $LocalHealthContextTable(this);
  late final $LocalConditionsTable localConditions = $LocalConditionsTable(
    this,
  );
  late final $LocalMedicationsTable localMedications = $LocalMedicationsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localProfiles,
    localCycles,
    localDailyLogs,
    localSymptoms,
    predictionCache,
    localHealthContext,
    localConditions,
    localMedications,
  ];
}

typedef $$LocalProfilesTableCreateCompanionBuilder =
    LocalProfilesCompanion Function({
      required String userId,
      Value<String?> name,
      Value<int?> usualCycleDays,
      Value<int?> usualPeriodDays,
      Value<String?> theme,
      Value<String?> units,
      Value<String?> timezone,
      Value<int?> birthYear,
      Value<int?> birthMonth,
      Value<SyncState> syncState,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalProfilesTableUpdateCompanionBuilder =
    LocalProfilesCompanion Function({
      Value<String> userId,
      Value<String?> name,
      Value<int?> usualCycleDays,
      Value<int?> usualPeriodDays,
      Value<String?> theme,
      Value<String?> units,
      Value<String?> timezone,
      Value<int?> birthYear,
      Value<int?> birthMonth,
      Value<SyncState> syncState,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalProfilesTable> {
  $$LocalProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usualCycleDays => $composableBuilder(
    column: $table.usualCycleDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usualPeriodDays => $composableBuilder(
    column: $table.usualPeriodDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get units => $composableBuilder(
    column: $table.units,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get birthYear => $composableBuilder(
    column: $table.birthYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get birthMonth => $composableBuilder(
    column: $table.birthMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, int> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalProfilesTable> {
  $$LocalProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usualCycleDays => $composableBuilder(
    column: $table.usualCycleDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usualPeriodDays => $composableBuilder(
    column: $table.usualPeriodDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get theme => $composableBuilder(
    column: $table.theme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get units => $composableBuilder(
    column: $table.units,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get birthYear => $composableBuilder(
    column: $table.birthYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get birthMonth => $composableBuilder(
    column: $table.birthMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalProfilesTable> {
  $$LocalProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get usualCycleDays => $composableBuilder(
    column: $table.usualCycleDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get usualPeriodDays => $composableBuilder(
    column: $table.usualPeriodDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get theme =>
      $composableBuilder(column: $table.theme, builder: (column) => column);

  GeneratedColumn<String> get units =>
      $composableBuilder(column: $table.units, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<int> get birthYear =>
      $composableBuilder(column: $table.birthYear, builder: (column) => column);

  GeneratedColumn<int> get birthMonth => $composableBuilder(
    column: $table.birthMonth,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SyncState, int> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalProfilesTable,
          LocalProfile,
          $$LocalProfilesTableFilterComposer,
          $$LocalProfilesTableOrderingComposer,
          $$LocalProfilesTableAnnotationComposer,
          $$LocalProfilesTableCreateCompanionBuilder,
          $$LocalProfilesTableUpdateCompanionBuilder,
          (
            LocalProfile,
            BaseReferences<_$AppDatabase, $LocalProfilesTable, LocalProfile>,
          ),
          LocalProfile,
          PrefetchHooks Function()
        > {
  $$LocalProfilesTableTableManager(_$AppDatabase db, $LocalProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<int?> usualCycleDays = const Value.absent(),
                Value<int?> usualPeriodDays = const Value.absent(),
                Value<String?> theme = const Value.absent(),
                Value<String?> units = const Value.absent(),
                Value<String?> timezone = const Value.absent(),
                Value<int?> birthYear = const Value.absent(),
                Value<int?> birthMonth = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProfilesCompanion(
                userId: userId,
                name: name,
                usualCycleDays: usualCycleDays,
                usualPeriodDays: usualPeriodDays,
                theme: theme,
                units: units,
                timezone: timezone,
                birthYear: birthYear,
                birthMonth: birthMonth,
                syncState: syncState,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<String?> name = const Value.absent(),
                Value<int?> usualCycleDays = const Value.absent(),
                Value<int?> usualPeriodDays = const Value.absent(),
                Value<String?> theme = const Value.absent(),
                Value<String?> units = const Value.absent(),
                Value<String?> timezone = const Value.absent(),
                Value<int?> birthYear = const Value.absent(),
                Value<int?> birthMonth = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProfilesCompanion.insert(
                userId: userId,
                name: name,
                usualCycleDays: usualCycleDays,
                usualPeriodDays: usualPeriodDays,
                theme: theme,
                units: units,
                timezone: timezone,
                birthYear: birthYear,
                birthMonth: birthMonth,
                syncState: syncState,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalProfilesTable, LocalProfile>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalProfilesTable,
                    LocalProfile
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalProfilesTable,
      LocalProfile,
      $$LocalProfilesTableFilterComposer,
      $$LocalProfilesTableOrderingComposer,
      $$LocalProfilesTableAnnotationComposer,
      $$LocalProfilesTableCreateCompanionBuilder,
      $$LocalProfilesTableUpdateCompanionBuilder,
      (
        LocalProfile,
        BaseReferences<_$AppDatabase, $LocalProfilesTable, LocalProfile>,
      ),
      LocalProfile,
      PrefetchHooks Function()
    >;
typedef $$LocalCyclesTableCreateCompanionBuilder =
    LocalCyclesCompanion Function({
      Value<int> id,
      required String localId,
      required String userId,
      Value<int?> serverId,
      required String periodStart,
      Value<String?> periodEnd,
      Value<SyncState> syncState,
      Value<DateTime> updatedAt,
    });
typedef $$LocalCyclesTableUpdateCompanionBuilder =
    LocalCyclesCompanion Function({
      Value<int> id,
      Value<String> localId,
      Value<String> userId,
      Value<int?> serverId,
      Value<String> periodStart,
      Value<String?> periodEnd,
      Value<SyncState> syncState,
      Value<DateTime> updatedAt,
    });

class $$LocalCyclesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalCyclesTable> {
  $$LocalCyclesTableFilterComposer({
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

  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodEnd => $composableBuilder(
    column: $table.periodEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, int> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalCyclesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalCyclesTable> {
  $$LocalCyclesTableOrderingComposer({
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

  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodEnd => $composableBuilder(
    column: $table.periodEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalCyclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalCyclesTable> {
  $$LocalCyclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get periodStart => $composableBuilder(
    column: $table.periodStart,
    builder: (column) => column,
  );

  GeneratedColumn<String> get periodEnd =>
      $composableBuilder(column: $table.periodEnd, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, int> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalCyclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalCyclesTable,
          LocalCycle,
          $$LocalCyclesTableFilterComposer,
          $$LocalCyclesTableOrderingComposer,
          $$LocalCyclesTableAnnotationComposer,
          $$LocalCyclesTableCreateCompanionBuilder,
          $$LocalCyclesTableUpdateCompanionBuilder,
          (
            LocalCycle,
            BaseReferences<_$AppDatabase, $LocalCyclesTable, LocalCycle>,
          ),
          LocalCycle,
          PrefetchHooks Function()
        > {
  $$LocalCyclesTableTableManager(_$AppDatabase db, $LocalCyclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalCyclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalCyclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalCyclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> localId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> periodStart = const Value.absent(),
                Value<String?> periodEnd = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalCyclesCompanion(
                id: id,
                localId: localId,
                userId: userId,
                serverId: serverId,
                periodStart: periodStart,
                periodEnd: periodEnd,
                syncState: syncState,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String localId,
                required String userId,
                Value<int?> serverId = const Value.absent(),
                required String periodStart,
                Value<String?> periodEnd = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalCyclesCompanion.insert(
                id: id,
                localId: localId,
                userId: userId,
                serverId: serverId,
                periodStart: periodStart,
                periodEnd: periodEnd,
                syncState: syncState,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalCyclesTable, LocalCycle>(table),
                  BaseReferences<_$AppDatabase, $LocalCyclesTable, LocalCycle>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalCyclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalCyclesTable,
      LocalCycle,
      $$LocalCyclesTableFilterComposer,
      $$LocalCyclesTableOrderingComposer,
      $$LocalCyclesTableAnnotationComposer,
      $$LocalCyclesTableCreateCompanionBuilder,
      $$LocalCyclesTableUpdateCompanionBuilder,
      (
        LocalCycle,
        BaseReferences<_$AppDatabase, $LocalCyclesTable, LocalCycle>,
      ),
      LocalCycle,
      PrefetchHooks Function()
    >;
typedef $$LocalDailyLogsTableCreateCompanionBuilder =
    LocalDailyLogsCompanion Function({
      Value<int> id,
      required String userId,
      required String logDate,
      Value<int?> pain,
      Value<String?> mood,
      Value<String?> flow,
      Value<String?> discharge,
      Value<String?> notes,
      Value<SyncState> syncState,
      Value<DateTime> updatedAt,
    });
typedef $$LocalDailyLogsTableUpdateCompanionBuilder =
    LocalDailyLogsCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> logDate,
      Value<int?> pain,
      Value<String?> mood,
      Value<String?> flow,
      Value<String?> discharge,
      Value<String?> notes,
      Value<SyncState> syncState,
      Value<DateTime> updatedAt,
    });

class $$LocalDailyLogsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalDailyLogsTable> {
  $$LocalDailyLogsTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logDate => $composableBuilder(
    column: $table.logDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pain => $composableBuilder(
    column: $table.pain,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flow => $composableBuilder(
    column: $table.flow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get discharge => $composableBuilder(
    column: $table.discharge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, int> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalDailyLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalDailyLogsTable> {
  $$LocalDailyLogsTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logDate => $composableBuilder(
    column: $table.logDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pain => $composableBuilder(
    column: $table.pain,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flow => $composableBuilder(
    column: $table.flow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get discharge => $composableBuilder(
    column: $table.discharge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalDailyLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalDailyLogsTable> {
  $$LocalDailyLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get logDate =>
      $composableBuilder(column: $table.logDate, builder: (column) => column);

  GeneratedColumn<int> get pain =>
      $composableBuilder(column: $table.pain, builder: (column) => column);

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<String> get flow =>
      $composableBuilder(column: $table.flow, builder: (column) => column);

  GeneratedColumn<String> get discharge =>
      $composableBuilder(column: $table.discharge, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, int> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalDailyLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalDailyLogsTable,
          LocalDailyLog,
          $$LocalDailyLogsTableFilterComposer,
          $$LocalDailyLogsTableOrderingComposer,
          $$LocalDailyLogsTableAnnotationComposer,
          $$LocalDailyLogsTableCreateCompanionBuilder,
          $$LocalDailyLogsTableUpdateCompanionBuilder,
          (
            LocalDailyLog,
            BaseReferences<_$AppDatabase, $LocalDailyLogsTable, LocalDailyLog>,
          ),
          LocalDailyLog,
          PrefetchHooks Function()
        > {
  $$LocalDailyLogsTableTableManager(
    _$AppDatabase db,
    $LocalDailyLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDailyLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDailyLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDailyLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> logDate = const Value.absent(),
                Value<int?> pain = const Value.absent(),
                Value<String?> mood = const Value.absent(),
                Value<String?> flow = const Value.absent(),
                Value<String?> discharge = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalDailyLogsCompanion(
                id: id,
                userId: userId,
                logDate: logDate,
                pain: pain,
                mood: mood,
                flow: flow,
                discharge: discharge,
                notes: notes,
                syncState: syncState,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String logDate,
                Value<int?> pain = const Value.absent(),
                Value<String?> mood = const Value.absent(),
                Value<String?> flow = const Value.absent(),
                Value<String?> discharge = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalDailyLogsCompanion.insert(
                id: id,
                userId: userId,
                logDate: logDate,
                pain: pain,
                mood: mood,
                flow: flow,
                discharge: discharge,
                notes: notes,
                syncState: syncState,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalDailyLogsTable, LocalDailyLog>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalDailyLogsTable,
                    LocalDailyLog
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalDailyLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalDailyLogsTable,
      LocalDailyLog,
      $$LocalDailyLogsTableFilterComposer,
      $$LocalDailyLogsTableOrderingComposer,
      $$LocalDailyLogsTableAnnotationComposer,
      $$LocalDailyLogsTableCreateCompanionBuilder,
      $$LocalDailyLogsTableUpdateCompanionBuilder,
      (
        LocalDailyLog,
        BaseReferences<_$AppDatabase, $LocalDailyLogsTable, LocalDailyLog>,
      ),
      LocalDailyLog,
      PrefetchHooks Function()
    >;
typedef $$LocalSymptomsTableCreateCompanionBuilder =
    LocalSymptomsCompanion Function({
      Value<int> id,
      required String userId,
      required String logDate,
      required String symptomType,
      Value<int> severity,
    });
typedef $$LocalSymptomsTableUpdateCompanionBuilder =
    LocalSymptomsCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> logDate,
      Value<String> symptomType,
      Value<int> severity,
    });

class $$LocalSymptomsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSymptomsTable> {
  $$LocalSymptomsTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logDate => $composableBuilder(
    column: $table.logDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get symptomType => $composableBuilder(
    column: $table.symptomType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSymptomsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSymptomsTable> {
  $$LocalSymptomsTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logDate => $composableBuilder(
    column: $table.logDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symptomType => $composableBuilder(
    column: $table.symptomType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSymptomsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSymptomsTable> {
  $$LocalSymptomsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get logDate =>
      $composableBuilder(column: $table.logDate, builder: (column) => column);

  GeneratedColumn<String> get symptomType => $composableBuilder(
    column: $table.symptomType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);
}

class $$LocalSymptomsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSymptomsTable,
          LocalSymptom,
          $$LocalSymptomsTableFilterComposer,
          $$LocalSymptomsTableOrderingComposer,
          $$LocalSymptomsTableAnnotationComposer,
          $$LocalSymptomsTableCreateCompanionBuilder,
          $$LocalSymptomsTableUpdateCompanionBuilder,
          (
            LocalSymptom,
            BaseReferences<_$AppDatabase, $LocalSymptomsTable, LocalSymptom>,
          ),
          LocalSymptom,
          PrefetchHooks Function()
        > {
  $$LocalSymptomsTableTableManager(_$AppDatabase db, $LocalSymptomsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSymptomsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSymptomsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSymptomsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> logDate = const Value.absent(),
                Value<String> symptomType = const Value.absent(),
                Value<int> severity = const Value.absent(),
              }) => LocalSymptomsCompanion(
                id: id,
                userId: userId,
                logDate: logDate,
                symptomType: symptomType,
                severity: severity,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String logDate,
                required String symptomType,
                Value<int> severity = const Value.absent(),
              }) => LocalSymptomsCompanion.insert(
                id: id,
                userId: userId,
                logDate: logDate,
                symptomType: symptomType,
                severity: severity,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSymptomsTable, LocalSymptom>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalSymptomsTable,
                    LocalSymptom
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSymptomsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSymptomsTable,
      LocalSymptom,
      $$LocalSymptomsTableFilterComposer,
      $$LocalSymptomsTableOrderingComposer,
      $$LocalSymptomsTableAnnotationComposer,
      $$LocalSymptomsTableCreateCompanionBuilder,
      $$LocalSymptomsTableUpdateCompanionBuilder,
      (
        LocalSymptom,
        BaseReferences<_$AppDatabase, $LocalSymptomsTable, LocalSymptom>,
      ),
      LocalSymptom,
      PrefetchHooks Function()
    >;
typedef $$PredictionCacheTableCreateCompanionBuilder =
    PredictionCacheCompanion Function({
      required String userId,
      Value<String?> phase,
      Value<String?> predictedNextPeriod,
      Value<int?> daysUntilNextPeriod,
      Value<String?> predictionStatus,
      Value<String?> predictionConfidence,
      Value<double?> averageCycleLength,
      Value<double?> averagePeriodLength,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });
typedef $$PredictionCacheTableUpdateCompanionBuilder =
    PredictionCacheCompanion Function({
      Value<String> userId,
      Value<String?> phase,
      Value<String?> predictedNextPeriod,
      Value<int?> daysUntilNextPeriod,
      Value<String?> predictionStatus,
      Value<String?> predictionConfidence,
      Value<double?> averageCycleLength,
      Value<double?> averagePeriodLength,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$PredictionCacheTableFilterComposer
    extends Composer<_$AppDatabase, $PredictionCacheTable> {
  $$PredictionCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get predictedNextPeriod => $composableBuilder(
    column: $table.predictedNextPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get daysUntilNextPeriod => $composableBuilder(
    column: $table.daysUntilNextPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get predictionStatus => $composableBuilder(
    column: $table.predictionStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get predictionConfidence => $composableBuilder(
    column: $table.predictionConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averageCycleLength => $composableBuilder(
    column: $table.averageCycleLength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get averagePeriodLength => $composableBuilder(
    column: $table.averagePeriodLength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PredictionCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $PredictionCacheTable> {
  $$PredictionCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phase => $composableBuilder(
    column: $table.phase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get predictedNextPeriod => $composableBuilder(
    column: $table.predictedNextPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get daysUntilNextPeriod => $composableBuilder(
    column: $table.daysUntilNextPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get predictionStatus => $composableBuilder(
    column: $table.predictionStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get predictionConfidence => $composableBuilder(
    column: $table.predictionConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averageCycleLength => $composableBuilder(
    column: $table.averageCycleLength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get averagePeriodLength => $composableBuilder(
    column: $table.averagePeriodLength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PredictionCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $PredictionCacheTable> {
  $$PredictionCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get phase =>
      $composableBuilder(column: $table.phase, builder: (column) => column);

  GeneratedColumn<String> get predictedNextPeriod => $composableBuilder(
    column: $table.predictedNextPeriod,
    builder: (column) => column,
  );

  GeneratedColumn<int> get daysUntilNextPeriod => $composableBuilder(
    column: $table.daysUntilNextPeriod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get predictionStatus => $composableBuilder(
    column: $table.predictionStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get predictionConfidence => $composableBuilder(
    column: $table.predictionConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<double> get averageCycleLength => $composableBuilder(
    column: $table.averageCycleLength,
    builder: (column) => column,
  );

  GeneratedColumn<double> get averagePeriodLength => $composableBuilder(
    column: $table.averagePeriodLength,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$PredictionCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PredictionCacheTable,
          PredictionCacheData,
          $$PredictionCacheTableFilterComposer,
          $$PredictionCacheTableOrderingComposer,
          $$PredictionCacheTableAnnotationComposer,
          $$PredictionCacheTableCreateCompanionBuilder,
          $$PredictionCacheTableUpdateCompanionBuilder,
          (
            PredictionCacheData,
            BaseReferences<
              _$AppDatabase,
              $PredictionCacheTable,
              PredictionCacheData
            >,
          ),
          PredictionCacheData,
          PrefetchHooks Function()
        > {
  $$PredictionCacheTableTableManager(
    _$AppDatabase db,
    $PredictionCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PredictionCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PredictionCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PredictionCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String?> phase = const Value.absent(),
                Value<String?> predictedNextPeriod = const Value.absent(),
                Value<int?> daysUntilNextPeriod = const Value.absent(),
                Value<String?> predictionStatus = const Value.absent(),
                Value<String?> predictionConfidence = const Value.absent(),
                Value<double?> averageCycleLength = const Value.absent(),
                Value<double?> averagePeriodLength = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PredictionCacheCompanion(
                userId: userId,
                phase: phase,
                predictedNextPeriod: predictedNextPeriod,
                daysUntilNextPeriod: daysUntilNextPeriod,
                predictionStatus: predictionStatus,
                predictionConfidence: predictionConfidence,
                averageCycleLength: averageCycleLength,
                averagePeriodLength: averagePeriodLength,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<String?> phase = const Value.absent(),
                Value<String?> predictedNextPeriod = const Value.absent(),
                Value<int?> daysUntilNextPeriod = const Value.absent(),
                Value<String?> predictionStatus = const Value.absent(),
                Value<String?> predictionConfidence = const Value.absent(),
                Value<double?> averageCycleLength = const Value.absent(),
                Value<double?> averagePeriodLength = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PredictionCacheCompanion.insert(
                userId: userId,
                phase: phase,
                predictedNextPeriod: predictedNextPeriod,
                daysUntilNextPeriod: daysUntilNextPeriod,
                predictionStatus: predictionStatus,
                predictionConfidence: predictionConfidence,
                averageCycleLength: averageCycleLength,
                averagePeriodLength: averagePeriodLength,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PredictionCacheTable, PredictionCacheData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $PredictionCacheTable,
                    PredictionCacheData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PredictionCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PredictionCacheTable,
      PredictionCacheData,
      $$PredictionCacheTableFilterComposer,
      $$PredictionCacheTableOrderingComposer,
      $$PredictionCacheTableAnnotationComposer,
      $$PredictionCacheTableCreateCompanionBuilder,
      $$PredictionCacheTableUpdateCompanionBuilder,
      (
        PredictionCacheData,
        BaseReferences<
          _$AppDatabase,
          $PredictionCacheTable,
          PredictionCacheData
        >,
      ),
      PredictionCacheData,
      PrefetchHooks Function()
    >;
typedef $$LocalHealthContextTableCreateCompanionBuilder =
    LocalHealthContextCompanion Function({
      required String userId,
      Value<String?> contraceptionMethod,
      Value<String?> contraceptionNote,
      Value<String?> pregnancyContext,
      Value<String?> healthNotes,
      Value<SyncState> syncState,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalHealthContextTableUpdateCompanionBuilder =
    LocalHealthContextCompanion Function({
      Value<String> userId,
      Value<String?> contraceptionMethod,
      Value<String?> contraceptionNote,
      Value<String?> pregnancyContext,
      Value<String?> healthNotes,
      Value<SyncState> syncState,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalHealthContextTableFilterComposer
    extends Composer<_$AppDatabase, $LocalHealthContextTable> {
  $$LocalHealthContextTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contraceptionMethod => $composableBuilder(
    column: $table.contraceptionMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contraceptionNote => $composableBuilder(
    column: $table.contraceptionNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pregnancyContext => $composableBuilder(
    column: $table.pregnancyContext,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get healthNotes => $composableBuilder(
    column: $table.healthNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, int> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalHealthContextTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalHealthContextTable> {
  $$LocalHealthContextTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contraceptionMethod => $composableBuilder(
    column: $table.contraceptionMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contraceptionNote => $composableBuilder(
    column: $table.contraceptionNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pregnancyContext => $composableBuilder(
    column: $table.pregnancyContext,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get healthNotes => $composableBuilder(
    column: $table.healthNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalHealthContextTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalHealthContextTable> {
  $$LocalHealthContextTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get contraceptionMethod => $composableBuilder(
    column: $table.contraceptionMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contraceptionNote => $composableBuilder(
    column: $table.contraceptionNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pregnancyContext => $composableBuilder(
    column: $table.pregnancyContext,
    builder: (column) => column,
  );

  GeneratedColumn<String> get healthNotes => $composableBuilder(
    column: $table.healthNotes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SyncState, int> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalHealthContextTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalHealthContextTable,
          LocalHealthContextData,
          $$LocalHealthContextTableFilterComposer,
          $$LocalHealthContextTableOrderingComposer,
          $$LocalHealthContextTableAnnotationComposer,
          $$LocalHealthContextTableCreateCompanionBuilder,
          $$LocalHealthContextTableUpdateCompanionBuilder,
          (
            LocalHealthContextData,
            BaseReferences<
              _$AppDatabase,
              $LocalHealthContextTable,
              LocalHealthContextData
            >,
          ),
          LocalHealthContextData,
          PrefetchHooks Function()
        > {
  $$LocalHealthContextTableTableManager(
    _$AppDatabase db,
    $LocalHealthContextTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalHealthContextTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalHealthContextTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalHealthContextTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String?> contraceptionMethod = const Value.absent(),
                Value<String?> contraceptionNote = const Value.absent(),
                Value<String?> pregnancyContext = const Value.absent(),
                Value<String?> healthNotes = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalHealthContextCompanion(
                userId: userId,
                contraceptionMethod: contraceptionMethod,
                contraceptionNote: contraceptionNote,
                pregnancyContext: pregnancyContext,
                healthNotes: healthNotes,
                syncState: syncState,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<String?> contraceptionMethod = const Value.absent(),
                Value<String?> contraceptionNote = const Value.absent(),
                Value<String?> pregnancyContext = const Value.absent(),
                Value<String?> healthNotes = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalHealthContextCompanion.insert(
                userId: userId,
                contraceptionMethod: contraceptionMethod,
                contraceptionNote: contraceptionNote,
                pregnancyContext: pregnancyContext,
                healthNotes: healthNotes,
                syncState: syncState,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalHealthContextTable, LocalHealthContextData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalHealthContextTable,
                    LocalHealthContextData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalHealthContextTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalHealthContextTable,
      LocalHealthContextData,
      $$LocalHealthContextTableFilterComposer,
      $$LocalHealthContextTableOrderingComposer,
      $$LocalHealthContextTableAnnotationComposer,
      $$LocalHealthContextTableCreateCompanionBuilder,
      $$LocalHealthContextTableUpdateCompanionBuilder,
      (
        LocalHealthContextData,
        BaseReferences<
          _$AppDatabase,
          $LocalHealthContextTable,
          LocalHealthContextData
        >,
      ),
      LocalHealthContextData,
      PrefetchHooks Function()
    >;
typedef $$LocalConditionsTableCreateCompanionBuilder =
    LocalConditionsCompanion Function({
      Value<int> id,
      required String localId,
      required String userId,
      Value<int?> serverId,
      required String code,
      Value<String?> customLabel,
      Value<String?> note,
      Value<bool> isActive,
      Value<bool> isDeleted,
      Value<SyncState> syncState,
      Value<DateTime> updatedAt,
    });
typedef $$LocalConditionsTableUpdateCompanionBuilder =
    LocalConditionsCompanion Function({
      Value<int> id,
      Value<String> localId,
      Value<String> userId,
      Value<int?> serverId,
      Value<String> code,
      Value<String?> customLabel,
      Value<String?> note,
      Value<bool> isActive,
      Value<bool> isDeleted,
      Value<SyncState> syncState,
      Value<DateTime> updatedAt,
    });

class $$LocalConditionsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalConditionsTable> {
  $$LocalConditionsTableFilterComposer({
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

  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customLabel => $composableBuilder(
    column: $table.customLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, int> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalConditionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalConditionsTable> {
  $$LocalConditionsTableOrderingComposer({
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

  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customLabel => $composableBuilder(
    column: $table.customLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalConditionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalConditionsTable> {
  $$LocalConditionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get customLabel => $composableBuilder(
    column: $table.customLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, int> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalConditionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalConditionsTable,
          LocalCondition,
          $$LocalConditionsTableFilterComposer,
          $$LocalConditionsTableOrderingComposer,
          $$LocalConditionsTableAnnotationComposer,
          $$LocalConditionsTableCreateCompanionBuilder,
          $$LocalConditionsTableUpdateCompanionBuilder,
          (
            LocalCondition,
            BaseReferences<
              _$AppDatabase,
              $LocalConditionsTable,
              LocalCondition
            >,
          ),
          LocalCondition,
          PrefetchHooks Function()
        > {
  $$LocalConditionsTableTableManager(
    _$AppDatabase db,
    $LocalConditionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalConditionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalConditionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalConditionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> localId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String?> customLabel = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalConditionsCompanion(
                id: id,
                localId: localId,
                userId: userId,
                serverId: serverId,
                code: code,
                customLabel: customLabel,
                note: note,
                isActive: isActive,
                isDeleted: isDeleted,
                syncState: syncState,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String localId,
                required String userId,
                Value<int?> serverId = const Value.absent(),
                required String code,
                Value<String?> customLabel = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalConditionsCompanion.insert(
                id: id,
                localId: localId,
                userId: userId,
                serverId: serverId,
                code: code,
                customLabel: customLabel,
                note: note,
                isActive: isActive,
                isDeleted: isDeleted,
                syncState: syncState,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalConditionsTable, LocalCondition>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalConditionsTable,
                    LocalCondition
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalConditionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalConditionsTable,
      LocalCondition,
      $$LocalConditionsTableFilterComposer,
      $$LocalConditionsTableOrderingComposer,
      $$LocalConditionsTableAnnotationComposer,
      $$LocalConditionsTableCreateCompanionBuilder,
      $$LocalConditionsTableUpdateCompanionBuilder,
      (
        LocalCondition,
        BaseReferences<_$AppDatabase, $LocalConditionsTable, LocalCondition>,
      ),
      LocalCondition,
      PrefetchHooks Function()
    >;
typedef $$LocalMedicationsTableCreateCompanionBuilder =
    LocalMedicationsCompanion Function({
      Value<int> id,
      required String localId,
      required String userId,
      Value<int?> serverId,
      required String name,
      Value<String?> note,
      Value<bool> isActive,
      Value<bool> isDeleted,
      Value<SyncState> syncState,
      Value<DateTime> updatedAt,
    });
typedef $$LocalMedicationsTableUpdateCompanionBuilder =
    LocalMedicationsCompanion Function({
      Value<int> id,
      Value<String> localId,
      Value<String> userId,
      Value<int?> serverId,
      Value<String> name,
      Value<String?> note,
      Value<bool> isActive,
      Value<bool> isDeleted,
      Value<SyncState> syncState,
      Value<DateTime> updatedAt,
    });

class $$LocalMedicationsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMedicationsTable> {
  $$LocalMedicationsTableFilterComposer({
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

  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, int> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMedicationsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMedicationsTable> {
  $$LocalMedicationsTableOrderingComposer({
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

  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMedicationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMedicationsTable> {
  $$LocalMedicationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, int> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalMedicationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMedicationsTable,
          LocalMedication,
          $$LocalMedicationsTableFilterComposer,
          $$LocalMedicationsTableOrderingComposer,
          $$LocalMedicationsTableAnnotationComposer,
          $$LocalMedicationsTableCreateCompanionBuilder,
          $$LocalMedicationsTableUpdateCompanionBuilder,
          (
            LocalMedication,
            BaseReferences<
              _$AppDatabase,
              $LocalMedicationsTable,
              LocalMedication
            >,
          ),
          LocalMedication,
          PrefetchHooks Function()
        > {
  $$LocalMedicationsTableTableManager(
    _$AppDatabase db,
    $LocalMedicationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMedicationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMedicationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMedicationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> localId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalMedicationsCompanion(
                id: id,
                localId: localId,
                userId: userId,
                serverId: serverId,
                name: name,
                note: note,
                isActive: isActive,
                isDeleted: isDeleted,
                syncState: syncState,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String localId,
                required String userId,
                Value<int?> serverId = const Value.absent(),
                required String name,
                Value<String?> note = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalMedicationsCompanion.insert(
                id: id,
                localId: localId,
                userId: userId,
                serverId: serverId,
                name: name,
                note: note,
                isActive: isActive,
                isDeleted: isDeleted,
                syncState: syncState,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalMedicationsTable, LocalMedication>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalMedicationsTable,
                    LocalMedication
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMedicationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMedicationsTable,
      LocalMedication,
      $$LocalMedicationsTableFilterComposer,
      $$LocalMedicationsTableOrderingComposer,
      $$LocalMedicationsTableAnnotationComposer,
      $$LocalMedicationsTableCreateCompanionBuilder,
      $$LocalMedicationsTableUpdateCompanionBuilder,
      (
        LocalMedication,
        BaseReferences<_$AppDatabase, $LocalMedicationsTable, LocalMedication>,
      ),
      LocalMedication,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalProfilesTableTableManager get localProfiles =>
      $$LocalProfilesTableTableManager(_db, _db.localProfiles);
  $$LocalCyclesTableTableManager get localCycles =>
      $$LocalCyclesTableTableManager(_db, _db.localCycles);
  $$LocalDailyLogsTableTableManager get localDailyLogs =>
      $$LocalDailyLogsTableTableManager(_db, _db.localDailyLogs);
  $$LocalSymptomsTableTableManager get localSymptoms =>
      $$LocalSymptomsTableTableManager(_db, _db.localSymptoms);
  $$PredictionCacheTableTableManager get predictionCache =>
      $$PredictionCacheTableTableManager(_db, _db.predictionCache);
  $$LocalHealthContextTableTableManager get localHealthContext =>
      $$LocalHealthContextTableTableManager(_db, _db.localHealthContext);
  $$LocalConditionsTableTableManager get localConditions =>
      $$LocalConditionsTableTableManager(_db, _db.localConditions);
  $$LocalMedicationsTableTableManager get localMedications =>
      $$LocalMedicationsTableTableManager(_db, _db.localMedications);
}
