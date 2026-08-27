package com.example.auto_clicker.service

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.graphics.Path
import android.os.Build
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class AutoClickerService : AccessibilityService() {

    companion object {
        const val TAG = "AutoClickerService"
        var sharedInstance: AutoClickerService? = null
            private set

        fun isServiceRunning(): Boolean {
            return sharedInstance != null
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        sharedInstance = this
        Log.d(TAG, "AutoClickerService connected successfully")
    }

    override fun onUnbind(intent: Intent?): Boolean {
        sharedInstance = null
        Log.d(TAG, "AutoClickerService unbound")
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        sharedInstance = null
        super.onDestroy()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // No event interception needed — we only perform gesture dispatching
    }

    override fun onKeyEvent(event: android.view.KeyEvent?): Boolean {
        if (KillSwitchHandler.handle(event)) {
            return true
        }
        return super.onKeyEvent(event)
    }

    override fun onInterrupt() {
        Log.d(TAG, "AutoClickerService interrupted")
    }

    fun dispatchClick(x: Float, y: Float, durationMs: Long = 50L, callback: ((Boolean) -> Unit)? = null) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            callback?.invoke(false)
            return
        }

        // On Android, a Path MUST have a non-zero length stroke for AccessibilityService to inject touch events.
        val path = Path().apply {
            moveTo(x, y)
            lineTo(x, y + 1f)
        }

        val stroke = GestureDescription.StrokeDescription(path, 0, durationMs.coerceAtLeast(1L))
        val gesture = GestureDescription.Builder().addStroke(stroke).build()

        var callbackCalled = false
        val gestureCallback = object : GestureResultCallback() {
            override fun onCompleted(gestureDescription: GestureDescription?) {
                super.onCompleted(gestureDescription)
                if (!callbackCalled) {
                    callbackCalled = true
                    callback?.invoke(true)
                }
            }

            override fun onCancelled(gestureDescription: GestureDescription?) {
                super.onCancelled(gestureDescription)
                if (!callbackCalled) {
                    callbackCalled = true
                    callback?.invoke(false)
                }
            }
        }

        val dispatched = dispatchGesture(gesture, gestureCallback, null)
        if (!dispatched && !callbackCalled) {
            callbackCalled = true
            callback?.invoke(false)
        }
    }

    fun dispatchSwipe(
        startX: Float,
        startY: Float,
        endX: Float,
        endY: Float,
        durationMs: Long = 300L,
        callback: ((Boolean) -> Unit)? = null
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            callback?.invoke(false)
            return
        }

        val path = Path().apply {
            moveTo(startX, startY)
            lineTo(endX, endY)
        }

        val stroke = GestureDescription.StrokeDescription(path, 0, durationMs.coerceAtLeast(1L))
        val gesture = GestureDescription.Builder().addStroke(stroke).build()

        var callbackCalled = false
        val gestureCallback = object : GestureResultCallback() {
            override fun onCompleted(gestureDescription: GestureDescription?) {
                super.onCompleted(gestureDescription)
                if (!callbackCalled) {
                    callbackCalled = true
                    callback?.invoke(true)
                }
            }

            override fun onCancelled(gestureDescription: GestureDescription?) {
                super.onCancelled(gestureDescription)
                if (!callbackCalled) {
                    callbackCalled = true
                    callback?.invoke(false)
                }
            }
        }

        val dispatched = dispatchGesture(gesture, gestureCallback, null)
        if (!dispatched && !callbackCalled) {
            callbackCalled = true
            callback?.invoke(false)
        }
    }
}
