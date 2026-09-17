/// Display-only count formatting. No calculation logic lives here:
// callers pass already-computed values, this only renders them
// grammatically ("1 day" vs "2 days") and cognitively ("–" for
// zero/sub-day intervals instead of "0 days").
String formatDayCount(int n, String unit) {
  if (n <= 0) return '–';
  if (n == 1) return '1 $unit';
  return '$n ${unit}s';
}

/// Full month names for birth month/year pickers. Single source shared by
/// onboarding and Profile so the pair always reads identically.
const List<String> kMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Display-only cycle-phase label. Backend phase strings are technical
/// identifiers; the UI shows a calm capitalized name instead of shouty
/// uppercase. No semantics change here — mapping only, unknown stays
/// unknown.
String formatPhaseLabel(String phase) {
  switch (phase.toLowerCase()) {
    case 'menstrual':
      return 'Menstrual';
    case 'follicular':
      return 'Follicular';
    case 'ovulation':
      return 'Ovulation';
    case 'luteal':
      return 'Luteal';
    default:
      return 'Unknown';
  }
}
