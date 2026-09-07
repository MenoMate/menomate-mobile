import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/care.dart';
import '../providers/cycle_provider.dart';

final dailyInsightProvider = FutureProvider.autoDispose<String?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final cycleData = await ref.watch(currentCycleProvider.future);
  
  final cycleDay = cycleData?.currentCycleDay ?? 1;
  final phase = cycleData?.phase ?? 'unknown';

  final prompt = 'Give me a strict two-sentence wellness tip based on the current cycle day $cycleDay (phase: $phase). Do not include any pleasantries or chat history.';

  final request = CareInteractionRequest(
    intent: 'general_inquiry',
    userMessage: prompt,
  );
  final response = await apiService.postCareInteraction(request);

  return response?.responseText;
});

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
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.orange.shade400),
                  const SizedBox(width: 8),
                  const Text(
                    'Daily Insight',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              insightAsync.when(
                data: (text) => Text(
                  text ?? 'Listen to your body today and take it easy.',
                  style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, __) => const Text(
                  'Could not fetch your daily insight. Please try again later.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
