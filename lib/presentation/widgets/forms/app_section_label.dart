import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Small uppercase blue section heading — "STARTING POSITION",
/// "END POSITION", "TIMING & BEHAVIOR".
class AppSectionLabel extends StatelessWidget {
  const AppSectionLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryBlue,
        letterSpacing: 0.4,
      ),
    );
  }
}
