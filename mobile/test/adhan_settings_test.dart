import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/data/models/adhan.dart';
import 'package:sakeenah_mobile/data/repositories/adhan_settings_repository.dart';
import 'package:sakeenah_mobile/data/worship/prayer_method.dart';
import 'package:sakeenah_mobile/data/worship/prayer_notifications.dart';
import 'package:sakeenah_mobile/data/worship/prayer_settings.dart';
import 'package:sakeenah_mobile/data/worship/prayer_times_service.dart';

void main() {
  test('defaults enable all five prayers with a ten-minute pre-alert', () {
    final defaults = AdhanPreferences.defaults();
    for (final prayer in const [
      PrayerName.fajr,
      PrayerName.dhuhr,
      PrayerName.asr,
      PrayerName.maghrib,
      PrayerName.isha,
    ]) {
      expect(defaults.isEnabled(prayer), isTrue);
    }
    expect(defaults.isEnabled(PrayerName.sunrise), isFalse);
    expect(defaults.preAlertMinutes, 10);
    expect(defaults.soundEnabled, isTrue);
  });

  test('preferences round-trip through JSON', () {
    final original = AdhanPreferences.defaults().copyWith(
      enabled: {...AdhanPreferences.defaults().enabled, PrayerName.fajr: false},
      preAlertMinutes: 20,
      soundEnabled: false,
    );
    final restored = AdhanPreferences.fromJson(original.toJson());

    expect(restored.isEnabled(PrayerName.fajr), isFalse);
    expect(restored.isEnabled(PrayerName.dhuhr), isTrue);
    expect(restored.preAlertMinutes, 20);
    expect(restored.soundEnabled, isFalse);
  });

  test('repository persists preferences', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repo = AdhanSettingsRepository(db);

    expect((await repo.load()).preAlertMinutes, 10);
    await repo.save(AdhanPreferences.defaults().copyWith(preAlertMinutes: 5));
    expect((await repo.load()).preAlertMinutes, 5);
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
    for (var index = 1; index < plan.length; index++) {
      expect(plan[index].instant.isBefore(plan[index - 1].instant), isFalse);
    }
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
        preAlertMinutes: 0,
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
      preferences: AdhanPreferences.defaults().copyWith(preAlertMinutes: 0),
      nowUtc: DateTime.utc(2026, 11, 26),
      daysAhead: 1,
    );
    expect(plan, hasLength(5));
  });
}
