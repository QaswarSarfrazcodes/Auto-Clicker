/// Design-scale sizing system.
///
/// The Figma frame for this project is exactly 390x844 (see the "Layout"
/// panel in the design file). Every size/position constant below is taken
/// directly from that frame. To move, resize, or "zoom" any element on any
/// screen, change the number here — nothing else in the widget tree should
/// ever contain a raw pixel value.
library;

import 'package:flutter/material.dart';

/// The reference frame the whole design was built at.
abstract final class AppDimensions {
  static const double figmaFrameWidth = 390;
  static const double figmaFrameHeight = 844;

  // ---------------------------------------------------------------------
  // Splash screen (Figma layer measurements)
  // ---------------------------------------------------------------------

  /// App icon badge — Width/Height from Figma "Image" inspector.
  static const double splashIconSize = 104;

  /// App icon badge — Top offset from Figma "Layout" inspector.
  static const double splashIconTop = 312;

  static const double splashIconCornerRadius = 24;
  static const double splashWordmarkTopGap = 20;
  static const double splashTaglineTopGap = 8;
  static const double splashSpinnerTopGap = 40;
  static const double splashSpinnerSize = 22;

  // ---------------------------------------------------------------------
  // Onboarding template (shared by screens 2, 3, 4)
  // ---------------------------------------------------------------------

  static const double onboardingHorizontalPadding = 28; // ~7-8% of 390
  static const double onboardingProgressBarTop = 24;
  static const double onboardingProgressBarHeight = 4;
  static const double onboardingProgressBarGap = 6;
  static const double onboardingIllustrationTop = 90;
  static const double onboardingIllustrationSize = 180;
  static const double onboardingHeadlineTopGap = 110;
  static const double onboardingSubtextTopGap = 12;
  static const double onboardingFooterBottom = 40;
  static const double onboardingButtonHeight = 52;
  static const double onboardingButtonRadius = 14;

  // ---------------------------------------------------------------------
  // Permission template (shared by screens 5, 6)
  // ---------------------------------------------------------------------

  static const double permissionHorizontalPadding = 28;
  static const double permissionBackButtonTop = 16;
  static const double permissionIconTop = 90;
  static const double permissionIconSize = 120;
  static const double permissionBadgeSize = 96;
  static const double permissionHeadlineTopGap = 40;
  static const double permissionSubtextTopGap = 12;
  static const double permissionButtonBottom = 32;
  static const double permissionLinkTopGap = 16;

  // ---------------------------------------------------------------------
  // Dashboard header (screen 7 — Figma "Rectangle 5703": 401x127,
  // top -13, left -5, bottom-left/right radius 12)
  // ---------------------------------------------------------------------

  static const double dashboardHeaderHeight = 127;
  static const double dashboardHeaderBottomRadius = 12;
  static const double dashboardHeaderHorizontalPadding = 20;
  static const double dashboardContentHorizontalPadding = 20;
  static const double dashboardGridGap = 14;
  static const double dashboardCardHeight = 120;
  static const double dashboardCardRadius = 16;
  static const double dashboardIconBadgeSize = 40;
  static const double dashboardRecentTileHeight = 48;
  static const double dashboardRecentIconSize = 28;
  static const double dashboardSectionGap = 24;

  // ---------------------------------------------------------------------
  // Simple back+title header (shared by screens 8, 10 and others)
  // ---------------------------------------------------------------------

  static const double headerTop = 16;
  static const double headerHeight = 44;
  static const double formHorizontalPadding = 24;
  static const double formFieldGap = 20;
  static const double formFieldHeight = 52;
  static const double formFieldRadius = 12;
  static const double formSectionGap = 28;
  static const double formButtonHeight = 52;

  // ---------------------------------------------------------------------
  // Click-point overlay (screen 9)
  // ---------------------------------------------------------------------

  static const double overlayBannerTop = 16;
  static const double overlayMarkerSize = 28;
  static const double overlayMarkerBadgeSize = 16;
  static const double overlaySheetRadius = 20;
  static const double overlaySheetPadding = 24;

  // ---------------------------------------------------------------------
  // Screen 11 — Running
  // ---------------------------------------------------------------------

  static const double statCardHeight = 76;
  static const double statCardGap = 12;
  static const double actionButtonHeight = 52;
  static const double actionButtonGap = 12;
  static const double statusDotSize = 10;

  // ---------------------------------------------------------------------
  // Screen 12 — Saved Scripts
  // ---------------------------------------------------------------------

  static const double filterTabHeight = 40;
  static const double scriptTileHeight = 72;
  static const double scriptTileGap = 12;
  static const double fabSize = 56;

  // ---------------------------------------------------------------------
  // Screen 13 — Settings
  // ---------------------------------------------------------------------

  static const double sectionHeaderIconSize = 18;
  static const double toggleRowVerticalPadding = 14;
  static const double promoCardPadding = 18;

  /// Power User card avatar image size & position adjustments (screen 13).
  /// Change these numbers to resize (small/large) or move (up/down, left/right):
  static const double promoCardAvatarSize = 36;
  static const double promoCardAvatarWidth = 36;
  static const double promoCardAvatarHeight = 36;
  static const double promoCardAvatarTopOffset = 0; // + moves down, - moves up
  static const double promoCardAvatarLeftOffset = 0; // + moves right, - moves left

  static const double needHelpIconSize = 44;


  const AppDimensions._();
}


/// Scales a "Figma pixel" value to the current device using the same
/// width/height ratio the design frame was built at. This is what lets
/// every screen stay pixel-identical to the design at 390x844 and scale
/// proportionally (not distorted) on any other screen size.
extension DesignScaleContext on BuildContext {
  Size get _screenSize => MediaQuery.of(this).size;

  double get widthScale => _screenSize.width / AppDimensions.figmaFrameWidth;

  double get heightScale =>
      _screenSize.height / AppDimensions.figmaFrameHeight;

  /// Scales a horizontal Figma value (x position or width).
  double scaleW(double figmaPx) => figmaPx * widthScale;

  /// Scales a vertical Figma value (y position or height).
  double scaleH(double figmaPx) => figmaPx * heightScale;

  /// Scales a value that should stay visually uniform (icon sizes,
  /// corner radii, font-independent spacing) using the smaller of the two
  /// axis scales, so it never stretches oddly on unusual aspect ratios.
  double scaleUniform(double figmaPx) =>
      figmaPx * (widthScale < heightScale ? widthScale : heightScale);
}
