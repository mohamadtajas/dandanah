// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Sakeenah';

  @override
  String get navDashboard => 'Home';

  @override
  String get navQuran => 'Mushaf';

  @override
  String get navAdhkar => 'Adhkar';

  @override
  String get navAudio => 'Audio';

  @override
  String get settings => 'Settings';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get dashboardWelcome => 'Tranquility of the heart';

  @override
  String get dashboardSubtitle =>
      'Quran, prayer times, adhkar and audio — offline.';

  @override
  String get prayerCardTitle => 'Prayer & Qibla';

  @override
  String get prayerCardBody =>
      'Prayer times calculated on your device, a prayer log and a streak.';

  @override
  String get quranCardTitle => 'Mushaf';

  @override
  String get quranCardBody =>
      'The full Uthmani text by surah or juz, with bookmarks and last position.';

  @override
  String get adhkarCardTitle => 'Adhkar';

  @override
  String get adhkarCardBody =>
      'The full Hisn al-Muslim with counters, progress and a daily streak.';

  @override
  String get audioCardTitle => 'Recitations & anasheed';

  @override
  String get audioCardBody =>
      'Background playback, playlists and downloads for offline listening.';

  @override
  String get quranPageTitle => 'Mushaf';

  @override
  String get adhkarPageTitle => 'Adhkar';

  @override
  String get audioPageTitle => 'Audio';

  @override
  String get settingsPageTitle => 'Settings';

  @override
  String get settingsOverview => 'Overview';

  @override
  String get settingsPlaceholder =>
      'Location, reminders and audio settings arrive in later phases.';

  @override
  String get dashboardTitle => 'Home';

  @override
  String get themeSection => 'Appearance';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String versionLine(String version) {
    return 'Version $version';
  }

  @override
  String get startupErrorTitle => 'Sakeenah could not start';

  @override
  String get startupErrorBody =>
      'The local data could not be prepared. Try again, and reinstall the app if the problem persists.';

  @override
  String get retry => 'Try again';

  @override
  String get prayerNext => 'Next prayer';

  @override
  String prayerTimeRemaining(String time) {
    return '$time remaining';
  }

  @override
  String get prayerToday => 'Today\'s times';

  @override
  String get prayerStreak => 'Prayer streak';

  @override
  String get prayerBestStreak => 'Best streak';

  @override
  String get prayerExcusedDay => 'Excused day';

  @override
  String get prayerMarkOnTime => 'On time';

  @override
  String get prayerMarkLate => 'Late';

  @override
  String get prayerMarkQada => 'Made up';

  @override
  String get prayerMarkMissed => 'Missed';

  @override
  String get prayerClear => 'Clear';

  @override
  String get prayerExcuse => 'Mark today excused';

  @override
  String get prayerUnExcuse => 'Remove excused day';

  @override
  String get prayerLocationMissing =>
      'Your location is not set; showing the default Makkah coordinates.';

  @override
  String get prayerOpenSettings => 'Set location';

  @override
  String get qiblaTitle => 'Qibla';

  @override
  String qiblaBearing(String degrees) {
    return 'Qibla $degrees°';
  }

  @override
  String get hijriTitle => 'Hijri date';

  @override
  String get prayerSettings => 'Prayer settings';

  @override
  String get prayerLocationSection => 'Location and times';

  @override
  String get prayerCalculationSection => 'Calculation';

  @override
  String get cityLabel => 'City';

  @override
  String get customLocation => 'Custom location';

  @override
  String get latitudeLabel => 'Latitude';

  @override
  String get longitudeLabel => 'Longitude';

  @override
  String get timezoneLabel => 'Timezone';

  @override
  String get methodLabel => 'Calculation method';

  @override
  String get madhabLabel => 'Asr madhab';

  @override
  String get shafi => 'Shafi';

  @override
  String get hanafi => 'Hanafi';

  @override
  String get highLatitudeLabel => 'High latitude rule';

  @override
  String get hijriAdjustmentLabel => 'Hijri adjustment';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get save => 'Save';

  @override
  String get prayerInvalidCoordinates => 'Enter valid coordinates.';

  @override
  String get prayerTimesUnavailable =>
      'Prayer times are not available for this location and date. Try another location or a lower latitude.';

  @override
  String get settingsSaveFailed => 'Could not save settings. Try again.';

  @override
  String get adhkarToday => 'Today\'s adhkar';

  @override
  String get adhkarMorning => 'Morning';

  @override
  String get adhkarEvening => 'Evening';

  @override
  String get adhkarFeatured => 'Featured adhkar';

  @override
  String get adhkarAll => 'All adhkar';

  @override
  String get adhkarSearch => 'Search adhkar';

  @override
  String get adhkarNoResults => 'No results';

  @override
  String adhkarRemaining(String count) {
    return '$count remaining';
  }

  @override
  String get adhkarDone => 'Done';

  @override
  String get adhkarTapToCount => 'Tap to count';

  @override
  String get adhkarCompletedTitle => 'Adhkar completed';

  @override
  String get adhkarCompletedBody => 'Added to today\'s streak.';

  @override
  String get adhkarResetItem => 'Reset this dhikr';

  @override
  String adhkarCategoryProgress(int completed, int total) {
    return 'Progress: $completed of $total';
  }

  @override
  String get adhkarClose => 'Close';

  @override
  String get adhkarResetCategory => 'Reset section';

  @override
  String get adhkarCompletedBodyGeneric => 'This adhkar section is complete.';

  @override
  String adhkarStreakCount(int count) {
    return 'Adhkar streak: $count';
  }

  @override
  String adhkarBestCount(int count) {
    return 'Best streak: $count';
  }

  @override
  String get adhkarPrevious => 'Previous';

  @override
  String get adhkarNext => 'Next';

  @override
  String get adhkarLoadError => 'Could not load adhkar.';

  @override
  String get adhkarActionError => 'Could not save progress.';

  @override
  String get adhkarClearSearch => 'Clear search';

  @override
  String get adhkarGoHome => 'Home';

  @override
  String prayerTodayProgress(int count) {
    return 'Today: $count / 5';
  }
}
