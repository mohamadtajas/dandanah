import 'package:adhan/adhan.dart' as adhan;

/// Clockwise bearing in degrees from true north towards the Kaaba.
double qiblaBearing(double latitude, double longitude) {
  const kaabaLatitude = 21.4225241;
  const kaabaLongitude = 39.8261818;
  if ((latitude - kaabaLatitude).abs() < 0.0001 &&
      (longitude - kaabaLongitude).abs() < 0.0001) {
    return 0;
  }
  final direction = adhan.Qibla(adhan.Coordinates(latitude, longitude))
      .direction;
  return direction % 360;
}
