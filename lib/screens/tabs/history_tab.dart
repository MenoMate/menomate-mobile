import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../data/app_database.dart';
import '../../data/sync_policy.dart';
import '../../models/summary.dart';
import '../../models/cycle.dart';
import '../../providers/cycle_provider.dart';
import '../../widgets/offline_banner.dart';
import '../../core/format.dart';

enum _HistoryPane { calendar, cycles }

/// Neutral Today emphasis shared by cells and the legend dot.
///
/// A whisper of onSurface (light: dark tint; dark: light tint), so Today
/// reads as "today/selection" rather than another menstrual status. Rose
/// stays logged-only, violet stays prediction-only. Single source for
/// cells and legend (exact match guaranteed); token-derived, so it tracks
/// light/dark mode with no new literals.
Color todayNeutralFill(ColorScheme colorScheme) {
  return colorScheme.onSurface.withValues(alpha: 0.10);
}

class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  /// Active pane: calendar browsing vs past-cycle statistics.
  _HistoryPane _pane = _HistoryPane.calendar;

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
                    // Pane selector: Calendar (day browsing) vs Cycles
                    // (statistics + past cycles). Tab index stays stable;
                    // this segments one destination, it adds no routes.
                    Center(
                      child: SegmentedButton<_HistoryPane>(
                        segments: const [
                          ButtonSegment<_HistoryPane>(
                            value: _HistoryPane.calendar,
                            icon: Icon(Icons.calendar_month_rounded, size: 16),
                            label: Text('Calendar'),
                          ),
                          ButtonSegment<_HistoryPane>(
                            value: _HistoryPane.cycles,
                            icon: Icon(Icons.history_rounded, size: 16),
                            label: Text('Cycles'),
                          ),
                        ],
                        selected: {_pane},
                        onSelectionChanged: (selected) {
                          setState(() {
                            _pane = selected.first;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_pane == _HistoryPane.calendar) ...[
                      // The Calendar Card
                      _buildCalendar(
                        _cyclesForCalendar(cyclesAsync),
                        currentCycleAsync.value?.dataOrNull,
                        context,
                      ),

                      const SizedBox(height: 12),

                      // Calendar Legend (concise single prediction line)
                      _buildCalendarLegend(
                          currentCycleAsync.value?.dataOrNull, context),

                      // Selected Date Detail Card
                      if (_selectedDay != null) ...[
                        const SizedBox(height: 16),
                        _buildSelectedDayCard(
                          _selectedDay!,
                          _cyclesForCalendar(cyclesAsync),
                          currentCycleAsync.value?.dataOrNull,
                          context,
                        ),
                      ],
                    ] else ...[
                      // Cycles pane: compact statistics + past-cycle list
                      // header. The list itself stays a sliver below.
                      summaryAsync.when(
                        data: (summaryState) {
                          if (summaryState is Unavailable) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Text(
                                  'Couldn\'t load history. Check your connection and pull to refresh.',
                                  textAlign: TextAlign.center,
                                  style:
                                      TextStyle(color: colorScheme.secondary),
                                ),
                              ),
                            );
                          }
                          final summary = summaryState.dataOrNull;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SyncStatusChip(state: summaryState),
                              if (summary != null)
                                _buildStatsCard(summary, context),
                            ],
                          );
                        },
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
                  ],
                ),
              ),
            ),

            // Past Cycles List (Cycles pane only)
            if (_pane == _HistoryPane.cycles)
              summaryAsync.when(
              data: (summaryState) {
                if (summaryState is Unavailable) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Couldn\'t load history. Check your connection and pull to refresh.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.secondary),
                        ),
                      ),
                    ),
                  );
                }
                final summary = summaryState.dataOrNull;
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

  /// Unwraps the cycle list for calendar rendering. Unavailable/no-data
  /// yields null (renders an empty calendar), never fake entries.
  List<CycleResponse>? _cyclesForCalendar(
    AsyncValue<DataState<List<CycleResponse>>> cyclesAsync,
  ) {
    return cyclesAsync.value?.dataOrNull;
  }

  Widget _buildCalendar(
    List<CycleResponse>? cycles,
    CurrentCycleResponse? currentCycle,
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
            return _buildCalendarCell(day, cycles, currentCycle, isOutside: false);
          },
          todayBuilder: (context, day, focusedDay) {
            return _buildCalendarCell(day, cycles, currentCycle, isToday: true, isOutside: false);
          },
          // Explicit selected styling in MenoMate tokens. Without this,
          // table_calendar falls back to its package-default indigo
          // selected decoration, which contradicts the legend.
          selectedBuilder: (context, day, focusedDay) {
            return _buildCalendarCell(
              day,
              cycles,
              currentCycle,
              isToday: isSameDay(day, DateTime.now()),
              isSelected: true,
              isOutside: false,
            );
          },
          outsideBuilder: (context, day, focusedDay) {
            return _buildCalendarCell(day, cycles, currentCycle, isOutside: true);
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
    bool isSelected = false,
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

    // Semantic fills from theme tokens: primary = logged rose,
    // todayNeutralFill = neutral Today emphasis, tertiary = predicted.
    // No package defaults, no hardcoded accents: the legend dots use these
    // same tokens. Rims are minimal: Today always carries an onSurface rim
    // (dark in light mode, light in dark mode); any selection upgrades it
    // to 2px. Fill alone already separates the three meanings.
    final todayFill = todayNeutralFill(colorScheme);
    BoxDecoration? decoration;
    Color? textColor = isOutside
        ? colorScheme.secondary.withValues(alpha: 0.35)
        : colorScheme.onSurface;

    if (isLoggedPeriod && isToday) {
      // Logged status wins the fill; the onSurface rim marks Today.
      decoration = BoxDecoration(
        color: colorScheme.primary.withValues(alpha: isOutside ? 0.4 : 0.85),
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.onSurface, width: 2),
      );
      textColor = colorScheme.onPrimary;
    } else if (isLoggedPeriod) {
      decoration = BoxDecoration(
        color: colorScheme.primary.withValues(alpha: isOutside ? 0.4 : 0.85),
        shape: BoxShape.circle,
        border: isSelected
            ? Border.all(color: colorScheme.onSurface, width: 2)
            : null,
      );
      textColor = colorScheme.onPrimary;
    } else if (isPredictedPeriod) {
      decoration = BoxDecoration(
        color: colorScheme.tertiary.withValues(alpha: isOutside ? 0.15 : 0.25),
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.tertiary.withValues(alpha: isOutside ? 0.5 : 1.0),
          width: 1.8,
        ),
      );
      textColor = colorScheme.onSurface;
    } else if (isToday) {
      decoration = BoxDecoration(
        color: isOutside ? todayFill.withValues(alpha: 0.4) : todayFill,
        shape: BoxShape.circle,
        border: Border.all(
          color: colorScheme.onSurface,
          width: isSelected ? 2 : 1.5,
        ),
      );
      textColor = colorScheme.onSurface;
    } else if (isSelected) {
      decoration = BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.primary, width: 1.5),
      );
      textColor = colorScheme.primary;
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
    final nextPredicted = currentCycle?.predictedNextPeriod;

    // Concise single prediction line. Confidence detail lives on Home;
    // the low-history explainer paragraph was removed to avoid stating
    // the same prediction information in multiple places.
    String predictionText;
    if (nextPredicted != null) {
      final formatted = DateFormat('MMM d').format(nextPredicted);
      predictionText = 'Likely window around $formatted';
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
              _buildLegendDot('Logged period', colorScheme,
                  fill: colorScheme.primary),
              _buildLegendDot('Predicted span', colorScheme,
                  fill: colorScheme.tertiary.withValues(alpha: 0.25),
                  rim: colorScheme.tertiary),
              // Neutral Today marker: the exact fill + rim of today cells,
              // so the three meanings separate without relying on the rim.
              _buildLegendDot('Today', colorScheme,
                  fill: todayNeutralFill(colorScheme),
                  rim: colorScheme.onSurface),
            ],
          ),
          Divider(height: 16, color: colorScheme.outline),
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
        ],
      ),
    );
  }

  Widget _buildLegendDot(String label, ColorScheme colorScheme,
      {required Color fill, Color? rim, double rimWidth = 1.5}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border:
                rim != null ? Border.all(color: rim, width: rimWidth) : null,
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
      statusColor = colorScheme.primary;
    } else if (isPredicted) {
      statusText = 'Estimated Predicted Period Span';
      statusColor = colorScheme.tertiary;
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
          const SizedBox(height: 12),
          // Existing History/calendar experience is the discovery path for
          // saved daily logs: opens the same logger for this date, which
          // edits the existing user+date record (never a duplicate).
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.push('/logger?date=${toIsoDate(day)}');
              },
              icon: const Icon(Icons.edit_note_outlined, size: 18),
              label: const Text('View / edit wellness log'),
            ),
          ),
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

    // Display formatting only: counts render grammatically ("1 day"),
    // and zero/sub-day intervals render as an em dash, never "0 days".
    // Cycle calculations are untouched.
    final periodLenStr = cycle.periodLengthDays != null
        ? formatDayCount(cycle.periodLengthDays!, 'day')
        : '--';
    final cycleLenStr = cycle.cycleLengthDays != null
        ? formatDayCount(cycle.cycleLengthDays!, 'day')
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
