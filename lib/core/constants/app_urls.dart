/// External URLs used across the app. Replace placeholder values before release.
abstract final class AppUrls {
  AppUrls._();

  // Legal & support
  static const String termsOfService =
      'https://autoclickerapp.example.com/terms';
  static const String privacyPolicy =
      'https://autoclickerapp.example.com/privacy';
  static const String supportEmail = 'support@autoclickerapp.example.com';

  // Store URLs — update package/app IDs before release
  static const String androidSubscriptions =
      'https://play.google.com/store/account/subscriptions?package=com.example.auto_clicker';
  static const String iosSubscriptions =
      'https://apps.apple.com/account/subscriptions';
  static const String iosAppStore =
      'https://apps.apple.com/app/id000000000'; // TODO: real App Store ID
  static const String rateAndroid =
      'https://play.google.com/store/apps/details?id=com.example.auto_clicker';
}
