import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  /// "Automate Repetitive Tasks" style onboarding headline.
  static const TextStyle onboardingHeadline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: Color(0xFF131130),
    height: 1.25,
    letterSpacing: -0.4,
  );

  /// Onboarding subtext under the headline.
  static const TextStyle onboardingSubtext = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xFF6B7280),
    height: 1.45,
  );

  /// General subtext style.
  static const TextStyle subtext = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  /// Primary filled-button label ("Next", "Get Started").
  static const TextStyle buttonLabel = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: -0.2,
  );

  /// "Skip" text button label.
  static const TextStyle textButtonLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Color(0xFF131130),
  );

  /// Splash screen "Auto" (regular weight part of the wordmark).
  static const TextStyle splashWordmarkRegular = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    letterSpacing: -0.3,
  );

  /// Splash screen "Clicker" (bold/highlighted pill part of the wordmark).
  static const TextStyle splashWordmarkBold = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: -0.3,
  );

  /// Splash tagline ("Automates Taps & Swipes").
  static const TextStyle splashTagline = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
    letterSpacing: 0.1,
  );

  /// Card/Item title text style.
  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Field label text style.
  static const TextStyle fieldLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  const AppTextStyles._();
}
