import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakeenah_mobile/data/app_services.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/features/settings/settings_page.dart';
import 'package:sakeenah_mobile/l10n/app_localizations.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;

void main() {
  setUpAll(() async {
    await AppServices.initialize(
      database: AppDatabase.memory(),
      bundle: _FileAssetBundle(),
    );
  });

  tearDownAll(AppServices.shutdown);

  testWidgets('theme segment invokes the callback', (tester) async {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final modes = <ThemeMode>[];
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
        home: SettingsPage(
          themeMode: ThemeMode.dark,
          onThemeChanged: modes.add,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pump(const Duration(milliseconds: 200));

    expect(modes, [ThemeMode.light]);
  });

  testWidgets('saves manual coordinates and calculation settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 3400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
        home: SettingsPage(themeMode: ThemeMode.dark, onThemeChanged: (_) {}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(find.byType(TextField).at(0), '30.0444');
    await tester.enterText(find.byType(TextField).at(1), '31.2357');
    await tester.tap(find.text('حفظ'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    final saved = AppServices.current.prayerSettings.value;
    expect(saved.latitude, 30.0444);
    expect(saved.longitude, 31.2357);
    expect(saved.configured, isTrue);
    expect(find.text('تم حفظ الإعدادات'), findsOneWidget);
  });
}

class _FileAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}
