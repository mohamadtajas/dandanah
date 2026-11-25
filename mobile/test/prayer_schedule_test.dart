import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/cities.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/data/worship/prayer_method.dart';
import 'package:sakeenah_mobile/data/worship/prayer_schedule.dart';
import 'package:sakeenah_mobile/data/worship/prayer_settings.dart';
import 'package:sakeenah_mobile/data/worship/prayer_times_service.dart';
import 'package:sakeenah_mobile/data/worship/timezone_bootstrap.dart';

void main() {
  const makkah = PrayerSettings(
    latitude: 21.4225,
    longitude: 39.8262,
    timezone: 'Asia/Riyadh',
    configured: true,
  );
  const service = PrayerScheduleService();

  group('prayer settings', () {
    test('round-trips through JSON and sanitizes bad values', () {
      final original = makkah.copyWith(
        method: PrayerMethod.egyptian,
        madhab: PrayerMadhab.hanafi,
        highLatitude: PrayerHighLatitude.twilightAngle,
        hijriAdjustment: 9,
      );
      final restored = PrayerSettings.fromJson(original.toJson());

      expect(restored.latitude, 21.4225);
      expect(restored.method, PrayerMethod.egyptian);
      expect(restored.madhab, PrayerMadhab.hanafi);
      expect(restored.highLatitude, PrayerHighLatitude.twilightAngle);
      expect(restored.hijriAdjustment, 3, reason: 'clamped to -3..3');

      final bad = PrayerSettings.fromJson({
        'latitude': 999,
        'longitude': -999,
        'timezone': 'Not/AZone',
        'hijriAdjustment': -9,
      });
      expect(bad.latitude, 90);
      expect(bad.longitude, -180);
      expect(bad.timezone, 'UTC');
      expect(bad.hijriAdjustment, -3);
    });

    test('repository saves and reloads settings', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final repo = PrayerSettingsRepository(db);

      await repo.save(
        makkah.copyWith(
          method: PrayerMethod.karachi,
          cityId: 'makkah',
          configured: true,
        ),
      );
      final loaded = await repo.load();
      expect(loaded.method, PrayerMethod.karachi);
      expect(loaded.cityId, 'makkah');
      expect(loaded.configured, isTrue);
    });
  });

  group('prayer schedule', () {
    const service = PrayerScheduleService();

    test('next prayer and countdown follow the local clock', () {
      final beforeFajr = service.build(
        makkah,
        nowUtc: DateTime.utc(2026, 11, 26, 2),
      );
      expect(beforeFajr.nowLocal.hour, 5);
      expect(beforeFajr.next.name, PrayerName.fajr);
      expect(beforeFajr.remaining, greaterThan(Duration.zero));
      expect(beforeFajr.dateKey, '2026-11-26');

      final afterSunrise = service.build(
        makkah,
        nowUtc: DateTime.utc(2026, 11, 26, 5),
      );
      expect(afterSunrise.next.name, PrayerName.dhuhr);
    });

    test('late evening rolls the next prayer to tomorrow Fajr', () {
      final schedule = service.build(
        makkah,
        nowUtc: DateTime.utc(2026, 11, 26, 20, 30),
      );
      expect(schedule.dateKey, '2026-11-26');
      expect(schedule.next.name, PrayerName.fajr);
      expect(schedule.next.local.day, 27);
      expect(schedule.next.local.hour, schedule.tomorrow.first.local.hour);
    });

    test('next prayer advances without rebuilding the schedule', () {
      final schedule = service.build(
        makkah,
        nowUtc: DateTime.utc(2026, 11, 26, 2),
      );
      final afterFajr = schedule.today
          .firstWhere((slot) => slot.name == PrayerName.fajr)
          .instant
          .add(const Duration(minutes: 1));

      expect(schedule.nextAt(afterFajr).name, PrayerName.dhuhr);
      expect(schedule.passedAt(PrayerName.fajr, afterFajr), isTrue);
      expect(schedule.isSameLocalDate(afterFajr), isTrue);
      expect(
        schedule.isSameLocalDate(afterFajr.add(const Duration(days: 1))),
        isFalse,
      );
    });

    test('eastern timezones keep the requested local date', () {
      const apia = PrayerSettings(
        latitude: -13.8333,
        longitude: -171.7667,
        timezone: 'Pacific/Apia',
      );
      final schedule = service.build(
        apia,
        nowUtc: DateTime.utc(2026, 11, 26, 0, 30),
      );
      expect(schedule.dateKey, '2026-11-26');
      expect(schedule.nowLocal.hour, 13);
      expect(schedule.hijri.month, inInclusiveRange(1, 12));
    });

    test('London summer time uses the DST offset', () {
      const london = PrayerSettings(
        latitude: 51.5074,
        longitude: -0.1278,
        timezone: 'Europe/London',
      );
      final schedule = service.build(
        london,
        nowUtc: DateTime.utc(2026, 6, 21, 12),
      );
      expect(schedule.nowLocal.hour, 13);
      expect(schedule.dateKey, '2026-06-21');
      expect(schedule.qibla, closeTo(118.9, 1.0));
    });
  });

  test('desktop city presets are available offline', () {
    expect(cities.length, 59);
    expect(cities.first.nameEn, 'Makkah');
    expect(cities.first.timezone, 'Asia/Riyadh');
    expect(cityById('cairo')?.countryEn, 'Egypt');
    for (final city in cities) {
      expect(isValidTimezone(city.timezone), isTrue, reason: ' -> ');
    }
    expect(isValidTimezone('UTC'), isTrue);
  });

  test('every method works with every high-latitude rule', () {
    for (final method in PrayerMethod.values) {
      for (final rule in PrayerHighLatitude.values) {
        final schedule = service.tryBuild(
          makkah.copyWith(method: method, highLatitude: rule),
          nowUtc: DateTime.utc(2026, 6, 21, 9),
        );
        expect(schedule, isNotNull, reason: ' + ');
      }
    }
  });

  test('polar coordinates return an unavailable schedule', () {
    const tromso = PrayerSettings(
      latitude: 69.6492,
      longitude: 18.9553,
      timezone: 'Europe/Oslo',
    );
    expect(
      service.tryBuild(tromso, nowUtc: DateTime.utc(2026, 6, 21, 12)),
      isNull,
    );
    expect(
      service.tryBuild(tromso, nowUtc: DateTime.utc(2026, 12, 21, 12)),
      isNull,
    );
  });

  test('a late Isha after midnight remains the next prayer', () {
    const paris = PrayerSettings(
      latitude: 48.8566,
      longitude: 2.3522,
      timezone: 'Europe/Paris',
      method: PrayerMethod.muslimWorldLeague,
      highLatitude: PrayerHighLatitude.middleOfTheNight,
    );
    final beforeMidnight = service.build(
      paris,
      nowUtc: DateTime.utc(2026, 6, 21, 21, 30),
    );
    final afterMidnight = service.build(
      paris,
      nowUtc: DateTime.utc(2026, 6, 21, 22, 10),
    );

    expect(beforeMidnight.next.name, PrayerName.isha);
    expect(afterMidnight.dateKey, '2026-06-22');
    expect(afterMidnight.next.name, PrayerName.isha);
    expect(afterMidnight.next.ownerDate, '2026-06-21');
    expect(afterMidnight.next.local.hour, 1);
    expect(
      afterMidnight.displayAt(afterMidnight.nowUtc).first.name,
      PrayerName.isha,
    );
  });

  test('DST offsets are resolved per date', () {
    const london = PrayerSettings(
      latitude: 51.5074,
      longitude: -0.1278,
      timezone: 'Europe/London',
    );
    final before = service.build(london, nowUtc: DateTime.utc(2026, 3, 28, 12));
    final after = service.build(london, nowUtc: DateTime.utc(2026, 3, 30, 12));
    expect(before.nowLocal.timeZoneOffset, Duration.zero);
    expect(after.nowLocal.timeZoneOffset, const Duration(hours: 1));
  });
}
