package app.sakeenah.mobile.widgets

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import app.sakeenah.mobile.R
import es.antonborri.home_widget.HomeWidgetProvider

class StreakWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val snapshot = WidgetData.read(widgetData)
    val configured = snapshot?.configured == true
    for (widgetId in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.widget_streak)
      views.setOnClickPendingIntent(R.id.streak_root, WidgetIntents.open(context))
      views.setTextViewText(
          R.id.streak_current,
          if (configured) "${snapshot?.current ?: 0}" else "—",
      )
      views.setTextViewText(
          R.id.streak_today,
          if (configured) {
            "اليوم: ${snapshot?.todayCount ?: 0} / ${snapshot?.goal ?: 5}"
          } else {
            "اضبط موقعك"
          },
      )
      views.setTextViewText(
          R.id.streak_best,
          if (configured) "أفضل سلسلة: ${snapshot?.best ?: 0}" else "",
      )
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
