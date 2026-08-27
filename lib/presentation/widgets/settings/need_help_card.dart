import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';

import '../../../core/constants/app_assets.dart';
import '../common/app_asset_image.dart';

/// Light-peach support card with a headset icon, description, and a
/// filled "Contact Support" button (screen 13, bottom).
class NeedHelpCard extends StatelessWidget {
  const NeedHelpCard({super.key, required this.onContactSupport});

  final VoidCallback onContactSupport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.promoCardPadding),
      decoration: BoxDecoration(
        color: AppColors.needHelpBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: AppDimensions.needHelpIconSize,
            height: AppDimensions.needHelpIconSize,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.needHelpButton, width: 1.2),
            ),
            child: const AppAssetImage(
              assetPath: AppIconAssets.contactSupport,
              size: 24,
              color: AppColors.needHelpButton,
              fallbackIcon: Icons.headset_mic_outlined,
              fallbackIconColor: AppColors.needHelpButton,
            ),
          ),

          const SizedBox(height: 10),
          Text(
            AppStrings.needHelpTitle,
            style: AppTextStyles.cardTitle.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.needHelpDescription,
            textAlign: TextAlign.center,
            style: AppTextStyles.fieldLabel.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContactSupport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.needHelpButton,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                AppStrings.contactSupportButton,
                style: AppTextStyles.buttonLabel.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
