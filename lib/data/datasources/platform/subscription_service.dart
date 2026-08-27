import 'dart:io' show Platform;

import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_urls.dart';
import '../../../core/util/logger.dart';

/// Opens the platform's subscription management page (§8).
class SubscriptionService {
  SubscriptionService._();
  static final SubscriptionService instance = SubscriptionService._();

  Future<void> openManageSubscription() async {
    final uri = Uri.parse(
      Platform.isAndroid
          ? AppUrls.androidSubscriptions
          : AppUrls.iosSubscriptions,
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      logDebug('SubscriptionService.openManageSubscription error: $e');
    }
  }

  /// Open store listing page (also used for rating from the drawer).
  Future<void> openStoreListing() async {
    final uri = Uri.parse(
      Platform.isAndroid ? AppUrls.rateAndroid : AppUrls.iosAppStore,
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      logDebug('SubscriptionService.openStoreListing error: $e');
    }
  }
}
