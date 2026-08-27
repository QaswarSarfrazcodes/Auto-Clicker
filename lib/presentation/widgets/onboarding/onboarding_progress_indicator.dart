import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// The 3-segment progress bar at the top of every onboarding screen.
/// Only the currently [activeIndex] segment is filled in [AppColors.primaryBlue],
/// while others remain [Color(0xFFE5E7EB)].
class OnboardingProgressIndicator extends StatelessWidget {
  const OnboardingProgressIndicator({
    super.key,
    required this.activeIndex,
    this.segmentCount = 3,
  });

  final int activeIndex;
  final int segmentCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(segmentCount * 2 - 1, (i) {
        if (i.isOdd) {
          return const SizedBox(width: AppDimensions.onboardingProgressBarGap);
        }
        final segmentIndex = i ~/ 2;
        final isActive = segmentIndex == activeIndex;
        return Expanded(
          child: Container(
            height: AppDimensions.onboardingProgressBarHeight,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primaryBlue
                  : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
