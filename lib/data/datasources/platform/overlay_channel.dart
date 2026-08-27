import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

import '../../../core/util/logger.dart';

/// Dart wrapper for the floating overlay MethodChannel (Android-only, §1).
///
/// On iOS this class is always a no-op — iOS doesn't allow third-party apps
/// to draw windows over other apps the way TYPE_APPLICATION_OVERLAY permits
/// on Android.
///
/// Now exposes [startPointPicker] / [stopPointPicker] and the
/// [onPointCaptured] stream for the live-screen coordinate picker feature (Phase B).
class OverlayChannel {
  OverlayChannel._();
  static final OverlayChannel instance = OverlayChannel._();

  static const MethodChannel _channel =
      MethodChannel('com.example.auto_clicker/overlay');

  // Stream controller for point-picker coordinate events
  static final StreamController<Map<String, double>> _pointCapturedController =
      StreamController<Map<String, double>>.broadcast();

  // Stream controller for picker "Done" event
  static final StreamController<void> _pickerDoneController =
      StreamController<void>.broadcast();

  bool get _isSupported => Platform.isAndroid;

  // ─────────────────────────────────────────────────────────────────────────
  // Control Bar API
  // ─────────────────────────────────────────────────────────────────────────

  /// Show the floating control bar over the current foreground app.
  Future<void> show() async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod<void>('show');
    } catch (e) {
      logDebug('OverlayChannel.show error: $e');
    }
  }

  /// Hide and destroy the floating control bar.
  Future<void> hide() async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod<void>('hide');
    } catch (e) {
      logDebug('OverlayChannel.hide error: $e');
    }
  }

  /// Push live state (running/paused + click count) into the overlay view.
  Future<void> update({
    required bool isRunning,
    required int clickCount,
  }) async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod<void>('update', {
        'isRunning': isRunning,
        'clickCount': clickCount,
      });
    } catch (e) {
      logDebug('OverlayChannel.update error: $e');
    }
  }

  /// Returns true if SYSTEM_ALERT_WINDOW permission is granted.
  Future<bool> hasPermission() async {
    if (!_isSupported) return true;
    try {
      return await _channel.invokeMethod<bool>('hasOverlayPermission') ?? false;
    } catch (e) {
      logDebug('OverlayChannel.hasPermission error: $e');
      return false;
    }
  }

  /// Open the system Overlay Permission settings page.
  Future<void> requestPermission() async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod<void>('requestOverlayPermission');
    } catch (e) {
      logDebug('OverlayChannel.requestPermission error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Point Picker API (Phase B)
  // ─────────────────────────────────────────────────────────────────────────

  /// Activate the live-screen point picker.
  ///
  /// [mode] is either `"click"` (unlimited taps) or `"swipe"` (auto-closes
  /// after 2 taps — start + end point).
  ///
  /// After calling this the app is minimized so the user can navigate to
  /// their target app. Listen to [onPointCaptured] for each coordinate and
  /// [onPickerDone] to know when the user tapped "Done".
  Future<void> startPointPicker({String mode = 'click'}) async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod<void>('startPointPicker', {'mode': mode});
    } catch (e) {
      logDebug('OverlayChannel.startPointPicker error: $e');
    }
  }

  /// Deactivate the point picker overlay and discard all pending taps.
  Future<void> stopPointPicker() async {
    if (!_isSupported) return;
    try {
      await _channel.invokeMethod<void>('stopPointPicker');
    } catch (e) {
      logDebug('OverlayChannel.stopPointPicker error: $e');
    }
  }

  /// Stream of physical screen coordinates (in pixels) captured by the point picker.
  /// Each event is `{'x': double, 'y': double}`.
  Stream<Map<String, double>> get onPointCaptured =>
      _pointCapturedController.stream;

  /// Emits once when the user taps the "Done" button in point-picker mode.
  Stream<void> get onPickerDone => _pickerDoneController.stream;

  // ─────────────────────────────────────────────────────────────────────────
  // Callbacks (control bar + point picker → Flutter)
  // ─────────────────────────────────────────────────────────────────────────

  /// Register callbacks for overlay button taps that happen while the Flutter
  /// engine is backgrounded (Play/Pause and Stop buttons on the floating bar),
  /// and point-picker coordinate events.
  void bindCallbacks({
    required VoidCallback onPlayPause,
    required VoidCallback onStop,
  }) {
    if (!_isSupported) return;
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onPlayPauseTapped':
          onPlayPause();
          break;
        case 'onStopTapped':
          onStop();
          break;
        case 'onPointCaptured':
          final args = call.arguments as Map<dynamic, dynamic>;
          _pointCapturedController.add({
            'x': (args['x'] as num).toDouble(),
            'y': (args['y'] as num).toDouble(),
          });
          break;
        case 'onPickerDone':
          _pickerDoneController.add(null);
          break;
      }
    });
  }
}
