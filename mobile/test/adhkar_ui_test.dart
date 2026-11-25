import 'dart:io';

import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakeenah_mobile/data/app_services.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart'
    hide AdhkarCategory, AdhkarItem;
import 'package:sakeenah_mobile/data/models/adhkar.dart';
import 'package:sakeenah_mobile/data/worship/timezone_bootstrap.dart';
import 'package:sakeenah_mobile/features/adhkar/adhkar_category_page.dart';
import 'package:sakeenah_mobile/features/adhkar/adhkar_page.dart';
import 'package:sakeenah_mobile/l10n/app_localizations.dart';
import 'package:sakeenah_mobile/theme/sakeenah_theme.dart';

final _clock = DateTime.utc(2026, 11, 26, 9);

void main() {
  setUpAll(() async {
    await AppServices.initialize(
      database: AppDatabase.memory(),
      bundle: _FileAssetBundle(),
    );
    final db = AppServices.current.database;
    await db
        .into(db.adhkarCategories)
        .insert(
          AdhkarCategoriesCompanion.insert(
            id: 'test-streak',
            title: 'اختبار السلسلة',
            featured: false,
            streakKey: const Value('morning'),
            sortOrder: 1000,
          ),
        );
    await db
        .into(db.adhkarItems)
        .insert(
          AdhkarItemsCompanion.insert(
            id: 'test-streak-1',
            categoryId: 'test-streak',
            body: 'ذكر اختبار السلسلة',
            repeatCount: 1,
            source: 'اختبار',
            sortOrder: 0,
          ),
        );
    await db
        .into(db.adhkarCategories)
        .insert(
          AdhkarCategoriesCompanion.insert(
            id: 'test-advance',
            title: 'اختبار التقدم',
            featured: false,
            sortOrder: 1001,
          ),
        );
    for (var index = 0; index < 3; index++) {
      await db
          .into(db.adhkarItems)
          .insert(
            AdhkarItemsCompanion.insert(
              id: 'test-advance-${index + 1}',
              categoryId: 'test-advance',
              body: ['الأول', 'الثاني', 'الثالث'][index],
              repeatCount: 1,
              source: 'اختبار',
              sortOrder: index,
            ),
          );
    }
    await db
        .into(db.adhkarCategories)
        .insert(
          AdhkarCategoriesCompanion.insert(
            id: 'test-search',
            title: 'دُعَاءُ الاختبار',
            featured: false,
            sortOrder: 1002,
          ),
        );
    await db
        .into(db.adhkarItems)
        .insert(
          AdhkarItemsCompanion.insert(
            id: 'test-search-1',
            categoryId: 'test-search',
            body: 'ذِكْرٌ لِلْبَحْثِ',
            repeatCount: 1,
            source: 'اختبار',
            sortOrder: 0,
          ),
        );
  });

  tearDownAll(AppServices.shutdown);

  setUp(() async {
    final db = AppServices.current.database;
    await db.delete(db.adhkarProgress).go();
    await db.delete(db.adhkarLogs).go();
  });

  String todayKey() => dateKeyInTimezone('Asia/Riyadh', now: _clock);

  Future<void> pumpPage(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(390, 844),
    double textScale = 1,
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
        theme: SakeenahTheme.dark(),
        builder: (context, widget) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: widget!,
        ),
        home: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  AdhkarCategory makeCategory(
    String id,
    String title,
    int itemCount, {
    String? streakKey,
  }) => AdhkarCategory(
    id: id,
    title: title,
    featured: false,
    itemCount: itemCount,
    streakKey: streakKey,
  );

  testWidgets('catalog shows the streak, featured and all categories', (
    tester,
  ) async {
    await pumpPage(tester, Scaffold(body: AdhkarPage(clock: () => _clock)));

    expect(find.text('أذكار اليوم'), findsOneWidget);
    expect(find.text('أذكار مختارة'), findsOneWidget);
    expect(find.text('كل الأذكار'), findsOneWidget);
    expect(find.text('أذكار الصباح'), findsOneWidget);
    expect(find.text('الصباح'), findsOneWidget);
    expect(find.text('المساء'), findsOneWidget);
  });

  testWidgets('counter advances to the next item and persists progress', (
    tester,
  ) async {
    final items = await AppServices.current.adhkar.itemsFor('hisn-002');
    final category = makeCategory('hisn-002', 'اختبار', 2);
    await pumpPage(
      tester,
      AdhkarCategoryPage(category: category, clock: () => _clock),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('اضغط للعد'), findsOneWidget);
    final before = await AppServices.current.adhkarPractice.completedCounts(
      items,
      todayKey(),
    );
    expect(before[items.first.id] ?? 0, 0);

    await tester.tap(find.byKey(ValueKey('adhkar-counter-${items.first.id}')));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    final counts = await AppServices.current.adhkarPractice.completedCounts(
      items,
      todayKey(),
    );
    expect(counts[items.first.id], 1);
    expect(find.text(items[1].text), findsOneWidget);
  });

  testWidgets('resumes on the first unfinished item', (tester) async {
    final items = await AppServices.current.adhkar.itemsFor('hisn-002');
    final category = makeCategory('hisn-002', 'اختبار', 2);
    await AppServices.current.adhkarPractice.increment(
      category,
      items.first,
      todayKey(),
    );

    await pumpPage(
      tester,
      AdhkarCategoryPage(category: category, clock: () => _clock),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(items[1].text), findsOneWidget);
  });

  testWidgets("completing a streak category writes today's log", (
    tester,
  ) async {
    final category = makeCategory(
      'test-streak',
      'اختبار السلسلة',
      1,
      streakKey: 'morning',
    );
    await pumpPage(
      tester,
      AdhkarCategoryPage(category: category, clock: () => _clock),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(
      find.byKey(const ValueKey('adhkar-counter-test-streak-1')),
    );
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    final db = AppServices.current.database;
    final logs = await db.select(db.adhkarLogs).get();
    expect(logs, hasLength(1));
    expect(logs.single.streakKey, 'morning');
    expect(logs.single.localDate, todayKey());
    expect(
      (await AppServices.current.adhkarPractice.streak(todayKey()))
          .todayMorning,
      isTrue,
    );
    expect(find.text('أتممت الأذكار'), findsOneWidget);
  });

  testWidgets('auto-advance moves forward from the completed item', (
    tester,
  ) async {
    final category = makeCategory('test-advance', 'اختبار التقدم', 3);
    await pumpPage(
      tester,
      AdhkarCategoryPage(category: category, clock: () => _clock),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.text('الثاني'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('adhkar-counter-test-advance-2')),
    );
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();

    expect(find.text('الثالث'), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);
  });

  testWidgets('search ignores vocalisation and finds item text', (
    tester,
  ) async {
    await pumpPage(tester, Scaffold(body: AdhkarPage(clock: () => _clock)));

    await tester.enterText(find.byType(TextField), 'للبحث');
    await tester.pumpAndSettle();

    expect(find.text('دُعَاءُ الاختبار'), findsOneWidget);
    expect(find.text('لا توجد نتائج'), findsNothing);
  });

  testWidgets('resetting a completed section clears its streak log', (
    tester,
  ) async {
    final category = makeCategory(
      'test-streak',
      'اختبار السلسلة',
      1,
      streakKey: 'morning',
    );
    await pumpPage(
      tester,
      AdhkarCategoryPage(category: category, clock: () => _clock),
    );
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(
      find.byKey(const ValueKey('adhkar-counter-test-streak-1')),
    );
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إغلاق'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('إعادة القسم'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'إعادة القسم'));
    await tester.pumpAndSettle();

    final db = AppServices.current.database;
    expect(await db.select(db.adhkarLogs).get(), isEmpty);
    expect(await db.select(db.adhkarProgress).get(), isEmpty);
    expect(find.text('اضغط للعد'), findsOneWidget);
  });

  testWidgets('catalog and counter survive a small phone at 2x text', (
    tester,
  ) async {
    await pumpPage(
      tester,
      Scaffold(body: AdhkarPage(clock: () => _clock)),
      size: const Size(320, 640),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);

    final category = makeCategory(
      'test-streak',
      'اختبار السلسلة',
      1,
      streakKey: 'morning',
    );
    await pumpPage(
      tester,
      AdhkarCategoryPage(category: category, clock: () => _clock),
      size: const Size(320, 640),
      textScale: 2,
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
