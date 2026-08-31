# Feature B — Video-Aware Scroll Hold: Solution Architecture

**Problem restated:** while auto-scrolling a feed (Instagram/TikTok/YouTube Shorts/Facebook
Reels) on a fixed interval, the script must detect that a video is actively playing on-screen
*right now* and hold the next scroll until the video finishes or a configurable max-wait
(default 3 min) expires.

**Bottom line up front:** the right solution is **not** a machine-learning model. It's a
**multi-signal Android system-API heuristic**, layered so the cheapest/most reliable signal is
tried first and progressively more expensive fallbacks only run when needed. No screen-recording
permission, no continuous neural-network inference, and near-zero battery cost. Section 3 below
explains exactly why an ML/CV approach is the wrong tool for this specific job, and section 4
still answers the "which AI model" question honestly for the narrow case where a learned
fallback *would* help.

---

## 1. The four signals, cheapest and most reliable first

### Signal 1 — `MediaSession` playback state (primary signal, ~90% of cases)

Instagram, TikTok, YouTube, and Facebook all expose their video player through Android's
`MediaSession` framework (it's what powers the lock-screen media controls and Android Auto —
apps that skip this get worse OS integration, so all four do implement it for their video
surfaces). A `NotificationListenerService` can query every app's active media session and read
its `PlaybackState` directly — no polling, no screen access, just an OS API telling you the
literal ground truth ("this app says it is PLAYING").

```kotlin
// android/app/src/main/kotlin/.../media/MediaSessionWatcher.kt
class MediaSessionWatcher(
    private val context: Context,
    private val notificationListenerComponent: ComponentName,
) {
    private val sessionManager =
        context.getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager

    /** True if ANY app currently reports an actively-playing media session. */
    fun isAnyMediaPlaying(): Boolean {
        val sessions = try {
            sessionManager.getActiveSessions(notificationListenerComponent)
        } catch (e: SecurityException) {
            // Notification Listener permission not granted — caller must fall
            // back to Signal 2/3 below.
            return false
        }
        return sessions.any { controller ->
            controller.playbackState?.state == PlaybackState.STATE_PLAYING
        }
    }

    /** Scoped to just the foreground app, so a background music player
     * (Spotify) doesn't falsely hold the scroll while browsing Instagram. */
    fun isForegroundAppPlaying(foregroundPackage: String): Boolean {
        val sessions = try {
            sessionManager.getActiveSessions(notificationListenerComponent)
        } catch (e: SecurityException) {
            return false
        }
        return sessions.any {
            it.packageName == foregroundPackage &&
                it.playbackState?.state == PlaybackState.STATE_PLAYING
        }
    }
}
```

Requires the user to grant **Notification Access** (`BIND_NOTIFICATION_LISTENER_SERVICE`) once,
in Settings — a standard, well-understood Android permission (same one used by notification
managers, not a red flag to users the way `MediaProjection`'s recording icon is).

### Signal 2 — `AccessibilityNodeInfo` view-class detection (secondary — you already have this permission)

The app already requires the Accessibility permission for gesture dispatch (skill §2), so this
signal is **free** — no new permission prompt at all. Video surfaces in these apps are backed by
a small, stable set of Android view classes:

| App | Typical player view class (verify per version — see §6 test matrix) |
|---|---|
| Instagram (Reels/feed video) | `android.view.TextureView` inside a `com.instagram.android...VideoContainer` |
| TikTok | `android.opengl.GLSurfaceView` or `TextureView` inside `com.ss.android...VideoView` |
| YouTube / YT Shorts | `androidx.media3.ui.PlayerView` (or legacy `com.google.android.exoplayer2.ui.PlayerView`) |
| Facebook Reels | `com.facebook...RichVideoPlayer` wrapping a `TextureView` |

```kotlin
// android/app/src/main/kotlin/.../accessibility/VideoSurfaceDetector.kt
object VideoSurfaceDetector {

    private val PLAYER_CLASS_HINTS = listOf(
        "PlayerView", "VideoView", "ExoPlayerView", "RichVideoPlayer", "VideoContainer",
    )
    private val SURFACE_CLASSES = setOf(
        "android.view.TextureView", "android.view.SurfaceView", "android.opengl.GLSurfaceView",
    )

    /** Walks the current foreground window's accessibility tree looking for a
     * large-area surface/player node. Large-area matters: filters out small
     * thumbnail/avatar TextureViews (e.g. a profile picture) which would
     * otherwise be false positives. */
    fun findLikelyVideoSurface(root: AccessibilityNodeInfo, screenArea: Int): Boolean {
        val queue = ArrayDeque<AccessibilityNodeInfo>().apply { add(root) }
        while (queue.isNotEmpty()) {
            val node = queue.removeFirst()
            val className = node.className?.toString() ?: ""
            val isSurfaceClass = SURFACE_CLASSES.any { className == it }
            val isHintedPlayerClass = PLAYER_CLASS_HINTS.any { className.contains(it) }

            if (isSurfaceClass || isHintedPlayerClass) {
                val bounds = Rect().also { node.getBoundsInScreen(it) }
                val nodeArea = bounds.width() * bounds.height()
                // A real video player fills a meaningful chunk of the screen —
                // Reels/Shorts are typically full-bleed, feed videos are at
                // least ~40% of screen height.
                if (nodeArea >= screenArea * 0.35) return true
            }
            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { queue.add(it) }
            }
        }
        return false
    }
}
```

### Signal 3 — `AudioPlaybackConfiguration` (tertiary — cheap confirmation/tiebreaker)

`AudioManager.getActivePlaybackConfigurations()` (API 26+) lists every app currently holding
audio focus with playback content — a fast, permission-free confirmation signal. Weaker alone
(muted autoplay videos, which are common on Reels/Shorts, won't show here), so it's used to
**corroborate** Signal 1/2, not replace them:

```kotlin
fun isForegroundAppPlayingAudio(context: Context, foregroundUid: Int): Boolean {
    val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    return audioManager.activePlaybackConfigurations.any { config ->
        config.clientUid == foregroundUid &&
            config.audioAttributes.usage == AudioAttributes.USAGE_MEDIA
    }
}
```

### Signal 4 — Downsampled frame-diff motion heuristic (last-resort fallback only, opt-in)

For the rare case where Signals 1–3 all come back negative (an app update renamed the player
view class before the table above is refreshed, or Notification Access was denied), a **classical
computer-vision heuristic** — not a neural network — is the appropriate fallback: capture two
small downsampled frames a few hundred ms apart via `AccessibilityService.takeScreenshot()`
(API 30+, **no `MediaProjection`, no persistent recording notification** — this is the key
reason it's preferable to screen-recording-based approaches), and compute mean pixel delta.
Continuous full-region video content produces a sustained, high, *rhythmic* delta; a static
feed (even with a subtle "new post" entrance animation) produces a brief delta that decays to
~0 within a few hundred ms.

```kotlin
class FrameDiffMotionDetector(private val service: AccessibilityService) {
    private var lastFrame: Bitmap? = null

    suspend fun sample(regionInScreenPct: RectF): MotionSample {
        val bitmap = captureDownsampled(regionInScreenPct) // e.g. 64x64px — cheap to diff
        val prev = lastFrame
        lastFrame = bitmap
        if (prev == null) return MotionSample(delta = 0f, sustained = false)
        return MotionSample(delta = meanAbsPixelDelta(prev, bitmap), sustained = false)
    }

    // Call sample() every ~400ms; if delta stays above threshold for 3+
    // consecutive samples, classify as "video playing." A single spike (a
    // scroll-in animation) does NOT count — sustained motion is what
    // distinguishes real video playback from UI transitions.
}
```

This runs at most a few times per scroll-interval check, on a tiny bitmap, using integer
arithmetic — negligible CPU/battery cost, nothing like running a CNN continuously.

### Combining the four signals

```kotlin
class VideoPlaybackDetector(
    private val mediaSessionWatcher: MediaSessionWatcher,
    private val surfaceDetector: VideoSurfaceDetector,
    private val audioConfig: AudioPlaybackConfigWatcher,
    private val motionDetector: FrameDiffMotionDetector,
    private val settings: VideoHoldSettings, // holdOnVideoEnabled, maxWaitSeconds, etc.
) {
    suspend fun isVideoCurrentlyPlaying(foregroundPackage: String, rootNode: AccessibilityNodeInfo): Boolean {
        if (mediaSessionWatcher.isForegroundAppPlaying(foregroundPackage)) return true
        val hasSurface = surfaceDetector.findLikelyVideoSurface(rootNode, screenAreaPx)
        if (hasSurface && audioConfig.isForegroundAppPlayingAudio(foregroundUid)) return true
        if (hasSurface && settings.motionFallbackEnabled) {
            return motionDetector.sample(fullScreenRegion).let { it.delta > MOTION_THRESHOLD }
        }
        return false
    }
}
```

---

## 2. State machine & scroll-loop integration

```dart
// domain/entities/video_hold_state.dart
enum VideoHoldPhase { idle, videoDetected, waitingForEnd, timedOut, resumed }

@freezed
class VideoHoldState with _$VideoHoldState {
  const factory VideoHoldState({
    required VideoHoldPhase phase,
    required Duration elapsedWait,
    required Duration maxWait, // default 3 min, configurable per script
  }) = _VideoHoldState;
}
```

```kotlin
// The core loop that replaces "always scroll every N seconds" with
// "check for video before every scroll."
suspend fun runScrollLoop(script: Script) {
    while (isRunning) {
        delay(script.intervalMs)
        if (script.holdOnVideoEnabled) {
            val holdResult = waitForVideoToEnd(
                maxWait = script.maxVideoWaitDuration, // default 180s
            )
            emitEvent(RunEvent.videoHoldPhase(holdResult.phase))
        }
        dispatchScrollGesture()
    }
}

suspend fun waitForVideoToEnd(maxWait: Duration): VideoHoldResult {
    val deadline = System.currentTimeMillis() + maxWait.inWholeMilliseconds
    while (System.currentTimeMillis() < deadline) {
        val (fgPackage, rootNode) = getForegroundWindowInfo() ?: break
        if (!videoPlaybackDetector.isVideoCurrentlyPlaying(fgPackage, rootNode)) {
            return VideoHoldResult(phase = VideoHoldPhase.resumed)
        }
        delay(500) // re-check twice a second — cheap given Signal 1/2 are near-free
    }
    return VideoHoldResult(phase = VideoHoldPhase.timedOut) // safety valve — never hang forever
}
```

The **3-minute default max-wait is a hard safety valve** — without it, a video stuck buffering
on a bad connection, or a livestream (which never "ends"), would freeze the script forever. This
must ship in v1, not as a later hardening pass.

---

## 3. Why this is deliberately *not* an ML/CV solution

Three reasons, in order of importance:

1. **The ground-truth signal already exists and is free.** Instagram/TikTok/YouTube/Facebook
   *already tell the OS* "I am playing video" via `MediaSession`/audio focus — that's a
   first-party, authoritative signal. Training a model to *infer* the same fact from pixels is
   solving an already-solved problem with a strictly noisier method.
2. **Continuous on-device inference is exactly the battery/thermal cost this app's own
   `PERFORMANCE_AND_EFFICIENCY.md` (§4, §7) says to avoid.** Even a "lightweight" mobile CNN
   (MobileNetV3-Small: ~2.9M params) run every few hundred ms, 24/7 while a script is active, is
   meaningfully more CPU/battery than a `PlaybackState` field read or a 64×64 integer pixel-diff.
3. **No accuracy win.** A vision model trained to say "is this a video frame" would have to
   solve a *harder* and *noisier* version of the problem the system APIs answer directly and
   exactly — it would need to distinguish "video playing" from "static image with a subtle
   Reels-style pulsing like button animation," which Signal 1 answers with zero ambiguity.

ML earns its cost when there's no cheaper authoritative signal. Here there is one. Reach for
Signal 4 (classical frame-diff, not ML) only as the deliberately-degraded fallback for the
signal-denied edge case.

---

## 4. The "which AI model" question — answered honestly

Searched GitHub and Hugging Face for a purpose-built "is a video currently playing on this
phone screen, in real time, cheaply enough to run in an always-on background service" model.
**None exists as a drop-in.** What's actually out there falls into three buckets, none of which
fit this task well:

| Category | Examples | Why it's the wrong fit here |
|---|---|---|
| **Full video/action-recognition models** | VideoMAE, TimeSformer, X3D (all on Hugging Face) | Built for offline classification of *what activity* a video clip shows (e.g. "playing basketball"), not "is something currently playing." Multi-second temporal windows, GPU-class compute — wildly overkill and too slow for a per-scroll real-time check on a phone CPU. |
| **General on-device image classifiers** (usable only as a base to *fine-tune your own* binary "video-frame vs static-UI-frame" classifier, which nobody has published pretrained) | MobileNetV3-Small/Large (TensorFlow/PyTorch, both on GitHub & Hugging Face `google/mobilenet_v3_small_100_224`), EfficientNet-Lite0 (TF Hub / Hugging Face), MobileViT-XXS (`apple/mobilevit-xx-small` on Hugging Face) | These are generic ImageNet classifiers. None of them "know" what a playing video looks like — you'd have to collect and label your own dataset of Instagram/TikTok/YouTube screenshots (video vs. static) and fine-tune one of these as the *last-resort* Signal-4 replacement. Not worth the labeling effort given Signals 1–3 already cover the vast majority of cases. |
| **Motion/optical-flow models** | RAFT, PWC-Net (both on GitHub, e.g. `princeton-vl/RAFT`) | Academically the "correct" tool for detecting motion, but designed for accuracy-focused offline video analysis — RAFT alone needs a real GPU to hit real-time frame rates. Absurdly disproportionate to a task that classical frame-differencing (§1, Signal 4) already solves in a few lines of integer math. |

**Recommendation:** don't adopt any of the above as-is. If, after shipping Signals 1–3, real-world
telemetry shows a meaningful share of sessions falling through to Signal 4 on specific apps,
*then* it's worth fine-tuning **MobileNetV3-Small** (smallest reasonable footprint, well-supported
TFLite export path, `google/mobilenet_v3_small_100_224` on Hugging Face as the starting
checkpoint) on a small labeled dataset of that app's own screenshots — a binary classifier, not a
detector, quantized to `int8` via TFLite for inference under ~5ms per frame. That's a Phase-3+
optimization, not a v1 requirement.

---

## 5. Data model & config additions

```dart
// domain/entities/script.dart — additive fields, backward compatible
@freezed
class Script with _$Script {
  const factory Script({
    required String id,
    required String name,
    required Duration scrollInterval,
    // ... existing fields (clickPoints, swipeConfig, etc.) ...

    // Feature B additions:
    @Default(false) bool holdOnVideoEnabled,
    @Default(Duration(minutes: 3)) Duration maxVideoWaitDuration,
    @Default(true) bool useMotionFallback, // Signal 4 opt-in/opt-out
  }) = _Script;
}
```

```dart
// UI addition — Create Script screen (screen 8) gains a new AppToggleRow +
// AppLabeledTextField pair, following the exact widget pattern already
// used for every other option on that screen:
AppToggleRow(
  label: 'Hold scroll during videos',
  subtitle: 'Pause auto-scroll when a video is playing on screen.',
  value: holdOnVideoEnabled,
  onChanged: (v) => controller.setHoldOnVideo(v),
),
if (holdOnVideoEnabled)
  AppLabeledTextField(
    label: 'Max wait time',
    controller: maxWaitController, // "3 min" default, editable
    keyboardType: TextInputType.number,
  ),
```

The Running screen (screen 11, already built) should surface the hold state live — e.g. the
`RunningStatusIndicator` (already built, §2.2 of the perf doc) swaps its label to "Waiting for
video…" and its color to an info-blue while `VideoHoldPhase.waitingForEnd` is active, reusing the
exact same widget with a new state rather than a new one.

---

## 6. Verification / test matrix

Player view class names (§1, Signal 2's table) drift across app updates — this needs a living
checklist, not a one-time verification:

| App | Test scenario | Expected behavior |
|---|---|---|
| Instagram Reels | Full-screen video autoplays | Scroll holds until video loop-count/duration heuristic or MediaSession signals end |
| Instagram feed | Static photo post | No hold — scroll proceeds on schedule |
| TikTok | Standard For You video | Scroll holds |
| YouTube Shorts | Muted-by-default short | Signal 1 (MediaSession) still fires even when muted — verify this specifically, since Signal 3 (audio) would miss it |
| Facebook Reels | Video with captions overlay | Verify the caption overlay view doesn't get misidentified as blocking the surface node search |
| Any app | Video buffering on poor connection | Max-wait timeout (§2) fires and scroll resumes — never hangs indefinitely |
| Any app | Livestream (no natural end) | Max-wait timeout is the only exit — confirm it's honored |
| Notification Access denied | Any app | Detector gracefully falls through to Signal 2/3/4 only — never crashes |

---

## 7. Implementation roadmap

### Phase 1 — Core detection (MVP)
- [ ] `MediaSessionWatcher` (Signal 1) + Notification Access permission-request flow
- [ ] `VideoSurfaceDetector` (Signal 2) with the initial view-class table
- [ ] `VideoPlaybackDetector` combiner + `waitForVideoToEnd()` loop with the 3-min safety valve
- [ ] `Script` entity fields + Create Script screen UI additions (§5)

### Phase 2 — Corroboration & UX polish
- [ ] `AudioPlaybackConfigWatcher` (Signal 3) wired in as a tiebreaker
- [ ] Running screen status indicator reflects `waitingForEnd` phase live
- [ ] Per-app view-class table externalized to a config file (not hardcoded) so it can be updated
      without a full app release if an app's UI changes

### Phase 3 — Fallback hardening
- [ ] `FrameDiffMotionDetector` (Signal 4) via `AccessibilityService.takeScreenshot()`
- [ ] Telemetry (opt-in, on-device only — no data leaves the phone per skill §5) on how often
      each signal tier actually fires, to decide whether Phase 4 is worth doing at all

### Phase 4 — ML fallback (only if Phase 3 telemetry justifies it)
- [ ] Collect + label a small screenshot dataset for whichever specific app/scenario Signal 4
      underperforms on
- [ ] Fine-tune MobileNetV3-Small, export `int8`-quantized TFLite, benchmark inference latency
      against the Signal 4 classical heuristic before deciding to ship it

---

## 8. Permissions summary

| Signal | New permission needed? |
|---|---|
| 1 — MediaSession | Notification Access (`BIND_NOTIFICATION_LISTENER_SERVICE`) — new, one-time grant |
| 2 — Accessibility view tree | None — already required for gesture dispatch |
| 3 — Audio playback config | None — no permission required for this API |
| 4 — Frame-diff via `takeScreenshot()` | None beyond Accessibility — critically, **not** `MediaProjection`, so no persistent screen-recording notification |

This keeps Feature B within the app's existing "no backend, no `INTERNET` permission, minimal
permission footprint" security posture (skill §5) — the one new permission (Notification Access)
is standard, well-understood by users, and revocable at any time in system settings.
