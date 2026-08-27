import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

/// A small pulsing green dot + status label ("Running" / "Paused").
class RunningStatusIndicator extends StatefulWidget {
  const RunningStatusIndicator({
    super.key,
    required this.label,
    this.color = AppColors.successGreen,
  });

  final String label;
  final Color color;

  @override
  State<RunningStatusIndicator> createState() =>
      _RunningStatusIndicatorState();
}

class _RunningStatusIndicatorState extends State<RunningStatusIndicator>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          child: FadeTransition(
            opacity: Tween(begin: 0.35, end: 1.0).animate(_controller),
            child: Container(
              width: AppDimensions.statusDotSize,
              height: AppDimensions.statusDotSize,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          widget.label,
          style: AppTextStyles.cardTitle.copyWith(
            color: widget.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

