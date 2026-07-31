package com.awwad.awwad

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * AlarmManager alarms do not survive a reboot; the stored adhan table does.
 * Re-arm the chain after boot (and after an app update, which also clears
 * alarms). Mirrors flutter_local_notifications' own boot receiver above it in
 * the manifest. NO foreground service is started here - Android 15 restricts
 * that from BOOT_COMPLETED - only an alarm is scheduled, which is allowed.
 */
class AdhanBootReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            // Wall-clock or timezone changed: the stored epoch moments are
            // still correct, but the armed alarm may now be mis-timed.
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            // The user granted «Alarms and reminders»: upgrade the armed
            // alarm to exact right away (docs: handle like BOOT_COMPLETED).
            "android.app.action.SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED",
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON" ->
                AdhanScheduler.rearm(ctx)
        }
    }
}
