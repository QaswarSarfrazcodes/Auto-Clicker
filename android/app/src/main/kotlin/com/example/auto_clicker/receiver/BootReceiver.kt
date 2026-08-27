package com.example.auto_clicker.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Listens for system boot completion (ACTION_BOOT_COMPLETED) (§18).
 * Checks the launch_on_startup preference written by Flutter before engine startup.
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        // Read launch_on_startup flag written directly into SharedPreferences by Flutter
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val launchOnStartup = prefs.getBoolean("flutter.launch_on_startup_enabled", true) &&
                prefs.getBoolean("launch_on_startup", true)

        Log.d(TAG, "Boot completed received. launch_on_startup=$launchOnStartup")

        if (!launchOnStartup) return

        // Note: Per design / safety posture, we do NOT automatically run scripts on boot.
        // The user must explicitly choose to run a script.
    }
}
