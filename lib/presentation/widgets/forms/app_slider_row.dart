import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// A "Label ... [123ms]" row with a slider underneath — used for
/// "Duration (ms)" and "Delay (ms)" on the Swipe Parameters screen. The
/// value badge updates live as the slider moves.
class AppSliderRow extends StatelessWidget {
  const AppSliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.valueLabelBuilder,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  /// Formats the raw slider value into the badge text, e.g. `(v) => '${v.round()}ms'`.
  final String Function(double value) valueLabelBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                valueLabelBuilder(value),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primaryBlue,
            inactiveTrackColor: AppColors.borderGray,
            thumbColor: AppColors.primaryBlue,
            overlayColor: AppColors.primaryBlue.withValues(alpha: 0.15),
            trackHeight: 3,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
