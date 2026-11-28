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
  List<int> _pendingIds = const [];
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(_refreshState);
    // Keep "Next reminder" accurate when the current minute rolls over.
    _clockTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _refreshState();
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshState() async {
    final notifier = ref.read(notificationPrefsProvider.notifier);
    final service = ref.read(notificationServiceProvider);
    final logged = await notifier.hasLoggedToday();
    final exact = await service.canScheduleExactAlarms();
    final pending = await service.pendingNotificationIds();
    if (mounted) {
      setState(() {
        _hasLoggedToday = logged;
        _canExactAlarm = exact;
        _pendingIds = pending;
      });
    }
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<TimeOfDay?> _showDigitalSliderTimePicker({
    required TimeOfDay initialTime,
    required String title,
  }) {
    int hour12 = initialTime.hour % 12 == 0 ? 12 : initialTime.hour % 12;
    int minute = initialTime.minute;
    bool isPm = initialTime.hour >= 12;

    return showDialog<TimeOfDay>(
      context: context,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: scheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(color: scheme.outline),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Digital Material You pill readout + AM/PM toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _DigitalUnitBox(
                            text: hour12.toString().padLeft(2, '0'),
                            scheme: scheme,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              ':',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          _DigitalUnitBox(
                            text: minute.toString().padLeft(2, '0'),
                            scheme: scheme,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            children: [
                              _AmPmPill(
                                label: 'AM',
                                selected: !isPm,
                                scheme: scheme,
                                onTap: () => setDialogState(() => isPm = false),
                              ),
                              const SizedBox(height: 6),
                              _AmPmPill(
                                label: 'PM',
                                selected: isPm,
                                scheme: scheme,
                                onTap: () => setDialogState(() => isPm = true),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Hour slider
                      Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: Text(
                              'Hour',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.secondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: hour12.toDouble(),
                              min: 1,
                              max: 12,
                              divisions: 11,
                              onChanged: (v) =>
                                  setDialogState(() => hour12 = v.round()),
                            ),
                          ),
                        ],
                      ),
                      // Minute slider + fine steppers
                      Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: Text(
                              'Min',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.secondary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setDialogState(() {
                              minute = (minute - 1 + 60) % 60;
                            }),
                          ),
                          Expanded(
                            child: Slider(
                              value: minute.toDouble(),
                              min: 0,
                              max: 59,
                              divisions: 59,
                              onChanged: (v) =>
                                  setDialogState(() => minute = v.round()),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setDialogState(() {
                              minute = (minute + 1) % 60;
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () {
                              final hour24 = isPm
                                  ? (hour12 == 12 ? 12 : hour12 + 12)
                                  : (hour12 == 12 ? 0 : hour12);
                              Navigator.of(ctx).pop(
                                TimeOfDay(hour: hour24, minute: minute),
                              );
                            },
                            child: const Text('Set'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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

    final dailyPending =
        _pendingIds.contains(NotificationService.dailyCheckInId);

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
                          'Exact alarm access is off in Android settings. Reminders may be delayed by several minutes.',
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
                      Text(
                        'Device alarm status: ${dailyPending ? 'Scheduled' : 'Pending'} · Exact timing: ${_canExactAlarm ? 'Allowed' : 'Restricted by OS'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: () async {
                          final picked = await _showDigitalSliderTimePicker(
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
                          final picked = await _showDigitalSliderTimePicker(
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
                            await _refreshState();
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
                'Reminders are scheduled locally on your device. Battery-saving modes on Android or iOS may delay delivery if exact alarm access is restricted.',
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

class _DigitalUnitBox extends StatelessWidget {
  final String text;
  final ColorScheme scheme;

  const _DigitalUnitBox({required this.text, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _AmPmPill extends StatelessWidget {
  final String label;
  final bool selected;
  final ColorScheme scheme;
  final VoidCallback onTap;

  const _AmPmPill({
    required this.label,
    required this.selected,
    required this.scheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 48,
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? scheme.onPrimary : scheme.secondary,
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
