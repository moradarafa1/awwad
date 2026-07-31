package com.awwad.awwad

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat

/**
 * Plays the adhan itself (foreground service, mediaPlayback type) instead of
 * letting the system play a channel sound. That inversion is what the owner's
 * requirement needs: ANY hardware button press (volume up/down, power) must
 * stop the sound instantly, and only a sound WE play can be stopped by us.
 *
 * Stop triggers, all of which stop the SOUND but keep the prayer notification
 * in the shade (alarm-clock behaviour, phase 0.6 item 2.1):
 *  - volume key press (android.media.VOLUME_CHANGED_ACTION broadcast)
 *  - power button (ACTION_SCREEN_OFF / ACTION_SCREEN_ON)
 *  - the notification's stop action button
 *  - playback completing naturally
 *
 * The sound plays on the ALARM stream (USAGE_ALARM): loud, controlled by the
 * alarm volume, and audible through Do Not Disturb under the default policy.
 */
class AdhanService : Service() {

    companion object {
        const val CHANNEL_SILENT = "awwad_adhan_fg_v1"
        const val NOTIFICATION_ID = 6100

        @Volatile
        private var instance: AdhanService? = null

        /** True when [start] managed to start the service. */
        fun start(
            ctx: Context,
            title: String,
            body: String,
            prayerKey: String?,
            stopLabel: String,
            snoozeLabel: String,
            snTitle: String?,
            snBody: String?,
            snoozeMinutes: Int,
        ): Boolean {
            return try {
                val i = Intent(ctx, AdhanService::class.java)
                    .putExtra("title", title)
                    .putExtra("body", body)
                    .putExtra("key", prayerKey)
                    .putExtra("stop", stopLabel)
                    .putExtra("snooze", snoozeLabel)
                    .putExtra("snTitle", snTitle)
                    .putExtra("snBody", snBody)
                    .putExtra("snoozeMinutes", snoozeMinutes)
                if (android.os.Build.VERSION.SDK_INT >= 26) {
                    ctx.startForegroundService(i)
                } else {
                    ctx.startService(i)
                }
                true
            } catch (e: Exception) {
                // ForegroundServiceStartNotAllowedException when the exact
                // grant is missing (no background-start exemption): the caller
                // falls back to the channel-sound notification.
                false
            }
        }

        /** Stops the sound if the service is running. Safe to call always. */
        fun stopPlayback(ctx: Context) {
            try {
                instance?.finish(keepNotification = true)
            } catch (e: Exception) {
            }
        }

        /**
         * Channel names are USER-FACING text (Android Settings shows them),
         * so the localized [name]/[description] come from the Dart-written
         * table, never a hardcoded language. Re-called on every fire ON
         * PURPOSE: createNotificationChannel updates the NAME of an existing
         * channel (never its behaviour), so a language switch relabels it.
         */
        fun ensureSilentChannel(
            ctx: Context, name: String? = null, description: String? = null
        ) {
            if (android.os.Build.VERSION.SDK_INT < 26) return
            try {
                val nm = ctx.getSystemService(NotificationManager::class.java)
                val table = AdhanScheduler.readTable(ctx)
                val ch = NotificationChannel(
                    CHANNEL_SILENT,
                    name ?: table?.optString("chName")?.ifBlank { null }
                        ?: "Adhan",
                    NotificationManager.IMPORTANCE_HIGH
                )
                ch.description =
                    description ?: table?.optString("chDesc") ?: ""
                // NO channel sound: the service's own MediaPlayer is the sound.
                ch.setSound(null, null)
                ch.enableVibration(false)
                // Bypass only takes effect if the user granted DND access;
                // harmless otherwise (same contract as awwad_adhan_v2).
                ch.setBypassDnd(true)
                nm.createNotificationChannel(ch)
            } catch (e: Exception) {
            }
        }

        /** Opens the app; the payload routes like a tapped FLN prayer alert. */
        fun tapIntent(ctx: Context, prayerKey: String?): PendingIntent {
            val payload =
                if (prayerKey.isNullOrBlank()) "prayer" else "prayer:$prayerKey"
            val i = Intent(ctx, MainActivity::class.java)
                .setAction(Intent.ACTION_MAIN)
                .addCategory(Intent.CATEGORY_LAUNCHER)
                .addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                )
                .putExtra(MainActivity.EXTRA_ADHAN_TAP, payload)
            return PendingIntent.getActivity(
                ctx, 6110, i,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
    }

    private var player: MediaPlayer? = null
    private var buttonsReceiver: BroadcastReceiver? = null
    private var session: android.media.session.MediaSession? = null
    private var finished = false

    // Kept from onStartCommand so finish() can re-post the notification
    // without the no-longer-relevant stop button once the sound has ended.
    private var nTitle = ""
    private var nBody = ""
    private var nKey: String? = null
    private var nSnooze = ""
    private var nSnTitle = ""
    private var nSnBody = ""
    private var nSnoozeMinutes = 10

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        instance = this
        // RE-ENTRANCY (adversarial review 2026-08-01): a second start can
        // reach a LIVE instance (a clock set backward re-fires the same entry
        // while the first adhan still plays). Tear the previous playback down
        // first, or the old MediaPlayer keeps playing with no reference and
        // no button can ever stop it; and reset [finished] or the new sound
        // becomes unstoppable instead.
        teardownPlayback()
        finished = false
        try {
            nTitle = intent?.getStringExtra("title") ?: ""
            nBody = intent?.getStringExtra("body") ?: ""
            nKey = intent?.getStringExtra("key")
            nSnooze = intent?.getStringExtra("snooze").orEmpty()
            nSnTitle = intent?.getStringExtra("snTitle").orEmpty()
            nSnBody = intent?.getStringExtra("snBody").orEmpty()
            nSnoozeMinutes = intent?.getIntExtra("snoozeMinutes", 10) ?: 10
            val stopLabel = intent?.getStringExtra("stop").orEmpty()
            ensureSilentChannel(this)
            startForeground(
                NOTIFICATION_ID,
                buildNotification(stopLabel = stopLabel, playing = true)
            )
            startSound()
            registerButtonListeners()
            startVolumeKeySession()
        } catch (e: Exception) {
            // KEEP the notification (fail-open): the prayer time DID enter;
            // only the sound failed. Erasing it here would leave the user
            // with nothing at all for that prayer, and the receiver's
            // channel-sound fallback cannot cover this (start() already
            // returned true).
            finish(keepNotification = true)
        }
        return START_NOT_STICKY
    }

    /** Releases player + receivers + session without touching the
     *  foreground state. Used by [finish] and by re-entrant starts. */
    private fun teardownPlayback() {
        try {
            buttonsReceiver?.let { unregisterReceiver(it) }
        } catch (e: Exception) {
        }
        buttonsReceiver = null
        try {
            session?.release()
        } catch (e: Exception) {
        }
        session = null
        try {
            player?.stop()
        } catch (e: Exception) {
        }
        try {
            player?.release()
        } catch (e: Exception) {
        }
        player = null
    }

    private fun startSound() {
        val p = MediaPlayer()
        player = p
        p.setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
        )
        // Keeps the CPU alive while the screen is off mid-adhan.
        p.setWakeMode(this, PowerManager.PARTIAL_WAKE_LOCK)
        val afd = resources.openRawResourceFd(R.raw.adhan)
        p.setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
        afd.close()
        p.setOnCompletionListener { finish(keepNotification = true) }
        p.setOnErrorListener { _, _, _ ->
            finish(keepNotification = true)
            true
        }
        p.prepare()
        p.start()
    }

    /**
     * "Any hardware button stops the sound." Volume keys surface as the
     * VOLUME_CHANGED_ACTION broadcast while the alarm stream is active; the
     * power button surfaces as SCREEN_OFF (or SCREEN_ON when the screen was
     * already off). Context-registered on purpose: these actions cannot be
     * received from the manifest, and we only care while sound is playing.
     */
    private fun registerButtonListeners() {
        val r = object : BroadcastReceiver() {
            override fun onReceive(c: Context?, i: Intent?) {
                finish(keepNotification = true)
            }
        }
        buttonsReceiver = r
        val f = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction("android.media.VOLUME_CHANGED_ACTION")
        }
        registerReceiver(r, f)
    }

    /**
     * PRIMARY volume-key interception: an active MediaSession routed to a
     * remote VolumeProvider receives the volume keys (public SDK behaviour,
     * and unlike the VOLUME_CHANGED_ACTION fallback it has no dead zone when
     * the alarm stream is already at max or min). While the session is active
     * a key press reaches onAdjustVolume instead of changing any volume,
     * which is exactly the alarm-clock contract: the button stops the sound.
     */
    private fun startVolumeKeySession() {
        try {
            val s = android.media.session.MediaSession(this, "awwad_adhan")
            s.setPlaybackState(
                android.media.session.PlaybackState.Builder()
                    .setState(
                        android.media.session.PlaybackState.STATE_PLAYING,
                        0L, 1f
                    )
                    .build()
            )
            s.setPlaybackToRemote(object : android.media.VolumeProvider(
                VOLUME_CONTROL_RELATIVE, 100, 50
            ) {
                override fun onAdjustVolume(direction: Int) {
                    // direction 0 is a "show UI" poll, not a key press.
                    if (direction != 0) finish(keepNotification = true)
                }
            })
            s.isActive = true
            session = s
        } catch (e: Exception) {
            // The broadcast receiver fallback still covers the volume keys.
        }
    }

    private fun buildNotification(
        stopLabel: String, playing: Boolean
    ): android.app.Notification {
        val b = NotificationCompat.Builder(this, CHANNEL_SILENT)
            .setSmallIcon(R.drawable.ic_stat_awwad)
            .setColor(0xFF4F8EF7.toInt())
            .setContentTitle(nTitle)
            .setContentText(nBody)
            .setStyle(NotificationCompat.BigTextStyle().bigText(nBody))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setContentIntent(tapIntent(this, nKey))
            .setOnlyAlertOnce(true)
        if (playing && stopLabel.isNotBlank()) {
            val si = Intent(this, AdhanAlarmReceiver::class.java)
                .setAction(AdhanScheduler.ACTION_STOP)
            b.addAction(
                0, stopLabel,
                PendingIntent.getBroadcast(
                    this, 6111, si,
                    PendingIntent.FLAG_UPDATE_CURRENT or
                        PendingIntent.FLAG_IMMUTABLE
                )
            )
        }
        // The snooze survives the sound ending: "remind me of this prayer in
        // N minutes" is meaningful either way. Handled by the RECEIVER, so it
        // keeps working after this service is long dead.
        if (nSnooze.isNotBlank() && nSnTitle.isNotBlank()) {
            val si = Intent(this, AdhanAlarmReceiver::class.java)
                .setAction(AdhanScheduler.ACTION_SNOOZE)
                .putExtra("snTitle", nSnTitle)
                .putExtra("snBody", nSnBody)
                .putExtra("snMinutes", nSnoozeMinutes)
            b.addAction(
                0, nSnooze,
                PendingIntent.getBroadcast(
                    this, 6112, si,
                    PendingIntent.FLAG_UPDATE_CURRENT or
                        PendingIntent.FLAG_IMMUTABLE
                )
            )
        }
        if (!playing) b.setAutoCancel(true)
        return b.build()
    }

    /**
     * Stops the sound and the foreground state. With [keepNotification] the
     * shade entry stays (silenced, dismissible, stop button gone) - stopping
     * the SOUND must not erase the fact that the prayer time entered.
     */
    @Synchronized
    fun finish(keepNotification: Boolean) {
        if (finished) return
        finished = true
        teardownPlayback()
        try {
            if (android.os.Build.VERSION.SDK_INT >= 24) {
                stopForeground(
                    if (keepNotification) STOP_FOREGROUND_DETACH
                    else STOP_FOREGROUND_REMOVE
                )
            } else {
                @Suppress("DEPRECATION")
                stopForeground(!keepNotification)
            }
            if (keepNotification && nTitle.isNotBlank()) {
                val nm = getSystemService(Context.NOTIFICATION_SERVICE)
                    as NotificationManager
                nm.notify(
                    NOTIFICATION_ID,
                    buildNotification(stopLabel = "", playing = false)
                )
            }
        } catch (e: Exception) {
        }
        stopSelf()
    }

    override fun onDestroy() {
        // Belt and braces: if the system kills the service, release the player.
        if (!finished) finish(keepNotification = true)
        instance = null
        super.onDestroy()
    }
}
