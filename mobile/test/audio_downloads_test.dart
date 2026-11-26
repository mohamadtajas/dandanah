import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/audio/audio_downloads.dart';
import 'package:sakeenah_mobile/data/audio/quran_audio_catalog.dart';
import 'package:sakeenah_mobile/data/models/audio.dart';
import 'package:sakeenah_mobile/data/models/quran.dart';

void main() {
  late Directory root;
  late int fetches;
  late AudioDownloadStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('sakeenah_audio_test');
    fetches = 0;
    store = AudioDownloadStore(
      root: root,
      fetch: (uri) async {
        fetches++;
        return List<int>.filled(1024, 7);
      },
    );
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  AudioTrack track(int ayah) => AudioTrack(
    id: 'Alafasy_128kbps:001${ayah.toString().padLeft(3, '0')}',
    reciterId: 'Alafasy_128kbps',
    reciterName: 'مشاري العفاسي',
    surah: 1,
    ayah: ayah,
    surahName: 'الفاتحة',
    url: QuranAudioCatalog.ayahUrl('Alafasy_128kbps', 1, ayah),
  );

  test('downloads files, skips existing ones and reports size', () async {
    final progress = <String>[];
    await store.downloadTracks([
      for (var ayah = 1; ayah <= 3; ayah++) track(ayah),
    ], onProgress: (done, total) => progress.add('$done/$total'));

    expect(fetches, 3);
    expect(store.surahDownloaded('Alafasy_128kbps', 1, 3), isTrue);
    expect(store.fileFor('Alafasy_128kbps', 1, 2).lengthSync(), 1024);
    expect(progress.last, '3/3');
    expect(store.bytesFor('Alafasy_128kbps'), 3 * 1024);
    expect(store.localPath('Alafasy_128kbps', 1, 1), startsWith('file://'));

    await store.downloadTracks([
      for (var ayah = 1; ayah <= 3; ayah++) track(ayah),
    ]);
    expect(fetches, 3, reason: 'existing files must not be fetched again');
  });

  test('delete removes a surah folder', () async {
    await store.downloadTracks([track(1), track(2)]);
    store.deleteSurah('Alafasy_128kbps', 1);

    expect(store.surahDownloaded('Alafasy_128kbps', 1, 2), isFalse);
    expect(store.bytesFor('Alafasy_128kbps'), 0);
  });

  test('manager keeps a whole-surah download and exposes local urls', () async {
    final manager = AudioDownloadManager(store);
    addTearDown(manager.dispose);
    final reciter = QuranAudioCatalog.reciters.first;
    const surah = Surah(
      number: 1,
      name: 'الفاتحة',
      englishName: 'Al-Fatiha',
      meaning: 'The Opening',
      ayahCount: 7,
      revelation: 'makkah',
    );

    await manager.downloadSurah(reciter, surah);

    expect(manager.running, isFalse);
    expect(manager.error, isNull);
    expect(manager.isDownloaded(1), isTrue);
    expect(manager.downloadedSurahs, contains(1));
    expect(manager.bytes, greaterThan(0));

    final remote = QuranAudioCatalog.surahQueue(
      reciter: reciter,
      surah: 1,
      surahName: 'الفاتحة',
      ayahCount: 7,
    ).first;
    expect(manager.localTrack(remote).url, startsWith('file://'));
  });
}
