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
