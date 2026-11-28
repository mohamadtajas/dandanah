import 'package:material_ui/material_ui.dart';

import '../models/adhan.dart';
import '../models/adhkar_reminders.dart';
import '../repositories/adhan_settings_repository.dart';
import '../repositories/adhkar_reminder_repository.dart';
import 'adhkar_reminders.dart';
import 'prayer_notification_service.dart';
import 'prayer_notifications.dart';
import 'prayer_settings.dart';

class AdhanScheduler {
  AdhanScheduler({
    required this.preferences,
    required this.settings,
    required this.service,
    this.adhkarPreferences,
    this.planner = const PrayerNotificationPlanner(),
    this.adhkarPlanner = const AdhkarReminderPlanner(),
  });

  final AdhanSettingsRepository preferences;
  final ValueNotifier<PrayerSettings> settings;
  final PrayerNotificationService service;
  final AdhkarReminderRepository? adhkarPreferences;
  final PrayerNotificationPlanner planner;
  final AdhkarReminderPlanner adhkarPlanner;

  /// Serialises refreshes so `cancelAll` and `schedule` cannot interleave.
  Future<void> _tail = Future<void>.value();

  Future<void> refresh({DateTime? now}) {
    final result = _tail.then((_) => _refresh(now: now));
    _tail = result.then((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<void> _refresh({DateTime? now}) async {
    // Before onboarding the settings are only Mecca defaults; scheduling
    // those would alert the user at the wrong times.
    if (!settings.value.configured) return;
    final at = now ?? DateTime.now().toUtc();
    await service.initialize();
    final prefs = await preferences.load();
    final plan = planner.plan(
      settings: settings.value,
      preferences: prefs,
      nowUtc: at,
    );
    await service.cancelAll();
    await service.schedule(plan, preferences: prefs, settings: settings.value);

    final reminderRepo = adhkarPreferences;
    if (reminderRepo != null) {
      final reminderPrefs = await reminderRepo.load();
      if (reminderPrefs.morning ||
          reminderPrefs.evening ||
          reminderPrefs.sleep) {
        final reminders = adhkarPlanner.plan(
          settings: settings.value,
          preferences: reminderPrefs,
          nowUtc: at,
        );
        await service.scheduleAdhkar(reminders, settings: settings.value);
      }
    }
  }

  Future<bool> requestPermissions() => service.requestPermissions();

  Future<bool> requestExactAlarms() => service.requestExactAlarms();

  Future<void> sendTest() async {
    await service.initialize();
    final prefs = await preferences.load();
    await service.showTest(soundId: prefs.soundId);
  }

  Future<void> sendScheduledTest(Duration delay) async {
    await service.initialize();
    final prefs = await preferences.load();
    await service.scheduleTestIn(delay, soundId: prefs.soundId);
  }

  Future<AdhanDiagnostics> diagnostics() => service.diagnostics();

  Future<void> save(AdhanPreferences next) async {
    await preferences.save(next);
    await refresh();
  }

  Future<void> saveAdhkarPreferences(AdhkarReminderPreferences next) async {
    await adhkarPreferences?.save(next);
    await refresh();
  }

  Future<AdhkarReminderPreferences> loadAdhkarPreferences() async =>
      await adhkarPreferences?.load() ?? AdhkarReminderPreferences.defaults();
}
