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
  northAmerica('northAmerica', 'أمريكا الشمالية (ISNA)', 'North America (ISNA)'),
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
