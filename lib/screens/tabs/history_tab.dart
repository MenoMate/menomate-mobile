import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/summary.dart';
import '../../models/cycle.dart';
import '../../providers/cycle_provider.dart';

class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final summaryAsync = ref.watch(historySummaryProvider);
    final cyclesAsync = ref.watch(cycleListProvider);
    final currentCycleAsync = ref.watch(currentCycleProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'History & Insights',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => refreshAllAppData(ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => refreshAllAppData(ref),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Stats Card
                    summaryAsync.when(
                      data: (summary) => summary != null
                          ? _buildStatsCard(summary, context)
                          : const SizedBox.shrink(),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Text(
                        'Could not load summary history.',
                        style: TextStyle(color: colorScheme.secondary),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section Title: Cycle Calendar
                    Text(
                      'Cycle Calendar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // The Calendar Card
                    _buildCalendar(cyclesAsync, currentCycleAsync, context),

                    const SizedBox(height: 12),

                    // Calendar Legend & Confidence Badge
                    _buildCalendarLegend(currentCycleAsync.value, context),

                    // Selected Date Detail Card
                    if (_selectedDay != null) ...[
                      const SizedBox(height: 16),
                      _buildSelectedDayCard(
                        _selectedDay!,
                        cyclesAsync.value,
                        currentCycleAsync.value,
                        context,
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Section Title: Past Cycles
                    Text(
                      'Past Cycles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Past Cycles List
            summaryAsync.when(
              data: (summary) {
                if (summary == null || summary.history.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No completed cycles logged yet.',
                          style: TextStyle(color: colorScheme.secondary),
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildCycleTile(summary.history[index], context),
                      childCount: summary.history.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(
    AsyncValue<List<CycleResponse>> cyclesAsync,
    AsyncValue<CurrentCycleResponse?> currentCycleAsync,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => _selectedDay != null && isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: colorScheme.onSurface),
          rightChevronIcon: Icon(Icons.chevron_right, color: colorScheme.onSurface),
        ),
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return _buildCalendarCell(day, cyclesAsync.value, currentCycleAsync.value, isOutside: false);
          },
          todayBuilder: (context, day, focusedDay) {
            return _buildCalendarCell(day, cyclesAsync.value, currentCycleAsync.value, isToday: true, isOutside: false);
          },
          outsideBuilder: (context, day, focusedDay) {
            return _buildCalendarCell(day, cyclesAsync.value, currentCycleAsync.value, isOutside: true);
          },
        ),
      ),
    );
  }

  Widget _buildCalendarCell(
    DateTime day,
    List<CycleResponse>? cycles,
    CurrentCycleResponse? currentCycle, {
    bool isToday = false,
    bool isOutside = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final checkDay = DateTime(day.year, day.month, day.day);

    // 1. Check logged period
    bool isLoggedPeriod = false;
    if (cycles != null) {
      for (var cycle in cycles) {
        final start = DateTime(cycle.periodStart.year, cycle.periodStart.month, cycle.periodStart.day);
        final end = cycle.periodEnd != null
            ? DateTime(cycle.periodEnd!.year, cycle.periodEnd!.month, cycle.periodEnd!.day)
            : (currentCycle?.isBleeding == true ? DateTime.now() : start);

        if (!checkDay.isBefore(start) && !checkDay.isAfter(end)) {
          isLoggedPeriod = true;
          break;
        }
      }
    }

    // 2. Check predicted future period across month boundary
    bool isPredictedPeriod = false;
    if (!isLoggedPeriod && currentCycle != null && currentCycle.predictedNextPeriod != null) {
      final pStart = currentCycle.predictedNextPeriod!;
      final start = DateTime(pStart.year, pStart.month, pStart.day);
      final avgLen = currentCycle.averagePeriodLength ?? 5;
      final end = start.add(Duration(days: avgLen - 1));

      if (!checkDay.isBefore(start) && !checkDay.isAfter(end)) {
        isPredictedPeriod = true;
      }
    }

    final isSelected = _selectedDay != null && isSameDay(_selectedDay, day);

    BoxDecoration? decoration;
    Color? textColor = isOutside
        ? colorScheme.secondary.withValues(alpha: 0.35)
        : colorScheme.onSurface;

    if (isLoggedPeriod) {
      decoration = BoxDecoration(
        color: const Color(0xFFE88FA8).withValues(alpha: isOutside ? 0.4 : 0.85),
        shape: BoxShape.circle,
        border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
      );
      textColor = Colors.white;
    } else if (isPredictedPeriod) {
      decoration = BoxDecoration(
        color: const Color(0xFFAEBBFF).withValues(alpha: isOutside ? 0.15 : 0.25),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFAEBBFF).withValues(alpha: isOutside ? 0.5 : 1.0),
          width: 1.8,
        ),
      );
      textColor = isOutside
          ? const Color(0xFFAEBBFF).withValues(alpha: 0.6)
          : (theme.brightness == Brightness.dark ? const Color(0xFFAEBBFF) : const Color(0xFF5367B8));
    } else if (isToday) {
      decoration = BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.primary, width: 1.5),
      );
      textColor = colorScheme.primary;
    } else if (isSelected) {
      decoration = BoxDecoration(
        border: Border.all(color: colorScheme.onSurface, width: 1.5),
        shape: BoxShape.circle,
      );
    }

    return Container(
      margin: const EdgeInsets.all(4.0),
      alignment: Alignment.center,
      decoration: decoration,
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: textColor,
          fontWeight: (isLoggedPeriod || isPredictedPeriod || isToday || isSelected)
              ? FontWeight.bold
              : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildCalendarLegend(CurrentCycleResponse? currentCycle, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final confidence = currentCycle?.predictionConfidence ?? 'None';
    final nextPredicted = currentCycle?.predictedNextPeriod;

    String predictionText;
    if (nextPredicted != null) {
      final formatted = DateFormat('MMM d').format(nextPredicted);
      predictionText = 'Predicted period: Around $formatted ($confidence confidence)';
    } else {
      predictionText = 'Predictions will appear once enough cycles are logged.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendDot(const Color(0xFFE88FA8), 'Logged period', colorScheme),
              _buildLegendDot(const Color(0xFFAEBBFF), 'Predicted span', colorScheme, isOutlined: true),
              _buildLegendDot(colorScheme.primary, 'Today', colorScheme),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  predictionText,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (confidence.toLowerCase() == 'low' || confidence.toLowerCase() == 'none') ...[
            const SizedBox(height: 4),
            Text(
              'Limited cycle history logged. Prediction confidence will improve over subsequent cycles.',
              style: TextStyle(fontSize: 11, color: colorScheme.secondary.withValues(alpha: 0.8)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label, ColorScheme colorScheme, {bool isOutlined = false}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isOutlined ? color.withValues(alpha: 0.25) : color,
            shape: BoxShape.circle,
            border: isOutlined ? Border.all(color: color, width: 1.5) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.secondary),
        ),
      ],
    );
  }

  Widget _buildSelectedDayCard(
    DateTime day,
    List<CycleResponse>? cycles,
    CurrentCycleResponse? currentCycle,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final checkDay = DateTime(day.year, day.month, day.day);
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(day);

    // Identify period status
    bool isPeriod = false;
    if (cycles != null) {
      for (var c in cycles) {
        final start = DateTime(c.periodStart.year, c.periodStart.month, c.periodStart.day);
        final end = c.periodEnd != null
            ? DateTime(c.periodEnd!.year, c.periodEnd!.month, c.periodEnd!.day)
            : (currentCycle?.isBleeding == true ? DateTime.now() : start);
        if (!checkDay.isBefore(start) && !checkDay.isAfter(end)) {
          isPeriod = true;
          break;
        }
      }
    }

    bool isPredicted = false;
    if (!isPeriod && currentCycle != null && currentCycle.predictedNextPeriod != null) {
      final pStart = currentCycle.predictedNextPeriod!;
      final start = DateTime(pStart.year, pStart.month, pStart.day);
      final avgLen = currentCycle.averagePeriodLength ?? 5;
      final end = start.add(Duration(days: avgLen - 1));
      if (!checkDay.isBefore(start) && !checkDay.isAfter(end)) {
        isPredicted = true;
      }
    }

    String statusText = 'Non-bleeding day';
    Color statusColor = colorScheme.secondary;
    if (isPeriod) {
      statusText = 'Logged Active Period';
      statusColor = const Color(0xFFE88FA8);
    } else if (isPredicted) {
      statusText = 'Estimated Predicted Period Span';
      statusColor = const Color(0xFFAEBBFF);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (currentCycle != null && isSameDay(DateTime.now(), day)) ...[
            const SizedBox(height: 8),
            Text(
              'Today: Day ${currentCycle.currentCycleDay ?? 1} of your cycle (${currentCycle.phase.toUpperCase()} phase).',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard(HistorySummaryResponse summary, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final avgCycleText = summary.averageCycleLength != null
        ? '${summary.averageCycleLength!.toStringAsFixed(0)} days'
        : '--';
    final avgPeriodText = summary.averagePeriodLength != null
        ? '${summary.averagePeriodLength!.toStringAsFixed(0)} days'
        : '--';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Cycles Logged', summary.totalPeriodsLogged.toString(), colorScheme),
          _buildDivider(colorScheme),
          _buildStatItem('Avg Cycle', avgCycleText, colorScheme),
          _buildDivider(colorScheme),
          _buildStatItem('Avg Period', avgPeriodText, colorScheme),
        ],
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Container(
      height: 36,
      width: 1,
      color: colorScheme.outline,
    );
  }

  Widget _buildStatItem(String label, String value, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colorScheme.secondary),
        ),
      ],
    );
  }

  Widget _buildCycleTile(HistoryPeriodEntry cycle, BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final startStr = DateFormat('MMM d').format(cycle.periodStart);
    final endStr = cycle.periodEnd != null
        ? DateFormat('MMM d').format(cycle.periodEnd!)
        : 'Ongoing';

    final periodLenStr = cycle.periodLengthDays != null
        ? '${cycle.periodLengthDays} days'
        : '--';
    final cycleLenStr = cycle.cycleLengthDays != null
        ? '${cycle.cycleLengthDays} days'
        : '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.water_drop, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$startStr - $endStr',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Period: $periodLenStr  ·  Cycle Interval: $cycleLenStr',
                  style: TextStyle(fontSize: 12, color: colorScheme.secondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
