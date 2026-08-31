package com.example.auto_clicker.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.example.auto_clicker.service.AutoClickForegroundService
import io.flutter.plugin.common.EventChannel

/**
 * Receives Continue / Stop taps from the Session Fatigue notification
 * while the app is backgrounded, and forwards the choice to Dart
 * over FatigueActionEventStreamHandler (EventChannel).
 */
class FatigueNotificationActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = when (intent.action) {
            AutoClickForegroundService.ACTION_FATIGUE_CONTINUE -> "continue"
            AutoClickForegroundService.ACTION_FATIGUE_STOP -> "stop"
            else -> return
        }
        FatigueActionEventStreamHandler.sink?.success(action)

        // Also forward the intent to the service so it can dismiss the notification
        val serviceIntent = Intent(context, AutoClickForegroundService::class.java).apply {
            this.action = intent.action
        }
        context.startService(serviceIntent)
    }
}

/**
 * EventChannel handler registered once in MainActivity.configureFlutterEngine.
 * Same singleton pattern as every other EventChannel in this project.
 */
object FatigueActionEventStreamHandler : EventChannel.StreamHandler {
    var sink: EventChannel.EventSink? = null
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) { sink = events }
    override fun onCancel(arguments: Any?) { sink = null }
}
