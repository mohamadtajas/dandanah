import '../db/app_database.dart';
import '../settings_store.dart';
import '../worship/prayer_settings.dart';

const locationOnboardingSeenKey = 'location.onboarding_seen';

/// True when the user has never chosen a location and has not dismissed the
/// first-run prompt before.
Future<bool> shouldShowLocationOnboarding(
  AppDatabase db,
  PrayerSettings settings,
) async {
  if (settings.configured) return false;
  return await SettingsStore.read(db, locationOnboardingSeenKey) != '1';
}

Future<void> markLocationOnboardingSeen(AppDatabase db) =>
    SettingsStore.write(db, locationOnboardingSeenKey, '1');
