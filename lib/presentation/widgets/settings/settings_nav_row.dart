import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// A settings row that's either informational or navigable.
class SettingsNavRow extends StatelessWidget {
  const SettingsNavRow({
    super.key,
    required this.title,
    this.value,
    this.onTap,
    this.valueColor,
    this.trailingIcon = Icons.chevron_right,
  });

  final String title;
  final String? value;
  final VoidCallback? onTap;
  final Color? valueColor;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.cardTitle.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          if (value != null)
            Text(
              value!,
              style: AppTextStyles.fieldLabel.copyWith(
                color: valueColor ?? AppColors.textSecondary,
                fontWeight: onTap != null ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(trailingIcon, size: 18, color: AppColors.iconMuted),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}
