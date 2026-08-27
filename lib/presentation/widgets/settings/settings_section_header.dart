import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

import '../common/app_asset_image.dart';

/// Small icon + bold label heading above a group of settings rows.
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({
    super.key,
    this.icon,
    this.iconAssetPath,
    required this.title,
  });

  final IconData? icon;
  final String? iconAssetPath;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (iconAssetPath != null)
          AppAssetImage(
            assetPath: iconAssetPath!,
            size: AppDimensions.sectionHeaderIconSize,
            color: AppColors.primaryBlue,
            fallbackIcon: icon ?? Icons.grid_view_rounded,
            fallbackIconColor: AppColors.primaryBlue,
          )
        else
          Icon(
            icon ?? Icons.grid_view_rounded,
            size: AppDimensions.sectionHeaderIconSize,
            color: AppColors.primaryBlue,
          ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.cardTitle.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

