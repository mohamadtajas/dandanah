package app.sakeenah.mobile.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import app.sakeenah.mobile.R
import es.antonborri.home_widget.HomeWidgetProvider

class NextPrayerWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val snapshot = WidgetData.read(widgetData)
    for (widgetId in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.widget_next_prayer)
      views.setOnClickPendingIntent(R.id.next_root, WidgetIntents.open(context))

      val next = snapshot?.takeIf { it.configured }?.next()
      if (next == null) {
        views.setTextViewText(R.id.next_label, "افتح التطبيق")
        views.setTextViewText(R.id.next_name, "—")
        views.setTextViewText(R.id.next_time, "")
        views.setTextViewText(R.id.next_button, "فتح")
        views.setOnClickPendingIntent(
            R.id.next_button,
            WidgetIntents.open(context),
        )
      } else {
        val (_, prayer) = next
        views.setTextViewText(R.id.next_label, "الصلاة القادمة")
        views.setTextViewText(R.id.next_name, prayer.name)
        views.setTextViewText(R.id.next_time, prayer.time)
        val due = snapshot.lastDue()
        if (due == null) {
          views.setTextViewText(R.id.next_button, "—")
          views.setOnClickPendingIntent(
              R.id.next_button,
              WidgetIntents.open(context),
          )
        } else if (due.second.done) {
          views.setTextViewText(R.id.next_button, "تمت")
          views.setOnClickPendingIntent(
              R.id.next_button,
              WidgetIntents.open(context),
          )
        } else {
          views.setTextViewText(R.id.next_button, "صليت")
          views.setOnClickPendingIntent(
              R.id.next_button,
              WidgetIntents.prayed(context, due.first, due.second),
          )
        }
      }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
