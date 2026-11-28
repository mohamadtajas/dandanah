class AudioReciter {
  const AudioReciter({
    required this.id,
    required this.name,
    required this.englishName,
    required this.style,
    required this.bitrate,
  });

  final String id;
  final String name;
  final String englishName;
  final String style;
  final int bitrate;
}

class AudioTrack {
  const AudioTrack({
    required this.id,
    required this.reciterId,
    required this.reciterName,
    required this.surah,
    required this.ayah,
    required this.surahName,
    required this.url,
    this.subtitleOverride,
  });

  final String id;
  final String reciterId;
  final String reciterName;
  final int surah;
  final int ayah;
  final String surahName;
  final String url;
  final String? subtitleOverride;

  String get title => surahName;
  String get subtitle => subtitleOverride ?? 'آية $ayah';

  /// Returns a copy pointing at a local file when the surah is downloaded.
  AudioTrack withUrl(String url) => AudioTrack(
    id: id,
    reciterId: reciterId,
    reciterName: reciterName,
    surah: surah,
    ayah: ayah,
    surahName: surahName,
    url: url,
    subtitleOverride: subtitleOverride,
  );
}

enum AudioRepeatMode { off, one, all }
