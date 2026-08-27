import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Back chevron + centered/leading title + optional trailing action icons.
class AppScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppScreenHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.onBack,
  });

  final String title;
  final List<Widget> actions;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kToolbarHeight,
      child: Row(
        children: [
          IconButton(
            splashRadius: 20,
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            color: AppColors.textPrimary,
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.cardTitle.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (actions.isEmpty)
            const SizedBox(width: 48)
          else
            Row(mainAxisSize: MainAxisSize.min, children: actions),
        ],
      ),
    );
  }
}
