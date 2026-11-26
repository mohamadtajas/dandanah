import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'سَكينة'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get navDashboard;

  /// No description provided for @navQuran.
  ///
  /// In ar, this message translates to:
  /// **'المصحف'**
  String get navQuran;

  /// No description provided for @navAdhkar.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار'**
  String get navAdhkar;

  /// No description provided for @navAudio.
  ///
  /// In ar, this message translates to:
  /// **'الصوت'**
  String get navAudio;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @comingSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريبًا'**
  String get comingSoon;

  /// No description provided for @dashboardWelcome.
  ///
  /// In ar, this message translates to:
  /// **'طمأنينة القلب'**
  String get dashboardWelcome;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'القرآن، ومواقيت الصلاة، والأذكار، والصوت — دون إنترنت.'**
  String get dashboardSubtitle;

  /// No description provided for @prayerCardTitle.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة والقبلة'**
  String get prayerCardTitle;

  /// No description provided for @prayerCardBody.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت محسوبة على جهازك، وسجل صلوات، وسلسلة استمرارية.'**
  String get prayerCardBody;

  /// No description provided for @quranCardTitle.
  ///
  /// In ar, this message translates to:
  /// **'المصحف'**
  String get quranCardTitle;

  /// No description provided for @quranCardBody.
  ///
  /// In ar, this message translates to:
  /// **'النص العثماني كاملًا، قراءة بالسور أو الأجزاء، مع العلامات وآخر موضع.'**
  String get quranCardBody;

  /// No description provided for @adhkarCardTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار'**
  String get adhkarCardTitle;

  /// No description provided for @adhkarCardBody.
  ///
  /// In ar, this message translates to:
  /// **'حصن المسلم كاملًا مع العدادات والتقدم وسلسلة يومية.'**
  String get adhkarCardBody;

  /// No description provided for @audioCardTitle.
  ///
  /// In ar, this message translates to:
  /// **'التلاوات والأناشيد'**
  String get audioCardTitle;

  /// No description provided for @audioCardBody.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل في الخلفية، قوائم تشغيل، وتنزيلات للاستماع دون إنترنت.'**
  String get audioCardBody;

  /// No description provided for @quranPageTitle.
  ///
  /// In ar, this message translates to:
  /// **'المصحف'**
  String get quranPageTitle;

  /// No description provided for @adhkarPageTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار'**
  String get adhkarPageTitle;

  /// No description provided for @audioPageTitle.
  ///
  /// In ar, this message translates to:
  /// **'الصوت'**
  String get audioPageTitle;

  /// No description provided for @settingsPageTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsPageTitle;

  /// No description provided for @settingsOverview.
  ///
  /// In ar, this message translates to:
  /// **'نظرة عامة'**
  String get settingsOverview;

  /// No description provided for @settingsPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'ستصل إعدادات الموقع والتذكير والصوت في المراحل القادمة.'**
  String get settingsPlaceholder;

  /// No description provided for @dashboardTitle.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get dashboardTitle;

  /// No description provided for @themeSection.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get themeSection;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get themeLight;

  /// No description provided for @versionLine.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {version}'**
  String versionLine(String version);

  /// No description provided for @startupErrorTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر بدء سَكينة'**
  String get startupErrorTitle;

  /// No description provided for @startupErrorBody.
  ///
  /// In ar, this message translates to:
  /// **'لم نتمكن من تجهيز البيانات المحلية. أعد المحاولة، وإن استمرت المشكلة فأعد تثبيت التطبيق.'**
  String get startupErrorBody;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @prayerNext.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة القادمة'**
  String get prayerNext;

  /// No description provided for @prayerTimeRemaining.
  ///
  /// In ar, this message translates to:
  /// **'متبقي {time}'**
  String prayerTimeRemaining(String time);

  /// No description provided for @prayerToday.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت اليوم'**
  String get prayerToday;

  /// No description provided for @prayerStreak.
  ///
  /// In ar, this message translates to:
  /// **'سلسلة الصلوات'**
  String get prayerStreak;

  /// No description provided for @prayerBestStreak.
  ///
  /// In ar, this message translates to:
  /// **'أفضل سلسلة'**
  String get prayerBestStreak;

  /// No description provided for @prayerExcusedDay.
  ///
  /// In ar, this message translates to:
  /// **'يوم معذور'**
  String get prayerExcusedDay;

  /// No description provided for @prayerMarkOnTime.
  ///
  /// In ar, this message translates to:
  /// **'في الوقت'**
  String get prayerMarkOnTime;

  /// No description provided for @prayerMarkLate.
  ///
  /// In ar, this message translates to:
  /// **'متأخرة'**
  String get prayerMarkLate;

  /// No description provided for @prayerMarkQada.
  ///
  /// In ar, this message translates to:
  /// **'قضاء'**
  String get prayerMarkQada;

  /// No description provided for @prayerMarkMissed.
  ///
  /// In ar, this message translates to:
  /// **'فائتة'**
  String get prayerMarkMissed;

  /// No description provided for @prayerClear.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get prayerClear;

  /// No description provided for @prayerExcuse.
  ///
  /// In ar, this message translates to:
  /// **'احتساب اليوم معذورًا'**
  String get prayerExcuse;

  /// No description provided for @prayerUnExcuse.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء عذر اليوم'**
  String get prayerUnExcuse;

  /// No description provided for @prayerLocationMissing.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم ضبط موقعك بعد؛ المواقيت المعروضة لإحداثيات مكة الافتراضية.'**
  String get prayerLocationMissing;

  /// No description provided for @prayerOpenSettings.
  ///
  /// In ar, this message translates to:
  /// **'ضبط الموقع'**
  String get prayerOpenSettings;

  /// No description provided for @qiblaTitle.
  ///
  /// In ar, this message translates to:
  /// **'القبلة'**
  String get qiblaTitle;

  /// No description provided for @qiblaBearing.
  ///
  /// In ar, this message translates to:
  /// **'اتجاه القبلة {degrees}°'**
  String qiblaBearing(String degrees);

  /// No description provided for @hijriTitle.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ الهجري'**
  String get hijriTitle;

  /// No description provided for @prayerSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الصلاة'**
  String get prayerSettings;

  /// No description provided for @prayerLocationSection.
  ///
  /// In ar, this message translates to:
  /// **'الموقع والمواقيت'**
  String get prayerLocationSection;

  /// No description provided for @prayerCalculationSection.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الحساب'**
  String get prayerCalculationSection;

  /// No description provided for @cityLabel.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get cityLabel;

  /// No description provided for @customLocation.
  ///
  /// In ar, this message translates to:
  /// **'موقع مخصص'**
  String get customLocation;

  /// No description provided for @latitudeLabel.
  ///
  /// In ar, this message translates to:
  /// **'خط العرض'**
  String get latitudeLabel;

  /// No description provided for @longitudeLabel.
  ///
  /// In ar, this message translates to:
  /// **'خط الطول'**
  String get longitudeLabel;

  /// No description provided for @timezoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'المنطقة الزمنية'**
  String get timezoneLabel;

  /// No description provided for @methodLabel.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الحساب'**
  String get methodLabel;

  /// No description provided for @madhabLabel.
  ///
  /// In ar, this message translates to:
  /// **'مذهب العصر'**
  String get madhabLabel;

  /// No description provided for @shafi.
  ///
  /// In ar, this message translates to:
  /// **'شافعي'**
  String get shafi;

  /// No description provided for @hanafi.
  ///
  /// In ar, this message translates to:
  /// **'حنفي'**
  String get hanafi;

  /// No description provided for @highLatitudeLabel.
  ///
  /// In ar, this message translates to:
  /// **'خطوط العرض العالية'**
  String get highLatitudeLabel;

  /// No description provided for @hijriAdjustmentLabel.
  ///
  /// In ar, this message translates to:
  /// **'تعديل التاريخ الهجري'**
  String get hijriAdjustmentLabel;

  /// No description provided for @settingsSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الإعدادات'**
  String get settingsSaved;

  /// No description provided for @sunrise.
  ///
  /// In ar, this message translates to:
  /// **'الشروق'**
  String get sunrise;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @prayerInvalidCoordinates.
  ///
  /// In ar, this message translates to:
  /// **'أدخل إحداثيات صحيحة.'**
  String get prayerInvalidCoordinates;

  /// No description provided for @prayerTimesUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حساب مواقيت الصلاة لهذا الموقع والتاريخ. جرّب موقعًا آخر أو خط عرض أقل.'**
  String get prayerTimesUnavailable;

  /// No description provided for @settingsSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذّر حفظ الإعدادات. حاول مرة أخرى.'**
  String get settingsSaveFailed;

  /// No description provided for @adhkarToday.
  ///
  /// In ar, this message translates to:
  /// **'أذكار اليوم'**
  String get adhkarToday;

  /// No description provided for @adhkarMorning.
  ///
  /// In ar, this message translates to:
  /// **'الصباح'**
  String get adhkarMorning;

  /// No description provided for @adhkarEvening.
  ///
  /// In ar, this message translates to:
  /// **'المساء'**
  String get adhkarEvening;

  /// No description provided for @adhkarFeatured.
  ///
  /// In ar, this message translates to:
  /// **'أذكار مختارة'**
  String get adhkarFeatured;

  /// No description provided for @adhkarAll.
  ///
  /// In ar, this message translates to:
  /// **'كل الأذكار'**
  String get adhkarAll;

  /// No description provided for @adhkarSearch.
  ///
  /// In ar, this message translates to:
  /// **'ابحث في الأذكار'**
  String get adhkarSearch;

  /// No description provided for @adhkarNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get adhkarNoResults;

  /// No description provided for @adhkarRemaining.
  ///
  /// In ar, this message translates to:
  /// **'متبقي {count}'**
  String adhkarRemaining(String count);

  /// No description provided for @adhkarDone.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get adhkarDone;

  /// No description provided for @adhkarTapToCount.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للعد'**
  String get adhkarTapToCount;

  /// No description provided for @adhkarCompletedTitle.
  ///
  /// In ar, this message translates to:
  /// **'أتممت الأذكار'**
  String get adhkarCompletedTitle;

  /// No description provided for @adhkarCompletedBody.
  ///
  /// In ar, this message translates to:
  /// **'أُضيفت إلى سلسلة اليوم.'**
  String get adhkarCompletedBody;

  /// No description provided for @adhkarResetItem.
  ///
  /// In ar, this message translates to:
  /// **'إعادة هذا الذكر'**
  String get adhkarResetItem;

  /// No description provided for @adhkarCategoryProgress.
  ///
  /// In ar, this message translates to:
  /// **'التقدم: {completed} من {total}'**
  String adhkarCategoryProgress(int completed, int total);

  /// No description provided for @adhkarClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get adhkarClose;

  /// No description provided for @adhkarResetCategory.
  ///
  /// In ar, this message translates to:
  /// **'إعادة القسم'**
  String get adhkarResetCategory;

  /// No description provided for @adhkarCompletedBodyGeneric.
  ///
  /// In ar, this message translates to:
  /// **'تم إكمال أذكار هذا القسم.'**
  String get adhkarCompletedBodyGeneric;

  /// No description provided for @adhkarStreakCount.
  ///
  /// In ar, this message translates to:
  /// **'سلسلة الأذكار: {count}'**
  String adhkarStreakCount(int count);

  /// No description provided for @adhkarBestCount.
  ///
  /// In ar, this message translates to:
  /// **'أفضل سلسلة: {count}'**
  String adhkarBestCount(int count);

  /// No description provided for @adhkarPrevious.
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get adhkarPrevious;

  /// No description provided for @adhkarNext.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get adhkarNext;

  /// No description provided for @adhkarLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل الأذكار.'**
  String get adhkarLoadError;

  /// No description provided for @adhkarActionError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ التقدم.'**
  String get adhkarActionError;

  /// No description provided for @adhkarClearSearch.
  ///
  /// In ar, this message translates to:
  /// **'مسح البحث'**
  String get adhkarClearSearch;

  /// No description provided for @adhkarGoHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get adhkarGoHome;

  /// No description provided for @prayerTodayProgress.
  ///
  /// In ar, this message translates to:
  /// **'اليوم: {count} / 5'**
  String prayerTodayProgress(int count);

  /// No description provided for @locationTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الموقع'**
  String get locationTitle;

  /// No description provided for @locationBody.
  ///
  /// In ar, this message translates to:
  /// **'نستخدم موقعك على هذا الجهاز فقط لحساب مواقيت الصلاة والقبلة. لا يُرسل إلى أي خادم.'**
  String get locationBody;

  /// No description provided for @locationUse.
  ///
  /// In ar, this message translates to:
  /// **'استخدم موقعي'**
  String get locationUse;

  /// No description provided for @locationChooseCity.
  ///
  /// In ar, this message translates to:
  /// **'اختيار مدينة'**
  String get locationChooseCity;

  /// No description provided for @locationDenied.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم السماح بالوصول إلى الموقع. يمكنك اختيار مدينة يدويًا.'**
  String get locationDenied;

  /// No description provided for @locationDeniedForever.
  ///
  /// In ar, this message translates to:
  /// **'تم رفض إذن الموقع. افتح إعدادات التطبيق للسماح به.'**
  String get locationDeniedForever;

  /// No description provided for @locationUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحديد موقعك الآن. حاول مرة أخرى.'**
  String get locationUnavailable;

  /// No description provided for @locationOpenSettings.
  ///
  /// In ar, this message translates to:
  /// **'فتح إعدادات التطبيق'**
  String get locationOpenSettings;

  /// No description provided for @locationFetching.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ تحديد موقعك…'**
  String get locationFetching;

  /// No description provided for @locationSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم استخدام موقعك الحالي.'**
  String get locationSaved;

  /// No description provided for @locationSourceDevice.
  ///
  /// In ar, this message translates to:
  /// **'موقع الجهاز'**
  String get locationSourceDevice;

  /// No description provided for @settingsLocationUse.
  ///
  /// In ar, this message translates to:
  /// **'استخدم موقعي الحالي'**
  String get settingsLocationUse;

  /// No description provided for @quranTabSurahs.
  ///
  /// In ar, this message translates to:
  /// **'السور'**
  String get quranTabSurahs;

  /// No description provided for @quranTabJuz.
  ///
  /// In ar, this message translates to:
  /// **'الأجزاء'**
  String get quranTabJuz;

  /// No description provided for @quranTabBookmarks.
  ///
  /// In ar, this message translates to:
  /// **'العلامات'**
  String get quranTabBookmarks;

  /// No description provided for @quranTabResume.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة'**
  String get quranTabResume;

  /// No description provided for @quranSearch.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن سورة'**
  String get quranSearch;

  /// No description provided for @quranSearchEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد سور مطابقة'**
  String get quranSearchEmpty;

  /// No description provided for @quranNoBookmarks.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد علامات بعد'**
  String get quranNoBookmarks;

  /// No description provided for @quranNoResume.
  ///
  /// In ar, this message translates to:
  /// **'لم تبدأ القراءة بعد'**
  String get quranNoResume;

  /// No description provided for @quranDailyAyah.
  ///
  /// In ar, this message translates to:
  /// **'آية اليوم'**
  String get quranDailyAyah;

  /// No description provided for @quranJuz.
  ///
  /// In ar, this message translates to:
  /// **'الجزء {number}'**
  String quranJuz(int number);

  /// No description provided for @quranAyahCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} آية'**
  String quranAyahCount(int count);

  /// No description provided for @quranMakkah.
  ///
  /// In ar, this message translates to:
  /// **'مكية'**
  String get quranMakkah;

  /// No description provided for @quranMadinah.
  ///
  /// In ar, this message translates to:
  /// **'مدنية'**
  String get quranMadinah;

  /// No description provided for @quranContinue.
  ///
  /// In ar, this message translates to:
  /// **'متابعة القراءة'**
  String get quranContinue;

  /// No description provided for @quranResumeAt.
  ///
  /// In ar, this message translates to:
  /// **'{surah} · الآية {ayah}'**
  String quranResumeAt(String surah, int ayah);

  /// No description provided for @quranBookmarkAt.
  ///
  /// In ar, this message translates to:
  /// **'{surah} · الآية {ayah}'**
  String quranBookmarkAt(String surah, int ayah);

  /// No description provided for @quranRemoveBookmark.
  ///
  /// In ar, this message translates to:
  /// **'إزالة العلامة'**
  String get quranRemoveBookmark;

  /// No description provided for @quranAddBookmark.
  ///
  /// In ar, this message translates to:
  /// **'إضافة علامة'**
  String get quranAddBookmark;

  /// No description provided for @quranSajda.
  ///
  /// In ar, this message translates to:
  /// **'سجدة'**
  String get quranSajda;

  /// No description provided for @quranReaderError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل المصحف.'**
  String get quranReaderError;

  /// No description provided for @quranFontDecrease.
  ///
  /// In ar, this message translates to:
  /// **'تصغير الخط'**
  String get quranFontDecrease;

  /// No description provided for @quranFontIncrease.
  ///
  /// In ar, this message translates to:
  /// **'تكبير الخط'**
  String get quranFontIncrease;

  /// No description provided for @quranRead.
  ///
  /// In ar, this message translates to:
  /// **'قراءة'**
  String get quranRead;

  /// No description provided for @quranJuzStart.
  ///
  /// In ar, this message translates to:
  /// **'يبدأ من {surah} · {ayah}'**
  String quranJuzStart(String surah, int ayah);

  /// No description provided for @quranAyahLabel.
  ///
  /// In ar, this message translates to:
  /// **'الآية {number}'**
  String quranAyahLabel(int number);

  /// No description provided for @audioChooseReciter.
  ///
  /// In ar, this message translates to:
  /// **'اختر القارئ'**
  String get audioChooseReciter;

  /// No description provided for @audioSearchSurah.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن سورة'**
  String get audioSearchSurah;

  /// No description provided for @audioPlaySurah.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل السورة'**
  String get audioPlaySurah;

  /// No description provided for @audioNowPlaying.
  ///
  /// In ar, this message translates to:
  /// **'قيد التشغيل'**
  String get audioNowPlaying;

  /// No description provided for @audioPlay.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل'**
  String get audioPlay;

  /// No description provided for @audioPause.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف مؤقت'**
  String get audioPause;

  /// No description provided for @audioNext.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get audioNext;

  /// No description provided for @audioPrevious.
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get audioPrevious;

  /// No description provided for @audioSpeed.
  ///
  /// In ar, this message translates to:
  /// **'السرعة'**
  String get audioSpeed;

  /// No description provided for @audioRepeat.
  ///
  /// In ar, this message translates to:
  /// **'التكرار'**
  String get audioRepeat;

  /// No description provided for @audioRepeatOff.
  ///
  /// In ar, this message translates to:
  /// **'بدون تكرار'**
  String get audioRepeatOff;

  /// No description provided for @audioRepeatOne.
  ///
  /// In ar, this message translates to:
  /// **'تكرار الآية'**
  String get audioRepeatOne;

  /// No description provided for @audioRepeatAll.
  ///
  /// In ar, this message translates to:
  /// **'تكرار السورة'**
  String get audioRepeatAll;

  /// No description provided for @audioQueueEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم تشغيل أي تلاوة'**
  String get audioQueueEmpty;

  /// No description provided for @audioStop.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get audioStop;

  /// No description provided for @audioAyahLabel.
  ///
  /// In ar, this message translates to:
  /// **'الآية {number}'**
  String audioAyahLabel(int number);

  /// No description provided for @audioReciterLabel.
  ///
  /// In ar, this message translates to:
  /// **'القارئ'**
  String get audioReciterLabel;

  /// No description provided for @audioStopPlayback.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف التلاوة'**
  String get audioStopPlayback;

  /// No description provided for @adhanSection.
  ///
  /// In ar, this message translates to:
  /// **'الأذان والتنبيهات'**
  String get adhanSection;

  /// No description provided for @adhanEnable.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل إشعارات الصلاة'**
  String get adhanEnable;

  /// No description provided for @adhanPreAlert.
  ///
  /// In ar, this message translates to:
  /// **'التنبيه المسبق'**
  String get adhanPreAlert;

  /// No description provided for @adhanNoPreAlert.
  ///
  /// In ar, this message translates to:
  /// **'بدون تنبيه مسبق'**
  String get adhanNoPreAlert;

  /// No description provided for @adhanMinutes.
  ///
  /// In ar, this message translates to:
  /// **'قبلها بـ {minutes} دقيقة'**
  String adhanMinutes(int minutes);

  /// No description provided for @adhanSound.
  ///
  /// In ar, this message translates to:
  /// **'صوت الأذان'**
  String get adhanSound;

  /// No description provided for @adhanTest.
  ///
  /// In ar, this message translates to:
  /// **'إرسال إشعار تجريبي'**
  String get adhanTest;

  /// No description provided for @adhanTestSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال إشعار تجريبي.'**
  String get adhanTestSent;

  /// No description provided for @adhanPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم منح إذن الإشعارات.'**
  String get adhanPermissionDenied;

  /// No description provided for @adhanSaveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ إعدادات الأذان.'**
  String get adhanSaveFailed;

  /// No description provided for @adhanHint.
  ///
  /// In ar, this message translates to:
  /// **'تُجدول التنبيهات محليًا لمدة أسبوعين وتُجدد عند فتح التطبيق.'**
  String get adhanHint;

  /// No description provided for @audioLoadError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تحميل قائمة السور.'**
  String get audioLoadError;

  /// No description provided for @audioPlaybackError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تشغيل التلاوة. تحقق من اتصالك بالإنترنت.'**
  String get audioPlaybackError;

  /// No description provided for @adhanBatteryTitle.
  ///
  /// In ar, this message translates to:
  /// **'لضمان وصول الأذان في وقته'**
  String get adhanBatteryTitle;

  /// No description provided for @adhanBatteryHint.
  ///
  /// In ar, this message translates to:
  /// **'اسمح للتطبيق بالعمل في الخلفية وأوقف تحسين البطارية له من إعدادات النظام.'**
  String get adhanBatteryHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
