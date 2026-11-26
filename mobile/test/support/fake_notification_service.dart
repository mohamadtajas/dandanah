import 'package:sakeenah_mobile/data/models/adhan.dart';
import 'package:sakeenah_mobile/data/worship/prayer_notification_service.dart';
import 'package:sakeenah_mobile/data/worship/prayer_settings.dart';

class FakeNotificationService implements PrayerNotificationService {
  int initialized = 0;
  int cancelled = 0;
  int permissionsAsked = 0;
  int testShown = 0;
  List<PrayerNotification> events = [];
  bool grantPermissions = true;

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
  Future<void> showTest() async => testShown++;
}
