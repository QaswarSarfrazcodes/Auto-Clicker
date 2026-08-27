/// Central registry of route name strings.
///
/// Deliberately has zero imports of its own screens/router — this file
/// only ever exports constants, so any screen can depend on it for
/// `RouteSettings(name: ...)` without ever creating a circular import
/// with `app_router.dart`.
abstract final class AppRouteNames {
  static const String splash = '/splash';
  static const String onboardingAutomate = '/onboarding/automate';
  static const String onboardingNoRootRequired = '/onboarding/no-root-required';
  static const String onboardingCustomScripts = '/onboarding/custom-scripts';
  static const String accessibilityPermission = '/permission/accessibility';
  static const String overlayPermission = '/permission/overlay';
  static const String dashboard = '/dashboard';
  static const String createScript = '/create-script';
  static const String placeClickPoints = '/create-script/place-click-points';
  static const String swipeParameters = '/create-script/swipe-parameters';
  static const String running = '/running';
  static const String savedScripts = '/saved-scripts';
  static const String settings = '/settings';

  const AppRouteNames._();
}

