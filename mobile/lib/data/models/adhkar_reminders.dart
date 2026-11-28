enum AdhkarReminderGroup { morning, evening, sleep }

class AdhkarReminderPreferences {
  const AdhkarReminderPreferences({
    this.morning = false,
    this.evening = false,
    this.sleep = false,
    this.morningOffsetMinutes = 30,
    this.eveningOffsetMinutes = 30,
    this.sleepHour = 21,
    this.sleepMinute = 30,
  });

  static const offsets = [15, 30, 45, 60, 90];

  final bool morning;
  final bool evening;
  final bool sleep;

  /// Minutes after Fajr.
  final int morningOffsetMinutes;

  /// Minutes after Asr.
  final int eveningOffsetMinutes;

  final int sleepHour;
  final int sleepMinute;

  factory AdhkarReminderPreferences.defaults() =>
      const AdhkarReminderPreferences();

  bool isEnabled(AdhkarReminderGroup group) => switch (group) {
    AdhkarReminderGroup.morning => morning,
    AdhkarReminderGroup.evening => evening,
    AdhkarReminderGroup.sleep => sleep,
  };

  static int normalizeOffset(int minutes) {
    if (offsets.contains(minutes)) return minutes;
    var best = offsets.first;
    for (final option in offsets) {
      if ((option - minutes).abs() < (best - minutes).abs()) best = option;
    }
    return best;
  }

  AdhkarReminderPreferences copyWith({
    bool? morning,
    bool? evening,
    bool? sleep,
    int? morningOffsetMinutes,
    int? eveningOffsetMinutes,
    int? sleepHour,
    int? sleepMinute,
  }) => AdhkarReminderPreferences(
    morning: morning ?? this.morning,
    evening: evening ?? this.evening,
    sleep: sleep ?? this.sleep,
    morningOffsetMinutes: morningOffsetMinutes == null
        ? this.morningOffsetMinutes
        : normalizeOffset(morningOffsetMinutes),
    eveningOffsetMinutes: eveningOffsetMinutes == null
        ? this.eveningOffsetMinutes
        : normalizeOffset(eveningOffsetMinutes),
    sleepHour: (sleepHour ?? this.sleepHour).clamp(0, 23),
    sleepMinute: (sleepMinute ?? this.sleepMinute).clamp(0, 59),
  );

  Map<String, dynamic> toJson() => {
    'morning': morning,
    'evening': evening,
    'sleep': sleep,
    'morningOffsetMinutes': morningOffsetMinutes,
    'eveningOffsetMinutes': eveningOffsetMinutes,
    'sleepHour': sleepHour,
    'sleepMinute': sleepMinute,
  };

  factory AdhkarReminderPreferences.fromJson(Map<String, dynamic> json) {
    bool flag(String key) => json[key] is bool ? json[key] as bool : false;
    int number(String key, int fallback) =>
        json[key] is num ? (json[key] as num).toInt() : fallback;
    return AdhkarReminderPreferences(
      morning: flag('morning'),
      evening: flag('evening'),
      sleep: flag('sleep'),
      morningOffsetMinutes: normalizeOffset(number('morningOffsetMinutes', 30)),
      eveningOffsetMinutes: normalizeOffset(number('eveningOffsetMinutes', 30)),
      sleepHour: number('sleepHour', 21).clamp(0, 23),
      sleepMinute: number('sleepMinute', 30).clamp(0, 59),
    );
  }
}

class AdhkarReminder {
  const AdhkarReminder({
    required this.id,
    required this.group,
    required this.instant,
  });

  final String id;
  final AdhkarReminderGroup group;
  final DateTime instant;
}
