import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/app_services.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';

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
  });

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

class _FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}
