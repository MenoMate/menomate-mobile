import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/sync_policy.dart';
import '../models/reproductive.dart';
import '../providers/reproductive_providers.dart';
import 'fertility_estimate_card.dart';

/// Contextual reproductive-health block for Home (Phase 5).
///
/// Home stays glanceable: this block renders nothing unless something is
/// actively relevant —
/// - a pregnancy-context summary when pregnancy mode is on,
/// - the fertility estimate card when an estimate is AVAILABLE or
///   LOW_CONFIDENCE (other estimate states live on their own surfaces),
/// - a quiet indicator when the user explicitly recorded aging context.
///
/// No medical alerts, no diagnosis language, no always-on panels.
class ReproductiveHomeBlock extends ConsumerWidget {
  const ReproductiveHomeBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregnancyAsync = ref.watch(pregnancyProvider);
    final estimateAsync = ref.watch(fertilityEstimateProvider);
    final agingAsync = ref.watch(agingProvider);

    final pregnancy = pregnancyAsync.value?.dataOrNull;
    final estimateState = estimateAsync.value;
    final estimate = estimateState?.dataOrNull;
    final aging = agingAsync.value?.dataOrNull;

    final showPregnancy = pregnancy?.isActive == true;
    final showEstimate =
        !showPregnancy &&
        estimate != null &&
        (estimate.status == FertilityEstimateStatus.available ||
            estimate.status == FertilityEstimateStatus.lowConfidence);
    final showAging = aging?.hasContext == true;

    if (!showPregnancy && !showEstimate && !showAging) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showPregnancy) ...[
          _PregnancySummaryCard(context: pregnancy!),
          const SizedBox(height: 12),
        ],
        if (showEstimate) ...[
          FertilityEstimateCard(state: estimateState!),
          const SizedBox(height: 12),
        ],
        if (showAging) ...[
          _AgingIndicatorCard(notes: aging!.notes),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _PregnancySummaryCard extends StatelessWidget {
  final PregnancyContext context;

  const _PregnancySummaryCard({required this.context});

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      return DateFormat('MMM d').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final c = this.context;
    final detail = c.hasGestationalAge
        ? '${c.gestationalAgeWeeks}w ${c.gestationalAgeDays}d · due ${_formatDate(c.estimatedDueDate)}'
        : (c.estimatedDueDate != null
              ? 'Due ${_formatDate(c.estimatedDueDate)}'
              : 'Dating not recorded yet');
    return Semantics(
      label:
          'Pregnancy mode is on. ${c.hasGestationalAge ? 'Gestational age ${c.gestationalAgeWeeks} weeks ${c.gestationalAgeDays} days. ' : ''}Estimated due date ${c.estimatedDueDate ?? 'not recorded'}.',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Row(
          children: [
            Icon(
              Icons.pregnant_woman_rounded,
              size: 22,
              color: colorScheme.onSurface,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pregnancy mode is on',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push('/profile/health/pregnancy-mode'),
              child: const Text('View'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgingIndicatorCard extends StatelessWidget {
  final String? notes;

  const _AgingIndicatorCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          const Icon(Icons.spa_outlined, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Reproductive-aging context saved',
              style: TextStyle(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/profile/health/aging'),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}
