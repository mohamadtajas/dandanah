import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../models/adhkar.dart';

/// Seeds the bundled Hisn al-Muslim collection once, preserving text and
/// attribution exactly as generated from the upstream MIT-licensed dataset.
abstract final class AdhkarSeeder {
  static Future<void> seed(AppDatabase db, String json) async {
    if (await db.adhkarCategories.count().getSingle() > 0) return;
    await db.transaction(() => seedInto(db, json));
  }

  /// Inserts the parsed bundle without checking or opening a transaction.
  /// Callers are responsible for doing both.
  static Future<void> seedInto(AppDatabase db, String json) async {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final categories = (data['categories'] as List)
        .cast<Map<String, dynamic>>();
    final itemRows = <AdhkarItemsCompanion>[];

    for (
      var categoryIndex = 0;
      categoryIndex < categories.length;
      categoryIndex++
    ) {
      final category = categories[categoryIndex];
      final items = (category['items'] as List).cast<Map<String, dynamic>>();
      for (var itemIndex = 0; itemIndex < items.length; itemIndex++) {
        final item = items[itemIndex];
        itemRows.add(
          AdhkarItemsCompanion.insert(
            id: item['id'] as String,
            categoryId: category['id'] as String,
            body: item['text'] as String,
            repeatCount: item['count'] as int,
            source: item['reference'] as String? ?? '',
            sortOrder: itemIndex,
          ),
        );
      }
    }

    await db.batch((batch) {
      batch.insertAll(db.adhkarCategories, [
        for (var index = 0; index < categories.length; index++)
          AdhkarCategoriesCompanion.insert(
            id: categories[index]['id'] as String,
            title: categories[index]['title'] as String,
            featured: categories[index]['featured'] as bool,
            streakKey: Value(categories[index]['streakKey'] as String?),
            sortOrder: index,
          ),
      ]);
      batch.insertAll(db.adhkarItems, itemRows);
    });
  }

  /// Attribution bundled with the collection; used by Credits in a later phase.
  static AdhkarSource parseSource(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    return AdhkarSource.fromJson(
      (data['source'] as Map).cast<String, dynamic>(),
    );
  }
}
