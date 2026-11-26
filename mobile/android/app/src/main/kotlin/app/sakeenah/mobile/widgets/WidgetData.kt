package app.sakeenah.mobile.widgets

import android.app.PendingIntent
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import app.sakeenah.mobile.MainActivity
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import org.json.JSONObject
import java.time.LocalDate

internal data class WidgetPrayer(
    val id: String,
    val name: String,
    val time: String,
    val at: Long,
    val done: Boolean,
)

internal data class WidgetDay(
    val date: String,
    val hijri: String,
    val prayers: List<WidgetPrayer>,
)

internal data class WidgetSnapshot(
    val configured: Boolean,
    val today: String,
    val hijri: String,
    val days: List<WidgetDay>,
    val current: Int,
    val best: Int,
    val todayCount: Int,
    val goal: Int,
) {
  fun next(now: Long = System.currentTimeMillis()): Pair<WidgetDay, WidgetPrayer>? {
    var best: Pair<WidgetDay, WidgetPrayer>? = null
    for (day in days) {
      for (prayer in day.prayers) {
        if (prayer.at <= now) continue
        if (best == null || prayer.at < best.second.at) best = day to prayer
      }
    }
    return best
  }

  /** The most recent prayer whose time has arrived, used by the prayed button. */
  fun lastDue(now: Long = System.currentTimeMillis()): Pair<WidgetDay, WidgetPrayer>? {
    var best: Pair<WidgetDay, WidgetPrayer>? = null
    for (day in days) {
      for (prayer in day.prayers) {
        if (prayer.at > now) continue
        if (best == null || prayer.at > best.second.at) best = day to prayer
      }
    }
    return best
  }

  fun todayDay(): WidgetDay? =
      days.firstOrNull { it.date == LocalDate.now().toString() }
          ?: days.firstOrNull { it.date == today }
          ?: days.firstOrNull()
}

internal object WidgetData {
  const val KEY = "sakeenah_widget_v1"

  fun read(prefs: SharedPreferences): WidgetSnapshot? {
    val raw = prefs.getString(KEY, null) ?: return null
    return try {
      val json = JSONObject(raw)
      val configured = json.optBoolean("configured", false)
      val daysJson = json.optJSONArray("days")
      val days = mutableListOf<WidgetDay>()
      if (daysJson != null) {
        for (index in 0 until daysJson.length()) {
          val day = daysJson.getJSONObject(index)
          val prayersJson = day.optJSONArray("prayers") ?: continue
          val prayers = mutableListOf<WidgetPrayer>()
          for (prayerIndex in 0 until prayersJson.length()) {
            val prayer = prayersJson.getJSONObject(prayerIndex)
            prayers.add(
                WidgetPrayer(
                    id = prayer.optString("id"),
                    name = prayer.optString("name"),
                    time = prayer.optString("time"),
                    at = prayer.optLong("at"),
                    done = prayer.optBoolean("done"),
                ),
            )
          }
          days.add(
              WidgetDay(
                  date = day.optString("date"),
                  hijri = day.optString("hijri"),
                  prayers = prayers,
              ),
          )
        }
      }
      val streak = json.optJSONObject("streak")
      WidgetSnapshot(
          configured = configured,
          today = json.optString("today"),
          hijri = json.optString("hijri"),
          days = days,
          current = streak?.optInt("current") ?: 0,
          best = streak?.optInt("best") ?: 0,
          todayCount = streak?.optInt("today") ?: 0,
          goal = streak?.optInt("goal") ?: 5,
      )
    } catch (_: Exception) {
      null
    }
  }
}

internal object WidgetIntents {
  fun open(context: Context): PendingIntent =
      HomeWidgetLaunchIntent.getActivity(
          context,
          MainActivity::class.java,
          Uri.parse("sakeenah://open"),
      )

  fun prayed(
      context: Context,
      day: WidgetDay,
      prayer: WidgetPrayer,
  ): PendingIntent =
      HomeWidgetLaunchIntent.getActivity(
          context,
          MainActivity::class.java,
          Uri.parse("sakeenah://prayed?date=${day.date}&prayer=${prayer.id}"),
      )
}
