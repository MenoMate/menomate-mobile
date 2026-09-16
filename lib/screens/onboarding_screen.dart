import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/device_timezone.dart';
import '../data/app_database.dart' show toIsoDate;
import '../data/sync_policy.dart';
import '../models/onboarding.dart';
import '../providers/data_providers.dart';
import '../providers/profile_provider.dart';
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

  DateTime? _lastPeriodStart;
  DateTime? _lastPeriodEnd;
  // Fail-closed default: an end date must be explicitly chosen; switching
  // to Ongoing clears it (§2.6).
  PeriodStatus _status = PeriodStatus.ended;
  Map<String, String> _errors = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cycleDaysController.dispose();
    _periodDaysController.dispose();
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
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  /// Device zone for the onboarding payload. Never blocks submission:
  /// an unreachable or slow platform channel degrades to null and the
  /// backend falls back to the stored/UTC date anchor.
  Future<String?> _deviceZone() async {
    try {
      return await deviceTimeZoneId().timeout(
        const Duration(seconds: 3),
      );
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
    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      return;
    }

    setState(() {
      _isLoading = true;
      _errors = {};
    });

    try {
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

      final result =
          await ref.read(apiServiceProvider).completeOnboarding(request);

      // Local-first persistence through the existing repositories: the
      // profile and first period survive restart and offline use. No
      // second cache, no new repository (§2.10).
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        await ref
            .read(profileRepositoryProvider)
            .storeOnboardedProfile(result.profile);
        await ref.read(cycleRepositoryProvider).storeOnboardedCycle(
              userId,
              serverId: result.periodId,
              periodStart: result.periodStart,
              periodEnd: result.periodEnd,
            );
        ref.read(profileProvider.notifier).setProfile(result.profile);
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
            const SizedBox(height: 24),

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
            const SizedBox(height: 24),

            Text('Last period', style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 12),

            Text('When did your last period start?',
                style: textTheme.bodyMedium),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(_lastPeriodStart == null
                  ? 'Select start date'
                  : dateFormat.format(_lastPeriodStart!)),
              onPressed: () => _selectDate(context, true),
            ),
            if (_errors.containsKey('start')) ...[
              const SizedBox(height: 4),
              Text(_errors['start']!,
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  )),
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
                label: Text(_lastPeriodEnd == null
                    ? 'Select end date'
                    : dateFormat.format(_lastPeriodEnd!)),
                onPressed: () => _selectDate(context, false),
              ),
            ],
            if (_errors.containsKey('end')) ...[
              const SizedBox(height: 4),
              Text(_errors['end']!,
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  )),
            ],
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _cycleDaysController,
                    decoration: InputDecoration(
                      labelText: 'Usual cycle length',
                      hintText: 'e.g. 28',
                      helperText:
                          'Days between periods. Leave blank if you\u2019re not sure.',
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
                      helperText:
                          'Days bleeding lasts. Leave blank if you\u2019re not sure.',
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
            const SizedBox(height: 32),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Complete onboarding',
                    style: TextStyle(fontSize: 16)),
              ),
            // Bottom breathing room so the CTA clears the keyboard area.
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
