import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sakeenah_mobile/data/location/device_location.dart';
import 'package:sakeenah_mobile/data/location/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/location-timezone');
  final now = DateTime.now();

  Position position() => Position(
    latitude: 31.9539,
    longitude: 35.9106,
    timestamp: now,
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  void mockTimezone(String? value) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method != 'getLocalTimezone') return null;
          return value;
        });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('returns coordinates and a valid IANA timezone', () async {
    mockTimezone('Asia/Amman');
    final result = await LocationService(
      platform: _FakePlatform(position: position()),
      timezoneChannel: channel,
    ).currentLocation();

    expect(result.isSuccess, isTrue);
    expect(result.location!.latitude, closeTo(31.9539, 1e-6));
    expect(result.location!.longitude, closeTo(35.9106, 1e-6));
    expect(result.location!.timezone, 'Asia/Amman');
  });

  test('keeps coordinates but drops an invalid timezone', () async {
    mockTimezone('Not/AZone');
    final result = await LocationService(
      platform: _FakePlatform(position: position()),
      timezoneChannel: channel,
    ).currentLocation();

    expect(result.isSuccess, isTrue);
    expect(result.location!.timezone, isNull);
  });

  test('maps denied permission to a failure', () async {
    mockTimezone('Asia/Amman');
    final result = await LocationService(
      platform: _FakePlatform(
        position: position(),
        permission: LocationPermission.denied,
      ),
      timezoneChannel: channel,
    ).currentLocation();

    expect(result.location, isNull);
    expect(result.failure, LocationFailure.denied);
  });

  test('maps denied forever to a failure', () async {
    mockTimezone('Asia/Amman');
    final result = await LocationService(
      platform: _FakePlatform(
        position: position(),
        permission: LocationPermission.deniedForever,
      ),
      timezoneChannel: channel,
    ).currentLocation();

    expect(result.failure, LocationFailure.deniedForever);
  });

  test('uses a fresh last known fix without waiting for GPS', () async {
    mockTimezone('Asia/Amman');
    final platform = _FakePlatform(position: position(), currentThrows: true)
      ..lastKnown = position();
    final result = await LocationService(
      platform: platform,
      timezoneChannel: channel,
    ).currentLocation();

    expect(result.isSuccess, isTrue);
    expect(platform.currentCalls, 0);
  });
}

class _FakePlatform implements LocationPlatform {
  _FakePlatform({
    required this.position,
    this.permission = LocationPermission.whileInUse,
    this.currentThrows = false,
  });

  final Position position;
  final LocationPermission permission;
  final bool currentThrows;
  Position? lastKnown;
  int currentCalls = 0;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position?> lastKnownPosition() async => lastKnown;

  @override
  Future<Position> currentPosition() async {
    currentCalls++;
    if (currentThrows) throw StateError('no current fix');
    return position;
  }

  @override
  Future<void> openSettings() async {}
}
