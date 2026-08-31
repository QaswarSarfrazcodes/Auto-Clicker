package com.example.auto_clicker.media

import android.content.ComponentName
import android.content.Context
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.util.Log

/**
 * Signal 1 — MediaSession playback state.
 *
 * Reads the authoritative PlaybackState that Instagram/TikTok/YouTube/Facebook
 * already publish to the OS (they need it for lock-screen controls and Android
 * Auto). Does NOT poll pixels — it reads a field the app explicitly set.
 *
 * Requires Notification Access (BIND_NOTIFICATION_LISTENER_SERVICE) granted
 * once by the user. If the permission is absent, every method returns false and
 * the caller silently falls through to Signal 2/3 (graceful degradation, FR-B5).
 */
class MediaSessionWatcher(
    private val context: Context,
    private val notificationListenerComponent: ComponentName,
) {
    companion object {
        private const val TAG = "MediaSessionWatcher"
    }

    private val sessionManager: MediaSessionManager by lazy {
        context.getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
    }

    /**
     * Returns true if ANY active media session reports STATE_PLAYING.
     * Use [isForegroundAppPlaying] instead to avoid false-positives from a
     * background music app (e.g. Spotify) running while the user browses Instagram.
     */
    fun isAnyMediaPlaying(): Boolean {
        return activeSessions()?.any { controller ->
            controller.playbackState?.state == PlaybackState.STATE_PLAYING
        } ?: false
    }

    /**
     * Returns true if the app identified by [foregroundPackage] (or any active video/social app)
     * currently reports STATE_PLAYING via MediaSession.
     */
    fun isForegroundAppPlaying(foregroundPackage: String): Boolean {
        val sessions = activeSessions() ?: return false
        return sessions.any { controller ->
            val pkg = controller.packageName ?: ""
            val isTargetApp = foregroundPackage.isEmpty() ||
                    pkg == foregroundPackage ||
                    pkg.contains("facebook", ignoreCase = true) ||
                    pkg.contains("instagram", ignoreCase = true) ||
                    pkg.contains("youtube", ignoreCase = true) ||
                    pkg.contains("tiktok", ignoreCase = true) ||
                    pkg.contains("twitter", ignoreCase = true)
            isTargetApp && controller.playbackState?.state == PlaybackState.STATE_PLAYING
        }
    }

    /**
     * Returns the list of active MediaControllers, or null if Notification
     * Access has not been granted (SecurityException is swallowed intentionally —
     * the caller must treat null as "signal unavailable, try next signal").
     */
    private fun activeSessions(): List<android.media.session.MediaController>? {
        return try {
            sessionManager.getActiveSessions(notificationListenerComponent)
        } catch (e: SecurityException) {
            // Notification Listener permission not granted yet.
            // Caller falls back to Signal 2 / 3 — never crashes.
            Log.d(TAG, "Notification Access not granted; Signal 1 unavailable: ${e.message}")
            null
        } catch (e: Exception) {
            Log.w(TAG, "Unexpected error reading active sessions: ${e.message}")
            null
        }
    }
}
