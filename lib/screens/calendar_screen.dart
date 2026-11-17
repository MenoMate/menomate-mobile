import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../core/theme.dart';
import '../data/app_database.dart' show toIsoDate;
import '../data/sync_policy.dart';
import '../models/cycle.dart';
import '../providers/cycle_provider.dart';
import '../providers/reproductive_providers.dart';
import '../screens/tabs/history_tab.dart' show todayNeutralFill;
import '../widgets/theme_atmosphere.dart';

enum CalendarView { month, year }

/// Calendar hierarchy root: Year ⇄ Month → Day Detail.
///
/// - Year View: 12-month overview with observed (rose) vs predicted
///   (violet, distinct) markings. Tap a month header → Month view;
///   tap a date → Day Detail.
/// - Month View: full month with logged/observed period days, predicted
///   span only when server data exists, today + selection.
/// - Day Detail: dedicated route `/calendar/day?date=YYYY-MM-DD`.
///
/// Observed and predicted are never visually identical. No client-side
/// prediction math: spans come only from `CurrentCycleResponse` +
/// `averagePeriodLength`.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarView _view = CalendarView.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  int _year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cyclesAsync = ref.watch(cycleListProvider);
    final currentAsync = ref.watch(currentCycleProvider);
    final cycles = cyclesAsync.value?.dataOrNull;
    final current = currentAsync.value?.dataOrNull;
    // Pregnancy suppression (§16): while pregnancy mode is active, future
    // menstrual predictions are withheld from every calendar surface.
    // Historical period data, navigation, and logged fills are untouched.
    final pregnancyActive =
        ref.watch(pregnancyProvider).value?.dataOrNull?.isActive == true;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Calendar',
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
      body: ThemeAtmosphereBackground(
        child: RefreshIndicator(
          onRefresh: () async => refreshAllAppData(ref),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SegmentedButton<CalendarView>(
                    segments: const [
                      ButtonSegment(
                        value: CalendarView.month,
                        icon: Icon(Icons.calendar_month_rounded, size: 16),
                        label: Text('Month'),
                      ),
                      ButtonSegment(
                        value: CalendarView.year,
                        icon: Icon(Icons.calendar_view_month_rounded, size: 16),
                        label: Text('Year'),
                      ),
                    ],
                    selected: {_view},
                    onSelectionChanged: (s) => setState(() => _view = s.first),
                  ),
                ),
                const SizedBox(height: 16),
                if (_view == CalendarView.month) ...[
                  _MonthCard(
                    focusedDay: _focusedDay,
                    selectedDay: _selectedDay,
                    cycles: cycles,
                    current: current,
                    pregnancyActive: pregnancyActive,
                    onFocused: (d) => setState(() => _focusedDay = d),
                    onSelected: (sel, foc) => setState(() {
                      _selectedDay = sel;
                      _focusedDay = foc;
                    }),
                  ),
                  const SizedBox(height: 12),
                  _LegendCard(
                    current: current,
                    pregnancyActive: pregnancyActive,
                  ),
                  if (_selectedDay != null) ...[
                    const SizedBox(height: 16),
                    _SelectedDayCard(
                      day: _selectedDay!,
                      cycles: cycles,
                      current: current,
                      pregnancyActive: pregnancyActive,
                    ),
                  ],
                ] else ...[
                  _YearHeader(
                    year: _year,
                    onPrev: () => setState(() => _year -= 1),
                    onNext: () => setState(() => _year += 1),
                  ),
                  const SizedBox(height: 12),
                  _YearGrid(
                    year: _year,
                    cycles: cycles,
                    current: current,
                    pregnancyActive: pregnancyActive,
                    onMonthTap: (month) {
                      setState(() {
                        _focusedDay = DateTime(_year, month, 1);
                        _view = CalendarView.month;
                      });
                    },
                    onDayTap: (day) {
                      context.push('/calendar/day?date=${toIsoDate(day)}');
                    },
                  ),
                  const SizedBox(height: 12),
                  _LegendCard(
                    current: current,
                    pregnancyActive: pregnancyActive,
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _isLoggedDay(
  DateTime day,
  List<CycleResponse>? cycles,
  CurrentCycleResponse? current,
) {
  if (cycles == null) return false;
  final check = DateTime(day.year, day.month, day.day);
  for (final c in cycles) {
    final start = DateTime(
      c.periodStart.year,
      c.periodStart.month,
      c.periodStart.day,
    );
    final end = c.periodEnd != null
        ? DateTime(c.periodEnd!.year, c.periodEnd!.month, c.periodEnd!.day)
        : (current?.isBleeding == true ? DateTime.now() : start);
    final endDay = DateTime(end.year, end.month, end.day);
    if (!check.isBefore(start) && !check.isAfter(endDay)) return true;
  }
  return false;
}

bool _isPredictedDay(
  DateTime day,
  List<CycleResponse>? cycles,
  CurrentCycleResponse? current, {
  bool pregnancyActive = false,
}) {
  // Pregnancy suppression: future menstrual predictions are withheld while
  // pregnancy mode is active. Logged history is unaffected (checked first
  // by callers via _isLoggedDay, which takes no suppression flag).
  if (pregnancyActive) return false;
  if (cycles != null && _isLoggedDay(day, cycles, current)) return false;
  if (current?.predictedNextPeriod == null) return false;
  final p = current!.predictedNextPeriod!;
  final start = DateTime(p.year, p.month, p.day);
  final avgLen = current.averagePeriodLength;
  if (avgLen == null) return false;
  final end = start.add(Duration(days: avgLen - 1));
  final check = DateTime(day.year, day.month, day.day);
  return !check.isBefore(start) && !check.isAfter(end);
}

class _MonthCard extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final List<CycleResponse>? cycles;
  final CurrentCycleResponse? current;
  final bool pregnancyActive;
  final ValueChanged<DateTime> onFocused;
  final void Function(DateTime, DateTime) onSelected;

  const _MonthCard({
    required this.focusedDay,
    required this.selectedDay,
    required this.cycles,
    required this.current,
    this.pregnancyActive = false,
    required this.onFocused,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) =>
            selectedDay != null && isSameDay(selectedDay, day),
        onDaySelected: onSelected,
        onDayLongPressed: (sel, foc) {
          onSelected(sel, foc);
          context.push('/calendar/day?date=${toIsoDate(sel)}');
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: colorScheme.onSurface,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: colorScheme.onSurface,
          ),
        ),
        onPageChanged: onFocused,
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (ctx, day, foc) => _MonthCell(
            day: day,
            cycles: cycles,
            current: current,
            pregnancyActive: pregnancyActive,
          ),
          todayBuilder: (ctx, day, foc) => _MonthCell(
            day: day,
            cycles: cycles,
            current: current,
            pregnancyActive: pregnancyActive,
            forceToday: true,
          ),
          selectedBuilder: (ctx, day, foc) => _MonthCell(
            day: day,
            cycles: cycles,
            current: current,
            pregnancyActive: pregnancyActive,
            forceSelected: true,
            forceToday: isSameDay(day, DateTime.now()),
          ),
          outsideBuilder: (ctx, day, foc) => _MonthCell(
            day: day,
            cycles: cycles,
            current: current,
            pregnancyActive: pregnancyActive,
            isOutside: true,
          ),
        ),
        onCalendarCreated: (_) {},
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  final DateTime day;
  final List<CycleResponse>? cycles;
  final CurrentCycleResponse? current;
  final bool pregnancyActive;
  final bool forceToday;
  final bool forceSelected;
  final bool isOutside;

  const _MonthCell({
    required this.day,
    required this.cycles,
    required this.current,
    this.pregnancyActive = false,
    this.forceToday = false,
    this.forceSelected = false,
    this.isOutside = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final logged = _isLoggedDay(day, cycles, current);
    final predicted = _isPredictedDay(
      day,
      cycles,
      current,
      pregnancyActive: pregnancyActive,
    );
    final todayFill = todayNeutralFill(colorScheme);

    BoxDecoration? decoration;
    Color? textColor = isOutside
        ? colorScheme.secondary.withValues(alpha: 0.35)
        : colorScheme.onSurface;
    final isToday = forceToday || isSameDay(day, DateTime.now());

    if (logged && isToday) {
      decoration = BoxDecoration(
        color: colorScheme.primary.withValues(alpha: isOutside ? 0.4 : 0.85),
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.onSurface, width: 2),
      );
      textColor = colorScheme.onPrimary;
    } else if (logged) {
      decoration = BoxDecoration(
        color: colorScheme.primary.withValues(alpha: isOutside ? 0.4 : 0.85),
        shape: BoxShape.circle,
        border: forceSelected
            ? Border.all(color: colorScheme.onSurface, width: 2)
            : null,
      );
      textColor = colorScheme.onPrimary;
    } else if (predicted) {
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
          width: forceSelected ? 2 : 1.5,
        ),
      );
      textColor = colorScheme.onSurface;
    } else if (forceSelected) {
      decoration = BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.primary, width: 1.5),
      );
      textColor = colorScheme.primary;
    }

    return GestureDetector(
      onTap: () {
        // TableCalendar handles selection; tap-through to day detail
        // happens via the SelectedDayCard button to avoid accidental nav.
      },
      child: Container(
        margin: const EdgeInsets.all(4.0),
        alignment: Alignment.center,
        decoration: decoration,
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontWeight: (logged || predicted || isToday || forceSelected)
                ? FontWeight.bold
                : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _LegendCard extends StatelessWidget {
  final CurrentCycleResponse? current;
  final bool pregnancyActive;

  const _LegendCard({required this.current, this.pregnancyActive = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final next = current?.predictedNextPeriod;
    final text = pregnancyActive
        ? 'Pregnancy mode is on — period predictions are paused. Your history is preserved.'
        : next != null
        ? 'Likely window around ${DateFormat('MMM d').format(next)}'
        : 'Predictions will appear once enough cycles are logged.';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? MenoMateTheme.starrySurfaceViolet
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _dot('Logged period', colorScheme, fill: colorScheme.primary),
              _dot(
                'Predicted period',
                colorScheme,
                fill: colorScheme.tertiary.withValues(alpha: 0.25),
                rim: colorScheme.tertiary,
              ),
              _dot(
                'Today',
                colorScheme,
                fill: todayNeutralFill(colorScheme),
                rim: colorScheme.onSurface,
              ),
              _dot(
                'Selected date',
                colorScheme,
                fill: colorScheme.primary.withValues(alpha: 0.15),
                rim: colorScheme.primary,
              ),
            ],
          ),
          Divider(height: 16, color: colorScheme.outline),
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 16,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
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

  Widget _dot(
    String label,
    ColorScheme scheme, {
    required Color fill,
    Color? rim,
  }) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: rim != null ? Border.all(color: rim, width: 1.5) : null,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: scheme.secondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  final DateTime day;
  final List<CycleResponse>? cycles;
  final CurrentCycleResponse? current;
  final bool pregnancyActive;

  const _SelectedDayCard({
    required this.day,
    required this.cycles,
    required this.current,
    this.pregnancyActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final logged = _isLoggedDay(day, cycles, current);
    final predicted = _isPredictedDay(
      day,
      cycles,
      current,
      pregnancyActive: pregnancyActive,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final check = DateTime(day.year, day.month, day.day);

    String status = 'Non-bleeding day';
    Color statusColor = colorScheme.secondary;
    IconData icon = Icons.circle_outlined;
    if (logged) {
      status = check.isAfter(today) ? 'Logged period' : 'Period active';
      statusColor = colorScheme.primary;
      icon = Icons.water_drop_outlined;
    } else if (predicted) {
      status = 'Predicted span';
      statusColor = colorScheme.tertiary;
      icon = Icons.auto_awesome_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(day),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 14, color: statusColor),
              const SizedBox(width: 6),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  context.push('/calendar/day?date=${toIsoDate(day)}'),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Open day detail'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/logger?date=${toIsoDate(day)}'),
              icon: const Icon(Icons.edit_note_outlined, size: 16),
              label: const Text('View / edit wellness log'),
            ),
          ),
        ],
      ),
    );
  }
}

class _YearHeader extends StatelessWidget {
  final int year;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _YearHeader({
    required this.year,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous year',
          onPressed: onPrev,
        ),
        Text(
          '$year',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next year',
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _YearGrid extends StatelessWidget {
  final int year;
  final List<CycleResponse>? cycles;
  final CurrentCycleResponse? current;
  final bool pregnancyActive;
  final ValueChanged<int> onMonthTap;
  final ValueChanged<DateTime> onDayTap;

  const _YearGrid({
    required this.year,
    required this.cycles,
    required this.current,
    this.pregnancyActive = false,
    required this.onMonthTap,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.86,
      ),
      itemCount: 12,
      itemBuilder: (context, i) {
        final month = i + 1;
        return _MiniMonth(
          year: year,
          month: month,
          cycles: cycles,
          current: current,
          pregnancyActive: pregnancyActive,
          onHeaderTap: () => onMonthTap(month),
          onDayTap: onDayTap,
        );
      },
    );
  }
}

class _MiniMonth extends StatelessWidget {
  final int year;
  final int month;
  final List<CycleResponse>? cycles;
  final CurrentCycleResponse? current;
  final bool pregnancyActive;
  final VoidCallback onHeaderTap;
  final ValueChanged<DateTime> onDayTap;

  const _MiniMonth({
    required this.year,
    required this.month,
    required this.cycles,
    required this.current,
    this.pregnancyActive = false,
    required this.onHeaderTap,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final first = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Monday-first offset (0..6).
    final leading = (first.weekday + 6) % 7;
    final today = DateTime.now();
    bool isToday(DateTime d) =>
        d.year == today.year && d.month == today.month && d.day == today.day;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onHeaderTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                DateFormat('MMM').format(first),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              itemCount: leading + daysInMonth,
              itemBuilder: (context, idx) {
                if (idx < leading) return const SizedBox.shrink();
                final dayNum = idx - leading + 1;
                final date = DateTime(year, month, dayNum);
                final logged = _isLoggedDay(date, cycles, current);
                final predicted = _isPredictedDay(
                  date,
                  cycles,
                  current,
                  pregnancyActive: pregnancyActive,
                );
                Color? bg;
                Color fg = colorScheme.onSurface;
                BoxBorder? border;
                if (logged) {
                  bg = colorScheme.primary.withValues(alpha: 0.85);
                  fg = colorScheme.onPrimary;
                } else if (predicted) {
                  bg = colorScheme.tertiary.withValues(alpha: 0.25);
                  border = Border.all(color: colorScheme.tertiary, width: 1);
                } else if (isToday(date)) {
                  bg = todayNeutralFill(colorScheme);
                  border = Border.all(color: colorScheme.onSurface, width: 1);
                }
                return GestureDetector(
                  onTap: () => onDayTap(date),
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bg,
                      shape: BoxShape.circle,
                      border: border,
                    ),
                    child: Text(
                      '$dayNum',
                      style: TextStyle(fontSize: 9, color: fg),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
