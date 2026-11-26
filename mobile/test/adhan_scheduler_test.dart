import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/data/models/adhan.dart';
import 'package:sakeenah_mobile/data/repositories/adhan_settings_repository.dart';
import 'package:sakeenah_mobile/data/worship/adhan_scheduler.dart';
import 'package:sakeenah_mobile/data/worship/prayer_notification_service.dart';
import 'package:sakeenah_mobile/data/worship/prayer_settings.dart';

void main() {
  late AppDatabase db;
  late AdhanSettingsRepository preferences;
  late ValueNotifier<PrayerSettings> settings;
  late _FakeNotifications service;
  late AdhanScheduler scheduler;

  setUp(() {
    db = AppDatabase.memory();
    preferences = AdhanSettingsRepository(db);
    settings = ValueNotifier(
      PrayerSettings.defaults().copyWith(configured: true),
    );
    service = _FakeNotifications();
    scheduler = AdhanScheduler(
      preferences: preferences,
      settings: settings,
      service: service,
    );
  });

  tearDown(() async {
    settings.dispose();
    await db.close();
  });

  test('refresh cancels and schedules the next two weeks', () async {
    await scheduler.refresh(now: DateTime.utc(2026, 11, 26));

    expect(service.initialized, 1);
    expect(service.cancelled, 1);
    expect(service.events, hasLength(140));
    expect(service.events.first.prayer.arabicName, isNotEmpty);
  });

  test('saving preferences reschedules with the new pre-alert', () async {
    await scheduler.refresh(now: DateTime.utc(2026, 11, 26));
    service.events.clear();

    await scheduler.save(
      AdhanPreferences.defaults().copyWith(
        preAlerts: {for (final prayer in obligatoryPrayerNames) prayer: 0},
      ),
    );
    expect(service.events.where((event) => event.preAlert), isEmpty);
  });

  test('permission and test notification are forwarded', () async {
    expect(await scheduler.requestPermissions(), isTrue);
    expect(service.permissionsAsked, 1);
    await scheduler.sendTest();
    expect(service.testShown, 1);
    expect(service.lastTestWithSound, isTrue);
  });

  test('an unconfigured location schedules nothing', () async {
    settings.value = PrayerSettings.defaults();
    await scheduler.refresh(now: DateTime.utc(2026, 11, 26));

    expect(service.initialized, 0);
    expect(service.cancelled, 0);
    expect(service.events, isEmpty);
  });

  test('concurrent refreshes are serialised', () async {
    await Future.wait([
      scheduler.refresh(now: DateTime.utc(2026, 11, 26)),
      scheduler.refresh(now: DateTime.utc(2026, 11, 26)),
    ]);

    expect(service.cancelled, 2);
  });
}

class _FakeNotifications implements PrayerNotificationService {
  int initialized = 0;
  int cancelled = 0;
  int permissionsAsked = 0;
  int testShown = 0;
  bool? lastTestWithSound;
  List<PrayerNotification> events = [];

  @override
  Future<void> initialize() async => initialized++;

  @override
  Future<bool> requestPermissions() async {
    permissionsAsked++;
    return true;
  }

  @override
  Future<void> cancelAll() async => cancelled++;

  @override
  Future<void> schedule(
    List<PrayerNotification> events, {
    required AdhanPreferences preferences,
    required PrayerSettings settings,
  }) async {
    this.events = events;
  }

  @override
  Future<void> showTest({bool withSound = true}) async {
    testShown++;
    lastTestWithSound = withSound;
  }
}
