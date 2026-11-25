import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/local_date.dart';

bool _ready = false;

/// Loads the full IANA database, including link names used by the desktop
/// city presets (`Asia/Kuwait`, `Asia/Muscat`, `UTC`, ...).
void ensureTimezones() {
  if (_ready) return;
  tzdata.initializeTimeZones();
  _ready = true;
}

bool isValidTimezone(String name) {
  ensureTimezones();
  try {
    tz.getLocation(name);
    return true;
  } catch (_) {
    return false;
  }
}

tz.Location locationFor(String name) {
  ensureTimezones();
  return tz.getLocation(isValidTimezone(name) ? name : 'UTC');
}

/// The calendar day the user is experiencing in their configured timezone.
String dateKeyInTimezone(String name, {DateTime? now}) {
  final local = tz.TZDateTime.from(
    (now ?? DateTime.now()).toUtc(),
    locationFor(name),
  );
  return localDateKey(local);
}

List<String> allTimezoneNames() {
  ensureTimezones();
  return tz.timeZoneDatabase.locations.keys.toList()..sort();
}
