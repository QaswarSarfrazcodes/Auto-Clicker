import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_route_names.dart';
import '../../../core/routing/spring_page_route.dart';
import '../../widgets/onboarding/onboarding_scaffold.dart';
import 'onboarding_custom_scripts_screen.dart';
import 'onboarding_no_root_required_screen.dart';

/// Screen 2 — "Automate Repetitive Tasks".
/// First of the three onboarding steps (progress index 0).
class OnboardingAutomateScreen extends StatelessWidget {
  const OnboardingAutomateScreen({super.key});

  void _goToNoRootRequired(BuildContext context) {
    Navigator.of(context).push(
      SpringPageRoute(
        settings: const RouteSettings(
          name: AppRouteNames.onboardingNoRootRequired,
        ),
        builder: (_) => const OnboardingNoRootRequiredScreen(),
      ),
    );
  }

  void _skipToFinalStep(BuildContext context) {
    Navigator.of(context).push(
      SpringPageRoute(
        settings: const RouteSettings(name: AppRouteNames.onboardingCustomScripts),
        builder: (_) => const OnboardingCustomScriptsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      activeIndex: 0,
      illustrationAsset: AppAssets.onboardingAutomateIllustration,
      headline: AppStrings.onboardingAutomateHeadline,
      subtext: AppStrings.onboardingAutomateSubtext,
      showBackButton: false,
      showSkip: true,
      primaryLabel: AppStrings.next,
      onPrimaryPressed: () => _goToNoRootRequired(context),
      onSkipPressed: () => _skipToFinalStep(context),
    );
  }
}
