package com.awwad.awwad

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import org.json.JSONObject

/**
 * Native adhan alarm chain. Dart computes the prayer times (the astronomical
 * engine stays in ONE place) and writes a ~30-day table to
 * FlutterSharedPreferences under "flutter.adhan_native_v1"; this object arms
 * exactly ONE AlarmManager alarm for the next entry and re-arms after each
 * fire (and after boot). Native so the adhan works with the app process dead,
 * and so the SOUND is played by AdhanService (our own MediaPlayer), which is
 * the only way a hardware button press can stop it - a channel sound is played
 * by the system and cannot be stopped without cancelling the notification.
 *
 * Everything here is fail-open: a parse error or a missing permission arms
 * nothing and never crashes.
 */
object AdhanScheduler {

    const val PREFS_KEY = "flutter.adhan_native_v1"
    const val ACTION_FIRE = "com.awwad.awwad.ADHAN_FIRE"
    const val ACTION_STOP = "com.awwad.awwad.ADHAN_STOP"
    const val ACTION_SNOOZE = "com.awwad.awwad.ADHAN_SNOOZE"
    const val ACTION_SNOOZE_FIRE = "com.awwad.awwad.ADHAN_SNOOZE_FIRE"

    private const val REQ_MAIN = 6001
    private const val REQ_SNOOZE = 6002

    /** The whole stored table, or null when absent/corrupt. */
    fun readTable(ctx: Context): JSONObject? = try {
        val raw = ctx.getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE
        ).getString(PREFS_KEY, null)
        if (raw.isNullOrBlank()) null else JSONObject(raw)
    } catch (e: Exception) {
        null
    }

    /** The next entry with at > [after], or null. */
    fun nextEntry(table: JSONObject?, after: Long): JSONObject? {
        try {
            val entries = table?.optJSONArray("entries") ?: return null
            var best: JSONObject? = null
            var bestAt = Long.MAX_VALUE
            for (i in 0 until entries.length()) {
                val e = entries.optJSONObject(i) ?: continue
                val at = e.optLong("at", 0L)
                if (at > after && at < bestAt) {
                    bestAt = at
                    best = e
                }
            }
            return best
        } catch (e: Exception) {
            return null
        }
    }

    /** The entry whose "at" equals [at] exactly (the one an alarm fired for). */
    fun entryAt(table: JSONObject?, at: Long): JSONObject? {
        try {
            val entries = table?.optJSONArray("entries") ?: return null
            for (i in 0 until entries.length()) {
                val e = entries.optJSONObject(i) ?: continue
                if (e.optLong("at", -1L) == at) return e
            }
            return null
        } catch (e: Exception) {
            return null
        }
    }

    private fun canExact(am: AlarmManager): Boolean =
        if (android.os.Build.VERSION.SDK_INT >= 31) {
            try {
                am.canScheduleExactAlarms()
            } catch (e: Exception) {
                false
            }
        } else true

    /**
     * (Re)arms the single upcoming adhan alarm from the stored table.
     * Cancels first, so calling it repeatedly is always safe. An empty or
     * missing table simply cancels (that is how Dart disables the adhan).
     */
    fun rearm(ctx: Context) {
        try {
            val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val pi = mainPendingIntent(ctx)
            am.cancel(pi)
            val next = nextEntry(readTable(ctx), System.currentTimeMillis())
                ?: return
            val at = next.optLong("at", 0L)
            if (at <= 0L) return
            if (canExact(am)) {
                // Exact + allow-while-idle: fires at the prayer minute even in
                // Doze. This is the whole point of the SCHEDULE_EXACT_ALARM
                // grant the UI asks for.
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
            } else {
                // Grant missing or revoked: inexact but still Doze-piercing.
                // The receiver's lateness guard keeps a deferred fire honest
                // (no adhan sound half an hour after the prayer).
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
            }
        } catch (e: Exception) {
            // fail-open: no alarm this round; the next app open re-arms
        }
    }

    private fun mainPendingIntent(ctx: Context): PendingIntent {
        val i = Intent(ctx, AdhanAlarmReceiver::class.java).setAction(ACTION_FIRE)
        return PendingIntent.getBroadcast(
            ctx, REQ_MAIN, i,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    /**
     * Arms the one-off snoozed-prayer reminder [minutes] from now. The snoozed
     * copy ("a reminder, the window is still open") is passed through rather
     * than re-read: re-firing the original "it is prayer time NOW" text later
     * would state something false.
     */
    fun armSnooze(ctx: Context, title: String, body: String, minutes: Int) {
        try {
            val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val at = System.currentTimeMillis() + minutes * 60_000L
            val i = Intent(ctx, AdhanAlarmReceiver::class.java)
                .setAction(ACTION_SNOOZE_FIRE)
                .putExtra("title", title)
                .putExtra("body", body)
            val pi = PendingIntent.getBroadcast(
                ctx, REQ_SNOOZE, i,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            // Inexact on purpose: a snooze minutes-scale reminder does not
            // justify exactness, and this must work without the grant.
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
        } catch (e: Exception) {
            // fail-open
        }
    }
}
