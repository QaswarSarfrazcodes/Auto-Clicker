import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';

import '../../../core/constants/app_assets.dart';
import '../common/app_asset_image.dart';

/// "Power User — Pro Version Active" promo banner (screen 13).
class PowerUserCard extends StatelessWidget {
  const PowerUserCard({super.key, required this.onManageSubscription});

  final VoidCallback onManageSubscription;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.promoCardPadding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.proCardGradientStart,
            AppColors.proCardGradientEnd,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Transform.translate(
                offset: const Offset(
                  AppDimensions.promoCardAvatarLeftOffset,
                  AppDimensions.promoCardAvatarTopOffset,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AppAssetImage(
                    assetPath: AppAssets.powerUserAvatar,
                    size: AppDimensions.promoCardAvatarSize,
                    width: AppDimensions.promoCardAvatarWidth,
                    height: AppDimensions.promoCardAvatarHeight,
                    fallbackIcon: Icons.person,
                    fallbackIconColor: Colors.white,
                    fallbackBackgroundColor:
                        Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
              const SizedBox(width: 12),


              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.powerUserTitle,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    AppStrings.powerUserStatus,
                    style: AppTextStyles.fieldLabel.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.powerUserDescription,
            style: AppTextStyles.fieldLabel.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onManageSubscription,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.proCardGradientStart,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                AppStrings.manageSubscriptionButton,
                style: AppTextStyles.buttonLabel.copyWith(
                  color: AppColors.proCardGradientStart,
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
