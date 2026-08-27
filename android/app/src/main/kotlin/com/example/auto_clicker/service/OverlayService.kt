package com.example.auto_clicker.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat

/**
 * Native Android WindowManager overlay service (§1).
 *
 * Provides two overlay modes:
 *  1. CONTROL BAR — floating Play/Pause, Stop, click counter shown while script runs.
 *  2. POINT PICKER — full-screen tap-capture mode for placing click/swipe points
 *     directly on any target app while Auto Clicker is backgrounded.
 *
 * Runs as a ForegroundService (via startForeground) so Android does not kill it
 * mid-script when memory pressure occurs on API 26+ devices.
 */
class OverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var pickerView: View? = null
    private var isRunning = true

    companion object {
        // Control bar actions
        const val ACTION_SHOW   = "com.example.auto_clicker.action.SHOW_OVERLAY"
        const val ACTION_HIDE   = "com.example.auto_clicker.action.HIDE_OVERLAY"
        const val ACTION_UPDATE = "com.example.auto_clicker.action.UPDATE_OVERLAY"

        // Point picker actions
        const val ACTION_POINT_PICKER_START = "com.example.auto_clicker.action.POINT_PICKER_START"
        const val ACTION_POINT_PICKER_STOP  = "com.example.auto_clicker.action.POINT_PICKER_STOP"

        const val EXTRA_IS_RUNNING    = "is_running"
        const val EXTRA_CLICK_COUNT   = "click_count"
        const val EXTRA_PICKER_MODE   = "picker_mode"   // "click" or "swipe"

        private const val CHANNEL_ID  = "overlay_service_channel"
        private const val NOTIF_ID    = 1002

        // Callbacks from overlay control bar buttons → wired back to Flutter in MainActivity
        var onPlayPause: (() -> Unit)? = null
        var onStop:      (() -> Unit)? = null

        // Callback for each point the user taps in picker mode → wired to Flutter in MainActivity
        var onPointCaptured: ((Float, Float) -> Unit)? = null
        // Callback when user taps "Done" in picker mode
        var onPickerDone: (() -> Unit)? = null
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        startForegroundWithNotification()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_SHOW               -> showControlBar()
            ACTION_HIDE               -> removeControlBar()
            ACTION_UPDATE             -> {
                isRunning = intent.getBooleanExtra(EXTRA_IS_RUNNING, true)
                updateControlBarState(intent.getIntExtra(EXTRA_CLICK_COUNT, 0))
            }
            ACTION_POINT_PICKER_START -> {
                val mode = intent.getStringExtra(EXTRA_PICKER_MODE) ?: "click"
                showPointPicker(mode)
            }
            ACTION_POINT_PICKER_STOP  -> removePointPicker()
        }
        return START_STICKY
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Foreground service notification (keeps the service alive on all APIs)
    // ─────────────────────────────────────────────────────────────────────────

    private fun startForegroundWithNotification() {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Auto Clicker Overlay",
                NotificationManager.IMPORTANCE_MIN   // Silent — no sound/vibration
            ).apply { description = "Keeps the floating overlay alive during automation" }
            manager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Auto Clicker")
            .setContentText("Overlay service running")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setOngoing(true)
            .build()

        startForeground(NOTIF_ID, notification)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Control Bar (Play/Pause, Stop, Click Counter)
    // ─────────────────────────────────────────────────────────────────────────

    private fun showControlBar() {
        if (overlayView != null) return

        val density = resources.displayMetrics.density
        fun dp(value: Int): Int = (value * density).toInt()

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            background = GradientDrawable().apply {
                setColor(0xE6131130.toInt())
                cornerRadius = dp(24).toFloat()
            }
            setPadding(dp(16), dp(8), dp(16), dp(8))
            elevation = dp(8).toFloat()
        }

        val counter = TextView(this).apply {
            text = "0"
            setTextColor(Color.WHITE)
            textSize = 14f
            setPadding(dp(4), 0, dp(12), 0)
            tag = "counter"
        }

        val playPauseBtn = ImageButton(this).apply {
            setImageResource(android.R.drawable.ic_media_pause)
            setBackgroundColor(Color.TRANSPARENT)
            setColorFilter(Color.WHITE)
            tag = "play_pause"
            setPadding(dp(6), dp(6), dp(6), dp(6))
            setOnClickListener { onPlayPause?.invoke() }
        }

        val stopBtn = ImageButton(this).apply {
            setImageResource(android.R.drawable.ic_menu_close_clear_cancel)
            setBackgroundColor(Color.TRANSPARENT)
            setColorFilter(Color.parseColor("#EF4444"))
            setPadding(dp(6), dp(6), dp(6), dp(6))
            setOnClickListener { onStop?.invoke() }
        }

        layout.addView(counter)
        layout.addView(playPauseBtn)
        layout.addView(stopBtn)

        val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutFlag,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = dp(20)
            y = dp(100)
        }

        // Drag-to-reposition
        var initialX = 0; var initialY = 0; var touchX = 0f; var touchY = 0f
        layout.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x; initialY = params.y
                    touchX = event.rawX; touchY = event.rawY; true
                }
                MotionEvent.ACTION_MOVE -> {
                    params.x = initialX + (event.rawX - touchX).toInt()
                    params.y = initialY + (event.rawY - touchY).toInt()
                    windowManager?.updateViewLayout(layout, params); true
                }
                else -> false
            }
        }

        windowManager?.addView(layout, params)
        overlayView = layout
    }

    private fun updateControlBarState(clickCount: Int) {
        val view = overlayView as? LinearLayout ?: return
        view.findViewWithTag<TextView>("counter")?.text = clickCount.toString()
        view.findViewWithTag<ImageButton>("play_pause")?.setImageResource(
            if (isRunning) android.R.drawable.ic_media_pause
            else android.R.drawable.ic_media_play
        )
    }

    private fun removeControlBar() {
        overlayView?.let { try { windowManager?.removeView(it) } catch (_: Exception) {} }
        overlayView = null
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Point Picker Overlay
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Shows a transparent full-screen tap-capture overlay on top of the target app.
     *
     * In "click" mode: every tap adds a numbered marker and fires [onPointCaptured].
     * In "swipe" mode: first tap = start point, second tap = end point then auto-closes.
     *
     * Raw event coordinates (rawX/rawY from MotionEvent) are already physical screen
     * pixels — exactly what dispatchGesture() expects. No coordinate conversion needed here.
     */
    private fun showPointPicker(mode: String) {
        if (pickerView != null) return

        val density = resources.displayMetrics.density
        fun dp(value: Int): Int = (value * density).toInt()

        val displayMetrics = resources.displayMetrics
        val screenWidth  = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels

        // Root container: full-screen, mostly transparent
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.argb(30, 0, 0, 0)) // Very subtle tint
        }

        // ─── Top instruction pill ────────────────────────────────────────────
        val isSwipeMode = mode == "swipe"
        var swipeTapCount = 0

        val instructionPill = TextView(this).apply {
            text = if (isSwipeMode) "Tap to place START point" else "Tap anywhere to add click point"
            setTextColor(Color.WHITE)
            textSize = 14f
            gravity = Gravity.CENTER
            setPadding(dp(20), dp(12), dp(20), dp(12))
            setBackgroundColor(Color.argb(220, 0, 82, 255)) // primaryBlue
        }

        // ─── Done button pill ────────────────────────────────────────────────
        val doneBtn = TextView(this).apply {
            text = "✅  Done"
            setTextColor(Color.WHITE)
            textSize = 14f
            gravity = Gravity.CENTER
            setPadding(dp(24), dp(12), dp(24), dp(12))
            setBackgroundColor(Color.argb(220, 22, 163, 74)) // green
            setOnClickListener {
                onPickerDone?.invoke()
                removePointPicker()
            }
        }

        val topBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setBackgroundColor(Color.TRANSPARENT)
            addView(instructionPill, LinearLayout.LayoutParams(0, dp(48), 1f))
            addView(doneBtn, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, dp(48)))
        }

        root.addView(topBar, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(48)))

        val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE

        // Picker params: full-screen, focusable so it receives touch events
        val params = WindowManager.LayoutParams(
            screenWidth,
            screenHeight,
            layoutFlag,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 0; y = 0
        }

        // Track markers already placed (as simple Views)
        val markers = mutableListOf<View>()
        var markerCount = 0

        root.setOnTouchListener { _, event ->
            if (event.action == MotionEvent.ACTION_UP) {
                val rawX = event.rawX
                val rawY = event.rawY

                // Fire raw physical screen coordinates to Flutter
                onPointCaptured?.invoke(rawX, rawY)
                markerCount++

                // Add numbered marker dot at tap location (visual only — inside overlay coords)
                val markerSize = dp(28)
                val marker = TextView(this@OverlayService).apply {
                    text = "$markerCount"
                    setTextColor(Color.WHITE)
                    textSize = 11f
                    gravity = Gravity.CENTER
                    setBackgroundColor(Color.argb(200, 0, 82, 255))
                    // Position marker: rawX/rawY are screen coords; adjust for top bar height
                    x = rawX - markerSize / 2
                    y = rawY - dp(48) - markerSize / 2 // subtract top bar offset
                }

                // We can't add to the FrameLayout-style easily — use a simple overlay position
                // by creating a separate small overlay window per marker
                val markerParams = WindowManager.LayoutParams(
                    markerSize, markerSize, layoutFlag,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                            WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                            WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.TOP or Gravity.START
                    x = rawX.toInt() - markerSize / 2
                    y = rawY.toInt() - markerSize / 2
                }
                try { windowManager?.addView(marker, markerParams) } catch (_: Exception) {}
                markers.add(marker)

                // Swipe mode: auto-close after 2 taps (start + end)
                if (isSwipeMode) {
                    swipeTapCount++
                    if (swipeTapCount == 1) {
                        instructionPill.text = "Tap to place END point"
                    } else if (swipeTapCount >= 2) {
                        onPickerDone?.invoke()
                        removePickerAndMarkers(markers)
                        return@setOnTouchListener true
                    }
                }
            }
            true
        }

        windowManager?.addView(root, params)
        pickerView = root
        // Store markers reference for cleanup
        root.tag = markers
    }

    private fun removePointPicker() {
        @Suppress("UNCHECKED_CAST")
        val markers = pickerView?.tag as? MutableList<View>
        removePickerAndMarkers(markers ?: mutableListOf())
    }

    private fun removePickerAndMarkers(markers: MutableList<View>) {
        markers.forEach { try { windowManager?.removeView(it) } catch (_: Exception) {} }
        markers.clear()
        pickerView?.let { try { windowManager?.removeView(it) } catch (_: Exception) {} }
        pickerView = null
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Lifecycle
    // ─────────────────────────────────────────────────────────────────────────

    override fun onDestroy() {
        removeControlBar()
        removePointPicker()
        super.onDestroy()
    }
}
