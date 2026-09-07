import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/summary.dart';
import '../../models/cycle.dart';
import '../../services/api_service.dart';
import '../../providers/cycle_provider.dart';

final historySummaryProvider = FutureProvider<HistorySummaryResponse?>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return await api.getCycleHistory();
});

final cycleListProvider = FutureProvider<List<CycleResponse>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return await api.getCycles();
});

class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(historySummaryProvider);
    final cyclesAsync = ref.watch(cycleListProvider);
    final currentCycleAsync = ref.watch(currentCycleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('History & Insights', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  summaryAsync.when(
                    data: (summary) => summary != null ? _buildStatsCard(summary) : const SizedBox(),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Error: $err'),
                  ),
                  const SizedBox(height: 32),
                  const Text('Cycle Calendar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildCalendar(cyclesAsync, currentCycleAsync),
                  const SizedBox(height: 32),
                  const Text('Past Cycles', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          summaryAsync.when(
            data: (summary) {
              if (summary == null || summary.history.isEmpty) {
                return const SliverToBoxAdapter(child: Center(child: Text('No past cycles')));
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildCycleTile(summary.history[index]),
                    childCount: summary.history.length,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox()),
            error: (err, _) => const SliverToBoxAdapter(child: SizedBox()),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _buildCalendar(AsyncValue<List<CycleResponse>> cyclesAsync, AsyncValue<CurrentCycleResponse?> currentCycleAsync) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return _buildCalendarCell(day, cyclesAsync.value, currentCycleAsync.value);
          },
          todayBuilder: (context, day, focusedDay) {
            return _buildCalendarCell(day, cyclesAsync.value, currentCycleAsync.value, isToday: true);
          },
        ),
      ),
    );
  }

  Widget _buildCalendarCell(DateTime day, List<CycleResponse>? cycles, CurrentCycleResponse? currentCycle, {bool isToday = false}) {
    // Check if day is part of a logged past period
    bool isLoggedPeriod = false;
    if (cycles != null) {
      for (var cycle in cycles) {
        final start = DateTime(cycle.periodStart.year, cycle.periodStart.month, cycle.periodStart.day);
        final end = cycle.periodEnd != null 
            ? DateTime(cycle.periodEnd!.year, cycle.periodEnd!.month, cycle.periodEnd!.day)
            : DateTime.now(); // If ongoing, assume up to today
        
        final checkDay = DateTime(day.year, day.month, day.day);
        
        if (checkDay.isAtSameMomentAs(start) || 
           (checkDay.isAfter(start) && checkDay.isBefore(end)) || 
           checkDay.isAtSameMomentAs(end)) {
          isLoggedPeriod = true;
          break;
        }
      }
    }

    // Check if day is a predicted future period
    bool isPredictedPeriod = false;
    if (!isLoggedPeriod && currentCycle != null && currentCycle.predictedNextPeriod != null) {
      final start = DateTime(
        currentCycle.predictedNextPeriod!.year, 
        currentCycle.predictedNextPeriod!.month, 
        currentCycle.predictedNextPeriod!.day
      );
      // Assume average period length or 5 days
      final avgLen = currentCycle.averagePeriodLength ?? 5;
      final end = start.add(Duration(days: avgLen - 1));
      
      final checkDay = DateTime(day.year, day.month, day.day);
      
      if (checkDay.isAtSameMomentAs(start) || 
         (checkDay.isAfter(start) && checkDay.isBefore(end)) || 
         checkDay.isAtSameMomentAs(end)) {
        isPredictedPeriod = true;
      }
    }

    BoxDecoration? decoration;
    Color? textColor;

    if (isLoggedPeriod) {
      decoration = BoxDecoration(
        color: Colors.redAccent.shade100,
        shape: BoxShape.circle,
      );
      textColor = Colors.red.shade900;
    } else if (isPredictedPeriod) {
      decoration = BoxDecoration(
        border: Border.all(color: Colors.purpleAccent, width: 2),
        shape: BoxShape.circle,
      );
      textColor = Colors.purple;
    } else if (isToday) {
      decoration = BoxDecoration(
        color: Colors.blue.shade100,
        shape: BoxShape.circle,
      );
    }

    return Container(
      margin: const EdgeInsets.all(6.0),
      alignment: Alignment.center,
      decoration: decoration,
      child: Text(
        '${day.day}',
        style: TextStyle(color: textColor ?? Colors.black87),
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
