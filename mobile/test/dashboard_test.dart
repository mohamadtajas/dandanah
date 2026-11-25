import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakeenah_mobile/data/app_services.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/data/worship/prayer_settings.dart';
import 'package:sakeenah_mobile/features/dashboard/dashboard_page.dart';
import 'package:sakeenah_mobile/l10n/app_localizations.dart';
import 'package:sakeenah_mobile/theme/sakeenah_theme.dart';

void main() {
  setUpAll(() async {
    await AppServices.initialize(
      database: AppDatabase.memory(),
      bundle: _FileAssetBundle(),
    );
  });

  tearDownAll(AppServices.shutdown);

  setUp(() async {
    await AppServices.current.updatePrayerSettings(
      PrayerSettings.defaults(timezone: 'Asia/Riyadh'),
    );
  });

  Future<void> pumpDashboard(WidgetTester tester) async {
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
        theme: SakeenahTheme.dark(),
        home: Scaffold(
          body: DashboardPage(
            onSelectTab: (_) {},
            clock: () => DateTime.utc(2026, 11, 26, 2),
          ),
        ),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  testWidgets('shows the next prayer, times, streak and location hint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpDashboard(tester);

    expect(find.text('الصلاة القادمة'), findsOneWidget);
    expect(find.text('الفجر'), findsWidgets);
    expect(find.text('مواقيت اليوم'), findsOneWidget);
    expect(find.textContaining('سلسلة الصلوات'), findsWidgets);
    expect(find.textContaining('لم يتم ضبط موقعك'), findsOneWidget);
    expect(find.byKey(const ValueKey('prayer-fajr')), findsOneWidget);
    expect(find.byKey(const ValueKey('prayer-isha')), findsOneWidget);
  });

  testWidgets('tapping a prayer logs it and updates the streak', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpDashboard(tester);

    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    await tester.tap(find.byKey(const ValueKey('prayer-fajr')));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);
    final streak = await AppServices.current.prayerLog.streak('2026-11-26');
    expect(streak.todayCount, 1);

    await tester.tap(find.byKey(const ValueKey('prayer-fajr')));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect((await AppServices.current.prayerLog.day('2026-11-26')).count, 0);
  });

  testWidgets('can mark the day excused and undo it', (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpDashboard(tester);

    await tester.tap(find.text('احتساب اليوم معذورًا'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(
      (await AppServices.current.prayerLog.day('2026-11-26')).excused,
      isTrue,
    );
    expect(find.text('إلغاء عذر اليوم'), findsOneWidget);

    await tester.tap(find.text('إلغاء عذر اليوم'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(
      (await AppServices.current.prayerLog.day('2026-11-26')).excused,
      isFalse,
    );
  });
}

class _FileAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}
