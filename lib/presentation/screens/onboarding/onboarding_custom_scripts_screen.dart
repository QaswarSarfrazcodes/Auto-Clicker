import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routing/app_route_names.dart';
import '../../../core/routing/spring_page_route.dart';
import '../../widgets/onboarding/onboarding_scaffold.dart';
import '../permission/accessibility_permission_screen.dart';

/// Screen 4 — "Create Custom Scripts".
/// Final onboarding step (progress index 2). Full-width "Get Started"
/// button instead of the Skip/Next row, per the design.
class OnboardingCustomScriptsScreen extends StatelessWidget {
  const OnboardingCustomScriptsScreen({super.key});

  void _handleGetStarted(BuildContext context) {
    Navigator.of(context).push(
      SpringPageRoute(
        settings: const RouteSettings(
          name: AppRouteNames.accessibilityPermission,
        ),
        builder: (_) => const AccessibilityPermissionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      activeIndex: 2,
      illustrationAsset: AppAssets.onboardingCustomScriptsIllustration,
      headline: AppStrings.onboardingCustomScriptsHeadline,
      subtext: AppStrings.onboardingCustomScriptsSubtext,
      showBackButton: false,
      showSkip: false,
      primaryLabel: AppStrings.getStarted,
      onPrimaryPressed: () => _handleGetStarted(context),
      headlineStyle: AppTextStyles.onboardingHeadline.copyWith(fontSize: 27),
    );
  }
}
