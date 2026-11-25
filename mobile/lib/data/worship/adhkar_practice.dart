import '../models/local_date.dart';

class AdhkarDay {
  const AdhkarDay({
    required this.date,
    this.morning = false,
    this.evening = false,
  });

  final String date;
  final bool morning;
  final bool evening;

  bool get qualifies => morning || evening;
}

class AdhkarStreak {
  const AdhkarStreak({
    required this.current,
    required this.best,
    required this.todayMorning,
    required this.todayEvening,
  });

  final int current;
  final int best;
  final bool todayMorning;
  final bool todayEvening;

  bool get todayComplete => todayMorning || todayEvening;
}

class AdhkarTapResult {
  const AdhkarTapResult({
    required this.itemCompleted,
    required this.categoryCompleted,
  });

  final bool itemCompleted;
  final bool categoryCompleted;
}

class AdhkarCategoryProgress {
  const AdhkarCategoryProgress({
    required this.completedItems,
    required this.totalItems,
    required this.completedRepeats,
    required this.totalRepeats,
  });

  final int completedItems;
  final int totalItems;
  final int completedRepeats;
  final int totalRepeats;

  bool get complete => totalItems > 0 && completedItems == totalItems;
  double get fraction =>
      totalRepeats == 0 ? 0 : completedRepeats / totalRepeats;
}

AdhkarStreak computeAdhkarStreak(Iterable<AdhkarDay> days, String todayKey) {
  final byDate = {for (final day in days) day.date: day};

  bool qualifies(String key) => byDate[key]?.qualifies ?? false;

  String shift(String key, int amount) {
    final date = DateTime.parse('${key}T00:00:00');
    return localDateKey(DateTime(date.year, date.month, date.day + amount));
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
  return AdhkarStreak(
    current: current,
    best: best,
    todayMorning: today?.morning ?? false,
    todayEvening: today?.evening ?? false,
  );
}
