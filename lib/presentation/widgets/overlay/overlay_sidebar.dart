import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// A floating vertical sidebar control panel for setting up automation scripts.
class OverlaySidebar extends StatelessWidget {
  const OverlaySidebar({
    super.key,
    this.onPlay,
    this.onAdd,
    this.onRemove,
    this.onSettings,
    this.onClose,
    this.isSwipeMode = false,
  });

  final VoidCallback? onPlay;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onSettings;
  final VoidCallback? onClose;
  final bool isSwipeMode;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite.withValues(alpha: 0.85),
            border: Border(
              right: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.5)),
              top: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.5)),
              bottom: BorderSide(color: AppColors.borderGray.withValues(alpha: 0.5)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SidebarIconButton(
                icon: Icons.check_circle_rounded,  // ✅ Checkmark = save/confirm, not "start automation"
                color: AppColors.primaryBlue,
                onTap: onPlay,
                tooltip: 'Save Points',
              ),
              const SizedBox(height: 16),
              _SidebarIconButton(
                icon: isSwipeMode ? Icons.swipe_rounded : Icons.add_circle_outline_rounded,
                color: AppColors.successGreen,
                onTap: onAdd,
                tooltip: isSwipeMode ? 'Add Swipe' : 'Add Click Point',
              ),
              const SizedBox(height: 16),
              _SidebarIconButton(
                icon: Icons.remove_circle_outline_rounded,
                color: AppColors.dangerRed,
                onTap: onRemove,
                tooltip: 'Remove Selected',
              ),
              const SizedBox(height: 16),
              _SidebarIconButton(
                icon: Icons.settings_rounded,
                color: AppColors.textSecondary,
                onTap: onSettings,
                tooltip: 'Settings',
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, thickness: 1, indent: 8, endIndent: 8),
              const SizedBox(height: 16),
              _SidebarIconButton(
                icon: Icons.close_rounded,
                color: AppColors.textPrimary,
                onTap: onClose,
                tooltip: 'Cancel',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarIconButton extends StatelessWidget {
  const _SidebarIconButton({
    required this.icon,
    required this.color,
    this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
      ),
    );
  }
}
