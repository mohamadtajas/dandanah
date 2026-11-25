import 'dart:convert';

import '../db/app_database.dart';
import '../models/adhan.dart';
import '../settings_store.dart';

class AdhanSettingsRepository {
  AdhanSettingsRepository(this._db);

  static const storageKey = 'adhan.settings';

  final AppDatabase _db;

  Future<AdhanPreferences> load() async {
    final raw = await SettingsStore.read(_db, storageKey);
    if (raw == null || raw.isEmpty) return AdhanPreferences.defaults();
    try {
      return AdhanPreferences.fromJson(
        Map<String, dynamic>.from(const JsonCodec().decode(raw) as Map),
      );
    } catch (_) {
      return AdhanPreferences.defaults();
    }
  }

  Future<void> save(AdhanPreferences preferences) => SettingsStore.write(
    _db,
    storageKey,
    const JsonCodec().encode(preferences.toJson()),
  );
}
