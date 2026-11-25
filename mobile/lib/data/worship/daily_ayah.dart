const _quranAyahCount = 6236;

/// A stable 1-based ayah ordinal for the day, used by the daily-ayah card.
///
/// FNV-1a over the full `YYYY-MM-DD` key spreads dates across the whole Quran;
/// a plain digit sum would collapse the year into a handful of ayat.
int dailyAyahOrdinal(String dateKey) {
  var hash = 0x811c9dc5;
  for (final unit in dateKey.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash % _quranAyahCount + 1;
}
