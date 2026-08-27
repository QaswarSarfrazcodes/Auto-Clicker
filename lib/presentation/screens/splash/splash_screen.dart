import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/routing/app_route_names.dart';
import '../../../core/routing/spring_page_route.dart';
import '../onboarding/onboarding_automate_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../../../data/datasources/preferences_local_datasource.dart';

/// Screen 1 — Splash.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _minSplashDuration = Duration(milliseconds: 1000);

  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    final startTime = DateTime.now();

    final prefs = PreferencesLocalDataSource.instance;
    final isOnboardingComplete = await prefs.isOnboardingComplete();

    final elapsed = DateTime.now().difference(startTime);
    final remaining = _minSplashDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (!mounted) return;

    if (isOnboardingComplete) {
      Navigator.of(context).pushReplacement(
        SpringPageRoute(
          settings: const RouteSettings(name: AppRouteNames.dashboard),
          builder: (_) => const DashboardScreen(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        SpringPageRoute(
          settings: const RouteSettings(name: AppRouteNames.onboardingAutomate),
          builder: (_) => const OnboardingAutomateScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0052FF),
              Color(0xFF0038B8),
              Color(0xFF021B79),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: const Center(
          child: _SplashBrandColumn(),
        ),
      ),
    );
  }
}

/// The centered icon badge + wordmark + tagline + spinner stack.
class _SplashBrandColumn extends StatelessWidget {
  const _SplashBrandColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // App Icon Badge
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: const Color(0xFF1E80FF),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              AppAssets.splashAppIcon,
              width: 54,
              height: 54,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.ads_click_rounded,
                color: Colors.white,
                size: 54,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Wordmark: "Auto" + highlighted blue pill "Clicker"
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              AppStrings.splashWordmarkRegular,
              style: AppTextStyles.splashWordmarkRegular,
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF1E80FF),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E80FF).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                AppStrings.splashWordmarkBold,
                style: AppTextStyles.splashWordmarkBold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Tagline
        const Text(
          AppStrings.splashTagline,
          style: AppTextStyles.splashTagline,
        ),

        const SizedBox(height: 36),

        // Circular ring spinner
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        ),
      ],
    );
  }
}
