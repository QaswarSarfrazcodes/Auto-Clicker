import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/session_fatigue_presets.dart';
import '../../../data/datasources/fatigue_preferences_datasource.dart';
import '../../../domain/entities/session_fatigue_config.dart';

/// The action mode the overlay should perform on target apps.
enum ActionMode {
  autoClick,
  autoScroll;

  String get label => switch (this) {
        ActionMode.autoClick => 'Auto Click',
        ActionMode.autoScroll => 'Auto Scroll',
      };

  IconData get icon => switch (this) {
        ActionMode.autoClick => Icons.touch_app_rounded,
        ActionMode.autoScroll => Icons.swap_vert_rounded,
      };

  Color get color => switch (this) {
        ActionMode.autoClick => const Color(0xFF2380FD),
        ActionMode.autoScroll => const Color(0xFF7C3AED),
      };
}

/// Scroll direction presets.
enum ScrollDirection {
  up,
  down,
  left,
  right;

  String get label => switch (this) {
        ScrollDirection.up => 'Up',
        ScrollDirection.down => 'Down',
        ScrollDirection.left => 'Left',
        ScrollDirection.right => 'Right',
      };

  IconData get icon => switch (this) {
        ScrollDirection.up => Icons.arrow_upward_rounded,
        ScrollDirection.down => Icons.arrow_downward_rounded,
        ScrollDirection.left => Icons.arrow_back_rounded,
        ScrollDirection.right => Icons.arrow_forward_rounded,
      };
}

/// Scroll coordinate config passed back to the running screen.
class ScrollCoordConfig {
  const ScrollCoordConfig({
    required this.direction,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    this.durationMs = 400,
  });

  final ScrollDirection direction;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final int durationMs;
}

/// Premium glassmorphism sidebar for the Running screen.
///
/// Features:
/// • Full BackdropFilter blur + glass effect
/// • Live fatigue countdown ring
/// • Speed control (interval +/-)
/// • Scroll direction + coordinate selector
/// • Grace window slider
/// • Auto-Pause timer with presets
class FatigueSidebar extends StatefulWidget {
  const FatigueSidebar({
    super.key,
    required this.scriptName,
    required this.clicks,
    required this.runtime,
    required this.isPaused,
    required this.initialConfig,
    required this.onConfigChanged,
    required this.onActionModeChanged,
    this.actionMode = ActionMode.autoClick,
    this.intervalValue = 2,
    this.intervalUnit = 'Sec',
    this.onSpeedChanged,
    this.onScrollConfigChanged,
    this.scrollConfig,
    this.fatigueElapsed = Duration.zero,
  });

  final String scriptName;
  final int clicks;
  final Duration runtime;
  final bool isPaused;
  final SessionFatigueConfig initialConfig;
  final ValueChanged<SessionFatigueConfig> onConfigChanged;
  final ValueChanged<ActionMode> onActionModeChanged;
  final ActionMode actionMode;

  /// Current interval value shown in speed control.
  final int intervalValue;
  final String intervalUnit;

  /// Called when user changes interval speed.
  final void Function(int value, String unit)? onSpeedChanged;

  /// Called when scroll coordinates change.
  final ValueChanged<ScrollCoordConfig>? onScrollConfigChanged;
  final ScrollCoordConfig? scrollConfig;

  /// How much of the fatigue timer has elapsed (driven from RunningScreen).
  final Duration fatigueElapsed;

  @override
  State<FatigueSidebar> createState() => _FatigueSidebarState();
}

class _FatigueSidebarState extends State<FatigueSidebar>
    with SingleTickerProviderStateMixin {
  late SessionFatiguePreset _selectedPreset;
  late TextEditingController _customMinutesController;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Speed control
  late int _intervalValue;
  late String _intervalUnit;

  // Scroll config
  ScrollDirection _scrollDirection = ScrollDirection.down;
  late TextEditingController _startXCtrl;
  late TextEditingController _startYCtrl;
  late TextEditingController _endXCtrl;
  late TextEditingController _endYCtrl;
  late TextEditingController _scrollDurationCtrl;

  // Grace window
  int _graceWindowMinutes = 5;

  bool _isSaving = false;
  Timer? _autoSaveTimer;

  // Which section is expanded
  bool _speedExpanded = true;
  bool _timerExpanded = true;
  bool _scrollExpanded = true;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.initialConfig.preset;
    _graceWindowMinutes = widget.initialConfig.graceWindow.inMinutes;
    final customMinutes = widget.initialConfig.customLimit?.inMinutes;
    _customMinutesController = TextEditingController(
      text: customMinutes?.toString() ?? '60',
    );

    _intervalValue = widget.intervalValue;
    _intervalUnit = widget.intervalUnit;

    final sc = widget.scrollConfig;
    _scrollDirection = sc?.direction ?? ScrollDirection.down;
    _startXCtrl = TextEditingController(
        text: sc?.startX.toInt().toString() ?? '200');
    _startYCtrl = TextEditingController(
        text: sc?.startY.toInt().toString() ?? '800');
    _endXCtrl = TextEditingController(
        text: sc?.endX.toInt().toString() ?? '200');
    _endYCtrl = TextEditingController(
        text: sc?.endY.toInt().toString() ?? '400');
    _scrollDurationCtrl = TextEditingController(
        text: sc?.durationMs.toString() ?? '400');

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void didUpdateWidget(FatigueSidebar old) {
    super.didUpdateWidget(old);
    if (old.intervalValue != widget.intervalValue) {
      _intervalValue = widget.intervalValue;
    }
    if (old.intervalUnit != widget.intervalUnit) {
      _intervalUnit = widget.intervalUnit;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _customMinutesController.dispose();
    _startXCtrl.dispose();
    _startYCtrl.dispose();
    _endXCtrl.dispose();
    _endYCtrl.dispose();
    _scrollDurationCtrl.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  // ── Fatigue ──────────────────────────────────────────────────────────────

  void _onPresetTap(SessionFatiguePreset preset) {
    HapticFeedback.selectionClick();
    setState(() => _selectedPreset = preset);
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 600), _saveConfig);
  }

  Future<void> _saveConfig() async {
    if (!mounted) return;
    setState(() => _isSaving = true);

    Duration? customLimit;
    if (_selectedPreset == SessionFatiguePreset.custom) {
      final minutes = int.tryParse(_customMinutesController.text.trim()) ?? 60;
      customLimit = Duration(minutes: minutes.clamp(5, 480));
      await FatiguePreferencesDataSource.instance
          .setCustomFatigueLimitMinutes(minutes.clamp(5, 480));
    } else {
      await FatiguePreferencesDataSource.instance
          .setCustomFatigueLimitMinutes(null);
    }

    await FatiguePreferencesDataSource.instance
        .setFatiguePresetIndex(_selectedPreset.index);
    await FatiguePreferencesDataSource.instance
        .setGraceWindowMinutes(_graceWindowMinutes);

    final newConfig = SessionFatigueConfig(
      preset: _selectedPreset,
      customLimit: customLimit,
      graceWindow: Duration(minutes: _graceWindowMinutes),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      widget.onConfigChanged(newConfig);
    }
  }

  // ── Speed ─────────────────────────────────────────────────────────────────

  void _adjustInterval(int delta) {
    HapticFeedback.lightImpact();
    final minVal = _intervalUnit == 'ms' ? 100 : 1;
    final maxVal = _intervalUnit == 'ms' ? 9900 : 60;
    final step = _intervalUnit == 'ms' ? 100 : 1;
    setState(() {
      _intervalValue = (_intervalValue + delta * step).clamp(minVal, maxVal);
    });
    widget.onSpeedChanged?.call(_intervalValue, _intervalUnit);
  }

  void _toggleUnit() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_intervalUnit == 'Sec') {
        _intervalUnit = 'ms';
        _intervalValue = (_intervalValue * 1000).clamp(100, 9900);
      } else {
        _intervalUnit = 'Sec';
        _intervalValue = (_intervalValue ~/ 1000).clamp(1, 60);
      }
    });
    widget.onSpeedChanged?.call(_intervalValue, _intervalUnit);
  }

  // ── Scroll config ─────────────────────────────────────────────────────────

  void _pushScrollConfig() {
    final sx = double.tryParse(_startXCtrl.text) ?? 200;
    final sy = double.tryParse(_startYCtrl.text) ?? 800;
    final ex = double.tryParse(_endXCtrl.text) ?? 200;
    final ey = double.tryParse(_endYCtrl.text) ?? 400;
    final dur = int.tryParse(_scrollDurationCtrl.text) ?? 400;
    widget.onScrollConfigChanged?.call(ScrollCoordConfig(
      direction: _scrollDirection,
      startX: sx,
      startY: sy,
      endX: ex,
      endY: ey,
      durationMs: dur.clamp(100, 3000),
    ));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String get _runtimeLabel {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(widget.runtime.inHours);
    final m = two(widget.runtime.inMinutes % 60);
    final s = two(widget.runtime.inSeconds % 60);
    return '$h:$m:$s';
  }

  String _formatClicks(int value) {
    if (value < 1000) return value.toString();
    if (value < 1000000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }

  /// 0.0–1.0 progress of the fatigue timer.
  double get _fatigueProgress {
    final limit = widget.initialConfig.effectiveLimit;
    if (limit == null || limit.inSeconds == 0) return 0.0;
    final elapsed = widget.fatigueElapsed.inSeconds;
    return (elapsed / limit.inSeconds).clamp(0.0, 1.0);
  }

  String get _fatigueRemainingLabel {
    final limit = widget.initialConfig.effectiveLimit;
    if (limit == null) return '—';
    final remaining = limit - widget.fatigueElapsed;
    if (remaining.isNegative) return '0:00';
    final m = remaining.inMinutes;
    final s = remaining.inSeconds % 60;
    if (m >= 60) {
      final h = m ~/ 60;
      final rm = m % 60;
      return rm == 0 ? '${h}h' : '${h}h ${rm}m';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              width: 300,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xE60D0D1F),
                    Color(0xEA0A0A1A),
                    Color(0xE6080812),
                  ],
                ),
                border: Border(
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────────────────
                    _SidebarHeader(
                      scriptName: widget.scriptName,
                      isPaused: widget.isPaused,
                    ),

                    // ── Scrollable content ───────────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Live Stats ─────────────────────────────────
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _StatBox(
                                      icon: Icons.mouse_rounded,
                                      label: 'Actions',
                                      value:
                                          _formatClicks(widget.clicks),
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _StatBox(
                                      icon: Icons.timer_rounded,
                                      label: 'Runtime',
                                      value: _runtimeLabel,
                                      color: AppColors.successGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // ── Fatigue Ring ────────────────────────────────
                            if (widget.initialConfig.isEnabled)
                              _FatigueRing(
                                progress: _fatigueProgress,
                                remainingLabel: _fatigueRemainingLabel,
                                isPaused: widget.isPaused,
                              ),

                            const SizedBox(height: 8),

                            // ── ACTION MODE ─────────────────────────────────
                            _CollapsibleSection(
                              label: 'ACTION MODE',
                              icon: Icons.touch_app_rounded,
                              iconColor: AppColors.primaryBlue,
                              isExpanded: true,
                              onToggle: null, // always visible
                              child: _ActionModeSelector(
                                selected: widget.actionMode,
                                onChanged: (mode) {
                                  HapticFeedback.lightImpact();
                                  widget.onActionModeChanged(mode);
                                },
                              ),
                            ),

                            // ── SCROLL CONFIG (only when autoScroll) ────────
                            if (widget.actionMode == ActionMode.autoScroll)
                              _CollapsibleSection(
                                label: 'SCROLL SETTINGS',
                                icon: Icons.swap_vert_rounded,
                                iconColor: const Color(0xFF7C3AED),
                                isExpanded: _scrollExpanded,
                                onToggle: () => setState(
                                    () => _scrollExpanded = !_scrollExpanded),
                                child: _ScrollConfigPanel(
                                  direction: _scrollDirection,
                                  startXCtrl: _startXCtrl,
                                  startYCtrl: _startYCtrl,
                                  endXCtrl: _endXCtrl,
                                  endYCtrl: _endYCtrl,
                                  durationCtrl: _scrollDurationCtrl,
                                  onDirectionChanged: (d) {
                                    HapticFeedback.selectionClick();
                                    setState(() => _scrollDirection = d);
                                    _pushScrollConfig();
                                  },
                                  onApply: _pushScrollConfig,
                                ),
                              ),

                            // ── SPEED CONTROL ────────────────────────────────
                            _CollapsibleSection(
                              label: 'SPEED CONTROL',
                              icon: Icons.speed_rounded,
                              iconColor: AppColors.accentOrange,
                              isExpanded: _speedExpanded,
                              onToggle: () => setState(
                                  () => _speedExpanded = !_speedExpanded),
                              child: _SpeedControlPanel(
                                intervalValue: _intervalValue,
                                intervalUnit: _intervalUnit,
                                onDecrease: () => _adjustInterval(-1),
                                onIncrease: () => _adjustInterval(1),
                                onToggleUnit: _toggleUnit,
                              ),
                            ),

                            // ── SESSION FATIGUE TIMER ────────────────────────
                            _CollapsibleSection(
                              label: 'AUTO-STOP TIMER',
                              icon: Icons.hourglass_bottom_rounded,
                              iconColor: AppColors.warningAmber,
                              isExpanded: _timerExpanded,
                              onToggle: () => setState(
                                  () => _timerExpanded = !_timerExpanded),
                              child: _FatiguePanel(
                                selectedPreset: _selectedPreset,
                                customMinutesController:
                                    _customMinutesController,
                                graceWindowMinutes: _graceWindowMinutes,
                                isSaving: _isSaving,
                                onPresetTap: _onPresetTap,
                                onCustomChanged: (_) => _scheduleAutoSave(),
                                onGraceChanged: (minutes) {
                                  setState(
                                      () => _graceWindowMinutes = minutes);
                                  _scheduleAutoSave();
                                },
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),

                    // ── Footer tip ──────────────────────────────────────────
                    _SidebarFooter(isSaving: _isSaving),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({
    required this.scriptName,
    required this.isPaused,
  });
  final String scriptName;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 12, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.07),
          ),
        ),
      ),
      child: Row(
        children: [
          // Glowing bolt icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2380FD), Color(0xFF1032A8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.5),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scriptName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _PulsingDot(isPaused: isPaused),
                    const SizedBox(width: 6),
                    Text(
                      isPaused ? 'Paused' : 'Running',
                      style: TextStyle(
                        color: isPaused
                            ? AppColors.warningAmber
                            : AppColors.successGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Close button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Icon(
                Icons.close_rounded,
                color: Colors.white.withValues(alpha: 0.5),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pulsing status dot ───────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.isPaused});
  final bool isPaused;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isPaused ? AppColors.warningAmber : AppColors.successGreen;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3 + 0.5 * _anim.value),
              blurRadius: 4 + 6 * _anim.value,
              spreadRadius: 0,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Fatigue ring ─────────────────────────────────────────────────────────────

class _FatigueRing extends StatelessWidget {
  const _FatigueRing({
    required this.progress,
    required this.remainingLabel,
    required this.isPaused,
  });
  final double progress;
  final String remainingLabel;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    final color = progress > 0.85
        ? AppColors.dangerRed
        : progress > 0.65
            ? AppColors.warningAmber
            : AppColors.primaryBlue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            // Ring
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _RingPainter(
                      progress: progress,
                      color: color,
                      trackColor: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  Center(
                    child: Icon(
                      isPaused
                          ? Icons.pause_rounded
                          : Icons.hourglass_bottom_rounded,
                      size: 22,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time Remaining',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    remainingLabel,
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'until auto-pause',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });
  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.shortestSide - 8) / 2;
    final strokeWidth = 5.0;

    // Track
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress <= 0) return;

    // Progress arc
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Collapsible section ──────────────────────────────────────────────────────

class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool isExpanded;
  final VoidCallback? onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Section header
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 12, color: iconColor),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
                if (onToggle != null) ...[
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: isExpanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Animated body
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: child,
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

// ─── Stat box ─────────────────────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action mode selector ─────────────────────────────────────────────────────

class _ActionModeSelector extends StatelessWidget {
  const _ActionModeSelector({
    required this.selected,
    required this.onChanged,
  });
  final ActionMode selected;
  final ValueChanged<ActionMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
        ),
      ),
      child: Row(
        children: ActionMode.values.map((mode) {
          final isSelected = selected == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(mode),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            mode.color,
                            mode.color.withValues(alpha: 0.7),
                          ],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: mode.color.withValues(alpha: 0.45),
                            blurRadius: 14,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      mode.icon,
                      size: 20,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      mode.label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Scroll config panel ──────────────────────────────────────────────────────

class _ScrollConfigPanel extends StatelessWidget {
  const _ScrollConfigPanel({
    required this.direction,
    required this.startXCtrl,
    required this.startYCtrl,
    required this.endXCtrl,
    required this.endYCtrl,
    required this.durationCtrl,
    required this.onDirectionChanged,
    required this.onApply,
  });
  final ScrollDirection direction;
  final TextEditingController startXCtrl;
  final TextEditingController startYCtrl;
  final TextEditingController endXCtrl;
  final TextEditingController endYCtrl;
  final TextEditingController durationCtrl;
  final ValueChanged<ScrollDirection> onDirectionChanged;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 13,
                color: Color(0xFF7C3AED),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Set start and end coordinates for the scroll gesture.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Direction picker
        Text(
          'DIRECTION',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: ScrollDirection.values.map((d) {
            final isSelected = d == direction;
            return Expanded(
              child: GestureDetector(
                onTap: () => onDirectionChanged(d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF7C3AED)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF7C3AED)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        d.icon,
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        d.label,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Coordinates
        _CoordRow(
          label: 'FROM (Start)',
          xCtrl: startXCtrl,
          yCtrl: startYCtrl,
          color: AppColors.successGreen,
        ),
        const SizedBox(height: 10),
        _CoordRow(
          label: 'TO (End)',
          xCtrl: endXCtrl,
          yCtrl: endYCtrl,
          color: AppColors.dangerRed,
        ),
        const SizedBox(height: 10),

        // Swipe duration
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SWIPE DURATION',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _GlassTextField(
                    controller: durationCtrl,
                    hint: '400',
                    suffix: 'ms',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _GlassButton(
                label: 'Apply',
                icon: Icons.check_rounded,
                color: const Color(0xFF7C3AED),
                onTap: onApply,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CoordRow extends StatelessWidget {
  const _CoordRow({
    required this.label,
    required this.xCtrl,
    required this.yCtrl,
    required this.color,
  });
  final String label;
  final TextEditingController xCtrl;
  final TextEditingController yCtrl;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _GlassTextField(
                controller: xCtrl,
                hint: 'X',
                prefix: 'X',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GlassTextField(
                controller: yCtrl,
                hint: 'Y',
                prefix: 'Y',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Speed control panel ──────────────────────────────────────────────────────

class _SpeedControlPanel extends StatelessWidget {
  const _SpeedControlPanel({
    required this.intervalValue,
    required this.intervalUnit,
    required this.onDecrease,
    required this.onIncrease,
    required this.onToggleUnit,
  });
  final int intervalValue;
  final String intervalUnit;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onToggleUnit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentOrange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accentOrange.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Value + controls
          Row(
            children: [
              // Decrease
              _CircleButton(
                icon: Icons.remove_rounded,
                onTap: onDecrease,
                color: AppColors.accentOrange,
              ),
              // Value display
              Expanded(
                child: Column(
                  children: [
                    Text(
                      intervalValue.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      intervalUnit == 'Sec'
                          ? 'seconds between actions'
                          : 'milliseconds between actions',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Increase
              _CircleButton(
                icon: Icons.add_rounded,
                onTap: onIncrease,
                color: AppColors.accentOrange,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Unit toggle
          GestureDetector(
            onTap: onToggleUnit,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.accentOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 14,
                    color: AppColors.accentOrange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Switch to ${intervalUnit == 'Sec' ? 'milliseconds' : 'seconds'}',
                    style: const TextStyle(
                      color: AppColors.accentOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Fatigue panel ────────────────────────────────────────────────────────────

class _FatiguePanel extends StatelessWidget {
  const _FatiguePanel({
    required this.selectedPreset,
    required this.customMinutesController,
    required this.graceWindowMinutes,
    required this.isSaving,
    required this.onPresetTap,
    required this.onCustomChanged,
    required this.onGraceChanged,
  });
  final SessionFatiguePreset selectedPreset;
  final TextEditingController customMinutesController;
  final int graceWindowMinutes;
  final bool isSaving;
  final ValueChanged<SessionFatiguePreset> onPresetTap;
  final ValueChanged<String> onCustomChanged;
  final ValueChanged<int> onGraceChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // On/Off toggle row
        _FatigueToggleRow(
          enabled: selectedPreset != SessionFatiguePreset.off,
          onToggled: (on) {
            onPresetTap(
              on ? SessionFatiguePreset.oneHour : SessionFatiguePreset.off,
            );
          },
        ),

        if (selectedPreset != SessionFatiguePreset.off) ...[
          const SizedBox(height: 14),

          // Preset chips
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final preset in SessionFatiguePreset.values
                  .where((p) => p != SessionFatiguePreset.off))
                _PresetChip(
                  label: preset.label,
                  isSelected: selectedPreset == preset,
                  onTap: () => onPresetTap(preset),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Custom minutes field
          if (selectedPreset == SessionFatiguePreset.custom)
            _CustomMinutesField(
              controller: customMinutesController,
              onChanged: onCustomChanged,
            ),

          // Effective limit label
          _EffectiveLimitLabel(
            preset: selectedPreset,
            customMinutes:
                int.tryParse(customMinutesController.text.trim()) ?? 60,
          ),

          const SizedBox(height: 14),

          // Grace window slider
          _GraceWindowSlider(
            minutes: graceWindowMinutes,
            onChanged: onGraceChanged,
          ),

          const SizedBox(height: 4),

          // Saving indicator
          AnimatedOpacity(
            opacity: isSaving ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Row(
              children: [
                SizedBox(
                  width: 11,
                  height: 11,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.successGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Saving...',
                  style: TextStyle(
                    color: AppColors.successGreen,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Grace window slider ──────────────────────────────────────────────────────

class _GraceWindowSlider extends StatelessWidget {
  const _GraceWindowSlider({
    required this.minutes,
    required this.onChanged,
  });
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer_off_outlined,
                  size: 13,
                  color: AppColors.warningAmber.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  'Grace Window',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.warningAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.warningAmber.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '$minutes min',
                style: const TextStyle(
                  color: AppColors.warningAmber,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'How long to wait before auto-stopping',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 10,
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.warningAmber,
            inactiveTrackColor:
                Colors.white.withValues(alpha: 0.1),
            thumbColor: AppColors.warningAmber,
            overlayColor:
                AppColors.warningAmber.withValues(alpha: 0.15),
            trackHeight: 3,
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: minutes.toDouble(),
            min: 1,
            max: 30,
            divisions: 29,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}

// ─── Fatigue toggle row ───────────────────────────────────────────────────────

class _FatigueToggleRow extends StatelessWidget {
  const _FatigueToggleRow({
    required this.enabled,
    required this.onToggled,
  });
  final bool enabled;
  final ValueChanged<bool> onToggled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Auto-Stop',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Pause & ask to continue after limit',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onToggled(!enabled);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 48,
            height: 27,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: enabled
                  ? const LinearGradient(
                      colors: [Color(0xFF2380FD), Color(0xFF1C4FC2)],
                    )
                  : null,
              color: enabled
                  ? null
                  : Colors.white.withValues(alpha: 0.12),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              alignment:
                  enabled ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 21,
                height: 21,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Preset chip ──────────────────────────────────────────────────────────────

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF2380FD), Color(0xFF1032A8)],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryBlue
                : Colors.white.withValues(alpha: 0.15),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─── Custom minutes field ─────────────────────────────────────────────────────

class _CustomMinutesField extends StatelessWidget {
  const _CustomMinutesField({
    required this.controller,
    required this.onChanged,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom duration',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        _GlassTextField(
          controller: controller,
          hint: '60',
          suffix: 'min',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        Text(
          'Range: 5 – 480 minutes',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.25),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

// ─── Effective limit label ────────────────────────────────────────────────────

class _EffectiveLimitLabel extends StatelessWidget {
  const _EffectiveLimitLabel({
    required this.preset,
    required this.customMinutes,
  });
  final SessionFatiguePreset preset;
  final int customMinutes;

  String get _label {
    if (preset == SessionFatiguePreset.custom) {
      final mins = customMinutes.clamp(5, 480);
      if (mins >= 60) {
        final h = mins ~/ 60;
        final m = mins % 60;
        return m == 0
            ? 'Script pauses after $h hour${h > 1 ? "s" : ""}'
            : 'Script pauses after ${h}h ${m}m';
      }
      return 'Script pauses after $mins minutes';
    }
    final dur = preset.duration;
    if (dur == null) return '';
    final mins = dur.inMinutes;
    if (mins >= 60) {
      return 'Script pauses after ${dur.inHours} hour${dur.inHours > 1 ? "s" : ""}';
    }
    return 'Script pauses after $mins minutes';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          size: 12,
          color: AppColors.successGreen.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            _label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.isSaving});
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 13,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Changes apply to the next run automatically.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Glass text field ─────────────────────────────────────────────────────────

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    this.hint,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });
  final TextEditingController controller;
  final String? hint;
  final String? prefix;
  final String? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          if (prefix != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(10),
                ),
              ),
              child: Text(
                prefix!,
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                isDense: true,
              ),
            ),
          ),
          if (suffix != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(10),
                ),
              ),
              child: Text(
                suffix!,
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Glass button ─────────────────────────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Circle button ────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
          ),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
