import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_urls.dart';
import '../../../core/util/logger.dart';

/// Opens the device's mail client pre-filled with support details (§9).
///
/// Falls back gracefully: if no mail client is available, [contactSupport]
/// returns `false` so the caller can show the raw email address as a snackbar.
class SupportService {
  SupportService._();
  static final SupportService instance = SupportService._();

  /// [deviceInfo] is appended to the email body — pass package/device info
  /// from package_info_plus / device_info_plus if available.
  Future<bool> contactSupport({String? deviceInfo}) async {
    final body = StringBuffer()
      ..writeln('Describe your issue:')
      ..writeln()
      ..writeln()
      ..writeln('--- App Info ---')
      ..writeln('Version: ${AppStrings.versionValue}');

    if (deviceInfo != null && deviceInfo.isNotEmpty) {
      body
        ..writeln()
        ..writeln('--- Device Info ---')
        ..writeln(deviceInfo);
    }

    final uri = Uri(
      scheme: 'mailto',
      path: AppUrls.supportEmail,
      queryParameters: {
        'subject': AppStrings.supportSubject,
        'body': body.toString(),
      },
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    } catch (e) {
      logDebug('SupportService.contactSupport error: $e');
      return false;
    }
  }
}
