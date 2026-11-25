import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/worship/hijri_date.dart';
import 'package:sakeenah_mobile/data/worship/prayer_method.dart';
import 'package:sakeenah_mobile/data/worship/prayer_times_service.dart';
import 'package:sakeenah_mobile/data/worship/qibla.dart';

void main() {
  group('prayer methods', () {
    test('twelve offline methods match the desktop catalogue', () {
      expect(PrayerMethod.values, hasLength(12));
      expect(PrayerMethod.values.map((method) => method.id).toSet(), {
        'ummAlQura',
        'muslimWorldLeague',
        'egyptian',
        'karachi',
        'dubai',
        'moonsightingCommittee',
        'northAmerica',
        'kuwait',
        'qatar',
        'singapore',
        'tehran',
        'turkey',
      });
      expect(PrayerMethod.values.every((m) => m.arabicName.isNotEmpty), isTrue);
      expect(
        PrayerMethod.values.every((m) => m.englishName.isNotEmpty),
        isTrue,
      );
      expect(PrayerMethod.byId('dubai'), PrayerMethod.dubai);
      expect(PrayerMethod.byId('unknown'), PrayerMethod.ummAlQura);
    });

    test('Makkah times are ordered and fall in the expected hours', () {
      final times = PrayerTimesService().calculate(
        date: DateTime(2026, 11, 26),
        latitude: 21.4225,
        longitude: 39.8262,
        method: PrayerMethod.ummAlQura,
        utcOffset: const Duration(hours: 3),
      );

      final order = [
        PrayerName.fajr,
        PrayerName.sunrise,
        PrayerName.dhuhr,
        PrayerName.asr,
        PrayerName.maghrib,
        PrayerName.isha,
      ];
      for (var i = 1; i < order.length; i++) {
        expect(
          times[order[i]].isAfter(times[order[i - 1]]),
          isTrue,
          reason: '${order[i].name} should follow ${order[i - 1].name}',
        );
      }

      expect(times[PrayerName.fajr].hour, 5);
      expect(times[PrayerName.dhuhr].hour, 12);
      expect(times[PrayerName.maghrib].hour, 17);
      expect(times[PrayerName.isha].hour, 19);
    });

    test('high-latitude summer still yields ordered times', () {
      final times = PrayerTimesService().calculate(
        date: DateTime(2026, 6, 21),
        latitude: 59.9139,
        longitude: 10.7522,
        method: PrayerMethod.muslimWorldLeague,
        utcOffset: const Duration(hours: 2),
      );
      expect(
        times[PrayerName.fajr].isBefore(times[PrayerName.sunrise]),
        isTrue,
      );
      expect(times[PrayerName.isha].isAfter(times[PrayerName.maghrib]), isTrue);
      expect(times[PrayerName.fajr].day, 21);
    });

    test('returns local wall-clock times on the requested date', () {
      final cases = [
        (
          name: 'Makkah',
          latitude: 21.4225,
          longitude: 39.8262,
          offset: const Duration(hours: 3),
        ),
        (
          name: 'Oslo',
          latitude: 59.9139,
          longitude: 10.7522,
          offset: const Duration(hours: 2),
        ),
        (
          name: 'Auckland',
          latitude: -36.8485,
          longitude: 174.7633,
          offset: const Duration(hours: 13),
        ),
        (
          name: 'Apia',
          latitude: -13.8333,
          longitude: -171.7667,
          offset: const Duration(hours: 13),
        ),
        (
          name: 'Kiritimati',
          latitude: 1.8721,
          longitude: -157.4278,
          offset: const Duration(hours: 14),
        ),
      ];

      for (final testCase in cases) {
        final times = PrayerTimesService().calculate(
          date: DateTime(2026, 11, 26),
          latitude: testCase.latitude,
          longitude: testCase.longitude,
          method: PrayerMethod.muslimWorldLeague,
          utcOffset: testCase.offset,
        );
        for (final entry in times.all.entries) {
          expect(entry.value.isUtc, isFalse, reason: testCase.name);
          expect(
            (entry.value.year, entry.value.month, entry.value.day),
            (2026, 11, 26),
            reason: '${testCase.name} ${entry.key.name}',
          );
        }
      }
    });
  });

  group('hijri date', () {
    test('documented Umm al-Qura conversion', () {
      final date = HijriDate.fromGregorian(DateTime(2018, 11, 12));
      expect((date.year, date.month, date.day), (1440, 3, 4));
      expect(date.monthNameAr, 'ربيع الأول');
      expect(date.formatAr(), '٤ ربيع الأول ١٤٤٠');
    });

    test('adjustment moves the Hijri day and wraps at month end', () {
      final base = HijriDate.fromGregorian(DateTime(2026, 11, 26));
      final plus = HijriDate.fromGregorian(
        DateTime(2026, 11, 26),
        adjustment: 1,
      );
      final minus = HijriDate.fromGregorian(
        DateTime(2026, 11, 26),
        adjustment: -1,
      );

      expect(plus.toGregorian().difference(DateTime(2026, 11, 26)).inDays, 1);
      expect(minus.toGregorian().difference(DateTime(2026, 11, 26)).inDays, -1);
      expect(plus.day, isNot(base.day));
      expect(minus.day, isNot(base.day));
      expect(base.year, greaterThan(1400));
      expect(base.monthNameAr, isNotEmpty);
    });
  });

  group('qibla', () {
    test('known bearings point at the Kaaba', () {
      expect(qiblaBearing(21.4225, 39.8262), closeTo(0, 0.5));
      expect(qiblaBearing(30.0444, 31.2357), closeTo(136.1, 1.0));
      expect(qiblaBearing(40.7128, -74.0060), closeTo(58.5, 1.0));
      expect(qiblaBearing(-6.2088, 106.8456), closeTo(295.2, 1.0));
      expect(qiblaBearing(51.5074, -0.1278), closeTo(118.9, 1.0));
    });

    test('bearing is always in the compass range', () {
      for (final point in [
        (0.0, 0.0),
        (90.0, 180.0),
        (-90.0, -180.0),
        (21.4, 39.8),
      ]) {
        final bearing = qiblaBearing(point.$1, point.$2);
        expect(bearing, greaterThanOrEqualTo(0));
        expect(bearing, lessThan(360));
      }
    });
  });
}
