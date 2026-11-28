import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/adhan.dart';
import '../models/adhkar_reminders.dart';
import '../worship/prayer_settings.dart';
import '../worship/timezone_bootstrap.dart';

class AdhanDiagnostics {
  const AdhanDiagnostics({
    required this.notificationsEnabled,
    required this.exactAlarms,
    required this.batteryOptimized,
    required this.pendingCount,
  });

  final bool notificationsEnabled;
  final bool exactAlarms;

  /// True when the OS may throttle or kill the app in the background.
  final bool batteryOptimized;

  final int pendingCount;
}

abstract interface class PrayerNotificationService {
  Future<void> initialize();

  Future<bool> requestPermissions();

  Future<void> cancelAll();

  Future<void> schedule(
    List<PrayerNotification> events, {
    required AdhanPreferences preferences,
    required PrayerSettings settings,
  });

  Future<void> scheduleAdhkar(
    List<AdhkarReminder> reminders, {
    required PrayerSettings settings,
  });

  Future<void> showTest({String soundId = 'beautiful'});

  Future<void> scheduleTestIn(Duration delay, {String soundId = 'beautiful'});

  Future<bool> requestExactAlarms();

  Future<AdhanDiagnostics> diagnostics();
}

class AlarmSupport {
  static const _channel = MethodChannel('app.sakeenah.mobile/alarms');

  static Future<bool> batteryExempt() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>(
            'isIgnoringBatteryOptimizations',
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> openBatterySettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<bool>('openBatterySettings');
    } catch (_) {
      // Settings are unavailable on this build; the guidance text still helps.
    }
  }
}

class LocalPrayerNotificationService implements PrayerNotificationService {
  LocalPrayerNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
    int? maxPending,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _maxPending = maxPending ?? (Platform.isIOS ? 60 : null);

  // Android locks a channel's sound and audio attributes after creation, so
  // these v2 IDs carry the alarm-stream routing. The adhan must stay audible
  // when notification or media volume is low or muted.
  static const _adhanChannel = 'adhan_v2';
  static const _adhan2Channel = 'adhan_2_v2';
  static const _adhan3Channel = 'adhan_3_v2';
  static const _silentChannel = 'prayer_silent';
  static const _adhkarChannel = 'adhkar_reminders';
  static const _testId = 999999;
  static const _scheduledTestId = 999998;

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
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _adhan2Channel,
        'الأذان ٢',
        description: 'تسجيل أذان بديل',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('adhan_2'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _adhan3Channel,
        'الأذان ٣',
        description: 'تسجيل أذان بديل',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('adhan_3'),
        audioAttributesUsage: AudioAttributesUsage.alarm,
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
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _adhkarChannel,
        'تذكير الأذكار',
        description: 'تذكير بأذكار الصباح والمساء والنوم',
        importance: Importance.high,
        playSound: false,
        enableVibration: true,
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
    final exact = await _exactAllowed();
    final horizon = DateTime.now().add(const Duration(seconds: 2));
    final pending = events
        .where((event) => event.instant.isAfter(horizon))
        .take(_maxPending ?? events.length);

    for (final event in pending) {
      final spec = _sound(event.preAlert ? 'silent' : preferences.soundId);
      final details = _details(spec);
      // The adhan itself uses the alarm-clock mode: it is the most reliable
      // path through Doze. Pre-alerts use an exact alarm without the alarm UI.
      final mode = !exact
          ? AndroidScheduleMode.inexactAllowWhileIdle
          : event.preAlert
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.alarmClock;
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
          androidScheduleMode: mode,
          payload: event.prayer.name,
        );
      } catch (error) {
        debugPrint('Could not schedule ${event.id}: $error');
      }
    }
  }

  @override
  Future<void> scheduleAdhkar(
    List<AdhkarReminder> reminders, {
    required PrayerSettings settings,
  }) async {
    await initialize();
    final location = locationFor(settings.timezone);
    final exact = await _exactAllowed();
    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    final horizon = DateTime.now().add(const Duration(seconds: 2));
    final pending = reminders
        .where((reminder) => reminder.instant.isAfter(horizon))
        .take(_maxPending ?? reminders.length);

    for (final reminder in pending) {
      final (title, body) = switch (reminder.group) {
        AdhkarReminderGroup.morning => ('أذكار الصباح', 'حان وقت أذكار الصباح'),
        AdhkarReminderGroup.evening => ('أذكار المساء', 'حان وقت أذكار المساء'),
        AdhkarReminderGroup.sleep => ('أذكار النوم', 'حان وقت أذكار النوم'),
      };
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _adhkarChannel,
          'تذكير الأذكار',
          channelDescription: 'تذكير بأذكار الصباح والمساء والنوم',
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: const DarwinNotificationDetails(presentSound: false),
      );
      try {
        await _plugin.zonedSchedule(
          id: _notificationId(reminder.id),
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(reminder.instant, location),
          notificationDetails: details,
          androidScheduleMode: mode,
          payload: 'adhkar:${reminder.group.name}',
        );
      } catch (error) {
        debugPrint('Could not schedule ${reminder.id}: $error');
      }
    }
  }

  @override
  Future<void> showTest({String soundId = 'beautiful'}) async {
    await initialize();
    await _plugin.show(
      id: _testId,
      title: 'اختبار الأذان',
      body: 'ستظهر تنبيهات الصلاة هكذا.',
      notificationDetails: _details(_sound(soundId)),
    );
  }

  @override
  Future<void> scheduleTestIn(
    Duration delay, {
    String soundId = 'beautiful',
  }) async {
    await initialize();
    final exact = await _exactAllowed();
    final when = DateTime.now().toUtc().add(delay);
    await _plugin.zonedSchedule(
      id: _scheduledTestId,
      title: 'اختبار في الوقت',
      body: 'إذا وصل هذا التنبيه في وقته فالأذان سيعمل.',
      scheduledDate: tz.TZDateTime.from(when, tz.UTC),
      notificationDetails: _details(_sound(soundId)),
      androidScheduleMode: exact
          ? AndroidScheduleMode.alarmClock
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'test',
    );
  }

  @override
  Future<AdhanDiagnostics> diagnostics() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final enabled = await android?.areNotificationsEnabled() ?? true;
    final exact = await android?.canScheduleExactNotifications() ?? true;
    final exempt = await AlarmSupport.batteryExempt();
    final pending = await _plugin.pendingNotificationRequests();
    return AdhanDiagnostics(
      notificationsEnabled: enabled,
      exactAlarms: exact,
      batteryOptimized: !exempt,
      pendingCount: pending.length,
    );
  }

  @override
  Future<bool> requestExactAlarms() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestExactAlarmsPermission() ??
        await android?.canScheduleExactNotifications() ??
        true;
  }

  _SoundSpec _sound(String soundId) => switch (soundId) {
    'adhan' => const _SoundSpec(
      channelId: _adhan2Channel,
      channelName: 'الأذان ٢',
      rawName: 'adhan_2',
      iosFile: 'adhan2.caf',
    ),
    'sabah' => const _SoundSpec(
      channelId: _adhan3Channel,
      channelName: 'الأذان ٣',
      rawName: 'adhan_3',
      iosFile: 'adhan3.caf',
    ),
    'silent' => const _SoundSpec(
      channelId: _silentChannel,
      channelName: 'تنبيهات صامتة',
    ),
    _ => const _SoundSpec(
      channelId: _adhanChannel,
      channelName: 'الأذان',
      rawName: 'adhan',
      iosFile: 'adhan.caf',
    ),
  };

  NotificationDetails _details(_SoundSpec sound) {
    final audible = sound.rawName != null;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        sound.channelId,
        sound.channelName,
        channelDescription: audible
            ? 'تنبيهات وقت الصلاة'
            : 'تنبيهات الصلاة بدون صوت',
        importance: audible ? Importance.max : Importance.high,
        priority: Priority.high,
        playSound: audible,
        sound: audible
            ? RawResourceAndroidNotificationSound(sound.rawName)
            : null,
        audioAttributesUsage: audible
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
        category: AndroidNotificationCategory.alarm,
      ),
      iOS: DarwinNotificationDetails(
        presentSound: audible,
        sound: sound.iosFile,
      ),
    );
  }

  Future<bool> _exactAllowed() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.canScheduleExactNotifications() ?? true;
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

class _SoundSpec {
  const _SoundSpec({
    required this.channelId,
    required this.channelName,
    this.rawName,
    this.iosFile,
  });

  final String channelId;
  final String channelName;
  final String? rawName;
  final String? iosFile;
}
