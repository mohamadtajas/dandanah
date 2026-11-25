import 'package:drift/drift.dart';

import '../db/app_database.dart' as db;
import '../models/quran_reader.dart';
import '../settings_store.dart';

abstract interface class QuranReaderRepository {
  static const fontSizeKey = 'quran.fontSize';
  static const defaultFontSize = 28;
  static const minFontSize = 20;
  static const maxFontSize = 44;

  Future<ReaderPosition?> position();

  Future<void> savePosition(int surah, int ayah);

  Future<List<QuranBookmark>> bookmarks();

  Future<bool> isBookmarked(int surah, int ayah);

  Future<void> toggleBookmark(int surah, int ayah);

  Future<void> removeBookmark(int surah, int ayah);

  Future<int> fontSize();

  Future<void> saveFontSize(int size);
}

class DriftQuranReaderRepository implements QuranReaderRepository {
  DriftQuranReaderRepository(this._db);

  final db.AppDatabase _db;

  @override
  Future<ReaderPosition?> position() async {
    final row = await (_db.select(
      _db.readerState,
    )..where((table) => table.id.equals(1))).getSingleOrNull();
    if (row == null) return null;
    return ReaderPosition(
      surah: row.surah,
      ayah: row.ayah,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<void> savePosition(int surah, int ayah) async {
    await _db
        .into(_db.readerState)
        .insertOnConflictUpdate(
          db.ReaderStateCompanion.insert(
            id: const Value(1),
            surah: surah,
            ayah: ayah,
            updatedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<List<QuranBookmark>> bookmarks() async {
    final rows =
        await (_db.select(_db.bookmarks)..orderBy([
              (table) => OrderingTerm.desc(table.createdAt),
              (table) => OrderingTerm.desc(table.id),
            ]))
            .get();
    return rows
        .map(
          (row) => QuranBookmark(
            surah: row.surah,
            ayah: row.ayah,
            createdAt: row.createdAt,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<bool> isBookmarked(int surah, int ayah) async =>
      await _bookmarkRow(surah, ayah) != null;

  @override
  Future<void> toggleBookmark(int surah, int ayah) async {
    await _db.transaction(() async {
      final existing = await _bookmarkRow(surah, ayah);
      if (existing == null) {
        await _db
            .into(_db.bookmarks)
            .insert(
              db.BookmarksCompanion.insert(
                surah: surah,
                ayah: ayah,
                createdAt: DateTime.now(),
              ),
            );
      } else {
        await (_db.delete(
          _db.bookmarks,
        )..where((row) => row.id.equals(existing.id))).go();
      }
    });
  }

  @override
  Future<void> removeBookmark(int surah, int ayah) async {
    await (_db.delete(
      _db.bookmarks,
    )..where((row) => row.surah.equals(surah) & row.ayah.equals(ayah))).go();
  }

  @override
  Future<int> fontSize() async {
    final stored = await SettingsStore.readInt(
      _db,
      QuranReaderRepository.fontSizeKey,
    );
    return (stored ?? QuranReaderRepository.defaultFontSize).clamp(
      QuranReaderRepository.minFontSize,
      QuranReaderRepository.maxFontSize,
    );
  }

  @override
  Future<void> saveFontSize(int size) async {
    final safe = size.clamp(
      QuranReaderRepository.minFontSize,
      QuranReaderRepository.maxFontSize,
    );
    await SettingsStore.write(_db, QuranReaderRepository.fontSizeKey, '$safe');
  }

  Future<db.Bookmark?> _bookmarkRow(int surah, int ayah) =>
      (_db.select(_db.bookmarks)
            ..where((row) => row.surah.equals(surah) & row.ayah.equals(ayah)))
          .getSingleOrNull();
}
