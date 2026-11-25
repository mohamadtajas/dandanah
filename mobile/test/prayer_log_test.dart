import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/data/repositories/prayer_log_repository.dart';
import 'package:sakeenah_mobile/data/worship/prayer_log.dart';
import 'package:sakeenah_mobile/data/worship/prayer_times_service.dart';

void main() {
  group('prayer streak', () {
    PrayerDay complete(String date) => PrayerDay(
      date: date,
      statuses: {
        for (final prayer in obligatoryPrayers) prayer: PrayerStatus.onTime,
      },
    );

    test('today unfinished keeps the chain from yesterday', () {
      final days = [
        for (var offset = 1; offset <= 5; offset++)
          complete('2026-11-${(25 - offset).toString().padLeft(2, '0')}'),
        const PrayerDay(date: '2026-11-25'),
      ];
      final streak = computePrayerStreak(days, '2026-11-25');
      expect(streak.current, 5);
      expect(streak.best, 5);
      expect(streak.todayComplete, isFalse);
      expect(streak.todayCount, 0);
    });

    test('excused days preserve the chain and gaps break it', () {
      final days = [
        complete('2026-11-25'),
        const PrayerDay(
          date: '2026-11-24',
          statuses: {
            PrayerName.fajr: PrayerStatus.excused,
            PrayerName.dhuhr: PrayerStatus.excused,
            PrayerName.asr: PrayerStatus.excused,
            PrayerName.maghrib: PrayerStatus.excused,
            PrayerName.isha: PrayerStatus.excused,
          },
        ),
        complete('2026-11-23'),
        complete('2026-11-21'),
      ];
      final streak = computePrayerStreak(days, '2026-11-25');
      expect(streak.current, 3);
      expect(streak.best, 3, reason: '2026-11-22 is missing');
      expect(streak.todayComplete, isTrue);
      expect(streak.todayExcused, isFalse);
    });

    test('best streak survives a break', () {
      final days = [
        for (final day in ['2026-11-24', '2026-11-23', '2026-11-22'])
          complete(day),
        for (final day in ['2026-11-20', '2026-11-19', '2026-11-18'])
          complete(day),
      ];
      final streak = computePrayerStreak(days, '2026-11-25');
      expect(streak.current, 3);
      expect(streak.best, 3);
    });

    test('a local date shift leaves yesterday intact', () {
      final days = [complete('2026-11-24'), complete('2026-11-25')];
      expect(computePrayerStreak(days, '2026-11-25').current, 2);
      final shifted = computePrayerStreak(days, '2026-11-26');
      expect(shifted.current, 2);
      expect(shifted.todayComplete, isFalse);
    });
  });

  group('prayer log repository', () {
    late AppDatabase db;
    late PrayerLogRepository logs;

    setUp(() {
      db = AppDatabase.memory();
      logs = DriftPrayerLogRepository(db);
    });

    tearDown(() => db.close());

    Future<void> completeAll(String date) async {
      for (final prayer in obligatoryPrayers) {
        await logs.setStatus(date, prayer, PrayerStatus.onTime);
      }
    }

    test('tracks each prayer and updates without duplicating rows', () async {
      await logs.setStatus('2026-11-26', PrayerName.fajr, PrayerStatus.onTime);
      await logs.setStatus('2026-11-26', PrayerName.dhuhr, PrayerStatus.late);
      await logs.setStatus('2026-11-26', PrayerName.asr, PrayerStatus.qada);
      await logs.setStatus(
        '2026-11-26',
        PrayerName.maghrib,
        PrayerStatus.onTime,
      );
      await logs.setStatus('2026-11-26', PrayerName.isha, PrayerStatus.onTime);

      var day = await logs.day('2026-11-26');
      expect(day.count, 5);
      expect(day.complete, isTrue);
      expect(day.statusOf(PrayerName.dhuhr), PrayerStatus.late);

      await logs.setStatus('2026-11-26', PrayerName.dhuhr, PrayerStatus.missed);
      day = await logs.day('2026-11-26');
      expect(day.count, 4);
      expect(day.statusOf(PrayerName.dhuhr), PrayerStatus.missed);

      await logs.setStatus('2026-11-26', PrayerName.dhuhr, null);
      expect((await logs.day('2026-11-26')).statusOf(PrayerName.dhuhr), isNull);
    });

    test('excused day qualifies for the streak and can be undone', () async {
      await logs.setExcused('2026-11-26', true);
      var day = await logs.day('2026-11-26');
      expect(day.excused, isTrue);
      expect(day.complete, isFalse);
      expect(day.count, 0);
      expect((await logs.streak('2026-11-26')).current, 1);

      await logs.setStatus('2026-11-26', PrayerName.fajr, PrayerStatus.onTime);
      day = await logs.day('2026-11-26');
      expect(day.excused, isFalse);
      expect(day.count, 1);
      expect((await logs.streak('2026-11-26')).todayCount, 1);
    });

    test('streak reads persisted days', () async {
      await completeAll('2026-11-23');
      await completeAll('2026-11-24');
      await completeAll('2026-11-25');

      final streak = await logs.streak('2026-11-25');
      expect(streak.current, 3);
      expect(streak.best, 3);
      expect(streak.todayComplete, isTrue);
    });

    test('changing excused to false clears the day', () async {
      await logs.setExcused('2026-11-26', true);
      await logs.setExcused('2026-11-26', false);
      final day = await logs.day('2026-11-26');
      expect(day.statuses, isEmpty);
      expect(day.qualifies, isFalse);
    });
  });
}
