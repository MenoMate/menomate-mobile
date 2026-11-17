import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart' show toIsoDate;
import '../widgets/theme_atmosphere.dart';

/// Dedicated Log experience (not Home-dependent).
///
/// Organizes supported logging into categories with cards/chips/pickers,
/// date selection, and clear save/update/delete actions (handled in
/// `/logger`). Past entries remain editable; future entries stay clearly
/// future. Offline logging flows through Drift via the existing
/// repositories — this screen never touches APIs directly.
class LogHubScreen extends ConsumerStatefulWidget {
  const LogHubScreen({super.key});

  @override
  ConsumerState<LogHubScreen> createState() => _LogHubScreenState();
}

class _LogHubScreenState extends ConsumerState<LogHubScreen> {
  DateTime _date = DateTime.now();

  String get _iso => toIsoDate(_date);
  bool get _isFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final check = DateTime(_date.year, _date.month, _date.day);
    return check.isAfter(today);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  void _openLogger() => context.push('/logger?date=$_iso');

  void _openFertilityLogger() => context.push('/fertility-log?date=$_iso');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Log',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ThemeAtmosphereBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date selector.
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: colorScheme.onSurface,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEE, MMM d, yyyy').format(_date),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            if (_isFuture)
                              Text(
                                'Future entry — stays a future entry.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.secondary,
                                ),
                              )
                            else
                              Text(
                                'Tap to change date.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.secondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'What do you want to record?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _LogCategoryCard(
                icon: Icons.water_drop_outlined,
                title: 'Period',
                subtitle: 'Log or edit your period for this date.',
                actionLabel: 'Log period',
                onTap: _openLogger,
              ),
              _LogCategoryCard(
                icon: Icons.opacity_outlined,
                title: 'Flow',
                subtitle: 'Light, Medium, Heavy — pick what fits.',
                actionLabel: 'Log flow',
                onTap: _openLogger,
              ),
              _LogCategoryCard(
                icon: Icons.healing_outlined,
                title: 'Symptoms',
                subtitle: 'Track how you\u2019re feeling.',
                actionLabel: 'Log symptoms',
                onTap: _openLogger,
              ),
              _LogCategoryCard(
                icon: Icons.mood_outlined,
                title: 'Mood',
                subtitle: 'Log your mood.',
                actionLabel: 'Log mood',
                onTap: _openLogger,
              ),
              _LogCategoryCard(
                icon: Icons.note_add_outlined,
                title: 'Notes',
                subtitle: 'Add a personal note.',
                actionLabel: 'Add note',
                onTap: _openLogger,
              ),
              const SizedBox(height: 20),
              const Text(
                'Fertility signs',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Recorded separately from discharge — each sign is its own observation.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 12),
              _LogCategoryCard(
                icon: Icons.science_outlined,
                title: 'LH test',
                subtitle: 'Ovulation test strip result, as observed.',
                actionLabel: 'Log LH',
                onTap: _openFertilityLogger,
              ),
              _LogCategoryCard(
                icon: Icons.thermostat_outlined,
                title: 'Basal body temperature',
                subtitle: 'Morning resting temperature in °C.',
                actionLabel: 'Log temp',
                onTap: _openFertilityLogger,
              ),
              _LogCategoryCard(
                icon: Icons.water_drop_outlined,
                title: 'Cervical mucus',
                subtitle: 'Fertility observation for this date.',
                actionLabel: 'Log mucus',
                onTap: _openFertilityLogger,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/calendar/day?date=$_iso'),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('View day detail'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogCategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  const _LogCategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: scheme.onSurface),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: scheme.secondary),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onTap, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
