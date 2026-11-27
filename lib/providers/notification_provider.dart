import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/router.dart';
import '../data/sync_policy.dart';
import '../models/cycle.dart';
import '../services/notification_service.dart';
import 'cycle_provider.dart';
import 'data_providers.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationPrefsNotifier extends Notifier<NotificationPreferences> {
  static const _kDailyEnabled = 'notif_daily_enabled';
  static const _kDailyHour = 'notif_daily_hour';
  static const _kDailyMinute = 'notif_daily_minute';
  static const _kSkipIfLogged = 'notif_skip_if_logged';
  static const _kPeriodEnabled = 'notif_period_enabled';
  static const _kPeriodLeadDays = 'notif_period_lead_days';
  static const _kPeriodHour = 'notif_period_hour';
  static const _kPeriodMinute = 'notif_period_minute';
  static const _kPeriodMode = 'notif_period_mode';

  bool _initialized = false;

  @override
  NotificationPreferences build() {
    if (!_initialized) {
      _initialized = true;
      Future.microtask(_loadAndInit);
    }
    return const NotificationPreferences();
  }

  Future<void> _loadAndInit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final loaded = NotificationPreferences(
        dailyCheckInEnabled: prefs.getBool(_kDailyEnabled) ?? false,
        dailyHour: prefs.getInt(_kDailyHour) ?? 20,
        dailyMinute: prefs.getInt(_kDailyMinute) ?? 0,
        skipIfLoggedToday: prefs.getBool(_kSkipIfLogged) ?? true,
        periodReminderEnabled: prefs.getBool(_kPeriodEnabled) ?? false,
        periodLeadDays: prefs.getInt(_kPeriodLeadDays) ?? 2,
        periodHour: prefs.getInt(_kPeriodHour) ?? 9,
        periodMinute: prefs.getInt(_kPeriodMinute) ?? 0,
        periodMode: prefs.getString(_kPeriodMode) == 'dailyUntilPredicted'
            ? PeriodReminderMode.dailyUntilPredicted
            : PeriodReminderMode.oneShot,
      );
      state = loaded;

      final service = ref.read(notificationServiceProvider);
      await service.initialize(
        onTap: (payload) {
          if (payload != null && payload.startsWith('/')) {
            try {
              ref.read(routerProvider).go(payload);
            } catch (e) {
              debugPrint('Notification tap navigation failed: $e');
            }
          }
        },
      );
      await syncNow();
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  Future<void> _persist(NotificationPreferences next) async {
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDailyEnabled, next.dailyCheckInEnabled);
    await prefs.setInt(_kDailyHour, next.dailyHour);
    await prefs.setInt(_kDailyMinute, next.dailyMinute);
    await prefs.setBool(_kSkipIfLogged, next.skipIfLoggedToday);
    await prefs.setBool(_kPeriodEnabled, next.periodReminderEnabled);
    await prefs.setInt(_kPeriodLeadDays, next.periodLeadDays);
    await prefs.setInt(_kPeriodHour, next.periodHour);
    await prefs.setInt(_kPeriodMinute, next.periodMinute);
    await prefs.setString(
      _kPeriodMode,
      next.periodMode == PeriodReminderMode.dailyUntilPredicted
          ? 'dailyUntilPredicted'
          : 'oneShot',
    );
  }

  Future<bool> _ensurePermissionIfEnabling(bool enabling) async {
    if (!enabling) return true;
    final service = ref.read(notificationServiceProvider);
    final granted = await service.requestPermission();
    if (!granted) {
      state = state.copyWith(permissionDenied: true);
      return false;
    }
    if (state.permissionDenied) {
      state = state.copyWith(permissionDenied: false);
    }
    return true;
  }

  Future<void> setDailyCheckInEnabled(bool enabled) async {
    if (!await _ensurePermissionIfEnabling(enabled)) return;
    await _persist(state.copyWith(dailyCheckInEnabled: enabled));
    await syncNow();
  }

  Future<void> setDailyTime(int hour, int minute) async {
    await _persist(state.copyWith(dailyHour: hour, dailyMinute: minute));
    await syncNow();
  }

  Future<void> setSkipIfLoggedToday(bool skip) async {
    await _persist(state.copyWith(skipIfLoggedToday: skip));
    await syncNow();
  }

  Future<void> setPeriodReminderEnabled(bool enabled) async {
    if (!await _ensurePermissionIfEnabling(enabled)) return;
    await _persist(state.copyWith(periodReminderEnabled: enabled));
    await syncNow();
  }

  Future<void> setPeriodLeadDays(int days) async {
    await _persist(state.copyWith(periodLeadDays: days));
    await syncNow();
  }

  Future<void> setPeriodTime(int hour, int minute) async {
    await _persist(state.copyWith(periodHour: hour, periodMinute: minute));
    await syncNow();
  }

  Future<void> setPeriodMode(PeriodReminderMode mode) async {
    await _persist(state.copyWith(periodMode: mode));
    await syncNow();
  }

  /// Called immediately when the user logs a period start so no stale
  /// upcoming-period reminder fires.
  Future<void> cancelPeriodRemindersOnPeriodStart() async {
    try {
      await ref.read(notificationServiceProvider).cancelPeriodReminders();
    } catch (e) {
      debugPrint('Failed to cancel period reminders: $e');
    }
  }

  Future<void> syncNow() async {
    try {
      final service = ref.read(notificationServiceProvider);
      final cycleAsync = ref.read(currentCycleProvider);
      final cycleState = cycleAsync.value;
      final isStale =
          cycleState is PendingSync || cycleState is ConflictState;
      final CurrentCycleResponse? cycle = switch (cycleState) {
        Fresh(data: final d) => d,
        Cached(data: final d) => d,
        PendingSync(data: final d) => d,
        ConflictState(data: final d) => d,
        _ => null,
      };

      bool hasLoggedToday = false;
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        final now = DateTime.now();
        final todayIso =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        final recent = await ref
            .read(dailyLogRepositoryProvider)
            .loadRecentLocalLogs(userId, days: 2);
        hasLoggedToday = recent.any((l) => l.logDate == todayIso);
      }

      await service.syncSchedules(
        prefs: state,
        cycle: cycle,
        isPredictionStale: isStale,
        hasLoggedToday: hasLoggedToday,
      );
    } catch (e) {
      debugPrint('Notification sync failed: $e');
    }
  }
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsNotifier, NotificationPreferences>(
      NotificationPrefsNotifier.new,
    );
