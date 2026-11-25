import 'package:drift/drift.dart';

import '../db/app_database.dart' as db;
import '../models/adhkar.dart';
import '../models/local_date.dart';
import '../worship/adhkar_practice.dart';

abstract interface class AdhkarPracticeRepository {
  Future<Map<String, int>> completedCounts(List<AdhkarItem> items, String date);

  Future<AdhkarCategoryProgress> categoryProgress(
    AdhkarCategory category,
    String date,
  );

  Future<Map<String, AdhkarCategoryProgress>> allCategoryProgress(String date);

  Future<AdhkarTapResult> increment(
    AdhkarCategory category,
    AdhkarItem item,
    String date,
  );

  Future<void> resetItem(AdhkarCategory category, AdhkarItem item, String date);

  Future<void> resetCategory(AdhkarCategory category, String date);

  Future<AdhkarStreak> streak(String today);

  Future<List<AdhkarDay>> days();
}

class DriftAdhkarPracticeRepository implements AdhkarPracticeRepository {
  DriftAdhkarPracticeRepository(this._db);

  final db.AppDatabase _db;

  @override
  Future<Map<String, int>> completedCounts(
    List<AdhkarItem> items,
    String date,
  ) async {
    if (items.isEmpty) return {};
    final ids = items.map((item) => item.id).toList();
    final rows = await (_db.select(
      _db.adhkarProgress,
    )..where((row) => row.itemId.isIn(ids) & row.localDate.equals(date))).get();
    return {for (final row in rows) row.itemId: row.completedCount};
  }

  @override
  Future<Map<String, AdhkarCategoryProgress>> allCategoryProgress(
    String date,
  ) async {
    final items = await _db.select(_db.adhkarItems).get();
    final progress = await (_db.select(
      _db.adhkarProgress,
    )..where((row) => row.localDate.equals(date))).get();
    final counts = {for (final row in progress) row.itemId: row.completedCount};

    final byCategory = <String, List<db.AdhkarItem>>{};
    for (final item in items) {
      byCategory.putIfAbsent(item.categoryId, () => []).add(item);
    }

    return {
      for (final entry in byCategory.entries)
        entry.key: _summary(entry.value, counts),
    };
  }

  @override
  Future<AdhkarCategoryProgress> categoryProgress(
    AdhkarCategory category,
    String date,
  ) async {
    final items = await _itemsFor(category.id);
    final counts = await completedCounts(items, date);
    var completedItems = 0;
    var completedRepeats = 0;
    var totalRepeats = 0;
    for (final item in items) {
      final done = (counts[item.id] ?? 0).clamp(0, item.repeatCount);
      completedRepeats += done;
      totalRepeats += item.repeatCount;
      if (done >= item.repeatCount) completedItems++;
    }
    return AdhkarCategoryProgress(
      completedItems: completedItems,
      totalItems: items.length,
      completedRepeats: completedRepeats,
      totalRepeats: totalRepeats,
    );
  }

  @override
  Future<AdhkarTapResult> increment(
    AdhkarCategory category,
    AdhkarItem item,
    String date,
  ) async {
    return _db.transaction(() async {
      final current = await _completedCount(item.id, date);
      if (current >= item.repeatCount) {
        return AdhkarTapResult(
          itemCompleted: true,
          categoryCompleted: (await categoryProgress(category, date)).complete,
        );
      }
      final next = current + 1;
      await _db
          .into(_db.adhkarProgress)
          .insertOnConflictUpdate(
            db.AdhkarProgressCompanion.insert(
              itemId: item.id,
              localDate: Value(date),
              completedCount: next,
              updatedAt: DateTime.now(),
            ),
          );
      if (next < item.repeatCount) {
        return const AdhkarTapResult(
          itemCompleted: false,
          categoryCompleted: false,
        );
      }
      return AdhkarTapResult(
        itemCompleted: true,
        categoryCompleted: await _completeCategoryIfDone(category, date),
      );
    });
  }

  @override
  Future<void> resetItem(
    AdhkarCategory category,
    AdhkarItem item,
    String date,
  ) async {
    await (_db.delete(
      _db.adhkarProgress,
    )..where((row) => row.itemId.equals(item.id))).go();
    await _deleteStreakLog(category, date);
  }

  @override
  Future<void> resetCategory(AdhkarCategory category, String date) async {
    final items = await _itemsFor(category.id);
    if (items.isNotEmpty) {
      final ids = items.map((item) => item.id).toList();
      await (_db.delete(
        _db.adhkarProgress,
      )..where((row) => row.itemId.isIn(ids))).go();
    }
    await _deleteStreakLog(category, date);
  }

  Future<void> _deleteStreakLog(AdhkarCategory category, String date) async {
    final key = category.streakKey;
    if (key == null || key.isEmpty) return;
    await (_db.delete(_db.adhkarLogs)..where(
          (row) => row.streakKey.equals(key) & row.localDate.equals(date),
        ))
        .go();
  }

  @override
  Future<AdhkarStreak> streak(String today) async =>
      computeAdhkarStreak(await days(), today);

  @override
  Future<List<AdhkarDay>> days() async {
    final rows = await _db.select(_db.adhkarLogs).get();
    final byDate = <String, AdhkarDay>{};
    for (final row in rows) {
      final date = row.localDate.isEmpty
          ? localDateKey(row.completedAt)
          : row.localDate;
      final current = byDate[date] ?? AdhkarDay(date: date);
      byDate[date] = AdhkarDay(
        date: date,
        morning: current.morning || row.streakKey == 'morning',
        evening: current.evening || row.streakKey == 'evening',
      );
    }
    return byDate.values.toList();
  }

  AdhkarCategoryProgress _summary(
    List<db.AdhkarItem> items,
    Map<String, int> counts,
  ) {
    var completedItems = 0;
    var completedRepeats = 0;
    var totalRepeats = 0;
    for (final item in items) {
      final done = (counts[item.id] ?? 0).clamp(0, item.repeatCount);
      completedRepeats += done;
      totalRepeats += item.repeatCount;
      if (done >= item.repeatCount) completedItems++;
    }
    return AdhkarCategoryProgress(
      completedItems: completedItems,
      totalItems: items.length,
      completedRepeats: completedRepeats,
      totalRepeats: totalRepeats,
    );
  }

  Future<List<AdhkarItem>> _itemsFor(String categoryId) async {
    final rows =
        await (_db.select(_db.adhkarItems)
              ..where((row) => row.categoryId.equals(categoryId))
              ..orderBy([(row) => OrderingTerm.asc(row.sortOrder)]))
            .get();
    return rows
        .map(
          (row) => AdhkarItem(
            id: row.id,
            categoryId: row.categoryId,
            text: row.body,
            repeatCount: row.repeatCount,
            reference: row.source,
          ),
        )
        .toList();
  }

  Future<int> _completedCount(String itemId, String date) async {
    final row =
        await (_db.select(_db.adhkarProgress)..where(
              (entry) =>
                  entry.itemId.equals(itemId) & entry.localDate.equals(date),
            ))
            .getSingleOrNull();
    return row?.completedCount ?? 0;
  }

  Future<bool> _completeCategoryIfDone(
    AdhkarCategory category,
    String date,
  ) async {
    final progress = await categoryProgress(category, date);
    if (!progress.complete) return false;

    final streakKey = category.streakKey;
    if (streakKey == null ||
        !const {'morning', 'evening'}.contains(streakKey)) {
      return true;
    }

    final existing =
        await (_db.select(_db.adhkarLogs)..where(
              (row) =>
                  row.streakKey.equals(streakKey) & row.localDate.equals(date),
            ))
            .get();
    if (existing.isEmpty) {
      await _db
          .into(_db.adhkarLogs)
          .insert(
            db.AdhkarLogsCompanion.insert(
              streakKey: streakKey,
              localDate: Value(date),
              completedAt: DateTime.now(),
            ),
          );
    }
    return true;
  }
}
