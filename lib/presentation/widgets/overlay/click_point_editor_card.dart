import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../common/app_primary_button.dart';
import '../forms/app_labeled_text_field.dart';
import '../forms/app_outlined_button.dart';

/// The "Point N" bottom card — X/Y coordinate + delay fields, Delete and
/// Save. Shown when a marker on the overlay canvas is selected.
class ClickPointEditorCard extends StatelessWidget {
  const ClickPointEditorCard({
    super.key,
    required this.pointIndex,
    required this.xController,
    required this.yController,
    required this.delayController,
    required this.onClose,
    required this.onDelete,
    required this.onSave,
  });

  final int pointIndex;
  final TextEditingController xController;
  final TextEditingController yController;
  final TextEditingController delayController;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.overlaySheetPadding),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.overlaySheetRadius),
          topRight: Radius.circular(AppDimensions.overlaySheetRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${AppStrings.pointLabel} $pointIndex',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppLabeledTextField(
            label: AppStrings.xCoordinate,
            controller: xController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          AppLabeledTextField(
            label: AppStrings.yCoordinate,
            controller: yController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          AppLabeledTextField(
            label: AppStrings.delayMs,
            controller: delayController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppOutlinedButton(
                  label: AppStrings.delete,
                  onPressed: onDelete,
                  color: AppColors.dangerRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppPrimaryButton(
                  label: AppStrings.save,
                  onPressed: onSave,
                  expand: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
