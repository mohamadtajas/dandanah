/// Offline prayer-time calculation methods supported on desktop and mobile.
enum PrayerMethod {
  ummAlQura('ummAlQura', 'أم القرى', 'Umm al-Qura'),
  muslimWorldLeague(
    'muslimWorldLeague',
    'رابطة العالم الإسلامي',
    'Muslim World League',
  ),
  egyptian(
    'egyptian',
    'الهيئة المصرية العامة للمساحة',
    'Egyptian General Authority',
  ),
  karachi(
    'karachi',
    'جامعة العلوم الإسلامية بكراتشي',
    'University of Islamic Sciences, Karachi',
  ),
  dubai('dubai', 'دبي', 'Dubai'),
  moonsightingCommittee(
    'moonsightingCommittee',
    'لجنة رؤية الهلال',
    'Moonsighting Committee',
  ),
  northAmerica(
    'northAmerica',
    'أمريكا الشمالية (ISNA)',
    'North America (ISNA)',
  ),
  kuwait('kuwait', 'الكويت', 'Kuwait'),
  qatar('qatar', 'قطر', 'Qatar'),
  singapore('singapore', 'سنغافورة', 'Singapore'),
  tehran('tehran', 'طهران', 'Tehran'),
  turkey('turkey', 'تركيا (ديانت)', 'Turkey (Diyanet)');

  const PrayerMethod(this.id, this.arabicName, this.englishName);

  final String id;
  final String arabicName;
  final String englishName;

  static PrayerMethod byId(String id) => PrayerMethod.values.firstWhere(
    (method) => method.id == id,
    orElse: () => PrayerMethod.ummAlQura,
  );
}

/// Asr shadow rule. Shafi (and the other three schools) use shadow length 1;
/// Hanafi uses 2.
enum PrayerMadhab { shafi, hanafi }

/// How Fajr and Isha are bounded when the sun misses the twilight angle.
enum PrayerHighLatitude {
  recommended('recommended', 'موصى به', 'Recommended'),
  middleOfTheNight('middleOfTheNight', 'منتصف الليل', 'Middle of the night'),
  seventhOfTheNight('seventhOfTheNight', 'سُبع الليل', 'Seventh of the night'),
  twilightAngle('twilightAngle', 'زاوية الشفق', 'Twilight angle');

  const PrayerHighLatitude(this.id, this.arabicName, this.englishName);

  final String id;
  final String arabicName;
  final String englishName;

  /// Desktop parity: seventh of the night above 48 degrees, middle otherwise.
  PrayerHighLatitude effectiveFor(double latitude) {
    if (this != PrayerHighLatitude.recommended) return this;
    return latitude.abs() >= 48
        ? PrayerHighLatitude.seventhOfTheNight
        : PrayerHighLatitude.middleOfTheNight;
  }

  static PrayerHighLatitude byId(String id) => PrayerHighLatitude.values
      .firstWhere((rule) => rule.id == id, orElse: () => recommended);
}
