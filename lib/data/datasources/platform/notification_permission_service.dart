import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/util/logger.dart';

/// Requests POST_NOTIFICATIONS permission at runtime on Android 13+ (§16).
///
/// Must be called before starting the foreground service — the ongoing
/// notification shown by AutoClickForegroundService requires this grant.
class NotificationPermissionService {
  NotificationPermissionService._();
  static final NotificationPermissionService instance =
      NotificationPermissionService._();

  /// Returns true if permission is already granted or was just granted.
  /// Returns false if the user denied — the caller should show an explanation.
  Future<bool> ensureGranted() async {
    // Not applicable on iOS (push notifications != foreground service notif),
    // web, or Android < 13 where POST_NOTIFICATIONS didn't exist.
    if (kIsWeb) return true;
    if (!Platform.isAndroid) return true;

    try {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) {
        // User already permanently denied — prompt them to go to settings.
        await openAppSettings();
        return false;
      }
      final result = await Permission.notification.request();
      logDebug(
          'NotificationPermissionService: result=${result.isGranted}');
      return result.isGranted;
    } catch (e) {
      logDebug('NotificationPermissionService.ensureGranted error: $e');
      return false; // fail-safe: let the caller decide
    }
  }
}
