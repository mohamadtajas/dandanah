import 'package:drift/drift.dart';

import '../db/app_database.dart' as db;
import '../worship/prayer_log.dart';
import '../worship/prayer_times_service.dart';

abstract interface class PrayerLogRepository {
  Future<PrayerDay> day(String date);

  Future<List<PrayerDay>> allDays();

  Future<void> setStatus(String date, PrayerName prayer, PrayerStatus? status);

  Future<void> setExcused(String date, bool excused);

  Future<PrayerStreak> streak(String todayKey);
}

class DriftPrayerLogRepository implements PrayerLogRepository {
  DriftPrayerLogRepository(this._db);

  final db.AppDatabase _db;

  @override
  Future<PrayerDay> day(String date) async {
    final rows = await (_db.select(
      _db.prayerLogs,
    )..where((row) => row.date.equals(date))).get();
    return _dayFromRows(date, rows);
  }

  @override
  Future<List<PrayerDay>> allDays() async {
    final rows = await _db.select(_db.prayerLogs).get();
    final grouped = <String, List<db.PrayerLog>>{};
    for (final row in rows) {
      grouped.putIfAbsent(row.date, () => []).add(row);
    }
    return [
      for (final entry in grouped.entries) _dayFromRows(entry.key, entry.value),
    ];
  }

  @override
  Future<void> setStatus(
    String date,
    PrayerName prayer,
    PrayerStatus? status,
  ) async {
    await _db.transaction(() async {
      final current = await day(date);
      if (current.excused) {
        await (_db.delete(
          _db.prayerLogs,
        )..where((row) => row.date.equals(date))).go();
      }

      if (status == null) {
        await (_db.delete(_db.prayerLogs)..where(
              (row) => row.date.equals(date) & row.prayer.equals(prayer.id),
            ))
            .go();
        return;
      }

      await _db
          .into(_db.prayerLogs)
          .insertOnConflictUpdate(
            db.PrayerLogsCompanion.insert(
              date: date,
              prayer: prayer.id,
              status: status.id,
            ),
          );
    });
  }

  @override
  Future<void> setExcused(String date, bool excused) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.prayerLogs,
      )..where((row) => row.date.equals(date))).go();
      if (!excused) return;

      await _db.batch((batch) {
        batch.insertAll(_db.prayerLogs, [
          for (final prayer in obligatoryPrayers)
            db.PrayerLogsCompanion.insert(
              date: date,
              prayer: prayer.id,
              status: PrayerStatus.excused.id,
            ),
        ]);
      });
    });
  }

  @override
  Future<PrayerStreak> streak(String todayKey) async =>
      computePrayerStreak(await allDays(), todayKey);

  PrayerDay _dayFromRows(String date, List<db.PrayerLog> rows) {
    final statuses = <PrayerName, PrayerStatus>{};
    for (final row in rows) {
      PrayerName? prayer;
      for (final candidate in PrayerName.values) {
        if (candidate.id == row.prayer) {
          prayer = candidate;
          break;
        }
      }
      if (prayer == null) continue;
      statuses[prayer] = PrayerStatus.byId(row.status);
    }
    return PrayerDay(date: date, statuses: statuses);
  }
}
