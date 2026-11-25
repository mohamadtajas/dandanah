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
  });

  final String id;
  final String reciterId;
  final String reciterName;
  final int surah;
  final int ayah;
  final String surahName;
  final String url;

  String get title => surahName;
  String get subtitle => 'آية $ayah';
}

enum AudioRepeatMode { off, one, all }
