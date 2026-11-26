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

  @override
  String get adhkarClearSearch => 'مسح البحث';

  @override
  String get adhkarGoHome => 'الرئيسية';

  @override
  String prayerTodayProgress(int count) {
    return 'اليوم: $count / 5';
  }

  @override
  String get locationTitle => 'تحديد الموقع';

  @override
  String get locationBody =>
      'نستخدم موقعك على هذا الجهاز فقط لحساب مواقيت الصلاة والقبلة. لا يُرسل إلى أي خادم.';

  @override
  String get locationUse => 'استخدم موقعي';

  @override
  String get locationChooseCity => 'اختيار مدينة';

  @override
  String get locationDenied =>
      'لم يتم السماح بالوصول إلى الموقع. يمكنك اختيار مدينة يدويًا.';

  @override
  String get locationDeniedForever =>
      'تم رفض إذن الموقع. افتح إعدادات التطبيق للسماح به.';

  @override
  String get locationUnavailable => 'تعذر تحديد موقعك الآن. حاول مرة أخرى.';

  @override
  String get locationOpenSettings => 'فتح إعدادات التطبيق';

  @override
  String get locationFetching => 'جارٍ تحديد موقعك…';

  @override
  String get locationSaved => 'تم استخدام موقعك الحالي.';

  @override
  String get locationSourceDevice => 'موقع الجهاز';

  @override
  String get settingsLocationUse => 'استخدم موقعي الحالي';

  @override
  String get quranTabSurahs => 'السور';

  @override
  String get quranTabJuz => 'الأجزاء';

  @override
  String get quranTabBookmarks => 'العلامات';

  @override
  String get quranTabResume => 'المتابعة';

  @override
  String get quranSearch => 'ابحث عن سورة';

  @override
  String get quranSearchEmpty => 'لا توجد سور مطابقة';

  @override
  String get quranNoBookmarks => 'لا توجد علامات بعد';

  @override
  String get quranNoResume => 'لم تبدأ القراءة بعد';

  @override
  String get quranDailyAyah => 'آية اليوم';

  @override
  String quranJuz(int number) {
    return 'الجزء $number';
  }

  @override
  String quranAyahCount(int count) {
    return '$count آية';
  }

  @override
  String get quranMakkah => 'مكية';

  @override
  String get quranMadinah => 'مدنية';

  @override
  String get quranContinue => 'متابعة القراءة';

  @override
  String quranResumeAt(String surah, int ayah) {
    return '$surah · الآية $ayah';
  }

  @override
  String quranBookmarkAt(String surah, int ayah) {
    return '$surah · الآية $ayah';
  }

  @override
  String get quranRemoveBookmark => 'إزالة العلامة';

  @override
  String get quranAddBookmark => 'إضافة علامة';

  @override
  String get quranSajda => 'سجدة';

  @override
  String get quranReaderError => 'تعذر تحميل المصحف.';

  @override
  String get quranFontDecrease => 'تصغير الخط';

  @override
  String get quranFontIncrease => 'تكبير الخط';

  @override
  String get quranRead => 'قراءة';

  @override
  String quranJuzStart(String surah, int ayah) {
    return 'يبدأ من $surah · $ayah';
  }

  @override
  String quranAyahLabel(int number) {
    return 'الآية $number';
  }

  @override
  String get audioChooseReciter => 'اختر القارئ';

  @override
  String get audioSearchSurah => 'ابحث عن سورة';

  @override
  String get audioPlaySurah => 'تشغيل السورة';

  @override
  String get audioNowPlaying => 'قيد التشغيل';

  @override
  String get audioPlay => 'تشغيل';

  @override
  String get audioPause => 'إيقاف مؤقت';

  @override
  String get audioNext => 'التالي';

  @override
  String get audioPrevious => 'السابق';

  @override
  String get audioSpeed => 'السرعة';

  @override
  String get audioRepeat => 'التكرار';

  @override
  String get audioRepeatOff => 'بدون تكرار';

  @override
  String get audioRepeatOne => 'تكرار الآية';

  @override
  String get audioRepeatAll => 'تكرار السورة';

  @override
  String get audioQueueEmpty => 'لم يتم تشغيل أي تلاوة';

  @override
  String get audioStop => 'إيقاف';

  @override
  String audioAyahLabel(int number) {
    return 'الآية $number';
  }

  @override
  String get audioReciterLabel => 'القارئ';

  @override
  String get audioStopPlayback => 'إيقاف التلاوة';

  @override
  String get adhanSection => 'الأذان والتنبيهات';

  @override
  String get adhanEnable => 'تفعيل إشعارات الصلاة';

  @override
  String get adhanPreAlert => 'التنبيه المسبق';

  @override
  String get adhanNoPreAlert => 'بدون تنبيه مسبق';

  @override
  String adhanMinutes(int minutes) {
    return 'قبلها بـ $minutes دقيقة';
  }

  @override
  String get adhanSound => 'صوت الأذان';

  @override
  String get adhanTest => 'إرسال إشعار تجريبي';

  @override
  String get adhanTestSent => 'تم إرسال إشعار تجريبي.';

  @override
  String get adhanPermissionDenied => 'لم يتم منح إذن الإشعارات.';

  @override
  String get adhanSaveFailed => 'تعذر حفظ إعدادات الأذان.';

  @override
  String get adhanHint =>
      'تُجدول التنبيهات محليًا لمدة أسبوعين وتُجدد عند فتح التطبيق.';

  @override
  String get audioLoadError => 'تعذر تحميل قائمة السور.';

  @override
  String get audioPlaybackError =>
      'تعذر تشغيل التلاوة. تحقق من اتصالك بالإنترنت.';

  @override
  String get adhanBatteryTitle => 'لضمان وصول الأذان في وقته';

  @override
  String get adhanBatteryHint =>
      'اسمح للتطبيق بالعمل في الخلفية وأوقف تحسين البطارية له من إعدادات النظام.';
}
