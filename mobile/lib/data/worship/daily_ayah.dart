const _quranAyahCount = 6236;

/// A stable 1-based ayah ordinal for the day, used by the daily-ayah card.
int dailyAyahOrdinal(String dateKey) {
  final sum = dateKey.codeUnits.fold<int>(0, (total, unit) => total + unit);
  return (sum * 37) % _quranAyahCount + 1;
}
