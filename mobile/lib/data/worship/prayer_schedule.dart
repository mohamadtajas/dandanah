import 'package:timezone/timezone.dart' as tz;

import '../models/local_date.dart';
import 'hijri_date.dart';
import 'prayer_settings.dart';
import 'prayer_times_service.dart';
import 'qibla.dart';
import 'timezone_bootstrap.dart';

class PrayerSlot {
  const PrayerSlot({
    required this.name,
    required this.local,
    required this.instant,
    required this.ownerDate,
  });

  final PrayerName name;
  final DateTime local;
  final DateTime instant;

  /// Local `YYYY-MM-DD` day this reading belongs to. A late Isha may belong to
  /// yesterday while still being the next prayer after midnight.
  final String ownerDate;

  String get timeLabel =>
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

class PrayerSchedule {
  const PrayerSchedule({
    required this.settings,
    required this.nowUtc,
    required this.nowLocal,
    required this.previous,
    required this.today,
    required this.tomorrow,
    required this.hijri,
    required this.qibla,
  });

  final PrayerSettings settings;
  final DateTime nowUtc;
  final DateTime nowLocal;
  final List<PrayerSlot> previous;
  final List<PrayerSlot> today;
  final List<PrayerSlot> tomorrow;
  final HijriDate hijri;
  final double qibla;

  String get dateKey => localDateKey(nowLocal);

  PrayerSlot get next => nextAt(nowUtc);

  PrayerSlot nextAt(DateTime now) {
    final candidates = [
      for (final slot in [...previous, ...today, ...tomorrow])
        if (slot.name != PrayerName.sunrise && slot.instant.isAfter(now)) slot,
    ]..sort((a, b) => a.instant.compareTo(b.instant));
    if (candidates.isNotEmpty) return candidates.first;
    return tomorrow.firstWhere((slot) => slot.name == PrayerName.fajr);
  }

  Duration get remaining => remainingAt(nowUtc);

  Duration remainingAt(DateTime now) {
    final left = nextAt(now).instant.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  bool passed(PrayerName name) => passedAt(name, nowUtc);

  bool passedAt(PrayerName name, DateTime now) {
    final slots =
        [...previous, ...today].where((slot) => slot.name == name).toList()
          ..sort((a, b) => b.instant.compareTo(a.instant));
    if (slots.isEmpty) return false;
    return !slots.first.instant.isAfter(now);
  }

  /// Previous-day late prayers that are still upcoming, followed by today.
  List<PrayerSlot> displayAt(DateTime now) {
    final late = previous
        .where(
          (slot) =>
              slot.name != PrayerName.sunrise && slot.instant.isAfter(now),
        )
        .toList();
    return [...late, ...today]..sort((a, b) => a.instant.compareTo(b.instant));
  }

  bool isSameLocalDate(DateTime now) {
    final location = locationFor(settings.timezone);
    final local = tz.TZDateTime.from(now, location);
    return localDateKey(local) == dateKey;
  }

  PrayerSlot slot(PrayerName name) =>
      today.firstWhere((slot) => slot.name == name);
}

/// Turns saved settings into today's schedule and the next prayer.
class PrayerScheduleService {
  const PrayerScheduleService();

  PrayerSchedule? tryBuild(PrayerSettings settings, {DateTime? nowUtc}) {
    try {
      return build(settings, nowUtc: nowUtc);
    } catch (_) {
      return null;
    }
  }

  PrayerSchedule build(PrayerSettings settings, {DateTime? nowUtc}) {
    final location = locationFor(settings.timezone);
    final now = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    final localNow = tz.TZDateTime.from(now, location);

    final previousDate = tz.TZDateTime(
      location,
      localNow.year,
      localNow.month,
      localNow.day - 1,
      12,
    );
    final nextDate = tz.TZDateTime(
      location,
      localNow.year,
      localNow.month,
      localNow.day + 1,
      12,
    );

    final previous = _day(
      settings,
      location,
      previousDate.year,
      previousDate.month,
      previousDate.day,
    );
    final today = _day(
      settings,
      location,
      localNow.year,
      localNow.month,
      localNow.day,
    );
    final tomorrow = _day(
      settings,
      location,
      nextDate.year,
      nextDate.month,
      nextDate.day,
    );

    return PrayerSchedule(
      settings: settings,
      nowUtc: now,
      nowLocal: localNow,
      previous: previous,
      today: today,
      tomorrow: tomorrow,
      hijri: HijriDate.fromGregorian(
        DateTime(localNow.year, localNow.month, localNow.day),
        adjustment: settings.hijriAdjustment,
      ),
      qibla: qiblaBearing(settings.latitude, settings.longitude),
    );
  }

  List<PrayerSlot> _day(
    PrayerSettings settings,
    tz.Location location,
    int year,
    int month,
    int day,
  ) {
    final noon = tz.TZDateTime(location, year, month, day, 12);
    final offset = noon.timeZoneOffset;
    final times = const PrayerTimesService().calculate(
      date: DateTime(year, month, day),
      latitude: settings.latitude,
      longitude: settings.longitude,
      method: settings.method,
      utcOffset: offset,
      madhab: settings.madhab,
      highLatitude: settings.highLatitude,
    );
    final ownerDate = localDateKey(DateTime(year, month, day));

    return [
      for (final entry in times.all.entries)
        PrayerSlot(
          name: entry.key,
          local: entry.value,
          instant: DateTime.utc(
            entry.value.year,
            entry.value.month,
            entry.value.day,
            entry.value.hour,
            entry.value.minute,
            entry.value.second,
          ).subtract(offset),
          ownerDate: ownerDate,
        ),
    ];
  }
}
