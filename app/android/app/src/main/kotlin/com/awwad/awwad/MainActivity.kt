package com.awwad.awwad

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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
    }
}
