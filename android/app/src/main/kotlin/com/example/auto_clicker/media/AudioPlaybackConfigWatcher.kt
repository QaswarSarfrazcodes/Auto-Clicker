package com.example.auto_clicker.media

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.os.Build
import android.util.Log

/**
 * Signal 3 — AudioPlaybackConfiguration tiebreaker.
 *
 * Reads [AudioManager.getActivePlaybackConfigurations] (API 26+) to confirm
 * that at least one app is actively routing USAGE_MEDIA audio output.
 *
 * IMPORTANT — public SDK limitation:
 *   [AudioPlaybackConfiguration.getClientUid()] is a @hide internal API and
 *   is therefore NOT available in the public SDK. Signal 3 can only tell us
 *   "something is playing audio with USAGE_MEDIA" — not which specific package.
 *   That is fine: this signal is used only as a tiebreaker to confirm Signal 2
 *   (a large video surface was found via the accessibility tree). The foreground-
 *   package scope is already handled by Signal 1 (MediaSession). Combining
 *   Signal 2 (video surface present) + Signal 3 (audio active system-wide) is
 *   enough to distinguish a playing video from a static UI with a large SurfaceView.
 *
 * This signal is NOT usable alone:
 *   - Muted autoplay videos (common on Reels/Shorts) won't show here.
 *   - A background music app (Spotify) makes this return true even when the
 *     foreground app is showing a static image.
 *   Callers must always combine Signal 3 with Signal 2 as a guard.
 *
 * No permission required — [AudioManager.getActivePlaybackConfigurations] is
 * open to all apps from API 26 onward.
 */
class AudioPlaybackConfigWatcher(private val context: Context) {

    companion object {
        private const val TAG = "AudioPlaybackConfigWatcher"
    }

    private val audioManager: AudioManager by lazy {
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    /**
     * Returns true if ANY app is currently playing USAGE_MEDIA audio.
     *
     * Use this only as a tiebreaker after Signal 2 (video surface detected) has
     * already returned true. On API < 26 always returns false.
     */
    fun isAnyMediaAudioActive(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            // AudioManager.getActivePlaybackConfigurations() requires API 26+
            return false
        }
        return try {
            audioManager.activePlaybackConfigurations.any { config ->
                config.audioAttributes.usage == AudioAttributes.USAGE_MEDIA
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error reading active playback configurations: ${e.message}")
            false
        }
    }
}

