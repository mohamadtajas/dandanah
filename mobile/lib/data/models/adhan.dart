import '../worship/prayer_times_service.dart';

const obligatoryPrayerNames = [
  PrayerName.fajr,
  PrayerName.dhuhr,
  PrayerName.asr,
  PrayerName.maghrib,
  PrayerName.isha,
];

class AdhanPreferences {
  /// Selectable pre-alert offsets in minutes; `0` disables the pre-alert.
  static const preAlertOptions = [0, 5, 10, 15, 20];

  /// Bundled adhan recordings plus a silent option.
  static const soundIds = ['beautiful', 'adhan', 'sabah', 'silent'];

  static const _defaultPreAlerts = {
    PrayerName.fajr: 10,
    PrayerName.dhuhr: 10,
    PrayerName.asr: 10,
    PrayerName.maghrib: 10,
    PrayerName.isha: 10,
  };

  const AdhanPreferences({
    this.enabled = const {
      PrayerName.fajr: true,
      PrayerName.dhuhr: true,
      PrayerName.asr: true,
      PrayerName.maghrib: true,
      PrayerName.isha: true,
    },
    this.preAlerts = _defaultPreAlerts,
    this.soundId = 'beautiful',
  });

  final Map<PrayerName, bool> enabled;

  /// Minutes before each prayer for its pre-alert; `0` disables it.
  final Map<PrayerName, int> preAlerts;

  /// One of [soundIds]; `silent` mutes the adhan itself.
  final String soundId;

  bool get soundEnabled => soundId != 'silent';

  factory AdhanPreferences.defaults() => const AdhanPreferences();

  /// Snaps a stored/legacy value to an option the settings dropdown can show.
  static int normalizePreAlert(int minutes) {
    var best = preAlertOptions.first;
    for (final option in preAlertOptions) {
      if ((option - minutes).abs() < (best - minutes).abs()) best = option;
    }
    return best;
  }

  bool isEnabled(PrayerName prayer) =>
      obligatoryPrayerNames.contains(prayer) && (enabled[prayer] ?? true);

  int preAlertFor(PrayerName prayer) =>
      normalizePreAlert(preAlerts[prayer] ?? 10);

  AdhanPreferences copyWith({
    Map<PrayerName, bool>? enabled,
    Map<PrayerName, int>? preAlerts,
    String? soundId,
    bool? soundEnabled,
  }) {
    final nextSound = soundId != null
        ? (soundIds.contains(soundId) ? soundId : 'beautiful')
        : (soundEnabled == null
              ? this.soundId
              : (soundEnabled
                    ? (this.soundId == 'silent' ? 'beautiful' : this.soundId)
                    : 'silent'));
    return AdhanPreferences(
      enabled: enabled ?? this.enabled,
      preAlerts: preAlerts == null
          ? this.preAlerts
          : {
              for (final prayer in obligatoryPrayerNames)
                prayer: normalizePreAlert(preAlerts[prayer] ?? 10),
            },
      soundId: nextSound,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': {
      for (final prayer in obligatoryPrayerNames)
        prayer.name: isEnabled(prayer),
    },
    'preAlerts': {
      for (final prayer in obligatoryPrayerNames)
        prayer.name: preAlertFor(prayer),
    },
    'soundId': soundId,
    'soundEnabled': soundEnabled,
  };

  factory AdhanPreferences.fromJson(Map<String, dynamic> json) {
    final raw = json['enabled'];
    final map = <PrayerName, bool>{};
    if (raw is Map) {
      for (final prayer in obligatoryPrayerNames) {
        final value = raw[prayer.name];
        map[prayer] = value is bool ? value : true;
      }
    } else {
      for (final prayer in obligatoryPrayerNames) {
        map[prayer] = true;
      }
    }

    // Version 1 stored one global `preAlertMinutes`; migrate it to all five.
    final legacy = json['preAlertMinutes'];
    final legacyMinutes = normalizePreAlert(
      legacy is num ? legacy.toInt() : 10,
    );
    final rawAlerts = json['preAlerts'];
    final alerts = <PrayerName, int>{};
    for (final prayer in obligatoryPrayerNames) {
      final value = rawAlerts is Map ? rawAlerts[prayer.name] : null;
      alerts[prayer] = normalizePreAlert(
        value is num ? value.toInt() : legacyMinutes,
      );
    }

    final storedId = json['soundId'];
    final legacySound = json['soundEnabled'];
    final soundId = soundIds.contains(storedId)
        ? storedId as String
        : (legacySound is bool
              ? (legacySound ? 'beautiful' : 'silent')
              : 'beautiful');
    return AdhanPreferences(enabled: map, preAlerts: alerts, soundId: soundId);
  }
}

class PrayerNotification {
  const PrayerNotification({
    required this.id,
    required this.prayer,
    required this.instant,
    required this.preAlert,
    this.preAlertMinutes = 0,
  });

  final String id;
  final PrayerName prayer;
  final DateTime instant;
  final bool preAlert;

  /// Offset carried into the notification body; zero for the adhan itself.
  final int preAlertMinutes;
}
