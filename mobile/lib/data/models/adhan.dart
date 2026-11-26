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

  AdhanPreferences copyWith({
    Map<PrayerName, bool>? enabled,
    int? preAlertMinutes,
    bool? soundEnabled,
  }) => AdhanPreferences(
    enabled: enabled ?? this.enabled,
    preAlertMinutes: preAlertMinutes == null
        ? this.preAlertMinutes
        : normalizePreAlert(preAlertMinutes),
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
        final value = raw[prayer.name];
        map[prayer] = value is bool ? value : true;
      }
    } else {
      for (final prayer in obligatoryPrayerNames) {
        map[prayer] = true;
      }
    }
    final sound = json['soundEnabled'];
    return AdhanPreferences(
      enabled: map,
      preAlertMinutes: normalizePreAlert(
        (json['preAlertMinutes'] as num?)?.toInt() ?? 10,
      ),
      soundEnabled: sound is bool ? sound : true,
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
