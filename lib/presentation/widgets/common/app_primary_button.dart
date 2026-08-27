import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

/// The solid `#2380FD` primary button used for "Next", "Get Started",
/// "Enable", etc.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingIcon,
    this.icon,
    this.color,
    this.expand = false,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? trailingIcon;
  final IconData? icon;
  final Color? color;

  /// When true, the button stretches to fill the available width.
  final bool expand;

  /// Optional explicit width — leave null to size to content.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primaryBlue;

    final button = Container(
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(AppDimensions.onboardingButtonRadius),
        boxShadow: [
          BoxShadow(
            color: effectiveColor.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.onboardingButtonRadius),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(label, style: AppTextStyles.buttonLabel),
            if (icon == null && trailingIcon != null) ...[
              const SizedBox(width: 6),
              Icon(trailingIcon, size: 18, color: Colors.white),
            ],
          ],
        ),
      ),
    );

    if (expand) {
      return SizedBox(
        width: double.infinity,
        height: AppDimensions.onboardingButtonHeight,
        child: button,
      );
    }

    return SizedBox(
      width: width,
      height: AppDimensions.onboardingButtonHeight,
      child: button,
    );
  }
}
