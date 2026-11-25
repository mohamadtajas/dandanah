# Device Location Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the user populate prayer coordinates and timezone from the phone, with a first-run permission prompt and a Settings refresh action.

**Architecture:** A thin `LocationService` wraps `geolocator` for one foreground fix and a small native method channel for the device IANA timezone. The first-run sheet and Settings page call the service through an injected interface, then save the resolved location into the existing `PrayerSettings` JSON.

**Tech Stack:** Flutter 3.50 / Dart 3.14, `geolocator` 14.1.2, Android MethodChannel, iOS MethodChannel, Drift settings store.

**Spec:** `docs/superpowers/specs/2026-11-26-device-location-design.md`

## Global Constraints

- Arabic-first UI; every new string goes in `app_ar.arb` and `app_en.arb`.
- Offline-first: no network calls for location or timezone.
- Foreground permission only; no background location.
- Manual city selection must keep working when permission is denied.
- Android minSdk 26, targetSdk 36; iOS CI must compile.
- Do not reintroduce `flutter_timezone`.

## Review Focus

- Permission denied and denied-forever: the user can always fall back to a city.
- Location timeout or no fix: no partial settings are saved.
- Invalid/absent native timezone: keep the current timezone, still save coordinates.
- First-run sheet appears once, not on every launch.
- GPS fix in a timezone with DST resolves the correct IANA name.

---

### Task 1: Persist the location source

**Files:**
- Modify: `lib/data/worship/prayer_settings.dart`
- Test: `test/prayer_schedule_test.dart`

**Interfaces:**
- Produces: `PrayerSettings.locationSource` as `String?` with values `device`, `city`, `manual`; `copyWith(locationSource: ..., clearLocationSource: ...)`.

- [ ] **Step 1: Write the failing test**

Add to `test/prayer_schedule_test.dart`:

```dart
test('location source survives JSON and manual edits reset it', () {
  final device = makkah.copyWith(
    configured: true,
    cityId: null,
    clearCity: true,
    locationSource: 'device',
  );
  final restored = PrayerSettings.fromJson(device.toJson());
  expect(restored.locationSource, 'device');
  expect(restored.cityId, isNull);

  final manual = restored.copyWith(locationSource: 'manual');
  expect(manual.locationSource, 'manual');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/prayer_schedule_test.dart`
Expected: FAIL because `locationSource` is not defined.

- [ ] **Step 3: Implement the field**

Add `this.locationSource` to the constructor, `final String? locationSource`, JSON read/write, and `copyWith` support. In `sanitized()`, keep only `device`, `city`, or `manual`; otherwise null.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/prayer_schedule_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/data/worship/prayer_settings.dart mobile/test/prayer_schedule_test.dart
git commit -m "feat(mobile): track how prayer location was set"
```

---

### Task 2: Location service and native timezone channel

**Files:**
- Create: `lib/data/location/device_location.dart`
- Create: `lib/data/location/location_service.dart`
- Create: `lib/data/location/geolocator_location_service.dart`
- Modify: `android/app/src/main/kotlin/app/sakeenah/mobile/MainActivity.kt`
- Modify: `ios/Runner/AppDelegate.swift`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`
- Test: `test/location_service_test.dart`

**Interfaces:**
- Consumes: `isValidTimezone(String)` from `lib/data/worship/timezone_bootstrap.dart`.
- Produces:
  - `DeviceLocation({required double latitude, required double longitude, String? timezone})`
  - `enum LocationFailure { denied, deniedForever, timeout, unavailable }`
  - `LocationResult.success(DeviceLocation)` / `LocationResult.failure(LocationFailure)`
  - `abstract interface class LocationPlatform { Future<LocationPermission> checkPermission(); Future<LocationPermission> requestPermission(); Future<Position?> lastKnownPosition(); Future<Position> currentPosition(); Future<void> openSettings(); }`
  - `abstract interface class LocationService { Future<LocationResult> currentLocation(); Future<void> openAppSettings(); }`
  - `GeolocatorLocationService({LocationPlatform? platform, MethodChannel? timezoneChannel})` implements it.

- [ ] **Step 1: Write the failing tests**

Create `test/location_service_test.dart` with a fake `MethodChannel` handler:

```dart
test('valid device timezone is returned', () async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async => 'Asia/Amman');
  final result = await service.currentLocation();
  expect(result.location?.timezone, 'Asia/Amman');
});
```

Also test an invalid timezone returns `timezone == null`, and that a denied permission maps to `LocationFailure.denied`. The fake implements `LocationPlatform`; do not call platform channels for coordinates in tests.

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/location_service_test.dart`
Expected: FAIL because the service and channel do not exist.

- [ ] **Step 3: Implement the service and channels**

Create the models/interface. Implement `GeolocatorLocationService`:

```dart
Future<LocationResult> currentLocation() async {
  var permission = await geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    return const LocationResult.failure(LocationFailure.denied);
  }
  if (permission == LocationPermission.deniedForever) {
    return const LocationResult.failure(LocationFailure.deniedForever);
  }
  try {
    final last = await geolocator.getLastKnownPosition();
    final fresh = last != null &&
        DateTime.now().difference(last.timestamp) < const Duration(minutes: 10);
    final position = fresh
        ? last
        : await geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 12),
            ),
          );
    final raw = await channel.invokeMethod<String>('getLocalTimezone');
    final timezone = raw != null && isValidTimezone(raw) ? raw : null;
    return LocationResult.success(DeviceLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      timezone: timezone,
    ));
  } on TimeoutException {
    return const LocationResult.failure(LocationFailure.timeout);
  } catch (_) {
    return const LocationResult.failure(LocationFailure.unavailable);
  }
}
```

`openAppSettings()` calls `Geolocator.openAppSettings()`.

Android channel in `MainActivity.configureFlutterEngine`; iOS channel in
`didInitializeImplicitFlutterEngine` using
`engineBridge.applicationRegistrar.messenger()`.

Add `<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>`
and `ACCESS_FINE_LOCATION`; add `NSLocationWhenInUseUsageDescription` to
`Info.plist`.

- [ ] **Step 4: Run tests and build**

Run: `flutter test test/location_service_test.dart`
Run: `flutter build apk --debug`
Expected: tests pass and Gradle succeeds.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/data/location mobile/test/location_service_test.dart mobile/android mobile/ios
git commit -m "feat(mobile): read device location and timezone"
```

---

### Task 3: First-run location sheet

**Files:**
- Create: `lib/features/location/location_onboarding_sheet.dart`
- Modify: `lib/app.dart`
- Modify: `lib/shell/app_shell.dart`
- Modify: `lib/data/app_services.dart`
- Test: `test/location_onboarding_test.dart`

**Interfaces:**
- Consumes: `LocationService`, `PrayerSettings`, `AppServices.updatePrayerSettings`.
- Produces: `shouldShowLocationOnboarding(AppDatabase db, PrayerSettings settings) -> Future<bool>` and `LocationOnboardingSheet`.

- [ ] **Step 1: Write the failing test**

Pump the sheet with a fake service that returns `DeviceLocation(31.95, 35.91, 'Asia/Amman')`, tap **استخدم موقعي**, and assert `PrayerSettings` now has those coordinates, `configured == true`, `locationSource == 'device'`, and `location.onboarding_seen` is true. A second test chooses **اختيار مدينة** and asserts no settings change but the seen flag is written.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/location_onboarding_test.dart`
Expected: FAIL because the sheet/helper do not exist.

- [ ] **Step 3: Implement the sheet and wiring**

`AppServices` creates a `GeolocatorLocationService` and exposes it as `location`.
`SakeenahApp` passes it to `AppShell`. In `AppShell.initState`, after the first
frame, check `!settings.configured && !seen`; show the sheet.

Sheet copy: title **تحديد الموقع**, body explains on-device use, buttons
**استخدم موقعي** and **اختيار مدينة**. On success, save:

```dart
settings.copyWith(
  latitude: location.latitude,
  longitude: location.longitude,
  timezone: location.timezone ?? settings.timezone,
  configured: true,
  clearCity: true,
  locationSource: 'device',
)
```

On failure show the mapped Arabic message and keep the sheet open.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/location_onboarding_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/features/location mobile/lib/app.dart mobile/lib/shell mobile/lib/data/app_services.dart mobile/test/location_onboarding_test.dart
git commit -m "feat(mobile): ask for location on first run"
```

---

### Task 4: Settings current-location action

**Files:**
- Modify: `lib/features/settings/settings_page.dart`
- Modify: `lib/shell/app_shell.dart`
- Test: `test/settings_page_test.dart`

**Interfaces:**
- Consumes: `LocationService`, `LocationResult`.
- Produces: a `SettingsPage` constructor accepting `required LocationService location`.

- [ ] **Step 1: Write the failing tests**

Use a fake service. Tap **استخدم موقعي الحالي** and assert latitude/longitude/timezone controllers are filled and the city becomes custom. Press **حفظ** and assert `locationSource == 'device'`. A denied test asserts the error text and that no settings changed.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/settings_page_test.dart`
Expected: FAIL because the button and parameter do not exist.

- [ ] **Step 3: Implement the button**

Place an `OutlinedButton.icon` above the city dropdown. While fetching,
disable it and show a 16 px spinner. On success fill the fields, set
`_cityId = null`, `_timezone = result.timezone ?? _timezone`, and
`_locationSource = 'device'`, and show **موقع الجهاز** under the dropdown.
On failure show a SnackBar; for
`deniedForever`, add a **فتح إعدادات التطبيق** action that calls
`location.openAppSettings()`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/settings_page_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/features/settings mobile/lib/shell mobile/test/settings_page_test.dart
git commit -m "feat(mobile): use current location from settings"
```

---

### Task 5: Verification

- [ ] **Step 1: Full checks**

```bash
cd mobile
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
```

Expected: no analyzer issues, all tests pass, APK builds.

- [ ] **Step 2: Emulator permission flow**

Install on `sakeenah_api36`, set a mock GPS fix, clear app data, launch.
Expected: first-run sheet appears; **استخدم موقعي** shows the OS permission
dialog; granting fills location and timezone; denying leaves city selection.

- [ ] **Step 3: Persistence check**

Force-stop and reopen. Expected: the sheet does not reappear and the saved
location/timezone remain.

- [ ] **Step 4: Commit and push; watch mobile CI**

```bash
git push origin master
```

Expected: Android and iOS jobs pass.
