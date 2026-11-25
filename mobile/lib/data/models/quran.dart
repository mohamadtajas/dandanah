/// Immutable Quran domain models, independent of the database layer.
class Surah {
  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.meaning,
    required this.ayahCount,
    required this.revelation,
    this.bismillah,
  });

  final int number;
  final String name;
  final String englishName;
  final String meaning;
  final int ayahCount;
  final String revelation;
  final String? bismillah;

  bool get isMakkan => revelation == 'makkah';
}

class Ayah {
  const Ayah({
    required this.surah,
    required this.number,
    required this.text,
    required this.juz,
    required this.page,
    this.sajda = false,
  });

  final int surah;
  final int number;
  final String text;
  final int juz;
  final int page;
  final bool sajda;
}

class Juz {
  const Juz({
    required this.number,
    required this.surah,
    required this.ayah,
    required this.ayahCount,
  });

  final int number;
  final int surah;
  final int ayah;
  final int ayahCount;
}

class QuranPage {
  const QuranPage({
    required this.number,
    required this.surah,
    required this.ayah,
  });

  final int number;
  final int surah;
  final int ayah;
}

typedef SajdaAyah = ({int surah, int ayah});
