import 'db/app_database.dart';

/// Small typed wrapper around the key/value settings table.
abstract final class SettingsStore {
  static Future<String?> read(AppDatabase db, String key) async {
    final row = await (db.select(
      db.settings,
    )..where((table) => table.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  static Future<void> write(AppDatabase db, String key, String value) async {
    await db
        .into(db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(
            key: key,
            value: value,
            updatedAt: DateTime.now(),
          ),
        );
  }

  static Future<int?> readInt(AppDatabase db, String key) async {
    final raw = await read(db, key);
    return raw == null ? null : int.tryParse(raw);
  }
}
