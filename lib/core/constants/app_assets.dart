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

  /// Splash screen app icon (screen 1).
  static const String splashAppIcon = '$_imagesBasePath/1_autoclicker_splash_srceen.png';

  /// Onboarding screen 2 illustration (automate tasks).
  static const String onboardingAutomateIllustration =
      '$_imagesBasePath/Automate-Repetitive-Tasks wali screen.svg';

  /// Onboarding screen 3 illustration (no root required).
  static const String onboardingNoRootIllustration =
      '$_imagesBasePath/No-Root-Required_screen.svg';

  /// Onboarding screen 4 illustration (custom scripts).
  static const String onboardingCustomScriptsIllustration =
      '$_imagesBasePath/create_custom_scripts_screen.svg';

  /// Screen 6 illustration — overlay permission.
  static const String overlayPermissionIllustration =
      '$_imagesBasePath/allow_display_all_over_other_apps_screen.svg';

  /// Screen 5 illustration — accessibility permission.
  static const String accessibilityPermissionIllustration =
      '$_imagesBasePath/enable_accesibillity_servicesz-screen.svg';

  /// Screen 13 — Power User avatar image.
  static const String powerUserAvatar =
      '$_imagesBasePath/13_image_in_blue_card.png';


  const AppAssets._();
}

abstract final class AppIconAssets {
  static const String _iconsBasePath = 'assets/icons';

  /// Splash screen loading icon (screen 1).
  static const String splashLoadingIcon =
      '$_iconsBasePath/loading_icon_splash_screen.svg';

  /// Dashboard menu bar icon (screen 7 header).
  static const String menuBar = '$_iconsBasePath/menu_bar_icon.svg';


  /// Dashboard settings gear icon (screen 7 header).
  static const String settings = '$_iconsBasePath/settings_icon.svg';

  /// Dashboard saved script card icon (screen 7 grid).
  static const String savedScript = '$_iconsBasePath/saved_script_icon.svg';

  /// Recent-script tile icon — Instagram (screen 7).
  static const String recentScriptInstagram =
      '$_iconsBasePath/instagram.svg';

  /// Recent-script tile icon — camera (screen 7).
  static const String recentScriptCamera =
      '$_iconsBasePath/camera_icon.svg';

  /// Recent-script tile icon — gaming/farming (screen 7).
  static const String recentScriptGaming =
      '$_iconsBasePath/gaming_framing.png';

  /// Click points overlay circle marker (screen 9).
  static const String circlePoint = '$_iconsBasePath/9_circle_icon.svg';

  /// Running screen pause icon (screen 11).
  static const String pause = '$_iconsBasePath/pause_icon.svg';

  /// Running screen stop icon (screen 11).
  static const String stop = '$_iconsBasePath/11_stop_icon.svg';

  /// Running screen resume icon (screen 11).
  static const String resume =
      '$_iconsBasePath/screen_7_for _recentscripts_screen_11_resume_icon.svg';

  /// Saved scripts FAB plus icon (screen 12).
  static const String plus = '$_iconsBasePath/12_plus_icon.svg';

  /// Settings section header icons (screen 13).
  static const String generalSettings = '$_iconsBasePath/13_geenral_icon.svg';
  static const String automationSettings = '$_iconsBasePath/13_automation_icon.svg';
  static const String contactSupport = '$_iconsBasePath/13_contact_support_icon.svg';

  const AppIconAssets._();
}

