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
import 'accessibility_permission_screen.dart';
import '../../../data/datasources/native_automation_channel.dart';

/// Screen 5 — "Allow Display all Over Other Apps".
/// Step 3 of 4 onboarding steps (progress index 2).
class OverlayPermissionScreen extends StatefulWidget {
  const OverlayPermissionScreen({super.key});

  @override
  State<OverlayPermissionScreen> createState() => _OverlayPermissionScreenState();
}

class _OverlayPermissionScreenState extends State<OverlayPermissionScreen>
    with WidgetsBindingObserver {
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
    final bool granted = await NativeAutomationChannel.isOverlayGranted();
    if (granted && mounted) {
      Navigator.of(context).pushReplacement(
        SpringPageRoute(
          settings: const RouteSettings(name: AppRouteNames.accessibilityPermission),
          builder: (_) => const AccessibilityPermissionScreen(),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Overlay Permission not granted. Please allow it to proceed.'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    }
  }

  Future<void> _handleGrantPermission(BuildContext context) async {
    if (!kIsWeb && Platform.isIOS) {
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          SpringPageRoute(
            settings: const RouteSettings(name: AppRouteNames.accessibilityPermission),
            builder: (_) => const AccessibilityPermissionScreen(),
          ),
        );
      }
      return;
    }

    setState(() => _isChecking = true);
    await NativeAutomationChannel.openOverlaySettings();
  }

  void _handleWhyIsThisNeeded(BuildContext context) {
    final bool isIOS = !kIsWeb && Platform.isIOS;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isIOS ? 'Floating Controls on iOS' : 'Display Over Other Apps'),
        content: Text(
          isIOS
              ? 'On iOS, automation scripts are executed inside the app or using iOS Switch Control recipes. Floating overlays across 3rd-party apps are exclusive to Android OS.'
              : 'This permission allows Auto Clicker to show a floating control bar (Play, Pause, Stop) over target applications while running scripts.',
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
      activeIndex: 2,
      segmentCount: 4,
      icon: AppAssetImage(
        assetPath: AppAssets.overlayPermissionIllustration,
        size: context.scaleUniform(AppDimensions.permissionIconSize),
        fallbackIcon: Icons.picture_in_picture_alt_rounded,
        fallbackIconColor: AppColors.primaryBlue,
      ),
      headline: AppStrings.overlayHeadline,
      subtext: AppStrings.overlaySubtext,
      primaryLabel: AppStrings.grantPermission,
      onPrimaryPressed: () => _handleGrantPermission(context),
      linkLabel: AppStrings.whyIsThisNeeded,
      onLinkPressed: () => _handleWhyIsThisNeeded(context),
    );
  }
}
