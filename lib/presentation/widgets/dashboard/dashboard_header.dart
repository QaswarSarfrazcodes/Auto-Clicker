import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../common/app_asset_image.dart';


/// The dashboard's gradient header bar.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.onMenuPressed,
    required this.onSettingsPressed,
  });

  final VoidCallback onMenuPressed;
  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: context.scaleH(AppDimensions.dashboardHeaderHeight),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.dashboardHeaderHorizontalPadding,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.headerGradientStart, AppColors.headerGradientEnd],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.dashboardHeaderBottomRadius),
          bottomRight:
              Radius.circular(AppDimensions.dashboardHeaderBottomRadius),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            InkWell(
              onTap: onMenuPressed,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: AppAssetImage(
                  assetPath: AppIconAssets.menuBar,
                  size: 22,
                  color: Colors.white,
                  fallbackIcon: Icons.menu_rounded,
                  fallbackIconColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                AppStrings.appTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            InkWell(
              onTap: onSettingsPressed,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: AppAssetImage(
                  assetPath: AppIconAssets.settings,
                  size: 22,
                  color: Colors.white,
                  fallbackIcon: Icons.settings_outlined,
                  fallbackIconColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

