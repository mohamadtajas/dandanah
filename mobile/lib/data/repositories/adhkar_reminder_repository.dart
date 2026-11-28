import 'dart:convert';

import '../db/app_database.dart';
import '../models/adhkar_reminders.dart';
import '../settings_store.dart';

class AdhkarReminderRepository {
  AdhkarReminderRepository(this._db);

  static const storageKey = 'adhkar.reminders';

  final AppDatabase _db;

  Future<AdhkarReminderPreferences> load() async {
    final raw = await SettingsStore.read(_db, storageKey);
    if (raw == null || raw.isEmpty) return AdhkarReminderPreferences.defaults();
    try {
      return AdhkarReminderPreferences.fromJson(
        Map<String, dynamic>.from(const JsonCodec().decode(raw) as Map),
      );
    } catch (_) {
      return AdhkarReminderPreferences.defaults();
    }
  }

  Future<void> save(AdhkarReminderPreferences preferences) =>
      SettingsStore.write(
        _db,
        storageKey,
        const JsonCodec().encode(preferences.toJson()),
      );
}
