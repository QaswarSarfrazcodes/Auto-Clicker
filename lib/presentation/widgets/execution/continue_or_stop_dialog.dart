import 'dart:async';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/session_fatigue_config.dart';

/// In-app "Continue?" dialog shown when the session limit is reached
/// and the app is foregrounded (FR-A4).
///
/// Features a live grace-window countdown so the user knows how long
/// they have before the script stops automatically (FR-A6).
class ContinueOrStopDialog extends StatefulWidget {
  const ContinueOrStopDialog({
    super.key,
    required this.scriptName,
    required this.config,
    required this.onContinue,
    required this.onStop,
  });

  final String scriptName;
  final SessionFatigueConfig config;
  final VoidCallback onContinue;
  final VoidCallback onStop;

  static Future<void> show(
    BuildContext context, {
    required String scriptName,
    required SessionFatigueConfig config,
    required VoidCallback onContinue,
    required VoidCallback onStop,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ContinueOrStopDialog(
        scriptName: scriptName,
        config: config,
        onContinue: onContinue,
        onStop: onStop,
      ),
    );
  }

  @override
  State<ContinueOrStopDialog> createState() => _ContinueOrStopDialogState();
}

class _ContinueOrStopDialogState extends State<ContinueOrStopDialog> {
  late Duration _remaining;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.config.graceWindow;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining -= const Duration(seconds: 1);
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String get _countdownLabel {
    final m = _remaining.inMinutes;
    final s = _remaining.inSeconds % 60;
    if (m > 0) return '$m min ${s.toString().padLeft(2, '0')} sec';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
          border: Border.all(
            color: AppColors.primaryBlue.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.2),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.warningAmber.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.warningAmber.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.timer_outlined,
                  color: AppColors.warningAmber,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Session Limit Reached',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Script name badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '"${widget.scriptName}"',
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Your script has been running for a while and was automatically paused. Would you like to continue?',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Countdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.hourglass_bottom_rounded,
                      size: 18,
                      color: _remaining.inSeconds < 60
                          ? AppColors.dangerRed
                          : AppColors.warningAmber,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Auto-stops in $_countdownLabel',
                      style: TextStyle(
                        color: _remaining.inSeconds < 60
                            ? AppColors.dangerRed
                            : AppColors.warningAmber,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _countdownTimer?.cancel();
                        Navigator.of(context).pop();
                        widget.onStop();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.dangerRed,
                        side: const BorderSide(color: AppColors.dangerRed),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Stop',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        _countdownTimer?.cancel();
                        Navigator.of(context).pop();
                        widget.onContinue();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_outline_rounded, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Continue',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
