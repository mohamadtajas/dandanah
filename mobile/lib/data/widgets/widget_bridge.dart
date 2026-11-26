import 'package:home_widget/home_widget.dart';

/// The three Android widget providers.
abstract final class PrayerWidgets {
  static const nextPrayer = 'NextPrayerWidgetProvider';
  static const prayerTimes = 'PrayerTimesWidgetProvider';
  static const streak = 'StreakWidgetProvider';

  static const all = [nextPrayer, prayerTimes, streak];
}

/// Small seam so widget publishing can be tested without platform channels.
abstract interface class WidgetBridge {
  Future<void> saveString(String key, String value);

  Future<void> updateWidget(String androidProvider);

  Future<void> scheduleUpdates(
    String androidProvider,
    List<DateTime> updateTimes,
  );
}

class HomeWidgetBridge implements WidgetBridge {
  const HomeWidgetBridge();

  @override
  Future<void> saveString(String key, String value) async {
    await HomeWidget.saveWidgetData<String>(key, value);
  }

  @override
  Future<void> updateWidget(String androidProvider) async {
    await HomeWidget.updateWidget(androidName: androidProvider);
  }

  @override
  Future<void> scheduleUpdates(
    String androidProvider,
    List<DateTime> updateTimes,
  ) async {
    await HomeWidget.scheduleWidgetUpdates(
      updateTimes,
      androidName: androidProvider,
    );
  }
}
