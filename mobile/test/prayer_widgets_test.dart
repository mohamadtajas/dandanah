import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/data/repositories/prayer_log_repository.dart';
import 'package:sakeenah_mobile/data/widgets/prayer_widget_publisher.dart';
import 'package:sakeenah_mobile/data/widgets/widget_bridge.dart';
import 'package:sakeenah_mobile/data/worship/prayer_log.dart';
import 'package:sakeenah_mobile/data/worship/prayer_settings.dart';
import 'package:sakeenah_mobile/data/worship/prayer_times_service.dart';

void main() {
  late AppDatabase db;
  late DriftPrayerLogRepository log;
  late ValueNotifier<PrayerSettings> settings;
  late _FakeBridge bridge;
  late PrayerWidgetPublisher publisher;

  setUp(() async {
    db = AppDatabase.memory();
    log = DriftPrayerLogRepository(db);
    settings = ValueNotifier(
      PrayerSettings.defaults(timezone: 'Asia/Riyadh')
          .copyWith(configured: true),
    );
    bridge = _FakeBridge();
    publisher = PrayerWidgetPublisher(
      settings: settings,
      log: log,
      bridge: bridge,
      clock: () => DateTime.utc(2026, 11, 26, 3),
    );
  });

  tearDown(() async {
    settings.dispose();
    await db.close();
  });

  test('publishes a week of prayer data and schedules updates', () async {
    await publisher.refresh();

    final raw = bridge.saved[PrayerWidgetPublisher.dataKey];
    expect(raw, isNotNull);
    final data = jsonDecode(raw!) as Map<String, dynamic>;
    expect(data['configured'], isTrue);
    expect(data['today'], '2026-11-26');
    expect(data['hijri'], isNotEmpty);
    final days = data['days'] as List<dynamic>;
    expect(days, hasLength(7));
    final first = days.first as Map<String, dynamic>;
    expect(first['date'], '2026-11-26');
    expect(first['prayers'], hasLength(5));
    expect((first['prayers'] as List).first['name'], 'الفجر');

    expect(bridge.updates, containsAll(PrayerWidgets.all));
    for (final provider in PrayerWidgets.all) {
      expect(bridge.schedules[provider], isNotEmpty);
      expect(
        bridge.schedules[provider]!.every(
          (time) => time.isAfter(DateTime.utc(2026, 11, 26, 3)),
        ),
        isTrue,
      );
    }
  });

  test('marks prayers already logged today', () async {
    await log.setStatus('2026-11-26', PrayerName.fajr, PrayerStatus.onTime);
    await publisher.refresh();

    final data = jsonDecode(
      bridge.saved[PrayerWidgetPublisher.dataKey]!,
    ) as Map<String, dynamic>;
    final fajr =
        ((data['days'] as List).first['prayers'] as List).first
            as Map<String, dynamic>;
    expect(fajr['done'], isTrue);
    expect((data['streak'] as Map)['today'], 1);
  });

  test('a widget tap logs the prayer and republishes', () async {
    final handled = await publisher.handlePrayed(
      Uri.parse('sakeenah://prayed?date=2026-11-26&prayer=fajr'),
    );

    expect(handled, isTrue);
    expect(
      (await log.day('2026-11-26')).statuses[PrayerName.fajr],
      PrayerStatus.onTime,
    );
    expect(bridge.saved, isNotEmpty);
    expect(bridge.updates, hasLength(3));
  });

  test('a tap for a prayer that has not started is ignored', () async {
    final handled = await publisher.handlePrayed(
      Uri.parse('sakeenah://prayed?date=2026-11-26&prayer=dhuhr'),
    );

    expect(handled, isFalse);
    expect((await log.day('2026-11-26')).statuses, isEmpty);
  });

  test('malformed or stale widget taps are ignored', () async {
    expect(await publisher.handlePrayed(Uri.parse('sakeenah://open')), isFalse);
    expect(
      await publisher.handlePrayed(
        Uri.parse('sakeenah://prayed?date=2026-11-20&prayer=fajr'),
      ),
      isFalse,
    );
    expect(
      await publisher.handlePrayed(
        Uri.parse('sakeenah://prayed?date=2026-11-26&prayer=sunrise'),
      ),
      isFalse,
    );
    expect((await log.day('2026-11-26')).statuses, isEmpty);
  });

  test('an unconfigured app publishes a placeholder', () async {
    settings.value = PrayerSettings.defaults();
    await publisher.refresh();

    final data = jsonDecode(
      bridge.saved[PrayerWidgetPublisher.dataKey]!,
    ) as Map<String, dynamic>;
    expect(data['configured'], isFalse);
    expect(bridge.updates, hasLength(3));
    expect(bridge.schedules.values.every((times) => times.isEmpty), isTrue);
  });
}

class _FakeBridge implements WidgetBridge {
  final saved = <String, String>{};
  final updates = <String>[];
  final schedules = <String, List<DateTime>>{};

  @override
  Future<void> saveString(String key, String value) async => saved[key] = value;

  @override
  Future<void> updateWidget(String androidProvider) async =>
      updates.add(androidProvider);

  @override
  Future<void> scheduleUpdates(
    String androidProvider,
    List<DateTime> updateTimes,
  ) async => schedules[androidProvider] = updateTimes;
}
