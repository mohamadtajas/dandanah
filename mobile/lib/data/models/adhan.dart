import '../worship/prayer_times_service.dart';

const obligatoryPrayerNames = [
  PrayerName.fajr,
  PrayerName.dhuhr,
  PrayerName.asr,
  PrayerName.maghrib,
  PrayerName.isha,
];

class AdhanPreferences {
  const AdhanPreferences({
    this.enabled = const {
      PrayerName.fajr: true,
      PrayerName.dhuhr: true,
      PrayerName.asr: true,
      PrayerName.maghrib: true,
      PrayerName.isha: true,
    },
    this.preAlertMinutes = 10,
    this.soundEnabled = true,
  });

  final Map<PrayerName, bool> enabled;
  final int preAlertMinutes;
  final bool soundEnabled;

  factory AdhanPreferences.defaults() => const AdhanPreferences();

  bool isEnabled(PrayerName prayer) =>
      obligatoryPrayerNames.contains(prayer) && (enabled[prayer] ?? true);

  AdhanPreferences copyWith({
    Map<PrayerName, bool>? enabled,
    int? preAlertMinutes,
    bool? soundEnabled,
  }) => AdhanPreferences(
    enabled: enabled ?? this.enabled,
    preAlertMinutes: preAlertMinutes ?? this.preAlertMinutes,
    soundEnabled: soundEnabled ?? this.soundEnabled,
  );

  Map<String, dynamic> toJson() => {
    'enabled': {
      for (final prayer in obligatoryPrayerNames)
        prayer.name: isEnabled(prayer),
    },
    'preAlertMinutes': preAlertMinutes,
    'soundEnabled': soundEnabled,
  };

  factory AdhanPreferences.fromJson(Map<String, dynamic> json) {
    final raw = json['enabled'];
    final map = <PrayerName, bool>{};
    if (raw is Map) {
      for (final prayer in obligatoryPrayerNames) {
        map[prayer] = raw[prayer.name] as bool? ?? true;
      }
    } else {
      for (final prayer in obligatoryPrayerNames) {
        map[prayer] = true;
      }
    }
    return AdhanPreferences(
      enabled: map,
      preAlertMinutes: (json['preAlertMinutes'] as num?)?.toInt() ?? 10,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
    );
  }
}

class PrayerNotification {
  const PrayerNotification({
    required this.id,
    required this.prayer,
    required this.instant,
    required this.preAlert,
  });

  final String id;
  final PrayerName prayer;
  final DateTime instant;
  final bool preAlert;
}
