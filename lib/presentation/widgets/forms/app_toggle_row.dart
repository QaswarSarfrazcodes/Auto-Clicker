import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// A "Label ... [switch]" row — used for "Random Delay" and
/// "Loop Sequence".
class AppToggleRow extends StatelessWidget {
  const AppToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.leadingIcon,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primaryBlue,
        ),
      ],
    );
  }
}
