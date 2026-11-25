import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/models/local_date.dart';
import 'package:sakeenah_mobile/data/worship/timezone_bootstrap.dart';

void main() {
  test('local date key is zero padded and ignores the time of day', () {
    expect(localDateKey(DateTime(2026, 1, 2)), '2026-01-02');
    expect(localDateKey(DateTime(2026, 11, 26, 0, 0, 1)), '2026-11-26');
    expect(localDateKey(DateTime(2026, 11, 26, 23, 59, 59)), '2026-11-26');
  });

  test('consecutive local midnights produce consecutive keys', () {
    final first = DateTime(2026, 11, 26);
    final second = DateTime(2026, 11, 27);
    expect(localDateKey(first), '2026-11-26');
    expect(localDateKey(second), '2026-11-27');
  });

  test('the adhkar day follows the configured timezone', () {
    final instant = DateTime.utc(2026, 11, 25, 22, 30);
    expect(dateKeyInTimezone('Asia/Riyadh', now: instant), '2026-11-26');
    expect(dateKeyInTimezone('America/New_York', now: instant), '2026-11-25');
  });
}
