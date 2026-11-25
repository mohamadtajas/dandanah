import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// Seeds the bundled Tanzil Uthmani text once. Text is copied verbatim from the
/// asset; this class never edits Quranic content.
abstract final class QuranSeeder {
  static Future<void> seed(AppDatabase db, String json) async {
    if (await db.surahs.count().getSingle() > 0) return;
    await db.transaction(() => seedInto(db, json));
  }

  /// Inserts the parsed bundle without checking or opening a transaction.
  /// Callers are responsible for doing both.
  static Future<void> seedInto(AppDatabase db, String json) async {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final surahs = (data['surahs'] as List).cast<Map<String, dynamic>>();
    final juzs = (data['juzs'] as List).cast<Map<String, dynamic>>();
    final pages = (data['pages'] as List).cast<Map<String, dynamic>>();
    final ayahs = (data['ayahs'] as List).cast<Map<String, dynamic>>();

    await db.batch((batch) {
      batch.insertAll(db.surahs, [
        for (final surah in surahs)
          SurahsCompanion.insert(
            number: Value(surah['number'] as int),
            name: surah['name'] as String,
            englishName: surah['englishName'] as String,
            meaning: surah['meaning'] as String,
            ayahCount: surah['ayahs'] as int,
            revelation: surah['revelation'] as String,
            bismillah: Value(surah['bismillah'] as String?),
          ),
      ]);
      batch.insertAll(db.juzs, [
        for (final juz in juzs)
          JuzsCompanion.insert(
            number: Value(juz['number'] as int),
            surah: juz['surah'] as int,
            ayah: juz['ayah'] as int,
            ayahCount: juz['ayahs'] as int,
          ),
      ]);
      batch.insertAll(db.quranPages, [
        for (final page in pages)
          QuranPagesCompanion.insert(
            number: Value(page['number'] as int),
            surah: page['surah'] as int,
            ayah: page['ayah'] as int,
          ),
      ]);
      batch.insertAll(db.ayahs, [
        for (final ayah in ayahs)
          AyahsCompanion.insert(
            surah: ayah['surah'] as int,
            ayah: ayah['ayah'] as int,
            body: ayah['text'] as String,
            juz: ayah['juz'] as int,
            page: ayah['page'] as int,
            sajda: Value(ayah['sajda'] as bool? ?? false),
          ),
      ]);
    });
  }
}
