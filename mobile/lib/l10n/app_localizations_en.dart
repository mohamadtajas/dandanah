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
}
