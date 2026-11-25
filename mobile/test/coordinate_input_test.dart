import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/worship/coordinate_input.dart';

void main() {
  test('parses Western coordinates', () {
    expect(parseCoordinate('21.4225'), 21.4225);
    expect(parseCoordinate('-171.7667'), -171.7667);
    expect(parseCoordinate(' 30.0444 '), 30.0444);
  });

  test('parses Arabic-Indic digits and separators', () {
    expect(parseCoordinate('٣١٫٩٥٣٩'), 31.9539);
    expect(parseCoordinate('٣٥٫٩١٠٦'), 35.9106);
    expect(parseCoordinate('۱٬۲۳۴٫۵'), 1234.5);
  });

  test('rejects malformed, non-finite and out-of-range values', () {
    expect(parseCoordinate(''), isNull);
    expect(parseCoordinate('abc'), isNull);
    expect(parseCoordinate('NaN'), isNull);
    expect(parseCoordinate('Infinity'), isNull);
    expect(parseCoordinate('1e999'), isNull);

    expect(isValidLatitude(90), isTrue);
    expect(isValidLatitude(90.1), isFalse);
    expect(isValidLongitude(-180), isTrue);
    expect(isValidLongitude(180.1), isFalse);
  });
}
