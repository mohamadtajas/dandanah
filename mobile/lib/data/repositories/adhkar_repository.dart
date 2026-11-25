import 'package:drift/drift.dart';

import '../db/app_database.dart' as db;
import '../models/adhkar.dart';
import '../text.dart';

/// Read-only access to the bundled Hisn al-Muslim collection.
abstract interface class AdhkarRepository {
  Future<List<AdhkarCategory>> categories({bool featuredOnly = false});

  Future<AdhkarCategory?> category(String id);

  Future<List<AdhkarItem>> itemsFor(String categoryId);

  /// All item bodies grouped by category, used to build the offline search
  /// index without loading 302 separate result sets.
  Future<Map<String, String>> itemTextByCategory();

  /// Normalised title + body index for the catalog search, built once.
  Future<Map<String, String>> searchIndex();

  Future<int> itemCount();

  Future<bool> isSeeded();
}

class DriftAdhkarRepository implements AdhkarRepository {
  DriftAdhkarRepository(this._db);

  final db.AppDatabase _db;
  List<AdhkarCategory>? _categoryCache;
  Map<String, List<AdhkarItem>>? _itemCache;
  Map<String, String>? _textCache;
  Map<String, String>? _searchCache;

  @override
  Future<List<AdhkarCategory>> categories({bool featuredOnly = false}) async {
    var cached = _categoryCache;
    if (cached == null) {
      final rows = await _categoryQuery().get();
      cached = rows.map(_category).toList(growable: false);
      _categoryCache = cached;
    }
    return featuredOnly
        ? cached.where((category) => category.featured).toList(growable: false)
        : cached;
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
    final cache = await _allItems();
    return cache[categoryId] ?? const [];
  }

  @override
  Future<int> itemCount() => _db.adhkarItems.count().getSingle();

  @override
  Future<Map<String, String>> itemTextByCategory() async {
    final cached = _textCache;
    if (cached != null) return cached;
    final items = await _allItems();
    final byCategory = {
      for (final entry in items.entries)
        entry.key: entry.value.map((item) => item.text).join(' '),
    };
    _textCache = byCategory;
    return byCategory;
  }

  @override
  Future<Map<String, String>> searchIndex() async {
    final cached = _searchCache;
    if (cached != null) return cached;
    final categories = await this.categories();
    final text = await itemTextByCategory();
    final index = {
      for (final category in categories)
        category.id: normalizeArabic(
          '${category.title} ${text[category.id] ?? ''}',
        ),
    };
    _searchCache = index;
    return index;
  }

  @override
  Future<bool> isSeeded() async =>
      await _db.adhkarCategories.count().getSingle() > 0 &&
      await _db.adhkarItems.count().getSingle() > 0;

  JoinedSelectStatement<HasResultSet, dynamic> _categoryQuery() {
    final count = _db.adhkarItems.id.count();
    return _db.select(_db.adhkarCategories).join([
        leftOuterJoin(
          _db.adhkarItems,
          _db.adhkarItems.categoryId.equalsExp(_db.adhkarCategories.id),
        ),
      ])
      ..addColumns([count])
      ..groupBy([_db.adhkarCategories.id])
      ..orderBy([OrderingTerm.asc(_db.adhkarCategories.sortOrder)]);
  }

  Future<Map<String, List<AdhkarItem>>> _allItems() async {
    final cached = _itemCache;
    if (cached != null) return cached;
    final rows = await (_db.select(
      _db.adhkarItems,
    )..orderBy([(row) => OrderingTerm.asc(row.sortOrder)])).get();
    final byCategory = <String, List<AdhkarItem>>{};
    for (final row in rows) {
      byCategory.putIfAbsent(row.categoryId, () => []).add(_item(row));
    }
    _itemCache = byCategory;
    return byCategory;
  }

  AdhkarItem _item(db.AdhkarItem row) => AdhkarItem(
    id: row.id,
    categoryId: row.categoryId,
    text: row.body,
    repeatCount: row.repeatCount,
    reference: row.source,
  );

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
