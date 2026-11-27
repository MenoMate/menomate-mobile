import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/notification_provider.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _hasLoggedToday = false;
  bool _canExactAlarm = true;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refreshState);
    // Keep "Next reminder" accurate when the current minute rolls over.
    _clockTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshState() async {
    final notifier = ref.read(notificationPrefsProvider.notifier);
    final logged = await notifier.hasLoggedToday();
    final exact =
        await ref.read(notificationServiceProvider).canScheduleExactAlarms();
    if (mounted) {
      setState(() {
        _hasLoggedToday = logged;
        _canExactAlarm = exact;
      });
    }
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<TimeOfDay?> _showWheelTimePicker({
    required TimeOfDay initialTime,
    required String title,
  }) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: title.toUpperCase(),
      initialEntryMode: TimePickerEntryMode.dial,
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(notificationPrefsProvider);
    final notifier = ref.read(notificationPrefsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    final now = DateTime.now();
    final nextFire = prefs.dailyCheckInEnabled
        ? NotificationService.nextDailyCheckInDateTime(
            now: now,
            hour: prefs.dailyHour,
            minute: prefs.dailyMinute,
            skipIfLoggedToday: prefs.skipIfLoggedToday,
            hasLoggedToday: _hasLoggedToday,
          )
        : null;

    final isToday = nextFire != null &&
        nextFire.year == now.year &&
        nextFire.month == now.month &&
        nextFire.day == now.day;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders & Notifications'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (prefs.permissionDenied)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Notification permission was not granted. Enable notifications in your device settings to receive reminders.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              if (!_canExactAlarm &&
                  (prefs.dailyCheckInEnabled || prefs.periodReminderEnabled))
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.alarm_on_outlined,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Exact alarm access is off in Android settings. Reminders may be delayed by a few minutes.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(notificationServiceProvider)
                              .requestExactAlarmsPermission();
                          await notifier.syncNow();
                          await _refreshState();
                        },
                        child: const Text('Allow'),
                      ),
                    ],
                  ),
                ),
              _SettingsCard(
                colorScheme: colorScheme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Daily check-in reminder',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Daily at ${_formatTime(prefs.dailyHour, prefs.dailyMinute)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.secondary,
                        ),
                      ),
                      value: prefs.dailyCheckInEnabled,
                      onChanged: (v) async {
                        await notifier.setDailyCheckInEnabled(v);
                        await _refreshState();
                      },
                    ),
                    if (prefs.dailyCheckInEnabled) ...[
                      if (nextFire != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            isToday
                                ? 'Next reminder: Today at ${DateFormat.jm().format(nextFire)}'
                                : prefs.skipIfLoggedToday && _hasLoggedToday
                                    ? 'Next reminder: Tomorrow at ${DateFormat.jm().format(nextFire)} (already logged today)'
                                    : 'Next reminder: Tomorrow at ${DateFormat.jm().format(nextFire)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await _showWheelTimePicker(
                            initialTime: TimeOfDay(
                              hour: prefs.dailyHour,
                              minute: prefs.dailyMinute,
                            ),
                            title: 'Daily Check-in Time',
                          );
                          if (picked != null) {
                            await notifier.setDailyTime(
                              picked.hour,
                              picked.minute,
                            );
                            await _refreshState();
                          }
                        },
                        icon: const Icon(Icons.schedule, size: 18),
                        label: Text(
                          'Change time (${_formatTime(prefs.dailyHour, prefs.dailyMinute)})',
                        ),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Skip if already logged today',
                          style: TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          'Turn off to always fire at the selected time even after logging today.',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.secondary,
                          ),
                        ),
                        value: prefs.skipIfLoggedToday,
                        onChanged: (v) async {
                          await notifier.setSkipIfLoggedToday(v);
                          await _refreshState();
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                colorScheme: colorScheme,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Upcoming period reminder',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        prefs.periodReminderEnabled
                            ? '${prefs.periodLeadDays} day(s) before estimated start at ${_formatTime(prefs.periodHour, prefs.periodMinute)}'
                            : 'Only scheduled when a valid forecast is available',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.secondary,
                        ),
                      ),
                      value: prefs.periodReminderEnabled,
                      onChanged: (v) async {
                        await notifier.setPeriodReminderEnabled(v);
                        await _refreshState();
                      },
                    ),
                    if (prefs.periodReminderEnabled) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Notify before estimated start',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: NotificationService.allowedLeadDays.map((d) {
                          return ChoiceChip(
                            label: Text('${d}d'),
                            selected: prefs.periodLeadDays == d,
                            onSelected: (_) => notifier.setPeriodLeadDays(d),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('One-shot'),
                            selected:
                                prefs.periodMode == PeriodReminderMode.oneShot,
                            onSelected: (_) => notifier
                                .setPeriodMode(PeriodReminderMode.oneShot),
                          ),
                          ChoiceChip(
                            label: const Text('Daily until predicted'),
                            selected:
                                prefs.periodMode ==
                                PeriodReminderMode.dailyUntilPredicted,
                            onSelected: (_) => notifier.setPeriodMode(
                              PeriodReminderMode.dailyUntilPredicted,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await _showWheelTimePicker(
                            initialTime: TimeOfDay(
                              hour: prefs.periodHour,
                              minute: prefs.periodMinute,
                            ),
                            title: 'Period Reminder Time',
                          );
                          if (picked != null) {
                            await notifier.setPeriodTime(
                              picked.hour,
                              picked.minute,
                            );
                          }
                        },
                        icon: const Icon(Icons.schedule, size: 18),
                        label: Text(
                          'Time: ${_formatTime(prefs.periodHour, prefs.periodMinute)}',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  await notifier.sendTestNotification();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test notification sent.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Send test notification now'),
              ),
              const SizedBox(height: 12),
              Text(
                'Reminders are scheduled locally on your device. Battery-saving modes on Android or iOS may slightly delay delivery.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.secondary.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final Widget child;

  const _SettingsCard({required this.colorScheme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline),
      ),
      child: child,
    );
  }
}
