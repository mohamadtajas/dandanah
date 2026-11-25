import 'package:hijri/hijri_calendar.dart';

const _monthNamesAr = [
  'محرم',
  'صفر',
  'ربيع الأول',
  'ربيع الآخر',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوال',
  'ذو القعدة',
  'ذو الحجة',
];

const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

String toArabicDigits(int value) => value
    .toString()
    .split('')
    .map((digit) => _arabicDigits[int.parse(digit)])
    .join();

/// A Hijri calendar date converted with the Umm al-Qura tables bundled by
/// `package:hijri`. The optional adjustment mirrors the desktop setting.
class HijriDate {
  const HijriDate._(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  factory HijriDate.fromGregorian(DateTime date, {int adjustment = 0}) {
    final shifted = DateTime(date.year, date.month, date.day + adjustment);
    final hijri = HijriCalendar.fromDate(shifted);
    return HijriDate._(hijri.hYear, hijri.hMonth, hijri.hDay);
  }

  String get monthNameAr => _monthNamesAr[month - 1];

  DateTime toGregorian() => HijriCalendar().hijriToGregorian(year, month, day);

  String formatAr() =>
      '${toArabicDigits(day)} $monthNameAr ${toArabicDigits(year)}';

  @override
  String toString() => '$day/$month/$year H';
}
