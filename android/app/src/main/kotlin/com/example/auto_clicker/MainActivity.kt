package com.example.auto_clicker

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import com.example.auto_clicker.service.AutoClickForegroundService
import com.example.auto_clicker.service.AutoClickerService
import com.example.auto_clicker.service.KillSwitchHandler
import com.example.auto_clicker.service.OverlayService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val AUTOMATION_CHANNEL = "com.example.auto_clicker/automation"
    private val OVERLAY_CHANNEL = "com.example.auto_clicker/overlay"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val automationMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUTOMATION_CHANNEL)
        val overlayMethodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, OVERLAY_CHANNEL)

        AutoClickForegroundService.onServiceStopRequested = {
            runOnUiThread {
                automationMethodChannel.invokeMethod("onServiceStopRequested", null)
            }
        }

        // Wire Emergency KillSwitch (Volume Down) to Flutter
        KillSwitchHandler.onEmergencyStop = {
            runOnUiThread {
                automationMethodChannel.invokeMethod("onEmergencyStop", null)
            }
        }

        // Wire Overlay control buttons directly back to Flutter
        OverlayService.onPlayPause = {
            runOnUiThread {
                overlayMethodChannel.invokeMethod("onPlayPauseTapped", null)
            }
        }

        OverlayService.onStop = {
            runOnUiThread {
                overlayMethodChannel.invokeMethod("onStopTapped", null)
            }
        }

        // Wire Point Picker coordinate captures back to Flutter
        OverlayService.onPointCaptured = { x, y ->
            runOnUiThread {
                overlayMethodChannel.invokeMethod(
                    "onPointCaptured",
                    mapOf("x" to x.toDouble(), "y" to y.toDouble())
                )
            }
        }

        // Wire Point Picker "Done" button back to Flutter
        OverlayService.onPickerDone = {
            runOnUiThread {
                overlayMethodChannel.invokeMethod("onPickerDone", null)
            }
        }

        // Automation Channel Handlers
        automationMethodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityGranted" -> {
                    result.success(AutoClickerService.isServiceRunning())
                }

                "openAccessibilitySettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.message, null)
                    }
                }

                "isOverlayGranted" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(Settings.canDrawOverlays(context))
                    } else {
                        result.success(true)
                    }
                }

                "openOverlaySettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            ).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.message, null)
                    }
                }

                "dispatchClick" -> {
                    val x = call.argument<Double>("x")?.toFloat() ?: 0f
                    val y = call.argument<Double>("y")?.toFloat() ?: 0f
                    val duration = (call.argument<Int>("duration") ?: 50).toLong()

                    val service = AutoClickerService.sharedInstance
                    if (service != null) {
                        runOnUiThread {
                            service.dispatchClick(x, y, duration) { success ->
                                runOnUiThread {
                                    result.success(success)
                                }
                            }
                        }
                    } else {
                        result.error("SERVICE_NOT_RUNNING", "Accessibility Service is not enabled", null)
                    }
                }

                "dispatchSwipe" -> {
                    val startX = call.argument<Double>("startX")?.toFloat() ?: 0f
                    val startY = call.argument<Double>("startY")?.toFloat() ?: 0f
                    val endX = call.argument<Double>("endX")?.toFloat() ?: 0f
                    val endY = call.argument<Double>("endY")?.toFloat() ?: 0f
                    val duration = (call.argument<Int>("duration") ?: 300).toLong()

                    val service = AutoClickerService.sharedInstance
                    if (service != null) {
                        runOnUiThread {
                            service.dispatchSwipe(startX, startY, endX, endY, duration) { success ->
                                runOnUiThread {
                                    result.success(success)
                                }
                            }
                        }
                    } else {
                        result.error("SERVICE_NOT_RUNNING", "Accessibility Service is not enabled", null)
                    }
                }

                "startForegroundService" -> {
                    try {
                        val intent = Intent(this, AutoClickForegroundService::class.java).apply {
                            action = AutoClickForegroundService.ACTION_START
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        KillSwitchHandler.isScriptRunning = true  // Enable kill-switch only during active script
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("FGS_ERROR", e.message, null)
                    }
                }

                "stopForegroundService" -> {
                    try {
                        val intent = Intent(this, AutoClickForegroundService::class.java).apply {
                            action = AutoClickForegroundService.ACTION_STOP
                        }
                        startService(intent)
                        KillSwitchHandler.isScriptRunning = false // Disable kill-switch when script stops
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("FGS_ERROR", e.message, null)
                    }
                }

                "minimizeApp" -> {
                    moveTaskToBack(true)
                    result.success(true)
                }

                else -> {
                    result.notImplemented()
                }
            }
        }

        // Overlay Channel Handlers (§1)
        overlayMethodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "show" -> {
                    try {
                        val intent = Intent(this, OverlayService::class.java).apply {
                            action = OverlayService.ACTION_SHOW
                        }
                        // OverlayService now runs as a ForegroundService
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OVERLAY_ERROR", e.message, null)
                    }
                }

                "hide" -> {
                    try {
                        val intent = Intent(this, OverlayService::class.java).apply {
                            action = OverlayService.ACTION_HIDE
                        }
                        startService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OVERLAY_ERROR", e.message, null)
                    }
                }

                "update" -> {
                    try {
                        val isRunning = call.argument<Boolean>("isRunning") ?: true
                        val count = call.argument<Int>("clickCount") ?: 0
                        val intent = Intent(this, OverlayService::class.java).apply {
                            action = OverlayService.ACTION_UPDATE
                            putExtra(OverlayService.EXTRA_IS_RUNNING, isRunning)
                            putExtra(OverlayService.EXTRA_CLICK_COUNT, count)
                        }
                        startService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OVERLAY_ERROR", e.message, null)
                    }
                }

                "hasOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(Settings.canDrawOverlays(context))
                    } else {
                        result.success(true)
                    }
                }

                "requestOverlayPermission" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val intent = Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            ).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.message, null)
                    }
                }

                "startPointPicker" -> {
                    try {
                        val mode = call.argument<String>("mode") ?: "click"
                        val intent = Intent(this, OverlayService::class.java).apply {
                            action = OverlayService.ACTION_POINT_PICKER_START
                            putExtra(OverlayService.EXTRA_PICKER_MODE, mode)
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        moveTaskToBack(true)  // Minimize app so user can see target app
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OVERLAY_ERROR", e.message, null)
                    }
                }

                "stopPointPicker" -> {
                    try {
                        val intent = Intent(this, OverlayService::class.java).apply {
                            action = OverlayService.ACTION_POINT_PICKER_STOP
                        }
                        startService(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("OVERLAY_ERROR", e.message, null)
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
