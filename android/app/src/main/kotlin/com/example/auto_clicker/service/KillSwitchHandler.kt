package com.example.auto_clicker.service

import android.view.KeyEvent

/**
 * Intercepts KEYCODE_VOLUME_DOWN system-wide via AccessibilityService onKeyEvent.
 * Acts as an emergency hardware kill-switch to immediately halt runaway scripts (§0c).
 *
 * Guard: only consumes the key event when a script is actively running so the
 * user's volume buttons work normally when no automation is in progress.
 */
object KillSwitchHandler {
    /** Set to true when a script starts, false when it stops. */
    var isScriptRunning: Boolean = false

    var onEmergencyStop: (() -> Unit)? = null

    fun handle(event: KeyEvent?): Boolean {
        if (!isScriptRunning) return false // Don't intercept when no script is running
        if (event == null) return false
        if (event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN && event.action == KeyEvent.ACTION_DOWN) {
            onEmergencyStop?.invoke()
            return true // Consume event so volume doesn't change mid-script
        }
        return false
    }
}
