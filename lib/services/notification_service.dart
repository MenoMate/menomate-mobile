import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/device_timezone.dart';
import '../models/cycle.dart';

enum PeriodReminderMode { oneShot, dailyUntilPredicted }

@immutable
class NotificationPreferences {
  final bool dailyCheckInEnabled;
  final int dailyHour;
  final int dailyMinute;
  final bool skipIfLoggedToday;

  final bool periodReminderEnabled;
  final int periodLeadDays;
  final int periodHour;
  final int periodMinute;
  final PeriodReminderMode periodMode;

  final bool permissionDenied;

  const NotificationPreferences({
    this.dailyCheckInEnabled = false,
    this.dailyHour = 20,
    this.dailyMinute = 0,
    this.skipIfLoggedToday = true,
    this.periodReminderEnabled = false,
    this.periodLeadDays = 2,
    this.periodHour = 9,
    this.periodMinute = 0,
    this.periodMode = PeriodReminderMode.oneShot,
    this.permissionDenied = false,
  });

  NotificationPreferences copyWith({
    bool? dailyCheckInEnabled,
    int? dailyHour,
    int? dailyMinute,
    bool? skipIfLoggedToday,
    bool? periodReminderEnabled,
    int? periodLeadDays,
    int? periodHour,
    int? periodMinute,
    PeriodReminderMode? periodMode,
    bool? permissionDenied,
  }) {
    return NotificationPreferences(
      dailyCheckInEnabled: dailyCheckInEnabled ?? this.dailyCheckInEnabled,
      dailyHour: dailyHour ?? this.dailyHour,
      dailyMinute: dailyMinute ?? this.dailyMinute,
      skipIfLoggedToday: skipIfLoggedToday ?? this.skipIfLoggedToday,
      periodReminderEnabled:
          periodReminderEnabled ?? this.periodReminderEnabled,
      periodLeadDays: periodLeadDays ?? this.periodLeadDays,
      periodHour: periodHour ?? this.periodHour,
      periodMinute: periodMinute ?? this.periodMinute,
      periodMode: periodMode ?? this.periodMode,
      permissionDenied: permissionDenied ?? this.permissionDenied,
    );
  }
}

/// Abstract scheduler interface so notification logic is 100% unit-testable
/// without platform channels.
abstract class NotificationScheduler {
  Future<bool> initialize(void Function(String? payload) onTap);
  Future<bool> requestPermission();
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
    required String channelId,
    required String channelName,
  });
  Future<void> scheduleOneShot({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
    required String channelId,
    required String channelName,
  });
  Future<void> cancel(int id);
  Future<void> cancelAll();
}

class FlutterLocalNotificationsScheduler implements NotificationScheduler {
  final FlutterLocalNotificationsPlugin _plugin;

  FlutterLocalNotificationsScheduler([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<bool> initialize(void Function(String? payload) onTap) async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    final initialized = await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) => onTap(details.payload),
    );
    return initialized ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    bool granted = true;
    final androidImpl =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final result = await androidImpl.requestNotificationsPermission();
      granted = result ?? true;
    }
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosImpl != null) {
      final result = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = granted && (result ?? false);
    }
    return granted;
  }

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
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
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
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();
}

class NotificationService {
  static const int dailyCheckInId = 1001;
  static const int periodReminderBaseId = 2001;
  static const int maxPeriodReminderIds = 10;

  static const String dailyChannelId = 'menomate_daily_checkin';
  static const String dailyChannelName = 'Daily Check-in Reminders';
  static const String periodChannelId = 'menomate_period_reminders';
  static const String periodChannelName = 'Upcoming Period Reminders';

  static const List<int> allowedLeadDays = [1, 2, 3, 5, 7];

  final NotificationScheduler _scheduler;
  bool _tzInitialized = false;
  bool _pluginInitialized = false;

  NotificationService({NotificationScheduler? scheduler})
      : _scheduler = scheduler ?? FlutterLocalNotificationsScheduler();

  Future<void> ensureTimezoneInitialized([String? overrideTzName]) async {
    if (!_tzInitialized) {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    }
    final tzName = overrideTzName ?? await deviceTimeZoneId();
    if (tzName != null && tzName.isNotEmpty) {
      try {
        tz.setLocalLocation(tz.getLocation(tzName));
        return;
      } catch (_) {
        // Unknown timezone name — fall back to UTC safely.
      }
    }
    tz.setLocalLocation(tz.UTC);
  }

  Future<void> initialize({
    required void Function(String? payload) onTap,
    String? overrideTzName,
  }) async {
    await ensureTimezoneInitialized(overrideTzName);
    if (!_pluginInitialized) {
      await _scheduler.initialize(onTap);
      _pluginInitialized = true;
    }
  }

  Future<bool> requestPermission() => _scheduler.requestPermission();

  Future<void> cancelDailyReminder() => _scheduler.cancel(dailyCheckInId);

  Future<void> cancelPeriodReminders() async {
    for (int i = 0; i < maxPeriodReminderIds; i++) {
      await _scheduler.cancel(periodReminderBaseId + i);
    }
  }

  Future<void> cancelAll() => _scheduler.cancelAll();

  /// Reconciles local notification schedules with current preferences,
  /// prediction state, and today's log state.
  Future<void> syncSchedules({
    required NotificationPreferences prefs,
    required CurrentCycleResponse? cycle,
    required bool isPredictionStale,
    required bool hasLoggedToday,
    DateTime? nowOverride,
    String? overrideTzName,
  }) async {
    await ensureTimezoneInitialized(overrideTzName);

    final now = nowOverride != null
        ? tz.TZDateTime.from(nowOverride, tz.local)
        : tz.TZDateTime.now(tz.local);

    // 1. Daily Check-in Reminder
    if (!prefs.dailyCheckInEnabled) {
      await cancelDailyReminder();
    } else {
      var candidate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        prefs.dailyHour,
        prefs.dailyMinute,
      );
      if (!candidate.isAfter(now) ||
          (prefs.skipIfLoggedToday && hasLoggedToday)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      await _scheduler.scheduleDaily(
        id: dailyCheckInId,
        title: 'Daily Symptom Check-in',
        body: 'Take a moment to log how you feel today in MenoMate.',
        scheduledDate: candidate,
        payload: '/logger',
        channelId: dailyChannelId,
        channelName: dailyChannelName,
      );
    }

    // 2. Upcoming Period Reminder (always clear old IDs first)
    await cancelPeriodReminders();

    if (!prefs.periodReminderEnabled ||
        cycle == null ||
        isPredictionStale ||
        cycle.predictionStatus == 'awaiting_next_start' ||
        cycle.predictedNextPeriod == null) {
      return;
    }

    final predicted = cycle.predictedNextPeriod!;
    final todayDate = DateTime(now.year, now.month, now.day);
    final predictedDate =
        DateTime(predicted.year, predicted.month, predicted.day);

    // Do not schedule if predicted date is today or in the past, or if a
    // period was already started today.
    if (!predictedDate.isAfter(todayDate)) return;
    if (cycle.latestPeriodStart != null) {
      final start = cycle.latestPeriodStart!;
      if (start.year == todayDate.year &&
          start.month == todayDate.month &&
          start.day == todayDate.day) {
        return;
      }
    }

    final leadDays = prefs.periodLeadDays.clamp(1, 7);
    final startWindowDate = predictedDate.subtract(Duration(days: leadDays));

    if (prefs.periodMode == PeriodReminderMode.oneShot) {
      final fireAt = tz.TZDateTime(
        tz.local,
        startWindowDate.year,
        startWindowDate.month,
        startWindowDate.day,
        prefs.periodHour,
        prefs.periodMinute,
      );
      if (fireAt.isAfter(now)) {
        await _scheduler.scheduleOneShot(
          id: periodReminderBaseId,
          title: 'Upcoming Period Estimate',
          body: leadDays == 1
              ? 'Your next period is estimated to start tomorrow.'
              : 'Your next period is estimated in about $leadDays days.',
          scheduledDate: fireAt,
          payload: '/home',
          channelId: periodChannelId,
          channelName: periodChannelName,
        );
      }
    } else {
      // Finite daily sequence from max(todayDate, startWindowDate) through
      // the day before predictedDate (capped at maxPeriodReminderIds).
      int slot = 0;
      DateTime cursor =
          startWindowDate.isBefore(todayDate) ? todayDate : startWindowDate;
      while (cursor.isBefore(predictedDate) && slot < maxPeriodReminderIds) {
        final fireAt = tz.TZDateTime(
          tz.local,
          cursor.year,
          cursor.month,
          cursor.day,
          prefs.periodHour,
          prefs.periodMinute,
        );
        if (fireAt.isAfter(now)) {
          final daysLeft = predictedDate.difference(cursor).inDays;
          await _scheduler.scheduleOneShot(
            id: periodReminderBaseId + slot,
            title: 'Upcoming Period Estimate',
            body: daysLeft == 1
                ? 'Your next period is estimated to start tomorrow.'
                : 'Your next period is estimated in about $daysLeft days.',
            scheduledDate: fireAt,
            payload: '/home',
            channelId: periodChannelId,
            channelName: periodChannelName,
          );
          slot++;
        }
        cursor = cursor.add(const Duration(days: 1));
      }
    }
  }
}
