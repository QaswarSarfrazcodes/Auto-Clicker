import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// One card in the dashboard's 2x2 action grid — icon badge, bold title,
/// gray caption.
class DashboardActionCard extends StatelessWidget {
  const DashboardActionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.caption,
    required this.onTap,
    this.filledIconBackground = false,
    this.hasActiveBorder = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String caption;
  final VoidCallback onTap;

  /// True for "New Script" — a solid colored circle behind a white icon.
  final bool filledIconBackground;

  /// True for highlighted card ("New Script") with primary blue border.
  final bool hasActiveBorder;

  @override
  Widget build(BuildContext context) {
    final Widget iconWidget = filledIconBackground
        ? Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          )
        : Icon(
            icon,
            color: iconColor,
            size: 30,
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.dashboardCardRadius),
        child: Container(
          height: AppDimensions.dashboardCardHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius:
                BorderRadius.circular(AppDimensions.dashboardCardRadius),
            border: Border.all(
              color: hasActiveBorder
                  ? AppColors.primaryBlue
                  : AppColors.borderGray.withValues(alpha: 0.8),
              width: hasActiveBorder ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
