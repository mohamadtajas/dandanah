import 'package:timezone/timezone.dart' as tz;

import '../models/adhkar_reminders.dart';
import '../models/local_date.dart';
import 'prayer_schedule.dart';
import 'prayer_settings.dart';
import 'prayer_times_service.dart';
import 'timezone_bootstrap.dart';

class AdhkarReminderPlanner {
  const AdhkarReminderPlanner({this.daysAhead = 30});

  final int daysAhead;

  List<AdhkarReminder> plan({
    required PrayerSettings settings,
    required AdhkarReminderPreferences preferences,
    required DateTime nowUtc,
    int? days,
  }) {
    final now = nowUtc.toUtc();
    final location = locationFor(settings.timezone);
    final localNow = tz.TZDateTime.from(now, location);
    final count = days ?? daysAhead;
    final reminders = <AdhkarReminder>[];

    for (var offset = 0; offset < count; offset++) {
      final date = tz.TZDateTime(
        location,
        localNow.year,
        localNow.month,
        localNow.day + offset,
        12,
      );
      final day = DateTime(date.year, date.month, date.day);
      final key = localDateKey(day);
      final slots = const PrayerScheduleService().slotsForDate(settings, day);

      DateTime? instantFor(PrayerName name) {
        for (final slot in slots) {
          if (slot.name == name) return slot.instant;
        }
        return null;
      }

      if (preferences.morning) {
        final fajr = instantFor(PrayerName.fajr);
        if (fajr != null) {
          final instant = fajr.add(
            Duration(minutes: preferences.morningOffsetMinutes),
          );
          if (instant.isAfter(now)) {
            reminders.add(
              AdhkarReminder(
                id: '$key-morning-adhkar',
                group: AdhkarReminderGroup.morning,
                instant: instant,
              ),
            );
          }
        }
      }

      if (preferences.evening) {
        final asr = instantFor(PrayerName.asr);
        if (asr != null) {
          final instant = asr.add(
            Duration(minutes: preferences.eveningOffsetMinutes),
          );
          if (instant.isAfter(now)) {
            reminders.add(
              AdhkarReminder(
                id: '$key-evening-adhkar',
                group: AdhkarReminderGroup.evening,
                instant: instant,
              ),
            );
          }
        }
      }

      if (preferences.sleep) {
        final instant = tz.TZDateTime(
          location,
          date.year,
          date.month,
          date.day,
          preferences.sleepHour,
          preferences.sleepMinute,
        ).toUtc();
        if (instant.isAfter(now)) {
          reminders.add(
            AdhkarReminder(
              id: '$key-sleep-adhkar',
              group: AdhkarReminderGroup.sleep,
              instant: instant,
            ),
          );
        }
      }
    }

    reminders.sort((a, b) => a.instant.compareTo(b.instant));
    return reminders;
  }
}
