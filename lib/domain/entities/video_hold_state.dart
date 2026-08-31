/// Feature B — Video-Aware Scroll Hold: state types.
///
/// These are the phases that [ExecuteScriptUseCase._waitForVideoToEnd] emits
/// so the Running screen can show live status to the user.
enum VideoHoldPhase {
  /// No video detected — scroll proceeds normally.
  idle,

  /// A video surface has just been detected; hold is starting.
  videoDetected,

  /// Actively holding — video is still playing.
  waitingForEnd,

  /// Max-wait cap expired (default 3 min). Scroll is forced to proceed.
  /// Never leaves the script in a permanently-hung state.
  timedOut,

  /// Playback ended naturally before the cap — scroll resumes.
  resumed,
}

/// Snapshot of the current video-hold phase emitted to the UI on each check.
class VideoHoldState {
  const VideoHoldState({
    required this.phase,
    required this.elapsedWait,
    required this.maxWait,
  });

  final VideoHoldPhase phase;

  /// How long the hold has been active so far.
  final Duration elapsedWait;

  /// The configured maximum wait (from [ScriptEntity.maxVideoWaitSeconds]).
  final Duration maxWait;

  /// A result returned by [ExecuteScriptUseCase._waitForVideoToEnd].
  const VideoHoldState.idle()
      : phase = VideoHoldPhase.idle,
        elapsedWait = Duration.zero,
        maxWait = const Duration(minutes: 3);

  @override
  String toString() =>
      'VideoHoldState(phase: $phase, elapsed: $elapsedWait, max: $maxWait)';
}
