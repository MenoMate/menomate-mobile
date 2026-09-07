import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cycle.dart';
import '../services/api_service.dart';

final currentCycleProvider = FutureProvider<CurrentCycleResponse?>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getCurrentCycle();
});
