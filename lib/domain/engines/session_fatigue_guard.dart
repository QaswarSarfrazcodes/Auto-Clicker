import '../entities/session_fatigue_config.dart';
import '../entities/session_fatigue_state.dart';

/// Pure Dart engine for the Session Fatigue Timer.
///
/// No Flutter, no platform imports — same tier as AutomationEngine.
/// One instance per running script execution; owned by RunningScreen.
class SessionFatigueGuard {
  SessionFatigueGuard({
    required this.config,
    required this.onLimitReached,
    required this.onGraceExpired,
  });

  final SessionFatigueConfig config;

  /// FR-A3: fired once the Session Limit is hit. Caller is responsible for
  /// pausing the engine and showing "Continue?".
  final void Function() onLimitReached;

  /// FR-A6: fired if no response arrives within the grace window — caller
  /// fully stops the script rather than leaving it paused forever.
  final void Function() onGraceExpired;

  SessionFatigueState _state = SessionFatigueState.initial;
  SessionFatigueState get state => _state;
  Duration get elapsed => _state.elapsedSinceLastCheckIn;

  bool _limitFired = false;

  /// Call once per engine tick (1s). Pause/resume gaps in the script itself
  /// don't call this, so elapsed time is continuous "wall" run time only.
  void onTick(Duration tickSize) {
    if (!config.isEnabled) return;

    switch (_state.phase) {
      case SessionFatiguePhase.running:
        final elapsed = _state.elapsedSinceLastCheckIn + tickSize;
        if (!_limitFired && elapsed >= config.effectiveLimit!) {
          _limitFired = true;
          _state = _state.copyWith(
            phase: SessionFatiguePhase.awaitingContinue,
            elapsedSinceLastCheckIn: elapsed,
            graceElapsed: Duration.zero,
          );
          onLimitReached();
        } else {
          _state = _state.copyWith(elapsedSinceLastCheckIn: elapsed);
        }
        break;

      case SessionFatiguePhase.awaitingContinue:
        final grace = _state.graceElapsed + tickSize;
        if (grace >= config.graceWindow) {
          _state = _state.copyWith(
            phase: SessionFatiguePhase.autoStopped,
            graceElapsed: grace,
          );
          onGraceExpired();
        } else {
          _state = _state.copyWith(graceElapsed: grace);
        }
        break;

      case SessionFatiguePhase.autoStopped:
        break; // terminal — a new guard instance is created for the next run
    }
  }

  /// FR-A5: user tapped "Continue" — resume and restart a fresh countdown.
  void resumeCheckIn() {
    _limitFired = false;
    _state = const SessionFatigueState(phase: SessionFatiguePhase.running);
  }

  void dispose() {
    _state = _state.copyWith(phase: SessionFatiguePhase.autoStopped);
  }
}
