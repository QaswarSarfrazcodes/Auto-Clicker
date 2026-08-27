import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/routing/app_route_names.dart';
import '../../../data/datasources/platform/support_service.dart';
import '../../../data/datasources/platform/subscription_service.dart';

/// App-wide navigation drawer shown from the Dashboard hamburger button (§13).
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 24),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primaryBlue, Color(0xFF1A3A8A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_fix_high,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              AppStrings.appTitle,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              AppStrings.splashTagline,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Navigation items
                      _DrawerItem(
                        icon: Icons.add_circle_outline,
                        label: AppStrings.createScript,
                        onTap: () {
                          Navigator.of(context)
                            ..pop()
                            ..pushNamed(AppRouteNames.createScript);
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.folder_outlined,
                        label: AppStrings.savedScriptsTitle,
                        onTap: () {
                          Navigator.of(context)
                            ..pop()
                            ..pushNamed(AppRouteNames.savedScripts);
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.settings_outlined,
                        label: AppStrings.settingsTitle,
                        onTap: () {
                          Navigator.of(context)
                            ..pop()
                            ..pushNamed(AppRouteNames.settings);
                        },
                      ),

                      const Divider(height: 16, indent: 20, endIndent: 20),

                      _DrawerItem(
                        icon: Icons.star_outline_rounded,
                        label: AppStrings.rateApp,
                        onTap: () async {
                          Navigator.of(context).pop();
                          await SubscriptionService.instance
                              .openManageSubscription();
                        },
                      ),
                      _DrawerItem(
                        icon: Icons.help_outline_rounded,
                        label: AppStrings.contactSupport,
                        onTap: () async {
                          Navigator.of(context).pop();
                          await SupportService.instance.contactSupport();
                        },
                      ),

                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          '${AppStrings.versionLabel} ${AppStrings.versionValue}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryBlue, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      horizontalTitleGap: 8,
    );
  }
}
