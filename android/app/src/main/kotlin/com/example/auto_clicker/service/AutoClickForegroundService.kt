package com.example.auto_clicker.service

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.example.auto_clicker.MainActivity

/**
 * Android Foreground Service (§11) to maintain execution continuity when
 * the app is backgrounded or when other apps are interacted with.
 */
class AutoClickForegroundService : Service() {

    companion object {
        const val CHANNEL_ID = "auto_clicker_running_channel"
        const val NOTIF_ID = 1001
        const val ACTION_START = "com.example.auto_clicker.action.START_FOREGROUND"
        const val ACTION_STOP = "com.example.auto_clicker.action.STOP_FOREGROUND"
        const val ACTION_STOP_FROM_NOTIF = "com.example.auto_clicker.action.STOP_FROM_NOTIFICATION"

        var onServiceStopRequested: (() -> Unit)? = null
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startForegroundWithNotification()
            ACTION_STOP_FROM_NOTIF -> {
                onServiceStopRequested?.invoke()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
            ACTION_STOP -> {
                // Stopped programmatically from Flutter — do not echo back onServiceStopRequested
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    private fun startForegroundWithNotification() {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Auto Clicker Running",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows status while an automation script is running"
            }
            manager.createNotificationChannel(channel)
        }

        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPending = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val stopIntent = Intent(this, AutoClickForegroundService::class.java).apply {
            action = ACTION_STOP_FROM_NOTIF
        }
        val stopPending = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Auto Clicker is running")
            .setContentText("Use the floating bar to pause or stop.")
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentIntent(openAppPending)
            .setOngoing(true)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", stopPending)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                startForeground(NOTIF_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE)
            } else {
                startForeground(NOTIF_ID, notification)
            }
        } else {
            startForeground(NOTIF_ID, notification)
        }
    }
}
