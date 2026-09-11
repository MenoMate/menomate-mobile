import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Record-level sync state stored on each user-data row.
/// No separate outbox table: every queued operation maps 1:1 to a row.
enum SyncState {
  synced,
  pending,
  conflict,
}

/// Local profile/preferences. One row per user.
/// Mirrors only the fields the offline Settings screen reads/writes.
class LocalProfiles extends Table {
  TextColumn get userId => text()();
  TextColumn get name => text().nullable()();
  IntColumn get usualCycleDays => integer().nullable()();
  IntColumn get usualPeriodDays => integer().nullable()();
  TextColumn get theme => text().nullable()();
  TextColumn get units => text().nullable()();
  IntColumn get syncState =>
      intEnum<SyncState>().withDefault(Constant(SyncState.synced.index))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {userId};
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
  IntColumn get pain => integer().withDefault(const Constant(0))();
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

@DriftDatabase(
  tables: [
    LocalProfiles,
    LocalCycles,
    LocalDailyLogs,
    LocalSymptoms,
    PredictionCache,
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
  int get schemaVersion => 1;

  /// Removes every user-scoped row. Called on sign-out so User B can never
  /// see User A's local records or cached prediction.
  Future<void> clearAllUserData() async {
    await transaction(() async {
      await delete(localProfiles).go();
      await delete(localCycles).go();
      await delete(localDailyLogs).go();
      await delete(localSymptoms).go();
      await delete(predictionCache).go();
    });
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
