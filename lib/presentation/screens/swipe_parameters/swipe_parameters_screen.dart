import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/datasources/platform/overlay_channel.dart';
import '../../../domain/entities/script_entity.dart';
import '../../widgets/forms/app_slider_row.dart';
import '../../widgets/overlay/click_point_marker.dart';
import '../../widgets/overlay/dot_grid_painter.dart';
import '../../widgets/overlay/overlay_sidebar.dart';
import '../../widgets/overlay/swipe_line_painter.dart';

/// Screen 10 — Swipe Parameters (Interactive Canvas).
class SwipeParametersScreen extends StatefulWidget {
  const SwipeParametersScreen({super.key, this.initialConfig});

  final SwipeConfigEntity? initialConfig;

  @override
  State<SwipeParametersScreen> createState() => _SwipeParametersScreenState();
}

class _SwipeParametersScreenState extends State<SwipeParametersScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Offset? _startPoint;
  Offset? _endPoint;

  bool _isPickerActive = false;

  StreamSubscription<Map<String, double>>? _pointSub;
  StreamSubscription<void>? _doneSub;

  double _durationMs = 300;
  double _delayMs = 0;
  bool _loopSequence = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final config = widget.initialConfig;
    if (config != null) {
      _startPoint = Offset(config.startX, config.startY);
      _endPoint = Offset(config.endX, config.endY);
      _durationMs = config.durationMs.toDouble();
      _delayMs = config.delayMs.toDouble();
      _loopSequence = config.loopSequence;
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (_startPoint != null && _endPoint != null) {
      _animationController.repeat(reverse: false);
    }

    int pickerTapIndex = 0;
    _pointSub = OverlayChannel.instance.onPointCaptured.listen((coords) {
      if (!_isPickerActive || !mounted) return;
      final double dpr = MediaQuery.of(context).devicePixelRatio;
      final double x = coords['x']! / (dpr > 0 ? dpr : 1.0);
      final double y = coords['y']! / (dpr > 0 ? dpr : 1.0);
      setState(() {
        if (pickerTapIndex == 0) {
          _startPoint = Offset(x, y);
          pickerTapIndex++;
        } else {
          _endPoint = Offset(x, y);
          _animationController.repeat(reverse: false);
          pickerTapIndex = 0;
          _isPickerActive = false;
        }
      });
    });

    _doneSub = OverlayChannel.instance.onPickerDone.listen((_) {
      if (!mounted) return;
      setState(() => _isPickerActive = false);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isPickerActive) {
      setState(() => _isPickerActive = false);
      OverlayChannel.instance.stopPointPicker();
    }
  }

  @override
  void dispose() {
    _pointSub?.cancel();
    _doneSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  void _handleCanvasTap(TapUpDetails details) {
    setState(() {
      if (_startPoint == null) {
        _startPoint = details.localPosition;
      } else if (_endPoint == null) {
        _endPoint = details.localPosition;
        _animationController.repeat(reverse: false);
      } else {
        _startPoint = details.localPosition;
        _endPoint = null;
        _animationController.stop();
      }
    });
  }

  void _handleReset() {
    setState(() {
      _startPoint = null;
      _endPoint = null;
      _animationController.stop();
    });
  }

  Future<void> _startLiveScreenPicker() async {
    if (!mounted) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14142B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
        ),
        title: const Row(
          children: [
            Icon(Icons.touch_app_rounded, color: AppColors.primaryBlue, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pick Swipe on Live Screen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: const Text(
          'The app will minimize over your target app (Facebook, TikTok, Game…):\n\n'
          '1. Tap where swipe should START\n'
          '2. Tap where swipe should END\n\n'
          'The picker will finish automatically after 2 taps.',
          style: TextStyle(color: Color(0xFFC0C0D8), height: 1.5, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8888A8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Start Picker", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _startPoint = null;
      _endPoint = null;
      _animationController.stop();
      _isPickerActive = true;
    });
    await OverlayChannel.instance.startPointPicker(mode: 'swipe');
  }

  void _handleSave(BuildContext context) {
    if (_startPoint == null || _endPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please place both start and end points for the swipe.'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    final config = SwipeConfigEntity(
      startX: _startPoint!.dx,
      startY: _startPoint!.dy,
      endX: _endPoint!.dx,
      endY: _endPoint!.dy,
      durationMs: _durationMs.round(),
      delayMs: _delayMs.round(),
      loopSequence: _loopSequence,
    );

    Navigator.of(context).pop(config);
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14142B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune_rounded, color: AppColors.primaryBlue, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Swipe Parameters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    AppSliderRow(
                      label: 'Swipe Duration (ms)',
                      value: _durationMs,
                      min: 100,
                      max: 3000,
                      onChanged: (value) {
                        setModalState(() => _durationMs = value);
                        setState(() => _durationMs = value);
                      },
                      valueLabelBuilder: (value) => '${value.round()}ms',
                    ),
                    const SizedBox(height: 16),
                    AppSliderRow(
                      label: 'Delay between Swipes (ms)',
                      value: _delayMs,
                      min: 0,
                      max: 5000,
                      onChanged: (value) {
                        setModalState(() => _delayMs = value);
                        setState(() => _delayMs = value);
                      },
                      valueLabelBuilder: (value) => '${value.round()}ms',
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Continuous Loop',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      value: _loopSequence,
                      onChanged: (value) {
                        setModalState(() => _loopSequence = value);
                        setState(() => _loopSequence = value);
                      },
                      activeThumbColor: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Apply Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.overlayScrim,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: DotGridPainter()),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: _handleCanvasTap,
              ),
            ),
            if (_startPoint != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: SwipeLinePainter(
                          startPoint: _startPoint!,
                          endPoint: _endPoint,
                          animationValue: _animationController.value,
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (_startPoint != null)
              Positioned(
                left: _startPoint!.dx - 35,
                top: _startPoint!.dy - 45,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _startPoint = _startPoint! + details.delta;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xF00052FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'START (${_startPoint!.dx.round()}, ${_startPoint!.dy.round()})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ClickPointMarker(
                        index: 1,
                        selected: false,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),
            if (_endPoint != null)
              Positioned(
                left: _endPoint!.dx - 35,
                top: _endPoint!.dy - 45,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _endPoint = _endPoint! + details.delta;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xF010B981),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'END (${_endPoint!.dx.round()}, ${_endPoint!.dy.round()})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      ClickPointMarker(
                        index: 2,
                        selected: false,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),

            // ─── Single Unified Top Glass Header Pill (No Overlapping Text!) ───
            Positioned(
              top: 12,
              left: 76,
              right: 16,
              child: _SwipeTopGlassHeader(
                startPoint: _startPoint,
                endPoint: _endPoint,
                isPickerActive: _isPickerActive,
                onPickLiveScreen: _startLiveScreenPicker,
                onCancelPicker: () {
                  setState(() => _isPickerActive = false);
                  OverlayChannel.instance.stopPointPicker();
                },
              ),
            ),

            // ─── Floating Sidebar ─────────────────────────────────────
            Positioned(
              left: 0,
              top: MediaQuery.of(context).size.height * 0.2,
              child: OverlaySidebar(
                isSwipeMode: true,
                onAdd: () {},
                onRemove: _handleReset,
                onPlay: () => _handleSave(context),
                onPickLiveScreen: _startLiveScreenPicker,
                onClose: () => Navigator.of(context).maybePop(),
                onSettings: _showSettingsBottomSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unified Top Glass Header Pill for Swipe Screen
// ─────────────────────────────────────────────────────────────────────────────

class _SwipeTopGlassHeader extends StatelessWidget {
  const _SwipeTopGlassHeader({
    required this.startPoint,
    required this.endPoint,
    required this.isPickerActive,
    required this.onPickLiveScreen,
    required this.onCancelPicker,
  });

  final Offset? startPoint;
  final Offset? endPoint;
  final bool isPickerActive;
  final VoidCallback onPickLiveScreen;
  final VoidCallback onCancelPicker;

  @override
  Widget build(BuildContext context) {
    String title;
    String sub;

    if (isPickerActive) {
      title = 'Live Swipe Picker Active';
      sub = 'Tap START then END point on target app';
    } else if (startPoint == null) {
      title = 'Tap Canvas for START Point';
      sub = 'Or tap Live App to place on Facebook/apps';
    } else if (endPoint == null) {
      title = 'Tap Canvas for END Point';
      sub = 'Swipe direction line will be drawn';
    } else {
      title = 'Swipe Gesture Ready';
      sub = 'Drag markers or tap Save (✅) to confirm';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xE614142B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPickerActive
                  ? const Color(0xFF0052FF)
                  : Colors.white.withValues(alpha: 0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.swap_vert_rounded,
                  color: Color(0xFFA78BFA),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              if (isPickerActive)
                GestureDetector(
                  onTap: onCancelPicker,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white70, size: 16),
                  ),
                )
              else
                GestureDetector(
                  onTap: onPickLiveScreen,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.smartphone_rounded,
                            color: Colors.white, size: 13),
                        SizedBox(width: 4),
                        Text(
                          'Live App',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
