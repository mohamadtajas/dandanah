import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';

import 'generated_migrations/schema.dart';

void main() {
  test('fresh database contains content and user tables at version 2', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    final tables = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .map((row) => row.read<String>('name'))
        .get();

    expect(
      tables,
      containsAll([
        'surahs',
        'ayahs',
        'juzs',
        'quran_pages',
        'adhkar_categories',
        'adhkar_items',
        'settings',
        'bookmarks',
        'reader_state',
        'adhkar_progress',
        'adhkar_logs',
        'prayer_logs',
      ]),
    );

    final version = await db
        .customSelect('PRAGMA user_version')
        .map((row) => row.read<int>('user_version'))
        .getSingle();
    expect(version, 2);

    final foreignKeys = await db
        .customSelect('PRAGMA foreign_keys')
        .map((row) => row.read<int>('foreign_keys'))
        .getSingle();
    expect(foreignKeys, 1);
  });

  test('upgrade from v1 keeps Quran content and adds user tables', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final old = await verifier.schemaAt(1);
    old.rawDatabase.execute(
      'INSERT INTO surahs '
      '(number, name, english_name, meaning, ayah_count, revelation, bismillah) '
      "VALUES (1, 'الفاتحة', 'Al-Faatiha', 'The Opening', 7, 'makkah', NULL)",
    );
    old.rawDatabase.execute(
      "INSERT INTO ayahs (surah, ayah, body, juz, page, sajda) "
      "VALUES (1, 1, 'بِسْمِ ٱللَّهِ', 1, 1, 0)",
    );

    final db = AppDatabase(old.newConnection());
    await verifier.migrateAndValidate(db, 2);

    final surahs = await db.select(db.surahs).get();
    expect(surahs, hasLength(1));
    expect(surahs.single.name, 'الفاتحة');
    expect(await db.select(db.ayahs).get(), hasLength(1));
    expect(await db.select(db.bookmarks).get(), isEmpty);
    expect(await db.select(db.settings).get(), isEmpty);

    await db.close();
  });
}
