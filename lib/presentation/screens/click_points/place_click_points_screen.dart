import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../data/datasources/platform/overlay_channel.dart';
import '../../../domain/entities/script_entity.dart';
import '../../widgets/overlay/click_point_editor_card.dart';
import '../../widgets/overlay/click_point_marker.dart';
import '../../widgets/overlay/dot_grid_painter.dart';
import '../../widgets/overlay/overlay_sidebar.dart';

/// Screen 9 — Place Click Points.
///
/// Supports two placement modes:
///  1. Canvas tap — tap the dot-grid canvas to place a point.
///  2. Live-screen picker — minimise the app, tap directly on target app (Facebook, Instagram, games…),
///     and physical coordinates are captured as logical points.
class PlaceClickPointsScreen extends StatefulWidget {
  const PlaceClickPointsScreen({super.key, this.initialPoints = const []});

  final List<ClickPointEntity> initialPoints;

  @override
  State<PlaceClickPointsScreen> createState() => _PlaceClickPointsScreenState();
}

class _PlaceClickPointsScreenState extends State<PlaceClickPointsScreen>
    with WidgetsBindingObserver {
  final List<_ClickPointDraft> _points = [];
  int? _selectedIndex;

  bool _isPickerActive = false;
  StreamSubscription<Map<String, double>>? _pointSub;
  StreamSubscription<void>? _doneSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Populate existing click points
    for (final point in widget.initialPoints) {
      _points.add(
        _ClickPointDraft(x: point.x, y: point.y, delayMs: point.delayMs),
      );
    }

    // Listen to point-capture events from the overlay point picker
    _pointSub = OverlayChannel.instance.onPointCaptured.listen((coords) {
      if (!_isPickerActive || !mounted) return;
      final double dpr = MediaQuery.of(context).devicePixelRatio;
      // Convert physical screen pixels from MotionEvent -> logical pixels (dp)
      final double logicalX = coords['x']! / (dpr > 0 ? dpr : 1.0);
      final double logicalY = coords['y']! / (dpr > 0 ? dpr : 1.0);
      setState(() {
        _points.add(_ClickPointDraft(x: logicalX, y: logicalY));
        _selectedIndex = _points.length - 1;
      });
    });

    // Listen for picker "Done" event
    _doneSub = OverlayChannel.instance.onPickerDone.listen((_) {
      if (!_isPickerActive || !mounted) return;
      setState(() => _isPickerActive = false);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes after point picker, stop picker mode
    if (state == AppLifecycleState.resumed && _isPickerActive) {
      _stopPicker();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Point Picker Control
  // ─────────────────────────────────────────────────────────────────────────

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
                'Pick on Live Screen',
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
          'The app will minimize over target app (Facebook, Game, TikTok…):\n\n'
          '1. Tap anywhere on target app to add click points\n'
          '2. Tap ✅ Done on the floating bar when finished.',
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

    setState(() => _isPickerActive = true);
    await OverlayChannel.instance.startPointPicker(mode: 'click');
  }

  Future<void> _stopPicker() async {
    setState(() => _isPickerActive = false);
    await OverlayChannel.instance.stopPointPicker();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Canvas Placement Methods
  // ─────────────────────────────────────────────────────────────────────────

  void _handleCanvasTap(TapUpDetails details) {
    setState(() {
      _points.add(
        _ClickPointDraft(
          x: details.localPosition.dx,
          y: details.localPosition.dy,
        ),
      );
      _selectedIndex = _points.length - 1;
    });
  }

  void _selectPoint(int index) {
    setState(() => _selectedIndex = index);
  }

  void _closeEditor() {
    setState(() => _selectedIndex = null);
  }

  void _deleteSelectedPoint() {
    if (_selectedIndex == null) return;
    setState(() {
      _points[_selectedIndex!].dispose();
      _points.removeAt(_selectedIndex!);
      _selectedIndex = null;
    });
  }

  void _saveSelectedPoint() {
    if (_selectedIndex == null) return;
    setState(() {
      final draft = _points[_selectedIndex!];
      draft.x = double.tryParse(draft.xController.text) ?? draft.x;
      draft.y = double.tryParse(draft.yController.text) ?? draft.y;
      draft.delayMs = int.tryParse(draft.delayController.text) ?? 0;
      _selectedIndex = null;
    });
  }

  void _addPointInCenter() {
    final size = MediaQuery.of(context).size;
    setState(() {
      _points.add(_ClickPointDraft(x: size.width / 2, y: size.height / 2));
      _selectedIndex = _points.length - 1;
    });
  }

  void _applyAndSave() {
    if (_selectedIndex != null) {
      final draft = _points[_selectedIndex!];
      draft.x = double.tryParse(draft.xController.text) ?? draft.x;
      draft.y = double.tryParse(draft.yController.text) ?? draft.y;
      draft.delayMs = int.tryParse(draft.delayController.text) ?? 0;
    }

    final List<ClickPointEntity> resultPoints = _points.map((p) {
      return ClickPointEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString() +
            p.hashCode.toString(),
        x: p.x,
        y: p.y,
        delayMs: p.delayMs,
      );
    }).toList();
    Navigator.of(context).pop(resultPoints);
  }

  @override
  void dispose() {
    _pointSub?.cancel();
    _doneSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    for (final point in _points) {
      point.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIndex != null ? _points[_selectedIndex!] : null;

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
            for (int i = 0; i < _points.length; i++)
              Positioned(
                left: _points[i].x - (AppDimensions.overlayMarkerSize + 8) / 2,
                top: _points[i].y - (_selectedIndex == i ? 50 : (AppDimensions.overlayMarkerSize + 8) / 2),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _points[i].x += details.delta.dx;
                      _points[i].y += details.delta.dy;
                      _points[i].xController.text =
                          _points[i].x.round().toString();
                      _points[i].yController.text =
                          _points[i].y.round().toString();
                      _selectedIndex = i;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedIndex == i)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xF014142B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryBlue),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            'X: ${_points[i].x.round()}, Y: ${_points[i].y.round()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ClickPointMarker(
                        index: i + 1,
                        selected: _selectedIndex == i,
                        onTap: () => _selectPoint(i),
                      ),
                    ],
                  ),
                ),
              ),

            // ─── Single Clean Top Glass Header Pill ─────────────────────
            Positioned(
              top: 12,
              left: 76,
              right: 16,
              child: _TopGlassHeader(
                pointCount: _points.length,
                isPickerActive: _isPickerActive,
                onPickLiveScreen: _startLiveScreenPicker,
                onCancelPicker: _stopPicker,
              ),
            ),

            // ─── Floating Sidebar ─────────────────────────────────────
            Positioned(
              left: 0,
              top: MediaQuery.of(context).size.height * 0.2,
              child: OverlaySidebar(
                isSwipeMode: false,
                pointCount: _points.length,
                onAdd: _addPointInCenter,
                onRemove: _deleteSelectedPoint,
                onPlay: _applyAndSave,
                onPickLiveScreen: _startLiveScreenPicker,
                onClose: () => Navigator.of(context).maybePop(),
                onSettings: () {
                  if (_points.isNotEmpty) {
                    _selectPoint(_selectedIndex ?? _points.length - 1);
                  }
                },
              ),
            ),

            if (selected != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: ClickPointEditorCard(
                  pointIndex: _selectedIndex! + 1,
                  xController: selected.xController,
                  yController: selected.yController,
                  delayController: selected.delayController,
                  onClose: _closeEditor,
                  onDelete: _deleteSelectedPoint,
                  onSave: _saveSelectedPoint,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unified Top Glass Header Widget (Fixes all text overlapping!)
// ─────────────────────────────────────────────────────────────────────────────

class _TopGlassHeader extends StatelessWidget {
  const _TopGlassHeader({
    required this.pointCount,
    required this.isPickerActive,
    required this.onPickLiveScreen,
    required this.onCancelPicker,
  });

  final int pointCount;
  final bool isPickerActive;
  final VoidCallback onPickLiveScreen;
  final VoidCallback onCancelPicker;

  @override
  Widget build(BuildContext context) {
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
              // Icon + title
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isPickerActive
                      ? const Color(0xFF0052FF).withValues(alpha: 0.2)
                      : AppColors.primaryBlue.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPickerActive
                      ? Icons.touch_app_rounded
                      : Icons.ads_click_rounded,
                  color: isPickerActive
                      ? const Color(0xFF38BDF8)
                      : AppColors.primaryBlue,
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
                      isPickerActive
                          ? 'Picker Mode Active'
                          : pointCount == 0
                              ? 'Tap Grid to Place Points'
                              : '$pointCount Point${pointCount > 1 ? "s" : ""} Placed',
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
                      isPickerActive
                          ? 'Tap directly on target app (Facebook…)'
                          : 'Drag points or pick directly on live app',
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

              // Action button
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
                        colors: [Color(0xFF2380FD), Color(0xFF1032A8)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withValues(alpha: 0.3),
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

// ─────────────────────────────────────────────────────────────────────────────
// Data class
// ─────────────────────────────────────────────────────────────────────────────

class _ClickPointDraft {
  _ClickPointDraft({
    required this.x,
    required this.y,
    this.delayMs = 0,
  })  : xController = TextEditingController(text: x.round().toString()),
        yController = TextEditingController(text: y.round().toString()),
        delayController = TextEditingController(text: delayMs.toString());

  double x;
  double y;
  int delayMs;

  final TextEditingController xController;
  final TextEditingController yController;
  final TextEditingController delayController;

  void dispose() {
    xController.dispose();
    yController.dispose();
    delayController.dispose();
  }
}
