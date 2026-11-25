import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/app_services.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/data/settings_store.dart';

void main() {
  test('startup services seed Quran and adhkar from bundled assets', () async {
    final services = await AppServices.initialize(
      database: AppDatabase.memory(),
      bundle: _FileAssetBundle(),
    );
    addTearDown(AppServices.shutdown);

    expect(AppServices.current, same(services));
    expect(await services.quran.ayahCount(), 6236);
    expect(await services.quran.surahs(), hasLength(114));
    expect(await services.adhkar.itemCount(), 302);
    expect(await services.adhkar.categories(), hasLength(126));
    expect(
      await SettingsStore.readInt(
        services.database,
        ContentBootstrap.versionKey,
      ),
      1,
    );
  });

  test('matching content version skips all asset reads', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final bundle = _FileAssetBundle();

    await ContentBootstrap.seed(db, bundle);
    expect(bundle.loads, 2);

    await ContentBootstrap.seed(db, bundle);
    expect(bundle.loads, 2);
  });

  test('bumping the content version reloads and refreshes content', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final bundle = _FileAssetBundle();

    await ContentBootstrap.seed(db, bundle);
    await ContentBootstrap.seed(db, bundle, version: 2);

    expect(bundle.loads, 4);
    expect(await SettingsStore.readInt(db, ContentBootstrap.versionKey), 2);
    expect(await db.ayahs.count().getSingle(), 6236);
    expect(await db.adhkarItems.count().getSingle(), 302);
  });

  test('partial content is repaired even when the version matches', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final bundle = _FileAssetBundle();

    await ContentBootstrap.seed(db, bundle);
    await db.customStatement('DELETE FROM ayahs WHERE surah = 1');
    expect(await db.ayahs.count().getSingle(), lessThan(6236));

    await ContentBootstrap.seed(db, bundle);

    expect(bundle.loads, 4);
    expect(await db.ayahs.count().getSingle(), 6236);
  });

  test(
    'a failing bundle leaves no services behind and closes the database',
    () async {
      await AppServices.shutdown();
      final db = AppDatabase.memory();

      await expectLater(
        AppServices.initialize(database: db, bundle: _FailingBundle()),
        throwsA(anything),
      );

      expect(() => AppServices.current, throwsStateError);
      await expectLater(db.customSelect('SELECT 1').get(), throwsA(anything));
    },
  );

  test('shutdown closes the database and clears the singleton', () async {
    await AppServices.initialize(
      database: AppDatabase.memory(),
      bundle: _FileAssetBundle(),
    );
    final db = AppServices.current.database;

    await AppServices.shutdown();

    expect(() => AppServices.current, throwsStateError);
    await expectLater(db.customSelect('SELECT 1').get(), throwsA(anything));
  });
}

class _FileAssetBundle extends AssetBundle {
  int loads = 0;

  @override
  Future<ByteData> load(String key) async {
    loads++;
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}

class _FailingBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) async {
    throw StateError('asset unavailable');
  }
}
