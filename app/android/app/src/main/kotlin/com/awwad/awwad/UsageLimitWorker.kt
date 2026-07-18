package com.awwad.awwad

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.NotificationCompat
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONObject
import java.util.Calendar

/**
 * Background guard for the phone-addiction feature: every ~15 minutes it
 * compares today's per-app screen time against the limits the user set in
 * Awwad and posts a warning notification the moment an app crosses its limit.
 *
 * Pure native on purpose: it reads the limits Flutter saved to
 * SharedPreferences ("flutter." prefix) and needs no Dart isolate, so it works
 * even when the app process is dead. Everything is fail-open: any error means
 * "no warning this cycle", never a crash.
 */
class UsageLimitWorker(ctx: Context, params: WorkerParameters) :
    Worker(ctx, params) {

    override fun doWork(): Result {
        try {
            val ctx = applicationContext
            val flutterPrefs =
                ctx.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            // Limits map: {"com.instagram.android": 30, ...} (minutes/day).
            val rawLimits =
                flutterPrefs.getString("flutter.app_usage_limits_v1", null)
                    ?: return Result.success()
            val limits = JSONObject(rawLimits)
            if (limits.length() == 0) return Result.success()

            // Today's usage since local midnight.
            val cal = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
            }
            val usm =
                ctx.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val usage = usm.queryAndAggregateUsageStats(
                cal.timeInMillis, System.currentTimeMillis()
            )

            // Locale for the notification text: read the app's saved locale.
            val loc = try {
                val settings = flutterPrefs.getString("flutter.awwad_settings", null)
                if (settings != null) JSONObject(settings).optString("locale", "ar")
                else "ar"
            } catch (e: Exception) { "ar" }

            val own = ctx.getSharedPreferences("awwad_usage_guard", Context.MODE_PRIVATE)
            val today = "${cal.get(Calendar.YEAR)}-${cal.get(Calendar.DAY_OF_YEAR)}"
            val pm = ctx.packageManager

            for (key in limits.keys()) {
                val limitMin = limits.optInt(key, 0)
                if (limitMin <= 0) continue
                val usedMin =
                    ((usage[key]?.totalTimeInForeground ?: 0L) / 60000L).toInt()
                if (usedMin < limitMin) continue

                // One warning per app per day.
                val flag = "notified_${key}_$today"
                if (own.getBoolean(flag, false)) continue

                val label = try {
                    pm.getApplicationLabel(pm.getApplicationInfo(key, 0)).toString()
                } catch (e: PackageManager.NameNotFoundException) { key }

                notify(ctx, key.hashCode(), loc, label, usedMin, limitMin)
                own.edit().putBoolean(flag, true).apply()
            }
            return Result.success()
        } catch (e: Exception) {
            return Result.success() // fail-open: never retry-storm, never crash
        }
    }

    private fun notify(
        ctx: Context, id: Int, loc: String, app: String, used: Int, limit: Int
    ) {
        val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (android.os.Build.VERSION.SDK_INT >= 26) {
            nm.createNotificationChannel(
                NotificationChannel(
                    "awwad_usage_guard", "Usage limits",
                    NotificationManager.IMPORTANCE_HIGH
                )
            )
        }
        val title = when (loc) {
            "en" -> "Time limit reached"
            "fr" -> "Limite de temps atteinte"
            else -> "بلغت حد الاستخدام"
        }
        val body = when (loc) {
            "en" -> "$app: $used min today (your limit is $limit). Time to step away."
            "fr" -> "$app : $used min aujourd'hui (limite $limit). Faites une pause."
            else -> "$app: استخدمته $used دقيقة اليوم (حددت $limit). حان وقت التوقف، أنت أقوى من العادة."
        }
        val n = NotificationCompat.Builder(ctx, "awwad_usage_guard")
            .setSmallIcon(R.drawable.ic_stat_awwad)
            .setColor(0xFF4F8EF7.toInt())
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()
        try { nm.notify(id, n) } catch (e: Exception) { /* permission off */ }
    }
}
