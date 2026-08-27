import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../common/app_asset_image.dart';

/// One row in the "Recent Scripts" list — compact colored square icon,
/// name, "Last used: ..." caption, and a circular play button.
class RecentScriptTile extends StatelessWidget {
  const RecentScriptTile({
    super.key,
    required this.iconAssetPath,
    required this.iconFallback,
    required this.iconColor,
    required this.name,
    required this.lastUsedLabel,
    required this.onPlayPressed,
  });

  final String iconAssetPath;
  final IconData iconFallback;
  final Color iconColor;
  final String name;
  final String lastUsedLabel;
  final VoidCallback onPlayPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPlayPressed,
        child: Container(
          height: AppDimensions.dashboardRecentTileHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: AppAssetImage(
                  assetPath: iconAssetPath,
                  size: AppDimensions.dashboardRecentIconSize,
                  fallbackIcon: iconFallback,
                  fallbackIconColor: iconColor,
                  fallbackBackgroundColor: iconColor.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lastUsedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.primaryBlue,
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
