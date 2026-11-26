import 'dart:convert';

import 'package:material_ui/material_ui.dart' show ValueNotifier;
import 'package:timezone/timezone.dart' as tz;

import '../models/local_date.dart';
import '../repositories/prayer_log_repository.dart';
import '../worship/hijri_date.dart';
import '../worship/prayer_log.dart';
import '../worship/prayer_schedule.dart';
import '../worship/prayer_settings.dart';
import '../worship/prayer_times_service.dart';
import '../worship/timezone_bootstrap.dart';
import 'widget_bridge.dart';

/// Builds the JSON the native widgets render and keeps their update alarms
/// armed. Widgets are Android-only for v1; this class is platform agnostic.
class PrayerWidgetPublisher {
  PrayerWidgetPublisher({
    required this.settings,
    required this.log,
    this.bridge = const HomeWidgetBridge(),
    this.clock,
    this.daysAhead = 7,
    this.schedule = const PrayerScheduleService(),
  });

  static const dataKey = 'sakeenah_widget_v1';

  final ValueNotifier<PrayerSettings> settings;
  final PrayerLogRepository log;
  final WidgetBridge bridge;
  final DateTime Function()? clock;
  final int daysAhead;
  final PrayerScheduleService schedule;

  Future<void> refresh() async {
    final now = (clock?.call() ?? DateTime.now()).toUtc();
    final s = settings.value;

    if (!s.configured) {
      await _save({
        'version': 1,
        'configured': false,
        'updated': now.millisecondsSinceEpoch,
      });
      await _broadcast(const []);
      return;
    }

    final todayKey = dateKeyInTimezone(s.timezone, now: now);
    final today = DateTime.parse('${todayKey}T00:00:00');
    final location = locationFor(s.timezone);
    final days = <Map<String, Object?>>[];
    final updateTimes = <DateTime>[];

    for (var offset = 0; offset < daysAhead; offset++) {
      final date = DateTime(today.year, today.month, today.day + offset);
      final key = localDateKey(date);
      final day = await log.day(key);
      final slots = schedule.slotsForDate(s, date);
      final prayers = <Map<String, Object?>>[];
      for (final slot in slots) {
        if (slot.name == PrayerName.sunrise) continue;
        prayers.add({
          'id': slot.name.id,
          'name': slot.name.arabicName,
          'time': slot.timeLabel,
          'at': slot.instant.millisecondsSinceEpoch,
          'done': _isDone(day, slot.name),
        });
        updateTimes.add(slot.instant);
      }
      days.add({
        'date': key,
        'hijri': HijriDate.fromGregorian(
          date,
          adjustment: s.hijriAdjustment,
        ).formatAr(),
        'prayers': prayers,
      });
      // Refresh at date rollover too, so "today" switches at midnight.
      updateTimes.add(
        tz.TZDateTime(
          location,
          date.year,
          date.month,
          date.day + 1,
          0,
          5,
        ).toUtc(),
      );
    }

    final streak = await log.streak(todayKey);
    final payload = {
      'version': 1,
      'configured': true,
      'today': todayKey,
      'hijri': days.first['hijri'],
      'days': days,
      'streak': {
        'current': streak.current,
        'best': streak.best,
        'today': streak.todayCount,
        'goal': 5,
      },
      'updated': now.millisecondsSinceEpoch,
    };
    await _save(payload);
    await _broadcast(
      updateTimes.where((time) => time.isAfter(now)).toList()..sort(),
    );
  }

  /// Handles a `sakeenah://prayed?date=YYYY-MM-DD&prayer=fajr` click from the
  /// next-prayer widget. Returns whether the URI was consumed.
  Future<bool> handlePrayed(Uri uri) async {
    if (uri.scheme != 'sakeenah' || uri.host != 'prayed') return false;
    final date = uri.queryParameters['date'];
    final prayerId = uri.queryParameters['prayer'];
    if (date == null || prayerId == null) return false;
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) return false;

    PrayerName? prayer;
    for (final candidate in PrayerName.values) {
      if (candidate.id == prayerId) {
        prayer = candidate;
        break;
      }
    }
    if (prayer == null || prayer == PrayerName.sunrise) return false;

    final s = settings.value;
    if (!s.configured) return false;
    final now = (clock?.call() ?? DateTime.now()).toUtc();
    final today = dateKeyInTimezone(s.timezone, now: now);
    final clickedDate = DateTime.parse('${date}T00:00:00');
    final base = DateTime.parse('${today}T00:00:00');
    final distance = clickedDate.difference(base).inDays;
    if (distance < -1 || distance > 1) return false;

    // A stale widget tap must not log a prayer before its time.
    DateTime? instant;
    for (final slot in schedule.slotsForDate(s, clickedDate)) {
      if (slot.name == prayer) {
        instant = slot.instant;
        break;
      }
    }
    if (instant == null || instant.isAfter(now)) return false;

    await log.setStatus(date, prayer, PrayerStatus.onTime);
    await refresh();
    return true;
  }

  bool _isDone(PrayerDay day, PrayerName prayer) {
    final status = day.statuses[prayer];
    return status != null &&
        status != PrayerStatus.missed &&
        status != PrayerStatus.excused;
  }

  Future<void> _save(Map<String, Object?> payload) =>
      bridge.saveString(dataKey, jsonEncode(payload));

  Future<void> _broadcast(List<DateTime> times) async {
    for (final provider in PrayerWidgets.all) {
      await bridge.updateWidget(provider);
      await bridge.scheduleUpdates(provider, times);
    }
  }
}
