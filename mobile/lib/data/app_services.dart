import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'db/app_database.dart';
import 'repositories/adhkar_repository.dart';
import 'repositories/prayer_log_repository.dart';
import 'repositories/quran_repository.dart';
import 'seed/adhkar_seeder.dart';
import 'seed/quran_seeder.dart';
import 'settings_store.dart';
import 'worship/prayer_settings.dart';

/// Loads the bundled Quran and adhkar assets into the local database.
///
/// A content version in the settings table gates the work: matching version and
/// complete row counts skip the asset reads entirely. Bumping [contentVersion]
/// (or a partial content set) replaces both collections atomically.
abstract final class ContentBootstrap {
  static const quranAsset = 'assets/data/quran.json';
  static const adhkarAsset = 'assets/data/adhkar.json';
  static const versionKey = 'content_version';

  /// Bump whenever the bundled assets change.
  static const contentVersion = 1;

  static Future<void> seed(
    AppDatabase db,
    AssetBundle bundle, {
    int version = contentVersion,
  }) async {
    if (await _isCurrent(db, version)) return;

    final quranJson = await bundle.loadString(quranAsset);
    final adhkarJson = await bundle.loadString(adhkarAsset);

    await db.transaction(() async {
      // Content only; bookmarks, reader position and streaks are user state
      // and intentionally survive a content refresh.
      await db.delete(db.ayahs).go();
      await db.delete(db.juzs).go();
      await db.delete(db.quranPages).go();
      await db.delete(db.surahs).go();
      await db.delete(db.adhkarItems).go();
      await db.delete(db.adhkarCategories).go();

      await QuranSeeder.seedInto(db, quranJson);
      await AdhkarSeeder.seedInto(db, adhkarJson);
      await SettingsStore.write(db, versionKey, '$version');
    });
  }

  static Future<bool> _isCurrent(AppDatabase db, int version) async {
    if (await SettingsStore.readInt(db, versionKey) != version) return false;
    final row = await db.customSelect('''
      SELECT
        (SELECT COUNT(*) FROM surahs) AS surahs,
        (SELECT COUNT(*) FROM ayahs) AS ayahs,
        (SELECT COUNT(*) FROM juzs) AS juzs,
        (SELECT COUNT(*) FROM quran_pages) AS pages,
        (SELECT COUNT(*) FROM adhkar_categories) AS categories,
        (SELECT COUNT(*) FROM adhkar_items) AS items
    ''').getSingle();
    return row.read<int>('surahs') == 114 &&
        row.read<int>('ayahs') == 6236 &&
        row.read<int>('juzs') == 30 &&
        row.read<int>('pages') == 604 &&
        row.read<int>('categories') == 126 &&
        row.read<int>('items') == 302;
  }
}

/// Long-lived offline services created once at startup.
class AppServices {
  AppServices._(
    this.database,
    this.quran,
    this.adhkar,
    this.prayerLog,
    this.prayerSettingsRepository,
    this.prayerSettings,
  );

  final AppDatabase database;
  final QuranRepository quran;
  final AdhkarRepository adhkar;
  final PrayerLogRepository prayerLog;
  final PrayerSettingsRepository prayerSettingsRepository;
  final ValueNotifier<PrayerSettings> prayerSettings;

  static AppServices? _current;

  static AppServices get current {
    final services = _current;
    if (services == null) {
      throw StateError('AppServices.initialize() has not completed');
    }
    return services;
  }

  static Future<AppServices> initialize({
    AssetBundle? bundle,
    AppDatabase? database,
  }) async {
    final db = database ?? await AppDatabase.open();
    try {
      await ContentBootstrap.seed(db, bundle ?? rootBundle);
      final settingsRepository = PrayerSettingsRepository(db);
      final settings = await settingsRepository.load();
      final services = AppServices._(
        db,
        DriftQuranRepository(db),
        DriftAdhkarRepository(db),
        DriftPrayerLogRepository(db),
        settingsRepository,
        ValueNotifier(settings),
      );
      _current = services;
      return services;
    } catch (_) {
      await db.close();
      rethrow;
    }
  }

  Future<void> updatePrayerSettings(PrayerSettings settings) async {
    await prayerSettingsRepository.save(settings);
    prayerSettings.value = settings.sanitized();
  }

  static Future<void> shutdown() async {
    final services = _current;
    _current = null;
    services?.prayerSettings.dispose();
    await services?.database.close();
  }
}
