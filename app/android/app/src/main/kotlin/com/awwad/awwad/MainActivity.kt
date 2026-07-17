package com.awwad.awwad

import android.app.AppOpsManager
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
        try {
            androidx.work.WorkManager.getInstance(this).enqueueUniquePeriodicWork(
                "awwad_usage_guard",
                androidx.work.ExistingPeriodicWorkPolicy.KEEP,
                androidx.work.PeriodicWorkRequestBuilder<UsageLimitWorker>(
                    java.time.Duration.ofMinutes(15)
                ).build()
            )
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
