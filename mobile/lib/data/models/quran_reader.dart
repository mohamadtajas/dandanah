class ReaderPosition {
  const ReaderPosition({
    required this.surah,
    required this.ayah,
    required this.updatedAt,
  });

  final int surah;
  final int ayah;
  final DateTime updatedAt;
}

class QuranBookmark {
  const QuranBookmark({
    required this.surah,
    required this.ayah,
    required this.createdAt,
  });

  final int surah;
  final int ayah;
  final DateTime createdAt;
}
