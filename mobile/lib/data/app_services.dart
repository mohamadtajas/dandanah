import 'package:flutter/services.dart';

import 'db/app_database.dart';
import 'repositories/adhkar_repository.dart';
import 'repositories/quran_repository.dart';
import 'seed/adhkar_seeder.dart';
import 'seed/quran_seeder.dart';

/// Loads the bundled Quran and adhkar assets into the local database. Safe to
/// call on every launch: each seeder checks for existing rows first.
abstract final class ContentBootstrap {
  static const quranAsset = 'assets/data/quran.json';
  static const adhkarAsset = 'assets/data/adhkar.json';

  static Future<void> seed(AppDatabase db, AssetBundle bundle) async {
    final quranJson = await bundle.loadString(quranAsset);
    final adhkarJson = await bundle.loadString(adhkarAsset);
    await QuranSeeder.seed(db, quranJson);
    await AdhkarSeeder.seed(db, adhkarJson);
  }
}

/// Long-lived offline services created once at startup.
class AppServices {
  AppServices._(this.database, this.quran, this.adhkar);

  final AppDatabase database;
  final QuranRepository quran;
  final AdhkarRepository adhkar;

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
    } catch (_) {
      await db.close();
      rethrow;
    }
    final services = AppServices._(
      db,
      DriftQuranRepository(db),
      DriftAdhkarRepository(db),
    );
    _current = services;
    return services;
  }

  static Future<void> shutdown() async {
    final services = _current;
    _current = null;
    await services?.database.close();
  }
}
