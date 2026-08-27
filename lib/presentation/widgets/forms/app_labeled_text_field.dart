import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// A labeled text field — "Script name", "X-Cordinate", etc. Works for
/// both text and numeric input via [keyboardType], and can show a
/// trailing widget (used for the unit dropdown next to "Interval").
class AppLabeledTextField extends StatelessWidget {
  const AppLabeledTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.keyboardType,
    this.suffix,
    this.trailing,
    this.readOnly = false,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final Widget? trailing;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: AppDimensions.formFieldHeight,
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            onChanged: onChanged,
            onSubmitted: onFieldSubmitted,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              suffixIcon: trailing ?? suffix,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.formFieldRadius),
                borderSide: const BorderSide(color: AppColors.borderGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.formFieldRadius),
                borderSide: const BorderSide(color: AppColors.primaryBlue),
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(AppDimensions.formFieldRadius),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
