import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../common/app_asset_image.dart';


/// Renders an onboarding illustration from [assetPath] (supports PNG and SVG).
class OnboardingIllustration extends StatelessWidget {
  const OnboardingIllustration({
    super.key,
    required this.assetPath,
    required this.size,
  });

  final String assetPath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AppAssetImage(
      assetPath: assetPath,
      size: size,
      fallbackIcon: Icons.image_outlined,
      fallbackBackgroundColor: AppColors.borderGray.withValues(alpha: 0.35),
    );
  }
}

