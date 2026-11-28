import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/audio/audio_durations.dart';

void main() {
  final index = AudioDurationIndex.fromJson({
    'Alafasy_128kbps': {
      '1': [9000, 11000, 8000, 12000, 10000, 14000, 7000],
      '2': [1000, 0, 3000],
    },
  });

  test('sums a complete surah and locates aggregate positions', () {
    expect(index.isComplete('Alafasy_128kbps', 1, 7), isTrue);
    expect(index.totalFor('Alafasy_128kbps', 1, 7), 71000);
    expect(index.beforeAyah('Alafasy_128kbps', 1, 3), 20000);
    expect(index.durationFor('Alafasy_128kbps', 1, 4), 12000);

    final target = index.locate(
      'Alafasy_128kbps',
      1,
      const Duration(seconds: 21),
    );
    expect(target?.ayah, 3);
    expect(target?.offset, const Duration(seconds: 1));

    final end = index.locate('Alafasy_128kbps', 1, const Duration(seconds: 71));
    expect(end, isNull);
  });

  test('incomplete or unknown surahs have no total', () {
    expect(index.isComplete('Alafasy_128kbps', 2, 3), isFalse);
    expect(index.totalFor('Alafasy_128kbps', 2, 3), isNull);
    expect(index.totalFor('Unknown', 1, 7), isNull);
    expect(index.locate('Unknown', 1, Duration.zero), isNull);
  });
}
