import 'package:timezone/timezone.dart' as tz;

import '../models/adhan.dart';
import '../models/local_date.dart';
import 'prayer_schedule.dart';
import 'prayer_settings.dart';
import 'timezone_bootstrap.dart';

class PrayerNotificationPlanner {
  const PrayerNotificationPlanner({this.daysAhead = 14});

  final int daysAhead;

  List<PrayerNotification> plan({
    required PrayerSettings settings,
    required AdhanPreferences preferences,
    required DateTime nowUtc,
    int? daysAhead,
  }) {
    final now = nowUtc.toUtc();
    final location = locationFor(settings.timezone);
    final localNow = tz.TZDateTime.from(now, location);
    final events = <PrayerNotification>[];
    final days = daysAhead ?? this.daysAhead;

    for (var offset = 0; offset < days; offset++) {
      final localDate = tz.TZDateTime(
        location,
        localNow.year,
        localNow.month,
        localNow.day + offset,
        12,
      );
      final date = DateTime(localDate.year, localDate.month, localDate.day);
      final slots = const PrayerScheduleService().slotsForDate(settings, date);
      for (final slot in slots) {
        if (!obligatoryPrayerNames.contains(slot.name)) continue;
        if (!preferences.isEnabled(slot.name)) continue;
        final day = localDateKey(date);
        if (slot.instant.isAfter(now)) {
          events.add(
            PrayerNotification(
              id: '$day-${slot.name.name}-adhan',
              prayer: slot.name,
              instant: slot.instant,
              preAlert: false,
            ),
          );
        }
        final minutes = preferences.preAlertFor(slot.name);
        if (minutes > 0) {
          final pre = slot.instant.subtract(Duration(minutes: minutes));
          if (pre.isAfter(now)) {
            events.add(
              PrayerNotification(
                id: '$day-${slot.name.name}-pre',
                prayer: slot.name,
                instant: pre,
                preAlert: true,
                preAlertMinutes: minutes,
              ),
            );
          }
        }
      }
    }

    events.sort((a, b) => a.instant.compareTo(b.instant));
    return events;
  }
}
