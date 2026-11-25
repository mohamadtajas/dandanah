import 'package:adhan/adhan.dart' as adhan;

import 'prayer_method.dart';

enum PrayerName {
  fajr('fajr', 'الفجر', 'Fajr'),
  sunrise('sunrise', 'الشروق', 'Sunrise'),
  dhuhr('dhuhr', 'الظهر', 'Dhuhr'),
  asr('asr', 'العصر', 'Asr'),
  maghrib('maghrib', 'المغرب', 'Maghrib'),
  isha('isha', 'العشاء', 'Isha');

  const PrayerName(this.id, this.arabicName, this.englishName);

  final String id;
  final String arabicName;
  final String englishName;
}

class DailyPrayerTimes {
  const DailyPrayerTimes(this._times);

  final Map<PrayerName, DateTime> _times;

  DateTime operator [](PrayerName name) => _times[name]!;

  Map<PrayerName, DateTime> get all => Map.unmodifiable(_times);
}

typedef _Reading = ({int hour, int minute, int second});

/// Calculates prayer times fully offline using the bundled Adhan port.
///
/// Returned values are wall-clock `DateTime`s for the location's UTC offset
/// (`isUtc == false`), always falling on the requested local calendar date.
/// They are display values, not UTC instants.
class PrayerTimesService {
  const PrayerTimesService();

  DailyPrayerTimes calculate({
    required DateTime date,
    required double latitude,
    required double longitude,
    required PrayerMethod method,
    required Duration utcOffset,
    PrayerMadhab madhab = PrayerMadhab.shafi,
  }) {
    final parameters = _calculationMethod(method).getParameters()
      ..madhab = madhab == PrayerMadhab.hanafi
          ? adhan.Madhab.hanafi
          : adhan.Madhab.shafi
      ..highLatitudeRule = adhan.HighLatitudeRule.seventh_of_the_night;

    final raw = adhan.PrayerTimes.utc(
      adhan.Coordinates(latitude, longitude),
      adhan.DateComponents(date.year, date.month, date.day),
      parameters,
    );

    final readings = <PrayerName, _Reading>{
      PrayerName.fajr: _reading(raw.fajr),
      PrayerName.sunrise: _reading(raw.sunrise),
      PrayerName.dhuhr: _reading(raw.dhuhr),
      PrayerName.asr: _reading(raw.asr),
      PrayerName.maghrib: _reading(raw.maghrib),
      PrayerName.isha: _reading(raw.isha),
    };

    final dhuhr = readings[PrayerName.dhuhr]!;
    final dhuhrDate = _resolveDhuhrUtcDate(date, utcOffset, dhuhr);

    final times = <PrayerName, DateTime>{};
    for (final entry in readings.entries) {
      var utcDate = dhuhrDate;
      final reading = entry.value;
      if ((entry.key == PrayerName.fajr || entry.key == PrayerName.sunrise) &&
          _after(reading, dhuhr)) {
        utcDate = dhuhrDate.subtract(const Duration(days: 1));
      }
      if ((entry.key == PrayerName.asr ||
              entry.key == PrayerName.maghrib ||
              entry.key == PrayerName.isha) &&
          _before(reading, dhuhr)) {
        utcDate = dhuhrDate.add(const Duration(days: 1));
      }
      times[entry.key] = _wallClock(utcDate, reading, utcOffset);
    }

    return DailyPrayerTimes(times);
  }

  adhan.CalculationMethod _calculationMethod(PrayerMethod method) {
    return switch (method) {
      PrayerMethod.ummAlQura => adhan.CalculationMethod.umm_al_qura,
      PrayerMethod.muslimWorldLeague =>
        adhan.CalculationMethod.muslim_world_league,
      PrayerMethod.egyptian => adhan.CalculationMethod.egyptian,
      PrayerMethod.karachi => adhan.CalculationMethod.karachi,
      PrayerMethod.dubai => adhan.CalculationMethod.dubai,
      PrayerMethod.moonsightingCommittee =>
        adhan.CalculationMethod.moon_sighting_committee,
      PrayerMethod.northAmerica => adhan.CalculationMethod.north_america,
      PrayerMethod.kuwait => adhan.CalculationMethod.kuwait,
      PrayerMethod.qatar => adhan.CalculationMethod.qatar,
      PrayerMethod.singapore => adhan.CalculationMethod.singapore,
      PrayerMethod.tehran => adhan.CalculationMethod.tehran,
      PrayerMethod.turkey => adhan.CalculationMethod.turkey,
    };
  }
}

_Reading _reading(DateTime time) =>
    (hour: time.hour, minute: time.minute, second: time.second);

int _seconds(_Reading reading) =>
    reading.hour * 3600 + reading.minute * 60 + reading.second;

bool _after(_Reading a, _Reading b) => _seconds(a) > _seconds(b);

bool _before(_Reading a, _Reading b) => _seconds(a) < _seconds(b);

/// `adhan` reduces each reading to a 0-24h clock. Pick the UTC date whose
/// Dhuhr lands nearest local noon on the requested date; this recovers the day
/// for UTC+13/14 and UTC-11/12 zones.
DateTime _resolveDhuhrUtcDate(
  DateTime date,
  Duration utcOffset,
  _Reading dhuhr,
) {
  var best = DateTime.utc(date.year, date.month, date.day);
  var bestScore = 1 << 30;
  for (var shift = -1; shift <= 1; shift++) {
    final candidate = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).add(Duration(days: shift));
    final local = _wallClockParts(candidate, dhuhr, utcOffset);
    final candidateDay = DateTime.utc(local.year, local.month, local.day);
    final requestedDay = DateTime.utc(date.year, date.month, date.day);
    final dayGap = candidateDay.difference(requestedDay).inDays.abs();
    final score = dayGap * 1000 + (local.hour - 12).abs();
    if (score < bestScore) {
      bestScore = score;
      best = candidate;
    }
  }
  return best;
}

DateTime _wallClockParts(
  DateTime utcDate,
  _Reading reading,
  Duration utcOffset,
) {
  return DateTime.utc(
    utcDate.year,
    utcDate.month,
    utcDate.day,
    reading.hour,
    reading.minute,
    reading.second,
  ).add(utcOffset);
}

/// Convert a shifted UTC value into a local wall-clock `DateTime` whose fields
/// match the location's clock, without pretending it is a UTC instant.
DateTime _wallClock(DateTime utcDate, _Reading reading, Duration utcOffset) {
  final shifted = _wallClockParts(utcDate, reading, utcOffset);
  return DateTime(
    shifted.year,
    shifted.month,
    shifted.day,
    shifted.hour,
    shifted.minute,
    shifted.second,
  );
}
