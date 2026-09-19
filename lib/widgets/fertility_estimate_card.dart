import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../data/sync_policy.dart';
import '../models/reproductive.dart';
import '../providers/reproductive_providers.dart';
import 'offline_banner.dart';

/// Server-computed fertility estimate presentation (Phase 2 contract).
///
/// Renders the backend estimate verbatim with estimate framing and the
/// safety disclaimer. Dated fertile-window/ovulation values appear ONLY
/// when the status is AVAILABLE with server-provided dates — every other
/// state shows no dates (never fabricated):
/// - LOW_CONFIDENCE: cautious wording, variability acknowledgment.
/// - INSUFFICIENT_DATA: empty state with logging guidance.
/// - SUPPRESSED: neutral copy, no medical implication.
///
/// Banned language (safe/unsafe days, guaranteed fertile/infertile days,
/// contraception guidance) never appears on this surface.
class FertilityEstimateCard extends ConsumerWidget {
  /// Overrides the watched provider value (widget-test seam). When null,
  /// the card watches [fertilityEstimateProvider].
  final DataState<FertilityEstimate?>? state;

  const FertilityEstimateCard({super.key, this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state != null) return _buildBody(context, ref, state!);
    final async = ref.watch(fertilityEstimateProvider);
    return async.when(
      data: (s) => _buildBody(context, ref, s),
      loading: () => const _EstimateLoading(),
      error: (err, _) => _EstimatePanel(
        icon: Icons.error_outline_rounded,
        title: 'Couldn\u2019t load fertility estimates',
        body: '$err',
        actionLabel: 'Try again',
        onAction: () => refreshReproductiveData(ref),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    DataState<FertilityEstimate?> state,
  ) {
    if (state is Unavailable) {
      return _EstimatePanel(
        icon: Icons.cloud_off_outlined,
        title: 'Estimates need a connection',
        body: 'Your logged signs stay on this device. Connect to see your updated estimate.',
        actionLabel: 'Try again',
        onAction: () => refreshReproductiveData(ref),
      );
    }
    final estimate = state.dataOrNull;
    if (estimate == null) return const SizedBox.shrink();
    switch (estimate.status) {
      case FertilityEstimateStatus.available:
        if (!estimate.hasDates) {
          return _lowConfidencePanel(context, ref, state, estimate);
        }
        return _availablePanel(context, ref, state, estimate);
      case FertilityEstimateStatus.lowConfidence:
        return _lowConfidencePanel(context, ref, state, estimate);
      case FertilityEstimateStatus.suppressed:
        return _EstimatePanel(
          icon: Icons.pause_circle_outline_rounded,
          title: 'Fertility estimates paused',
          body: 'New fertility dates aren\u2019t shown right now. Your logged history is kept as is.',
          actionLabel: 'View pregnancy context',
          onAction: () => context.push('/profile/health/pregnancy-mode'),
          syncState: state,
        );
      case FertilityEstimateStatus.insufficientData:
        return _EstimatePanel(
          icon: Icons.insights_outlined,
          title: 'Not enough information yet',
          body: 'Keep logging periods and fertility signs — more history can improve the estimate.',
          actionLabel: 'Log fertility signs',
          onAction: () => context.push('/fertility-log'),
          syncState: state,
        );
    }
  }

  Widget _availablePanel(
    BuildContext context,
    WidgetRef ref,
    DataState<FertilityEstimate?> state,
    FertilityEstimate estimate,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final range =
        '${_formatDate(estimate.fertileWindowStart!)} – ${_formatDate(estimate.fertileWindowEnd!)}';
    return Container(
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
          SyncStatusChip(state: state),
          Row(
            children: [
              Icon(
                Icons.egg_outlined,
                size: 20,
                color: colorScheme.onSurface,
                semanticLabel: 'Estimated fertility',
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Estimated fertile window',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label:
                'Estimated fertile window, $range. Estimated ovulation day, ${_formatDate(estimate.estimatedOvulationDate!)}.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  range,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estimated ovulation day: ${_formatDate(estimate.estimatedOvulationDate!)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (estimate.evidenceSource == EstimateEvidenceSource.observed) ...[
            const SizedBox(height: 6),
            Text(
              'Based on signs you\u2019ve logged plus your cycle history.',
              style: TextStyle(fontSize: 12, color: colorScheme.secondary),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            estimate.disclaimer,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.secondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/fertility-log'),
              child: const Text('Log fertility signs'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lowConfidencePanel(
    BuildContext context,
    WidgetRef ref,
    DataState<FertilityEstimate?> state,
    FertilityEstimate estimate,
  ) {
    return _EstimatePanel(
      icon: Icons.help_outline_rounded,
      title: 'Estimate uncertain',
      body:
          'There isn\u2019t enough reliable information for fertility dates right now — cycle patterns vary, and missing signs lower certainty. '
          'This doesn\u2019t say anything about fertility itself. Keep logging and check back.',
      disclaimer: estimate.disclaimer,
      actionLabel: 'Log fertility signs',
      onAction: () => context.push('/fertility-log'),
      syncState: state,
    );
  }

  String _formatDate(String iso) {
    try {
      return DateFormat('MMM d').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}

class _EstimateLoading extends StatelessWidget {
  const _EstimateLoading();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Neutral estimate-state panel: icon + title + body + optional disclaimer
/// + optional action. Never renders dates.
class _EstimatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? disclaimer;
  final String? actionLabel;
  final VoidCallback? onAction;
  final DataState? syncState;

  const _EstimatePanel({
    required this.icon,
    required this.title,
    required this.body,
    this.disclaimer,
    this.actionLabel,
    this.onAction,
    this.syncState,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
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
          if (syncState != null) SyncStatusChip(state: syncState!),
          Row(
            children: [
              Icon(icon, size: 20, color: colorScheme.onSurface),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.secondary,
              height: 1.4,
            ),
          ),
          if (disclaimer != null) ...[
            const SizedBox(height: 8),
            Text(
              disclaimer!,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.secondary,
                height: 1.4,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ),
        ],
      ),
    );
  }
}
