import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

/// One labeled stat box (e.g. "Clicks" → "1,234"). Used in a row of two
/// for screen 11's Clicks/Runtime pair.
class RunningStatCard extends StatelessWidget {
  const RunningStatCard({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.scaleH(AppDimensions.statCardHeight),
      padding: EdgeInsets.symmetric(
        horizontal: context.scaleW(12),
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      alignment: Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            label,
            style: AppTextStyles.fieldLabel.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.cardTitle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
