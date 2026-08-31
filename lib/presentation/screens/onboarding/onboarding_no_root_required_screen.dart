import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_route_names.dart';
import '../../../core/routing/spring_page_route.dart';
import '../../widgets/onboarding/onboarding_scaffold.dart';
import '../permission/overlay_permission_screen.dart';

/// Screen 3 — "No Root Required".
/// Step 2 of 4 onboarding steps (progress index 1).
class OnboardingNoRootRequiredScreen extends StatelessWidget {
  const OnboardingNoRootRequiredScreen({super.key});

  void _goToOverlayPermission(BuildContext context) {
    Navigator.of(context).push(
      SpringPageRoute(
        settings: const RouteSettings(name: AppRouteNames.overlayPermission),
        builder: (_) => const OverlayPermissionScreen(),
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
      segmentCount: 4,
      illustrationAsset: AppAssets.onboardingNoRootIllustration,
      headline: AppStrings.onboardingNoRootHeadline,
      subtext: subtext,
      showBackButton: true,
      showSkip: true,
      primaryLabel: AppStrings.next,
      onPrimaryPressed: () => _goToOverlayPermission(context),
      onSkipPressed: () => _goToOverlayPermission(context),
    );
  }
}
