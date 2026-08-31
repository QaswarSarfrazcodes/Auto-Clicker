import 'dart:async';
import 'dart:math';

import '../../core/util/logger.dart';
import '../../data/datasources/native_automation_channel.dart';
import '../../data/datasources/video_hold_channel.dart';
import '../entities/script_entity.dart';
import '../entities/video_hold_state.dart';

enum ExecutionState { idle, running, paused, stopped }

/// UseCase that executes an Auto Clicker script using the native Accessibility Service channel.
class ExecuteScriptUseCase {
  ExecuteScriptUseCase({
    required this.script,
    Future<bool> Function(double x, double y, {int durationMs})? dispatchClick,
    Future<bool> Function(
      double startX,
      double startY,
      double endX,
      double endY, {
      int durationMs,
    })?
    dispatchSwipe,
    // Feature B — injectable for unit-testing without a real MethodChannel
    Future<bool> Function(String foregroundPackage)? isVideoPlaying,
  })  : _dispatchClick = dispatchClick ?? NativeAutomationChannel.dispatchClick,
        _dispatchSwipe = dispatchSwipe ?? NativeAutomationChannel.dispatchSwipe,
        _isVideoPlaying = isVideoPlaying ?? _defaultIsVideoPlaying;

  /// Default Signal 1→2→3 detector — delegates to VideoHoldChannel.
  static Future<bool> _defaultIsVideoPlaying(String foregroundPackage) =>
      VideoHoldChannel.isVideoPlaying(foregroundPackage: foregroundPackage);

  final ScriptEntity script;
  final Future<bool> Function(double x, double y, {int durationMs})
  _dispatchClick;
  final Future<bool> Function(
    double startX,
    double startY,
    double endX,
    double endY, {
    int durationMs,
  })
  _dispatchSwipe;
  /// Feature B — injectable check; defaults to [VideoHoldChannel.isVideoPlaying].
  final Future<bool> Function(String foregroundPackage) _isVideoPlaying;
  ExecutionState _state = ExecutionState.idle;
  int _clicksCompleted = 0;
  int _iterations = 0;
  int _elapsedSeconds = 0;

  Timer? _runtimeTimer;
  bool _loopActive = false;
  bool _completionSent = false;
  Function(int clicks, int seconds)? _onTick;
  Function()? _onComplete;

  ExecutionState get state => _state;
  int get clicksCompleted => _clicksCompleted;
  int get elapsedSeconds => _elapsedSeconds;

  void start({
    required Function(int clicks, int seconds) onTick,
    required Function() onComplete,
  }) {
    if (_state == ExecutionState.running) return;

    _onTick = onTick;
    _onComplete = onComplete;
    _completionSent = false;
    _state = ExecutionState.running;
    logDebug('ExecuteScriptUseCase starting script "${script.name}"');

    // Start runtime timer to track execution duration
    _runtimeTimer?.cancel();
    _runtimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state == ExecutionState.running) {
        _elapsedSeconds++;
        if (_clicksCompleted > 0) {
          onTick(_clicksCompleted, _elapsedSeconds);
        }
      }
    });

    // Calculate base interval in milliseconds
    int intervalMs = script.intervalUnit.toLowerCase() == 'ms'
        ? script.intervalValue
        : script.intervalValue * 1000;
    if (intervalMs < 10) intervalMs = 10;

    // Launch non-overlapping async execution loop
    _startLoop(intervalMs);
  }

  void _startLoop(int intervalMs) {
    if (_loopActive) return;
    _loopActive = true;
    unawaited(_runExecutionLoop(intervalMs));
  }

  /// Sequential async loop preventing overlapping timers and race conditions (Finding 3.2).
  Future<void> _runExecutionLoop(int baseIntervalMs) async {
    final Random random = Random();

    while (_state == ExecutionState.running) {
      final startTime = DateTime.now();

      // Check repeat count if custom count is configured
      if (script.repeatType == 'custom' &&
          (_clicksCompleted >= script.repeatCount || _iterations >= script.repeatCount)) {
        stop();
        _complete();
        break;
      }

      // Calculate delay including random bounds
      int currentIntervalMs = baseIntervalMs;
      if (script.randomDelayEnabled &&
          script.randomDelayMax > script.randomDelayMin) {
        final int minimumMs = script.randomDelayMin * 1000;
        final int rangeMs =
            (script.randomDelayMax - script.randomDelayMin) * 1000;
        currentIntervalMs += minimumMs + random.nextInt(rangeMs + 1);
      }

      // Action Dispatching
      // Feature B — hold the next scroll/click while a video is playing.
      if (script.holdOnVideoEnabled && _state == ExecutionState.running) {
        final holdPhase = await _waitForVideoToEnd();
        logDebug('VideoHold ended with phase: $holdPhase');
        if (_state != ExecutionState.running) break;
      }

      if (script.actionType == 'swipe') {
        final swipe = script.swipeConfig ??
            const SwipeConfigEntity(
              startX: 540,
              startY: 1500,
              endX: 540,
              endY: 500,
              durationMs: 250,
            );

        // Wait for any previous gesture to finish before dispatching the next one.
        await _pauseAwareDelay(swipe.durationMs + 50);
        if (_state != ExecutionState.running) break;

        final success = await _dispatchSwipe(
          swipe.startX,
          swipe.startY,
          swipe.endX,
          swipe.endY,
          durationMs: swipe.durationMs,
        );
        // Don't stop on a single gesture cancellation — log and continue the loop.
        if (success) {
          _clicksCompleted++;
          _onTick?.call(_clicksCompleted, _elapsedSeconds);
        }
        if (_state != ExecutionState.running) break;

        if (swipe.loopSequence) {
          if (swipe.delayMs > 0) await _pauseAwareDelay(swipe.delayMs);
          if (_state != ExecutionState.running) break;
          await _pauseAwareDelay(swipe.durationMs + 50); // wait for forward swipe
          await _dispatchSwipe(
            swipe.endX,
            swipe.endY,
            swipe.startX,
            swipe.startY,
            durationMs: swipe.durationMs,
          );
        }
        if (swipe.delayMs > 0) await _pauseAwareDelay(swipe.delayMs);
      } else if (script.clickPoints.isNotEmpty) {
        for (final cp in script.clickPoints) {
          if (_state != ExecutionState.running) break;
          // Apply ±1.5px micro-jitter if random delay / anti-detection is enabled
          final double jitterX = script.randomDelayEnabled ? (random.nextDouble() * 3.0 - 1.5) : 0.0;
          final double jitterY = script.randomDelayEnabled ? (random.nextDouble() * 3.0 - 1.5) : 0.0;
          final success = await _dispatchClick(cp.x + jitterX, cp.y + jitterY, durationMs: 50);
          _clicksCompleted++;
          _onTick?.call(_clicksCompleted, _elapsedSeconds);
          if (!success) {
            logDebug('Click gesture dispatch not acknowledged at (${cp.x}, ${cp.y})');
          }
          if (cp.delayMs > 0) {
            await _pauseAwareDelay(cp.delayMs);
          } else {
            await _pauseAwareDelay(20);
          }
        }
      } else {
        // Default click coordinate if no points are configured in click mode
        final double jitterX = script.randomDelayEnabled ? (random.nextDouble() * 3.0 - 1.5) : 0.0;
        final double jitterY = script.randomDelayEnabled ? (random.nextDouble() * 3.0 - 1.5) : 0.0;
        final success = await _dispatchClick(540 + jitterX, 960 + jitterY, durationMs: 50);
        _clicksCompleted++;
        _onTick?.call(_clicksCompleted, _elapsedSeconds);
        if (!success) {
          logDebug('Default click dispatch not acknowledged at (540, 960)');
        }
        await _pauseAwareDelay(20);
      }

      _iterations++;
      if (_state != ExecutionState.running) break;

      // Check count bounds again
      if (script.repeatType == 'custom' &&
          (_clicksCompleted >= script.repeatCount || _iterations >= script.repeatCount)) {
        stop();
        _complete();
        break;
      }

      // Compute elapsed execution time and adjust timing delay accordingly
      final int elapsedMs = DateTime.now().difference(startTime).inMilliseconds;
      final int sleepMs = currentIntervalMs - elapsedMs;

      if (sleepMs > 0) {
        await _pauseAwareDelay(sleepMs);
      } else {
        // Yield execution to the framework to prevent thread blocking
        await _pauseAwareDelay(1);
      }
    }
    _loopActive = false;
  }

  // ---------------------------------------------------------------------------
  // Feature B — Video-Aware Scroll Hold
  // ---------------------------------------------------------------------------

  /// Holds the next scroll until the video ends or [maxWait] expires.
  ///
  /// Polls [_isVideoPlaying] every 500 ms. Returns the final [VideoHoldPhase]:
  ///   • [VideoHoldPhase.idle]    — video wasn't playing at all (no hold needed)
  ///   • [VideoHoldPhase.resumed] — video ended naturally before the cap
  ///   • [VideoHoldPhase.timedOut]— max-wait expired; scroll forced to proceed
  ///
  /// The 3-minute cap (default) is the hard safety valve from solution.md §2 —
  /// it ensures the script NEVER hangs indefinitely on a livestream or a
  /// broken/stuck playback state.
  Future<VideoHoldPhase> _waitForVideoToEnd() async {
    // Quick initial check — if video isn't playing, return immediately (idle).
    final isPlaying = await _isVideoPlaying('');
    if (!isPlaying) return VideoHoldPhase.idle;

    logDebug('VideoHold: video detected, holding scroll for up to ${script.maxVideoWaitSeconds}s');

    final deadline = DateTime.now().add(script.maxVideoWaitDuration);

    while (DateTime.now().isBefore(deadline) && _state == ExecutionState.running) {
      // Re-check twice per second — cheap given Signal 1/2 are near-free calls.
      await _pauseAwareDelay(500);
      if (_state != ExecutionState.running) break;

      final stillPlaying = await _isVideoPlaying('');
      if (!stillPlaying) {
        logDebug('VideoHold: playback ended naturally — resuming scroll');
        return VideoHoldPhase.resumed;
      }
    }

    // Max-wait cap expired — force scroll to proceed, never hang forever.
    logDebug('VideoHold: max-wait (${script.maxVideoWaitSeconds}s) expired — forcing scroll');
    return VideoHoldPhase.timedOut;
  }

  Future<void> _pauseAwareDelay(int milliseconds) async {
    var remaining = milliseconds;
    while (remaining > 0 && _state != ExecutionState.stopped) {
      if (_state == ExecutionState.paused) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        continue;
      }
      final slice = remaining > 20 ? 20 : remaining;
      await Future<void>.delayed(Duration(milliseconds: slice));
      remaining -= slice;
    }
  }

  void _complete() {
    if (_completionSent) return;
    _completionSent = true;
    _runtimeTimer?.cancel(); // ensure the periodic timer is cancelled on natural completion
    _onComplete?.call();
  }

  void pause() {
    _state = ExecutionState.paused;
    logDebug('ExecuteScriptUseCase paused');
  }

  void resume() {
    if (_state == ExecutionState.paused) {
      _state = ExecutionState.running;
      final intervalMs = script.intervalUnit.toLowerCase() == 'ms'
          ? script.intervalValue
          : script.intervalValue * 1000;
      _startLoop(intervalMs < 10 ? 10 : intervalMs);
      logDebug('ExecuteScriptUseCase resumed');
    }
  }

  void stop() {
    _state = ExecutionState.stopped;
    _runtimeTimer?.cancel();
    logDebug(
      'ExecuteScriptUseCase stopped. Total clicks: $_clicksCompleted, duration: ${_elapsedSeconds}s',
    );
  }
}
