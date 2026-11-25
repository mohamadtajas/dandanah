import 'dart:convert';

import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../db/app_database.dart';
import '../settings_store.dart';
import 'prayer_method.dart';

/// Persisted calculation and location preferences.
class PrayerSettings {
  const PrayerSettings({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.method = PrayerMethod.ummAlQura,
    this.madhab = PrayerMadhab.shafi,
    this.highLatitude = PrayerHighLatitude.recommended,
    this.hijriAdjustment = 0,
    this.configured = false,
    this.cityId,
  });

  static const storageKey = 'prayer.settings';

  final double latitude;
  final double longitude;
  final String timezone;
  final PrayerMethod method;
  final PrayerMadhab madhab;
  final PrayerHighLatitude highLatitude;
  final int hijriAdjustment;
  final bool configured;
  final String? cityId;

  factory PrayerSettings.defaults({String timezone = 'Asia/Riyadh'}) =>
      PrayerSettings(latitude: 21.4225, longitude: 39.8262, timezone: timezone);

  factory PrayerSettings.fromJson(Map<String, dynamic> json) => PrayerSettings(
    latitude: (json['latitude'] as num?)?.toDouble() ?? 21.4225,
    longitude: (json['longitude'] as num?)?.toDouble() ?? 39.8262,
    timezone: json['timezone'] as String? ?? 'Asia/Riyadh',
    method: PrayerMethod.byId(json['method'] as String? ?? 'ummAlQura'),
    madhab: json['madhab'] == 'hanafi'
        ? PrayerMadhab.hanafi
        : PrayerMadhab.shafi,
    highLatitude: PrayerHighLatitude.byId(
      json['highLatitude'] as String? ?? 'recommended',
    ),
    hijriAdjustment: (json['hijriAdjustment'] as num?)?.toInt() ?? 0,
    configured: json['configured'] as bool? ?? false,
    cityId: json['cityId'] as String?,
  ).sanitized();

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'timezone': timezone,
    'method': method.id,
    'madhab': madhab.name,
    'highLatitude': highLatitude.id,
    'hijriAdjustment': hijriAdjustment,
    'configured': configured,
    'cityId': cityId,
  };

  PrayerSettings copyWith({
    double? latitude,
    double? longitude,
    String? timezone,
    PrayerMethod? method,
    PrayerMadhab? madhab,
    PrayerHighLatitude? highLatitude,
    int? hijriAdjustment,
    bool? configured,
    String? cityId,
    bool clearCity = false,
  }) => PrayerSettings(
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    timezone: timezone ?? this.timezone,
    method: method ?? this.method,
    madhab: madhab ?? this.madhab,
    highLatitude: highLatitude ?? this.highLatitude,
    hijriAdjustment: hijriAdjustment ?? this.hijriAdjustment,
    configured: configured ?? this.configured,
    cityId: clearCity ? null : cityId ?? this.cityId,
  ).sanitized();

  PrayerSettings sanitized() {
    final safeLatitude = latitude.isFinite
        ? latitude.clamp(-90.0, 90.0)
        : 21.4225;
    final safeLongitude = longitude.isFinite
        ? longitude.clamp(-180.0, 180.0)
        : 39.8262;
    return PrayerSettings(
      latitude: safeLatitude,
      longitude: safeLongitude,
      timezone: _validTimezone(timezone) ? timezone : 'Asia/Riyadh',
      method: method,
      madhab: madhab,
      highLatitude: highLatitude,
      hijriAdjustment: hijriAdjustment.clamp(-3, 3),
      configured: configured,
      cityId: cityId,
    );
  }
}

class PrayerSettingsRepository {
  PrayerSettingsRepository(this._db);

  final AppDatabase _db;

  Future<PrayerSettings> load() async {
    final raw = await SettingsStore.read(_db, PrayerSettings.storageKey);
    if (raw != null) {
      try {
        final decoded = PrayerSettings.fromJson(
          Map<String, dynamic>.from(const JsonCodec().decode(raw) as Map),
        );
        if (_validTimezone(decoded.timezone)) return decoded;
      } catch (_) {
        // Corrupt settings fall back to the defaults below.
      }
    }
    return PrayerSettings.defaults();
  }

  Future<void> save(PrayerSettings settings) async {
    final safe = settings.sanitized();
    await SettingsStore.write(
      _db,
      PrayerSettings.storageKey,
      const JsonCodec().encode(safe.toJson()),
    );
  }
}

bool _timezonesReady = false;

void _ensureTimezones() {
  if (_timezonesReady) return;
  tzdata.initializeTimeZones();
  _timezonesReady = true;
}

bool _validTimezone(String name) {
  try {
    _ensureTimezones();
    tz.getLocation(name);
    return true;
  } catch (_) {
    return false;
  }
}
