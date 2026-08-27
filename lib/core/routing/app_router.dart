import 'package:flutter/material.dart';

import '../../presentation/screens/click_points/place_click_points_screen.dart';
import '../../presentation/screens/create_script/create_script_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/onboarding/onboarding_automate_screen.dart';
import '../../presentation/screens/onboarding/onboarding_custom_scripts_screen.dart';
import '../../presentation/screens/onboarding/onboarding_no_root_required_screen.dart';
import '../../presentation/screens/permission/accessibility_permission_screen.dart';
import '../../presentation/screens/permission/overlay_permission_screen.dart';
import '../../presentation/screens/running/running_screen.dart';
import '../../presentation/screens/saved_scripts/saved_scripts_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/swipe_parameters/swipe_parameters_screen.dart';
import '../../domain/entities/script_entity.dart';
import 'app_route_names.dart';
import 'spring_page_route.dart';

/// Maps [AppRouteNames] to their screens, wrapping every route in
/// [SpringPageRoute] so the whole app shares the same Figma-matched
/// transition by default.
class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRouteNames.splash:
        return SpringPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
      case AppRouteNames.onboardingAutomate:
        return SpringPageRoute(
          settings: settings,
          builder: (_) => const OnboardingAutomateScreen(),
        );
      case AppRouteNames.onboardingNoRootRequired:
        return SpringPageRoute(
          settings: settings,
          builder: (_) => const OnboardingNoRootRequiredScreen(),
        );
      case AppRouteNames.onboardingCustomScripts:
        return SpringPageRoute(
          settings: settings,
          builder: (_) => const OnboardingCustomScriptsScreen(),
        );
      case AppRouteNames.accessibilityPermission:
        return SpringPageRoute(
          settings: settings,
          builder: (_) => const AccessibilityPermissionScreen(),
        );
      case AppRouteNames.overlayPermission:
        return SpringPageRoute(
          settings: settings,
          builder: (_) => const OverlayPermissionScreen(),
        );
      case AppRouteNames.dashboard:
        return SpringPageRoute(
          settings: settings,
          builder: (_) => const DashboardScreen(),
        );
      case AppRouteNames.createScript:
        return SpringPageRoute(
          settings: settings,
          builder: (_) => const CreateScriptScreen(),
        );
      case AppRouteNames.placeClickPoints:
        return SpringPageRoute(
          settings: settings,
          builder: (_) => const PlaceClickPointsScreen(),
        );
      case AppRouteNames.swipeParameters:
        return SpringPageRoute(
          settings: settings,
          builder: (_) => const SwipeParametersScreen(),
        );
      case AppRouteNames.running:
        final dynamic arg = settings.arguments;
        final ScriptEntity? script = arg is ScriptEntity ? arg : null;
        final String scriptName = arg is String
            ? arg
            : (script?.name ?? 'Auto Scroll');
        return SpringPageRoute(
          settings: settings,
          builder: (_) => RunningScreen(
            scriptName: scriptName,
            script: script,
          ),
        );
      case AppRouteNames.savedScripts:
        return SpringPageRoute(
          settings: settings,
          builder: (_) => const SavedScriptsScreen(),
        );
      case AppRouteNames.settings:
        return SpringPageRoute(
          settings: settings,
          builder: (_) => const SettingsScreen(),
        );
      default:
        return SpringPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
    }
  }
}

