import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:menomate_mobile/content/local_insights_engine.dart';
import 'package:menomate_mobile/core/theme.dart';
import 'package:menomate_mobile/data/app_database.dart';
import 'package:menomate_mobile/data/repositories/cycle_repository.dart';
import 'package:menomate_mobile/data/sync_policy.dart';
import 'package:menomate_mobile/models/cycle.dart';
import 'package:menomate_mobile/models/daily_log.dart';
import 'package:menomate_mobile/providers/care_consent_provider.dart';
import 'package:menomate_mobile/providers/care_session_provider.dart';
import 'package:menomate_mobile/services/api_service.dart';
import 'package:menomate_mobile/services/notification_service.dart';
import 'package:menomate_mobile/widgets/interactive_cycle_ring.dart';
import 'package:timezone/timezone.dart' as tz;

class _NoopApiService extends ApiService {
  _NoopApiService() : super(Dio());
}

class _ScheduledCall {
  final int id;
  final String title;
  final String body;
  final tz.TZDateTime scheduledDate;
  final String payload;
  final bool daily;

  _ScheduledCall({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.payload,
    required this.daily,
  });
}

class _FakeNotificationScheduler implements NotificationScheduler {
  bool permissionResult = true;
  bool initialized = false;
  void Function(String? payload)? onTapCallback;
  final List<_ScheduledCall> scheduled = [];
  final List<int> cancelledIds = [];
  bool cancelledAll = false;

  @override
  Future<bool> initialize(void Function(String? payload) onTap) async {
    initialized = true;
    onTapCallback = onTap;
    return true;
  }

  @override
  Future<bool> requestPermission() async => permissionResult;

  @override
  Future<bool> canScheduleExactAlarms() async => true;

  @override
  Future<bool> requestExactAlarmsPermission() async => true;

  @override
  Future<List<int>> pendingNotificationIds() async =>
      scheduled.map((e) => e.id).toList();

  @override
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
    required String channelId,
    required String channelName,
  }) async {
    scheduled.add(
      _ScheduledCall(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: payload,
        daily: true,
      ),
    );
  }

  @override
  Future<void> scheduleOneShot({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
    required String channelId,
    required String channelName,
  }) async {
    scheduled.add(
      _ScheduledCall(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: payload,
        daily: false,
      ),
    );
  }

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelledAll = true;
    scheduled.clear();
  }

  @override
  Future<void> showTestNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
    required String channelId,
    required String channelName,
  }) async {}
}

void main() {
  group('Stage 1 — PredictionCache persistence & offline countdown', () {
    test(
      'persists predictedCycleLength, computes dynamic countdown, and marks awaiting_next_start when past',
      () async {
        final db = AppDatabase.memory();
        addTearDown(db.close);
        final repo = CycleRepository(db, _NoopApiService());

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final start = today.subtract(const Duration(days: 10));
        final futurePred = today.add(const Duration(days: 22));

        await db.into(db.localCycles).insert(
              LocalCyclesCompanion.insert(
                localId: 'c-1',
                userId: 'u1',
                periodStart: start.toIso8601String().split('T').first,
              ),
            );
        await db.into(db.predictionCache).insert(
              PredictionCacheCompanion.insert(
                userId: 'u1',
                predictedNextPeriod: Value(
                  futurePred.toIso8601String().split('T').first,
                ),
                predictedCycleLength: const Value(32),
                daysUntilNextPeriod: const Value(99), // intentionally stale fixed value
                predictionStatus: const Value('upcoming'),
                predictionConfidence: const Value('moderate'),
                averageCycleLength: const Value(30),
                averagePeriodLength: const Value(5),
              ),
            );

        final state = await repo.loadCurrentLocal('u1');
        expect(state, isA<Fresh<CurrentCycleResponse?>>());
        final current = (state as Fresh<CurrentCycleResponse?>).data!;
        expect(current.predictedCycleLength, 32);
        expect(current.daysUntilNextPeriod, 22);
        expect(current.predictionStatus, 'upcoming');

        // Past predicted date -> awaiting_next_start without fabricating negative/default days
        final pastPred = today.subtract(const Duration(days: 3));
        await (db.update(db.predictionCache)
              ..where((t) => t.userId.equals('u1')))
            .write(
              PredictionCacheCompanion(
                predictedNextPeriod: Value(
                  pastPred.toIso8601String().split('T').first,
                ),
              ),
            );
        final pastState =
            await repo.loadCurrentLocal('u1') as Fresh<CurrentCycleResponse?>;
        expect(pastState.data!.predictionStatus, 'awaiting_next_start');
        expect(pastState.data!.daysUntilNextPeriod, 0);
      },
    );
  });

  group('Stage 2 — InteractiveCycleRing exploration & return to today', () {
    testWidgets(
      'displays current day & estimated phase, explores via slider/+/-, and returns to today',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: MenoMateTheme.sakuraTheme,
            home: const Scaffold(
              body: Center(
                child: InteractiveCycleRing(
                  currentDay: 3,
                  cycleLength: 28,
                  periodLength: 5,
                  phase: 'menstrual',
                ),
              ),
            ),
          ),
        );

        expect(find.text('Day 3'), findsOneWidget);
        expect(find.textContaining('Menstrual'), findsAtLeastNWidgets(2));
        expect(find.text('Return to Day 3'), findsNothing);

        // Tap + button to explore Day 4
        await tester.tap(find.byTooltip('Next cycle day'));
        await tester.pumpAndSettle();

        expect(find.text('Exploring'), findsOneWidget);
        expect(find.text('Day 4'), findsOneWidget);
        expect(find.text('Return to Day 3'), findsOneWidget);

        // Move slider to Day 14 (Est. Ovulation)
        final slider = tester.widget<Slider>(find.byType(Slider));
        slider.onChanged?.call(14);
        await tester.pumpAndSettle();

        expect(find.text('Day 14'), findsOneWidget);
        expect(find.textContaining('Est. Ovulation'), findsAtLeastNWidgets(2));

        // Return to Day 3
        await tester.tap(find.text('Return to Day 3'));
        await tester.pumpAndSettle();

        expect(find.text('Day 3'), findsOneWidget);
        expect(find.text('Return to Day 3'), findsNothing);
      },
    );
  });

  group('Stage 3 — Local insights engine & backend parity', () {
    test(
      'separates cycle lengths from period durations, preserves pain=null vs 0, and matches backend fixture',
      () {
        final today = DateTime(2026, 6, 15);
        final c1Start = today.subtract(const Duration(days: 14));
        final c2Start = today.subtract(const Duration(days: 4));

        final cycles = [
          CycleResponse(
            id: 1,
            userId: 'u1',
            periodStart: c1Start,
            periodEnd: c1Start.add(const Duration(days: 4)), // 5 days
            periodLengthDays: 5,
            createdAt: c1Start,
            updatedAt: c1Start,
          ),
          CycleResponse(
            id: 2,
            userId: 'u1',
            periodStart: c2Start,
            periodEnd: c2Start.add(const Duration(days: 3)), // 4 days
            periodLengthDays: 4,
            createdAt: c2Start,
            updatedAt: c2Start,
          ),
        ];

        final logs = [
          DailyLogResponse(
            id: 1,
            userId: 'u1',
            logDate: toIsoDate(c1Start),
            pain: 2,
            mood: const ['calm'],
            symptoms: const [SymptomItem(symptomType: 'cramps', severity: 2)],
          ),
          DailyLogResponse(
            id: 2,
            userId: 'u1',
            logDate: toIsoDate(c1Start.add(const Duration(days: 1))),
            pain: null, // must not be imputed as 0
            symptoms: const [SymptomItem(symptomType: 'cramps', severity: 0)],
          ),
          DailyLogResponse(
            id: 3,
            userId: 'u1',
            logDate: toIsoDate(c2Start.add(const Duration(days: 1))),
            pain: 7,
            mood: const ['irritable'],
            symptoms: const [SymptomItem(symptomType: 'cramps', severity: 4)],
          ),
          DailyLogResponse(
            id: 4,
            userId: 'u1',
            logDate: toIsoDate(c2Start.add(const Duration(days: 2))),
            pain: 8,
            symptoms: const [],
          ),
        ];

        final summary = computeLocalPatterns(
          cycles: cycles,
          logs: logs,
          today: today,
          windowDays: 90,
        );

        expect(summary.loggedDays, 4);
        expect(summary.effectiveWindowDays, 15);
        expect(summary.explicitZeroPainDays, 0);
        expect(summary.painSeries.length, 3);
        expect(summary.recordedPeriodLengths, [5, 4]);
        expect(summary.observedCycleLengths, isEmpty); // 10 days < 15d min cycle length
        expect(summary.symptomByCycleBucket['cramps']?['Days 1-2'], 3);
        expect(summary.unratedSymptomCount, 1);
      },
    );
  });

  group('Stage 4 — Local notification scheduling & safety guards', () {
    test(
      'schedules daily check-in, one-shot/finite period reminders, skips stale/missing forecasts, and cancels on period start',
      () async {
        final fake = _FakeNotificationScheduler();
        final service = NotificationService(scheduler: fake);
        String? tappedPayload;
        await service.initialize(
          onTap: (p) => tappedPayload = p,
          overrideTzName: 'Asia/Kolkata',
        );

        final now = DateTime(2026, 6, 15, 8, 0);
        final predicted = DateTime(2026, 6, 20);
        final cycle = CurrentCycleResponse(
          hasData: true,
          currentCycleDay: 24,
          phase: 'luteal',
          isBleeding: false,
          latestPeriodStart: DateTime(2026, 5, 22),
          predictedCycleLength: 29,
          predictedNextPeriod: predicted,
          daysUntilNextPeriod: 5,
          predictionStatus: 'upcoming',
          predictionConfidence: 'moderate',
        );

        // 1. Daily check-in + one-shot period reminder (2d lead -> June 18 09:00)
        await service.syncSchedules(
          prefs: const NotificationPreferences(
            dailyCheckInEnabled: true,
            dailyHour: 20,
            dailyMinute: 30,
            skipIfLoggedToday: true,
            periodReminderEnabled: true,
            periodLeadDays: 2,
            periodHour: 9,
            periodMinute: 0,
            periodMode: PeriodReminderMode.oneShot,
          ),
          cycle: cycle,
          isPredictionStale: false,
          hasLoggedToday: false,
          nowOverride: now,
          overrideTzName: 'Asia/Kolkata',
        );

        expect(fake.scheduled.length, 2);
        expect(fake.scheduled[0].id, NotificationService.dailyCheckInId);
        expect(fake.scheduled[0].daily, true);
        expect(fake.scheduled[0].payload, '/logger');
        expect(fake.scheduled[0].scheduledDate.location.name, 'Asia/Kolkata');

        expect(fake.scheduled[1].id, NotificationService.periodReminderBaseId);
        expect(fake.scheduled[1].daily, false);
        expect(fake.scheduled[1].payload, '/home');
        expect(fake.scheduled[1].scheduledDate.day, 18);

        // Tap callback routes payload
        fake.onTapCallback?.call('/logger');
        expect(tappedPayload, '/logger');

        // 2. Daily until predicted -> finite one-shot series (June 18 and June 19)
        fake.scheduled.clear();
        await service.syncSchedules(
          prefs: const NotificationPreferences(
            dailyCheckInEnabled: false,
            periodReminderEnabled: true,
            periodLeadDays: 2,
            periodHour: 9,
            periodMinute: 0,
            periodMode: PeriodReminderMode.dailyUntilPredicted,
          ),
          cycle: cycle,
          isPredictionStale: false,
          hasLoggedToday: false,
          nowOverride: now,
          overrideTzName: 'Asia/Kolkata',
        );

        expect(fake.scheduled.length, 2);
        expect(fake.scheduled.every((c) => !c.daily), true);
        expect(fake.scheduled.map((c) => c.scheduledDate.day).toList(), [18, 19]);

        // 3. Stale prediction -> does NOT schedule period reminders
        fake.scheduled.clear();
        await service.syncSchedules(
          prefs: const NotificationPreferences(
            periodReminderEnabled: true,
            periodLeadDays: 2,
          ),
          cycle: cycle,
          isPredictionStale: true,
          hasLoggedToday: false,
          nowOverride: now,
          overrideTzName: 'Asia/Kolkata',
        );
        expect(fake.scheduled, isEmpty);

        // 4. Cancel on period start clears period ID range
        fake.cancelledIds.clear();
        await service.cancelPeriodReminders();
        expect(
          fake.cancelledIds,
          List.generate(
            NotificationService.maxPeriodReminderIds,
            (i) => NotificationService.periodReminderBaseId + i,
          ),
        );

        // 5. nextDailyCheckInDateTime: fires today if skipIfLoggedToday=false even if logged
        final at218 = DateTime(2026, 6, 15, 2, 18);
        final fireToday = NotificationService.nextDailyCheckInDateTime(
          now: at218,
          hour: 2,
          minute: 19,
          skipIfLoggedToday: false,
          hasLoggedToday: true,
        );
        expect(fireToday, DateTime(2026, 6, 15, 2, 19));

        final skippedToTomorrow = NotificationService.nextDailyCheckInDateTime(
          now: at218,
          hour: 2,
          minute: 19,
          skipIfLoggedToday: true,
          hasLoggedToday: true,
        );
        expect(skippedToTomorrow, DateTime(2026, 6, 16, 2, 19));

        // 6. Legacy Android timezone alias ('Asia/Calcutta') resolves to 'Asia/Kolkata'
        await service.ensureTimezoneInitialized('Asia/Calcutta');
        expect(service.currentTimezoneName, 'Asia/Kolkata');
      },
    );
  });

  group('Stage 5 — Care privacy consent & category serialization', () {
    test('buildCareRequest encodes explicit consent and allowed categories', () {
      final unconsented = buildCareRequest(
        text: 'What helps cramps?',
        intent: 'pain_help',
        priorTurns: const [],
      );
      expect(unconsented.toJson()['consent_granted'], false);
      expect(unconsented.toJson().containsKey('allowed_categories'), false);

      final consented = buildCareRequest(
        text: 'Summarize my patterns',
        intent: 'pattern_summary',
        priorTurns: const [],
        consentGranted: true,
        allowedCategories: const [
          CarePrivacyCategories.cycles,
          CarePrivacyCategories.dailyLogs,
        ],
      );
      expect(consented.toJson()['consent_granted'], true);
      expect(
        consented.toJson()['allowed_categories'],
        ['cycles', 'daily_logs'],
      );
    });
  });
}
