/// Feature B — Video-Aware Scroll Hold: platform channel bridge.
///
/// Thin wrapper around the `com.example.auto_clicker/video_hold` MethodChannel
/// declared in MainActivity.kt. Calls are routed to
/// [AutoClickerService.queryVideoPlayback] which cascades through Signals 1→2→3.
///
/// All methods are safe to call even when the Accessibility Service is not
/// running — they return false rather than throwing.
library;

import 'package:flutter/services.dart';

class VideoHoldChannel {
  VideoHoldChannel._();

  static const _channel = MethodChannel('com.example.auto_clicker/video_hold');

  /// Returns true if a video is currently detected as playing for the given
  /// [foregroundPackage] (e.g. `"com.instagram.android"`).
  ///
  /// Pass an empty string when the foreground package is unknown — the native
  /// side will still attempt Signals 2/3 via the Accessibility node tree.
  static Future<bool> isVideoPlaying({String foregroundPackage = ''}) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isVideoPlaying',
        {'foregroundPackage': foregroundPackage},
      );
      return result ?? false;
    } on PlatformException catch (_) {
      // Native side threw — treat as "not playing" so the script is never
      // blocked by an exception in the detection layer.
      return false;
    }
  }

  /// Returns true if the user has granted Notification Access and
  /// [MediaPlaybackListenerService] is currently bound (Signal 1 available).
  static Future<bool> isNotificationAccessGranted() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('isNotificationAccessGranted');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Deep-links to System Settings › Special app access › Notification access.
  static Future<void> openNotificationAccessSettings() async {
    try {
      await _channel.invokeMethod<void>('openNotificationAccessSettings');
    } on PlatformException catch (_) {
      // Ignore — user can navigate manually.
    }
  }
}
