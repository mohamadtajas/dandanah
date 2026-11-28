import 'package:sakeenah_mobile/data/models/adhan.dart';
import 'package:sakeenah_mobile/data/models/adhkar_reminders.dart';
import 'package:sakeenah_mobile/data/worship/prayer_notification_service.dart';
import 'package:sakeenah_mobile/data/worship/prayer_settings.dart';

class FakeNotificationService implements PrayerNotificationService {
  int initialized = 0;
  int cancelled = 0;
  int permissionsAsked = 0;
  int testShown = 0;
  int scheduledTests = 0;
  List<PrayerNotification> events = [];
  List<AdhkarReminder> reminders = [];
  bool grantPermissions = true;
  String? lastTestSoundId;
  AdhanDiagnostics diagnosticsValue = const AdhanDiagnostics(
    notificationsEnabled: true,
    exactAlarms: true,
    batteryOptimized: false,
    pendingCount: 0,
  );

  @override
  Future<void> initialize() async => initialized++;

  @override
  Future<bool> requestPermissions() async {
    permissionsAsked++;
    return grantPermissions;
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
  Future<void> showTest({String soundId = 'beautiful'}) async {
    testShown++;
    lastTestSoundId = soundId;
  }

  @override
  Future<void> scheduleAdhkar(
    List<AdhkarReminder> reminders, {
    required PrayerSettings settings,
  }) async {
    this.reminders = reminders;
  }

  @override
  Future<void> scheduleTestIn(
    Duration delay, {
    String soundId = 'beautiful',
  }) async => scheduledTests++;

  @override
  Future<bool> requestExactAlarms() async => true;

  @override
  Future<AdhanDiagnostics> diagnostics() async => diagnosticsValue;
}
