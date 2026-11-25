/// A timezone-stable key for a local calendar day (`YYYY-MM-DD`).
///
/// Prayer and adhkar streaks are grouped by the day the user experienced, not
/// by an instant; storing this string avoids midnight and timezone drift.
String localDateKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
