import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_route_names.dart';
import '../../../core/routing/spring_page_route.dart';
import '../../widgets/onboarding/onboarding_scaffold.dart';
import 'onboarding_custom_scripts_screen.dart';

/// Screen 3 — "No Root Required".
/// Second onboarding step (progress index 1). Shows the back chevron.
class OnboardingNoRootRequiredScreen extends StatelessWidget {
  const OnboardingNoRootRequiredScreen({super.key});

  void _goToCustomScripts(BuildContext context) {
    Navigator.of(context).push(
      SpringPageRoute(
        settings: const RouteSettings(name: AppRouteNames.onboardingCustomScripts),
        builder: (_) => const OnboardingCustomScriptsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isIOS = !kIsWeb && Platform.isIOS;
    final String subtext = isIOS
        ? 'Automate safely using iOS Switch Control recipes and in-app tools.'
        : AppStrings.onboardingNoRootSubtext;

    return OnboardingScaffold(
      activeIndex: 1,
      illustrationAsset: AppAssets.onboardingNoRootIllustration,
      headline: AppStrings.onboardingNoRootHeadline,
      subtext: subtext,
      showBackButton: false,
      showSkip: true,
      primaryLabel: AppStrings.next,
      onPrimaryPressed: () => _goToCustomScripts(context),
      onSkipPressed: () => _goToCustomScripts(context),
    );
  }
}
