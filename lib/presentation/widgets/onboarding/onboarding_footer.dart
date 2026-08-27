import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../common/app_primary_button.dart';
import '../common/app_text_button.dart';

/// The footer action area shared by all onboarding screens.
///
/// Screens 2 and 3 use the "Skip" + "Next" row ([showSkip] = true).
/// Screen 4 uses a single full-width "Get Started" button ([showSkip] =
/// false) — pass [primaryLabel] to control the button text either way.
class OnboardingFooter extends StatelessWidget {
  const OnboardingFooter({
    super.key,
    required this.onPrimaryPressed,
    this.onSkipPressed,
    this.showSkip = true,
    this.primaryLabel = AppStrings.next,
  });

  final VoidCallback onPrimaryPressed;
  final VoidCallback? onSkipPressed;
  final bool showSkip;
  final String primaryLabel;

  @override
  Widget build(BuildContext context) {
    if (!showSkip) {
      return AppPrimaryButton(
        label: primaryLabel,
        onPressed: onPrimaryPressed,
        expand: true,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppTextButton(
          label: AppStrings.skip,
          onPressed: onSkipPressed ?? onPrimaryPressed,
        ),
        AppPrimaryButton(
          label: primaryLabel,
          onPressed: onPrimaryPressed,
          trailingIcon: Icons.arrow_forward,
        ),
      ],
    );
  }
}
