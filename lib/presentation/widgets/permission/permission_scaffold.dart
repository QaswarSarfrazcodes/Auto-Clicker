import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../common/app_back_header.dart';
import '../common/app_primary_button.dart';
import '../common/app_text_button.dart';
import '../onboarding/onboarding_progress_indicator.dart';

/// The single shared template behind the permission steps in onboarding (Steps 3 and 4).
class PermissionScaffold extends StatelessWidget {
  const PermissionScaffold({
    super.key,
    this.activeIndex = 2,
    this.segmentCount = 4,
    this.showProgressIndicator = true,
    this.showBackButton = true,
    required this.icon,
    required this.headline,
    required this.subtext,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.linkLabel,
    required this.onLinkPressed,
  });

  final int activeIndex;
  final int segmentCount;
  final bool showProgressIndicator;
  final bool showBackButton;
  final Widget icon;
  final String headline;
  final String subtext;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final String linkLabel;
  final VoidCallback onLinkPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.permissionHorizontalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppDimensions.onboardingProgressBarTop),
                      if (showProgressIndicator) ...[
                        OnboardingProgressIndicator(
                          activeIndex: activeIndex,
                          segmentCount: segmentCount,
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (showBackButton)
                        InkWell(
                          onTap: () => Navigator.of(context).maybePop(),
                          borderRadius: BorderRadius.circular(20),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.arrow_back_ios_new, size: 18),
                          ),
                        ),
                      const SizedBox(height: AppDimensions.permissionIconTop),
                      Center(child: icon),
                      const SizedBox(height: AppDimensions.permissionHeadlineTopGap),
                      Text(
                        headline,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.onboardingHeadline,
                      ).withFullWidth(),
                      const SizedBox(height: AppDimensions.permissionSubtextTopGap),
                      Text(
                        subtext,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.onboardingSubtext,
                      ).withFullWidth(),
                      const Spacer(),
                      const SizedBox(height: 16),
                      AppPrimaryButton(
                        label: primaryLabel,
                        onPressed: onPrimaryPressed,
                        expand: true,
                      ),
                      const SizedBox(height: AppDimensions.permissionLinkTopGap),
                      Center(
                        child: AppTextButton(
                          label: linkLabel,
                          onPressed: onLinkPressed,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.permissionButtonBottom),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

extension _FullWidthText on Text {
  Widget withFullWidth() => SizedBox(width: double.infinity, child: this);
}
