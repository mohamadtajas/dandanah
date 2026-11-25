import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/data/location/device_location.dart';
import 'package:sakeenah_mobile/data/location/location_onboarding.dart';
import 'package:sakeenah_mobile/data/location/location_service.dart';
import 'package:sakeenah_mobile/data/worship/prayer_settings.dart';
import 'package:sakeenah_mobile/features/location/location_onboarding_sheet.dart';
import 'package:sakeenah_mobile/l10n/app_localizations.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    required LocationService location,
    required PrayerSettings settings,
    required Future<void> Function(PrayerSettings) onSave,
    required Future<void> Function() onDismiss,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: LocationOnboardingSheet(
            location: location,
            settings: settings,
            onSave: onSave,
            onDismiss: onDismiss,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('granted location is saved with its timezone', (tester) async {
    PrayerSettings? saved;
    await pumpSheet(
      tester,
      location: _FakeLocationService(
        const LocationResult.success(
          DeviceLocation(
            latitude: 31.9539,
            longitude: 35.9106,
            timezone: 'Asia/Amman',
          ),
        ),
      ),
      settings: PrayerSettings.defaults(),
      onSave: (settings) async => saved = settings,
      onDismiss: () async {},
    );

    await tester.tap(find.text('استخدم موقعي'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(saved, isNotNull);
    expect(saved!.locationSource, 'device');
    expect(saved!.configured, isTrue);
    expect(saved!.cityId, isNull);
    expect(saved!.timezone, 'Asia/Amman');
    expect(saved!.latitude, closeTo(31.9539, 1e-6));
  });

  testWidgets('choosing a city only records the dismissal', (tester) async {
    var dismissed = false;
    PrayerSettings? saved;
    await pumpSheet(
      tester,
      location: _FakeLocationService(
        const LocationResult.failure(LocationFailure.denied),
      ),
      settings: PrayerSettings.defaults(),
      onSave: (settings) async => saved = settings,
      onDismiss: () async => dismissed = true,
    );

    await tester.tap(find.text('اختيار مدينة'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(dismissed, isTrue);
    expect(saved, isNull);
  });

  testWidgets('denied permission keeps the sheet open with an error', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      location: _FakeLocationService(
        const LocationResult.failure(LocationFailure.denied),
      ),
      settings: PrayerSettings.defaults(),
      onSave: (_) async {},
      onDismiss: () async {},
    );

    await tester.tap(find.text('استخدم موقعي'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.text('لم يتم السماح بالوصول إلى الموقع. يمكنك اختيار مدينة يدويًا.'),
      findsOneWidget,
    );
    expect(find.text('اختيار مدينة'), findsOneWidget);
  });

  test('onboarding is shown once until a location is configured', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    expect(
      await shouldShowLocationOnboarding(db, PrayerSettings.defaults()),
      isTrue,
    );

    await markLocationOnboardingSeen(db);
    expect(
      await shouldShowLocationOnboarding(db, PrayerSettings.defaults()),
      isFalse,
    );
    expect(
      await shouldShowLocationOnboarding(
        db,
        PrayerSettings.defaults().copyWith(configured: true),
      ),
      isFalse,
    );
  });
}

class _FakeLocationService implements LocationService {
  _FakeLocationService(this.result);

  final LocationResult result;

  @override
  Future<LocationResult> currentLocation() async => result;

  @override
  Future<void> openAppSettings() async {}
}
