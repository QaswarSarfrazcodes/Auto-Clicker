package com.example.auto_clicker.service

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Intent
import android.graphics.Path
import android.os.Build
import android.util.Log
import android.util.DisplayMetrics
import android.view.accessibility.AccessibilityEvent
import com.example.auto_clicker.accessibility.VideoSurfaceDetector
import com.example.auto_clicker.media.AudioPlaybackConfigWatcher

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

    // -------------------------------------------------------------------------
    // Feature B — Video-Aware Scroll Hold
    // -------------------------------------------------------------------------

    /**
     * Returns true if a video is currently playing on screen.
     *
     * Signal cascade:
     *   Signal 1 — MediaSession PlaybackState (authoritative OS media session)
     *   Signal 2 — Accessibility node tree (VideoSurfaceDetector with 25% threshold)
     *   Signal 3 — AudioPlaybackConfiguration (active USAGE_MEDIA audio confirmation)
     */
    fun queryVideoPlayback(foregroundPackage: String = ""): Boolean {
        val activePkg = if (foregroundPackage.isNotEmpty()) {
            foregroundPackage
        } else {
            rootInActiveWindow?.packageName?.toString() ?: ""
        }

        // Signal 1 — MediaSession Playback State
        val listenerService = MediaPlaybackListenerService.sharedInstance
        if (listenerService != null && listenerService.queryIsVideoPlaying(activePkg)) {
            Log.d(TAG, "Video detected via Signal 1 (MediaSession) for $activePkg")
            return true
        }

        // Signal 3 — Audio Playback (Active media audio output)
        val audioWatcher = AudioPlaybackConfigWatcher(applicationContext)
        val isAudioPlaying = audioWatcher.isAnyMediaAudioActive()

        // Signal 2 — Accessibility node tree surface detection
        val root = rootInActiveWindow
        if (root != null) {
            val metrics = DisplayMetrics()
            @Suppress("DEPRECATION")
            val display = windowManager?.defaultDisplay
            display?.getMetrics(metrics)
            val screenArea = metrics.widthPixels * metrics.heightPixels

            val hasSurface = VideoSurfaceDetector.findLikelyVideoSurface(root, screenArea, 0.25f)
            if (hasSurface && isAudioPlaying) {
                Log.d(TAG, "Video detected via Signal 2+3 (surface + active audio) for $activePkg")
                return true
            }
        }

        // Corroboration: Active media audio while on a known video app (Facebook/YouTube/TikTok)
        if (isAudioPlaying && (activePkg.contains("facebook") || activePkg.contains("instagram") || activePkg.contains("youtube") || activePkg.contains("tiktok") || activePkg.isEmpty())) {
            Log.d(TAG, "Video detected via Signal 3 (Active Media Audio in video app) for $activePkg")
            return true
        }

        return false
    }

    private val windowManager: android.view.WindowManager?
        get() = getSystemService(WINDOW_SERVICE) as? android.view.WindowManager
}
