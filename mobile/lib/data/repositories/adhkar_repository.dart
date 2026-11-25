import 'package:drift/drift.dart';

import '../db/app_database.dart' as db;
import '../models/adhkar.dart';

/// Read-only access to the bundled Hisn al-Muslim collection.
abstract interface class AdhkarRepository {
  Future<List<AdhkarCategory>> categories({bool featuredOnly = false});

  Future<AdhkarCategory?> category(String id);

  Future<List<AdhkarItem>> itemsFor(String categoryId);

  /// All item bodies grouped by category, used to build the offline search
  /// index without loading 302 separate result sets.
  Future<Map<String, String>> itemTextByCategory();

  Future<int> itemCount();

  Future<bool> isSeeded();
}

class DriftAdhkarRepository implements AdhkarRepository {
  DriftAdhkarRepository(this._db);

  final db.AppDatabase _db;

  @override
  Future<List<AdhkarCategory>> categories({bool featuredOnly = false}) async {
    final rows = await _categoryQuery(featuredOnly: featuredOnly).get();
    return rows.map(_category).toList(growable: false);
  }

  @override
  Future<AdhkarCategory?> category(String id) async {
    final rows =
        await (_categoryQuery()..where(_db.adhkarCategories.id.equals(id)))
            .getSingleOrNull();
    return rows == null ? null : _category(rows);
  }

  @override
  Future<List<AdhkarItem>> itemsFor(String categoryId) async {
    final rows =
        await (_db.select(_db.adhkarItems)
              ..where((t) => t.categoryId.equals(categoryId))
              ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
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
        .toList(growable: false);
  }

  @override
  Future<int> itemCount() => _db.adhkarItems.count().getSingle();

  @override
  Future<Map<String, String>> itemTextByCategory() async {
    final rows = await _db.select(_db.adhkarItems).get();
    final byCategory = <String, String>{};
    for (final row in rows) {
      byCategory.update(
        row.categoryId,
        (value) => '$value ${row.body}',
        ifAbsent: () => row.body,
      );
    }
    return byCategory;
  }

  @override
  Future<bool> isSeeded() async =>
      await _db.adhkarCategories.count().getSingle() > 0 &&
      await _db.adhkarItems.count().getSingle() > 0;

  JoinedSelectStatement<HasResultSet, dynamic> _categoryQuery({
    bool featuredOnly = false,
  }) {
    final count = _db.adhkarItems.id.count();
    final query =
        _db.select(_db.adhkarCategories).join([
            leftOuterJoin(
              _db.adhkarItems,
              _db.adhkarItems.categoryId.equalsExp(_db.adhkarCategories.id),
            ),
          ])
          ..addColumns([count])
          ..groupBy([_db.adhkarCategories.id])
          ..orderBy([OrderingTerm.asc(_db.adhkarCategories.sortOrder)]);
    if (featuredOnly) {
      query.where(_db.adhkarCategories.featured.equals(true));
    }
    return query;
  }

  AdhkarCategory _category(TypedResult row) {
    final category = row.readTable(_db.adhkarCategories);
    final count = row.read(_db.adhkarItems.id.count()) ?? 0;
    return AdhkarCategory(
      id: category.id,
      title: category.title,
      featured: category.featured,
      itemCount: count,
      streakKey: category.streakKey,
    );
  }
}
