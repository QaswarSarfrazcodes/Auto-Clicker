/// Centralized color tokens for the Auto Clicker app.
///
/// Every hex value here is copied 1:1 from the Figma dev-mode export —
/// never hardcode a `Color(0x...)` inside a widget, always reference a
/// constant from this file so a design tweak only ever touches one place.
library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  // ---------------------------------------------------------------------
  // Brand / primary
  // ---------------------------------------------------------------------

  /// Primary action color — "Next", "Get Started", "Enable" buttons,
  /// active progress-bar segment.
  static const Color primaryBlue = Color(0xFF2380FD);

  // ---------------------------------------------------------------------
  // Splash screen gradient (exact Figma dev-mode values)
  // ---------------------------------------------------------------------

  /// Splash background gradient — start color (top-left).
  static const Color splashGradientStart = Color(0xFF0655FF);

  /// Splash background gradient — end color (bottom-right), Figma stop @ 10%.
  static const Color splashGradientEnd = Color(0xFF043399);

  // ---------------------------------------------------------------------
  // Surfaces & text
  // ---------------------------------------------------------------------

  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF7F8FA);
  static const Color textPrimary = Color(0xFF1E1E1E);
  static const Color textSecondary = Color(0xFF767676);
  static const Color borderGray = Color(0xFFE0E0E0);

  /// White text/icons at reduced opacity — used for the splash tagline.
  static Color onDarkMuted = Colors.white.withValues(alpha: 0.6);

  // ---------------------------------------------------------------------
  // Dashboard header gradient (screen 7 — exact Figma dev-mode values,
  // "Rectangle 5703": 401x127, top -13, left -5, bottom corners 12px)
  // ---------------------------------------------------------------------

  /// Dashboard header gradient — start color (top).
  static const Color headerGradientStart = Color(0xFF13112C);

  /// Dashboard header gradient — end color (bottom). Same value as
  /// [primaryBlue] in the Figma export.
  static const Color headerGradientEnd = Color(0xFF2380FD);

  // ---------------------------------------------------------------------
  // Secondary accents
  // ---------------------------------------------------------------------

  /// Secondary action color — "Saved Script"/"Export Script" icons.
  static const Color accentOrange = Color(0xFFF58B21);

  /// Recent-script tile accent — Instagram-style entry.
  static const Color accentPink = Color(0xFFE1306C);

  /// Recent-script tile accent — camera/interval-tap entry.
  static const Color accentPurple = Color(0xFF5B4B8A);

  // ---------------------------------------------------------------------
  // Screens 11–13 specific tokens (Running, Saved Scripts, Settings)
  // ---------------------------------------------------------------------

  /// "Pause" button fill on the Running screen (screen 11).
  static const Color pauseAmber = Color(0xFFF5A623);

  /// "Power User" promo card gradient (screen 13).
  static const Color proCardGradientStart = Color(0xFF2380FD);
  static const Color proCardGradientEnd = Color(0xFF1C4FC2);

  /// "Need Help?" card (screen 13).
  static const Color needHelpBackground = Color(0xFFFBE5D6);
  static const Color needHelpButton = Color(0xFF9A4A1E);

  /// Track color for switches in their OFF state (Settings toggles).
  static const Color switchTrackOff = Color(0xFFE0E0E0);

  /// Muted icon tint used for section header glyphs and nav-row chevrons.
  static const Color iconMuted = Color(0xFF9AA0A6);

  // ---------------------------------------------------------------------
  // Status colors
  // ---------------------------------------------------------------------

  static const Color successGreen = Color(0xFF2FB344);
  static const Color dangerRed = Color(0xFFE5484D);
  static const Color warningAmber = Color(0xFFF5A623);

  // ---------------------------------------------------------------------
  // Overlay / scrim
  // ---------------------------------------------------------------------

  /// Semi-transparent dark scrim behind the click-point placement overlay.
  static Color overlayScrim = const Color(0xFF120B2E).withValues(alpha: 0.92);

  const AppColors._();
}

