import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(settings);
        await migrator.createTable(bookmarks);
        await migrator.createIndex(bookmarksAyah);
        await migrator.createTable(readerState);
        await migrator.createTable(adhkarProgress);
        await migrator.createTable(adhkarLogs);
        await migrator.createIndex(adhkarLogsStreak);
        await migrator.createTable(prayerLogs);
        await migrator.createIndex(prayerLogsDate);
      }
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

@TableIndex(name: 'adhkar_logs_streak', columns: {#streakKey, #completedAt})
class AdhkarLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get streakKey => text()();
  DateTimeColumn get completedAt => dateTime()();
}

@TableIndex(name: 'prayer_logs_date', columns: {#date})
class PrayerLogs extends Table {
  DateTimeColumn get date => dateTime()();
  TextColumn get prayer => text()();
  TextColumn get status => text()();

  @override
  Set<Column<Object>> get primaryKey => {date, prayer};
}
