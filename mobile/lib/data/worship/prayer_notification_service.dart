import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/adhan.dart';
import '../worship/prayer_settings.dart';
import '../worship/timezone_bootstrap.dart';

abstract interface class PrayerNotificationService {
  Future<void> initialize();

  Future<bool> requestPermissions();

  Future<void> cancelAll();

  Future<void> schedule(
    List<PrayerNotification> events, {
    required AdhanPreferences preferences,
    required PrayerSettings settings,
  });

  Future<void> showTest();
}

class LocalPrayerNotificationService implements PrayerNotificationService {
  LocalPrayerNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _adhanChannel = 'adhan';
  static const _reminderChannel = 'prayer_reminders';
  static const _testId = 999999;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    ensureTimezones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestSoundPermission: false,
      requestBadgePermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _adhanChannel,
        'الأذان',
        description: 'تنبيهات وقت الصلاة',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('adhan'),
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _reminderChannel,
        'تنبيهات الصلاة',
        description: 'تذكير قبل الصلاة',
        importance: Importance.high,
      ),
    );
    _initialized = true;
  }

  @override
  Future<bool> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final notifications =
        await android?.requestNotificationsPermission() ?? true;
    final exact = await android?.requestExactAlarmsPermission() ?? true;
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosGranted =
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;
    return notifications && exact && iosGranted;
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> schedule(
    List<PrayerNotification> events, {
    required AdhanPreferences preferences,
    required PrayerSettings settings,
  }) async {
    await initialize();
    final location = locationFor(settings.timezone);
    for (final event in events) {
      final isAdhan = !event.preAlert;
      final useAdhanSound = preferences.soundEnabled && isAdhan;
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          useAdhanSound ? _adhanChannel : _reminderChannel,
          useAdhanSound ? 'الأذان' : 'تنبيهات الصلاة',
          channelDescription: 'تنبيهات وقت الصلاة',
          importance: Importance.max,
          priority: Priority.high,
          playSound: useAdhanSound,
          sound: useAdhanSound
              ? const RawResourceAndroidNotificationSound('adhan')
              : null,
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: DarwinNotificationDetails(presentSound: useAdhanSound),
      );
      await _plugin.zonedSchedule(
        id: _notificationId(event.id),
        title: event.preAlert
            ? 'اقتربت صلاة ${event.prayer.arabicName}'
            : 'حان وقت صلاة ${event.prayer.arabicName}',
        body: event.preAlert
            ? 'بعد ${preferences.preAlertMinutes} دقيقة'
            : 'حان وقت الصلاة',
        scheduledDate: tz.TZDateTime.from(event.instant, location),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: event.prayer.name,
      );
    }
  }

  @override
  Future<void> showTest() async {
    await initialize();
    await _plugin.show(
      id: _testId,
      title: 'اختبار الأذان',
      body: 'ستظهر تنبيهات الصلاة هكذا.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _adhanChannel,
          'الأذان',
          channelDescription: 'تنبيهات وقت الصلاة',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('adhan'),
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: DarwinNotificationDetails(presentSound: true),
      ),
    );
  }

  int _notificationId(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }
}
