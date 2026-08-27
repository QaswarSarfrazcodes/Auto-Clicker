import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/datasources/native_automation_channel.dart';
import '../../../data/datasources/platform/notification_permission_service.dart';
import '../../../data/datasources/platform/overlay_channel.dart';
import '../../../data/datasources/script_local_datasource.dart';
import '../../../domain/entities/script_entity.dart';
import '../../../domain/usecases/execute_script_usecase.dart';
import '../../widgets/common/app_primary_button.dart';
import '../../widgets/common/app_text_button.dart';
import '../../widgets/running/running_stat_card.dart';
import '../../widgets/running/running_status_indicator.dart';

/// Screen 11 — Running.
class RunningScreen extends StatefulWidget {
  const RunningScreen({
    super.key,
    this.scriptName = 'Auto Scroll',
    this.script,
  });

  final String scriptName;
  final ScriptEntity? script;

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  final TextEditingController _scriptNameController = TextEditingController();
  final TextEditingController _speedController = TextEditingController();

  ExecuteScriptUseCase? _useCase;
  late ScriptEntity _activeScript;
  bool _isPaused = false;
  int _clicks = 0;
  Duration _runtime = Duration.zero;
  StreamSubscription<void>? _emergencyStopSubscription;

  @override
  void initState() {
    super.initState();
    NativeAutomationChannel.initialize();

    _activeScript =
        widget.script ??
        ScriptEntity(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: widget.scriptName,
          actionType: 'click',
          intervalValue: 2,
          intervalUnit: 'Sec',
          clickPoints: const [
            ClickPointEntity(id: '1', x: 200, y: 400, delayMs: 500),
          ],
        );

    _scriptNameController.text = _activeScript.name;
    _speedController.text =
        '${_activeScript.intervalValue} ${_activeScript.intervalUnit}';

    // §0c: Listen for Volume Down emergency hardware kill-switch
    _emergencyStopSubscription = NativeAutomationChannel.emergencyStopStream
        .listen((_) {
          if (mounted) {
            _stop();
          }
        });

    // §1: Bind overlay control bar buttons
    OverlayChannel.instance.bindCallbacks(
      onPlayPause: () {
        if (mounted) _togglePause();
      },
      onStop: () {
        if (mounted) _stop();
      },
    );

    _initExecution();
  }

  Future<void> _initExecution() async {
    // Pre-flight check: ensure accessibility is granted before touching any service.
    // Without this, dispatchGesture fails silently and the script exits immediately
    // with zero user feedback. Now shows a clear actionable dialog instead.
    final bool accessGranted = await NativeAutomationChannel.isAccessibilityGranted();
    if (!accessGranted && mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Accessibility Service Required'),
          content: const Text(
            'Auto Clicker needs the Accessibility Service enabled to perform taps and swipes.\n\n'
            'Go to:\nSettings → Accessibility → Auto Clicker → Enable',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              onPressed: () {
                Navigator.of(context).pop();
                NativeAutomationChannel.openAccessibilitySettings();
              },
              child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).maybePop();
      return;
    }

    _useCase = ExecuteScriptUseCase(script: _activeScript);
    // §16: Ensure notification permission is requested on Android 13+
    await NotificationPermissionService.instance.ensureGranted();

    if (!mounted) return;

    // §11: Start native Android foreground service
    await NativeAutomationChannel.startForegroundService();

    // Record lastRunAt for accurate "last used" display in dashboard
    if (widget.script != null) {
      final updated = _activeScript.copyWith(lastRunAt: DateTime.now());
      setState(() => _activeScript = updated);
      await ScriptLocalDataSource.instance.updateScript(updated);
    }

    // §1: Show floating control bar overlay
    await OverlayChannel.instance.show();
    await OverlayChannel.instance.update(isRunning: true, clickCount: 0);

    if (!mounted) return;
    _useCase!.start(
      onTick: (clicks, seconds) {
        if (mounted) {
          setState(() {
            _clicks = clicks;
            _runtime = Duration(seconds: seconds);
          });
          // §1: Update floating overlay live click counter
          OverlayChannel.instance.update(
            isRunning: !_isPaused,
            clickCount: clicks,
          );
        }
      },
      onComplete: () {
        _cleanupServices();
        if (mounted) {
          Navigator.of(context).maybePop();
        }
      },
    );
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _useCase?.pause();
      } else {
        _useCase?.resume();
      }
    });
    // §1: Push paused/running state to floating overlay
    OverlayChannel.instance.update(isRunning: !_isPaused, clickCount: _clicks);
  }

  void _cleanupServices() {
    OverlayChannel.instance.hide();
    NativeAutomationChannel.stopForegroundService();
  }

  void _stop() {
    _useCase?.stop();
    _cleanupServices();
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _minimize() => NativeAutomationChannel.minimizeApp();

  // §10: Script name edit & persistence
  Future<void> _handleRenameScript(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == _activeScript.name) return;

    final updated = _activeScript.copyWith(name: trimmed);
    setState(() {
      _activeScript = updated;
    });

    final success = await ScriptLocalDataSource.instance.updateScript(updated);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Renamed script to "$trimmed"'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  String get _runtimeLabel {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(_runtime.inHours);
    final m = two(_runtime.inMinutes % 60);
    final s = two(_runtime.inSeconds % 60);
    return '$h:$m:$s';
  }

  @override
  void dispose() {
    _emergencyStopSubscription?.cancel();
    _useCase?.stop();
    _cleanupServices();
    _scriptNameController.dispose();
    _speedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.scaleW(28)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: context.scaleH(20)),
              RunningStatusIndicator(
                label: _isPaused ? 'Paused' : AppStrings.runningStatus,
                color: _isPaused
                    ? AppColors.pauseAmber
                    : AppColors.successGreen,
              ),
              SizedBox(height: context.scaleH(20)),
              _RunningDetailCard(
                label: AppStrings.scriptNameLabel,
                trailing: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                child: TextField(
                  controller: _scriptNameController,
                  onSubmitted: _handleRenameScript,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              SizedBox(height: context.scaleH(16)),
              Row(
                children: [
                  Expanded(
                    child: RunningStatCard(
                      label: AppStrings.clicksLabel,
                      value: _formatClicks(_clicks),
                    ),
                  ),
                  SizedBox(width: context.scaleW(AppDimensions.statCardGap)),
                  Expanded(
                    child: RunningStatCard(
                      label: AppStrings.runtimeLabel,
                      value: _runtimeLabel,
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.scaleH(16)),
              _RunningDetailCard(
                label: AppStrings.speedLabel,
                child: Text(
                  _speedController.text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(height: context.scaleH(24)),
              // ─── 2-state Pause/Resume + Stop buttons ─────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _isPaused
                        ? AppPrimaryButton(
                            label: AppStrings.resumeButton,
                            color: AppColors.primaryBlue,
                            icon: Icons.play_circle_outline_rounded,
                            onPressed: _togglePause,
                          )
                        : AppPrimaryButton(
                            label: AppStrings.pauseButton,
                            color: AppColors.pauseAmber,
                            icon: Icons.pause,
                            onPressed: _togglePause,
                          ),
                  ),
                  SizedBox(
                    width: context.scaleW(AppDimensions.actionButtonGap),
                  ),
                  Expanded(
                    child: AppPrimaryButton(
                      label: AppStrings.stopButton,
                      color: AppColors.dangerRed,
                      icon: Icons.stop,
                      onPressed: _stop,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: AppTextButton(
                  label: AppStrings.minimizeLabel,
                  trailingIcon: Icons.keyboard_arrow_down,
                  onPressed: _minimize,
                ),
              ),
              SizedBox(height: context.scaleH(16)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatClicks(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buffer.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }
}

class _RunningDetailCard extends StatelessWidget {
  const _RunningDetailCard({
    required this.label,
    required this.child,
    this.trailing,
  });

  final String label;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.scaleH(AppDimensions.statCardHeight),
      padding: EdgeInsets.symmetric(horizontal: context.scaleW(16)),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGray),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
