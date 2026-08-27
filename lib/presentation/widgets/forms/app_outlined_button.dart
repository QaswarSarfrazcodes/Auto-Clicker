import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// The outlined secondary button style — "Add Click Point",
/// "Reset to Default", and (in red) "Delete".
class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primaryBlue,
    this.expand = true,
  });

  final String label;
  final VoidCallback onPressed;
  final Color color;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        backgroundColor: color.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.formFieldRadius),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
      ),
    );

    return SizedBox(
      width: expand ? double.infinity : null,
      height: AppDimensions.formButtonHeight,
      child: button,
    );
  }
}
