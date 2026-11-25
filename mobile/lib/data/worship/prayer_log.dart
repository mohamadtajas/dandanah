import '../models/local_date.dart';
import 'prayer_times_service.dart';

enum PrayerStatus {
  onTime('onTime', 'في الوقت', 'On time'),
  late('late', 'متأخرة', 'Late'),
  qada('qada', 'قضاء', 'Made up'),
  missed('missed', 'فائتة', 'Missed'),
  excused('excused', 'معذور', 'Excused');

  const PrayerStatus(this.id, this.arabicName, this.englishName);

  final String id;
  final String arabicName;
  final String englishName;

  bool get countsAsDone =>
      this == PrayerStatus.onTime ||
      this == PrayerStatus.late ||
      this == PrayerStatus.qada;

  static PrayerStatus byId(String id) => PrayerStatus.values.firstWhere(
    (status) => status.id == id,
    orElse: () => PrayerStatus.missed,
  );
}

const obligatoryPrayers = [
  PrayerName.fajr,
  PrayerName.dhuhr,
  PrayerName.asr,
  PrayerName.maghrib,
  PrayerName.isha,
];

class PrayerDay {
  const PrayerDay({
    required this.date,
    this.statuses = const {},
    this.excused = false,
  });

  final String date;
  final Map<PrayerName, PrayerStatus> statuses;
  final bool excused;

  PrayerStatus? statusOf(PrayerName prayer) => statuses[prayer];

  int get count => obligatoryPrayers
      .where((prayer) => statuses[prayer]?.countsAsDone ?? false)
      .length;

  bool get complete => count == 5;

  bool get qualifies => complete || excused;
}

class PrayerStreak {
  const PrayerStreak({
    required this.current,
    required this.best,
    required this.todayComplete,
    required this.todayExcused,
    required this.todayCount,
  });

  final int current;
  final int best;
  final bool todayComplete;
  final bool todayExcused;
  final int todayCount;
}

PrayerStreak computePrayerStreak(Iterable<PrayerDay> days, String todayKey) {
  final byDate = {for (final day in days) day.date: day};

  bool qualifies(String key) => byDate[key]?.qualifies ?? false;

  String shift(String key, int days) {
    final date = DateTime.parse('${key}T00:00:00');
    return localDateKey(DateTime(date.year, date.month, date.day + days));
  }

  var cursor = qualifies(todayKey) ? todayKey : shift(todayKey, -1);
  var current = 0;
  while (qualifies(cursor)) {
    current++;
    cursor = shift(cursor, -1);
  }

  var best = 0;
  var run = 0;
  String? previous;
  final keys = byDate.keys.toList()..sort();
  for (final key in keys) {
    if (byDate[key]!.qualifies) {
      run = previous != null && shift(previous, 1) == key ? run + 1 : 1;
      if (run > best) best = run;
    } else {
      run = 0;
    }
    previous = key;
  }

  final today = byDate[todayKey];
  return PrayerStreak(
    current: current,
    best: best,
    todayComplete: today?.complete ?? false,
    todayExcused: today?.excused ?? false,
    todayCount: today?.count ?? 0,
  );
}
