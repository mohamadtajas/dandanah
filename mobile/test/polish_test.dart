import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakeenah_mobile/data/app_services.dart';
import 'package:sakeenah_mobile/data/audio/playback_controller.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/data/models/audio.dart';
import 'package:sakeenah_mobile/data/repositories/adhan_settings_repository.dart';
import 'package:sakeenah_mobile/data/worship/adhan_scheduler.dart';
import 'package:sakeenah_mobile/data/worship/prayer_settings.dart';
import 'package:sakeenah_mobile/features/audio/audio_page.dart';
import 'package:sakeenah_mobile/features/audio/mini_player.dart';
import 'package:sakeenah_mobile/features/audio/player_page.dart';
import 'package:sakeenah_mobile/features/quran/quran_page.dart';
import 'package:sakeenah_mobile/features/quran/quran_reader_page.dart';
import 'package:sakeenah_mobile/features/settings/settings_page.dart';
import 'package:sakeenah_mobile/l10n/app_localizations.dart';
import 'package:sakeenah_mobile/theme/sakeenah_theme.dart';

import 'support/fake_audio_engine.dart';
import 'support/fake_notification_service.dart';

void main() {
  late PlaybackController playback;

  setUpAll(() async {
    playback = PlaybackController(FakeAudioEngine());
    await AppServices.initialize(
      database: AppDatabase.memory(),
      bundle: _FileAssetBundle(),
      playback: playback,
      notifications: FakeNotificationService(),
    );
    await AppServices.current.updatePrayerSettings(
      PrayerSettings.defaults().copyWith(configured: true),
    );
  });

  tearDownAll(AppServices.shutdown);

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(320, 640),
  }) async {
    tester.view.physicalSize = size;
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
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: widget!,
        ),
        theme: SakeenahTheme.dark(),
        home: child,
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
  }

  testWidgets('Quran catalog fits a small phone at 2x text', (tester) async {
    await pump(tester, const Scaffold(body: MushafPage()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Quran reader fits a small phone at 2x text', (tester) async {
    await pump(tester, const QuranReaderPage.surah(surah: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('audio catalog fits a small phone at 2x text', (tester) async {
    await pump(tester, Scaffold(body: AudioPage(playback: playback)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('audio player and mini-player fit at 2x text', (tester) async {
    await playback.playQueue([
      const AudioTrack(
        id: 'test',
        reciterId: 'test',
        reciterName: 'مشاري العفاسي',
        surah: 1,
        ayah: 1,
        surahName: 'الفاتحة',
        url: 'https://example.test/001001.mp3',
      ),
    ]);
    await pump(tester, PlayerPage(playback: playback));
    expect(tester.takeException(), isNull);

    await pump(tester, MiniPlayer(playback: playback));
    expect(tester.takeException(), isNull);
  });

  testWidgets('adhan settings fit a small phone at 2x text', (tester) async {
    final scheduler = AdhanScheduler(
      preferences: AdhanSettingsRepository(AppServices.current.database),
      settings: AppServices.current.prayerSettings,
      service: FakeNotificationService(),
    );
    await pump(
      tester,
      SettingsPage(
        themeMode: ThemeMode.dark,
        onThemeChanged: (_) {},
        location: AppServices.current.location,
        adhanScheduler: scheduler,
      ),
      size: const Size(320, 1200),
    );
    expect(tester.takeException(), isNull);
  });
}

class _FileAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}
