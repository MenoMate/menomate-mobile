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

class $LocalFertilityObservationsTable extends LocalFertilityObservations
    with
        TableInfo<$LocalFertilityObservationsTable, LocalFertilityObservation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalFertilityObservationsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _observationDateMeta = const VerificationMeta(
    'observationDate',
  );
  @override
  late final GeneratedColumn<String> observationDate = GeneratedColumn<String>(
    'observation_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _observationTypeMeta = const VerificationMeta(
    'observationType',
  );
  @override
  late final GeneratedColumn<String> observationType = GeneratedColumn<String>(
    'observation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lhResultMeta = const VerificationMeta(
    'lhResult',
  );
  @override
  late final GeneratedColumn<String> lhResult = GeneratedColumn<String>(
    'lh_result',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bbtCelsiusMeta = const VerificationMeta(
    'bbtCelsius',
  );
  @override
  late final GeneratedColumn<double> bbtCelsius = GeneratedColumn<double>(
    'bbt_celsius',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mucusCategoryMeta = const VerificationMeta(
    'mucusCategory',
  );
  @override
  late final GeneratedColumn<String> mucusCategory = GeneratedColumn<String>(
    'mucus_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
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
      ).withConverter<SyncState>(
        $LocalFertilityObservationsTable.$convertersyncState,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localId,
    userId,
    serverId,
    observationDate,
    observationType,
    lhResult,
    bbtCelsius,
    mucusCategory,
    source,
    note,
    isDeleted,
    syncState,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_fertility_observations';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalFertilityObservation> instance, {
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
    if (data.containsKey('observation_date')) {
      context.handle(
        _observationDateMeta,
        observationDate.isAcceptableOrUnknown(
          data['observation_date']!,
          _observationDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_observationDateMeta);
    }
    if (data.containsKey('observation_type')) {
      context.handle(
        _observationTypeMeta,
        observationType.isAcceptableOrUnknown(
          data['observation_type']!,
          _observationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_observationTypeMeta);
    }
    if (data.containsKey('lh_result')) {
      context.handle(
        _lhResultMeta,
        lhResult.isAcceptableOrUnknown(data['lh_result']!, _lhResultMeta),
      );
    }
    if (data.containsKey('bbt_celsius')) {
      context.handle(
        _bbtCelsiusMeta,
        bbtCelsius.isAcceptableOrUnknown(data['bbt_celsius']!, _bbtCelsiusMeta),
      );
    }
    if (data.containsKey('mucus_category')) {
      context.handle(
        _mucusCategoryMeta,
        mucusCategory.isAcceptableOrUnknown(
          data['mucus_category']!,
          _mucusCategoryMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
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
  LocalFertilityObservation map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalFertilityObservation(
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
      observationDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observation_date'],
      )!,
      observationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observation_type'],
      )!,
      lhResult: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lh_result'],
      ),
      bbtCelsius: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bbt_celsius'],
      ),
      mucusCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mucus_category'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      syncState: $LocalFertilityObservationsTable.$convertersyncState.fromSql(
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
  $LocalFertilityObservationsTable createAlias(String alias) {
    return $LocalFertilityObservationsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, int, int> $convertersyncState =
      const EnumIndexConverter<SyncState>(SyncState.values);
}

class LocalFertilityObservation extends DataClass
    implements Insertable<LocalFertilityObservation> {
  final int id;
  final String localId;
  final String userId;
  final int? serverId;
  final String observationDate;
  final String observationType;
  final String? lhResult;
  final double? bbtCelsius;
  final String? mucusCategory;
  final String source;
  final String? note;
  final bool isDeleted;
  final SyncState syncState;
  final DateTime updatedAt;
  const LocalFertilityObservation({
    required this.id,
    required this.localId,
    required this.userId,
    this.serverId,
    required this.observationDate,
    required this.observationType,
    this.lhResult,
    this.bbtCelsius,
    this.mucusCategory,
    required this.source,
    this.note,
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
    map['observation_date'] = Variable<String>(observationDate);
    map['observation_type'] = Variable<String>(observationType);
    if (!nullToAbsent || lhResult != null) {
      map['lh_result'] = Variable<String>(lhResult);
    }
    if (!nullToAbsent || bbtCelsius != null) {
      map['bbt_celsius'] = Variable<double>(bbtCelsius);
    }
    if (!nullToAbsent || mucusCategory != null) {
      map['mucus_category'] = Variable<String>(mucusCategory);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    {
      map['sync_state'] = Variable<int>(
        $LocalFertilityObservationsTable.$convertersyncState.toSql(syncState),
      );
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalFertilityObservationsCompanion toCompanion(bool nullToAbsent) {
    return LocalFertilityObservationsCompanion(
      id: Value(id),
      localId: Value(localId),
      userId: Value(userId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      observationDate: Value(observationDate),
      observationType: Value(observationType),
      lhResult: lhResult == null && nullToAbsent
          ? const Value.absent()
          : Value(lhResult),
      bbtCelsius: bbtCelsius == null && nullToAbsent
          ? const Value.absent()
          : Value(bbtCelsius),
      mucusCategory: mucusCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(mucusCategory),
      source: Value(source),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      isDeleted: Value(isDeleted),
      syncState: Value(syncState),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalFertilityObservation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalFertilityObservation(
      id: serializer.fromJson<int>(json['id']),
      localId: serializer.fromJson<String>(json['localId']),
      userId: serializer.fromJson<String>(json['userId']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      observationDate: serializer.fromJson<String>(json['observationDate']),
      observationType: serializer.fromJson<String>(json['observationType']),
      lhResult: serializer.fromJson<String?>(json['lhResult']),
      bbtCelsius: serializer.fromJson<double?>(json['bbtCelsius']),
      mucusCategory: serializer.fromJson<String?>(json['mucusCategory']),
      source: serializer.fromJson<String>(json['source']),
      note: serializer.fromJson<String?>(json['note']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      syncState: $LocalFertilityObservationsTable.$convertersyncState.fromJson(
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
      'observationDate': serializer.toJson<String>(observationDate),
      'observationType': serializer.toJson<String>(observationType),
      'lhResult': serializer.toJson<String?>(lhResult),
      'bbtCelsius': serializer.toJson<double?>(bbtCelsius),
      'mucusCategory': serializer.toJson<String?>(mucusCategory),
      'source': serializer.toJson<String>(source),
      'note': serializer.toJson<String?>(note),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'syncState': serializer.toJson<int>(
        $LocalFertilityObservationsTable.$convertersyncState.toJson(syncState),
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalFertilityObservation copyWith({
    int? id,
    String? localId,
    String? userId,
    Value<int?> serverId = const Value.absent(),
    String? observationDate,
    String? observationType,
    Value<String?> lhResult = const Value.absent(),
    Value<double?> bbtCelsius = const Value.absent(),
    Value<String?> mucusCategory = const Value.absent(),
    String? source,
    Value<String?> note = const Value.absent(),
    bool? isDeleted,
    SyncState? syncState,
    DateTime? updatedAt,
  }) => LocalFertilityObservation(
    id: id ?? this.id,
    localId: localId ?? this.localId,
    userId: userId ?? this.userId,
    serverId: serverId.present ? serverId.value : this.serverId,
    observationDate: observationDate ?? this.observationDate,
    observationType: observationType ?? this.observationType,
    lhResult: lhResult.present ? lhResult.value : this.lhResult,
    bbtCelsius: bbtCelsius.present ? bbtCelsius.value : this.bbtCelsius,
    mucusCategory: mucusCategory.present
        ? mucusCategory.value
        : this.mucusCategory,
    source: source ?? this.source,
    note: note.present ? note.value : this.note,
    isDeleted: isDeleted ?? this.isDeleted,
    syncState: syncState ?? this.syncState,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalFertilityObservation copyWithCompanion(
    LocalFertilityObservationsCompanion data,
  ) {
    return LocalFertilityObservation(
      id: data.id.present ? data.id.value : this.id,
      localId: data.localId.present ? data.localId.value : this.localId,
      userId: data.userId.present ? data.userId.value : this.userId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      observationDate: data.observationDate.present
          ? data.observationDate.value
          : this.observationDate,
      observationType: data.observationType.present
          ? data.observationType.value
          : this.observationType,
      lhResult: data.lhResult.present ? data.lhResult.value : this.lhResult,
      bbtCelsius: data.bbtCelsius.present
          ? data.bbtCelsius.value
          : this.bbtCelsius,
      mucusCategory: data.mucusCategory.present
          ? data.mucusCategory.value
          : this.mucusCategory,
      source: data.source.present ? data.source.value : this.source,
      note: data.note.present ? data.note.value : this.note,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalFertilityObservation(')
          ..write('id: $id, ')
          ..write('localId: $localId, ')
          ..write('userId: $userId, ')
          ..write('serverId: $serverId, ')
          ..write('observationDate: $observationDate, ')
          ..write('observationType: $observationType, ')
          ..write('lhResult: $lhResult, ')
          ..write('bbtCelsius: $bbtCelsius, ')
          ..write('mucusCategory: $mucusCategory, ')
          ..write('source: $source, ')
          ..write('note: $note, ')
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
    observationDate,
    observationType,
    lhResult,
    bbtCelsius,
    mucusCategory,
    source,
    note,
    isDeleted,
    syncState,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalFertilityObservation &&
          other.id == this.id &&
          other.localId == this.localId &&
          other.userId == this.userId &&
          other.serverId == this.serverId &&
          other.observationDate == this.observationDate &&
          other.observationType == this.observationType &&
          other.lhResult == this.lhResult &&
          other.bbtCelsius == this.bbtCelsius &&
          other.mucusCategory == this.mucusCategory &&
          other.source == this.source &&
          other.note == this.note &&
          other.isDeleted == this.isDeleted &&
          other.syncState == this.syncState &&
          other.updatedAt == this.updatedAt);
}

class LocalFertilityObservationsCompanion
    extends UpdateCompanion<LocalFertilityObservation> {
  final Value<int> id;
  final Value<String> localId;
  final Value<String> userId;
  final Value<int?> serverId;
  final Value<String> observationDate;
  final Value<String> observationType;
  final Value<String?> lhResult;
  final Value<double?> bbtCelsius;
  final Value<String?> mucusCategory;
  final Value<String> source;
  final Value<String?> note;
  final Value<bool> isDeleted;
  final Value<SyncState> syncState;
  final Value<DateTime> updatedAt;
  const LocalFertilityObservationsCompanion({
    this.id = const Value.absent(),
    this.localId = const Value.absent(),
    this.userId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.observationDate = const Value.absent(),
    this.observationType = const Value.absent(),
    this.lhResult = const Value.absent(),
    this.bbtCelsius = const Value.absent(),
    this.mucusCategory = const Value.absent(),
    this.source = const Value.absent(),
    this.note = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LocalFertilityObservationsCompanion.insert({
    this.id = const Value.absent(),
    required String localId,
    required String userId,
    this.serverId = const Value.absent(),
    required String observationDate,
    required String observationType,
    this.lhResult = const Value.absent(),
    this.bbtCelsius = const Value.absent(),
    this.mucusCategory = const Value.absent(),
    this.source = const Value.absent(),
    this.note = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : localId = Value(localId),
       userId = Value(userId),
       observationDate = Value(observationDate),
       observationType = Value(observationType);
  static Insertable<LocalFertilityObservation> custom({
    Expression<int>? id,
    Expression<String>? localId,
    Expression<String>? userId,
    Expression<int>? serverId,
    Expression<String>? observationDate,
    Expression<String>? observationType,
    Expression<String>? lhResult,
    Expression<double>? bbtCelsius,
    Expression<String>? mucusCategory,
    Expression<String>? source,
    Expression<String>? note,
    Expression<bool>? isDeleted,
    Expression<int>? syncState,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localId != null) 'local_id': localId,
      if (userId != null) 'user_id': userId,
      if (serverId != null) 'server_id': serverId,
      if (observationDate != null) 'observation_date': observationDate,
      if (observationType != null) 'observation_type': observationType,
      if (lhResult != null) 'lh_result': lhResult,
      if (bbtCelsius != null) 'bbt_celsius': bbtCelsius,
      if (mucusCategory != null) 'mucus_category': mucusCategory,
      if (source != null) 'source': source,
      if (note != null) 'note': note,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncState != null) 'sync_state': syncState,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LocalFertilityObservationsCompanion copyWith({
    Value<int>? id,
    Value<String>? localId,
    Value<String>? userId,
    Value<int?>? serverId,
    Value<String>? observationDate,
    Value<String>? observationType,
    Value<String?>? lhResult,
    Value<double?>? bbtCelsius,
    Value<String?>? mucusCategory,
    Value<String>? source,
    Value<String?>? note,
    Value<bool>? isDeleted,
    Value<SyncState>? syncState,
    Value<DateTime>? updatedAt,
  }) {
    return LocalFertilityObservationsCompanion(
      id: id ?? this.id,
      localId: localId ?? this.localId,
      userId: userId ?? this.userId,
      serverId: serverId ?? this.serverId,
      observationDate: observationDate ?? this.observationDate,
      observationType: observationType ?? this.observationType,
      lhResult: lhResult ?? this.lhResult,
      bbtCelsius: bbtCelsius ?? this.bbtCelsius,
      mucusCategory: mucusCategory ?? this.mucusCategory,
      source: source ?? this.source,
      note: note ?? this.note,
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
    if (observationDate.present) {
      map['observation_date'] = Variable<String>(observationDate.value);
    }
    if (observationType.present) {
      map['observation_type'] = Variable<String>(observationType.value);
    }
    if (lhResult.present) {
      map['lh_result'] = Variable<String>(lhResult.value);
    }
    if (bbtCelsius.present) {
      map['bbt_celsius'] = Variable<double>(bbtCelsius.value);
    }
    if (mucusCategory.present) {
      map['mucus_category'] = Variable<String>(mucusCategory.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<int>(
        $LocalFertilityObservationsTable.$convertersyncState.toSql(
          syncState.value,
        ),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalFertilityObservationsCompanion(')
          ..write('id: $id, ')
          ..write('localId: $localId, ')
          ..write('userId: $userId, ')
          ..write('serverId: $serverId, ')
          ..write('observationDate: $observationDate, ')
          ..write('observationType: $observationType, ')
          ..write('lhResult: $lhResult, ')
          ..write('bbtCelsius: $bbtCelsius, ')
          ..write('mucusCategory: $mucusCategory, ')
          ..write('source: $source, ')
          ..write('note: $note, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $LocalPregnancyContextTable extends LocalPregnancyContext
    with TableInfo<$LocalPregnancyContextTable, LocalPregnancyContextData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPregnancyContextTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _datingSourceMeta = const VerificationMeta(
    'datingSource',
  );
  @override
  late final GeneratedColumn<String> datingSource = GeneratedColumn<String>(
    'dating_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estimatedDueDateMeta = const VerificationMeta(
    'estimatedDueDate',
  );
  @override
  late final GeneratedColumn<String> estimatedDueDate = GeneratedColumn<String>(
    'estimated_due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lmpDateMeta = const VerificationMeta(
    'lmpDate',
  );
  @override
  late final GeneratedColumn<String> lmpDate = GeneratedColumn<String>(
    'lmp_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confirmationDateMeta = const VerificationMeta(
    'confirmationDate',
  );
  @override
  late final GeneratedColumn<String> confirmationDate = GeneratedColumn<String>(
    'confirmation_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _datingNoteMeta = const VerificationMeta(
    'datingNote',
  );
  @override
  late final GeneratedColumn<String> datingNote = GeneratedColumn<String>(
    'dating_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eddStatusMeta = const VerificationMeta(
    'eddStatus',
  );
  @override
  late final GeneratedColumn<String> eddStatus = GeneratedColumn<String>(
    'edd_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eddLabelMeta = const VerificationMeta(
    'eddLabel',
  );
  @override
  late final GeneratedColumn<String> eddLabel = GeneratedColumn<String>(
    'edd_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _datingConfidenceMeta = const VerificationMeta(
    'datingConfidence',
  );
  @override
  late final GeneratedColumn<String> datingConfidence = GeneratedColumn<String>(
    'dating_confidence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gestationalAgeTotalDaysMeta =
      const VerificationMeta('gestationalAgeTotalDays');
  @override
  late final GeneratedColumn<int> gestationalAgeTotalDays =
      GeneratedColumn<int>(
        'gestational_age_total_days',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _gestationalAgeWeeksMeta =
      const VerificationMeta('gestationalAgeWeeks');
  @override
  late final GeneratedColumn<int> gestationalAgeWeeks = GeneratedColumn<int>(
    'gestational_age_weeks',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gestationalAgeDaysMeta =
      const VerificationMeta('gestationalAgeDays');
  @override
  late final GeneratedColumn<int> gestationalAgeDays = GeneratedColumn<int>(
    'gestational_age_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _daysUntilDueMeta = const VerificationMeta(
    'daysUntilDue',
  );
  @override
  late final GeneratedColumn<int> daysUntilDue = GeneratedColumn<int>(
    'days_until_due',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _asOfDateMeta = const VerificationMeta(
    'asOfDate',
  );
  @override
  late final GeneratedColumn<String> asOfDate = GeneratedColumn<String>(
    'as_of_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timezoneNameMeta = const VerificationMeta(
    'timezoneName',
  );
  @override
  late final GeneratedColumn<String> timezoneName = GeneratedColumn<String>(
    'timezone_name',
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
      ).withConverter<SyncState>(
        $LocalPregnancyContextTable.$convertersyncState,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    isActive,
    datingSource,
    estimatedDueDate,
    lmpDate,
    confirmationDate,
    datingNote,
    eddStatus,
    eddLabel,
    datingConfidence,
    gestationalAgeTotalDays,
    gestationalAgeWeeks,
    gestationalAgeDays,
    daysUntilDue,
    asOfDate,
    timezoneName,
    syncState,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_pregnancy_context';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPregnancyContextData> instance, {
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
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('dating_source')) {
      context.handle(
        _datingSourceMeta,
        datingSource.isAcceptableOrUnknown(
          data['dating_source']!,
          _datingSourceMeta,
        ),
      );
    }
    if (data.containsKey('estimated_due_date')) {
      context.handle(
        _estimatedDueDateMeta,
        estimatedDueDate.isAcceptableOrUnknown(
          data['estimated_due_date']!,
          _estimatedDueDateMeta,
        ),
      );
    }
    if (data.containsKey('lmp_date')) {
      context.handle(
        _lmpDateMeta,
        lmpDate.isAcceptableOrUnknown(data['lmp_date']!, _lmpDateMeta),
      );
    }
    if (data.containsKey('confirmation_date')) {
      context.handle(
        _confirmationDateMeta,
        confirmationDate.isAcceptableOrUnknown(
          data['confirmation_date']!,
          _confirmationDateMeta,
        ),
      );
    }
    if (data.containsKey('dating_note')) {
      context.handle(
        _datingNoteMeta,
        datingNote.isAcceptableOrUnknown(data['dating_note']!, _datingNoteMeta),
      );
    }
    if (data.containsKey('edd_status')) {
      context.handle(
        _eddStatusMeta,
        eddStatus.isAcceptableOrUnknown(data['edd_status']!, _eddStatusMeta),
      );
    }
    if (data.containsKey('edd_label')) {
      context.handle(
        _eddLabelMeta,
        eddLabel.isAcceptableOrUnknown(data['edd_label']!, _eddLabelMeta),
      );
    }
    if (data.containsKey('dating_confidence')) {
      context.handle(
        _datingConfidenceMeta,
        datingConfidence.isAcceptableOrUnknown(
          data['dating_confidence']!,
          _datingConfidenceMeta,
        ),
      );
    }
    if (data.containsKey('gestational_age_total_days')) {
      context.handle(
        _gestationalAgeTotalDaysMeta,
        gestationalAgeTotalDays.isAcceptableOrUnknown(
          data['gestational_age_total_days']!,
          _gestationalAgeTotalDaysMeta,
        ),
      );
    }
    if (data.containsKey('gestational_age_weeks')) {
      context.handle(
        _gestationalAgeWeeksMeta,
        gestationalAgeWeeks.isAcceptableOrUnknown(
          data['gestational_age_weeks']!,
          _gestationalAgeWeeksMeta,
        ),
      );
    }
    if (data.containsKey('gestational_age_days')) {
      context.handle(
        _gestationalAgeDaysMeta,
        gestationalAgeDays.isAcceptableOrUnknown(
          data['gestational_age_days']!,
          _gestationalAgeDaysMeta,
        ),
      );
    }
    if (data.containsKey('days_until_due')) {
      context.handle(
        _daysUntilDueMeta,
        daysUntilDue.isAcceptableOrUnknown(
          data['days_until_due']!,
          _daysUntilDueMeta,
        ),
      );
    }
    if (data.containsKey('as_of_date')) {
      context.handle(
        _asOfDateMeta,
        asOfDate.isAcceptableOrUnknown(data['as_of_date']!, _asOfDateMeta),
      );
    }
    if (data.containsKey('timezone_name')) {
      context.handle(
        _timezoneNameMeta,
        timezoneName.isAcceptableOrUnknown(
          data['timezone_name']!,
          _timezoneNameMeta,
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
  LocalPregnancyContextData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPregnancyContextData(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      datingSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dating_source'],
      ),
      estimatedDueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estimated_due_date'],
      ),
      lmpDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lmp_date'],
      ),
      confirmationDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confirmation_date'],
      ),
      datingNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dating_note'],
      ),
      eddStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}edd_status'],
      ),
      eddLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}edd_label'],
      ),
      datingConfidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dating_confidence'],
      ),
      gestationalAgeTotalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gestational_age_total_days'],
      ),
      gestationalAgeWeeks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gestational_age_weeks'],
      ),
      gestationalAgeDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}gestational_age_days'],
      ),
      daysUntilDue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days_until_due'],
      ),
      asOfDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}as_of_date'],
      ),
      timezoneName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone_name'],
      ),
      syncState: $LocalPregnancyContextTable.$convertersyncState.fromSql(
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
  $LocalPregnancyContextTable createAlias(String alias) {
    return $LocalPregnancyContextTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, int, int> $convertersyncState =
      const EnumIndexConverter<SyncState>(SyncState.values);
}

class LocalPregnancyContextData extends DataClass
    implements Insertable<LocalPregnancyContextData> {
  final String userId;
  final bool isActive;
  final String? datingSource;
  final String? estimatedDueDate;
  final String? lmpDate;
  final String? confirmationDate;
  final String? datingNote;
  final String? eddStatus;
  final String? eddLabel;
  final String? datingConfidence;
  final int? gestationalAgeTotalDays;
  final int? gestationalAgeWeeks;
  final int? gestationalAgeDays;
  final int? daysUntilDue;
  final String? asOfDate;
  final String? timezoneName;
  final SyncState syncState;
  final DateTime updatedAt;
  const LocalPregnancyContextData({
    required this.userId,
    required this.isActive,
    this.datingSource,
    this.estimatedDueDate,
    this.lmpDate,
    this.confirmationDate,
    this.datingNote,
    this.eddStatus,
    this.eddLabel,
    this.datingConfidence,
    this.gestationalAgeTotalDays,
    this.gestationalAgeWeeks,
    this.gestationalAgeDays,
    this.daysUntilDue,
    this.asOfDate,
    this.timezoneName,
    required this.syncState,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || datingSource != null) {
      map['dating_source'] = Variable<String>(datingSource);
    }
    if (!nullToAbsent || estimatedDueDate != null) {
      map['estimated_due_date'] = Variable<String>(estimatedDueDate);
    }
    if (!nullToAbsent || lmpDate != null) {
      map['lmp_date'] = Variable<String>(lmpDate);
    }
    if (!nullToAbsent || confirmationDate != null) {
      map['confirmation_date'] = Variable<String>(confirmationDate);
    }
    if (!nullToAbsent || datingNote != null) {
      map['dating_note'] = Variable<String>(datingNote);
    }
    if (!nullToAbsent || eddStatus != null) {
      map['edd_status'] = Variable<String>(eddStatus);
    }
    if (!nullToAbsent || eddLabel != null) {
      map['edd_label'] = Variable<String>(eddLabel);
    }
    if (!nullToAbsent || datingConfidence != null) {
      map['dating_confidence'] = Variable<String>(datingConfidence);
    }
    if (!nullToAbsent || gestationalAgeTotalDays != null) {
      map['gestational_age_total_days'] = Variable<int>(
        gestationalAgeTotalDays,
      );
    }
    if (!nullToAbsent || gestationalAgeWeeks != null) {
      map['gestational_age_weeks'] = Variable<int>(gestationalAgeWeeks);
    }
    if (!nullToAbsent || gestationalAgeDays != null) {
      map['gestational_age_days'] = Variable<int>(gestationalAgeDays);
    }
    if (!nullToAbsent || daysUntilDue != null) {
      map['days_until_due'] = Variable<int>(daysUntilDue);
    }
    if (!nullToAbsent || asOfDate != null) {
      map['as_of_date'] = Variable<String>(asOfDate);
    }
    if (!nullToAbsent || timezoneName != null) {
      map['timezone_name'] = Variable<String>(timezoneName);
    }
    {
      map['sync_state'] = Variable<int>(
        $LocalPregnancyContextTable.$convertersyncState.toSql(syncState),
      );
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalPregnancyContextCompanion toCompanion(bool nullToAbsent) {
    return LocalPregnancyContextCompanion(
      userId: Value(userId),
      isActive: Value(isActive),
      datingSource: datingSource == null && nullToAbsent
          ? const Value.absent()
          : Value(datingSource),
      estimatedDueDate: estimatedDueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedDueDate),
      lmpDate: lmpDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lmpDate),
      confirmationDate: confirmationDate == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmationDate),
      datingNote: datingNote == null && nullToAbsent
          ? const Value.absent()
          : Value(datingNote),
      eddStatus: eddStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(eddStatus),
      eddLabel: eddLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(eddLabel),
      datingConfidence: datingConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(datingConfidence),
      gestationalAgeTotalDays: gestationalAgeTotalDays == null && nullToAbsent
          ? const Value.absent()
          : Value(gestationalAgeTotalDays),
      gestationalAgeWeeks: gestationalAgeWeeks == null && nullToAbsent
          ? const Value.absent()
          : Value(gestationalAgeWeeks),
      gestationalAgeDays: gestationalAgeDays == null && nullToAbsent
          ? const Value.absent()
          : Value(gestationalAgeDays),
      daysUntilDue: daysUntilDue == null && nullToAbsent
          ? const Value.absent()
          : Value(daysUntilDue),
      asOfDate: asOfDate == null && nullToAbsent
          ? const Value.absent()
          : Value(asOfDate),
      timezoneName: timezoneName == null && nullToAbsent
          ? const Value.absent()
          : Value(timezoneName),
      syncState: Value(syncState),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalPregnancyContextData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPregnancyContextData(
      userId: serializer.fromJson<String>(json['userId']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      datingSource: serializer.fromJson<String?>(json['datingSource']),
      estimatedDueDate: serializer.fromJson<String?>(json['estimatedDueDate']),
      lmpDate: serializer.fromJson<String?>(json['lmpDate']),
      confirmationDate: serializer.fromJson<String?>(json['confirmationDate']),
      datingNote: serializer.fromJson<String?>(json['datingNote']),
      eddStatus: serializer.fromJson<String?>(json['eddStatus']),
      eddLabel: serializer.fromJson<String?>(json['eddLabel']),
      datingConfidence: serializer.fromJson<String?>(json['datingConfidence']),
      gestationalAgeTotalDays: serializer.fromJson<int?>(
        json['gestationalAgeTotalDays'],
      ),
      gestationalAgeWeeks: serializer.fromJson<int?>(
        json['gestationalAgeWeeks'],
      ),
      gestationalAgeDays: serializer.fromJson<int?>(json['gestationalAgeDays']),
      daysUntilDue: serializer.fromJson<int?>(json['daysUntilDue']),
      asOfDate: serializer.fromJson<String?>(json['asOfDate']),
      timezoneName: serializer.fromJson<String?>(json['timezoneName']),
      syncState: $LocalPregnancyContextTable.$convertersyncState.fromJson(
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
      'isActive': serializer.toJson<bool>(isActive),
      'datingSource': serializer.toJson<String?>(datingSource),
      'estimatedDueDate': serializer.toJson<String?>(estimatedDueDate),
      'lmpDate': serializer.toJson<String?>(lmpDate),
      'confirmationDate': serializer.toJson<String?>(confirmationDate),
      'datingNote': serializer.toJson<String?>(datingNote),
      'eddStatus': serializer.toJson<String?>(eddStatus),
      'eddLabel': serializer.toJson<String?>(eddLabel),
      'datingConfidence': serializer.toJson<String?>(datingConfidence),
      'gestationalAgeTotalDays': serializer.toJson<int?>(
        gestationalAgeTotalDays,
      ),
      'gestationalAgeWeeks': serializer.toJson<int?>(gestationalAgeWeeks),
      'gestationalAgeDays': serializer.toJson<int?>(gestationalAgeDays),
      'daysUntilDue': serializer.toJson<int?>(daysUntilDue),
      'asOfDate': serializer.toJson<String?>(asOfDate),
      'timezoneName': serializer.toJson<String?>(timezoneName),
      'syncState': serializer.toJson<int>(
        $LocalPregnancyContextTable.$convertersyncState.toJson(syncState),
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalPregnancyContextData copyWith({
    String? userId,
    bool? isActive,
    Value<String?> datingSource = const Value.absent(),
    Value<String?> estimatedDueDate = const Value.absent(),
    Value<String?> lmpDate = const Value.absent(),
    Value<String?> confirmationDate = const Value.absent(),
    Value<String?> datingNote = const Value.absent(),
    Value<String?> eddStatus = const Value.absent(),
    Value<String?> eddLabel = const Value.absent(),
    Value<String?> datingConfidence = const Value.absent(),
    Value<int?> gestationalAgeTotalDays = const Value.absent(),
    Value<int?> gestationalAgeWeeks = const Value.absent(),
    Value<int?> gestationalAgeDays = const Value.absent(),
    Value<int?> daysUntilDue = const Value.absent(),
    Value<String?> asOfDate = const Value.absent(),
    Value<String?> timezoneName = const Value.absent(),
    SyncState? syncState,
    DateTime? updatedAt,
  }) => LocalPregnancyContextData(
    userId: userId ?? this.userId,
    isActive: isActive ?? this.isActive,
    datingSource: datingSource.present ? datingSource.value : this.datingSource,
    estimatedDueDate: estimatedDueDate.present
        ? estimatedDueDate.value
        : this.estimatedDueDate,
    lmpDate: lmpDate.present ? lmpDate.value : this.lmpDate,
    confirmationDate: confirmationDate.present
        ? confirmationDate.value
        : this.confirmationDate,
    datingNote: datingNote.present ? datingNote.value : this.datingNote,
    eddStatus: eddStatus.present ? eddStatus.value : this.eddStatus,
    eddLabel: eddLabel.present ? eddLabel.value : this.eddLabel,
    datingConfidence: datingConfidence.present
        ? datingConfidence.value
        : this.datingConfidence,
    gestationalAgeTotalDays: gestationalAgeTotalDays.present
        ? gestationalAgeTotalDays.value
        : this.gestationalAgeTotalDays,
    gestationalAgeWeeks: gestationalAgeWeeks.present
        ? gestationalAgeWeeks.value
        : this.gestationalAgeWeeks,
    gestationalAgeDays: gestationalAgeDays.present
        ? gestationalAgeDays.value
        : this.gestationalAgeDays,
    daysUntilDue: daysUntilDue.present ? daysUntilDue.value : this.daysUntilDue,
    asOfDate: asOfDate.present ? asOfDate.value : this.asOfDate,
    timezoneName: timezoneName.present ? timezoneName.value : this.timezoneName,
    syncState: syncState ?? this.syncState,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalPregnancyContextData copyWithCompanion(
    LocalPregnancyContextCompanion data,
  ) {
    return LocalPregnancyContextData(
      userId: data.userId.present ? data.userId.value : this.userId,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      datingSource: data.datingSource.present
          ? data.datingSource.value
          : this.datingSource,
      estimatedDueDate: data.estimatedDueDate.present
          ? data.estimatedDueDate.value
          : this.estimatedDueDate,
      lmpDate: data.lmpDate.present ? data.lmpDate.value : this.lmpDate,
      confirmationDate: data.confirmationDate.present
          ? data.confirmationDate.value
          : this.confirmationDate,
      datingNote: data.datingNote.present
          ? data.datingNote.value
          : this.datingNote,
      eddStatus: data.eddStatus.present ? data.eddStatus.value : this.eddStatus,
      eddLabel: data.eddLabel.present ? data.eddLabel.value : this.eddLabel,
      datingConfidence: data.datingConfidence.present
          ? data.datingConfidence.value
          : this.datingConfidence,
      gestationalAgeTotalDays: data.gestationalAgeTotalDays.present
          ? data.gestationalAgeTotalDays.value
          : this.gestationalAgeTotalDays,
      gestationalAgeWeeks: data.gestationalAgeWeeks.present
          ? data.gestationalAgeWeeks.value
          : this.gestationalAgeWeeks,
      gestationalAgeDays: data.gestationalAgeDays.present
          ? data.gestationalAgeDays.value
          : this.gestationalAgeDays,
      daysUntilDue: data.daysUntilDue.present
          ? data.daysUntilDue.value
          : this.daysUntilDue,
      asOfDate: data.asOfDate.present ? data.asOfDate.value : this.asOfDate,
      timezoneName: data.timezoneName.present
          ? data.timezoneName.value
          : this.timezoneName,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPregnancyContextData(')
          ..write('userId: $userId, ')
          ..write('isActive: $isActive, ')
          ..write('datingSource: $datingSource, ')
          ..write('estimatedDueDate: $estimatedDueDate, ')
          ..write('lmpDate: $lmpDate, ')
          ..write('confirmationDate: $confirmationDate, ')
          ..write('datingNote: $datingNote, ')
          ..write('eddStatus: $eddStatus, ')
          ..write('eddLabel: $eddLabel, ')
          ..write('datingConfidence: $datingConfidence, ')
          ..write('gestationalAgeTotalDays: $gestationalAgeTotalDays, ')
          ..write('gestationalAgeWeeks: $gestationalAgeWeeks, ')
          ..write('gestationalAgeDays: $gestationalAgeDays, ')
          ..write('daysUntilDue: $daysUntilDue, ')
          ..write('asOfDate: $asOfDate, ')
          ..write('timezoneName: $timezoneName, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    isActive,
    datingSource,
    estimatedDueDate,
    lmpDate,
    confirmationDate,
    datingNote,
    eddStatus,
    eddLabel,
    datingConfidence,
    gestationalAgeTotalDays,
    gestationalAgeWeeks,
    gestationalAgeDays,
    daysUntilDue,
    asOfDate,
    timezoneName,
    syncState,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPregnancyContextData &&
          other.userId == this.userId &&
          other.isActive == this.isActive &&
          other.datingSource == this.datingSource &&
          other.estimatedDueDate == this.estimatedDueDate &&
          other.lmpDate == this.lmpDate &&
          other.confirmationDate == this.confirmationDate &&
          other.datingNote == this.datingNote &&
          other.eddStatus == this.eddStatus &&
          other.eddLabel == this.eddLabel &&
          other.datingConfidence == this.datingConfidence &&
          other.gestationalAgeTotalDays == this.gestationalAgeTotalDays &&
          other.gestationalAgeWeeks == this.gestationalAgeWeeks &&
          other.gestationalAgeDays == this.gestationalAgeDays &&
          other.daysUntilDue == this.daysUntilDue &&
          other.asOfDate == this.asOfDate &&
          other.timezoneName == this.timezoneName &&
          other.syncState == this.syncState &&
          other.updatedAt == this.updatedAt);
}

class LocalPregnancyContextCompanion
    extends UpdateCompanion<LocalPregnancyContextData> {
  final Value<String> userId;
  final Value<bool> isActive;
  final Value<String?> datingSource;
  final Value<String?> estimatedDueDate;
  final Value<String?> lmpDate;
  final Value<String?> confirmationDate;
  final Value<String?> datingNote;
  final Value<String?> eddStatus;
  final Value<String?> eddLabel;
  final Value<String?> datingConfidence;
  final Value<int?> gestationalAgeTotalDays;
  final Value<int?> gestationalAgeWeeks;
  final Value<int?> gestationalAgeDays;
  final Value<int?> daysUntilDue;
  final Value<String?> asOfDate;
  final Value<String?> timezoneName;
  final Value<SyncState> syncState;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalPregnancyContextCompanion({
    this.userId = const Value.absent(),
    this.isActive = const Value.absent(),
    this.datingSource = const Value.absent(),
    this.estimatedDueDate = const Value.absent(),
    this.lmpDate = const Value.absent(),
    this.confirmationDate = const Value.absent(),
    this.datingNote = const Value.absent(),
    this.eddStatus = const Value.absent(),
    this.eddLabel = const Value.absent(),
    this.datingConfidence = const Value.absent(),
    this.gestationalAgeTotalDays = const Value.absent(),
    this.gestationalAgeWeeks = const Value.absent(),
    this.gestationalAgeDays = const Value.absent(),
    this.daysUntilDue = const Value.absent(),
    this.asOfDate = const Value.absent(),
    this.timezoneName = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPregnancyContextCompanion.insert({
    required String userId,
    this.isActive = const Value.absent(),
    this.datingSource = const Value.absent(),
    this.estimatedDueDate = const Value.absent(),
    this.lmpDate = const Value.absent(),
    this.confirmationDate = const Value.absent(),
    this.datingNote = const Value.absent(),
    this.eddStatus = const Value.absent(),
    this.eddLabel = const Value.absent(),
    this.datingConfidence = const Value.absent(),
    this.gestationalAgeTotalDays = const Value.absent(),
    this.gestationalAgeWeeks = const Value.absent(),
    this.gestationalAgeDays = const Value.absent(),
    this.daysUntilDue = const Value.absent(),
    this.asOfDate = const Value.absent(),
    this.timezoneName = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<LocalPregnancyContextData> custom({
    Expression<String>? userId,
    Expression<bool>? isActive,
    Expression<String>? datingSource,
    Expression<String>? estimatedDueDate,
    Expression<String>? lmpDate,
    Expression<String>? confirmationDate,
    Expression<String>? datingNote,
    Expression<String>? eddStatus,
    Expression<String>? eddLabel,
    Expression<String>? datingConfidence,
    Expression<int>? gestationalAgeTotalDays,
    Expression<int>? gestationalAgeWeeks,
    Expression<int>? gestationalAgeDays,
    Expression<int>? daysUntilDue,
    Expression<String>? asOfDate,
    Expression<String>? timezoneName,
    Expression<int>? syncState,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (isActive != null) 'is_active': isActive,
      if (datingSource != null) 'dating_source': datingSource,
      if (estimatedDueDate != null) 'estimated_due_date': estimatedDueDate,
      if (lmpDate != null) 'lmp_date': lmpDate,
      if (confirmationDate != null) 'confirmation_date': confirmationDate,
      if (datingNote != null) 'dating_note': datingNote,
      if (eddStatus != null) 'edd_status': eddStatus,
      if (eddLabel != null) 'edd_label': eddLabel,
      if (datingConfidence != null) 'dating_confidence': datingConfidence,
      if (gestationalAgeTotalDays != null)
        'gestational_age_total_days': gestationalAgeTotalDays,
      if (gestationalAgeWeeks != null)
        'gestational_age_weeks': gestationalAgeWeeks,
      if (gestationalAgeDays != null)
        'gestational_age_days': gestationalAgeDays,
      if (daysUntilDue != null) 'days_until_due': daysUntilDue,
      if (asOfDate != null) 'as_of_date': asOfDate,
      if (timezoneName != null) 'timezone_name': timezoneName,
      if (syncState != null) 'sync_state': syncState,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPregnancyContextCompanion copyWith({
    Value<String>? userId,
    Value<bool>? isActive,
    Value<String?>? datingSource,
    Value<String?>? estimatedDueDate,
    Value<String?>? lmpDate,
    Value<String?>? confirmationDate,
    Value<String?>? datingNote,
    Value<String?>? eddStatus,
    Value<String?>? eddLabel,
    Value<String?>? datingConfidence,
    Value<int?>? gestationalAgeTotalDays,
    Value<int?>? gestationalAgeWeeks,
    Value<int?>? gestationalAgeDays,
    Value<int?>? daysUntilDue,
    Value<String?>? asOfDate,
    Value<String?>? timezoneName,
    Value<SyncState>? syncState,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalPregnancyContextCompanion(
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
      datingSource: datingSource ?? this.datingSource,
      estimatedDueDate: estimatedDueDate ?? this.estimatedDueDate,
      lmpDate: lmpDate ?? this.lmpDate,
      confirmationDate: confirmationDate ?? this.confirmationDate,
      datingNote: datingNote ?? this.datingNote,
      eddStatus: eddStatus ?? this.eddStatus,
      eddLabel: eddLabel ?? this.eddLabel,
      datingConfidence: datingConfidence ?? this.datingConfidence,
      gestationalAgeTotalDays:
          gestationalAgeTotalDays ?? this.gestationalAgeTotalDays,
      gestationalAgeWeeks: gestationalAgeWeeks ?? this.gestationalAgeWeeks,
      gestationalAgeDays: gestationalAgeDays ?? this.gestationalAgeDays,
      daysUntilDue: daysUntilDue ?? this.daysUntilDue,
      asOfDate: asOfDate ?? this.asOfDate,
      timezoneName: timezoneName ?? this.timezoneName,
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
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (datingSource.present) {
      map['dating_source'] = Variable<String>(datingSource.value);
    }
    if (estimatedDueDate.present) {
      map['estimated_due_date'] = Variable<String>(estimatedDueDate.value);
    }
    if (lmpDate.present) {
      map['lmp_date'] = Variable<String>(lmpDate.value);
    }
    if (confirmationDate.present) {
      map['confirmation_date'] = Variable<String>(confirmationDate.value);
    }
    if (datingNote.present) {
      map['dating_note'] = Variable<String>(datingNote.value);
    }
    if (eddStatus.present) {
      map['edd_status'] = Variable<String>(eddStatus.value);
    }
    if (eddLabel.present) {
      map['edd_label'] = Variable<String>(eddLabel.value);
    }
    if (datingConfidence.present) {
      map['dating_confidence'] = Variable<String>(datingConfidence.value);
    }
    if (gestationalAgeTotalDays.present) {
      map['gestational_age_total_days'] = Variable<int>(
        gestationalAgeTotalDays.value,
      );
    }
    if (gestationalAgeWeeks.present) {
      map['gestational_age_weeks'] = Variable<int>(gestationalAgeWeeks.value);
    }
    if (gestationalAgeDays.present) {
      map['gestational_age_days'] = Variable<int>(gestationalAgeDays.value);
    }
    if (daysUntilDue.present) {
      map['days_until_due'] = Variable<int>(daysUntilDue.value);
    }
    if (asOfDate.present) {
      map['as_of_date'] = Variable<String>(asOfDate.value);
    }
    if (timezoneName.present) {
      map['timezone_name'] = Variable<String>(timezoneName.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<int>(
        $LocalPregnancyContextTable.$convertersyncState.toSql(syncState.value),
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
    return (StringBuffer('LocalPregnancyContextCompanion(')
          ..write('userId: $userId, ')
          ..write('isActive: $isActive, ')
          ..write('datingSource: $datingSource, ')
          ..write('estimatedDueDate: $estimatedDueDate, ')
          ..write('lmpDate: $lmpDate, ')
          ..write('confirmationDate: $confirmationDate, ')
          ..write('datingNote: $datingNote, ')
          ..write('eddStatus: $eddStatus, ')
          ..write('eddLabel: $eddLabel, ')
          ..write('datingConfidence: $datingConfidence, ')
          ..write('gestationalAgeTotalDays: $gestationalAgeTotalDays, ')
          ..write('gestationalAgeWeeks: $gestationalAgeWeeks, ')
          ..write('gestationalAgeDays: $gestationalAgeDays, ')
          ..write('daysUntilDue: $daysUntilDue, ')
          ..write('asOfDate: $asOfDate, ')
          ..write('timezoneName: $timezoneName, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalAgingContextTable extends LocalAgingContext
    with TableInfo<$LocalAgingContextTable, LocalAgingContextData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAgingContextTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
      ).withConverter<SyncState>($LocalAgingContextTable.$convertersyncState);
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
  List<GeneratedColumn> get $columns => [userId, notes, syncState, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_aging_context';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAgingContextData> instance, {
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
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  LocalAgingContextData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAgingContextData(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      syncState: $LocalAgingContextTable.$convertersyncState.fromSql(
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
  $LocalAgingContextTable createAlias(String alias) {
    return $LocalAgingContextTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, int, int> $convertersyncState =
      const EnumIndexConverter<SyncState>(SyncState.values);
}

class LocalAgingContextData extends DataClass
    implements Insertable<LocalAgingContextData> {
  final String userId;
  final String? notes;
  final SyncState syncState;
  final DateTime updatedAt;
  const LocalAgingContextData({
    required this.userId,
    this.notes,
    required this.syncState,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['sync_state'] = Variable<int>(
        $LocalAgingContextTable.$convertersyncState.toSql(syncState),
      );
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalAgingContextCompanion toCompanion(bool nullToAbsent) {
    return LocalAgingContextCompanion(
      userId: Value(userId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      syncState: Value(syncState),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalAgingContextData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAgingContextData(
      userId: serializer.fromJson<String>(json['userId']),
      notes: serializer.fromJson<String?>(json['notes']),
      syncState: $LocalAgingContextTable.$convertersyncState.fromJson(
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
      'notes': serializer.toJson<String?>(notes),
      'syncState': serializer.toJson<int>(
        $LocalAgingContextTable.$convertersyncState.toJson(syncState),
      ),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalAgingContextData copyWith({
    String? userId,
    Value<String?> notes = const Value.absent(),
    SyncState? syncState,
    DateTime? updatedAt,
  }) => LocalAgingContextData(
    userId: userId ?? this.userId,
    notes: notes.present ? notes.value : this.notes,
    syncState: syncState ?? this.syncState,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalAgingContextData copyWithCompanion(LocalAgingContextCompanion data) {
    return LocalAgingContextData(
      userId: data.userId.present ? data.userId.value : this.userId,
      notes: data.notes.present ? data.notes.value : this.notes,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAgingContextData(')
          ..write('userId: $userId, ')
          ..write('notes: $notes, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, notes, syncState, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAgingContextData &&
          other.userId == this.userId &&
          other.notes == this.notes &&
          other.syncState == this.syncState &&
          other.updatedAt == this.updatedAt);
}

class LocalAgingContextCompanion
    extends UpdateCompanion<LocalAgingContextData> {
  final Value<String> userId;
  final Value<String?> notes;
  final Value<SyncState> syncState;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalAgingContextCompanion({
    this.userId = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAgingContextCompanion.insert({
    required String userId,
    this.notes = const Value.absent(),
    this.syncState = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<LocalAgingContextData> custom({
    Expression<String>? userId,
    Expression<String>? notes,
    Expression<int>? syncState,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (notes != null) 'notes': notes,
      if (syncState != null) 'sync_state': syncState,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAgingContextCompanion copyWith({
    Value<String>? userId,
    Value<String?>? notes,
    Value<SyncState>? syncState,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalAgingContextCompanion(
      userId: userId ?? this.userId,
      notes: notes ?? this.notes,
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
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<int>(
        $LocalAgingContextTable.$convertersyncState.toSql(syncState.value),
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
    return (StringBuffer('LocalAgingContextCompanion(')
          ..write('userId: $userId, ')
          ..write('notes: $notes, ')
          ..write('syncState: $syncState, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
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
  late final $LocalFertilityObservationsTable localFertilityObservations =
      $LocalFertilityObservationsTable(this);
  late final $LocalPregnancyContextTable localPregnancyContext =
      $LocalPregnancyContextTable(this);
  late final $LocalAgingContextTable localAgingContext =
      $LocalAgingContextTable(this);
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
    localFertilityObservations,
    localPregnancyContext,
    localAgingContext,
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
typedef $$LocalFertilityObservationsTableCreateCompanionBuilder =
    LocalFertilityObservationsCompanion Function({
      Value<int> id,
      required String localId,
      required String userId,
      Value<int?> serverId,
      required String observationDate,
      required String observationType,
      Value<String?> lhResult,
      Value<double?> bbtCelsius,
      Value<String?> mucusCategory,
      Value<String> source,
      Value<String?> note,
      Value<bool> isDeleted,
      Value<SyncState> syncState,
      Value<DateTime> updatedAt,
    });
typedef $$LocalFertilityObservationsTableUpdateCompanionBuilder =
    LocalFertilityObservationsCompanion Function({
      Value<int> id,
      Value<String> localId,
      Value<String> userId,
      Value<int?> serverId,
      Value<String> observationDate,
      Value<String> observationType,
      Value<String?> lhResult,
      Value<double?> bbtCelsius,
      Value<String?> mucusCategory,
      Value<String> source,
      Value<String?> note,
      Value<bool> isDeleted,
      Value<SyncState> syncState,
      Value<DateTime> updatedAt,
    });

class $$LocalFertilityObservationsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalFertilityObservationsTable> {
  $$LocalFertilityObservationsTableFilterComposer({
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

  ColumnFilters<String> get observationDate => $composableBuilder(
    column: $table.observationDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observationType => $composableBuilder(
    column: $table.observationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lhResult => $composableBuilder(
    column: $table.lhResult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bbtCelsius => $composableBuilder(
    column: $table.bbtCelsius,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mucusCategory => $composableBuilder(
    column: $table.mucusCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
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

class $$LocalFertilityObservationsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalFertilityObservationsTable> {
  $$LocalFertilityObservationsTableOrderingComposer({
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

  ColumnOrderings<String> get observationDate => $composableBuilder(
    column: $table.observationDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observationType => $composableBuilder(
    column: $table.observationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lhResult => $composableBuilder(
    column: $table.lhResult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bbtCelsius => $composableBuilder(
    column: $table.bbtCelsius,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mucusCategory => $composableBuilder(
    column: $table.mucusCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
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

class $$LocalFertilityObservationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalFertilityObservationsTable> {
  $$LocalFertilityObservationsTableAnnotationComposer({
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

  GeneratedColumn<String> get observationDate => $composableBuilder(
    column: $table.observationDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get observationType => $composableBuilder(
    column: $table.observationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lhResult =>
      $composableBuilder(column: $table.lhResult, builder: (column) => column);

  GeneratedColumn<double> get bbtCelsius => $composableBuilder(
    column: $table.bbtCelsius,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mucusCategory => $composableBuilder(
    column: $table.mucusCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, int> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalFertilityObservationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalFertilityObservationsTable,
          LocalFertilityObservation,
          $$LocalFertilityObservationsTableFilterComposer,
          $$LocalFertilityObservationsTableOrderingComposer,
          $$LocalFertilityObservationsTableAnnotationComposer,
          $$LocalFertilityObservationsTableCreateCompanionBuilder,
          $$LocalFertilityObservationsTableUpdateCompanionBuilder,
          (
            LocalFertilityObservation,
            BaseReferences<
              _$AppDatabase,
              $LocalFertilityObservationsTable,
              LocalFertilityObservation
            >,
          ),
          LocalFertilityObservation,
          PrefetchHooks Function()
        > {
  $$LocalFertilityObservationsTableTableManager(
    _$AppDatabase db,
    $LocalFertilityObservationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalFertilityObservationsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalFertilityObservationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalFertilityObservationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> localId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> observationDate = const Value.absent(),
                Value<String> observationType = const Value.absent(),
                Value<String?> lhResult = const Value.absent(),
                Value<double?> bbtCelsius = const Value.absent(),
                Value<String?> mucusCategory = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalFertilityObservationsCompanion(
                id: id,
                localId: localId,
                userId: userId,
                serverId: serverId,
                observationDate: observationDate,
                observationType: observationType,
                lhResult: lhResult,
                bbtCelsius: bbtCelsius,
                mucusCategory: mucusCategory,
                source: source,
                note: note,
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
                required String observationDate,
                required String observationType,
                Value<String?> lhResult = const Value.absent(),
                Value<double?> bbtCelsius = const Value.absent(),
                Value<String?> mucusCategory = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => LocalFertilityObservationsCompanion.insert(
                id: id,
                localId: localId,
                userId: userId,
                serverId: serverId,
                observationDate: observationDate,
                observationType: observationType,
                lhResult: lhResult,
                bbtCelsius: bbtCelsius,
                mucusCategory: mucusCategory,
                source: source,
                note: note,
                isDeleted: isDeleted,
                syncState: syncState,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalFertilityObservationsTable,
                    LocalFertilityObservation
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalFertilityObservationsTable,
                    LocalFertilityObservation
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalFertilityObservationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalFertilityObservationsTable,
      LocalFertilityObservation,
      $$LocalFertilityObservationsTableFilterComposer,
      $$LocalFertilityObservationsTableOrderingComposer,
      $$LocalFertilityObservationsTableAnnotationComposer,
      $$LocalFertilityObservationsTableCreateCompanionBuilder,
      $$LocalFertilityObservationsTableUpdateCompanionBuilder,
      (
        LocalFertilityObservation,
        BaseReferences<
          _$AppDatabase,
          $LocalFertilityObservationsTable,
          LocalFertilityObservation
        >,
      ),
      LocalFertilityObservation,
      PrefetchHooks Function()
    >;
typedef $$LocalPregnancyContextTableCreateCompanionBuilder =
    LocalPregnancyContextCompanion Function({
      required String userId,
      Value<bool> isActive,
      Value<String?> datingSource,
      Value<String?> estimatedDueDate,
      Value<String?> lmpDate,
      Value<String?> confirmationDate,
      Value<String?> datingNote,
      Value<String?> eddStatus,
      Value<String?> eddLabel,
      Value<String?> datingConfidence,
      Value<int?> gestationalAgeTotalDays,
      Value<int?> gestationalAgeWeeks,
      Value<int?> gestationalAgeDays,
      Value<int?> daysUntilDue,
      Value<String?> asOfDate,
      Value<String?> timezoneName,
      Value<SyncState> syncState,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalPregnancyContextTableUpdateCompanionBuilder =
    LocalPregnancyContextCompanion Function({
      Value<String> userId,
      Value<bool> isActive,
      Value<String?> datingSource,
      Value<String?> estimatedDueDate,
      Value<String?> lmpDate,
      Value<String?> confirmationDate,
      Value<String?> datingNote,
      Value<String?> eddStatus,
      Value<String?> eddLabel,
      Value<String?> datingConfidence,
      Value<int?> gestationalAgeTotalDays,
      Value<int?> gestationalAgeWeeks,
      Value<int?> gestationalAgeDays,
      Value<int?> daysUntilDue,
      Value<String?> asOfDate,
      Value<String?> timezoneName,
      Value<SyncState> syncState,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalPregnancyContextTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPregnancyContextTable> {
  $$LocalPregnancyContextTableFilterComposer({
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

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get datingSource => $composableBuilder(
    column: $table.datingSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estimatedDueDate => $composableBuilder(
    column: $table.estimatedDueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lmpDate => $composableBuilder(
    column: $table.lmpDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confirmationDate => $composableBuilder(
    column: $table.confirmationDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get datingNote => $composableBuilder(
    column: $table.datingNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eddStatus => $composableBuilder(
    column: $table.eddStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eddLabel => $composableBuilder(
    column: $table.eddLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get datingConfidence => $composableBuilder(
    column: $table.datingConfidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gestationalAgeTotalDays => $composableBuilder(
    column: $table.gestationalAgeTotalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gestationalAgeWeeks => $composableBuilder(
    column: $table.gestationalAgeWeeks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gestationalAgeDays => $composableBuilder(
    column: $table.gestationalAgeDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get daysUntilDue => $composableBuilder(
    column: $table.daysUntilDue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get asOfDate => $composableBuilder(
    column: $table.asOfDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezoneName => $composableBuilder(
    column: $table.timezoneName,
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

class $$LocalPregnancyContextTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPregnancyContextTable> {
  $$LocalPregnancyContextTableOrderingComposer({
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

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get datingSource => $composableBuilder(
    column: $table.datingSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estimatedDueDate => $composableBuilder(
    column: $table.estimatedDueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lmpDate => $composableBuilder(
    column: $table.lmpDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confirmationDate => $composableBuilder(
    column: $table.confirmationDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get datingNote => $composableBuilder(
    column: $table.datingNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eddStatus => $composableBuilder(
    column: $table.eddStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eddLabel => $composableBuilder(
    column: $table.eddLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get datingConfidence => $composableBuilder(
    column: $table.datingConfidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gestationalAgeTotalDays => $composableBuilder(
    column: $table.gestationalAgeTotalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gestationalAgeWeeks => $composableBuilder(
    column: $table.gestationalAgeWeeks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gestationalAgeDays => $composableBuilder(
    column: $table.gestationalAgeDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get daysUntilDue => $composableBuilder(
    column: $table.daysUntilDue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get asOfDate => $composableBuilder(
    column: $table.asOfDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezoneName => $composableBuilder(
    column: $table.timezoneName,
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

class $$LocalPregnancyContextTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPregnancyContextTable> {
  $$LocalPregnancyContextTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get datingSource => $composableBuilder(
    column: $table.datingSource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get estimatedDueDate => $composableBuilder(
    column: $table.estimatedDueDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lmpDate =>
      $composableBuilder(column: $table.lmpDate, builder: (column) => column);

  GeneratedColumn<String> get confirmationDate => $composableBuilder(
    column: $table.confirmationDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get datingNote => $composableBuilder(
    column: $table.datingNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eddStatus =>
      $composableBuilder(column: $table.eddStatus, builder: (column) => column);

  GeneratedColumn<String> get eddLabel =>
      $composableBuilder(column: $table.eddLabel, builder: (column) => column);

  GeneratedColumn<String> get datingConfidence => $composableBuilder(
    column: $table.datingConfidence,
    builder: (column) => column,
  );

  GeneratedColumn<int> get gestationalAgeTotalDays => $composableBuilder(
    column: $table.gestationalAgeTotalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get gestationalAgeWeeks => $composableBuilder(
    column: $table.gestationalAgeWeeks,
    builder: (column) => column,
  );

  GeneratedColumn<int> get gestationalAgeDays => $composableBuilder(
    column: $table.gestationalAgeDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get daysUntilDue => $composableBuilder(
    column: $table.daysUntilDue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get asOfDate =>
      $composableBuilder(column: $table.asOfDate, builder: (column) => column);

  GeneratedColumn<String> get timezoneName => $composableBuilder(
    column: $table.timezoneName,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SyncState, int> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalPregnancyContextTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalPregnancyContextTable,
          LocalPregnancyContextData,
          $$LocalPregnancyContextTableFilterComposer,
          $$LocalPregnancyContextTableOrderingComposer,
          $$LocalPregnancyContextTableAnnotationComposer,
          $$LocalPregnancyContextTableCreateCompanionBuilder,
          $$LocalPregnancyContextTableUpdateCompanionBuilder,
          (
            LocalPregnancyContextData,
            BaseReferences<
              _$AppDatabase,
              $LocalPregnancyContextTable,
              LocalPregnancyContextData
            >,
          ),
          LocalPregnancyContextData,
          PrefetchHooks Function()
        > {
  $$LocalPregnancyContextTableTableManager(
    _$AppDatabase db,
    $LocalPregnancyContextTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPregnancyContextTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalPregnancyContextTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalPregnancyContextTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> datingSource = const Value.absent(),
                Value<String?> estimatedDueDate = const Value.absent(),
                Value<String?> lmpDate = const Value.absent(),
                Value<String?> confirmationDate = const Value.absent(),
                Value<String?> datingNote = const Value.absent(),
                Value<String?> eddStatus = const Value.absent(),
                Value<String?> eddLabel = const Value.absent(),
                Value<String?> datingConfidence = const Value.absent(),
                Value<int?> gestationalAgeTotalDays = const Value.absent(),
                Value<int?> gestationalAgeWeeks = const Value.absent(),
                Value<int?> gestationalAgeDays = const Value.absent(),
                Value<int?> daysUntilDue = const Value.absent(),
                Value<String?> asOfDate = const Value.absent(),
                Value<String?> timezoneName = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPregnancyContextCompanion(
                userId: userId,
                isActive: isActive,
                datingSource: datingSource,
                estimatedDueDate: estimatedDueDate,
                lmpDate: lmpDate,
                confirmationDate: confirmationDate,
                datingNote: datingNote,
                eddStatus: eddStatus,
                eddLabel: eddLabel,
                datingConfidence: datingConfidence,
                gestationalAgeTotalDays: gestationalAgeTotalDays,
                gestationalAgeWeeks: gestationalAgeWeeks,
                gestationalAgeDays: gestationalAgeDays,
                daysUntilDue: daysUntilDue,
                asOfDate: asOfDate,
                timezoneName: timezoneName,
                syncState: syncState,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<bool> isActive = const Value.absent(),
                Value<String?> datingSource = const Value.absent(),
                Value<String?> estimatedDueDate = const Value.absent(),
                Value<String?> lmpDate = const Value.absent(),
                Value<String?> confirmationDate = const Value.absent(),
                Value<String?> datingNote = const Value.absent(),
                Value<String?> eddStatus = const Value.absent(),
                Value<String?> eddLabel = const Value.absent(),
                Value<String?> datingConfidence = const Value.absent(),
                Value<int?> gestationalAgeTotalDays = const Value.absent(),
                Value<int?> gestationalAgeWeeks = const Value.absent(),
                Value<int?> gestationalAgeDays = const Value.absent(),
                Value<int?> daysUntilDue = const Value.absent(),
                Value<String?> asOfDate = const Value.absent(),
                Value<String?> timezoneName = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPregnancyContextCompanion.insert(
                userId: userId,
                isActive: isActive,
                datingSource: datingSource,
                estimatedDueDate: estimatedDueDate,
                lmpDate: lmpDate,
                confirmationDate: confirmationDate,
                datingNote: datingNote,
                eddStatus: eddStatus,
                eddLabel: eddLabel,
                datingConfidence: datingConfidence,
                gestationalAgeTotalDays: gestationalAgeTotalDays,
                gestationalAgeWeeks: gestationalAgeWeeks,
                gestationalAgeDays: gestationalAgeDays,
                daysUntilDue: daysUntilDue,
                asOfDate: asOfDate,
                timezoneName: timezoneName,
                syncState: syncState,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalPregnancyContextTable,
                    LocalPregnancyContextData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalPregnancyContextTable,
                    LocalPregnancyContextData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPregnancyContextTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalPregnancyContextTable,
      LocalPregnancyContextData,
      $$LocalPregnancyContextTableFilterComposer,
      $$LocalPregnancyContextTableOrderingComposer,
      $$LocalPregnancyContextTableAnnotationComposer,
      $$LocalPregnancyContextTableCreateCompanionBuilder,
      $$LocalPregnancyContextTableUpdateCompanionBuilder,
      (
        LocalPregnancyContextData,
        BaseReferences<
          _$AppDatabase,
          $LocalPregnancyContextTable,
          LocalPregnancyContextData
        >,
      ),
      LocalPregnancyContextData,
      PrefetchHooks Function()
    >;
typedef $$LocalAgingContextTableCreateCompanionBuilder =
    LocalAgingContextCompanion Function({
      required String userId,
      Value<String?> notes,
      Value<SyncState> syncState,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalAgingContextTableUpdateCompanionBuilder =
    LocalAgingContextCompanion Function({
      Value<String> userId,
      Value<String?> notes,
      Value<SyncState> syncState,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalAgingContextTableFilterComposer
    extends Composer<_$AppDatabase, $LocalAgingContextTable> {
  $$LocalAgingContextTableFilterComposer({
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

class $$LocalAgingContextTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalAgingContextTable> {
  $$LocalAgingContextTableOrderingComposer({
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

class $$LocalAgingContextTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalAgingContextTable> {
  $$LocalAgingContextTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, int> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalAgingContextTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalAgingContextTable,
          LocalAgingContextData,
          $$LocalAgingContextTableFilterComposer,
          $$LocalAgingContextTableOrderingComposer,
          $$LocalAgingContextTableAnnotationComposer,
          $$LocalAgingContextTableCreateCompanionBuilder,
          $$LocalAgingContextTableUpdateCompanionBuilder,
          (
            LocalAgingContextData,
            BaseReferences<
              _$AppDatabase,
              $LocalAgingContextTable,
              LocalAgingContextData
            >,
          ),
          LocalAgingContextData,
          PrefetchHooks Function()
        > {
  $$LocalAgingContextTableTableManager(
    _$AppDatabase db,
    $LocalAgingContextTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAgingContextTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalAgingContextTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalAgingContextTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAgingContextCompanion(
                userId: userId,
                notes: notes,
                syncState: syncState,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<String?> notes = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAgingContextCompanion.insert(
                userId: userId,
                notes: notes,
                syncState: syncState,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalAgingContextTable, LocalAgingContextData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalAgingContextTable,
                    LocalAgingContextData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalAgingContextTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalAgingContextTable,
      LocalAgingContextData,
      $$LocalAgingContextTableFilterComposer,
      $$LocalAgingContextTableOrderingComposer,
      $$LocalAgingContextTableAnnotationComposer,
      $$LocalAgingContextTableCreateCompanionBuilder,
      $$LocalAgingContextTableUpdateCompanionBuilder,
      (
        LocalAgingContextData,
        BaseReferences<
          _$AppDatabase,
          $LocalAgingContextTable,
          LocalAgingContextData
        >,
      ),
      LocalAgingContextData,
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
  $$LocalFertilityObservationsTableTableManager
  get localFertilityObservations =>
      $$LocalFertilityObservationsTableTableManager(
        _db,
        _db.localFertilityObservations,
      );
  $$LocalPregnancyContextTableTableManager get localPregnancyContext =>
      $$LocalPregnancyContextTableTableManager(_db, _db.localPregnancyContext);
  $$LocalAgingContextTableTableManager get localAgingContext =>
      $$LocalAgingContextTableTableManager(_db, _db.localAgingContext);
}
