import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/summary.dart';
import '../../services/api_service.dart';

final historySummaryProvider = FutureProvider<HistorySummaryResponse?>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return await api.getCycleHistory();
});

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historySummaryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('History & Insights', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: historyAsync.when(
        data: (summary) {
          if (summary == null) {
            return const Center(child: Text('Failed to load history'));
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildStatsCard(summary),
              const SizedBox(height: 24),
              const Text('Past Cycles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...summary.history.map((cycle) => _buildCycleTile(cycle)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildStatsCard(HistorySummaryResponse summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Cycles Logged', summary.totalPeriodsLogged.toString()),
              _buildStatItem('Avg Cycle', '${summary.averageCycleLength?.toStringAsFixed(1) ?? "--"} days'),
              _buildStatItem('Avg Period', '${summary.averagePeriodLength?.toStringAsFixed(1) ?? "--"} days'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
      ],
    );
  }

  Widget _buildCycleTile(HistoryPeriodEntry cycle) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFCDD2),
          child: Icon(Icons.water_drop, color: Colors.redAccent, size: 20),
        ),
        title: Text('${cycle.periodStart.month}/${cycle.periodStart.day} - '
            '${cycle.periodEnd != null ? "${cycle.periodEnd!.month}/${cycle.periodEnd!.day}" : "Ongoing"}'),
        subtitle: Text('Cycle length: ${cycle.cycleLengthDays ?? "--"} days'),
      ),
    );
  }
}
