package com.example.auto_clicker.service

import android.content.ComponentName
import android.content.Context
import android.service.notification.NotificationListenerService
import android.util.Log
import com.example.auto_clicker.media.MediaSessionWatcher

/**
 * Feature B — MediaPlaybackListenerService
 *
 * A NotificationListenerService that hosts [MediaSessionWatcher] (Signal 1).
 * Declared in AndroidManifest.xml with BIND_NOTIFICATION_LISTENER_SERVICE.
 * The user grants "Notification Access" once in System Settings.
 *
 * The service exposes a [sharedInstance] singleton so that other components
 * (AutoClickerService, MainActivity MethodChannel) can call
 * [queryIsVideoPlaying] without holding a reference to the Context.
 *
 * Graceful degradation (FR-B5):
 *   - If the user never grants Notification Access this service is never bound,
 *     so [sharedInstance] remains null. Callers must handle null and fall through
 *     to Signal 2 / 3 detection.
 *   - If the service is later unbound (permission revoked), [sharedInstance]
 *     is set to null — same fallback path.
 */
class MediaPlaybackListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "MediaPlaybackListenerSvc"

        /** Non-null only while Notification Access is granted and the service is bound. */
        var sharedInstance: MediaPlaybackListenerService? = null
            private set

        fun isAvailable(): Boolean = sharedInstance != null
    }

    private lateinit var sessionWatcher: MediaSessionWatcher

    override fun onListenerConnected() {
        super.onListenerConnected()
        sharedInstance = this
        val component = ComponentName(this, MediaPlaybackListenerService::class.java)
        sessionWatcher = MediaSessionWatcher(this, component)
        Log.d(TAG, "MediaPlaybackListenerService connected — Signal 1 active")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        sharedInstance = null
        Log.d(TAG, "MediaPlaybackListenerService disconnected — Signal 1 unavailable")
    }

    override fun onDestroy() {
        sharedInstance = null
        super.onDestroy()
    }

    /**
     * Entry point for the automation engine.
     *
     * Returns true if the app identified by [foregroundPackage] is currently
     * reporting STATE_PLAYING via the MediaSession framework.
     *
     * Returns false if Notification Access is not granted or no active session
     * matches — the caller must proceed to check Signal 2 / 3.
     */
    fun queryIsVideoPlaying(foregroundPackage: String): Boolean {
        return if (::sessionWatcher.isInitialized) {
            sessionWatcher.isForegroundAppPlaying(foregroundPackage)
        } else {
            false
        }
    }
}
