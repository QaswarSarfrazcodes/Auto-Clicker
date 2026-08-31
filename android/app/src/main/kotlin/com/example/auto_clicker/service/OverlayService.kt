package com.example.auto_clicker.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.core.app.NotificationCompat
import kotlin.math.abs

/**
 * Ultra-Premium Floating Multi-Tool Sidebar & Background Automation Engine.
 *
 * Universal Enhancements:
 *  1. MAGNETIC EDGE DOCKING: Automatically snaps to left or right screen border on touch release.
 *  2. GHOST OPACITY MODE: Dims to 40% translucency during execution so underlying app content is 100% visible.
 *  3. ZERO-OBSTRUCTION FLAG_NOT_TOUCHABLE: Touch events penetrate directly into Facebook, TikTok & Games during runs.
 *  4. IN-FEED VIDEO INTERCEPTOR: Automatically pauses on in-feed videos and displays an interactive [🎬 Video (0:15) | ⏩ Skip] badge.
 *  5. 32px COLLAPSIBLE MENU BUBBLE: Single-tap collapse to a tiny unobtrusive bubble.
 */
class OverlayService : Service() {

    private val TAG = "OverlayService"

    private var windowManager: WindowManager? = null
    private var sidebarView: View? = null
    private var menuBubbleView: View? = null
    private var videoSkipPillView: View? = null

    // Placed click targets
    private val placedTargetViews = mutableListOf<View>()
    private val placedTargetParams = mutableListOf<WindowManager.LayoutParams>()
    private val placedCoordinates = mutableListOf<Pair<Float, Float>>()

    // Placed swipe targets (START 🟢 & END 🔴)
    private var swipeStartView: View? = null
    private var swipeStartParams: WindowManager.LayoutParams? = null
    private var swipeEndView: View? = null
    private var swipeEndParams: WindowManager.LayoutParams? = null

    // Engine settings
    private var isRunning = false
    private var isSwipeMode = true
    private var isVideoHoldEnabled = true
    private var fatigueMinutes = 30
    private var scrollIntervalMs = 2500L // 2.5s default for social feeds

    // Video hold state
    private var isHoldingForVideo = false
    private var videoRemainingSec = -1

    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        const val ACTION_SHOW = "com.example.auto_clicker.action.SHOW_OVERLAY"
        const val ACTION_HIDE = "com.example.auto_clicker.action.HIDE_OVERLAY"
        const val ACTION_UPDATE = "com.example.auto_clicker.action.UPDATE_OVERLAY"
        const val ACTION_POINT_PICKER_START = "com.example.auto_clicker.action.POINT_PICKER_START"
        const val ACTION_POINT_PICKER_STOP = "com.example.auto_clicker.action.POINT_PICKER_STOP"

        const val EXTRA_IS_RUNNING = "is_running"
        const val EXTRA_CLICK_COUNT = "click_count"
        const val EXTRA_PICKER_MODE = "picker_mode"

        private const val CHANNEL_ID = "overlay_service_channel"
        private const val NOTIF_ID = 1002

        var onPlayPause: (() -> Unit)? = null
        var onStop: (() -> Unit)? = null
        var onPointCaptured: ((Float, Float) -> Unit)? = null
        var onPickerDone: (() -> Unit)? = null
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        startForegroundWithNotification()
        setupVideoWatcherCallbacks()
    }

    private fun setupVideoWatcherCallbacks() {
        ScreenVideoTimeWatcher.sharedInstance?.onVideoEndedCallback = {
            if (isRunning && isHoldingForVideo) {
                Log.d(TAG, "🎬 Video finished callback received! Resuming scroll immediately.")
                isHoldingForVideo = false
                hideVideoSkipPill()
                triggerNextGesture()
            }
        }

        ScreenVideoTimeWatcher.sharedInstance?.onVideoStatusUpdated = { isPlaying, progress, remainingSec ->
            if (isRunning && isVideoHoldEnabled) {
                if (isPlaying) {
                    videoRemainingSec = remainingSec
                    showOrUpdateVideoSkipPill(remainingSec, progress)
                } else if (!isPlaying && isHoldingForVideo) {
                    isHoldingForVideo = false
                    hideVideoSkipPill()
                }
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_SHOW, ACTION_POINT_PICKER_START -> {
                val mode = intent.getStringExtra(EXTRA_PICKER_MODE) ?: "swipe"
                isSwipeMode = mode == "swipe"
                showFloatingMultiToolbar()
            }
            ACTION_HIDE, ACTION_POINT_PICKER_STOP -> {
                stopGestureLoop()
                dismissAllOverlays()
            }
            ACTION_UPDATE -> {
                val runState = intent.getBooleanExtra(EXTRA_IS_RUNNING, isRunning)
                if (runState != isRunning) {
                    if (runState) startGestureLoop() else stopGestureLoop()
                }
            }
        }
        return START_STICKY
    }

    private fun dp(v: Int): Int {
        val density = resources.displayMetrics.density
        return (v * density).toInt()
    }

    private fun dp(v: Float): Int {
        val density = resources.displayMetrics.density
        return (v * density).toInt()
    }

    private fun getOverlayLayoutFlag(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Active Gesture Dispatch Loop (Executes real scrolling & clicking)
    // ─────────────────────────────────────────────────────────────────────────

    private val gestureLoopRunnable = object : Runnable {
        override fun run() {
            if (!isRunning) return

            val service = AutoClickerService.sharedInstance
            if (service == null) {
                Toast.makeText(
                    this@OverlayService,
                    "⚠️ Accessibility Service is OFF! Please enable Auto Clicker in Accessibility Settings.",
                    Toast.LENGTH_LONG
                ).show()
                stopGestureLoop()
                return
            }

            // Feature B: Super Hybrid Video Detection Hold
            val isWatcherVideo = ScreenVideoTimeWatcher.sharedInstance?.isVideoPlaying == true
            val isServiceVideo = service.queryVideoPlayback("")

            if (isVideoHoldEnabled && (isWatcherVideo || isServiceVideo)) {
                if (!isHoldingForVideo) {
                    isHoldingForVideo = true
                    Log.d(TAG, "🎬 In-feed video detected! Holding auto-scroll...")
                    showOrUpdateVideoSkipPill(videoRemainingSec, 0f)
                }
                // Check back in 1 second while video is active
                mainHandler.postDelayed(this, 1000L)
                return
            }

            isHoldingForVideo = false
            hideVideoSkipPill()

            triggerNextGesture()
            mainHandler.postDelayed(this, scrollIntervalMs)
        }
    }

    private fun triggerNextGesture() {
        val service = AutoClickerService.sharedInstance ?: return
        val displayMetrics = resources.displayMetrics

        // ── Mode A: Swipe Gestures (Social Feeds / Reels) ───────────────
        if (isSwipeMode || swipeStartParams != null || swipeEndParams != null) {
            val startX = swipeStartParams?.let { (it.x + dp(35)).toFloat() }
                ?: (displayMetrics.widthPixels / 2f)
            val startY = swipeStartParams?.let { (it.y + dp(25)).toFloat() }
                ?: (displayMetrics.heightPixels * 0.75f)

            val endX = swipeEndParams?.let { (it.x + dp(35)).toFloat() }
                ?: (displayMetrics.widthPixels / 2f)
            val endY = swipeEndParams?.let { (it.y + dp(25)).toFloat() }
                ?: (displayMetrics.heightPixels * 0.25f)

            Log.d(TAG, "Executing swipe: ($startX, $startY) -> ($endX, $endY)")
            service.dispatchSwipe(startX, startY, endX, endY, 300L) { success ->
                Log.d(TAG, "Swipe completed: $success")
            }
        }
        // ── Mode B: Click Targets (1, 2, 3...) ──────────────────────────
        else if (placedCoordinates.isNotEmpty()) {
            for (coord in placedCoordinates) {
                service.dispatchClick(coord.first, coord.second, 50L)
            }
        }
        // ── Default Fallback Swipe ──────────────────────────────────────
        else {
            val midX = displayMetrics.widthPixels / 2f
            val startY = displayMetrics.heightPixels * 0.75f
            val endY = displayMetrics.heightPixels * 0.25f
            service.dispatchSwipe(midX, startY, midX, endY, 300L)
        }
    }

    private fun setPinsTouchable(touchable: Boolean) {
        val wm = windowManager ?: return

        swipeStartView?.let { view ->
            swipeStartParams?.let { params ->
                if (touchable) {
                    params.flags = params.flags and WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE.inv()
                } else {
                    params.flags = params.flags or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                }
                try { wm.updateViewLayout(view, params) } catch (_: Exception) {}
            }
        }

        swipeEndView?.let { view ->
            swipeEndParams?.let { params ->
                if (touchable) {
                    params.flags = params.flags and WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE.inv()
                } else {
                    params.flags = params.flags or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                }
                try { wm.updateViewLayout(view, params) } catch (_: Exception) {}
            }
        }

        for (i in placedTargetViews.indices) {
            if (i < placedTargetParams.size) {
                val view = placedTargetViews[i]
                val params = placedTargetParams[i]
                if (touchable) {
                    params.flags = params.flags and WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE.inv()
                } else {
                    params.flags = params.flags or WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                }
                try { wm.updateViewLayout(view, params) } catch (_: Exception) {}
            }
        }
    }

    private fun startGestureLoop() {
        val service = AutoClickerService.sharedInstance
        if (service == null) {
            Toast.makeText(
                this,
                "⚠️ Accessibility Service is OFF! Please enable Auto Clicker in Accessibility Settings.",
                Toast.LENGTH_LONG
            ).show()
            try {
                val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                startActivity(intent)
            } catch (_: Exception) {}
            return
        }

        if (isSwipeMode && swipeStartView == null && swipeEndView == null) {
            spawnDraggableSwipePair()
        }

        isRunning = true
        setPinsTouchable(false)
        applyGhostMode(true) // Dims toolbar to 40% translucent ghost mode
        updatePlayPauseButton()
        mainHandler.removeCallbacks(gestureLoopRunnable)
        mainHandler.post(gestureLoopRunnable)
        Toast.makeText(this, "▶ Auto-Scroll Started! Speed: ${(scrollIntervalMs / 1000.0)}s", Toast.LENGTH_SHORT).show()
    }

    private fun stopGestureLoop() {
        isRunning = false
        isHoldingForVideo = false
        hideVideoSkipPill()
        setPinsTouchable(true)
        applyGhostMode(false) // Restores 100% opacity
        updatePlayPauseButton()
        mainHandler.removeCallbacks(gestureLoopRunnable)
        Toast.makeText(this, "⏸ Auto-Scroll Paused", Toast.LENGTH_SHORT).show()
    }

    private fun applyGhostMode(ghost: Boolean) {
        sidebarView?.alpha = if (ghost) 0.40f else 1.0f
        menuBubbleView?.alpha = if (ghost) 0.50f else 1.0f
    }

    // ─────────────────────────────────────────────────────────────────────────
    // In-Feed Video Skip Pill Badge [ 🎬 Video Playing (0:15) | ⏩ Skip ]
    // ─────────────────────────────────────────────────────────────────────────

    private fun showOrUpdateVideoSkipPill(remainingSec: Int, progress: Float) {
        val wm = windowManager ?: return

        val displayText = if (remainingSec > 0) {
            "🎬 Video ($remainingSec s)"
        } else if (progress > 0) {
            "🎬 Video (${progress.toInt()}%)"
        } else {
            "🎬 Video Playing"
        }

        if (videoSkipPillView != null) {
            videoSkipPillView?.findViewWithTag<TextView>("video_label")?.text = displayText
            return
        }

        val pillLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(12), dp(6), dp(10), dp(6))
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#E60F172A"))
                cornerRadius = dp(20).toFloat()
                setStroke(dp(1.5f), Color.parseColor("#38BDF8"))
            }
            elevation = dp(24).toFloat()

            val label = TextView(this@OverlayService).apply {
                tag = "video_label"
                text = displayText
                setTextColor(Color.WHITE)
                textSize = 12f
                typeface = Typeface.DEFAULT_BOLD
            }
            addView(label)

            val spacer = View(this@OverlayService).apply {
                layoutParams = LinearLayout.LayoutParams(dp(8), dp(1))
            }
            addView(spacer)

            val skipBtn = TextView(this@OverlayService).apply {
                text = "⏩ Skip"
                setTextColor(Color.parseColor("#F87171"))
                textSize = 12f
                typeface = Typeface.DEFAULT_BOLD
                setPadding(dp(6), dp(3), dp(6), dp(3))
                background = GradientDrawable().apply {
                    setColor(Color.parseColor("#33EF4444"))
                    cornerRadius = dp(8).toFloat()
                }
                setOnClickListener {
                    Log.d(TAG, "User clicked Skip on in-feed video!")
                    isHoldingForVideo = false
                    hideVideoSkipPill()
                    triggerNextGesture()
                }
            }
            addView(skipBtn)
        }

        val displayMetrics = resources.displayMetrics
        val pillParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            getOverlayLayoutFlag(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
            y = dp(70)
        }

        try {
            wm.addView(pillLayout, pillParams)
            videoSkipPillView = pillLayout
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun hideVideoSkipPill() {
        videoSkipPillView?.let {
            try { windowManager?.removeView(it) } catch (_: Exception) {}
        }
        videoSkipPillView = null
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Floating Multi-Tool Sidebar with Magnetic Edge Docking
    // ─────────────────────────────────────────────────────────────────────────

    private fun showFloatingMultiToolbar() {
        if (sidebarView != null) return
        removeMenuBubble()

        val glassBg = GradientDrawable().apply {
            setColor(Color.parseColor("#F50F172A"))
            cornerRadius = dp(20).toFloat()
            setStroke(dp(1), Color.parseColor("#4D38BDF8"))
        }

        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            background = glassBg
            setPadding(dp(6), dp(8), dp(6), dp(8))
            elevation = dp(20).toFloat()
        }

        // Top Grip Handle
        container.addView(createHeaderHandle())

        // 1. Play / Pause Tool
        val playBtn = createToolItem(
            iconRes = if (isRunning) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play,
            label = if (isRunning) "Pause" else "Start",
            colorHex = if (isRunning) "#F59E0B" else "#10B981",
            tag = "btn_play_pause",
            onClick = {
                if (isRunning) stopGestureLoop() else startGestureLoop()
                onPlayPause?.invoke()
            }
        )
        container.addView(playBtn)

        // 2. Add Scroll Path Tool
        val addScrollBtn = createToolItem(
            iconRes = android.R.drawable.ic_menu_rotate,
            label = "Scroll Path",
            colorHex = "#A855F7",
            tag = "btn_add_scroll",
            onClick = {
                isSwipeMode = true
                spawnDraggableSwipePair()
            }
        )
        container.addView(addScrollBtn)

        // 3. Add Click Target Tool
        val addClickBtn = createToolItem(
            iconRes = android.R.drawable.ic_input_add,
            label = "Add Click",
            colorHex = "#38BDF8",
            tag = "btn_add_click",
            onClick = {
                isSwipeMode = false
                spawnDraggableClickPoint()
            }
        )
        container.addView(addClickBtn)

        // 4. Scroll Speed Adjuster
        val speedBtn = createToolItem(
            iconRes = android.R.drawable.ic_menu_manage,
            label = "${(scrollIntervalMs / 1000.0)}s Speed",
            colorHex = "#38BDF8",
            tag = "btn_speed",
            onClick = { cycleSpeedInterval() }
        )
        container.addView(speedBtn)

        // 5. Video Auto-Pause Tool
        val videoRadarBtn = createToolItem(
            iconRes = android.R.drawable.ic_menu_slideshow,
            label = if (isVideoHoldEnabled) "Video Hold" else "Video OFF",
            colorHex = if (isVideoHoldEnabled) "#06B6D4" else "#64748B",
            tag = "btn_video_radar",
            onClick = { toggleVideoRadar() }
        )
        container.addView(videoRadarBtn)

        // 6. Fatigue Break Timer Tool
        val fatigueBtn = createToolItem(
            iconRes = android.R.drawable.ic_lock_idle_alarm,
            label = if (fatigueMinutes > 0) "${fatigueMinutes}m Break" else "Break OFF",
            colorHex = "#F59E0B",
            tag = "btn_fatigue",
            onClick = { cycleFatigueTimer() }
        )
        container.addView(fatigueBtn)

        // 7. Remove Last Pin / Undo
        val removeBtn = createToolItem(
            iconRes = android.R.drawable.ic_delete,
            label = "Undo",
            colorHex = "#EF4444",
            tag = "btn_remove",
            onClick = { removeLastPlacedTarget() }
        )
        container.addView(removeBtn)

        // 8. Collapse to 32px Bubble
        val collapseBtn = createToolItem(
            iconRes = android.R.drawable.arrow_down_float,
            label = "MENU",
            colorHex = "#38BDF8",
            tag = "btn_collapse",
            onClick = { collapseToMenuBubble() }
        )
        container.addView(collapseBtn)

        // 9. Exit Tool
        val exitBtn = createToolItem(
            iconRes = android.R.drawable.ic_menu_close_clear_cancel,
            label = "Exit",
            colorHex = "#64748B",
            tag = "btn_exit",
            onClick = {
                stopGestureLoop()
                onStop?.invoke()
                dismissAllOverlays()
            }
        )
        container.addView(exitBtn)

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            getOverlayLayoutFlag(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = dp(8)
            y = dp(140)
        }

        attachMagneticDragListener(container, params) {}

        try {
            windowManager?.addView(container, params)
            sidebarView = container
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun createHeaderHandle(): LinearLayout {
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(0, dp(2), 0, dp(4))

            val grip = TextView(this@OverlayService).apply {
                text = "⠿ AUTO"
                setTextColor(Color.parseColor("#38BDF8"))
                textSize = 9f
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
                letterSpacing = 0.08f
            }
            addView(grip)
        }
    }

    private fun createToolItem(
        iconRes: Int,
        label: String,
        colorHex: String,
        tag: String,
        onClick: () -> Unit
    ): LinearLayout {
        val root = LinearLayout(this)
        root.tag = tag
        root.orientation = LinearLayout.VERTICAL
        root.gravity = Gravity.CENTER_HORIZONTAL
        root.isClickable = true
        root.setPadding(dp(4), dp(3), dp(4), dp(4))
        root.setOnClickListener { onClick() }

        val iconWrapper = FrameLayout(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(36), dp(36))
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#26${colorHex.replace("#", "")}"))
                setStroke(dp(1), Color.parseColor(colorHex))
            }

            val icon = ImageView(this@OverlayService).apply {
                setImageResource(iconRes)
                setColorFilter(Color.parseColor(colorHex))
                val padding = dp(8)
                setPadding(padding, padding, padding, padding)
            }
            addView(icon)
        }

        val text = TextView(this).apply {
            this.text = label
            textSize = 8.5f
            setTextColor(Color.parseColor("#E2E8F0"))
            gravity = Gravity.CENTER
            typeface = Typeface.DEFAULT_BOLD
            setPadding(0, dp(2), 0, 0)
        }
        text.tag = "label"

        root.addView(iconWrapper)
        root.addView(text)
        return root
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 32px Collapsible Bubble with Magnetic Snapping
    // ─────────────────────────────────────────────────────────────────────────

    private fun collapseToMenuBubble() {
        removeSidebar()
        if (menuBubbleView != null) return

        val density = resources.displayMetrics.density
        val size = (48 * density).toInt()

        val bubble = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#F50F172A"))
                setStroke((2 * density).toInt(), Color.parseColor("#38BDF8"))
            }
            elevation = (22 * density)

            val contentLayout = LinearLayout(this@OverlayService).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )

                val menuIcon = TextView(this@OverlayService).apply {
                    text = "≡"
                    setTextColor(Color.parseColor("#38BDF8"))
                    textSize = 18f
                    typeface = Typeface.DEFAULT_BOLD
                    gravity = Gravity.CENTER
                }

                val menuText = TextView(this@OverlayService).apply {
                    text = "MENU"
                    setTextColor(Color.WHITE)
                    textSize = 8f
                    typeface = Typeface.DEFAULT_BOLD
                    gravity = Gravity.CENTER
                }

                addView(menuIcon)
                addView(menuText)
            }
            addView(contentLayout)
        }

        val params = WindowManager.LayoutParams(
            size, size, getOverlayLayoutFlag(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = (8 * density).toInt()
            y = (200 * density).toInt()
        }

        attachMagneticDragListener(bubble, params) {
            removeMenuBubble()
            showFloatingMultiToolbar()
        }

        try {
            windowManager?.addView(bubble, params)
            menuBubbleView = bubble
            Toast.makeText(this, "Sidebar collapsed. Tap anytime to expand!", Toast.LENGTH_SHORT).show()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Magnetic Edge Snapping Touch Listener
    // ─────────────────────────────────────────────────────────────────────────

    private fun attachMagneticDragListener(
        view: View,
        params: WindowManager.LayoutParams,
        onClick: () -> Unit
    ) {
        var startX = 0
        var startY = 0
        var touchX = 0f
        var touchY = 0f
        var isDragging = false
        val touchSlop = dp(6)

        view.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    startX = params.x
                    startY = params.y
                    touchX = event.rawX
                    touchY = event.rawY
                    isDragging = false
                    view.alpha = 1.0f // Fully visible when user interacts
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - touchX).toInt()
                    val dy = (event.rawY - touchY).toInt()
                    if (abs(dx) > touchSlop || abs(dy) > touchSlop) {
                        isDragging = true
                    }
                    if (isDragging) {
                        params.x = startX + dx
                        params.y = startY + dy
                        windowManager?.updateViewLayout(view, params)
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!isDragging) {
                        onClick()
                    } else {
                        // Magnetic snap to left or right screen border
                        val screenWidth = resources.displayMetrics.widthPixels
                        val snapLeft = dp(8)
                        val snapRight = screenWidth - view.width - dp(8)
                        params.x = if (params.x + view.width / 2 < screenWidth / 2) snapLeft else snapRight
                        windowManager?.updateViewLayout(view, params)
                    }
                    if (isRunning) applyGhostMode(true)
                    true
                }
                else -> false
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Spawning Draggable Swipe Path Markers (START 🟢 & END 🔴)
    // ─────────────────────────────────────────────────────────────────────────

    private fun spawnDraggableSwipePair() {
        removeSwipeMarkers()

        val density = resources.displayMetrics.density
        val markerWidth = (74 * density).toInt()
        val markerHeight = (52 * density).toInt()
        val displayMetrics = resources.displayMetrics
        val screenCenterX = displayMetrics.widthPixels / 2 - markerWidth / 2

        val startMarker = createNamedPillMarker("START 🟢", "Swipe Begins Here", "#10B981")
        val startParams = WindowManager.LayoutParams(
            markerWidth, markerHeight, getOverlayLayoutFlag(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = screenCenterX
            y = (displayMetrics.heightPixels * 0.72f).toInt()
        }
        attachMarkerDragListener(startMarker, startParams)

        val endMarker = createNamedPillMarker("END 🔴", "Swipe Lifts Here", "#EF4444")
        val endParams = WindowManager.LayoutParams(
            markerWidth, markerHeight, getOverlayLayoutFlag(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = screenCenterX
            y = (displayMetrics.heightPixels * 0.28f).toInt()
        }
        attachMarkerDragListener(endMarker, endParams)

        try {
            windowManager?.addView(startMarker, startParams)
            windowManager?.addView(endMarker, endParams)
            swipeStartView = startMarker
            swipeStartParams = startParams
            swipeEndView = endMarker
            swipeEndParams = endParams

            onPointCaptured?.invoke(startParams.x.toFloat(), startParams.y.toFloat())
            onPointCaptured?.invoke(endParams.x.toFloat(), endParams.y.toFloat())
            Toast.makeText(this, "Swipe Path: 'START 🟢' at bottom, 'END 🔴' at top. Tap 'Start' to begin!", Toast.LENGTH_LONG).show()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun createNamedPillMarker(title: String, subtitle: String, colorHex: String): LinearLayout {
        val density = resources.displayMetrics.density
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding((6 * density).toInt(), (4 * density).toInt(), (6 * density).toInt(), (4 * density).toInt())
            background = GradientDrawable().apply {
                cornerRadius = (14 * density)
                setColor(Color.parseColor(colorHex))
                setStroke((2 * density).toInt(), Color.WHITE)
            }
            elevation = (20 * density)

            val titleView = TextView(this@OverlayService).apply {
                text = title
                setTextColor(Color.WHITE)
                textSize = 11f
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
            }

            val subView = TextView(this@OverlayService).apply {
                text = subtitle
                setTextColor(Color.parseColor("#E2E8F0"))
                textSize = 7.5f
                gravity = Gravity.CENTER
            }

            addView(titleView)
            addView(subView)
        }
    }

    private fun spawnDraggableClickPoint() {
        val pointNumber = placedCoordinates.size + 1
        val density = resources.displayMetrics.density
        val markerSize = (46 * density).toInt()

        val displayMetrics = resources.displayMetrics
        val initialX = displayMetrics.widthPixels / 2 - markerSize / 2
        val initialY = displayMetrics.heightPixels / 2 - markerSize / 2

        val marker = FrameLayout(this).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#F02563EB"))
                setStroke((2.5f * density).toInt(), Color.WHITE)
            }
            elevation = (20 * density)

            val numberText = TextView(this@OverlayService).apply {
                text = "$pointNumber"
                setTextColor(Color.WHITE)
                textSize = 15f
                typeface = Typeface.DEFAULT_BOLD
                gravity = Gravity.CENTER
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )
            }
            addView(numberText)
        }

        val markerParams = WindowManager.LayoutParams(
            markerSize, markerSize, getOverlayLayoutFlag(),
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = initialX
            y = initialY
        }

        attachMarkerDragListener(marker, markerParams)

        try {
            windowManager?.addView(marker, markerParams)
            placedTargetViews.add(marker)
            placedTargetParams.add(markerParams)
            placedCoordinates.add(Pair(initialX.toFloat(), initialY.toFloat()))
            onPointCaptured?.invoke(initialX.toFloat(), initialY.toFloat())
            Toast.makeText(this, "Click Target ($pointNumber) added! Drag onto any button.", Toast.LENGTH_SHORT).show()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun attachMarkerDragListener(view: View, params: WindowManager.LayoutParams) {
        var startX = 0
        var startY = 0
        var touchX = 0f
        var touchY = 0f

        view.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    startX = params.x
                    startY = params.y
                    touchX = event.rawX
                    touchY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - touchX).toInt()
                    val dy = (event.rawY - touchY).toInt()
                    params.x = startX + dx
                    params.y = startY + dy
                    windowManager?.updateViewLayout(view, params)
                    true
                }
                MotionEvent.ACTION_UP -> {
                    val index = placedTargetViews.indexOf(view)
                    if (index >= 0 && index < placedCoordinates.size) {
                        placedCoordinates[index] = Pair(params.x.toFloat(), params.y.toFloat())
                        onPointCaptured?.invoke(params.x.toFloat(), params.y.toFloat())
                    }
                    true
                }
                else -> false
            }
        }
    }

    private fun removeLastPlacedTarget() {
        if (placedTargetViews.isNotEmpty()) {
            val lastView = placedTargetViews.removeAt(placedTargetViews.size - 1)
            if (placedTargetParams.isNotEmpty()) {
                placedTargetParams.removeAt(placedTargetParams.size - 1)
            }
            try { windowManager?.removeView(lastView) } catch (_: Exception) {}
            if (placedCoordinates.isNotEmpty()) {
                placedCoordinates.removeAt(placedCoordinates.size - 1)
            }
            Toast.makeText(this, "Target removed (${placedTargetViews.size} left)", Toast.LENGTH_SHORT).show()
        } else if (swipeStartView != null || swipeEndView != null) {
            removeSwipeMarkers()
            Toast.makeText(this, "Swipe markers removed", Toast.LENGTH_SHORT).show()
        } else {
            Toast.makeText(this, "No targets to remove", Toast.LENGTH_SHORT).show()
        }
    }

    private fun removeSwipeMarkers() {
        swipeStartView?.let { try { windowManager?.removeView(it) } catch (_: Exception) {} }
        swipeEndView?.let { try { windowManager?.removeView(it) } catch (_: Exception) {} }
        swipeStartView = null
        swipeStartParams = null
        swipeEndView = null
        swipeEndParams = null
    }

    private fun cycleSpeedInterval() {
        val speeds = listOf(500L, 1000L, 2000L, 2500L, 3000L, 5000L)
        val currentIndex = speeds.indexOf(scrollIntervalMs)
        val nextIndex = (currentIndex + 1) % speeds.size
        scrollIntervalMs = speeds[nextIndex]

        val label = "${(scrollIntervalMs / 1000.0)}s Speed"
        sidebarView?.findViewWithTag<View>("btn_speed")?.findViewWithTag<TextView>("label")?.text = label
        Toast.makeText(this, "⏱️ Scroll Speed: ${(scrollIntervalMs / 1000.0)}s", Toast.LENGTH_SHORT).show()
    }

    private fun toggleVideoRadar() {
        isVideoHoldEnabled = !isVideoHoldEnabled
        val label = if (isVideoHoldEnabled) "Video Hold" else "Video OFF"
        sidebarView?.findViewWithTag<View>("btn_video_radar")?.findViewWithTag<TextView>("label")?.text = label
        val msg = if (isVideoHoldEnabled) "🎬 Video Auto-Hold ON" else "🎬 Video Auto-Hold OFF"
        Toast.makeText(this, msg, Toast.LENGTH_SHORT).show()
    }

    private fun cycleFatigueTimer() {
        val options = listOf(15, 30, 45, 60, 0)
        val currentIndex = options.indexOf(fatigueMinutes)
        val nextIndex = (currentIndex + 1) % options.size
        fatigueMinutes = options[nextIndex]

        val label = if (fatigueMinutes > 0) "${fatigueMinutes}m Break" else "Break OFF"
        sidebarView?.findViewWithTag<View>("btn_fatigue")?.findViewWithTag<TextView>("label")?.text = label
        Toast.makeText(this, "⏱️ Fatigue Timer: $label", Toast.LENGTH_SHORT).show()
    }

    private fun updatePlayPauseButton() {
        val view = sidebarView?.findViewWithTag<View>("btn_play_pause") ?: return
        val label = view.findViewWithTag<TextView>("label")
        val icon = (view as? LinearLayout)?.getChildAt(0) as? FrameLayout
        val iv = icon?.getChildAt(0) as? ImageView

        if (isRunning) {
            label?.text = "Pause"
            iv?.setImageResource(android.R.drawable.ic_media_pause)
            iv?.setColorFilter(Color.parseColor("#F59E0B"))
        } else {
            label?.text = "Start"
            iv?.setImageResource(android.R.drawable.ic_media_play)
            iv?.setColorFilter(Color.parseColor("#10B981"))
        }
    }

    private fun removeSidebar() {
        sidebarView?.let { try { windowManager?.removeView(it) } catch (_: Exception) {} }
        sidebarView = null
    }

    private fun removeMenuBubble() {
        menuBubbleView?.let { try { windowManager?.removeView(it) } catch (_: Exception) {} }
        menuBubbleView = null
    }

    private fun dismissAllOverlays() {
        stopGestureLoop()
        removeSidebar()
        removeMenuBubble()
        hideVideoSkipPill()
        removeSwipeMarkers()
        placedTargetViews.forEach { try { windowManager?.removeView(it) } catch (_: Exception) {} }
        placedTargetViews.clear()
        placedTargetParams.clear()
        placedCoordinates.clear()
        stopSelf()
    }

    private fun startForegroundWithNotification() {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Auto Clicker Overlay",
                NotificationManager.IMPORTANCE_MIN
            ).apply { description = "Floating Multi-Tool Toolbar active" }
            manager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Auto Clicker Floating Multi-Tool Active")
            .setContentText("Multi-Tool Toolbar running over target apps")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setOngoing(true)
            .build()

        startForeground(NOTIF_ID, notification)
    }

    override fun onDestroy() {
        dismissAllOverlays()
        super.onDestroy()
    }
}
