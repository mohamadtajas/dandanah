import '../models/audio.dart';

abstract final class QuranAudioCatalog {
  static const provider = 'everyayah';
  static const baseUrl = 'https://everyayah.com/data';

  static const reciters = <AudioReciter>[
    AudioReciter(
      id: 'Alafasy_128kbps',
      name: 'مشاري العفاسي',
      englishName: 'Mishary Alafasy',
      style: 'مرتل',
      bitrate: 128,
    ),
    AudioReciter(
      id: 'Husary_128kbps',
      name: 'محمود خليل الحصري',
      englishName: 'Mahmoud Al-Husary',
      style: 'مرتل',
      bitrate: 128,
    ),
    AudioReciter(
      id: 'Minshawy_Murattal_128kbps',
      name: 'محمد صديق المنشاوي',
      englishName: 'Al-Minshawi',
      style: 'مرتل',
      bitrate: 128,
    ),
    AudioReciter(
      id: 'Abdul_Basit_Murattal_192kbps',
      name: 'عبد الباسط عبد الصمد',
      englishName: 'Abdul Basit',
      style: 'مرتل',
      bitrate: 192,
    ),
    AudioReciter(
      id: 'Abdurrahmaan_As-Sudais_192kbps',
      name: 'عبد الرحمن السديس',
      englishName: 'Abdurrahman As-Sudais',
      style: 'مرتل',
      bitrate: 192,
    ),
    AudioReciter(
      id: 'Saood_ash-Shuraym_128kbps',
      name: 'سعود الشريم',
      englishName: 'Saud Ash-Shuraym',
      style: 'مرتل',
      bitrate: 128,
    ),
    AudioReciter(
      id: 'MaherAlMuaiqly128kbps',
      name: 'ماهر المعيقلي',
      englishName: 'Maher Al-Muaiqly',
      style: 'مرتل',
      bitrate: 128,
    ),
    AudioReciter(
      id: 'Ghamadi_40kbps',
      name: 'سعد الغامدي',
      englishName: 'Saad Al-Ghamdi',
      style: 'مرتل',
      bitrate: 40,
    ),
  ];

  static AudioReciter? reciter(String id) {
    for (final reciter in reciters) {
      if (reciter.id == id) return reciter;
    }
    return null;
  }

  static String ayahUrl(String reciterId, int surah, int ayah) {
    final surahPart = surah.toString().padLeft(3, '0');
    final ayahPart = ayah.toString().padLeft(3, '0');
    return '$baseUrl/$reciterId/$surahPart$ayahPart.mp3';
  }

  static List<AudioTrack> surahQueue({
    required AudioReciter reciter,
    required int surah,
    required String surahName,
    required int ayahCount,
  }) => [
    for (var ayah = 1; ayah <= ayahCount; ayah++)
      AudioTrack(
        id: '${reciter.id}:${surah.toString().padLeft(3, '0')}${ayah.toString().padLeft(3, '0')}',
        reciterId: reciter.id,
        reciterName: reciter.name,
        surah: surah,
        ayah: ayah,
        surahName: surahName,
        url: ayahUrl(reciter.id, surah, ayah),
      ),
  ];
}
