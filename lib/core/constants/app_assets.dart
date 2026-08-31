/// Centralized asset paths.
///
/// Drop the exported PNG/SVG files from Figma into `assets/images/` using
/// these exact filenames, and declare the folder once in `pubspec.yaml`:
///
/// ```yaml
/// flutter:
///   assets:
///     - assets/images/
/// ```
library;

abstract final class AppAssets {
  static const String _imagesBasePath = 'assets/images';

  /// Splash screen & app icon (screen 1).
  static const String splashAppIcon = '$_imagesBasePath/app_logoandsplashscreen.webp';

  /// Onboarding screen 1 illustration (automate tasks).
  static const String onboardingAutomateIllustration =
      '$_imagesBasePath/onboarding_automate.webp';

  /// Onboarding screen 2 illustration (no root required).
  static const String onboardingNoRootIllustration =
      '$_imagesBasePath/onboarding_no_root.webp';

  /// Onboarding custom scripts illustration.
  static const String onboardingCustomScriptsIllustration =
      '$_imagesBasePath/onboarding_custom_scripts.webp';

  /// Overlay permission illustration.
  static const String overlayPermissionIllustration =
      '$_imagesBasePath/overlay_permission_illustration.webp';

  /// Accessibility permission illustration.
  static const String accessibilityPermissionIllustration =
      '$_imagesBasePath/accessibility_permission_illustration.webp';

  /// Power User avatar image.
  static const String powerUserAvatar =
      '$_imagesBasePath/power_user_card_illustration.webp';

  const AppAssets._();
}

abstract final class AppIconAssets {
  static const String _iconsBasePath = 'assets/icons';

  /// Splash screen loading icon.
  static const String splashLoadingIcon =
      '$_iconsBasePath/ic_splash_loading.svg';

  /// Dashboard menu bar icon.
  static const String menuBar = '$_iconsBasePath/ic_menu_bar.svg';

  /// Dashboard settings gear icon.
  static const String settings = '$_iconsBasePath/ic_settings.svg';

  /// Dashboard saved script card icon.
  static const String savedScript = '$_iconsBasePath/ic_saved_script.svg';

  /// Recent-script tile icon — Instagram.
  static const String recentScriptInstagram =
      '$_iconsBasePath/ic_instagram.svg';

  /// Recent-script tile icon — camera.
  static const String recentScriptCamera =
      '$_iconsBasePath/ic_camera.svg';

  /// Recent-script tile icon — gaming/farming.
  static const String recentScriptGaming =
      '$_iconsBasePath/ic_gaming.svg';

  /// Click points overlay circle marker.
  static const String circlePoint = '$_iconsBasePath/ic_circle_marker.svg';

  /// Running screen pause icon.
  static const String pause = '$_iconsBasePath/ic_pause.svg';

  /// Running screen stop icon.
  static const String stop = '$_iconsBasePath/ic_stop.svg';

  /// Running screen resume icon.
  static const String resume = '$_iconsBasePath/ic_resume.svg';

  /// Saved scripts FAB plus icon.
  static const String plus = '$_iconsBasePath/ic_plus.svg';

  /// Settings section header icons.
  static const String generalSettings = '$_iconsBasePath/ic_general_settings.svg';
  static const String automationSettings = '$_iconsBasePath/ic_automation_settings.svg';
  static const String contactSupport = '$_iconsBasePath/ic_contact_support.svg';

  const AppIconAssets._();
}

