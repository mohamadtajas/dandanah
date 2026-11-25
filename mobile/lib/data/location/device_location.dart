/// One foreground location fix plus the device timezone, if it can be read.
class DeviceLocation {
  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    this.timezone,
  });

  final double latitude;
  final double longitude;

  /// IANA name such as `Asia/Amman`; null when the platform value was invalid.
  final String? timezone;
}

enum LocationFailure { denied, deniedForever, timeout, unavailable }

class LocationResult {
  const LocationResult.success(DeviceLocation value)
    : location = value,
      failure = null;

  const LocationResult.failure(LocationFailure value)
    : location = null,
      failure = value;

  final DeviceLocation? location;
  final LocationFailure? failure;

  bool get isSuccess => location != null;
}
