import 'dart:async';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../worship/timezone_bootstrap.dart';
import 'device_location.dart';

/// Injectable seam over the geolocator plugin so tests never touch platform
/// channels for coordinates.
abstract interface class LocationPlatform {
  Future<LocationPermission> checkPermission();

  Future<LocationPermission> requestPermission();

  Future<Position?> lastKnownPosition();

  Future<Position> currentPosition();

  Future<void> openSettings();
}

class LocationService {
  LocationService({LocationPlatform? platform, MethodChannel? timezoneChannel})
    : _platform = platform ?? const GeolocatorPlatformAdapter(),
      _timezoneChannel =
          timezoneChannel ??
          const MethodChannel('app.sakeenah.mobile/timezone');

  final LocationPlatform _platform;
  final MethodChannel _timezoneChannel;

  Future<LocationResult> currentLocation() async {
    try {
      var permission = await _platform.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _platform.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.failure(LocationFailure.deniedForever);
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        return const LocationResult.failure(LocationFailure.denied);
      }

      final last = await _platform.lastKnownPosition();
      final fresh =
          last != null &&
          DateTime.now().difference(last.timestamp) <
              const Duration(minutes: 10);
      final position = fresh ? last : await _platform.currentPosition();
      final raw = await _timezoneChannel.invokeMethod<String>(
        'getLocalTimezone',
      );
      final timezone = raw != null && isValidTimezone(raw) ? raw : null;
      return LocationResult.success(
        DeviceLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          timezone: timezone,
        ),
      );
    } on TimeoutException {
      return const LocationResult.failure(LocationFailure.timeout);
    } catch (_) {
      return const LocationResult.failure(LocationFailure.unavailable);
    }
  }

  Future<void> openAppSettings() => _platform.openSettings();
}

class GeolocatorPlatformAdapter implements LocationPlatform {
  const GeolocatorPlatformAdapter();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<Position?> lastKnownPosition() => Geolocator.getLastKnownPosition();

  @override
  Future<Position> currentPosition() => Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: Duration(seconds: 12),
    ),
  );

  @override
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }
}
