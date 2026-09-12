import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sync_policy.dart';
import '../services/api_service.dart';
import '../models/care.dart';
import '../providers/cycle_provider.dart';

/// Last-good insight holder (plain Riverpod state, no new cache layer).
///
/// A single fetch per app run: the value survives Home revisits,
/// pull-to-refresh cycles, and offline transitions, so there is no spinner
/// flash and no repeated Care request on every navigation. Offline revisits
/// render the cached value; only a first-ever offline visit falls back to
/// the phase tip below. Use [DailyInsightNotifier.refresh] for an explicit
/// refresh if a future design needs one.
class DailyInsightNotifier extends Notifier<AsyncValue<String?>> {
  @override
  AsyncValue<String?> build() {
    unawaited(_fetchOnce());
    return const AsyncLoading();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await _fetchOnce();
  }

  Future<void> _fetchOnce() async {
    final apiService = ref.read(apiServiceProvider);
    String phase = 'menstrual';
    try {
      final cycleState = await ref.read(currentCycleProvider.future);
      phase = cycleState.dataOrNull?.phase.toLowerCase() ?? 'menstrual';
    } catch (_) {
      // Offline/empty cycle state: keep default phase for the fallback.
    }

    final prompt = 'Provide ONE concise, supportive wellness tip (nutrition, hydration, gentle movement, or rest) specifically suited for the $phase phase of the menstrual cycle. Do NOT repeat the cycle day number, do NOT name the cycle phase, and do NOT mention any next period dates. Maximum 2 sentences.';

    try {
      final request = CareInteractionRequest(
        intent: 'cycle_insight',
        userMessage: prompt,
      );
      final response = await apiService.postCareInteraction(request);
      state = AsyncData(response?.responseText);
    } catch (_) {
      switch (phase) {
        case 'menstrual':
          state = const AsyncData('Focus on warm fluids, magnesium-rich foods, and extra rest today.');
        case 'follicular':
          state = const AsyncData('Naturally rising energy makes this a great time for fresh nutrients and active movement.');
        case 'ovulation':
          state = const AsyncData('Support peak vitality with steady hydration and balanced meals.');
        case 'luteal':
          state = const AsyncData('Prioritize grounding evening routines and restorative rest as your body unwinds.');
        default:
          state = const AsyncData('Listen to your body today, stay hydrated, and take moments to rest.');
      }
    }
  }
}

final dailyInsightProvider =
    NotifierProvider<DailyInsightNotifier, AsyncValue<String?>>(
  DailyInsightNotifier.new,
);

class DailyInsightCard extends ConsumerStatefulWidget {
  const DailyInsightCard({super.key});

  @override
  ConsumerState<DailyInsightCard> createState() => _DailyInsightCardState();
}

class _DailyInsightCardState extends ConsumerState<DailyInsightCard> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    final insightAsync = ref.watch(dailyInsightProvider);

    return Dismissible(
      key: const Key('daily_insight_card'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        setState(() {
          _isDismissed = true;
        });
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.orange.shade400),
                  const SizedBox(width: 8),
                  Text(
                    'Daily Insight',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              insightAsync.when(
                data: (text) => Text(
                  text ?? 'Listen to your body today and take it easy.',
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface, height: 1.4),
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, _) => Text(
                  'Could not fetch your daily insight. Please try again later.',
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
