package com.awwad.awwad

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat

/**
 * Handles the native adhan alarm chain:
 *  - ACTION_FIRE: the prayer minute arrived. Re-arm the next alarm FIRST
 *    (nothing may break the chain), then decide honestly what to show:
 *      on time (<= 5 min late)  -> AdhanService plays the adhan + notification
 *      5..30 min late           -> silent "prayer time entered" notification
 *      > 30 min late            -> nothing (a stale adhan is worse than none)
 *    The lateness guard is what kills the two owner-reported bugs at once: a
 *    Doze-deferred alarm can no longer sound half an hour after the prayer,
 *    and it can no longer land in the same delivery batch as a habit reminder
 *    and masquerade as "the habit reminder played the adhan".
 *  - ACTION_STOP / ACTION_SNOOZE: notification action buttons.
 *  - ACTION_SNOOZE_FIRE: the snoozed reminder coming back.
 */
class AdhanAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(ctx: Context, intent: Intent) {
        try {
            when (intent.action) {
                AdhanScheduler.ACTION_FIRE -> onFire(ctx)
                AdhanScheduler.ACTION_STOP -> {
                    AdhanService.stopPlayback(ctx)
                }
                AdhanScheduler.ACTION_SNOOZE -> {
                    val t = intent.getStringExtra("snTitle") ?: return
                    val b = intent.getStringExtra("snBody") ?: ""
                    val m = intent.getIntExtra("snMinutes", 10)
                    AdhanService.stopPlayback(ctx)
                    cancelNotification(ctx)
                    AdhanScheduler.armSnooze(ctx, t, b, m)
                }
                AdhanScheduler.ACTION_SNOOZE_FIRE -> {
                    postPlain(
                        ctx,
                        intent.getStringExtra("title") ?: return,
                        intent.getStringExtra("body") ?: "",
                    )
                }
            }
        } catch (e: Exception) {
            // fail-open, always: a crash here would kill the whole chain
        }
    }

    private fun onFire(ctx: Context) {
        val table = AdhanScheduler.readTable(ctx)
        val now = System.currentTimeMillis()
        // The entry this alarm was armed for = the latest entry whose time has
        // passed. Re-arm the NEXT one before anything else can fail.
        val due = latestDue(table, now)
        AdhanScheduler.rearm(ctx)
        due ?: return
        val late = now - due.optLong("at", now)
        val fresh = late <= 5 * 60_000L
        val stale = late > 30 * 60_000L
        if (stale) return
        val title = (if (fresh) due.optString("title")
            else due.optString("lateTitle", due.optString("title")))
        val body = (if (fresh) due.optString("body")
            else due.optString("lateBody", due.optString("body")))
        if (title.isBlank()) return
        // The background FGS-start exemption rides on the EXACT alarm: with
        // the grant missing this fire came from an inexact alarm and
        // startForegroundService would throw. Skip straight to the fallback
        // (the system plays the adhan as the channel sound, same as the
        // pre-native design) instead of relying on the exception path.
        val exactOk = try {
            android.os.Build.VERSION.SDK_INT < 31 ||
                (ctx.getSystemService(Context.ALARM_SERVICE)
                    as android.app.AlarmManager).canScheduleExactAlarms()
        } catch (e: Exception) {
            false
        }
        if (fresh && exactOk) {
            val started = AdhanService.start(
                ctx,
                title = title,
                body = body,
                prayerKey = due.optString("key"),
                stopLabel = table?.optString("stop") ?: "",
                snoozeLabel = table?.optString("snooze") ?: "",
                snTitle = due.optString("snTitle"),
                snBody = due.optString("snBody"),
                snoozeMinutes = table?.optInt("snoozeMinutes", 10) ?: 10,
            )
            // The service could not start (OEM quirk, race on the grant):
            // fall back to the system playing the adhan from the channel
            // sound. The buttons cannot stop that sound, but a silent prayer
            // time would be worse.
            if (!started) postChannelSoundAdhan(ctx, title, body, due.optString("key"))
        } else if (fresh) {
            // On time but no exact grant: the system plays the channel sound.
            postChannelSoundAdhan(ctx, title, body, due.optString("key"))
        } else {
            postPlain(ctx, title, body, prayerKey = due.optString("key"))
        }
    }

    /** Latest entry whose time is <= now (the one the alarm fired for). */
    private fun latestDue(
        table: org.json.JSONObject?, now: Long
    ): org.json.JSONObject? {
        try {
            val entries = table?.optJSONArray("entries") ?: return null
            var best: org.json.JSONObject? = null
            var bestAt = Long.MIN_VALUE
            for (i in 0 until entries.length()) {
                val e = entries.optJSONObject(i) ?: continue
                val at = e.optLong("at", 0L)
                if (at in 1..now && at > bestAt) {
                    bestAt = at
                    best = e
                }
            }
            return best
        } catch (e: Exception) {
            return null
        }
    }

    private fun cancelNotification(ctx: Context) {
        try {
            val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager
            nm.cancel(AdhanService.NOTIFICATION_ID)
        } catch (e: Exception) {
        }
    }

    /** Silent notification on the no-sound adhan channel (late / snoozed). */
    private fun postPlain(
        ctx: Context, title: String, body: String, prayerKey: String? = null
    ) {
        try {
            val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager
            AdhanService.ensureSilentChannel(ctx)
            val n = NotificationCompat.Builder(ctx, AdhanService.CHANNEL_SILENT)
                .setSmallIcon(R.drawable.ic_stat_awwad)
                .setColor(0xFF4F8EF7.toInt())
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .setContentIntent(AdhanService.tapIntent(ctx, prayerKey))
                .build()
            nm.notify(AdhanService.NOTIFICATION_ID, n)
        } catch (e: Exception) {
        }
    }

    /**
     * Degraded fallback when AdhanService cannot start: the plugin-era adhan
     * channel awwad_adhan_v2 carries the adhan as its CHANNEL sound (alarm
     * usage, DND bypass when granted), so the system plays it for us.
     */
    private fun postChannelSoundAdhan(
        ctx: Context, title: String, body: String, prayerKey: String?
    ) {
        try {
            val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager
            if (android.os.Build.VERSION.SDK_INT >= 26 &&
                nm.getNotificationChannel("awwad_adhan_v2") == null
            ) {
                // Normally created localized from Dart on app open; this is a
                // safety net for a fire that beats the first open. The name
                // comes from the table so it is never English-only.
                val ch = NotificationChannel(
                    "awwad_adhan_v2",
                    AdhanScheduler.readTable(ctx)?.optString("chName")
                        ?.ifBlank { null } ?: "Adhan",
                    NotificationManager.IMPORTANCE_HIGH
                )
                ch.setSound(
                    android.net.Uri.parse(
                        "android.resource://${ctx.packageName}/raw/adhan"
                    ),
                    android.media.AudioAttributes.Builder()
                        .setUsage(android.media.AudioAttributes.USAGE_ALARM)
                        .setContentType(
                            android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION
                        )
                        .build()
                )
                nm.createNotificationChannel(ch)
            }
            val n = NotificationCompat.Builder(ctx, "awwad_adhan_v2")
                .setSmallIcon(R.drawable.ic_stat_awwad)
                .setColor(0xFF4F8EF7.toInt())
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setAutoCancel(true)
                .setContentIntent(AdhanService.tapIntent(ctx, prayerKey))
                .build()
            nm.notify(AdhanService.NOTIFICATION_ID, n)
        } catch (e: Exception) {
        }
    }
}
