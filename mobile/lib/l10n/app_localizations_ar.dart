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

  @override
  String get startupErrorTitle => 'تعذّر بدء سَكينة';

  @override
  String get startupErrorBody =>
      'لم نتمكن من تجهيز البيانات المحلية. أعد المحاولة، وإن استمرت المشكلة فأعد تثبيت التطبيق.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get prayerNext => 'الصلاة القادمة';

  @override
  String prayerTimeRemaining(String time) {
    return 'متبقي $time';
  }

  @override
  String get prayerToday => 'مواقيت اليوم';

  @override
  String get prayerStreak => 'سلسلة الصلوات';

  @override
  String get prayerBestStreak => 'أفضل سلسلة';

  @override
  String get prayerExcusedDay => 'يوم معذور';

  @override
  String get prayerMarkOnTime => 'في الوقت';

  @override
  String get prayerMarkLate => 'متأخرة';

  @override
  String get prayerMarkQada => 'قضاء';

  @override
  String get prayerMarkMissed => 'فائتة';

  @override
  String get prayerClear => 'مسح';

  @override
  String get prayerExcuse => 'احتساب اليوم معذورًا';

  @override
  String get prayerUnExcuse => 'إلغاء عذر اليوم';

  @override
  String get prayerLocationMissing =>
      'لم يتم ضبط موقعك بعد؛ المواقيت المعروضة لإحداثيات مكة الافتراضية.';

  @override
  String get prayerOpenSettings => 'ضبط الموقع';

  @override
  String get qiblaTitle => 'القبلة';

  @override
  String qiblaBearing(String degrees) {
    return 'اتجاه القبلة $degrees°';
  }

  @override
  String get hijriTitle => 'التاريخ الهجري';

  @override
  String get prayerSettings => 'إعدادات الصلاة';

  @override
  String get prayerLocationSection => 'الموقع والمواقيت';

  @override
  String get prayerCalculationSection => 'طريقة الحساب';

  @override
  String get cityLabel => 'المدينة';

  @override
  String get customLocation => 'موقع مخصص';

  @override
  String get latitudeLabel => 'خط العرض';

  @override
  String get longitudeLabel => 'خط الطول';

  @override
  String get timezoneLabel => 'المنطقة الزمنية';

  @override
  String get methodLabel => 'طريقة الحساب';

  @override
  String get madhabLabel => 'مذهب العصر';

  @override
  String get shafi => 'شافعي';

  @override
  String get hanafi => 'حنفي';

  @override
  String get highLatitudeLabel => 'خطوط العرض العالية';

  @override
  String get hijriAdjustmentLabel => 'تعديل التاريخ الهجري';

  @override
  String get settingsSaved => 'تم حفظ الإعدادات';

  @override
  String get sunrise => 'الشروق';

  @override
  String get save => 'حفظ';

  @override
  String get prayerInvalidCoordinates => 'أدخل إحداثيات صحيحة.';

  @override
  String get prayerTimesUnavailable =>
      'تعذّر حساب مواقيت الصلاة لهذا الموقع والتاريخ. جرّب موقعًا آخر أو خط عرض أقل.';

  @override
  String get settingsSaveFailed => 'تعذّر حفظ الإعدادات. حاول مرة أخرى.';

  @override
  String get adhkarToday => 'أذكار اليوم';

  @override
  String get adhkarMorning => 'الصباح';

  @override
  String get adhkarEvening => 'المساء';

  @override
  String get adhkarFeatured => 'أذكار مختارة';

  @override
  String get adhkarAll => 'كل الأذكار';

  @override
  String get adhkarSearch => 'ابحث في الأذكار';

  @override
  String get adhkarNoResults => 'لا توجد نتائج';

  @override
  String adhkarRemaining(String count) {
    return 'متبقي $count';
  }

  @override
  String get adhkarDone => 'تم';

  @override
  String get adhkarTapToCount => 'اضغط للعد';

  @override
  String get adhkarCompletedTitle => 'أتممت الأذكار';

  @override
  String get adhkarCompletedBody => 'أُضيفت إلى سلسلة اليوم.';

  @override
  String get adhkarResetItem => 'إعادة هذا الذكر';

  @override
  String adhkarCategoryProgress(int completed, int total) {
    return 'التقدم: $completed من $total';
  }

  @override
  String get adhkarClose => 'إغلاق';

  @override
  String get adhkarResetCategory => 'إعادة القسم';

  @override
  String get adhkarCompletedBodyGeneric => 'تم إكمال أذكار هذا القسم.';

  @override
  String adhkarStreakCount(int count) {
    return 'سلسلة الأذكار: $count';
  }

  @override
  String adhkarBestCount(int count) {
    return 'أفضل سلسلة: $count';
  }

  @override
  String get adhkarPrevious => 'السابق';

  @override
  String get adhkarNext => 'التالي';

  @override
  String get adhkarLoadError => 'تعذر تحميل الأذكار.';

  @override
  String get adhkarActionError => 'تعذر حفظ التقدم.';
}
