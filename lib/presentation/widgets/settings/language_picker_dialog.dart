import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/datasources/preferences_local_datasource.dart';

/// Language picker dialog shown from Settings → Application Language (§4).
class LanguagePickerDialog extends StatefulWidget {
  const LanguagePickerDialog({super.key});

  @override
  State<LanguagePickerDialog> createState() => _LanguagePickerDialogState();
}

class _LanguagePickerDialogState extends State<LanguagePickerDialog> {
  static const Map<String, String> _options = {
    'en': AppStrings.languageEnglish,
    'ur': AppStrings.languageUrdu,
  };

  String _selected = 'en';

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    final lang =
        await PreferencesLocalDataSource.instance.getAppLanguage();
    if (mounted) setState(() => _selected = lang);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        AppStrings.appLanguage,
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _options.entries.map((e) {
          return RadioListTile<String>(
            contentPadding: EdgeInsets.zero,
            title: Text(e.value),
            value: e.key,
            // ignore: deprecated_member_use
            groupValue: _selected,
            activeColor: AppColors.primaryBlue,
            // ignore: deprecated_member_use
            onChanged: (v) async {
              if (v == null) return;
              setState(() => _selected = v);
              await PreferencesLocalDataSource.instance.setAppLanguage(v);
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.ok),
        ),
      ],
    );
  }
}
