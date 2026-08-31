import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import 'onboarding_footer.dart';
import 'onboarding_illustration.dart';
import 'onboarding_progress_indicator.dart';

/// The single shared template behind onboarding screens 2, 3 and 4.
///
/// Every screen file just supplies its own copy/asset/behavior through
/// these parameters — no screen re-implements the layout, so the three
/// screens can never visually drift apart from each other.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.activeIndex,
    this.segmentCount = 4,
    required this.illustrationAsset,
    required this.headline,
    required this.subtext,
    required this.onPrimaryPressed,
    this.onSkipPressed,
    this.showBackButton = false,
    this.showSkip = true,
    this.primaryLabel = 'Next',
    this.headlineStyle,
  });

  final int activeIndex;
  final int segmentCount;
  final String illustrationAsset;
  final String headline;
  final String subtext;
  final VoidCallback onPrimaryPressed;
  final VoidCallback? onSkipPressed;
  final bool showBackButton;
  final bool showSkip;
  final String primaryLabel;
  final TextStyle? headlineStyle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.onboardingHorizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.onboardingProgressBarTop),
              if (showBackButton)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back_ios_new, size: 18),
                    ),
                  ),
                ),
              OnboardingProgressIndicator(activeIndex: activeIndex),
              const SizedBox(height: AppDimensions.onboardingIllustrationTop),
              Center(
                child: OnboardingIllustration(
                  assetPath: illustrationAsset,
                  size: AppDimensions.onboardingIllustrationSize,
                ),
              ),
              const SizedBox(height: AppDimensions.onboardingHeadlineTopGap),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: headlineStyle ?? AppTextStyles.onboardingHeadline,
              ).withFullWidth(),
              const SizedBox(height: AppDimensions.onboardingSubtextTopGap),
              Text(
                subtext,
                textAlign: TextAlign.center,
                style: AppTextStyles.onboardingSubtext,
              ).withFullWidth(),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(
                  bottom: AppDimensions.onboardingFooterBottom,
                ),
                child: OnboardingFooter(
                  onPrimaryPressed: onPrimaryPressed,
                  onSkipPressed: onSkipPressed,
                  showSkip: showSkip,
                  primaryLabel: primaryLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiny private extension so headline/subtext `Text` widgets stretch to
/// the full row width (needed for `TextAlign.center` to actually center).
extension _FullWidthText on Text {
  Widget withFullWidth() => SizedBox(width: double.infinity, child: this);
}
