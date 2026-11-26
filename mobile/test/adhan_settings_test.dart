import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/data/models/adhan.dart';
import 'package:sakeenah_mobile/data/models/local_date.dart';
import 'package:sakeenah_mobile/data/repositories/adhan_settings_repository.dart';
import 'package:sakeenah_mobile/data/worship/prayer_method.dart';
import 'package:sakeenah_mobile/data/worship/prayer_notifications.dart';
import 'package:sakeenah_mobile/data/worship/prayer_settings.dart';
import 'package:sakeenah_mobile/data/worship/prayer_times_service.dart';
import 'package:sakeenah_mobile/data/worship/timezone_bootstrap.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  test('defaults enable all five prayers with a ten-minute pre-alert', () {
    final defaults = AdhanPreferences.defaults();
    for (final prayer in obligatoryPrayerNames) {
      expect(defaults.isEnabled(prayer), isTrue);
      expect(defaults.preAlertFor(prayer), 10);
    }
    expect(defaults.isEnabled(PrayerName.sunrise), isFalse);
    expect(defaults.soundEnabled, isTrue);
  });

  test('each prayer keeps its own pre-alert offset', () {
    final original = AdhanPreferences.defaults().copyWith(
      enabled: {...AdhanPreferences.defaults().enabled, PrayerName.fajr: false},
      preAlerts: {
        PrayerName.fajr: 20,
        PrayerName.dhuhr: 0,
        PrayerName.asr: 5,
        PrayerName.maghrib: 15,
        PrayerName.isha: 10,
      },
      soundEnabled: false,
    );
    final restored = AdhanPreferences.fromJson(original.toJson());

    expect(restored.isEnabled(PrayerName.fajr), isFalse);
    expect(restored.isEnabled(PrayerName.dhuhr), isTrue);
    expect(restored.preAlertFor(PrayerName.fajr), 20);
    expect(restored.preAlertFor(PrayerName.dhuhr), 0);
    expect(restored.preAlertFor(PrayerName.asr), 5);
    expect(restored.preAlertFor(PrayerName.maghrib), 15);
    expect(restored.preAlertFor(PrayerName.isha), 10);
    expect(restored.soundEnabled, isFalse);
  });

  test('legacy global pre-alert migrates to every prayer', () {
    final restored = AdhanPreferences.fromJson({
      'enabled': {'fajr': 'yes', 'dhuhr': false},
      'preAlertMinutes': 7,
      'soundEnabled': 'loud',
    });

    expect(restored.isEnabled(PrayerName.fajr), isTrue);
    expect(restored.isEnabled(PrayerName.dhuhr), isFalse);
    for (final prayer in obligatoryPrayerNames) {
      expect(restored.preAlertFor(prayer), 5);
    }
    expect(restored.soundEnabled, isTrue);
  });

  test('corrupt per-prayer values are normalised', () {
    final restored = AdhanPreferences.fromJson({
      'preAlerts': {'fajr': 99, 'dhuhr': -4, 'asr': 'soon'},
    });

    expect(restored.preAlertFor(PrayerName.fajr), 20);
    expect(restored.preAlertFor(PrayerName.dhuhr), 0);
    expect(restored.preAlertFor(PrayerName.asr), 10);
    expect(
      AdhanPreferences.defaults()
          .copyWith(preAlerts: {PrayerName.isha: 7})
          .preAlertFor(PrayerName.isha),
      5,
    );
  });

  test('repository persists preferences', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = AdhanSettingsRepository(db);

    expect((await repo.load()).preAlertFor(PrayerName.fajr), 10);
    await repo.save(
      AdhanPreferences.defaults().copyWith(
        preAlerts: {PrayerName.fajr: 5, PrayerName.isha: 20},
      ),
    );
    final loaded = await repo.load();
    expect(loaded.preAlertFor(PrayerName.fajr), 5);
    expect(loaded.preAlertFor(PrayerName.isha), 20);
    expect(loaded.preAlertFor(PrayerName.dhuhr), 10);
  });

  test('planner emits adhan and pre-alert events in order', () {
    final plan = PrayerNotificationPlanner().plan(
      settings: PrayerSettings.defaults(),
      preferences: AdhanPreferences.defaults(),
      nowUtc: DateTime.utc(2026, 11, 26),
      daysAhead: 2,
    );

    final adhan = plan.where((event) => !event.preAlert).toList();
    final pre = plan.where((event) => event.preAlert).toList();
    expect(adhan, hasLength(10));
    expect(pre, hasLength(10));
    expect(adhan.first.prayer, PrayerName.fajr);
    expect(adhan.first.instant.isAfter(DateTime.utc(2026, 11, 26)), isTrue);
    expect(
      pre.first.instant,
      adhan.first.instant.subtract(const Duration(minutes: 10)),
    );
    expect(pre.first.preAlertMinutes, 10);
    for (var index = 1; index < plan.length; index++) {
      expect(plan[index].instant.isBefore(plan[index - 1].instant), isFalse);
    }
  });

  test('planner honours a different offset per prayer', () {
    final preferences = AdhanPreferences.defaults().copyWith(
      preAlerts: {
        PrayerName.fajr: 20,
        PrayerName.dhuhr: 0,
        PrayerName.asr: 5,
        PrayerName.maghrib: 15,
        PrayerName.isha: 10,
      },
    );
    final plan = PrayerNotificationPlanner().plan(
      settings: PrayerSettings.defaults(),
      preferences: preferences,
      nowUtc: DateTime.utc(2026, 11, 26),
      daysAhead: 1,
    );

    final byId = {for (final event in plan) event.id: event};
    final fajr = byId['2026-11-26-fajr-pre'];
    final dhuhr = byId['2026-11-26-dhuhr-pre'];
    final asr = byId['2026-11-26-asr-pre'];
    expect(fajr, isNotNull);
    expect(fajr!.preAlertMinutes, 20);
    expect(dhuhr, isNull);
    expect(asr!.preAlertMinutes, 5);
  });

  test('disabled prayers and past events are omitted', () {
    final settings = PrayerSettings.defaults();
    final plan = PrayerNotificationPlanner().plan(
      settings: settings,
      preferences: AdhanPreferences.defaults().copyWith(
        enabled: {
          ...AdhanPreferences.defaults().enabled,
          PrayerName.dhuhr: false,
        },
        preAlerts: {for (final prayer in obligatoryPrayerNames) prayer: 0},
      ),
      nowUtc: DateTime.utc(2026, 11, 26, 20),
      daysAhead: 2,
    );

    expect(plan.where((event) => event.prayer == PrayerName.dhuhr), isEmpty);
    expect(plan.where((event) => event.preAlert), isEmpty);
    expect(
      plan.every(
        (event) => event.instant.isAfter(DateTime.utc(2026, 11, 26, 20)),
      ),
      isTrue,
    );
  });

  test('a custom calculation method reaches the planner', () {
    final settings = PrayerSettings.defaults().copyWith(
      method: PrayerMethod.egyptian,
    );
    final plan = PrayerNotificationPlanner().plan(
      settings: settings,
      preferences: AdhanPreferences.defaults().copyWith(
        preAlerts: {for (final prayer in obligatoryPrayerNames) prayer: 0},
      ),
      nowUtc: DateTime.utc(2026, 11, 26),
      daysAhead: 1,
    );
    expect(plan, hasLength(5));
  });

  test('planner keeps local prayer days across a DST change', () {
    const timezone = 'America/New_York';
    final settings = PrayerSettings.defaults(timezone: timezone)
        .copyWith(latitude: 40.7128, longitude: -74.0060);
    final plan = PrayerNotificationPlanner().plan(
      settings: settings,
      preferences: AdhanPreferences.defaults(),
      // DST starts in New York on 2026-03-08.
      nowUtc: DateTime.utc(2026, 3, 7, 12),
      daysAhead: 3,
    );

    final location = locationFor(timezone);
    final days = <String>{};
    for (final event in plan) {
      final local = tz.TZDateTime.from(event.instant, location);
      final day = localDateKey(local);
      days.add(day);
      expect(
        event.id.startsWith(day),
        isTrue,
        reason: '${event.id} should occur on $day',
      );
    }
    expect(days, containsAll(['2026-03-07', '2026-03-08', '2026-03-09']));

    for (final adhan in plan.where((event) => !event.preAlert)) {
      final preId = adhan.id.replaceAll('-adhan', '-pre');
      final pre = plan.where((event) => event.id == preId).firstOrNull;
      if (pre == null) continue;
      expect(
        pre.instant,
        adhan.instant.subtract(Duration(minutes: pre.preAlertMinutes)),
      );
    }
  });
}
