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

  Future<void> refresh({DateTime? now}) async {
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
    await service.showTest();
  }

  Future<void> save(AdhanPreferences next) async {
    await preferences.save(next);
    await refresh();
  }
}
