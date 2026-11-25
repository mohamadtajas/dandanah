import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/data/repositories/quran_repository.dart';
import 'package:sakeenah_mobile/data/seed/quran_seeder.dart';

void main() {
  late AppDatabase db;
  late QuranRepository quran;
  late Map<(int, int), String> source;
  late Map<(int, int), ({String text, int juz, int page, bool sajda})>
  sourceRows;

  setUp(() async {
    db = AppDatabase.memory();
    final raw = await File('assets/data/quran.json').readAsString();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final ayahs = (data['ayahs'] as List).cast<Map<String, dynamic>>();
    source = {
      for (final ayah in ayahs)
        (ayah['surah'] as int, ayah['ayah'] as int): ayah['text'] as String,
    };
    sourceRows = {
      for (final ayah in ayahs)
        (ayah['surah'] as int, ayah['ayah'] as int): (
          text: ayah['text'] as String,
          juz: ayah['juz'] as int,
          page: ayah['page'] as int,
          sajda: ayah['sajda'] as bool? ?? false,
        ),
    };
    await QuranSeeder.seed(db, raw);
    quran = DriftQuranRepository(db);
  });

  tearDown(() => db.close());

  test('bundle contains the full Quran with accurate counts', () async {
    final surahs = await quran.surahs();
    expect(surahs, hasLength(114));
    expect(surahs.first.ayahCount, 7);
    expect(surahs[1].ayahCount, 286);
    expect(surahs.last.number, 114);

    expect(await quran.ayahCount(), 6236);
    expect(surahs.map((s) => s.ayahCount).reduce((a, b) => a + b), 6236);
  });

  test('surah reads return ordered ayahs unchanged from the source', () async {
    final fatiha = await quran.ayahsForSurah(1);
    expect(fatiha, hasLength(7));
    expect(fatiha.first.surah, 1);
    expect(fatiha.first.number, 1);
    expect(fatiha.first.text, source[(1, 1)]);

    final baqarah = await quran.ayahsForSurah(2);
    expect(baqarah, hasLength(286));
    expect(baqarah.first.text, source[(2, 1)]);
    expect(_bare(baqarah.first.text), 'الم');

    final nas = await quran.ayahsForSurah(114);
    expect(nas, hasLength(6));
    expect(nas.last.text, source[(114, 6)]);
    expect(_bare(nas.last.text), 'من الجنة والناس');
  });

  test('every stored ayah matches the bundled source exactly', () async {
    final rows = await db.select(db.ayahs).get();
    expect(rows, hasLength(6236));
    for (final row in rows) {
      final expected = sourceRows[(row.surah, row.ayah)];
      expect(expected, isNotNull, reason: 'missing ${row.surah}:${row.ayah}');
      expect(row.body, expected!.text);
      expect(row.juz, expected.juz, reason: 'juz ${row.surah}:${row.ayah}');
      expect(row.page, expected.page, reason: 'page ${row.surah}:${row.ayah}');
      expect(
        row.sajda,
        expected.sajda,
        reason: 'sajda ${row.surah}:${row.ayah}',
      );
    }
    expect(
      rows.map((row) => (row.surah, row.ayah)).toSet(),
      sourceRows.keys.toSet(),
    );
  });

  test('basmala is separate except Al-Fatiha and At-Tawba', () async {
    expect((await quran.surahByNumber(1))!.bismillah, isNull);
    expect((await quran.surahByNumber(9))!.bismillah, isNull);
    final baqarah = await quran.surahByNumber(2);
    expect(baqarah!.bismillah, isNotNull);
    expect(baqarah.bismillah, startsWith('بِسْمِ'));

    final first = await quran.ayah(2, 1);
    expect(first!.text, 'الٓمٓ');
    expect(first.text.contains('بِسْمِ'), isFalse);

    final count = (await quran.surahs())
        .where((surah) => surah.bismillah != null)
        .length;
    expect(count, 112);
  });

  test('known ayah carries juz, page and sajda metadata', () async {
    final kursi = await quran.ayah(2, 255);
    expect(kursi, isNotNull);
    expect(kursi!.text, source[(2, 255)]);
    expect(_bare(kursi.text), startsWith('الله لا إله إلا هو الحي القيوم'));
    expect(kursi.juz, 3);
    expect(kursi.page, 42);

    final surah = await quran.surahByNumber(2);
    expect(surah?.revelation, 'madinah');
    expect(surah?.englishName, 'Al-Baqara');

    expect(await quran.ayah(2, 300), isNull);
    expect(await quran.surahByNumber(115), isNull);
    expect(await quran.ayahsForSurah(115), isEmpty);
  });

  test('juz and page boundaries cover the whole text once', () async {
    final juzs = await quran.juzs();
    expect(juzs, hasLength(30));
    expect(juzs.map((j) => j.ayahCount).reduce((a, b) => a + b), 6236);

    final first = await quran.ayahsForJuz(1);
    expect(first, hasLength(148));
    expect((first.first.surah, first.first.number), (1, 1));

    final second = await quran.ayahsForJuz(2);
    expect((second.first.surah, second.first.number), (2, 142));

    final last = await quran.ayahsForJuz(30);
    expect(last, hasLength(564));
    expect((last.first.surah, last.first.number), (78, 1));
    expect((last.last.surah, last.last.number), (114, 6));

    final pages = await quran.pages();
    expect(pages, hasLength(604));
    expect(
      (pages.first.number, pages.first.surah, pages.first.ayah),
      (1, 1, 1),
    );
    expect(pages.last.number, 604);
  });

  test('all fifteen sajda ayahs are flagged', () async {
    final flagged = await quran.sajdaAyahs();
    expect(flagged, hasLength(15));
    expect(flagged, contains((surah: 7, ayah: 206)));
  });

  test('seeding is idempotent and reports readiness', () async {
    final fresh = AppDatabase.memory();
    addTearDown(fresh.close);
    final repo = DriftQuranRepository(fresh);
    expect(await repo.isSeeded(), isFalse);

    final json = await File('assets/data/quran.json').readAsString();
    await QuranSeeder.seed(fresh, json);
    expect(await repo.isSeeded(), isTrue);
    await QuranSeeder.seed(fresh, json);

    expect(await repo.ayahCount(), 6236);
    expect(await repo.surahs(), hasLength(114));
  });
}

/// Removes Arabic combining marks so content checks do not depend on the
/// canonical order of shadda/fatha in a hand-written literal.
String _bare(String text) => text
    .replaceAll('\u0671', '\u0627')
    .replaceAll(RegExp('[\u064B-\u065F\u0670\u06D6-\u06ED]'), '')
    .replaceAll('\u0649', '\u064A');
