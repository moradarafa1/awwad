package com.awwad.awwad

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar
import java.util.Locale

/**
 * Home-screen widget: active habit name + streak + a quick-log button.
 * All texts are PRE-LOCALIZED and pushed by the Dart side (HomeWidgetSync);
 * this class only lays them out. The one piece of native logic is the
 * midnight rollover: data saved on a previous day must not keep showing
 * today as already logged, so the saved dayKey is compared with the current
 * date and the button falls back to its "log now" state on a new day.
 */
class AwwadWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.awwad_widget).apply {
                val name = widgetData.getString("aw_name", null) ?: "عوّاد"
                val streak = widgetData.getString("aw_streak", null)
                    ?: "افتح التطبيق لبدء سلسلتك"
                val savedDate = widgetData.getString("aw_date", null)
                val logged = widgetData.getBoolean("aw_logged", false) &&
                    savedDate == todayKey()
                val btn = if (logged) {
                    widgetData.getString("aw_btn_done", null) ?: "سُجّل اليوم"
                } else {
                    widgetData.getString("aw_btn_log", null) ?: "سجّل هذا اليوم"
                }

                setTextViewText(R.id.aw_name, name)
                setTextViewText(R.id.aw_streak, streak)
                setTextViewText(R.id.aw_btn, btn)
                setInt(
                    R.id.aw_btn, "setBackgroundResource",
                    if (logged) R.drawable.awwad_widget_btn_done
                    else R.drawable.awwad_widget_btn
                )
                setTextColor(
                    R.id.aw_btn,
                    if (logged) 0xFF2DD4BF.toInt() else 0xFF0A0E14.toInt()
                )

                // Tapping the card opens the app.
                setOnClickPendingIntent(
                    R.id.aw_container,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                )
                // The button quick-logs in the background while a habit
                // exists and today is unlogged; otherwise (already logged, or
                // no habit yet: a background log would be a dead tap) it
                // opens the app.
                val hasHabit = widgetData.getBoolean("aw_has", false)
                setOnClickPendingIntent(
                    R.id.aw_btn,
                    if (hasHabit && !logged) {
                        HomeWidgetBackgroundIntent.getBroadcast(
                            context, Uri.parse("awwad://quicklog")
                        )
                    } else {
                        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                    }
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /** Must produce the same yyyy-MM-dd string as Dart's dayKey(). Explicitly
     *  Gregorian: Calendar.getInstance() follows the device locale and would
     *  return Buddhist/Japanese years on those devices, so the saved Dart
     *  date would never match and the logged state would never display. */
    private fun todayKey(): String {
        val cal = java.util.GregorianCalendar()
        return String.format(
            Locale.US, "%04d-%02d-%02d",
            cal.get(Calendar.YEAR),
            cal.get(Calendar.MONTH) + 1,
            cal.get(Calendar.DAY_OF_MONTH),
        )
    }
}
