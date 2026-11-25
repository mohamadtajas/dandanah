# Device location design

Date: 2026-11-26
Status: awaiting approval

## Intent

Let the user set prayer location from the phone instead of hunting through 59
city presets. The first run should ask for location permission, and Settings
should offer a refresh action later. Prayer times and qibla must stay offline.

## Goals

- One tap in Settings (and once on first run) fills exact latitude/longitude.
- Resolve the device IANA timezone so DST and travel work with the existing
  `PrayerScheduleService`.
- Request foreground permission only; never background location.
- Keep manual city and coordinate entry working when permission is denied.
- Persist the result and show which source is active.
- Keep location on the device; no network call.

## Non-goals

- Maps, reverse geocoding or a visible address.
- Continuous tracking, geofencing or background updates.
- Replacing the 59 city presets.

## Approaches considered

1. **`geolocator` + a small native timezone channel (chosen).** The plugin
   handles Android/iOS permission UX and a single fix; the channel returns
   `TimeZone.getDefault().id` / `TimeZone.current.identifier`, avoiding the
   timezone plugin that previously broke Gradle.
2. **Native location code only.** No dependency, but duplicated Android and
   iOS code and manual permission handling. Slower to ship and harder to test.
3. **Manual city only.** Least work, but does not satisfy the request.

## Behaviour

### First run

If `configured` is false and onboarding has not been shown, show an Arabic
bottom sheet after the first frame:

- Title: تحديد الموقع
- Body: explains that location is used only on the device for prayer times.
- Primary: **استخدم موقعي** — requests permission, gets one fix, saves
  coordinates + device timezone, closes the sheet.
- Secondary: **اختيار مدينة** — dismisses the sheet and leaves the user on the
  dashboard location hint / Settings.

The sheet is not shown again after either choice. If permission is denied, a
short message explains that city selection still works.

### Settings

Add **استخدم موقعي الحالي** above the city dropdown.

- Shows a spinner while requesting/fetching.
- On success: fills latitude, longitude and timezone fields, clears the city
  selection, marks the source as device; the user still presses **حفظ** so
  unsaved method/madhab edits are not lost.
- On denial or timeout: inline Arabic error; offer **فتح إعدادات التطبيق**
  when permission is permanently denied.
- Fetch timeout: 12 seconds. Use the last known fix immediately if fresh enough,
  otherwise request a single current fix.

### Data

Add `locationSource` (`device`, `city`, `manual`) to `PrayerSettings` JSON.
GPS sets `configured: true`, `cityId: null`, `locationSource: device`.
Settings shows **موقع الجهاز** when that source is active.

### Timezone

After a fix, call the native channel for the IANA name. Validate it against the
bundled database; if invalid, keep the current setting and still save
coordinates. No new timezone package.

### Platform permissions

- Android manifest: `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION`.
- iOS `Info.plist`: `NSLocationWhenInUseUsageDescription` in Arabic/English.
- No background location permission.

## Implementation shape

- `DeviceLocation { latitude, longitude, timezone }`.
- `LocationService` interface with `Future<DeviceLocation> currentLocation()`.
- `GeolocatorLocationService` wraps geolocator + the timezone channel.
- Inject the service into the first-run sheet and Settings page so tests use a
  fake without touching platform channels.
- `LocationOnboarding` helper reads/writes a `location.onboarding_seen` key.
- Tests: permission granted, denied, timeout, invalid timezone, saved
  settings, and first-run suppression after a choice.

## Risks

- Adding a plugin changes Gradle/CocoaPods configuration; CI must build both.
- Emulator GPS may have no fix, so the fake service is the primary test path.
- A single fix can be stale; the settings action always re-fetches.

## Acceptance

- First launch asks for permission with clear Arabic copy.
- Allowing it fills location and timezone; times and qibla update.
- Denying it leaves manual city selection fully usable and does not nag.
- Settings refresh works and persists across restart.
- `flutter analyze`, tests, Android CI and iOS CI stay green.
