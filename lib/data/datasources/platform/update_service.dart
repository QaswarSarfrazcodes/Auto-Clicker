import 'dart:io' show Platform;

import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_urls.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/util/logger.dart';

/// Handles in-app update checking (§6).
/// Android: deep-links to Play Store listing (in_app_update would need
///   Google Play Services at build time — url_launcher is simpler and works
///   on all devices including sideloaded APKs).
/// iOS: opens App Store listing.
class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  Future<String> checkForUpdates() async {
    try {
      final Uri uri = Platform.isAndroid
          ? Uri.parse(AppUrls.rateAndroid)
          : Uri.parse(AppUrls.iosAppStore);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return Platform.isIOS
            ? AppStrings.openedAppStore
            : AppStrings.checkingForUpdates;
      }
      return AppStrings.somethingWentWrong;
    } catch (e) {
      logDebug('UpdateService.checkForUpdates error: $e');
      return AppStrings.somethingWentWrong;
    }
  }
}
