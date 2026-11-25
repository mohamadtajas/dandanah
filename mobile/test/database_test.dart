import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';

import 'generated_migrations/schema.dart';

void main() {
  test(
    'fresh database contains content and user tables at version 3',
    () async {
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
      expect(version, 3);

      final foreignKeys = await db
          .customSelect('PRAGMA foreign_keys')
          .map((row) => row.read<int>('foreign_keys'))
          .getSingle();
      expect(foreignKeys, 1);

      final prayer = await _columns(db, 'prayer_logs');
      expect(prayer['date'], 'TEXT');
      expect(prayer['prayer'], 'TEXT');
      expect(prayer['status'], 'TEXT');

      final adhkarLogs = await _columns(db, 'adhkar_logs');
      expect(adhkarLogs['local_date'], 'TEXT');
    },
  );

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
    await verifier.migrateAndValidate(db, 3);

    final surahs = await db.select(db.surahs).get();
    expect(surahs, hasLength(1));
    expect(surahs.single.name, 'الفاتحة');
    expect(await db.select(db.ayahs).get(), hasLength(1));
    expect(await db.select(db.bookmarks).get(), isEmpty);
    expect(await db.select(db.settings).get(), isEmpty);

    await db.close();
  });

  test(
    'v2 prayer and adhkar logs survive the v3 local-date migration',
    () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final old = await verifier.schemaAt(2);
      final noon = DateTime(2026, 11, 26, 12).millisecondsSinceEpoch ~/ 1000;
      old.rawDatabase.execute(
        'INSERT INTO prayer_logs (date, prayer, status) VALUES (?, ?, ?)',
        [noon, 'fajr', 'done'],
      );
      old.rawDatabase.execute(
        'INSERT INTO adhkar_logs (streak_key, completed_at) VALUES (?, ?)',
        ['morning', noon],
      );

      final db = AppDatabase(old.newConnection());
      await verifier.migrateAndValidate(db, 3);

      final prayers = await db
          .customSelect('SELECT date, prayer, status FROM prayer_logs')
          .get();
      expect(prayers, hasLength(1));
      expect(prayers.single.read<String>('date'), '2026-11-26');
      expect(prayers.single.read<String>('prayer'), 'fajr');
      expect(prayers.single.read<String>('status'), 'done');

      final logs = await db
          .customSelect('SELECT local_date FROM adhkar_logs')
          .get();
      expect(logs, hasLength(1));
      expect(logs.single.read<String>('local_date'), '2026-11-26');

      await db.close();
    },
  );

  test('a failed upgrade rolls back every earlier migration step', () async {
    final verifier = SchemaVerifier(GeneratedHelper());
    final old = await verifier.schemaAt(1);
    old.rawDatabase.execute('CREATE TABLE prayer_logs (x TEXT)');

    final db = AppDatabase(old.newConnection());
    await expectLater(verifier.migrateAndValidate(db, 3), throwsA(anything));

    final tables = old.rawDatabase
        .select("SELECT name FROM sqlite_master WHERE type = 'table'")
        .map((row) => row['name'] as String)
        .toList();
    expect(tables, isNot(contains('settings')));
    expect(tables, isNot(contains('bookmarks')));

    final version = old.rawDatabase
        .select('PRAGMA user_version')
        .first['user_version'];
    expect(version, 1);

    await db.close();
  });
}

Future<Map<String, String>> _columns(GeneratedDatabase db, String table) async {
  final rows = await db.customSelect('PRAGMA table_info($table)').get();
  return {
    for (final row in rows) row.read<String>('name'): row.read<String>('type'),
  };
}
