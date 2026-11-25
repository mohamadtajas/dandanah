import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/data/models/local_date.dart';
import 'package:sakeenah_mobile/data/repositories/quran_repository.dart';
import 'package:sakeenah_mobile/data/seed/quran_seeder.dart';
import 'package:sakeenah_mobile/data/worship/daily_ayah.dart';

void main() {
  test('daily ayah ordinal is stable and inside the Quran', () {
    final first = dailyAyahOrdinal('2026-11-26');
    expect(dailyAyahOrdinal('2026-11-26'), first);
    expect(first, inInclusiveRange(1, 6236));
    expect(dailyAyahOrdinal('2026-11-27'), isNot(first));
    expect(dailyAyahOrdinal('2026-11-27'), inInclusiveRange(1, 6236));
  });

  test('a year of dates maps to many different ayat', () {
    final ordinals = {
      for (var day = 0; day < 365; day++)
        dailyAyahOrdinal(
          localDateKey(DateTime(2026, 1, 1).add(Duration(days: day))),
        ),
    };
    expect(ordinals.length, greaterThan(330));
  });

  test('ayahByOrdinal starts at Al-Fatiha 1 and handles bounds', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await QuranSeeder.seed(
      db,
      await File('assets/data/quran.json').readAsString(),
    );
    final quran = DriftQuranRepository(db);

    final first = await quran.ayahByOrdinal(1);
    expect(first, isNotNull);
    expect(first!.surah, 1);
    expect(first.number, 1);

    final last = await quran.ayahByOrdinal(6236);
    expect(last!.surah, 114);
    expect(last.number, 6);
    expect(await quran.ayahByOrdinal(0), isNull);
    expect(await quran.ayahByOrdinal(6237), isNull);
  });
}
