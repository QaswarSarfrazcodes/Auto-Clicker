import 'package:flutter/foundation.dart';

/// Performance-friendly debug logger.
///
/// Wrapped inside `assert()` so that string interpolation and log overhead
/// are completely tree-shaken out of release builds.
void logDebug(String message) {
  assert(() {
    debugPrint('[AutoClicker] $message');
    return true;
  }());
}
