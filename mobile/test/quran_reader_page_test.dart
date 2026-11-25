import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:sakeenah_mobile/data/app_services.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/data/worship/prayer_settings.dart';
import 'package:sakeenah_mobile/features/quran/quran_reader_page.dart';
import 'package:sakeenah_mobile/l10n/app_localizations.dart';
import 'package:sakeenah_mobile/theme/sakeenah_theme.dart';

void main() {
  setUpAll(() async {
    await AppServices.initialize(
      database: AppDatabase.memory(),
      bundle: _FileAssetBundle(),
    );
    await AppServices.current.updatePrayerSettings(
      PrayerSettings.defaults().copyWith(configured: true),
    );
  });

  tearDownAll(AppServices.shutdown);

  setUp(() async {
    final db = AppServices.current.database;
    await db.delete(db.readerState).go();
    await db.delete(db.bookmarks).go();
    await AppServices.current.quranReader.saveFontSize(28);
  });

  Future<void> pumpReader(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(390, 844);
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
        theme: SakeenahTheme.dark(),
        home: page,
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
  }

  testWidgets('surah reader shows the first ayah and bismillah', (
    tester,
  ) async {
    final baqarah = await AppServices.current.quran.surahByNumber(2);
    await pumpReader(tester, const QuranReaderPage.surah(surah: 2));

    expect(find.text(baqarah!.bismillah!), findsOneWidget);
    expect(
      find.text((await AppServices.current.quran.ayah(2, 1))!.text),
      findsOneWidget,
    );
    expect(
      find.text((await AppServices.current.quran.ayah(1, 2))!.text),
      findsNothing,
    );
  });

  testWidgets('font controls change and persist the ayah size', (tester) async {
    final first = await AppServices.current.quran.ayah(1, 1);
    await pumpReader(tester, const QuranReaderPage.surah(surah: 1));

    Text ayahText() => tester.widget<Text>(find.text(first!.text));
    expect(ayahText().style?.fontSize, 28);

    await tester.tap(find.byKey(const ValueKey('quran-font-increase')));
    await tester.pumpAndSettle();
    expect(ayahText().style?.fontSize, 30);
    expect(await AppServices.current.quranReader.fontSize(), 30);

    await pumpReader(tester, const QuranReaderPage.surah(surah: 1));
    expect(ayahText().style?.fontSize, 30);

    await tester.tap(find.byKey(const ValueKey('quran-font-decrease')));
    await tester.pumpAndSettle();
    expect(ayahText().style?.fontSize, 28);
  });

  testWidgets('bookmark icon toggles for an ayah', (tester) async {
    await pumpReader(tester, const QuranReaderPage.surah(surah: 1));

    await tester.tap(find.byKey(const ValueKey('quran-bookmark-1-1')));
    await tester.pumpAndSettle();
    expect(await AppServices.current.quranReader.isBookmarked(1, 1), isTrue);

    await tester.tap(find.byKey(const ValueKey('quran-bookmark-1-1')));
    await tester.pumpAndSettle();
    expect(await AppServices.current.quranReader.isBookmarked(1, 1), isFalse);
  });

  testWidgets('tapping an ayah saves the resume position', (tester) async {
    await pumpReader(tester, const QuranReaderPage.surah(surah: 1));

    await tester.tap(find.byKey(const ValueKey('quran-ayah-1-3')));
    await tester.pumpAndSettle();

    final position = await AppServices.current.quranReader.position();
    expect(position!.surah, 1);
    expect(position.ayah, 3);
  });

  testWidgets('opens at a saved ayah', (tester) async {
    final ayah = await AppServices.current.quran.ayah(2, 255);
    await pumpReader(
      tester,
      const QuranReaderPage.surah(surah: 2, initialAyah: 255),
    );

    expect(find.text(ayah!.text), findsOneWidget);
  });

  testWidgets('juz reader starts at the first ayah of the juz', (tester) async {
    final first = (await AppServices.current.quran.ayahsForJuz(30)).first;
    await pumpReader(tester, const QuranReaderPage.juz(juz: 30));

    expect(find.text('النبإ'), findsOneWidget);
    expect(find.text(first.text), findsOneWidget);
  });

  testWidgets('juz 2 does not inject a mid-surah basmala', (tester) async {
    final baqarah = await AppServices.current.quran.surahByNumber(2);
    await pumpReader(tester, const QuranReaderPage.juz(juz: 2));

    expect(find.text(baqarah!.bismillah!), findsNothing);
  });

  testWidgets('at-Tawba renders without a basmala', (tester) async {
    final baqarah = await AppServices.current.quran.surahByNumber(2);
    await pumpReader(tester, const QuranReaderPage.surah(surah: 9));

    expect(find.text(baqarah!.bismillah!), findsNothing);
  });

  testWidgets('flushes the pending position before the route pops', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
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
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const QuranReaderPage.surah(surah: 2),
                ),
              ),
              child: const Text('فتح'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(ScrollablePositionedList),
      const Offset(0, -1400),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    final position = await AppServices.current.quranReader.position();
    expect(position, isNotNull);
    expect(position!.surah, 2);
    expect(position.ayah, greaterThan(1));
  });
}

class _FileAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}
