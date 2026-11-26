import 'package:material_ui/material_ui.dart';

import '../models/adhan.dart';
import '../repositories/adhan_settings_repository.dart';
import 'prayer_notification_service.dart';
import 'prayer_notifications.dart';
import 'prayer_settings.dart';

class AdhanScheduler {
  AdhanScheduler({
    required this.preferences,
    required this.settings,
    required this.service,
    this.planner = const PrayerNotificationPlanner(),
  });

  final AdhanSettingsRepository preferences;
  final ValueNotifier<PrayerSettings> settings;
  final PrayerNotificationService service;
  final PrayerNotificationPlanner planner;

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
    await service.initialize();
    final prefs = await preferences.load();
    final plan = planner.plan(
      settings: settings.value,
      preferences: prefs,
      nowUtc: now ?? DateTime.now().toUtc(),
    );
    await service.cancelAll();
    await service.schedule(plan, preferences: prefs, settings: settings.value);
  }

  Future<bool> requestPermissions() => service.requestPermissions();

  Future<void> sendTest() async {
    await service.initialize();
    final prefs = await preferences.load();
    await service.showTest(withSound: prefs.soundEnabled);
  }

  Future<void> save(AdhanPreferences next) async {
    await preferences.save(next);
    await refresh();
  }
}
