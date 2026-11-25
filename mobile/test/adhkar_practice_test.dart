import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart'
    hide AdhkarCategory, AdhkarItem;
import 'package:sakeenah_mobile/data/models/adhkar.dart';
import 'package:sakeenah_mobile/data/repositories/adhkar_practice_repository.dart';
import 'package:sakeenah_mobile/data/seed/adhkar_seeder.dart';
import 'package:sakeenah_mobile/data/worship/adhkar_practice.dart';

void main() {
  group('adhkar streak', () {
    AdhkarDay day(String date, {bool morning = false, bool evening = false}) =>
        AdhkarDay(date: date, morning: morning, evening: evening);

    test('morning or evening qualifies a day', () {
      final days = [
        day('2026-11-26', morning: true),
        day('2026-11-25', evening: true),
        day('2026-11-24', morning: true, evening: true),
        day('2026-11-23'),
        day('2026-11-22', morning: true),
      ];
      final streak = computeAdhkarStreak(days, '2026-11-26');
      expect(streak.current, 3);
      expect(streak.best, 3);
      expect(streak.todayMorning, isTrue);
      expect(streak.todayEvening, isFalse);
    });

    test('unfinished today leaves the running streak intact', () {
      final days = [
        day('2026-11-25', morning: true),
        day('2026-11-24', evening: true),
      ];
      final streak = computeAdhkarStreak(days, '2026-11-26');
      expect(streak.current, 2);
      expect(streak.todayComplete, isFalse);
    });

    test('a gap resets current but best keeps the longest run', () {
      final days = [
        day('2026-11-26', morning: true),
        day('2026-11-25'),
        day('2026-11-24', morning: true),
        day('2026-11-23', morning: true),
        day('2026-11-22', morning: true),
        day('2026-11-20', morning: true),
      ];
      final streak = computeAdhkarStreak(days, '2026-11-26');
      expect(streak.current, 1);
      expect(streak.best, 3);
    });

    test('a shifted local date leaves yesterday counted', () {
      final days = [
        day('2026-11-24', morning: true),
        day('2026-11-25', evening: true),
      ];
      expect(computeAdhkarStreak(days, '2026-11-25').current, 2);
      expect(computeAdhkarStreak(days, '2026-11-26').current, 2);
    });
  });

  group('adhkar progress repository', () {
    late AppDatabase db;
    late DriftAdhkarPracticeRepository practice;
    late AdhkarCategory testCategory;
    late AdhkarItem testItem;

    setUp(() async {
      db = AppDatabase.memory();
      final raw = await File('assets/data/adhkar.json').readAsString();
      await AdhkarSeeder.seed(db, raw);

      await db
          .into(db.adhkarCategories)
          .insert(
            AdhkarCategoriesCompanion.insert(
              id: 'test-streak',
              title: 'اختبار',
              featured: false,
              streakKey: const Value('morning'),
              sortOrder: 999,
            ),
          );
      await db
          .into(db.adhkarItems)
          .insert(
            AdhkarItemsCompanion.insert(
              id: 'test-1',
              categoryId: 'test-streak',
              body: 'ذكر للاختبار',
              repeatCount: 2,
              source: 'اختبار',
              sortOrder: 0,
            ),
          );
      testCategory = const AdhkarCategory(
        id: 'test-streak',
        title: 'اختبار',
        featured: false,
        itemCount: 1,
        streakKey: 'morning',
      );
      testItem = const AdhkarItem(
        id: 'test-1',
        categoryId: 'test-streak',
        text: 'ذكر للاختبار',
        repeatCount: 2,
        reference: 'اختبار',
      );
      practice = DriftAdhkarPracticeRepository(db);
    });

    tearDown(() => db.close());

    test(
      'counts reps, caps at the target and reports item completion',
      () async {
        final first = await practice.increment(
          testCategory,
          testItem,
          '2026-11-26',
        );
        expect(first.itemCompleted, isFalse);
        expect(first.categoryCompleted, isFalse);
        expect(
          (await practice.completedCounts([testItem], '2026-11-26'))['test-1'],
          1,
        );

        final second = await practice.increment(
          testCategory,
          testItem,
          '2026-11-26',
        );
        expect(second.itemCompleted, isTrue);
        expect(second.categoryCompleted, isTrue);

        final third = await practice.increment(
          testCategory,
          testItem,
          '2026-11-26',
        );
        expect(third.itemCompleted, isTrue);
        expect(third.categoryCompleted, isTrue);
        expect(
          (await practice.completedCounts([testItem], '2026-11-26'))['test-1'],
          2,
        );
      },
    );

    test('logs a completed category once and exposes the streak', () async {
      await practice.increment(testCategory, testItem, '2026-11-26');
      await practice.increment(testCategory, testItem, '2026-11-26');
      await practice.increment(testCategory, testItem, '2026-11-26');

      final logs = await db.select(db.adhkarLogs).get();
      expect(logs, hasLength(1));
      expect(logs.single.streakKey, 'morning');
      expect(logs.single.localDate, '2026-11-26');

      final streak = await practice.streak('2026-11-26');
      expect(streak.current, 1);
      expect(streak.todayMorning, isTrue);
    });

    test('reset clears counters and the earned streak log', () async {
      await practice.increment(testCategory, testItem, '2026-11-26');
      await practice.increment(testCategory, testItem, '2026-11-26');
      await practice.resetCategory(testCategory, '2026-11-26');

      final progress = await practice.categoryProgress(
        testCategory,
        '2026-11-26',
      );
      expect(progress.complete, isFalse);
      expect(progress.completedItems, 0);
      expect((await db.select(db.adhkarLogs).get()), isEmpty);
    });

    test(
      'progress resets on a new local day and earns a new streak day',
      () async {
        await practice.increment(testCategory, testItem, '2026-11-26');
        await practice.increment(testCategory, testItem, '2026-11-26');

        expect(
          await practice.completedCounts([testItem], '2026-11-27'),
          isEmpty,
        );

        await practice.increment(testCategory, testItem, '2026-11-27');
        await practice.increment(testCategory, testItem, '2026-11-27');

        final logs = await db.select(db.adhkarLogs).get();
        expect(
          logs.map((row) => row.localDate),
          containsAll(['2026-11-26', '2026-11-27']),
        );
        expect((await practice.streak('2026-11-27')).current, 2);
      },
    );

    test('category progress follows the bundled counts', () async {
      final category = const AdhkarCategory(
        id: 'morning',
        title: 'أذكار الصباح',
        featured: true,
        itemCount: 24,
        streakKey: 'morning',
      );
      final progress = await practice.categoryProgress(category, '2026-11-26');
      expect(progress.totalItems, 24);
      expect(progress.completedItems, 0);
      expect(progress.totalRepeats, 358);
      expect(progress.fraction, 0);
    });

    test('section progress follows repeats, not just finished items', () async {
      const category = AdhkarCategory(
        id: 'morning',
        title: 'أذكار الصباح',
        featured: true,
        itemCount: 24,
        streakKey: 'morning',
      );
      final row =
          await (db.select(db.adhkarItems)
                ..where(
                  (entry) =>
                      entry.categoryId.equals('morning') &
                      entry.repeatCount.isBiggerThanValue(1),
                )
                ..limit(1))
              .getSingle();
      final item = AdhkarItem(
        id: row.id,
        categoryId: row.categoryId,
        text: row.body,
        repeatCount: row.repeatCount,
        reference: row.source,
      );

      await practice.increment(category, item, '2026-11-26');
      final progress = await practice.categoryProgress(category, '2026-11-26');
      expect(progress.completedItems, 0);
      expect(progress.completedRepeats, 1);
      expect(progress.fraction, closeTo(1 / 358, 1e-9));
    });
  });
}
