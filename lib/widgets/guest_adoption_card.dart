import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/format.dart';
import '../data/app_database.dart' show OfflineAdoptionCounts;
import '../providers/cycle_provider.dart';
import '../providers/data_providers.dart';
import '../providers/offline_mode_provider.dart';

/// One-time contextual Home card shown after an authenticated user has
/// completed onboarding when local records exist under `kOfflineUserId`.
/// Reuses [offlineAdoptionProvider] and [adoptOfflineDataIntoAccount] without
/// duplicating sync logic or touching local rows until the user consents.
class GuestAdoptionCard extends ConsumerStatefulWidget {
  const GuestAdoptionCard({super.key});

  @override
  ConsumerState<GuestAdoptionCard> createState() => _GuestAdoptionCardState();
}

class _GuestAdoptionCardState extends ConsumerState<GuestAdoptionCard> {
  bool _isAdopting = false;

  List<String> _summaryParts(OfflineAdoptionCounts counts) {
    final parts = <String>[
      if (counts.cycles > 0) formatDayCount(counts.cycles, 'cycle'),
      if (counts.logs > 0) formatDayCount(counts.logs, 'daily log'),
    ];
    if (counts.conditions > 0) {
      parts.add(formatDayCount(counts.conditions, 'condition'));
    }
    if (counts.medications > 0) {
      parts.add(formatDayCount(counts.medications, 'medication'));
    }
    if (counts.healthContext) parts.add('health notes');
    return parts;
  }

  Future<void> _importRecords() async {
    if (_isAdopting) return;
    setState(() => _isAdopting = true);
    try {
      final counts = await adoptOfflineDataIntoAccount(ref);
      if (!mounted) return;
      final parts = _summaryParts(counts);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            parts.isEmpty
                ? 'Local records imported into your account.'
                : 'Imported ${parts.join(' · ')} into your account.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Couldn\u2019t import your local records right now. They remain saved on this device.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdopting = false);
    }
  }

  Future<void> _dismissForNow() async {
    if (_isAdopting) return;
    final authId = ref.read(authUserIdProvider);
    if (authId != null) {
      await ref.read(offlineModeProvider.notifier).declineAdoption(authId);
    }
    ref.invalidate(offlineAdoptionProvider);
  }

  @override
  Widget build(BuildContext context) {
    final adoption = ref.watch(offlineAdoptionProvider).value;
    if (adoption == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final parts = _summaryParts(adoption);
    final summary = parts.isEmpty ? 'local records' : parts.join(' and ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.phonelink_setup_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Local records saved on this device',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'You have $summary from using MenoMate without an account. '
              'Import them into your account so they stay synced.',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.secondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isAdopting ? null : _importRecords,
                    child: _isAdopting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Review and import'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _isAdopting ? null : _dismissForNow,
                  child: const Text('Not now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
