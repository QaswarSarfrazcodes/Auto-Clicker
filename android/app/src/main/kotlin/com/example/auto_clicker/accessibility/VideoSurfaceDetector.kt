package com.example.auto_clicker.accessibility

import android.graphics.Rect
import android.util.Log
import android.view.accessibility.AccessibilityNodeInfo

/**
 * Signal 2 — AccessibilityNodeInfo view-class detection.
 *
 * The app already holds the Accessibility permission for gesture dispatch,
 * so this signal is completely free — no new permission needed.
 *
 * Strategy: BFS-walk the active window's node tree looking for a surface or
 * player node that covers at least 35% of the total screen area. The area
 * threshold filters out small avatar/thumbnail TextureViews that would otherwise
 * be false-positives.
 *
 * Known player view classes per app (verify against app version — see §6 of
 * solution.md for the maintenance note):
 *   Instagram (Reels/feed)  → TextureView inside VideoContainer
 *   TikTok                  → GLSurfaceView or TextureView inside ss.android...VideoView
 *   YouTube / YT Shorts     → androidx.media3.ui.PlayerView (or legacy ExoPlayer2 PlayerView)
 *   Facebook Reels          → com.facebook...RichVideoPlayer wrapping TextureView
 */
object VideoSurfaceDetector {

    private const val TAG = "VideoSurfaceDetector"

    /** Exact surface-rendering view classes that host video content on Android. */
    private val SURFACE_CLASSES = setOf(
        "android.view.TextureView",
        "android.view.SurfaceView",
        "android.opengl.GLSurfaceView",
    )

    /**
     * Substring hints in class names that indicate a dedicated video player
     * container — matched case-insensitively.
     */
    private val PLAYER_CLASS_HINTS = listOf(
        "PlayerView",
        "VideoView",
        "ExoPlayerView",
        "RichVideoPlayer",
        "VideoContainer",
        "VideoPlayer",
        "MediaPlayer",
    )

    /**
     * Returns true if the current foreground window contains a video surface
     * node whose bounding rect covers at least [minScreenFraction] of the total
     * screen area [screenArea] (in px²).
     *
     * [root] must NOT be recycled by the caller before this method returns.
     */
    fun findLikelyVideoSurface(
        root: AccessibilityNodeInfo,
        screenArea: Int,
        minScreenFraction: Float = 0.35f,
    ): Boolean {
        val queue = ArrayDeque<AccessibilityNodeInfo>().apply { add(root) }
        val visited = mutableSetOf<AccessibilityNodeInfo>()

        while (queue.isNotEmpty()) {
            val node = queue.removeFirst()
            if (!visited.add(node)) continue

            val className = node.className?.toString() ?: ""

            val isSurfaceClass = SURFACE_CLASSES.any { className == it }
            val isHintedClass = PLAYER_CLASS_HINTS.any { className.contains(it, ignoreCase = true) }

            if (isSurfaceClass || isHintedClass) {
                val bounds = Rect()
                node.getBoundsInScreen(bounds)
                val nodeArea = bounds.width() * bounds.height()

                if (screenArea > 0 && nodeArea >= screenArea * minScreenFraction) {
                    Log.d(TAG, "Video surface detected: class=$className area=$nodeArea screenArea=$screenArea")
                    return true
                }
            }

            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { queue.add(it) }
            }
        }
        return false
    }
}
