import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
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

    // Swipe picker: first event = start, second = end, then auto-closes
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
        // Reset and start new
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
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Pick Swipe on Live Screen',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'The app will minimise.\n\n'
          '1. Go to your target app (Facebook, Camera, game…)\n'
          '2. Tap where the swipe should START\n'
          '3. Tap where the swipe should END\n\n'
          'The picker will close automatically after 2 taps.',
          style: TextStyle(color: Color(0xFFB0B0C8), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8888A8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Let's Go"),
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
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Swipe Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppSliderRow(
                      label: 'Duration (ms)',
                      value: _durationMs,
                      min: 0,
                      max: 2000,
                      onChanged: (value) {
                        setModalState(() => _durationMs = value);
                        setState(() => _durationMs = value);
                      },
                      valueLabelBuilder: (value) => '${value.round()}ms',
                    ),
                    const SizedBox(height: 16),
                    AppSliderRow(
                      label: 'Delay (ms)',
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
                      title: const Text(AppStrings.loopSequence),
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
                          'Done',
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
                left:
                    _startPoint!.dx - (AppDimensions.overlayMarkerSize + 8) / 2,
                top:
                    _startPoint!.dy - (AppDimensions.overlayMarkerSize + 8) / 2,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _startPoint = _startPoint! + details.delta;
                    });
                  },
                  child: ClickPointMarker(
                    index: 1,
                    selected: false,
                    onTap: () {},
                  ),
                ),
              ),
            if (_endPoint != null)
              Positioned(
                left: _endPoint!.dx - (AppDimensions.overlayMarkerSize + 8) / 2,
                top: _endPoint!.dy - (AppDimensions.overlayMarkerSize + 8) / 2,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _endPoint = _endPoint! + details.delta;
                    });
                  },
                  child: ClickPointMarker(
                    index: 2,
                    selected: false,
                    onTap: () {},
                  ),
                ),
              ),
            Positioned(
              left: 0,
              top: MediaQuery.of(context).size.height * 0.2,
              child: OverlaySidebar(
                isSwipeMode: true,
                onAdd: () {}, // Handled by tapping on canvas
                onRemove: _handleReset,
                onPlay: () => _handleSave(context),
                onClose: () => Navigator.of(context).maybePop(),
                onSettings: _showSettingsBottomSheet,
              ),
            ),
            // ─── Live Screen Picker banner ─────────────────────────
            Positioned(
              top: 20,
              left: 80,
              right: 20,
              child: _isPickerActive
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0052FF).withAlpha(220),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.touch_app_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tap START then END on your target app',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                : GestureDetector(
                    onTap: _startLiveScreenPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A2E).withAlpha(200),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryBlue.withAlpha(128)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.smartphone_rounded, color: AppColors.primaryBlue, size: 18),
                          SizedBox(width: 8),
                          Text(
                            '📍 Pick on Live Screen',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: TextButton(
                onPressed: () => _handleSave(context),
                child: const Text(AppStrings.saveChanges),
              ),
            ),
            if (_startPoint == null)
              Positioned(
                top: AppDimensions.overlayBannerTop,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Tap anywhere to place the Start point',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_endPoint == null)
              Positioned(
                top: AppDimensions.overlayBannerTop,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Tap again to place the End point',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
