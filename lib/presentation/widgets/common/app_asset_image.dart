import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_colors.dart';

/// Renders an image or SVG icon from [assetPath], falling back to [fallbackIcon]
/// inside a soft rounded box if the asset is missing or fails to load.
class AppAssetImage extends StatelessWidget {
  const AppAssetImage({
    super.key,
    required this.assetPath,
    required this.size,
    this.width,
    this.height,
    this.color,
    this.fallbackIcon = Icons.image_outlined,
    this.fallbackIconColor,
    this.fallbackBackgroundColor,
  });

  final String assetPath;
  final double size;
  final double? width;
  final double? height;
  final Color? color;
  final IconData fallbackIcon;
  final Color? fallbackIconColor;
  final Color? fallbackBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width ?? size;
    final effectiveHeight = height ?? size;

    final isSvg = assetPath.toLowerCase().endsWith('.svg');

    Widget fallbackWidget() => DecoratedBox(
          decoration: BoxDecoration(
            color: fallbackBackgroundColor ??
                AppColors.borderGray.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(size * 0.2),
          ),
          child: Center(
            child: Icon(
              fallbackIcon,
              color: fallbackIconColor ?? AppColors.textSecondary,
              size: size * 0.45,
            ),
          ),
        );

    return SizedBox(
      width: effectiveWidth,
      height: effectiveHeight,
      child: isSvg
          ? SvgPicture.asset(
              assetPath,
              width: effectiveWidth,
              height: effectiveHeight,
              fit: BoxFit.contain,
              colorFilter: color != null
                  ? ColorFilter.mode(color!, BlendMode.srcIn)
                  : null,
              placeholderBuilder: (_) => fallbackWidget(),
            )
          : Image.asset(
              assetPath,
              width: effectiveWidth,
              height: effectiveHeight,
              cacheWidth: (effectiveWidth * (MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0)).round(),
              cacheHeight: (effectiveHeight * (MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0)).round(),
              fit: BoxFit.contain,
              color: color,
              errorBuilder: (context, error, stackTrace) => fallbackWidget(),
            ),
    );
  }
}
