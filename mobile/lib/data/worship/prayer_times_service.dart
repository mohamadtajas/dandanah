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

/// Calculates prayer times fully offline using the bundled Adhan port.
class PrayerTimesService {
  const PrayerTimesService();

  DailyPrayerTimes calculate({
    required DateTime date,
    required double latitude,
    required double longitude,
    required PrayerMethod method,
    Duration utcOffset = Duration.zero,
    PrayerMadhab madhab = PrayerMadhab.shafi,
  }) {
    final parameters = _calculationMethod(method).getParameters()
      ..madhab = madhab == PrayerMadhab.hanafi
          ? adhan.Madhab.hanafi
          : adhan.Madhab.shafi
      ..highLatitudeRule = adhan.HighLatitudeRule.seventh_of_the_night;

    final times = adhan.PrayerTimes.utcOffset(
      adhan.Coordinates(latitude, longitude),
      adhan.DateComponents(date.year, date.month, date.day),
      parameters,
      utcOffset,
    );

    return DailyPrayerTimes({
      PrayerName.fajr: times.fajr,
      PrayerName.sunrise: times.sunrise,
      PrayerName.dhuhr: times.dhuhr,
      PrayerName.asr: times.asr,
      PrayerName.maghrib: times.maghrib,
      PrayerName.isha: times.isha,
    });
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
