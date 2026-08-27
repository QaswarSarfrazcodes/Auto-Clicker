import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../core/util/logger.dart';

/// Dart wrapper for the native Automation MethodChannel (Android & iOS).
class NativeAutomationChannel {
  static const MethodChannel _channel = MethodChannel(
    'com.example.auto_clicker/automation',
  );

  static final StreamController<void> _emergencyStopController =
      StreamController<void>.broadcast();

  /// Stream that emits whenever the user hits the hardware Volume Down kill-switch (§0c)
  /// or clicks the Stop button on the system notification.
  static Stream<void> get emergencyStopStream =>
      _emergencyStopController.stream;

  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onEmergencyStop' ||
          call.method == 'onServiceStopRequested') {
        logDebug(
          'NativeAutomationChannel received kill-switch / notification stop signal',
        );
        _emergencyStopController.add(null);
      }
    });
  }

  /// Device pixel ratio to convert logical pixels (dp) to hardware physical screen pixels (px).
  static double get _devicePixelRatio {
    try {
      final views = WidgetsBinding.instance.platformDispatcher.views;
      if (views.isNotEmpty) {
        return views.first.devicePixelRatio;
      }
    } catch (_) {}
    return 1.0;
  }

  /// Whether background gesture injection is supported natively by the OS platform.
  static bool get isNativeGestureSupported => !kIsWeb && Platform.isAndroid;

  /// Check if the native Accessibility Service is enabled and running.
  static Future<bool> isAccessibilityGranted() async {
    if (kIsWeb) return true;
    if (!Platform.isAndroid) {
      return true;
    }
    try {
      final bool? result = await _channel.invokeMethod<bool>(
        'isAccessibilityGranted',
      );
      return result ?? false;
    } catch (e) {
      logDebug('NativeAutomationChannel isAccessibilityGranted error: $e');
      return false;
    }
  }

  /// Open system Accessibility Settings page.
  static Future<bool> openAccessibilitySettings() async {
    if (kIsWeb) return true;
    try {
      final bool? result = await _channel.invokeMethod<bool>(
        'openAccessibilitySettings',
      );
      return result ?? false;
    } catch (e) {
      logDebug('NativeAutomationChannel openAccessibilitySettings error: $e');
      return false;
    }
  }

  /// Check if Display Over Other Apps (SYSTEM_ALERT_WINDOW) permission is granted.
  static Future<bool> isOverlayGranted() async {
    if (kIsWeb || !Platform.isAndroid) {
      return true;
    }
    try {
      final bool? result = await _channel.invokeMethod<bool>(
        'isOverlayGranted',
      );
      return result ?? false;
    } catch (e) {
      logDebug('NativeAutomationChannel isOverlayGranted error: $e');
      return false;
    }
  }

  /// Open system Overlay Permission Settings page.
  static Future<bool> openOverlaySettings() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final bool? result = await _channel.invokeMethod<bool>(
        'openOverlaySettings',
      );
      return result ?? false;
    } catch (e) {
      logDebug('NativeAutomationChannel openOverlaySettings error: $e');
      return false;
    }
  }

  /// Dispatch a single tap/click gesture.
  /// (x, y) are in Flutter logical pixels (dp). They are converted to physical hardware pixels for Android.
  static Future<bool> dispatchClick(
    double x,
    double y, {
    int durationMs = 50,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final double dpr = _devicePixelRatio;
      final bool? result = await _channel.invokeMethod<bool>('dispatchClick', {
        'x': x * dpr,
        'y': y * dpr,
        'duration': durationMs,
      });
      return result ?? false;
    } catch (e) {
      logDebug('NativeAutomationChannel dispatchClick error: $e');
      return false;
    }
  }

  /// Dispatch a swipe gesture from (startX, startY) to (endX, endY).
  /// Coordinates are in Flutter logical pixels (dp) and converted to physical pixels for Android.
  static Future<bool> dispatchSwipe(
    double startX,
    double startY,
    double endX,
    double endY, {
    int durationMs = 300,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      final double dpr = _devicePixelRatio;
      final bool? result = await _channel.invokeMethod<bool>('dispatchSwipe', {
        'startX': startX * dpr,
        'startY': startY * dpr,
        'endX': endX * dpr,
        'endY': endY * dpr,
        'duration': durationMs,
      });
      return result ?? false;
    } catch (e) {
      logDebug('NativeAutomationChannel dispatchSwipe error: $e');
      return false;
    }
  }

  /// Start Android foreground service with ongoing notification (§11).
  static Future<void> startForegroundService() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('startForegroundService');
    } catch (e) {
      logDebug('NativeAutomationChannel startForegroundService error: $e');
    }
  }

  /// Stop Android foreground service (§11).
  static Future<void> stopForegroundService() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stopForegroundService');
    } catch (e) {
      logDebug('NativeAutomationChannel stopForegroundService error: $e');
    }
  }

  /// Move the Android activity behind the target app without stopping execution.
  static Future<void> minimizeApp() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('minimizeApp');
    } catch (e) {
      logDebug('NativeAutomationChannel minimizeApp error: $e');
    }
  }
}
