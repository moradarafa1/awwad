package com.awwad.awwad

import android.app.AppOpsManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Process
import android.provider.Settings
import java.util.Calendar
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Usage-limit guard: a 15-minute periodic check that posts a warning
        // the moment a limited app crosses its daily screen-time budget, even
        // if Awwad itself is closed. KEEP = never duplicated across launches.
        // Only runs while the user actually HAS limits: with none set the
        // periodic work is cancelled instead of waking every 15 minutes for
        // nothing (it re-enqueues on the next launch after a limit is saved).
        try {
            val wm = androidx.work.WorkManager.getInstance(this)
            val hasLimits = getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            ).getString("flutter.app_usage_limits_v1", null)
                ?.let { it.trim() != "{}" && it.isNotEmpty() } ?: false
            if (hasLimits) {
                wm.enqueueUniquePeriodicWork(
                    "awwad_usage_guard",
                    androidx.work.ExistingPeriodicWorkPolicy.KEEP,
                    androidx.work.PeriodicWorkRequestBuilder<UsageLimitWorker>(
                        java.time.Duration.ofMinutes(15)
                    ).build()
                )
            } else {
                wm.cancelUniqueWork("awwad_usage_guard")
            }
        } catch (e: Exception) {
            // WorkManager unavailable: the in-app checks still work.
        }

        // App-usage monitoring (phone-addiction habit, phase A: read-only).
        // Uses the special PACKAGE_USAGE_STATS permission the user grants in
        // system settings. Everything is fail-open: errors return safe values.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "awwad/usage_stats"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasPermission" -> {
                    try {
                        val appOps =
                            getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
                        val mode = appOps.unsafeCheckOpNoThrow(
                            AppOpsManager.OPSTR_GET_USAGE_STATS,
                            Process.myUid(), packageName
                        )
                        result.success(mode == AppOpsManager.MODE_ALLOWED)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "openSettings" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            startActivity(Intent(Settings.ACTION_SETTINGS))
                            result.success(true)
                        } catch (e2: Exception) {
                            result.success(false)
                        }
                    }
                }
                // Called by the Dart side right after limits are saved so the
                // background guard starts/stops without waiting for the next
                // app launch (mirrors the enqueue gating in configureFlutterEngine).
                "syncGuard" -> {
                    try {
                        val wm = androidx.work.WorkManager.getInstance(this)
                        val hasLimits = getSharedPreferences(
                            "FlutterSharedPreferences", Context.MODE_PRIVATE
                        ).getString("flutter.app_usage_limits_v1", null)
                            ?.let { it.trim() != "{}" && it.isNotEmpty() } ?: false
                        if (hasLimits) {
                            wm.enqueueUniquePeriodicWork(
                                "awwad_usage_guard",
                                androidx.work.ExistingPeriodicWorkPolicy.KEEP,
                                androidx.work.PeriodicWorkRequestBuilder<UsageLimitWorker>(
                                    java.time.Duration.ofMinutes(15)
                                ).build()
                            )
                        } else {
                            wm.cancelUniqueWork("awwad_usage_guard")
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "todayUsage" -> {
                    try {
                        val usm = getSystemService(Context.USAGE_STATS_SERVICE)
                            as UsageStatsManager
                        val cal = Calendar.getInstance().apply {
                            set(Calendar.HOUR_OF_DAY, 0)
                            set(Calendar.MINUTE, 0)
                            set(Calendar.SECOND, 0)
                            set(Calendar.MILLISECOND, 0)
                        }
                        val start = cal.timeInMillis
                        val end = System.currentTimeMillis()
                        val agg = usm.queryAndAggregateUsageStats(start, end)
                        // Per-app open counts from the raw event stream.
                        // Consecutive resumes of the same package are one
                        // "open" (in-app screen changes fire ACTIVITY_RESUMED
                        // too); only a switch from another app counts.
                        val opens = HashMap<String, Int>()
                        try {
                            val resumed =
                                if (android.os.Build.VERSION.SDK_INT >= 29)
                                    UsageEvents.Event.ACTIVITY_RESUMED
                                else
                                    @Suppress("DEPRECATION")
                                    UsageEvents.Event.MOVE_TO_FOREGROUND
                            val events = usm.queryEvents(start, end)
                            val ev = UsageEvents.Event()
                            var lastPkg: String? = null
                            while (events.hasNextEvent()) {
                                events.getNextEvent(ev)
                                if (ev.eventType != resumed) continue
                                val p = ev.packageName ?: continue
                                if (p != lastPkg) {
                                    opens[p] = (opens[p] ?: 0) + 1
                                    lastPkg = p
                                }
                            }
                        } catch (e: Exception) {
                            // Fail-open: rows simply carry opens = 0.
                        }
                        val pm = packageManager
                        val rows = mutableListOf<Map<String, Any>>()
                        for ((pkg, stats) in agg) {
                            if (pkg == packageName) continue
                            val minutes =
                                (stats.totalTimeInForeground / 60000L).toInt()
                            if (minutes < 1) continue
                            // Only user-launchable apps: keeps the list meaningful.
                            if (pm.getLaunchIntentForPackage(pkg) == null) continue
                            val label = try {
                                pm.getApplicationLabel(
                                    pm.getApplicationInfo(pkg, 0)
                                ).toString()
                            } catch (e: Exception) {
                                pkg
                            }
                            rows.add(mapOf(
                                "package" to pkg,
                                "label" to label,
                                "minutes" to minutes,
                                "opens" to (opens[pkg] ?: 0),
                            ))
                        }
                        rows.sortByDescending { it["minutes"] as Int }
                        result.success(rows)
                    } catch (e: Exception) {
                        result.success(emptyList<Map<String, Any>>())
                    }
                }
                else -> result.notImplemented()
            }
        }

        // DNS shield: read the system Private DNS setting (no permission
        // needed for these Settings.Global keys) and open the settings UI so
        // the user can enable a family DNS resolver. Used by the porn-blocking
        // "content shield" feature; reading is fail-open (nulls -> unknown).
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "awwad/dns_shield"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> {
                    try {
                        // Values: "hostname" | "opportunistic" | "off" | null
                        // (null = never configured = opportunistic default).
                        val mode = Settings.Global.getString(
                            contentResolver, "private_dns_mode"
                        ) ?: "opportunistic"
                        val host = Settings.Global.getString(
                            contentResolver, "private_dns_specifier"
                        )
                        result.success(mapOf("mode" to mode, "hostname" to host))
                    } catch (e: Exception) {
                        result.success(mapOf("mode" to "unknown", "hostname" to null))
                    }
                }
                "openSettings" -> {
                    // Try the direct Private DNS panel first (present on most
                    // OEMs even though the action string is not in the public
                    // SDK constants), then fall back to broader screens.
                    val actions = listOf(
                        "android.settings.PRIVATE_DNS_SETTINGS",
                        Settings.ACTION_WIRELESS_SETTINGS,
                        Settings.ACTION_SETTINGS,
                    )
                    var opened = false
                    for (action in actions) {
                        try {
                            startActivity(Intent(action))
                            opened = true
                            break
                        } catch (e: Exception) {
                            // try the next fallback
                        }
                    }
                    result.success(opened)
                }
                else -> result.notImplemented()
            }
        }

        // Reminder reliability helpers: aggressive OEM battery managers
        // (Xiaomi/Oppo/Vivo/Huawei...) kill scheduled alarms. These open the
        // relevant system screens so the user can exempt Awwad. Fail-open.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "awwad/reliability"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "manufacturer" -> result.success(android.os.Build.MANUFACTURER)
                // The adhan channel with DND BYPASS. flutter_local_notifications
                // cannot express setBypassDnd, so the channel is created here and
                // the Dart side just posts to its id. Bypass is only GRANTED if
                // the user gives Awwad "Do Not Disturb access" in system
                // settings; without it Android keeps the channel but ignores the
                // flag, which is a silent, safe degrade.
                "createAdhanChannel" -> {
                    try {
                        if (android.os.Build.VERSION.SDK_INT >= 26) {
                            val nm = getSystemService(NotificationManager::class.java)
                            val ch = NotificationChannel(
                                "awwad_adhan_v2",
                                call.argument<String>("name")
                                    ?: "Adhan (bypasses Do Not Disturb)",
                                NotificationManager.IMPORTANCE_HIGH
                            )
                            ch.description = call.argument<String>("description")
                            ch.setBypassDnd(true)
                            ch.setSound(
                                android.net.Uri.parse(
                                    "android.resource://$packageName/raw/adhan"
                                ),
                                android.media.AudioAttributes.Builder()
                                    .setUsage(android.media.AudioAttributes.USAGE_ALARM)
                                    .setContentType(
                                        android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION
                                    )
                                    .build()
                            )
                            // Deliberately NOT guarded by "channel does not
                            // exist yet". setBypassDnd only takes effect while
                            // the app holds DND policy access, which the user
                            // grants LATER, so this must be re-callable to
                            // apply the flag once it is granted. (Android
                            // ignores importance/sound changes on an existing
                            // channel, so re-calling cannot override the
                            // user's own tuning.)
                            nm.createNotificationChannel(ch)
                            // The v1 channel is dead: leaving it behind shows
                            // two adhan entries in system settings, one inert.
                            try {
                                nm.deleteNotificationChannel("awwad_adhan_v1")
                            } catch (e: Exception) {
                                // nothing to delete on a fresh install
                            }
                            result.success(true)
                        } else {
                            result.success(false) // pre-Oreo has no channels
                        }
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                // Whether the user has granted DND access, so the UI can tell
                // the truth instead of promising a bypass that will not happen.
                "hasDndAccess" -> {
                    try {
                        val nm = getSystemService(NotificationManager::class.java)
                        result.success(nm.isNotificationPolicyAccessGranted)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "openDndAccessSettings" -> {
                    try {
                        startActivity(
                            Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "openNotificationSettings" -> {
                    // Deep link into this app's notification settings (API 26+),
                    // falling back to app details, then general Settings.
                    val intents = listOf(
                        Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                            .putExtra(Settings.EXTRA_APP_PACKAGE, packageName),
                        Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            android.net.Uri.parse("package:$packageName")
                        ),
                        Intent(Settings.ACTION_SETTINGS),
                    )
                    var opened = false
                    for (intent in intents) {
                        try {
                            startActivity(intent)
                            opened = true
                            break
                        } catch (e: Exception) {
                            // try the next fallback
                        }
                    }
                    result.success(opened)
                }
                "openBatterySettings" -> {
                    // The per-OEM "app auto-start / battery saver" screens are
                    // non-public; the stock exemption list + app details are
                    // reliable everywhere.
                    val intents = listOf(
                        Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
                        Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            android.net.Uri.parse("package:$packageName")
                        ),
                        Intent(Settings.ACTION_SETTINGS),
                    )
                    var opened = false
                    for (intent in intents) {
                        try {
                            startActivity(intent)
                            opened = true
                            break
                        } catch (e: Exception) {
                            // try the next fallback
                        }
                    }
                    result.success(opened)
                }
                else -> result.notImplemented()
            }
        }
    }
}
