import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/models/adhkar_reminders.dart';
import 'package:sakeenah_mobile/data/worship/adhkar_reminders.dart';
import 'package:sakeenah_mobile/data/worship/prayer_schedule.dart';
import 'package:sakeenah_mobile/data/worship/prayer_settings.dart';
import 'package:sakeenah_mobile/data/worship/prayer_times_service.dart';

void main() {
  test('defaults are disabled and serialise safely', () {
    final defaults = AdhkarReminderPreferences.defaults();
    expect(defaults.morning, isFalse);
    expect(defaults.evening, isFalse);
    expect(defaults.sleep, isFalse);

    final restored = AdhkarReminderPreferences.fromJson({
      'morning': true,
      'evening': 'yes',
      'sleep': true,
      'morningOffsetMinutes': 17,
      'eveningOffsetMinutes': 100,
      'sleepHour': 30,
      'sleepMinute': 61,
    });
    expect(restored.morning, isTrue);
    expect(restored.evening, isFalse);
    expect(restored.sleep, isTrue);
    expect(restored.morningOffsetMinutes, 15);
    expect(restored.eveningOffsetMinutes, 90);
    expect(restored.sleepHour, 23);
    expect(restored.sleepMinute, 59);
  });

  test('planner places morning after Fajr and sleep at its local time', () {
    final plan = const AdhkarReminderPlanner().plan(
      settings: PrayerSettings.defaults(timezone: 'Asia/Riyadh'),
      preferences: AdhkarReminderPreferences.defaults().copyWith(
        morning: true,
        evening: true,
        sleep: true,
        morningOffsetMinutes: 30,
        eveningOffsetMinutes: 45,
        sleepHour: 22,
        sleepMinute: 0,
      ),
      nowUtc: DateTime.utc(2026, 11, 26),
      days: 1,
    );

    final morning = plan.firstWhere(
      (reminder) => reminder.group == AdhkarReminderGroup.morning,
    );
    final evening = plan.firstWhere(
      (reminder) => reminder.group == AdhkarReminderGroup.evening,
    );
    final sleep = plan.firstWhere(
      (reminder) => reminder.group == AdhkarReminderGroup.sleep,
    );

    // Riyadh is UTC+3; Fajr is around 05:18 local -> 02:18 UTC.
    final fajr = const PrayerScheduleService()
        .slotsForDate(
          PrayerSettings.defaults(timezone: 'Asia/Riyadh'),
          DateTime(2026, 11, 26),
        )
        .firstWhere((slot) => slot.name == PrayerName.fajr);
    expect(morning.instant, fajr.instant.add(const Duration(minutes: 30)));
    expect(evening.instant.isAfter(morning.instant), isTrue);
    expect(sleep.instant, DateTime.utc(2026, 11, 26, 19));
    expect(plan.map((r) => r.id).toSet(), hasLength(plan.length));
  });

  test('disabled groups are not planned', () {
    final plan = const AdhkarReminderPlanner().plan(
      settings: PrayerSettings.defaults(),
      preferences: AdhkarReminderPreferences.defaults(),
      nowUtc: DateTime.utc(2026, 11, 26),
      days: 2,
    );
    expect(plan, isEmpty);
  });
}
