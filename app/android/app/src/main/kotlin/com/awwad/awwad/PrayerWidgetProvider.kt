package com.awwad.awwad

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.util.Calendar
import java.util.GregorianCalendar

/**
 * PRAYER home-screen widget: the next prayer, a LIVE countdown to the adhan,
 * the Hijri date and today's five times.
 *
 * Every user-visible STRING is pushed pre-localized by the Dart side
 * (PrayerWidgetSync.push) because the widget must follow the APP language,
 * which can differ from the device's. Two things are computed here instead,
 * and only because they cannot be pushed:
 *
 *  1. The COUNTDOWN. A RemoteViews tree cannot tick and the widget update
 *     floor is 30 minutes, so any pushed "01:12 left" would be a lie within a
 *     minute. A Chronometer in countdown mode is ticked by the SYSTEM
 *     process, second by second, with the app never woken.
 *  2. The HIJRI DATE. A pushed string would go stale at the first midnight,
 *     so only the twelve month NAMES are pushed and the Umm al-Qura
 *     conversion runs here at render time (android.icu, API 24+, minSdk is
 *     24). ICU carries the official Umm al-Qura tables, so this matches the
 *     Saudi calendar rather than an arithmetic approximation of it.
 *
 * The card is redrawn at the exact moments it stops being true: every prayer
 * entry (the countdown must roll to the next prayer) and every midnight (the
 * Hijri date rolls over). See [armTick].
 */
class PrayerWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val now = System.currentTimeMillis()
        val entries = parseEntries(widgetData.getString("pw_times", null))
        val names = parseNames(widgetData.getString("pw_names", null))
        val order = (widgetData.getString("pw_order", null) ?: "")
            .split(",").map { it.trim() }.filter { it.isNotEmpty() }
        // The pushed table covers 30 days; running past its end is the same
        // "no data" case as never having configured a location.
        val next = entries.firstOrNull { it.at > now }
        val has = widgetData.getBoolean("pw_has", false) && next != null
        val hijri = hijriLine(widgetData)
        val today = timesToday(entries, now)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.prayer_widget).apply {
                // Tapping the card opens the app on the prayer screen.
                setOnClickPendingIntent(
                    R.id.pw_container,
                    HomeWidgetLaunchIntent.getActivity(
                        context, MainActivity::class.java,
                        Uri.parse("awwad://prayer"),
                    )
                )
                if (hijri.isEmpty()) {
                    setViewVisibility(R.id.pw_hijri, View.GONE)
                } else {
                    setViewVisibility(R.id.pw_hijri, View.VISIBLE)
                    setTextViewText(R.id.pw_hijri, hijri)
                }
                if (!has || next == null) {
                    setViewVisibility(R.id.pw_next, View.GONE)
                    setViewVisibility(R.id.pw_countdown, View.GONE)
                    setViewVisibility(R.id.pw_row, View.GONE)
                    setViewVisibility(R.id.pw_empty, View.VISIBLE)
                    setTextViewText(
                        R.id.pw_empty,
                        widgetData.getString("pw_empty", null)
                            ?: "حدّد موقعك من إعدادات الصلاة"
                    )
                } else {
                    setViewVisibility(R.id.pw_empty, View.GONE)
                    setViewVisibility(R.id.pw_next, View.VISIBLE)
                    setViewVisibility(R.id.pw_countdown, View.VISIBLE)
                    setViewVisibility(R.id.pw_row, View.VISIBLE)
                    val label = widgetData.getString("pw_next", null) ?: ""
                    val name = names[next.key] ?: next.key
                    // ONE string on purpose: Android's bidi algorithm then
                    // puts an Arabic name on the right and a Latin one on the
                    // left by itself, with no locale-dependent layout switch.
                    setTextViewText(
                        R.id.pw_next,
                        if (label.isBlank()) "$name  ${next.hhmm}"
                        else "$label: $name  ${next.hhmm}"
                    )
                    setChronometerCountDown(R.id.pw_countdown, true)
                    setChronometer(
                        R.id.pw_countdown,
                        // Chronometer counts in the elapsedRealtime timebase,
                        // not wall clock.
                        SystemClock.elapsedRealtime() + (next.at - now),
                        null,
                        true,
                    )
                    fillRow(this, order, today, names, next.key)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
        armTick(context, nextTick(next?.at, now))
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        // Our own refresh alarm, plus the system's "your card just went
        // stale" broadcasts. Android 8+ withholds most implicit broadcasts
        // from manifest receivers and the exception list has moved between
        // releases, so these are treated as a BONUS, never as the mechanism:
        // whatever the OS declines to deliver is still covered by the tick
        // alarm armed in onUpdate.
        when (intent.action) {
            ACTION_TICK,
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_LOCALE_CHANGED,
            -> refresh(context)
        }
    }

    /** First widget placed: draw it and start the refresh chain. */
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        refresh(context)
    }

    /** Last widget removed: stop waking the device for nothing. */
    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        armTick(context, 0L)
    }

    // --- rendering helpers ---------------------------------------------

    private fun fillRow(
        v: RemoteViews,
        order: List<String>,
        today: Map<String, String>,
        names: Map<String, String>,
        nextKey: String,
    ) {
        val keys = if (order.size == 5) order else CHRONOLOGICAL
        for (i in 0 until 5) {
            val k = keys[i]
            val isNext = k == nextKey
            v.setTextViewText(NAME_IDS[i], names[k] ?: k)
            v.setTextViewText(TIME_IDS[i], today[k] ?: "--:--")
            v.setTextColor(NAME_IDS[i], if (isNext) TEAL else MUTED)
            v.setTextColor(TIME_IDS[i], if (isNext) TEAL else DIM)
        }
    }

    /**
     * «12 صفر 1448 هـ · مكة المكرمة». Empty (and the line hidden) if the
     * month names were never pushed or ICU refuses the conversion.
     */
    private fun hijriLine(d: SharedPreferences): String {
        val months = (d.getString("pw_hmonths", null) ?: "").split("|")
        if (months.size != 12) return ""
        val suffix = (d.getString("pw_hsuffix", null) ?: "").trim()
        val city = (d.getString("pw_city", null) ?: "").trim()
        val date = try {
            val cal = android.icu.util.IslamicCalendar()
            cal.setCalculationType(
                android.icu.util.IslamicCalendar.CalculationType.ISLAMIC_UMALQURA
            )
            cal.timeInMillis = System.currentTimeMillis()
            val y = cal.get(android.icu.util.Calendar.YEAR)
            val m = cal.get(android.icu.util.Calendar.MONTH)
            val day = cal.get(android.icu.util.Calendar.DAY_OF_MONTH)
            if (m < 0 || m > 11) "" else "$day ${months[m]} $y $suffix".trim()
        } catch (e: Exception) {
            ""
        }
        if (date.isEmpty()) return ""
        return if (city.isEmpty()) date else "$date  ·  $city"
    }

    /** The five times of the CURRENT day, keyed by prayer. */
    private fun timesToday(entries: List<Slot>, now: Long): Map<String, String> {
        val today = dayOf(now)
        val out = LinkedHashMap<String, String>()
        for (e in entries) if (dayOf(e.at) == today) out[e.key] = e.hhmm
        return out
    }

    /** yyyyMMdd in the DEVICE timezone, explicitly Gregorian: a locale
     *  calendar (Buddhist, Japanese) would never match the pushed days. */
    private fun dayOf(ms: Long): Int {
        val c = GregorianCalendar()
        c.timeInMillis = ms
        return c.get(Calendar.YEAR) * 10000 +
            (c.get(Calendar.MONTH) + 1) * 100 +
            c.get(Calendar.DAY_OF_MONTH)
    }

    /**
     * The next moment the card stops being true: the next prayer (the
     * countdown must roll over to the one after it) or the next midnight (the
     * Hijri date changes), whichever comes first.
     */
    private fun nextTick(nextAt: Long?, now: Long): Long {
        val c = GregorianCalendar()
        c.timeInMillis = now
        c.add(Calendar.DAY_OF_MONTH, 1)
        c.set(Calendar.HOUR_OF_DAY, 0)
        c.set(Calendar.MINUTE, 0)
        c.set(Calendar.SECOND, 5)
        c.set(Calendar.MILLISECOND, 0)
        val midnight = c.timeInMillis
        // +2s: fire just AFTER the prayer, so the entry is already in the past
        // and the next one is picked.
        val prayer = if (nextAt == null) Long.MAX_VALUE else nextAt + 2000L
        return minOf(prayer, midnight)
    }

    private fun armTick(ctx: Context, at: Long) {
        try {
            val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pi = tickIntent(ctx)
            am.cancel(pi)
            if (at <= 0L || at == Long.MAX_VALUE) return
            // INEXACT on purpose. Redrawing a card does not justify the
            // SCHEDULE_EXACT_ALARM grant (Play restricts it to time-critical
            // alerts, and the adhan already owns the app's one exact alarm).
            // allow-while-idle still pierces Doze, and the Chronometer keeps
            // counting inside the system process meanwhile, so a few minutes
            // of slack are invisible to the user.
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
        } catch (e: Exception) {
            // fail-open: the OS still redraws every updatePeriodMillis, and
            // the adhan chain refreshes us at every prayer.
        }
    }

    private data class Slot(val at: Long, val key: String, val hhmm: String)

    /** "epoch|key|HH:mm,..." as pushed by Dart, ascending by time. */
    private fun parseEntries(raw: String?): List<Slot> {
        if (raw.isNullOrBlank()) return emptyList()
        val out = ArrayList<Slot>()
        for (part in raw.split(",")) {
            val f = part.split("|")
            if (f.size != 3) continue
            val at = f[0].toLongOrNull() ?: continue
            if (at <= 0L || f[1].isBlank()) continue
            out.add(Slot(at, f[1], f[2]))
        }
        out.sortBy { it.at }
        return out
    }

    /** "fajr=الفجر,dhuhr=..." as pushed by Dart. */
    private fun parseNames(raw: String?): Map<String, String> {
        if (raw.isNullOrBlank()) return emptyMap()
        val out = HashMap<String, String>()
        for (part in raw.split(",")) {
            val i = part.indexOf('=')
            if (i <= 0 || i == part.length - 1) continue
            out[part.substring(0, i)] = part.substring(i + 1)
        }
        return out
    }

    companion object {
        const val ACTION_TICK = "com.awwad.awwad.PRAYER_WIDGET_TICK"
        private const val REQ_TICK = 6101

        private val CHRONOLOGICAL =
            listOf("fajr", "dhuhr", "asr", "maghrib", "isha")
        private val NAME_IDS = intArrayOf(
            R.id.pw_n0, R.id.pw_n1, R.id.pw_n2, R.id.pw_n3, R.id.pw_n4
        )
        private val TIME_IDS = intArrayOf(
            R.id.pw_t0, R.id.pw_t1, R.id.pw_t2, R.id.pw_t3, R.id.pw_t4
        )
        private val TEAL = 0xFF2DD4BF.toInt()
        private val MUTED = 0xFF94A3B8.toInt()
        private val DIM = 0xFFCBD5E1.toInt()

        /**
         * Redraws every placed instance. Safe to call from anywhere and cheap
         * when no widget exists; the native adhan chain calls it at every
         * prayer, which is what keeps the card exact even when Doze defers
         * our own inexact refresh alarm.
         */
        fun refresh(ctx: Context) {
            try {
                val mgr = AppWidgetManager.getInstance(ctx) ?: return
                val ids = mgr.getAppWidgetIds(
                    ComponentName(ctx, PrayerWidgetProvider::class.java)
                )
                if (ids == null || ids.isEmpty()) return
                ctx.sendBroadcast(
                    Intent(ctx, PrayerWidgetProvider::class.java)
                        .setAction(AppWidgetManager.ACTION_APPWIDGET_UPDATE)
                        .putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                )
            } catch (e: Exception) {
                // fail-open
            }
        }

        private fun tickIntent(ctx: Context): PendingIntent {
            val i = Intent(ctx, PrayerWidgetProvider::class.java)
                .setAction(ACTION_TICK)
            return PendingIntent.getBroadcast(
                ctx, REQ_TICK, i,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
    }
}
