import 'package:drift/drift.dart';

import '../db/app_database.dart' as db;
import '../models/quran.dart';

/// Read-only access to the bundled Quran text.
abstract interface class QuranRepository {
  Future<List<Surah>> surahs();

  Future<Surah?> surahByNumber(int number);

  Future<List<Ayah>> ayahsForSurah(int surah);

  Future<List<Ayah>> ayahsForJuz(int juz);

  Future<Ayah?> ayah(int surah, int number);

  Future<List<Juz>> juzs();

  Future<List<QuranPage>> pages();

  Future<List<SajdaAyah>> sajdaAyahs();

  Future<int> ayahCount();

  Future<bool> isSeeded();
}

class DriftQuranRepository implements QuranRepository {
  DriftQuranRepository(this._db);

  final db.AppDatabase _db;

  @override
  Future<List<Surah>> surahs() async {
    final rows = await (_db.select(
      _db.surahs,
    )..orderBy([(t) => OrderingTerm.asc(t.number)])).get();
    return rows.map(_surah).toList(growable: false);
  }

  @override
  Future<Surah?> surahByNumber(int number) async {
    final row = await (_db.select(
      _db.surahs,
    )..where((t) => t.number.equals(number))).getSingleOrNull();
    return row == null ? null : _surah(row);
  }

  @override
  Future<List<Ayah>> ayahsForSurah(int surah) async {
    final rows =
        await (_db.select(_db.ayahs)
              ..where((t) => t.surah.equals(surah))
              ..orderBy([(t) => OrderingTerm.asc(t.ayah)]))
            .get();
    return rows.map(_ayah).toList(growable: false);
  }

  @override
  Future<List<Ayah>> ayahsForJuz(int juz) async {
    final rows =
        await (_db.select(_db.ayahs)
              ..where((t) => t.juz.equals(juz))
              ..orderBy([
                (t) => OrderingTerm.asc(t.surah),
                (t) => OrderingTerm.asc(t.ayah),
              ]))
            .get();
    return rows.map(_ayah).toList(growable: false);
  }

  @override
  Future<Ayah?> ayah(int surah, int number) async {
    final row =
        await (_db.select(_db.ayahs)
              ..where((t) => t.surah.equals(surah) & t.ayah.equals(number)))
            .getSingleOrNull();
    return row == null ? null : _ayah(row);
  }

  @override
  Future<List<Juz>> juzs() async {
    final rows = await (_db.select(
      _db.juzs,
    )..orderBy([(t) => OrderingTerm.asc(t.number)])).get();
    return rows
        .map(
          (row) => Juz(
            number: row.number,
            surah: row.surah,
            ayah: row.ayah,
            ayahCount: row.ayahCount,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<QuranPage>> pages() async {
    final rows = await (_db.select(
      _db.quranPages,
    )..orderBy([(t) => OrderingTerm.asc(t.number)])).get();
    return rows
        .map(
          (row) =>
              QuranPage(number: row.number, surah: row.surah, ayah: row.ayah),
        )
        .toList(growable: false);
  }

  @override
  Future<List<SajdaAyah>> sajdaAyahs() async {
    final rows =
        await (_db.selectOnly(_db.ayahs)
              ..addColumns([_db.ayahs.surah, _db.ayahs.ayah])
              ..where(_db.ayahs.sajda.equals(true)))
            .get();
    return rows
        .map(
          (row) => (
            surah: row.read(_db.ayahs.surah)!,
            ayah: row.read(_db.ayahs.ayah)!,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<int> ayahCount() => _db.ayahs.count().getSingle();

  @override
  Future<bool> isSeeded() async =>
      await _db.surahs.count().getSingle() > 0 &&
      await _db.ayahs.count().getSingle() > 0;

  Surah _surah(db.Surah row) => Surah(
    number: row.number,
    name: row.name,
    englishName: row.englishName,
    meaning: row.meaning,
    ayahCount: row.ayahCount,
    revelation: row.revelation,
    bismillah: row.bismillah,
  );

  Ayah _ayah(db.Ayah row) => Ayah(
    surah: row.surah,
    number: row.ayah,
    text: row.body,
    juz: row.juz,
    page: row.page,
    sajda: row.sajda,
  );
}
