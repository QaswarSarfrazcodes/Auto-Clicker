/// Phase of the Session Fatigue Guard.
enum SessionFatiguePhase {
  running, // counting elapsed runtime normally
  awaitingContinue, // auto-paused, "Continue?" shown, grace window ticking
  autoStopped, // grace window expired with no response (FR-A6)
}

/// Runtime state snapshot of the fatigue guard for a single script run.
class SessionFatigueState {
  const SessionFatigueState({
    this.phase = SessionFatiguePhase.running,
    this.elapsedSinceLastCheckIn = Duration.zero,
    this.graceElapsed = Duration.zero,
  });

  final SessionFatiguePhase phase;
  final Duration elapsedSinceLastCheckIn;
  final Duration graceElapsed;

  static const initial = SessionFatigueState();

  SessionFatigueState copyWith({
    SessionFatiguePhase? phase,
    Duration? elapsedSinceLastCheckIn,
    Duration? graceElapsed,
  }) {
    return SessionFatigueState(
      phase: phase ?? this.phase,
      elapsedSinceLastCheckIn:
          elapsedSinceLastCheckIn ?? this.elapsedSinceLastCheckIn,
      graceElapsed: graceElapsed ?? this.graceElapsed,
    );
  }
}
