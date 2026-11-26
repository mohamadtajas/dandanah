import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint;
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

  Future<void> showTest({bool withSound = true});
}

class LocalPrayerNotificationService implements PrayerNotificationService {
  LocalPrayerNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    int? maxPending,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _maxPending = maxPending ?? (Platform.isIOS ? 60 : null);

  static const _adhanChannel = 'adhan';
  static const _silentChannel = 'prayer_silent';
  static const _testId = 999999;

  /// iOS keeps at most 64 pending requests; older ones are silently dropped.
  static const iosPendingLimit = 64;

  final FlutterLocalNotificationsPlugin _plugin;
  final int? _maxPending;
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
    // Android channels own their sound, so a separate silent channel is
    // required for pre-alerts and when the adhan sound is disabled.
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _silentChannel,
        'تنبيهات صامتة',
        description: 'تنبيهات الصلاة بدون صوت',
        importance: Importance.high,
        playSound: false,
        enableVibration: false,
      ),
    );
    _initialized = true;
  }

  @override
  Future<bool> requestPermissions() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final notifications =
        await android?.requestNotificationsPermission() ?? true;
    final exact = await android?.requestExactAlarmsPermission() ?? true;
    // Exact alarms are an optimisation: scheduling falls back to inexact
    // alarms, so only notification permission is decisive here.
    debugPrint('Exact alarm permission: $exact');
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosGranted =
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;
    return notifications && iosGranted;
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
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final exactAlarms = await android?.canScheduleExactNotifications() ?? false;
    final scheduleMode = exactAlarms
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    debugPrint('Scheduling prayer notifications with $scheduleMode');
    final horizon = DateTime.now().add(const Duration(seconds: 2));
    final pending = events
        .where((event) => event.instant.isAfter(horizon))
        .take(_maxPending ?? events.length);

    for (final event in pending) {
      final useAdhanSound = preferences.soundEnabled && !event.preAlert;
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          useAdhanSound ? _adhanChannel : _silentChannel,
          useAdhanSound ? 'الأذان' : 'تنبيهات صامتة',
          channelDescription: useAdhanSound
              ? 'تنبيهات وقت الصلاة'
              : 'تنبيهات الصلاة بدون صوت',
          importance: useAdhanSound ? Importance.max : Importance.high,
          priority: Priority.high,
          playSound: useAdhanSound,
          sound: useAdhanSound
              ? const RawResourceAndroidNotificationSound('adhan')
              : null,
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: useAdhanSound,
          sound: useAdhanSound ? 'adhan.caf' : null,
        ),
      );
      try {
        await _plugin.zonedSchedule(
          id: _notificationId(event.id),
          title: event.preAlert
              ? 'اقتربت صلاة ${event.prayer.arabicName}'
              : 'حان وقت صلاة ${event.prayer.arabicName}',
          body: event.preAlert
              ? 'بعد ${event.preAlertMinutes} دقيقة'
              : 'حان وقت الصلاة',
          scheduledDate: tz.TZDateTime.from(event.instant, location),
          notificationDetails: details,
          androidScheduleMode: scheduleMode,
          payload: event.prayer.name,
        );
      } catch (error) {
        // One refused request must not abort the rest of the plan.
        debugPrint('Could not schedule ${event.id}: $error');
      }
    }
  }

  @override
  Future<void> showTest({bool withSound = true}) async {
    await initialize();
    await _plugin.show(
      id: _testId,
      title: 'اختبار الأذان',
      body: 'ستظهر تنبيهات الصلاة هكذا.',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          withSound ? _adhanChannel : _silentChannel,
          withSound ? 'الأذان' : 'تنبيهات صامتة',
          channelDescription: 'تنبيهات وقت الصلاة',
          importance: withSound ? Importance.max : Importance.high,
          priority: Priority.high,
          playSound: withSound,
          sound: withSound
              ? const RawResourceAndroidNotificationSound('adhan')
              : null,
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: withSound,
          sound: withSound ? 'adhan.caf' : null,
        ),
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
