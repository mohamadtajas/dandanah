import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/audio/quran_audio_catalog.dart';

void main() {
  test('catalog has curated reciters and stable EveryAyah URLs', () {
    expect(QuranAudioCatalog.reciters, isNotEmpty);
    final reciter = QuranAudioCatalog.reciter('Alafasy_128kbps');
    expect(reciter, isNotNull);

    final queue = QuranAudioCatalog.surahQueue(
      reciter: reciter!,
      surah: 1,
      surahName: 'الفاتحة',
      ayahCount: 7,
    );
    expect(queue, hasLength(7));
    expect(queue.first.surah, 1);
    expect(queue.first.ayah, 1);
    expect(
      queue.first.url,
      'https://everyayah.com/data/Alafasy_128kbps/001001.mp3',
    );
    expect(queue.last.url, endsWith('/001007.mp3'));
    expect(queue.first.reciterName, reciter.name);
  });

  test('unknown reciters are rejected', () {
    expect(QuranAudioCatalog.reciter('missing'), isNull);
  });
}
