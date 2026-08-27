import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// The simple "‹ back  Title" header used on every screen that isn't the
/// dashboard (which has its own gradient header widget instead).
class AppBackHeader extends StatelessWidget {
  const AppBackHeader({
    super.key,
    this.title,
    this.onBack,
    this.trailing,
  });

  final String? title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.headerHeight,
      child: Row(
        children: [
          InkWell(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (title != null) ...[
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ] else
            const Spacer(),
          ?trailing,


        ],
      ),
    );
  }
}
