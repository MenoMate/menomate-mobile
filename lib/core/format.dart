/// Display-only count formatting. No calculation logic lives here:
// callers pass already-computed values, this only renders them
// grammatically ("1 day" vs "2 days") and cognitively ("–" for
// zero/sub-day intervals instead of "0 days").
String formatDayCount(int n, String unit) {
  if (n <= 0) return '–';
  if (n == 1) return '1 $unit';
  return '$n ${unit}s';
}
