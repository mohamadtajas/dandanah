import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/data/repositories/adhkar_repository.dart';
import 'package:sakeenah_mobile/data/seed/adhkar_seeder.dart';

void main() {
  late AppDatabase db;
  late AdhkarRepository adhkar;
  late Map<String, String> sourceTexts;

  setUp(() async {
    db = AppDatabase.memory();
    final raw = await File('assets/data/adhkar.json').readAsString();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    sourceTexts = {
      for (final category
          in (data['categories'] as List).cast<Map<String, dynamic>>())
        for (final item
            in (category['items'] as List).cast<Map<String, dynamic>>())
          item['id'] as String: item['text'] as String,
    };
    await AdhkarSeeder.seed(db, raw);
    adhkar = DriftAdhkarRepository(db);
  });

  tearDown(() => db.close());

  test('bundle contains every Hisn al-Muslim chapter and item', () async {
    final categories = await adhkar.categories();
    expect(categories, hasLength(126));
    expect(await adhkar.itemCount(), 302);

    final featured = await adhkar.categories(featuredOnly: true);
    expect(featured, hasLength(6));
    expect(
      featured.map((c) => c.id),
      containsAll(['morning', 'evening', 'sleep', 'waking']),
    );
  });

  test('morning category exposes ordered items and repeat counts', () async {
    final morning = await adhkar.category('morning');
    expect(morning, isNotNull);
    expect(morning!.title, 'أذكار الصباح');
    expect(morning.featured, isTrue);
    expect(morning.streakKey, 'morning');
    expect(morning.itemCount, 24);

    final items = await adhkar.itemsFor('morning');
    expect(items, hasLength(24));
    expect(items.first.id, 'morning-01');
    expect(items.first.repeatCount, 1);
    expect(items.first.text, sourceTexts['morning-01']);
    expect(items.first.reference, isNotEmpty);

    final hundred = items.firstWhere((item) => item.id == 'morning-18');
    expect(hundred.repeatCount, 100);
  });

  test(
    'every item has a positive repeat count and belongs to a category',
    () async {
      final categories = await adhkar.categories();
      var total = 0;
      for (final category in categories) {
        final items = await adhkar.itemsFor(category.id);
        expect(items, hasLength(category.itemCount));
        for (final item in items) {
          expect(item.categoryId, category.id);
          expect(item.repeatCount, greaterThan(0));
          expect(item.text, isNotEmpty);
          expect(item.text, sourceTexts[item.id]);
          total++;
        }
      }
      expect(total, 302);
    },
  );

  test('missing categories are empty rather than throwing', () async {
    expect(await adhkar.category('does-not-exist'), isNull);
    expect(await adhkar.itemsFor('does-not-exist'), isEmpty);
  });

  test('bundled attribution stays with the data', () async {
    final raw = await File('assets/data/adhkar.json').readAsString();
    final source = AdhkarSeeder.parseSource(raw);
    expect(source.title, 'حصن المسلم من أذكار الكتاب والسنة');
    expect(source.author, contains('سعيد بن علي'));
    expect(source.license, 'MIT');
    expect(source.copyright, contains('Abdellah SELLAM'));
    expect(source.repository, contains('HisnElMuslim'));
  });

  test('seeding is idempotent and reports readiness', () async {
    final fresh = AppDatabase.memory();
    addTearDown(fresh.close);
    final repo = DriftAdhkarRepository(fresh);
    expect(await repo.isSeeded(), isFalse);

    final json = await File('assets/data/adhkar.json').readAsString();
    await AdhkarSeeder.seed(fresh, json);
    expect(await repo.isSeeded(), isTrue);
    await AdhkarSeeder.seed(fresh, json);

    expect(await repo.categories(), hasLength(126));
    expect(await repo.itemCount(), 302);
  });
}
