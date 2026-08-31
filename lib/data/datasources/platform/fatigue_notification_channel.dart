import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

import '../../../core/util/logger.dart';

/// Dart MethodChannel wrapper for the native fatigue notification actions.
///
/// On Android: shows a high-priority notification with "Continue" / "Stop"
/// action buttons when the session limit is reached while the app is
/// backgrounded or the phone is locked (FR-A4).
///
/// On iOS: this is a no-op — the in-app ContinueOrStopDialog is the only
/// prompt surface on iOS (background execution already limited per spec §2).
class FatigueNotificationChannel {
  FatigueNotificationChannel._();
  static final FatigueNotificationChannel instance =
      FatigueNotificationChannel._();

  static const _channel =
      MethodChannel('com.example.auto_clicker/fatigue_notification');
  static const _actionChannel =
      EventChannel('com.example.auto_clicker/fatigue_notification_actions');

  bool get _isSupported => !const bool.fromEnvironment('dart.library.html') &&
      Platform.isAndroid;

  /// Shows the "Continue?" notification with Continue/Stop actions.
  Future<void> showContinuePrompt({required String scriptName}) async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod<void>(
          'showContinuePrompt', {'scriptName': scriptName});
    } catch (e) {
      logDebug('FatigueNotificationChannel.showContinuePrompt error: $e');
    }
  }

  /// Dismisses the "Continue?" notification.
  Future<void> dismissContinuePrompt() async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod<void>('dismissContinuePrompt');
    } catch (e) {
      logDebug('FatigueNotificationChannel.dismissContinuePrompt error: $e');
    }
  }

  /// Stream of 'continue' | 'stop' fired when the user taps a notification
  /// action button while the app is backgrounded.
  Stream<String> get actionStream => _actionChannel
      .receiveBroadcastStream()
      .map((e) => e as String)
      .handleError((e) => logDebug('FatigueNotificationChannel stream error: $e'));
}
