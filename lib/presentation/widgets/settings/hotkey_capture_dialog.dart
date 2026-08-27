import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/datasources/preferences_local_datasource.dart';

/// Dialog that captures a key press from a physical keyboard and saves it
/// as the global hotkey for start/stop. Android-only feature (§5).
class HotkeyCaptureDialog extends StatefulWidget {
  const HotkeyCaptureDialog({super.key});

  @override
  State<HotkeyCaptureDialog> createState() => _HotkeyCaptureDialogState();
}

class _HotkeyCaptureDialogState extends State<HotkeyCaptureDialog> {
  String _capturedLabel = AppStrings.pressAnyKey;
  String? _capturedKeyId;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadCurrent();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _loadCurrent() async {
    final hotkey =
        await PreferencesLocalDataSource.instance.getGlobalHotkey();
    if (mounted && hotkey != null) {
      setState(() {
        _capturedLabel = hotkey;
        _capturedKeyId = hotkey;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        AppStrings.globalHotkeysDialog,
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            setState(() {
              _capturedLabel = event.logicalKey.keyLabel.isNotEmpty
                  ? event.logicalKey.keyLabel
                  : event.physicalKey.debugName ?? 'Unknown';
              _capturedKeyId = _capturedLabel;
            });
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.keyboard_outlined,
                  size: 32, color: AppColors.primaryBlue),
              const SizedBox(height: 12),
              Text(
                _capturedLabel,
                style: AppTextStyles.cardTitle.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _capturedKeyId != null
                      ? AppColors.primaryBlue
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text(
            AppStrings.cancel,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: _capturedKeyId == null
              ? null
              : () async {
                  await PreferencesLocalDataSource.instance
                      .setGlobalHotkey(_capturedKeyId!);
                  if (context.mounted) {
                    Navigator.of(context).pop(_capturedKeyId);
                  }
                },
          child: const Text(
            AppStrings.save,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
