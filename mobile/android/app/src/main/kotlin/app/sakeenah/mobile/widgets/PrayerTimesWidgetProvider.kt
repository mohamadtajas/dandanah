package app.sakeenah.mobile.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import app.sakeenah.mobile.R
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerTimesWidgetProvider : HomeWidgetProvider() {
  private val nameIds =
      intArrayOf(
          R.id.row_name_1,
          R.id.row_name_2,
          R.id.row_name_3,
          R.id.row_name_4,
          R.id.row_name_5,
      )
  private val timeIds =
      intArrayOf(
          R.id.row_time_1,
          R.id.row_time_2,
          R.id.row_time_3,
          R.id.row_time_4,
          R.id.row_time_5,
      )
  private val checkIds =
      intArrayOf(
          R.id.row_check_1,
          R.id.row_check_2,
          R.id.row_check_3,
          R.id.row_check_4,
          R.id.row_check_5,
      )

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val snapshot = WidgetData.read(widgetData)
    for (widgetId in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.widget_prayer_times)
      views.setOnClickPendingIntent(R.id.times_root, WidgetIntents.open(context))

      val day = snapshot?.takeIf { it.configured }?.todayDay()
      if (day == null) {
        views.setTextViewText(R.id.times_hijri, "افتح التطبيق")
        for (index in nameIds.indices) {
          views.setTextViewText(nameIds[index], "")
          views.setTextViewText(timeIds[index], "")
          views.setTextViewText(checkIds[index], "")
        }
      } else {
        views.setTextViewText(R.id.times_hijri, day.hijri)
        for (index in nameIds.indices) {
          val prayer = day.prayers.getOrNull(index)
          views.setTextViewText(nameIds[index], prayer?.name ?: "")
          views.setTextViewText(timeIds[index], prayer?.time ?: "")
          views.setTextViewText(
              checkIds[index],
              if (prayer?.done == true) "✓" else "",
          )
        }
      }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
