import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// A single numbered marker dropped on the overlay canvas — a small blue
/// dot with a ring around it, and a numbered badge top-right (matches the
/// "1", "2", "3" markers in the design). [selected] highlights the ring.
class ClickPointMarker extends StatefulWidget {
  const ClickPointMarker({
    super.key,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<ClickPointMarker> createState() => _ClickPointMarkerState();
}

class _ClickPointMarkerState extends State<ClickPointMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.selected) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ClickPointMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      if (widget.selected) {
        _controller.repeat(reverse: true);
      } else {
        _controller.animateTo(0.0, duration: const Duration(milliseconds: 200));
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: widget.selected ? 1.0 : 0.45,
          child: SizedBox(
            width: AppDimensions.overlayMarkerSize + 8,
            height: AppDimensions.overlayMarkerSize + 8,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.selected ? _scaleAnimation.value : 0.85,
                  child: child,
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: AppDimensions.overlayMarkerSize,
                    height: AppDimensions.overlayMarkerSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.selected
                          ? AppColors.primaryBlue.withValues(alpha: 0.15)
                          : const Color(0x330052FF),
                      border: Border.all(
                        color: widget.selected ? Colors.white : AppColors.primaryBlue,
                        width: widget.selected ? 3 : 1.5,
                      ),
                      boxShadow: widget.selected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: AppDimensions.overlayMarkerBadgeSize,
                      height: AppDimensions.overlayMarkerBadgeSize,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryBlue,
                      ),
                      child: Text(
                        '${widget.index}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

