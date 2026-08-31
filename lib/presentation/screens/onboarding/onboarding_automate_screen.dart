import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_route_names.dart';
import '../../../core/routing/spring_page_route.dart';
import '../../widgets/onboarding/onboarding_scaffold.dart';
import 'onboarding_no_root_required_screen.dart';
import '../permission/overlay_permission_screen.dart';

/// Screen 2 — "Automate Repetitive Tasks".
/// Step 1 of 4 onboarding steps (progress index 0).
class OnboardingAutomateScreen extends StatelessWidget {
  const OnboardingAutomateScreen({super.key});

  void _goToStepTwo(BuildContext context) {
    Navigator.of(context).push(
      SpringPageRoute(
        settings: const RouteSettings(name: AppRouteNames.onboardingNoRootRequired),
        builder: (_) => const OnboardingNoRootRequiredScreen(),
      ),
    );
  }

  void _skipToPermissions(BuildContext context) {
    Navigator.of(context).push(
      SpringPageRoute(
        settings: const RouteSettings(name: AppRouteNames.overlayPermission),
        builder: (_) => const OverlayPermissionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      activeIndex: 0,
      segmentCount: 4,
      illustrationAsset: AppAssets.onboardingAutomateIllustration,
      headline: AppStrings.onboardingAutomateHeadline,
      subtext: AppStrings.onboardingAutomateSubtext,
      showBackButton: false,
      showSkip: true,
      primaryLabel: AppStrings.next,
      onPrimaryPressed: () => _goToStepTwo(context),
      onSkipPressed: () => _skipToPermissions(context),
    );
  }
}
