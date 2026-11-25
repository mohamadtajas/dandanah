// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'سَكينة';

  @override
  String get navDashboard => 'الرئيسية';

  @override
  String get navQuran => 'المصحف';

  @override
  String get navAdhkar => 'الأذكار';

  @override
  String get navAudio => 'الصوت';

  @override
  String get settings => 'الإعدادات';

  @override
  String get comingSoon => 'قريبًا';

  @override
  String get dashboardWelcome => 'طمأنينة القلب';

  @override
  String get dashboardSubtitle =>
      'القرآن، ومواقيت الصلاة، والأذكار، والصوت — دون إنترنت.';

  @override
  String get prayerCardTitle => 'الصلاة والقبلة';

  @override
  String get prayerCardBody =>
      'مواقيت محسوبة على جهازك، وسجل صلوات، وسلسلة استمرارية.';

  @override
  String get quranCardTitle => 'المصحف';

  @override
  String get quranCardBody =>
      'النص العثماني كاملًا، قراءة بالسور أو الأجزاء، مع العلامات وآخر موضع.';

  @override
  String get adhkarCardTitle => 'الأذكار';

  @override
  String get adhkarCardBody =>
      'حصن المسلم كاملًا مع العدادات والتقدم وسلسلة يومية.';

  @override
  String get audioCardTitle => 'التلاوات والأناشيد';

  @override
  String get audioCardBody =>
      'تشغيل في الخلفية، قوائم تشغيل، وتنزيلات للاستماع دون إنترنت.';

  @override
  String get quranPageTitle => 'المصحف';

  @override
  String get adhkarPageTitle => 'الأذكار';

  @override
  String get audioPageTitle => 'الصوت';

  @override
  String get settingsPageTitle => 'الإعدادات';

  @override
  String get settingsOverview => 'نظرة عامة';

  @override
  String get settingsPlaceholder =>
      'ستصل إعدادات الموقع والتذكير والصوت في المراحل القادمة.';

  @override
  String get dashboardTitle => 'الرئيسية';

  @override
  String get themeSection => 'المظهر';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeLight => 'فاتح';

  @override
  String versionLine(String version) {
    return 'الإصدار $version';
  }
}
