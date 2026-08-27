import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

/// Shows an "Are you sure?" dialog before deleting a script.
/// Returns true if the user confirmed, false if cancelled.
Future<bool> showConfirmDeleteDialog(
  BuildContext context,
  String scriptName,
) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            AppStrings.deleteScriptTitle,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Delete "$scriptName"?\n${AppStrings.deleteScriptConfirm}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                AppStrings.cancel,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text(
                AppStrings.deleteConfirm,
                style: TextStyle(
                  color: AppColors.dangerRed,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ) ??
      false;
}
