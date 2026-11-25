import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'schema_versions.dart';

part 'app_database.g.dart';

/// Surah metadata, exactly as bundled from the Tanzil Uthmani source.
class Surahs extends Table {
  IntColumn get number => integer()();
  TextColumn get name => text()();
  TextColumn get englishName => text()();
  TextColumn get meaning => text()();
  IntColumn get ayahCount => integer()();
  TextColumn get revelation => text()();
  TextColumn get bismillah => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {number};
}

@TableIndex(name: 'ayahs_juz', columns: {#juz})
@TableIndex(name: 'ayahs_page', columns: {#page})
class Ayahs extends Table {
  IntColumn get surah => integer().references(Surahs, #number)();
  IntColumn get ayah => integer()();
  TextColumn get body => text()();
  IntColumn get juz => integer()();
  IntColumn get page => integer()();
  BoolColumn get sajda => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {surah, ayah};
}

class Juzs extends Table {
  IntColumn get number => integer()();
  IntColumn get surah => integer().references(Surahs, #number)();
  IntColumn get ayah => integer()();
  IntColumn get ayahCount => integer()();

  @override
  Set<Column<Object>> get primaryKey => {number};
}

class QuranPages extends Table {
  IntColumn get number => integer()();
  IntColumn get surah => integer().references(Surahs, #number)();
  IntColumn get ayah => integer()();

  @override
  Set<Column<Object>> get primaryKey => {number};
}

class AdhkarCategories extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  BoolColumn get featured => boolean()();
  TextColumn get streakKey => text().nullable()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(name: 'adhkar_items_category', columns: {#categoryId})
class AdhkarItems extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().references(AdhkarCategories, #id)();
  TextColumn get body => text()();
  IntColumn get repeatCount => integer()();
  TextColumn get source => text()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Offline database. Content is seeded once from bundled assets; later phases
/// add user state through explicit migrations.
@DriftDatabase(
  tables: [
    Surahs,
    Ayahs,
    Juzs,
    QuranPages,
    AdhkarCategories,
    AdhkarItems,
    Settings,
    Bookmarks,
    ReaderState,
    AdhkarProgress,
    AdhkarLogs,
    PrayerLogs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  AppDatabase.memory() : super(NativeDatabase.memory());

  static Future<AppDatabase> open() async {
    final directory = await getApplicationSupportDirectory();
    final file = File(p.join(directory.path, 'sakeenah.sqlite'));
    return AppDatabase(NativeDatabase.createInBackground(file));
  }

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      final steps = migrationSteps(
        from1To2: (m, schema) async {
          await m.createTable(schema.settings);
          await m.createTable(schema.bookmarks);
          await m.createIndex(schema.bookmarksAyah);
          await m.createTable(schema.readerState);
          await m.createTable(schema.adhkarProgress);
          await m.createTable(schema.adhkarLogs);
          await m.createIndex(schema.adhkarLogsStreak);
          await m.createTable(schema.prayerLogs);
          await m.createIndex(schema.prayerLogsDate);
        },
        from2To3: (m, schema) async {
          // Streak logs gain a stable local calendar date. Existing rows are
          // backfilled from their instant using the device's local timezone.
          await m.addColumn(schema.adhkarLogs, schema.adhkarLogs.localDate);
          await m.database.customStatement(
            "UPDATE adhkar_logs "
            "SET local_date = date(completed_at, 'unixepoch', 'localtime')",
          );
          await m.database.customStatement(
            'DROP INDEX IF EXISTS adhkar_logs_streak',
          );
          await m.createIndex(schema.adhkarLogsStreak);

          // Prayer logs move from an instant to a YYYY-MM-DD local date so
          // streak grouping and timezone changes cannot create duplicate days.
          await m.database.customStatement(
            'ALTER TABLE prayer_logs RENAME TO prayer_logs_v2',
          );
          await m.createTable(schema.prayerLogs);
          await m.database.customStatement(
            'INSERT INTO prayer_logs (date, prayer, status) '
            "SELECT date(date, 'unixepoch', 'localtime'), prayer, status "
            'FROM prayer_logs_v2',
          );
          await m.database.customStatement('DROP TABLE prayer_logs_v2');
        },
      );

      // Drift updates user_version after each step, so a failure leaves the
      // database on the last completed version and the step can be retried.
      await migrator.runMigrationSteps(
        from: from,
        to: to,
        steps: (version, database) =>
            database.transaction(() => steps(version, database)),
      );
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@TableIndex(name: 'bookmarks_ayah', columns: {#surah, #ayah}, unique: true)
class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get surah => integer()();
  IntColumn get ayah => integer()();
  DateTimeColumn get createdAt => dateTime()();
}

/// The single row (id = 1) remembering where reading stopped.
class ReaderState extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get surah => integer()();
  IntColumn get ayah => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AdhkarProgress extends Table {
  TextColumn get itemId => text()();
  IntColumn get completedCount => integer()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {itemId};
}

@TableIndex(name: 'adhkar_logs_streak', columns: {#streakKey, #localDate})
class AdhkarLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get streakKey => text()();
  TextColumn get localDate => text().withDefault(const Constant(''))();
  DateTimeColumn get completedAt => dateTime()();
}

class PrayerLogs extends Table {
  TextColumn get date => text()();
  TextColumn get prayer => text()();
  TextColumn get status => text()();

  @override
  Set<Column<Object>> get primaryKey => {date, prayer};
}
