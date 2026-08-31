import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_route_names.dart';
import '../../../core/routing/spring_page_route.dart';
import '../../widgets/common/app_asset_image.dart';
import '../../widgets/permission/permission_scaffold.dart';
import '../dashboard/dashboard_screen.dart';
import '../../../data/datasources/native_automation_channel.dart';
import '../../../data/datasources/preferences_local_datasource.dart';

/// Screen 6 — "Enable Accessibility Services".
/// Step 4 of 4 onboarding steps (progress index 3).
class AccessibilityPermissionScreen extends StatefulWidget {
  const AccessibilityPermissionScreen({super.key});

  @override
  State<AccessibilityPermissionScreen> createState() =>
      _AccessibilityPermissionScreenState();
}

class _AccessibilityPermissionScreenState
    extends State<AccessibilityPermissionScreen> with WidgetsBindingObserver {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isChecking) {
      _checkPermissionAndNavigate();
    }
  }

  Future<void> _checkPermissionAndNavigate() async {
    setState(() => _isChecking = false);
    for (int attempt = 0; attempt < 3; attempt++) {
      final bool granted = await NativeAutomationChannel.isAccessibilityGranted();
      if (granted && mounted) {
        await PreferencesLocalDataSource.instance.setOnboardingComplete(true);
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            SpringPageRoute(
              settings: const RouteSettings(name: AppRouteNames.dashboard),
              builder: (_) => const DashboardScreen(),
            ),
            (route) => false,
          );
        }
        return;
      }
      if (attempt < 2) await Future.delayed(const Duration(seconds: 1));
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Accessibility not enabled yet. Open Settings → Accessibility → Auto Clicker → Enable it, then return here.',
          ),
          backgroundColor: AppColors.dangerRed,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleEnable(BuildContext context) async {
    if (!kIsWeb && Platform.isIOS) {
      await PreferencesLocalDataSource.instance.setOnboardingComplete(true);
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          SpringPageRoute(
            settings: const RouteSettings(name: AppRouteNames.dashboard),
            builder: (_) => const DashboardScreen(),
          ),
          (route) => false,
        );
      }
      return;
    }

    setState(() => _isChecking = true);
    await NativeAutomationChannel.openAccessibilitySettings();
  }

  void _handleHowItWorks(BuildContext context) {
    final bool isIOS = !kIsWeb && Platform.isIOS;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isIOS ? 'iOS Automation Guide' : 'How Accessibility Works'),
        content: Text(
          isIOS
              ? 'On iOS devices, automated taps and gestures are configured safely using iOS Switch Control recipes or in-app automation. No personal data is collected or transmitted.'
              : 'Auto Clicker uses Android Accessibility Service API to simulate tap and swipe gestures at your configured coordinates. No personal data is read, collected, or transmitted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PermissionScaffold(
      activeIndex: 3,
      segmentCount: 4,
      icon: AppAssetImage(
        assetPath: AppAssets.accessibilityPermissionIllustration,
        size: context.scaleUniform(AppDimensions.permissionIconSize),
        fallbackIcon: Icons.accessibility_new_rounded,
        fallbackIconColor: AppColors.primaryBlue,
      ),
      headline: AppStrings.accessibilityHeadline,
      subtext: AppStrings.accessibilitySubtext,
      primaryLabel: AppStrings.getStarted,
      onPrimaryPressed: () => _handleEnable(context),
      linkLabel: AppStrings.howItWorks,
      onLinkPressed: () => _handleHowItWorks(context),
    );
  }
}
