import '../models/audio.dart';

class IslamicRadio {
  const IslamicRadio({
    required this.id,
    required this.name,
    required this.country,
    required this.url,
  });

  final String id;
  final String name;
  final String country;
  final String url;

  AudioTrack toAudioTrack() => AudioTrack(
    id: 'radio:$id',
    reciterId: 'radio',
    reciterName: country,
    surah: 0,
    ayah: 1,
    surahName: name,
    url: url,
    subtitleOverride: 'بث مباشر',
  );
}

/// Curated, verified Islamic stations only. Every URL is HTTPS and was
/// checked for a live audio response.
const islamicRadios = <IslamicRadio>[
  IslamicRadio(
    id: 'quran_kuwait',
    name: 'إذاعة القرآن الكريم — الكويت',
    country: 'الكويت',
    url: 'https://radio.mp3islam.com/listen/quran_radio/radio.mp3',
  ),
  IslamicRadio(
    id: 'abdulbasit',
    name: 'إذاعة عبد الباسط عبد الصمد',
    country: 'الكويت',
    url: 'https://radio.mp3islam.com/listen/abdulbasit/radio.mp3',
  ),
  IslamicRadio(
    id: 'minshawi',
    name: 'إذاعة محمد صديق المنشاوي',
    country: 'الكويت',
    url: 'https://radio.mp3islam.com/listen/minshawi/radio.mp3',
  ),
  IslamicRadio(
    id: 'sharjah',
    name: 'إذاعة القرآن الكريم — الشارقة',
    country: 'الإمارات',
    url: 'https://l3.itworkscdn.net/smcquranlive/quranradiolive/icecast.audio',
  ),
  IslamicRadio(
    id: 'hussary',
    name: 'إذاعة محمود خليل الحصري',
    country: 'مصر',
    url: 'https://qurango.net/radio/mahmoud_khalil_alhussary',
  ),
  IslamicRadio(
    id: 'darusalam',
    name: 'إذاعة دار السلام',
    country: 'العراق',
    url: 'https://streams.radio.co/s0975ec186/listen',
  ),
];
