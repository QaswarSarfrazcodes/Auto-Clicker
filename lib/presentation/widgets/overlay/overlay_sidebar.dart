import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';

/// Ultra-premium glassmorphic vertical multi-toolbar for click point & swipe setup.
///
/// Features clear UX labels below each icon, glowing accents, tactile haptics,
/// fatigue timer indicators, and video radar status.
class OverlaySidebar extends StatefulWidget {
  const OverlaySidebar({
    super.key,
    this.onPlay,
    this.onAdd,
    this.onRemove,
    this.onPickLiveScreen,
    this.onSettings,
    this.onFatigueTimer,
    this.onVideoHoldToggle,
    this.onClose,
    this.isSwipeMode = false,
    this.pointCount = 0,
    this.fatigueMinutes = 30,
    this.isVideoHoldEnabled = true,
  });

  final VoidCallback? onPlay;
  final VoidCallback? onAdd;
  final VoidCallback? onRemove;
  final VoidCallback? onPickLiveScreen;
  final VoidCallback? onSettings;
  final VoidCallback? onFatigueTimer;
  final VoidCallback? onVideoHoldToggle;
  final VoidCallback? onClose;
  final bool isSwipeMode;
  final int pointCount;
  final int fatigueMinutes;
  final bool isVideoHoldEnabled;

  @override
  State<OverlaySidebar> createState() => _OverlaySidebarState();
}

class _OverlaySidebarState extends State<OverlaySidebar> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: _isExpanded ? 76 : 48,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xF20F172A), // Slate 900 Glass
                  Color(0xEB020617), // Deep Dark Glass
                  Color(0xF20F172A),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0x3338BDF8), // Electric Cyan border
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(2, 4),
                ),
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Expand / Collapse Header Grip ──────────────────────
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isExpanded = !_isExpanded);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isExpanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                              size: 14,
                              color: const Color(0xFF38BDF8),
                            ),
                            if (_isExpanded) ...[
                              const SizedBox(width: 3),
                              const Text(
                                'AUTO ▾',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // ── 1. Save & Start (Checkmark) ───────────────────────────
                  _SidebarToolItem(
                    icon: Icons.check_circle_rounded,
                    label: 'Done',
                    gradient: const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    shadowColor: const Color(0xFF3B82F6),
                    onTap: widget.onPlay,
                    tooltip: 'Save & Return',
                    isHero: true,
                    showLabel: _isExpanded,
                  ),
                  const SizedBox(height: 10),

                  // ── 2. Add Click / Swipe ─────────────────────────────────
                  _SidebarToolItem(
                    icon: widget.isSwipeMode ? Icons.swipe_rounded : Icons.add_circle_rounded,
                    label: widget.isSwipeMode ? 'Swipe' : 'Add Click',
                    color: const Color(0xFF10B981),
                    onTap: widget.onAdd,
                    tooltip: widget.isSwipeMode ? 'Add Swipe Gesture' : 'Add Click Target',
                    badgeCount: widget.pointCount > 0 ? widget.pointCount : null,
                    showLabel: _isExpanded,
                  ),
                  const SizedBox(height: 10),

                  // ── 3. Remove Selected / Last Point ───────────────────────
                  _SidebarToolItem(
                    icon: Icons.remove_circle_outline_rounded,
                    label: 'Undo',
                    color: const Color(0xFFEF4444),
                    onTap: widget.onRemove,
                    tooltip: 'Remove Point',
                    showLabel: _isExpanded,
                  ),
                  const SizedBox(height: 10),

                  // ── 4. Pick Directly on Live Target App (Instagram, etc) ──
                  if (widget.onPickLiveScreen != null) ...[
                    _SidebarToolItem(
                      icon: Icons.open_in_new_rounded,
                      label: 'Live App',
                      color: const Color(0xFF06B6D4),
                      onTap: widget.onPickLiveScreen,
                      tooltip: 'Floating Toolbar on Target App',
                      showLabel: _isExpanded,
                    ),
                    const SizedBox(height: 10),
                  ],

                  // ── 5. Session Fatigue Timer Indicator ────────────────────
                  _SidebarToolItem(
                    icon: Icons.timer_outlined,
                    label: '${widget.fatigueMinutes}m Break',
                    color: const Color(0xFFF59E0B),
                    onTap: widget.onFatigueTimer ?? widget.onSettings,
                    tooltip: 'Fatigue Auto-Break Timer',
                    showLabel: _isExpanded,
                  ),
                  const SizedBox(height: 10),

                  // ── 6. Video Hold Radar Status ───────────────────────────
                  _SidebarToolItem(
                    icon: widget.isVideoHoldEnabled ? Icons.videocam_rounded : Icons.videocam_off_outlined,
                    label: widget.isVideoHoldEnabled ? 'Radar ON' : 'Radar OFF',
                    color: widget.isVideoHoldEnabled ? const Color(0xFFA855F7) : const Color(0xFF64748B),
                    onTap: widget.onVideoHoldToggle ?? widget.onSettings,
                    tooltip: 'Video-Aware Scroll Hold Radar',
                    showLabel: _isExpanded,
                  ),
                  const SizedBox(height: 10),

                  // ── 7. Settings / Speed Parameters ───────────────────────
                  _SidebarToolItem(
                    icon: Icons.tune_rounded,
                    label: 'Speed',
                    color: const Color(0xFF38BDF8),
                    onTap: widget.onSettings,
                    tooltip: 'Interval & Speed Settings',
                    showLabel: _isExpanded,
                  ),
                  const SizedBox(height: 12),

                  // ── Divider ──────────────────────────────────────────────
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── 8. Close / Cancel ────────────────────────────────────
                  _SidebarToolItem(
                    icon: Icons.close_rounded,
                    label: 'Cancel',
                    color: Colors.white.withValues(alpha: 0.6),
                    onTap: widget.onClose,
                    tooltip: 'Exit Overlay',
                    showLabel: _isExpanded,
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarToolItem extends StatelessWidget {
  const _SidebarToolItem({
    required this.icon,
    required this.label,
    this.color,
    this.gradient,
    this.shadowColor,
    this.onTap,
    this.tooltip,
    this.isHero = false,
    this.badgeCount,
    this.showLabel = true,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final List<Color>? gradient;
  final Color? shadowColor;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool isHero;
  final int? badgeCount;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.white;

    return Tooltip(
      message: tooltip ?? label,
      preferBelow: false,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isHero ? 42 : 36,
                  height: isHero ? 42 : 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: gradient != null
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: gradient!,
                          )
                        : null,
                    color: gradient == null
                        ? effectiveColor.withValues(alpha: 0.12)
                        : null,
                    border: Border.all(
                      color: gradient != null
                          ? Colors.white.withValues(alpha: 0.5)
                          : effectiveColor.withValues(alpha: 0.4),
                      width: isHero ? 1.5 : 1.0,
                    ),
                    boxShadow: shadowColor != null || isHero
                        ? [
                            BoxShadow(
                              color: (shadowColor ?? gradient?.first ?? effectiveColor)
                                  .withValues(alpha: 0.45),
                              blurRadius: isHero ? 12 : 6,
                              spreadRadius: isHero ? 1 : 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: gradient != null ? Colors.white : effectiveColor,
                    size: isHero ? 20 : 18,
                  ),
                ),
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0F172A),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (showLabel) ...[
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: effectiveColor.withValues(alpha: 0.9),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

