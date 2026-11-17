import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Stable identity for local-only tracking rows. Deliberately NOT a UUID:
/// it can never collide with a Supabase user id, is never sent to Supabase
/// Auth, and never creates an account of any kind. Lives here (not in a
/// provider) so both the database helpers and the Riverpod layer can share
/// it without an import cycle.
const kOfflineUserId = 'offline-local';

/// Adoptable offline data, counted inside the adoption transaction so an
/// offer built from these numbers is reliable — never an estimate.
/// `healthContext` is true when the offline singleton carries any
/// user-provided field.
typedef OfflineAdoptionCounts = ({
  int cycles,
  int logs,
  int conditions,
  int medications,
  bool healthContext,
});

/// Record-level sync state stored on each user-data row.
/// No separate outbox table: every queued operation maps 1:1 to a row.
enum SyncState { synced, pending, conflict }

/// Local profile/preferences. One row per user.
/// Mirrors only the fields the offline Settings screen reads/writes.
class LocalProfiles extends Table {
  TextColumn get userId => text()();
  TextColumn get name => text().nullable()();
  IntColumn get usualCycleDays => integer().nullable()();
  IntColumn get usualPeriodDays => integer().nullable()();
  TextColumn get theme => text().nullable()();
  TextColumn get units => text().nullable()();
  // Canonical IANA timezone, synced to the server profile. Null until the
  // device reports it; offline-safe (pending rows flush via syncPending).
  TextColumn get timezone => text().nullable()();
  // Month/year precision only — no birth day is ever asked for or stored.
  // Null pair means "not provided" (mirrors the backend pair contract).
  IntColumn get birthYear => integer().nullable()();
  IntColumn get birthMonth => integer().nullable()();
  IntColumn get syncState =>
      intEnum<SyncState>().withDefault(Constant(SyncState.synced.index))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userId};
}

/// Singleton health context per user: contraception / pregnancy selections
/// plus free-text notes. All content columns optional; the row merely
/// records what the user chose to provide. Replaced wholesale on sync
/// (PUT), never merged with server inference — there is none.
class LocalHealthContext extends Table {
  TextColumn get userId => text()();
  TextColumn get contraceptionMethod => text().nullable()();
  TextColumn get contraceptionNote => text().nullable()();
  TextColumn get pregnancyContext => text().nullable()();
  TextColumn get healthNotes => text().nullable()();
  IntColumn get syncState =>
      intEnum<SyncState>().withDefault(Constant(SyncState.synced.index))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userId};
}

/// User-reported health conditions. Presence in this table is the user's
/// own statement — never a detection or diagnosis. `localId` is the safe
/// temporary identity for offline-created rows; `serverId` is filled when
/// the backend create succeeds. `isDeleted` is a sync tombstone: deletes
/// apply locally immediately and are pushed as DELETE on the next pass.
class LocalConditions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get localId => text().unique()();
  TextColumn get userId => text()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get code => text()();
  TextColumn get customLabel => text().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get syncState =>
      intEnum<SyncState>().withDefault(Constant(SyncState.synced.index))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// User-recorded medications/treatments. Names are free text and duplicates
/// are allowed by backend design; nothing is ever inferred from them.
/// Sync mechanics mirror [LocalConditions].
class LocalMedications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get localId => text().unique()();
  TextColumn get userId => text()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get name => text()();
  TextColumn get note => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get syncState =>
      intEnum<SyncState>().withDefault(Constant(SyncState.synced.index))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Local cycles. Dates stored as ISO `yyyy-MM-dd` text for date-only
/// semantics (no timezone pitfalls).
/// `localId` is the safe temporary identity for offline-created rows;
/// `serverId` is filled when the backend create succeeds (reconcile).
/// `id` is a stable local integer so offline-only rows can satisfy the
/// API models' required int ids (exposed as `-id` until reconciled).
class LocalCycles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get localId => text().unique()();
  TextColumn get userId => text()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get periodStart => text()();
  TextColumn get periodEnd => text().nullable()();
  IntColumn get syncState =>
      intEnum<SyncState>().withDefault(Constant(SyncState.synced.index))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Local daily logs. Natural key (user_id, log_date) matches the backend
/// upsert contract, so repeated offline edits converge to one server record.
class LocalDailyLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get logDate => text()();
  // Nullable pain: null = not provided; 0 = explicitly logged no pain.
  // (v3 migration from non-null default-0; historical 0s preserved as-is.)
  IntColumn get pain => integer().nullable()();
  TextColumn get mood => text().nullable()();
  TextColumn get flow => text().nullable()();
  TextColumn get discharge => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get syncState =>
      intEnum<SyncState>().withDefault(Constant(SyncState.synced.index))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {userId, logDate},
  ];
}

/// Symptom children of a local daily log. Synced together with the parent
/// log row; no independent sync state.
class LocalSymptoms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text()();
  TextColumn get logDate => text()();
  TextColumn get symptomType => text()();
  IntColumn get severity => integer().withDefault(const Constant(0))();
}

/// Minimal verbatim cache of server-computed prediction fields — exactly the
/// fields Home/History/Calendar render offline. Display only; Flutter never
/// computes prediction values from these or from local rows.
class PredictionCache extends Table {
  TextColumn get userId => text()();
  TextColumn get phase => text().nullable()();
  TextColumn get predictedNextPeriod => text().nullable()();
  IntColumn get daysUntilNextPeriod => integer().nullable()();
  TextColumn get predictionStatus => text().nullable()();
  TextColumn get predictionConfidence => text().nullable()();
  RealColumn get averageCycleLength => real().nullable()();
  RealColumn get averagePeriodLength => real().nullable()();
  DateTimeColumn get fetchedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userId};
}

/// User-measured fertility observations (Phase 2 OBSERVED facts: LH test,
/// BBT, cervical mucus). Deliberately separate from `LocalDailyLogs`
/// (generic discharge scale) and `LocalSymptoms` (fixed taxonomy), mirroring
/// the backend's separate `fertility_observations` table.
///
/// Grain mirrors the backend upsert contract: one live row per
/// (user, date, type). Re-posting the same triple overwrites
/// deterministically, so repeated offline edits converge to one server
/// record. `localId` is the safe temporary identity for offline-created
/// rows; `serverId` is filled when the backend create/upsert succeeds.
/// `isDeleted` is a sync tombstone: deletes apply locally immediately and
/// are pushed as DELETE on the next pass.
///
/// No DB-level unique triple is declared (a pending tombstone must be able
/// to coexist with its replacement until the push converges); the
/// repository enforces one live row per triple in code.
class LocalFertilityObservations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get localId => text().unique()();
  TextColumn get userId => text()();
  IntColumn get serverId => integer().nullable()();
  TextColumn get observationDate => text()();
  TextColumn get observationType => text()();
  TextColumn get lhResult => text().nullable()();
  RealColumn get bbtCelsius => real().nullable()();
  TextColumn get mucusCategory => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get note => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get syncState =>
      intEnum<SyncState>().withDefault(Constant(SyncState.synced.index))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Explicit user-controlled pregnancy mode + dating basis (Phase 3).
/// Singleton per user: absence means pregnancy mode was never entered;
/// `isActive = false` retains history with mode off (DELETE erases it).
///
/// Stored dating fields are verbatim user/clinician input (PUT
/// full-replacement, never merged). The `edd*` / gestational-age / `asOf`
/// columns are a verbatim cache of the last server-derived dating display —
/// exactly the fields pregnancy surfaces render offline. Display only;
/// Flutter never computes dating values (same precedent as
/// [PredictionCache]). The cached derivation is always presented with its
/// [asOfDate] so stale values are never shown as current without provenance.
class LocalPregnancyContext extends Table {
  TextColumn get userId => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get datingSource => text().nullable()();
  TextColumn get estimatedDueDate => text().nullable()();
  TextColumn get lmpDate => text().nullable()();
  TextColumn get confirmationDate => text().nullable()();
  TextColumn get datingNote => text().nullable()();
  TextColumn get eddStatus => text().nullable()();
  TextColumn get eddLabel => text().nullable()();
  TextColumn get datingConfidence => text().nullable()();
  IntColumn get gestationalAgeTotalDays => integer().nullable()();
  IntColumn get gestationalAgeWeeks => integer().nullable()();
  IntColumn get gestationalAgeDays => integer().nullable()();
  IntColumn get daysUntilDue => integer().nullable()();
  TextColumn get asOfDate => text().nullable()();
  TextColumn get timezoneName => text().nullable()();
  IntColumn get syncState =>
      intEnum<SyncState>().withDefault(Constant(SyncState.synced.index))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userId};
}

/// Explicit user-declared reproductive-aging context (Phase 4). Singleton
/// free-text note, stored verbatim and never parsed into medical facts.
/// Absence (or NULL notes) means no recorded context. Clearing is via PUT
/// with notes null (full-replacement); there is no PATCH/DELETE surface.
/// Carries no staging vocabulary by design — none is invented.
class LocalAgingContext extends Table {
  TextColumn get userId => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get syncState =>
      intEnum<SyncState>().withDefault(Constant(SyncState.synced.index))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userId};
}

@DriftDatabase(
  tables: [
    LocalProfiles,
    LocalCycles,
    LocalDailyLogs,
    LocalSymptoms,
    PredictionCache,
    LocalHealthContext,
    LocalConditions,
    LocalMedications,
    LocalFertilityObservations,
    LocalPregnancyContext,
    LocalAgingContext,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Production constructor: file-backed SQLite in the app documents dir.
  /// `path_provider` is used ONLY for this path resolution.
  static Future<AppDatabase> openFile(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');
    return AppDatabase(NativeDatabase.createInBackground(file));
  }

  /// Test constructor: in-memory database, same schema.
  static AppDatabase memory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v1 -> v2: nullable profile timezone column (offline-safe;
      // existing rows keep NULL until the device syncs its zone).
      if (from < 2) {
        await m.addColumn(localProfiles, localProfiles.timezone);
      }
      // v2 -> v3: daily-log pain becomes nullable so "not provided"
      // (NULL) is distinct from "explicitly logged no pain" (0).
      // Historical 0s are preserved untouched (never reinterpreted).
      if (from < 3) {
        await m.alterTable(
          TableMigration(
            localDailyLogs,
            newColumns: [localDailyLogs.pain],
            // v2 rows are all non-null by the old constraint, so a
            // plain cast preserves every value into the nullable column.
            columnTransformer: {
              localDailyLogs.pain: localDailyLogs.pain.cast<int>(),
            },
          ),
        );
      }
      // v3 -> v4: V1 Health Context foundation. New nullable profile DOB
      // columns (existing rows keep NULL = "not provided") plus three new
      // tables; no existing table is altered beyond the additive columns.
      if (from < 4) {
        await m.addColumn(localProfiles, localProfiles.birthYear);
        await m.addColumn(localProfiles, localProfiles.birthMonth);
        await m.createTable(localHealthContext);
        await m.createTable(localConditions);
        await m.createTable(localMedications);
      }
      // v4 -> v5: Phase 5 reproductive health (fertility observations,
      // pregnancy mode, aging context). Three new tables only; no existing
      // table is altered. Additive and safe: existing rows untouched.
      if (from < 5) {
        await m.createTable(localFertilityObservations);
        await m.createTable(localPregnancyContext);
        await m.createTable(localAgingContext);
      }
    },
  );

  /// Whether any local user-data row is still awaiting sync (or was
  /// rejected and needs review). Used to warn before destructive wipes
  /// such as sign-out. Symptom rows and the prediction cache carry no
  /// independent sync state: symptoms flush with their parent log, and
  /// the cache is server-derived display data that is safe to rebuild.
  /// Health context rows (including delete tombstones) do carry sync
  /// state, so they participate here like every other user-data row.
  Future<bool> hasUnsyncedData() async {
    final pending = SyncState.pending.index;
    final conflict = SyncState.conflict.index;
    final profileHit =
        await (selectOnly(localProfiles)
              ..addColumns([localProfiles.userId])
              ..where(
                localProfiles.syncState.equals(pending) |
                    localProfiles.syncState.equals(conflict),
              )
              ..limit(1))
            .getSingleOrNull();
    if (profileHit != null) return true;
    final cycleHit =
        await (selectOnly(localCycles)
              ..addColumns([localCycles.id])
              ..where(
                localCycles.syncState.equals(pending) |
                    localCycles.syncState.equals(conflict),
              )
              ..limit(1))
            .getSingleOrNull();
    if (cycleHit != null) return true;
    final logHit =
        await (selectOnly(localDailyLogs)
              ..addColumns([localDailyLogs.id])
              ..where(
                localDailyLogs.syncState.equals(pending) |
                    localDailyLogs.syncState.equals(conflict),
              )
              ..limit(1))
            .getSingleOrNull();
    if (logHit != null) return true;
    final contextHit =
        await (selectOnly(localHealthContext)
              ..addColumns([localHealthContext.userId])
              ..where(
                localHealthContext.syncState.equals(pending) |
                    localHealthContext.syncState.equals(conflict),
              )
              ..limit(1))
            .getSingleOrNull();
    if (contextHit != null) return true;
    final conditionHit =
        await (selectOnly(localConditions)
              ..addColumns([localConditions.id])
              ..where(
                localConditions.syncState.equals(pending) |
                    localConditions.syncState.equals(conflict),
              )
              ..limit(1))
            .getSingleOrNull();
    if (conditionHit != null) return true;
    final medicationHit =
        await (selectOnly(localMedications)
              ..addColumns([localMedications.id])
              ..where(
                localMedications.syncState.equals(pending) |
                    localMedications.syncState.equals(conflict),
              )
              ..limit(1))
            .getSingleOrNull();
    if (medicationHit != null) return true;
    final observationHit =
        await (selectOnly(localFertilityObservations)
              ..addColumns([localFertilityObservations.id])
              ..where(
                localFertilityObservations.syncState.equals(pending) |
                    localFertilityObservations.syncState.equals(conflict),
              )
              ..limit(1))
            .getSingleOrNull();
    if (observationHit != null) return true;
    final pregnancyHit =
        await (selectOnly(localPregnancyContext)
              ..addColumns([localPregnancyContext.userId])
              ..where(
                localPregnancyContext.syncState.equals(pending) |
                    localPregnancyContext.syncState.equals(conflict),
              )
              ..limit(1))
            .getSingleOrNull();
    if (pregnancyHit != null) return true;
    final agingHit =
        await (selectOnly(localAgingContext)
              ..addColumns([localAgingContext.userId])
              ..where(
                localAgingContext.syncState.equals(pending) |
                    localAgingContext.syncState.equals(conflict),
              )
              ..limit(1))
            .getSingleOrNull();
    return agingHit != null;
  }

  /// How much offline-created data could move into an account. Counts are
  /// taken inside the adoption transaction, so an offer built from these
  /// numbers is reliable — never an estimate. `healthContext` is true when
  /// the offline singleton carries any user-provided field.
  Future<OfflineAdoptionCounts> offlineAdoptableCounts() async {
    final cycles =
        await (selectOnly(localCycles)
              ..addColumns([localCycles.id])
              ..where(localCycles.userId.equals(kOfflineUserId)))
            .get();
    final logs =
        await (selectOnly(localDailyLogs)
              ..addColumns([localDailyLogs.id])
              ..where(localDailyLogs.userId.equals(kOfflineUserId)))
            .get();
    final conditions =
        await (selectOnly(localConditions)
              ..addColumns([localConditions.id])
              ..where(localConditions.userId.equals(kOfflineUserId)))
            .get();
    final medications =
        await (selectOnly(localMedications)
              ..addColumns([localMedications.id])
              ..where(localMedications.userId.equals(kOfflineUserId)))
            .get();
    final context = await (select(
      localHealthContext,
    )..where((t) => t.userId.equals(kOfflineUserId))).getSingleOrNull();
    return (
      cycles: cycles.length,
      logs: logs.length,
      conditions: conditions.length,
      medications: medications.length,
      healthContext:
          context != null &&
          (context.contraceptionMethod != null ||
              context.contraceptionNote != null ||
              context.pregnancyContext != null ||
              context.healthNotes != null),
    );
  }

  /// Moves offline-created tracking rows (cycles, daily logs + their
  /// symptoms, health conditions, medications, the health context
  /// singleton, fertility observations, and the pregnancy/aging singletons)
  /// into [newUserId] after explicit user consent. Invariant:
  /// rows under [kOfflineUserId] never carry a `serverId` (sync only ever
  /// runs for authenticated ids), so adoption only ever creates fresh
  /// server records or hits the existing per-row conflict path — it can
  /// never PATCH over another record. Values, timestamps, and sync states
  /// are preserved untouched. The offline profile and prediction rows do
  /// NOT move: the account profile stays authoritative (callers disclose
  /// that display preferences reset). Returns the adopted row counts.
  ///
  /// The returned counts keep the Phase 1 shape (reproductive rows ride the
  /// same consent without changing the offer numbers); see
  /// [reproductiveAdoptableCounts] for the reproductive share.
  Future<OfflineAdoptionCounts> adoptOfflineData(String newUserId) async {
    return transaction(() async {
      final cycles = await (select(
        localCycles,
      )..where((t) => t.userId.equals(kOfflineUserId))).get();
      final logs = await (select(
        localDailyLogs,
      )..where((t) => t.userId.equals(kOfflineUserId))).get();
      final conditions = await (select(
        localConditions,
      )..where((t) => t.userId.equals(kOfflineUserId))).get();
      final medications = await (select(
        localMedications,
      )..where((t) => t.userId.equals(kOfflineUserId))).get();
      final context = await (select(
        localHealthContext,
      )..where((t) => t.userId.equals(kOfflineUserId))).getSingleOrNull();
      final hasContext =
          context != null &&
          (context.contraceptionMethod != null ||
              context.contraceptionNote != null ||
              context.pregnancyContext != null ||
              context.healthNotes != null);
      final observations = await (select(
        localFertilityObservations,
      )..where((t) => t.userId.equals(kOfflineUserId))).get();
      final pregnancy = await (select(
        localPregnancyContext,
      )..where((t) => t.userId.equals(kOfflineUserId))).getSingleOrNull();
      final aging = await (select(
        localAgingContext,
      )..where((t) => t.userId.equals(kOfflineUserId))).getSingleOrNull();
      final hasReproductive =
          observations.isNotEmpty ||
          pregnancy != null ||
          (aging != null && aging.notes != null);
      if (cycles.isEmpty &&
          logs.isEmpty &&
          conditions.isEmpty &&
          medications.isEmpty &&
          !hasContext &&
          !hasReproductive) {
        return (
          cycles: 0,
          logs: 0,
          conditions: 0,
          medications: 0,
          healthContext: false,
        );
      }
      await (update(localCycles)..where((t) => t.userId.equals(kOfflineUserId)))
          .write(LocalCyclesCompanion(userId: Value(newUserId)));
      await (update(localDailyLogs)
            ..where((t) => t.userId.equals(kOfflineUserId)))
          .write(LocalDailyLogsCompanion(userId: Value(newUserId)));
      await (update(localSymptoms)
            ..where((t) => t.userId.equals(kOfflineUserId)))
          .write(LocalSymptomsCompanion(userId: Value(newUserId)));
      await (update(localConditions)
            ..where((t) => t.userId.equals(kOfflineUserId)))
          .write(LocalConditionsCompanion(userId: Value(newUserId)));
      await (update(localMedications)
            ..where((t) => t.userId.equals(kOfflineUserId)))
          .write(LocalMedicationsCompanion(userId: Value(newUserId)));
      await (update(localHealthContext)
            ..where((t) => t.userId.equals(kOfflineUserId)))
          .write(LocalHealthContextCompanion(userId: Value(newUserId)));
      await (update(localFertilityObservations)
            ..where((t) => t.userId.equals(kOfflineUserId)))
          .write(LocalFertilityObservationsCompanion(userId: Value(newUserId)));
      await (update(localPregnancyContext)
            ..where((t) => t.userId.equals(kOfflineUserId)))
          .write(LocalPregnancyContextCompanion(userId: Value(newUserId)));
      await (update(localAgingContext)
            ..where((t) => t.userId.equals(kOfflineUserId)))
          .write(LocalAgingContextCompanion(userId: Value(newUserId)));
      await (delete(
        localProfiles,
      )..where((t) => t.userId.equals(kOfflineUserId))).go();
      await (delete(
        predictionCache,
      )..where((t) => t.userId.equals(kOfflineUserId))).go();
      return (
        cycles: cycles.length,
        logs: logs.length,
        conditions: conditions.length,
        medications: medications.length,
        healthContext: hasContext,
      );
    });
  }

  /// Removes every user-scoped row. Called on sign-out so User B can never
  /// see User A's local records or cached prediction. Health context rows
  /// are user-scoped health data and are wiped exactly like everything else.
  Future<void> clearAllUserData() async {
    await transaction(() async {
      await delete(localProfiles).go();
      await delete(localCycles).go();
      await delete(localDailyLogs).go();
      await delete(localSymptoms).go();
      await delete(predictionCache).go();
      await delete(localHealthContext).go();
      await delete(localConditions).go();
      await delete(localMedications).go();
      await delete(localFertilityObservations).go();
      await delete(localPregnancyContext).go();
      await delete(localAgingContext).go();
    });
  }

  /// Reproductive share of offline-created data (fertility observations,
  /// pregnancy singleton presence, recorded aging notes). Counts are taken
  /// outside any transaction; callers use them for honest post-adoption
  /// reporting, not for the adoption offer itself (see [adoptOfflineData]).
  Future<({int observations, bool pregnancy, bool aging})>
  reproductiveAdoptableCounts() async {
    final observations =
        await (selectOnly(localFertilityObservations)
              ..addColumns([localFertilityObservations.id])
              ..where(localFertilityObservations.userId.equals(kOfflineUserId)))
            .get();
    final pregnancy = await (select(
      localPregnancyContext,
    )..where((t) => t.userId.equals(kOfflineUserId))).getSingleOrNull();
    final aging = await (select(
      localAgingContext,
    )..where((t) => t.userId.equals(kOfflineUserId))).getSingleOrNull();
    return (
      observations: observations.length,
      pregnancy: pregnancy != null,
      aging: aging != null && aging.notes != null,
    );
  }
}

/// Date-only helpers shared by repositories. All local dates are stored and
/// compared as ISO `yyyy-MM-dd` strings using device-local calendar parts —
/// never UTC-shifted datetimes. These helpers perform display/storage
/// formatting only; they compute no prediction semantics.
String toIsoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

String todayIso() => toIsoDate(DateTime.now());

DateTime parseIsoDate(String iso) => DateTime.parse(iso);

/// Whole-day difference `later - earlier` for ISO date strings.
/// Used ONLY for display labels (Day N, observed tile intervals).
int isoDayDifference(String earlierIso, String laterIso) =>
    parseIsoDate(laterIso).difference(parseIsoDate(earlierIso)).inDays;
