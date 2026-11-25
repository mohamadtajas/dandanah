const _arabicDigits = '٠١٢٣٤٥٦٧٨٩';
const _persianDigits = '۰۱۲۳۴۵۶۷۸۹';

/// Parses decimal coordinates typed with Western or Arabic-Indic digits and
/// separators. Returns null for non-finite or malformed input.
double? parseCoordinate(String raw) {
  var value = raw.trim();
  if (value.isEmpty) return null;

  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    final arabic = _arabicDigits.indexOf(char);
    final persian = _persianDigits.indexOf(char);
    if (arabic >= 0) {
      buffer.write(arabic);
    } else if (persian >= 0) {
      buffer.write(persian);
    } else if (char == '٫') {
      buffer.write('.');
    } else if (char == '٬' || char == '،' || char == ',') {
      // Thousands separators add no information.
    } else {
      buffer.write(char);
    }
  }

  final parsed = double.tryParse(buffer.toString());
  if (parsed == null || !parsed.isFinite) return null;
  return parsed;
}

bool isValidLatitude(double value) => value >= -90 && value <= 90;

bool isValidLongitude(double value) => value >= -180 && value <= 180;
