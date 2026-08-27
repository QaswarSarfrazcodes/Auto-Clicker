import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

enum ScriptFilter { all, click, swipe }

/// Three-way pill filter row (All / Click / Swipe) at the top of the
/// Saved Scripts list.
class ScriptFilterTabs extends StatelessWidget {
  const ScriptFilterTabs({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ScriptFilter selected;
  final ValueChanged<ScriptFilter> onChanged;

  static const _labels = {
    ScriptFilter.all: 'All',
    ScriptFilter.click: 'Click',
    ScriptFilter.swipe: 'Swipe',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.scaleH(AppDimensions.filterTabHeight),
      child: Row(
        children: ScriptFilter.values.map((filter) {
          final isSelected = filter == selected;
          return Padding(
            padding: EdgeInsets.only(right: context.scaleW(10)),
            child: GestureDetector(
              onTap: () => onChanged(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(
                  horizontal: context.scaleW(18),
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : AppColors.borderGray,
                  ),
                ),
                child: Text(
                  _labels[filter]!,
                  style: AppTextStyles.buttonLabel.copyWith(
                    fontSize: 13,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
