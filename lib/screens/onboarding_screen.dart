import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/device_timezone.dart';
import '../core/format.dart' show kMonthNames;
import '../data/app_database.dart' show toIsoDate;
import '../data/sync_policy.dart';
import '../models/health_context.dart' show validateBirthPair;
import '../models/onboarding.dart';
import '../providers/cycle_provider.dart';
import '../providers/data_providers.dart';
import '../providers/offline_mode_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

/// First-run personalization: name, last period (start + Ongoing/Ended
/// status), and optional usual lengths. Single atomic API call; the backend
/// remains authoritative for all date bounds and completion semantics.
/// Client validation only prevents obvious invalid requests early.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _cycleDaysController = TextEditingController();
  final _periodDaysController = TextEditingController();
  final _birthYearController = TextEditingController();

  int? _dobMonth;

  DateTime? _lastPeriodStart;
  DateTime? _lastPeriodEnd;
  // Fail-closed default: an end date must be explicitly chosen; switching
  // to Ongoing clears it (§2.6).
  PeriodStatus _status = PeriodStatus.ended;
  // Optional preference shared by both paths; defaults to metric and can
  // be changed later in Settings. Never a medical question.
  String _selectedUnits = 'metric';
  Map<String, String> _errors = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cycleDaysController.dispose();
    _periodDaysController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final today = _today();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_lastPeriodStart ?? today)
          : (_lastPeriodEnd ?? _lastPeriodStart ?? today),
      // No arbitrary historical lower bound: users may have much older
      // history and must never invent a recent date (§2.7).
      firstDate: isStart
          ? DateTime(1900)
          : (_lastPeriodStart ?? DateTime(1900)),
      // The backend rejects future user-local dates, so they are not
      // offered. End cannot precede the chosen start.
      lastDate: today,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _lastPeriodStart = picked;
        } else {
          _lastPeriodEnd = picked;
        }
        _errors.remove(isStart ? 'start' : 'end');
      });
    }
  }

  void _setStatus(PeriodStatus status) {
    setState(() {
      _status = status;
      if (status == PeriodStatus.ongoing) {
        // Ended → Ongoing clears the end date; no separate clear button.
        _lastPeriodEnd = null;
      }
      _errors.remove('end');
    });
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  /// Device zone for the onboarding payload. Never blocks submission:
  /// an unreachable or slow platform channel degrades to null and the
  /// backend falls back to the stored/UTC date anchor.
  Future<String?> _deviceZone() async {
    try {
      return await deviceTimeZoneId().timeout(const Duration(seconds: 3));
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    final cycleParsed = parseUsualCycleDays(_cycleDaysController.text);
    final periodParsed = parseUsualPeriodDays(_periodDaysController.text);
    final errors = validateOnboardingInput(
      name: _nameController.text,
      periodStart: _lastPeriodStart,
      status: _status,
      periodEnd: _lastPeriodEnd,
      usualCycle: cycleParsed,
      usualPeriod: periodParsed,
      today: DateTime.now(),
    );
    // Birth month/year is optional and validated as a pair, mirroring the
    // backend contract (both together or both blank). Reuses the same
    // fields the Profile screen edits — no new storage, no new logic.
    final birthYearRaw = _birthYearController.text.trim();
    final int? birthYear = birthYearRaw.isEmpty
        ? null
        : int.tryParse(birthYearRaw);
    if (birthYearRaw.isNotEmpty && birthYear == null) {
      errors['dob'] = 'Please enter a 4-digit birth year.';
    } else {
      final dobError = validateBirthPair(birthYear, _dobMonth);
      if (dobError != null) errors['dob'] = dobError;
    }
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }

    setState(() {
      _isLoading = true;
      _errors = {};
    });

    try {
      // Offline path: same questions, purely local writes. No account, no
      // network, no Supabase call of any kind.
      final offline = ref.read(isOfflineTrackingProvider);
      final userId = ref.read(currentUserIdProvider);
      if (offline && userId != null) {
        await ref.read(profileRepositoryProvider).saveProfile(userId, {
          'name': _nameController.text.trim(),
          'usual_cycle_days': cycleParsed.isValid ? cycleParsed.value : null,
          'usual_period_days': periodParsed.isValid ? periodParsed.value : null,
          'theme': ref.read(themeModeProvider) == ThemeMode.dark
              ? 'dark'
              : 'light',
          'units': _selectedUnits,
          'birth_year': birthYear,
          'birth_month': _dobMonth,
          'timezone': await _deviceZone(),
        }, localOnly: true);
        await ref
            .read(cycleRepositoryProvider)
            .storeLocalCycle(
              userId,
              periodStart: toIsoDate(_lastPeriodStart!),
              periodEnd: _status == PeriodStatus.ended && _lastPeriodEnd != null
                  ? toIsoDate(_lastPeriodEnd!)
                  : resolvePeriodEndIso(_status, null),
            );
        refreshAllAppData(ref);
        return;
      }

      final request = OnboardingRequest(
        name: _nameController.text.trim(),
        lastPeriodStart: toIsoDate(_lastPeriodStart!),
        lastPeriodEnd: _status == PeriodStatus.ended && _lastPeriodEnd != null
            ? toIsoDate(_lastPeriodEnd!)
            : resolvePeriodEndIso(_status, null),
        usualCycleDays: cycleParsed.isValid ? cycleParsed.value : null,
        usualPeriodDays: periodParsed.isValid ? periodParsed.value : null,
        // Persist the device zone atomically with onboarding so the
        // backend computes user-local dates from the very first request.
        timezone: await _deviceZone(),
      );

      final result = await ref
          .read(apiServiceProvider)
          .completeOnboarding(request);

      // Local-first persistence through the existing repositories: the
      // profile and first period survive restart and offline use. No
      // second cache, no new repository (§2.10).
      if (userId != null) {
        await ref
            .read(profileRepositoryProvider)
            .storeOnboardedProfile(result.profile);
        await ref
            .read(cycleRepositoryProvider)
            .storeOnboardedCycle(
              userId,
              serverId: result.periodId,
              periodStart: result.periodStart,
              periodEnd: result.periodEnd,
            );
        // Apply the optional extras (units, birth pair) on top of the
        // fresh server profile; a failed patch safely stays pending for
        // the next sync.
        final updated = await ref.read(profileRepositoryProvider).saveProfile(
          userId,
          {
            'units': _selectedUnits,
            'birth_year': birthYear,
            'birth_month': _dobMonth,
          },
        );
        ref
            .read(profileProvider.notifier)
            .setProfile(updated.dataOrNull ?? result.profile);
      } else {
        await ref.read(profileProvider.notifier).reload();
      }
      // No manual navigation: the router observes profile state and
      // transitions to home (§2.12).
    } on ValidationError catch (e) {
      _showMessage('Please check your entries. ${e.message}');
    } on Conflict catch (e) {
      // Already onboarded (e.g. another device finished first): reload so
      // the router can place the user correctly instead of stranding them.
      try {
        await ref.read(profileProvider.notifier).reload();
      } catch (_) {
        // Reload failure still leaves the message below; never mask it.
      }
      _showMessage(e.message);
    } on NetworkUnavailable {
      _showMessage('You\u2019re offline. Check your connection and try again.');
    } on AuthFailure {
      _showMessage('Your session expired. Please sign in again.');
    } on ServerError {
      _showMessage('Something went wrong. Please try again.');
    } catch (_) {
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Welcome to MenoMate')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Let\u2019s personalize your experience.',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'A few basics to start — the rest is optional and can wait.',
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'To get started',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'What should we call you?',
                border: const OutlineInputBorder(),
                errorText: _errors['name'],
              ),
              onChanged: (_) {
                if (_errors.containsKey('name')) {
                  setState(() => _errors.remove('name'));
                }
              },
            ),
            const SizedBox(height: 16),

            Text(
              'When did your last period start?',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _lastPeriodStart == null
                    ? 'Select start date'
                    : dateFormat.format(_lastPeriodStart!),
              ),
              onPressed: () => _selectDate(context, true),
            ),
            if (_errors.containsKey('start')) ...[
              const SizedBox(height: 4),
              Text(
                _errors['start']!,
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),

            Text('Has your last period ended?', style: textTheme.bodyMedium),
            const SizedBox(height: 8),
            SegmentedButton<PeriodStatus>(
              segments: const [
                ButtonSegment<PeriodStatus>(
                  value: PeriodStatus.ongoing,
                  label: Text('Ongoing'),
                  icon: Icon(Icons.more_horiz),
                ),
                ButtonSegment<PeriodStatus>(
                  value: PeriodStatus.ended,
                  label: Text('Ended'),
                  icon: Icon(Icons.check),
                ),
              ],
              selected: {_status},
              onSelectionChanged: (selected) => _setStatus(selected.first),
            ),
            if (_status == PeriodStatus.ended) ...[
              const SizedBox(height: 12),
              Text('When did it end?', style: textTheme.bodyMedium),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _lastPeriodEnd == null
                      ? 'Select end date'
                      : dateFormat.format(_lastPeriodEnd!),
                ),
                onPressed: () => _selectDate(context, false),
              ),
            ],
            if (_errors.containsKey('end')) ...[
              const SizedBox(height: 4),
              Text(
                _errors['end']!,
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 24),

            Text(
              'Nice to have — optional',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Skip anything you\u2019re not sure about — you can add it later in Profile.',
              style: textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _cycleDaysController,
                    decoration: InputDecoration(
                      labelText: 'Usual cycle length',
                      hintText: 'e.g. 28',
                      helperText: 'Days between periods. Leave blank if you\u2019re not sure.',
                      border: const OutlineInputBorder(),
                      errorText: _errors['cycle'],
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      if (_errors.containsKey('cycle')) {
                        setState(() => _errors.remove('cycle'));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _periodDaysController,
                    decoration: InputDecoration(
                      labelText: 'Usual period length',
                      hintText: 'e.g. 5',
                      helperText: 'Days bleeding lasts. Leave blank if you\u2019re not sure.',
                      border: const OutlineInputBorder(),
                      errorText: _errors['period'],
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      if (_errors.containsKey('period')) {
                        setState(() => _errors.remove('period'));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'Measurement units',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Used for temperature and health displays. '
              'You can change this later in Settings.',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'metric',
                  label: Text('Metric (°C)'),
                  icon: Icon(Icons.thermostat_outlined),
                ),
                ButtonSegment<String>(
                  value: 'imperial',
                  label: Text('Imperial (°F)'),
                  icon: Icon(Icons.thermostat),
                ),
              ],
              selected: {_selectedUnits},
              onSelectionChanged: (selected) =>
                  setState(() => _selectedUnits = selected.first),
            ),
            const SizedBox(height: 16),

            Text(
              'Birth month & year (optional)',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButton<int?>(
                    value: _dobMonth,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    hint: const Text('Month'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('—'),
                      ),
                      for (var i = 0; i < 12; i++)
                        DropdownMenuItem<int?>(
                          value: i + 1,
                          child: Text(kMonthNames[i]),
                        ),
                    ],
                    onChanged: (val) => setState(() {
                      _dobMonth = val;
                      _errors.remove('dob');
                    }),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _birthYearController,
                    decoration: InputDecoration(
                      labelText: 'Year',
                      hintText: 'e.g. 1990',
                      border: const OutlineInputBorder(),
                      errorText: _errors['dob'],
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      if (_errors.containsKey('dob')) {
                        setState(() => _errors.remove('dob'));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            if (ref.watch(isOfflineTrackingProvider)) ...[
              Text(
                'Your tracking data stays on this device. '
                'You can sign in later to sync it.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Complete onboarding',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            // Bottom breathing room so the CTA clears the keyboard area.
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
