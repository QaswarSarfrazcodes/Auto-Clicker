import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
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
///  2. Live-screen picker — minimise the app, tap directly on the target app,
///     and physical coordinates are converted to standard logical points.
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
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Pick on Live Screen',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'The app will minimise.\n\n'
          '1. Go to your target app (Facebook, Camera, game…)\n'
          '2. Tap where you want each auto-click to land\n'
          '3. Tap ✅ Done on the floating toolbar when finished.',
          style: TextStyle(color: Color(0xFFB0B0C8), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF8888A8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Let's Go"),
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
                top: _points[i].y - (AppDimensions.overlayMarkerSize + 8) / 2,
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
                  child: ClickPointMarker(
                    index: i + 1,
                    selected: _selectedIndex == i,
                    onTap: () => _selectPoint(i),
                  ),
                ),
              ),

            // ─── Live Screen Picker Button ─────────────────────────────
            Positioned(
              top: 16,
              left: 80,
              right: 20,
              child: _LivePickerBanner(
                isActive: _isPickerActive,
                onPickLiveScreen: _startLiveScreenPicker,
                onCancelPicker: _stopPicker,
              ),
            ),

            Positioned(
              left: 0,
              top: MediaQuery.of(context).size.height * 0.2,
              child: OverlaySidebar(
                isSwipeMode: false,
                onAdd: _addPointInCenter,
                onRemove: _deleteSelectedPoint,
                onPlay: _applyAndSave,
                onClose: () => Navigator.of(context).maybePop(),
                onSettings: () {
                  if (_points.isNotEmpty) {
                    _selectPoint(_selectedIndex ?? _points.length - 1);
                  }
                },
              ),
            ),

            if (_points.isEmpty)
              const Positioned(
                top: AppDimensions.overlayBannerTop,
                left: 88,
                right: 20,
                child: Text(
                  AppStrings.tapAnywhereToPlaceClickPoints,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
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
// Live Picker Banner Widget
// ─────────────────────────────────────────────────────────────────────────────

class _LivePickerBanner extends StatelessWidget {
  const _LivePickerBanner({
    required this.isActive,
    required this.onPickLiveScreen,
    required this.onCancelPicker,
  });

  final bool isActive;
  final VoidCallback onPickLiveScreen;
  final VoidCallback onCancelPicker;

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0052FF).withAlpha(220),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.touch_app_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Picker active — tap on your target app',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
            GestureDetector(
              onTap: onCancelPicker,
              child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onPickLiveScreen,
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
