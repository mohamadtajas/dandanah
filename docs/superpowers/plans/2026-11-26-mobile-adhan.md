# Mobile Adhan and Notifications Plan

**Goal:** Schedule per-prayer adhan and pre-alert notifications offline, with persisted preferences and a test notification.

**Architecture:** A pure `PrayerNotificationPlanner` turns `PrayerSettings` + `AdhanPreferences` into dated notification plans. `AdhanSettingsRepository` persists JSON in `SettingsStore`. `PrayerNotificationService` wraps `flutter_local_notifications`; `AdhanScheduler` reconciles the plan on startup/settings change.

**Spec:** `docs/plans/sakeenah-plan.md` (M6).

## Tasks

### Task 1: Preferences and pure planner

Create `lib/data/models/adhan.dart`, `lib/data/worship/prayer_notifications.dart`, `lib/data/repositories/adhan_settings_repository.dart`; tests for defaults, JSON, per-prayer toggles, pre-alerts, disabled prayers and ordering. Expose `PrayerScheduleService.slotsForDate`.

### Task 2: Notification service and scheduler

Wrap `flutter_local_notifications` behind an interface; add Android channels (adhan and silent), exact-alarm permission with an inexact fallback, boot receiver, raw adhan sound; `AdhanScheduler.refresh()` cancels and reschedules 14 days, serialises concurrent refreshes and skips before onboarding. iOS caps the plan at 60 pending notifications and bundles a 29-second `adhan.caf` excerpt. Tests use a fake service.

### Task 3: Settings UI

Add an adhan section: per-prayer switches, a pre-alert offset per prayer, sound, test notification, permission status, OEM battery guidance. Saving prayer settings reschedules; tests use a fake scheduler/service.

### Task 4: Device verification

Build/install, grant notification and exact-alarm permission, send a test notification, schedule a near-future prayer, verify Doze/screen-off on the owner’s phone later. Release builds are checked for `INTERNET` and the adhan resource (AGP 9 shrinks it otherwise). Verify the iOS `adhan.caf` sound on a real iPhone.
