import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';

/// One row in the Saved Scripts list.
class SavedScriptTile extends StatelessWidget {
  const SavedScriptTile({
    super.key,
    required this.name,
    required this.createdDate,
    required this.onPlay,
    required this.onMenu,
  });

  final String name;
  final String createdDate;
  final VoidCallback onPlay;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPlay,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: context.scaleH(AppDimensions.scriptTileHeight),
          padding: EdgeInsets.symmetric(horizontal: context.scaleW(14)),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.cardTitle.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${AppStrings.createdPrefix}$createdDate',
                      style: AppTextStyles.fieldLabel.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.primaryBlue,
                child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 4),
              IconButton(
                splashRadius: 18,
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                onPressed: onMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
