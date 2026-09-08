import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cycle.dart';
import '../models/summary.dart';
import '../services/api_service.dart';
import 'profile_provider.dart';

final currentCycleProvider = FutureProvider<CurrentCycleResponse?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getCurrentCycle();
});

final historySummaryProvider = FutureProvider<HistorySummaryResponse?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getCycleHistory();
});

final cycleListProvider = FutureProvider<List<CycleResponse>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getCycles();
});

void refreshAllAppData(WidgetRef ref) {
  ref.invalidate(currentCycleProvider);
  ref.invalidate(historySummaryProvider);
  ref.invalidate(cycleListProvider);
  ref.invalidate(profileProvider);
}
