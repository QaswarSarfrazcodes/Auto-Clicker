import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../common/app_back_header.dart';
import '../common/app_primary_button.dart';
import '../common/app_text_button.dart';

/// The single shared template behind the two permission screens (5 and 6).
/// Each screen only supplies its icon/illustration, copy, and button
/// behavior — the layout itself lives here exactly once.
class PermissionScaffold extends StatelessWidget {
  const PermissionScaffold({
    super.key,
    required this.icon,
    required this.headline,
    required this.subtext,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    required this.linkLabel,
    required this.onLinkPressed,
  });

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
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.permissionHorizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.permissionBackButtonTop),
              const AppBackHeader(),
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
  }
}

extension _FullWidthText on Text {
  Widget withFullWidth() => SizedBox(width: double.infinity, child: this);
}
