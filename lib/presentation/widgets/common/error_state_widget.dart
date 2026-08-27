import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../common/app_text_button.dart';

/// Full-screen centered error state with a retry button.
/// Used when a data-layer call fails instead of silently showing empty state.
class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.dangerRed,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.subtext.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            AppTextButton(
              label: AppStrings.retry,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
