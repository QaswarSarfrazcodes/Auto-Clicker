# Auto Clicker — New Requirements: Session Fatigue Timer & Content-Aware Adaptive Scroll

**Document type:** New Feature Requirements (FR/NFR) + Technical Feasibility Research
**Status:** Proposed — not yet built. Companion to `PROJECT_COMPLETE.md` and the
`/auto-clicker-project` skill.
**Requested by:** Project owner (Qaswar), framed as two new "PM asks":

> **Roman Urdu summary:** Do naye features chahiye. Pehla — jab app kisi doosri app (jaise
> Instagram/Facebook) par auto-scroll chala rahi ho, to 45 minute ya 1 hour (configurable) ke
> baad **khud se ruk jaye** aur user se "Continue?" poochay. Doosra — agar scroll interval 4-5
> second ka set kiya hai lekin scroll karte waqt **video** aa jaye, to jab tak video khatam na
> ho, agla scroll na ho — yani app ko pata hona chahiye ke screen par video chal rahi hai ya
> nahi. Is document mein dono features ke liye requirements aur — sabse zaroori — **kaunsa free
> ya sasta AI/API/platform** ye kaam kar sakta hai, aur agar Google AI Pro subscription (1
> saal/18 months) li jaye to us se kya fayda hoga, sab research karke likha gaya hai.

---

## 1. Feature A — Session Fatigue Timer ("Auto-Pause & Ask to Continue")

### 1.1 Problem
A script (especially auto-scroll/auto-click) can run indefinitely. Nothing today stops it after
a long stretch, which is both a battery/wear concern and — more importantly — the kind of
"runs forever unattended" behavior that both Play Store review and the user's own instinct
flag as bad practice for this app category.

### 1.2 Requirement — This needs **zero AI, zero API, zero internet**

This is pure application logic, already well inside the existing `ExecuteScriptUseCase` design.

| ID | Requirement |
|---|---|
| FR-A1 | Every script execution tracks continuous elapsed runtime independent of pause/resume gaps |
| FR-A2 | A configurable **Session Limit** (default: off; presets 30 min / 45 min / 1 hour / 2 hours / Custom) can be set globally in Settings, and optionally overridden per-script |
| FR-A3 | When elapsed runtime reaches the Session Limit, the engine **auto-pauses** (does not stop — the script state and click/runtime counters are preserved) |
| FR-A4 | On auto-pause, the user is shown a **"Continue?"** prompt — as an in-app dialog if the app is foregrounded, or as a **high-priority notification with inline Yes/No actions** if the app/script is minimized or the phone is locked |
| FR-A5 | Tapping "Continue" resumes exactly where it left off (same click index, same counters) and restarts a fresh Session Limit countdown |
| FR-A6 | No response within a configurable grace window (default 5 minutes) auto-stops the script fully, rather than leaving it paused-forever silently consuming a foreground-service notification slot |
| FR-A7 | The Session Limit is a **safety/UX feature, not a security feature** — it must not be confused with or replace the hardware kill-switch (Volume Down) or the interval-floor freeze guard already specified elsewhere |

### 1.3 Implementation sketch (Dart, no native/AI needed)

```dart
// domain/usecases/execute_script_usecase.dart (extension of existing design)
class SessionFatigueGuard {
  SessionFatigueGuard({required this.limit, required this.onLimitReached});

  final Duration limit;
  final VoidCallback onLimitReached;
  Duration _elapsedSinceLastCheckIn = Duration.zero;

  /// Call this every engine tick (already happens once per second per the
  /// existing ExecuteScriptUseCase design).
  void onTick(Duration tickSize) {
    _elapsedSinceLastCheckIn += tickSize;
    if (_elapsedSinceLastCheckIn >= limit) {
      onLimitReached(); // triggers pause() + the Continue? prompt
    }
  }

  /// Reset when the user taps "Continue".
  void resetCheckIn() => _elapsedSinceLastCheckIn = Duration.zero;
}
```

The "Continue?" prompt while minimized reuses the **already-specified**
`AutoClickForegroundService` notification channel (§8.3 of the master spec) — just add a second
notification style with two action buttons (`Continue`, `Stop`) instead of the single `Stop`
action it already has. **No new permission, no new dependency.**

### 1.4 Effort & cost
**Free. Lightweight. A few hours of Dart + a notification-action wiring change on the Android
side.** This should ship before Feature B regardless of what's decided there.

---

## 2. Feature B — Content-Aware Adaptive Scroll ("Don't scroll past a playing video")

### 2.1 Problem, precisely restated
User sets a scroll script with e.g. a 4–5 second interval. While scrolling through a feed
(Instagram/Facebook/TikTok/YouTube Shorts style), a **video post** appears. A fixed-interval
scroll doesn't know or care — it scrolls past the video before it finishes. The ask is: **detect
that a video is currently playing on-screen, and hold the next scroll until it ends** (or a
sane per-video maximum wait, so the script never hangs forever on a broken/looping video).

This is fundamentally harder than Feature A because it requires the app to know something about
*what's on someone else's screen* — which is exactly the kind of thing that pulls toward "AI
that watches the screen," but that is **not the only, and not the best, way to solve it.**

### 2.2 Deep-dive: every realistic technical option, ranked

#### 🟢 Option 1 (RECOMMENDED DEFAULT) — Native Media Session detection. No AI. No internet.

Android already requires every well-behaved video/audio app to publish a **`MediaSession`**
with a `PlaybackState` (`STATE_PLAYING`, `STATE_PAUSED`, etc.) whenever it plays media — this is
literally how the lock screen, Bluetooth car displays, and Android Auto already show
play/pause controls for *any* app's media. A **`NotificationListenerService`** in our own app
can call `MediaSessionManager.getActiveSessions()` and read the `PlaybackState` of whatever app
is currently playing something, **without ever looking at a pixel of the screen.**

- **What it needs:** one additional special Android permission — **"Notification access"**
  (`BIND_NOTIFICATION_LISTENER_SERVICE`). This is a *different* special-access permission from
  Accessibility and Overlay (already required), granted the same way: a deep link to
  `Settings > Apps > Special app access > Notification access`, one manual toggle.
- **Cost:** **$0.** Fully on-device, fully offline, no API, no AI model, no network call.
- **Battery/perf cost:** negligible — it's an event callback, not a poll loop.
- **Limitation (must be disclosed honestly):** not every app is equally reliable here.
  YouTube, most music/podcast apps, and full-screen video players almost always expose a proper
  `MediaSession`. Some short-form feeds (Instagram Reels, TikTok, Facebook's in-feed video) are
  **inconsistent** — some versions publish a session, some autoplay muted in-feed video without
  one. This option should ship as the **primary, always-on, free mechanism**, with an honest
  Settings note: *"Works reliably with YouTube and most media apps. Support for
  Instagram/TikTok/Facebook in-feed video depends on that app's version and may not always be
  detected."*

#### 🟡 Option 2 — Accessibility node-tree heuristic (maintained per-app allowlist)

Since the app already runs an `AccessibilityService` for click dispatch, that same service can
also **inspect the current window's `AccessibilityNodeInfo` tree** for view class names known to
render video (`android.widget.VideoView`, ExoPlayer's `PlayerView`, `TextureView` inside a known
Instagram/TikTok package's view hierarchy) and treat a match as "video likely playing."

- **Cost:** **$0**, on-device, offline.
- **Limitation:** this is a **heuristic, not a guarantee** — it requires maintaining a small
  per-app list of view-class signatures, and breaks whenever Meta/TikTok/Google ship a UI
  refactor (which happens often). Treat this as a **fallback/supplement** to Option 1, not a
  replacement, and budget periodic maintenance for it.

#### 🟠 Option 3 — On-device motion/frame-diff via screen capture (generic, app-agnostic)

Capture the screen at a low rate (e.g. 2–4 fps) via Android's `MediaProjection` API, and run a
**simple pixel-difference / optical-flow heuristic** (not a trained AI model — just comparing
consecutive downsampled frames) to detect sustained motion in the region where content sits,
which is a reasonable proxy for "something is playing/animating" vs. a static feed screenshot.

- **Cost:** **$0** — no AI model, no API, no internet. Can be built with plain image-diffing
  math (even a 32×32 downsampled grayscale frame diff is enough signal for "static vs moving").
- **Real downsides, must be disclosed:**
  1. **Requires the separate `MediaProjection` screen-recording consent dialog** — and Android
     does **not** let this be silently pre-approved; the system consent prompt reappears
     essentially every time a new capture session starts (this got stricter, not looser, in
     recent Android versions around foreground-service-type enforcement). That's a real,
     recurring UX cost this app doesn't have today.
  2. Meaningfully higher battery/CPU cost than Option 1 (continuous frame capture, even at low
     fps, is far from free).
  3. Real privacy optics problem: "this automation app is now also screen-recording you" is a
     much bigger ask than "this app can tap your screen," even though no data leaves the device.
  4. A moving GIF/sticker/animated ad would false-positive as "video," which is arguably fine
     (a moving ad is content worth waiting on too) but should be a documented, accepted
     trade-off, not a surprise.
- **Recommendation:** keep this as an **opt-in "Advanced Detection" toggle**, off by default,
  clearly labeled with what extra permission and battery cost it carries — not the default path.

#### 🔴 Option 4 — Cloud multimodal AI vision (Gemini API / similar) analyzing periodic screenshots

This is the literal "AI that looks at the screen" version of the ask — periodically send a
low-res screenshot to a vision-capable LLM (Gemini 2.5/3 Flash, GPT-4o-mini-class models, etc.)
and ask "is a video currently playing in this image, yes/no." Doing the actual research the
user asked for on this path:

**What it would cost — real 2026 numbers, researched:**
- Google's **Gemini Developer API** (the one you'd actually call from app code) has its own
  independent Free tier, separate from any consumer subscription: as of mid-2026, **Gemini 2.5
  Flash / Flash-Lite** offer roughly **1,500 requests/day, 15 RPM, 1M tokens/minute**, free, no
  credit card, and it supports image input. Gemini 2.5 **Pro** was cut down hard on the free
  tier in April 2026 (as low as 50 requests/day) — not viable for a real feature, but Flash/
  Flash-Lite comfortably could be, *if* this were the chosen path.
- **Important correction to the "buy Google AI Pro" idea:** the **consumer Google AI Pro
  subscription** (Google One-bundled, ~$19.99/month historically, repriced around I/O 2026)
  gives you more usage of the **Gemini app, AI Studio's interactive chat UI, Antigravity, and
  Flow** — it does **not** increase the **Developer API** quota your *app's backend calls* draw
  from. Those are billed/rate-limited completely separately, per Google Cloud project, via
  **Cloud Billing** (pay-per-token), not via a personal AI Pro/Ultra subscription. **So: buying
  yourself a Google AI Pro plan for a year would not give this app any extra API headroom at
  all** — that money would need to go toward enabling Cloud Billing on the API project instead
  (which then removes the free tier on that project entirely, pay-per-call from token one — a
  real trap Google's own docs warn about: enabling billing deletes the free tier rather than
  extending it, so a separate always-free project should be kept for this if billing is ever
  turned on elsewhere).
- **Bigger problem than cost — architecture conflict:** this app's entire design (see
  `PROJECT_COMPLETE.md` NFR-07 and the project skill's security section) is **"zero declared
  internet permission, 100% offline, zero outbound calls."** Wiring in a cloud vision API means
  adding `INTERNET` permission and sending screenshots off-device — a direct contradiction of
  that principle, not a small addition. Even on the generous free tier, this should never be
  silently bundled into the default build; if it ships at all, it must be a clearly-labeled,
  off-by-default, explicitly-opt-in mode with its own consent screen ("this feature sends
  periodic low-res screenshots to Google's Gemini API to detect video content — nothing else in
  this app does this").
- **Recommendation: don't build this for v1.** Options 1–3 solve the actual stated problem
  (don't scroll past a video) without any of this cost, latency (a network round-trip per check
  is far slower than a local `MediaSession` read), or architectural compromise.

### 2.3 Recommended solution (what to actually build)

| Priority | Solution | Why |
|---|---|---|
| **Ship first** | Option 1 — MediaSession/NotificationListener detection | Free, instant, on-device, no new architecture conflict, covers YouTube and most media apps reliably |
| **Ship as fallback, same release or soon after** | Option 2 — Accessibility node heuristic for a small maintained allowlist (Instagram, TikTok, Facebook) | Free, catches some of what Option 1 misses on short-form feeds; accepted as "best effort," not guaranteed |
| **Optional, opt-in, later** | Option 3 — frame-diff motion detection | Only if user feedback shows Options 1+2 miss too much; ship behind an explicit "Advanced Detection" toggle with its own permission/battery disclosure |
| **Not recommended for this app** | Option 4 — cloud AI vision | Conflicts with the offline-first architecture, adds real latency/cost/privacy surface for a problem the free on-device options already solve well enough |

### 2.4 New Functional Requirements

| ID | Requirement |
|---|---|
| FR-B1 | Settings exposes a **"Wait for video to finish before scrolling"** toggle, off by default (this is a behavior change to an existing script pattern, so it should be an explicit opt-in, not silently always-on) |
| FR-B2 | When enabled, requires the **Notification Access** special permission — requested via a dedicated permission screen (same pattern as screens 5/6), explaining *why* in plain language before deep-linking to Settings |
| FR-B3 | While a script's configured scroll target is detected as "playing" (`PlaybackState.STATE_PLAYING` via Option 1, or a heuristic match via Option 2), the engine **holds the next scroll dispatch** |
| FR-B4 | A **maximum wait cap** (default 3 minutes, configurable) forces the scroll to proceed even if playback state is stuck "playing" (handles looping videos, ads, or a stuck/misreported state) — this prevents the exact kind of infinite-hang the interval-floor guard elsewhere in the spec already protects against in spirit |
| FR-B5 | If Notification Access is denied/revoked, the feature **silently and safely falls back to fixed-interval scrolling** (never blocks core app usage over an optional feature's permission) |
| FR-B6 | The detection mechanism (Option 1 vs Option 2 heuristic) and its known limitations are disclosed in-app, in plain language, at the point the toggle is enabled — not buried in a settings sub-menu |
| FR-B7 | This feature interacts with Feature A's Session Fatigue Timer additively: time spent "holding" for a video still counts toward elapsed session time (a 45-minute cap shouldn't become 2 hours because the script kept pausing for videos) |

### 2.5 New Non-Functional Requirements

| ID | Requirement |
|---|---|
| NFR-B1 | Zero new outbound network calls — this feature must not compromise the app's existing "zero internet permission" posture |
| NFR-B2 | Detection check latency must be near-instant (<50ms) — this is a local API read (Option 1) or a lightweight node-tree walk (Option 2), never a network round trip |
| NFR-B3 | The feature must degrade gracefully (see FR-B5) rather than fail loudly, since it depends on OS/app behavior outside this app's control |

### 2.6 New permission required (Android)

```xml
<!-- AndroidManifest.xml addition -->
<service
    android:name=".service.MediaPlaybackListenerService"
    android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"
    android:exported="false">
    <intent-filter>
        <action android:name="android.service.notification.NotificationListenerService" />
    </intent-filter>
</service>
```

```kotlin
// service/MediaPlaybackListenerService.kt — sketch
class MediaPlaybackListenerService : NotificationListenerService() {
    private lateinit var mediaSessionManager: MediaSessionManager

    override fun onListenerConnected() {
        mediaSessionManager = getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
    }

    /** Called by the automation engine before each scroll dispatch. */
    fun isAnyRecognizedAppPlayingVideo(): Boolean {
        val component = ComponentName(this, MediaPlaybackListenerService::class.java)
        val controllers = mediaSessionManager.getActiveSessions(component)
        return controllers.any { it.playbackState?.state == PlaybackState.STATE_PLAYING }
    }
}
```

**iOS note:** the closest equivalent is `MPNowPlayingInfoCenter` / observing `AVAudioSession`
route and interruption notifications, but iOS's sandboxing (already documented in the project
skill's §2 platform constraint) limits what a third-party app can observe about *another* app's
now-playing state compared to Android. Treat this as an **Android-first feature**; the iOS
variant should be scoped as a smaller, separate research spike rather than assumed to port
directly.

---

## 3. Summary Table — Every New Requirement, Cost, and Recommendation

| Feature | Needs AI/API? | Needs Internet? | New Permission? | Cost | Recommendation |
|---|---|---|---|---|---|
| A — Session Fatigue Timer | No | No | None | Free | ✅ Build now |
| B — Video detection (Option 1, MediaSession) | No | No | Notification Access | Free | ✅ Build now, ship as default |
| B — Video detection (Option 2, a11y heuristic) | No | No | None (reuses existing Accessibility permission) | Free (some ongoing maintenance) | ✅ Build as fallback |
| B — Video detection (Option 3, frame-diff) | No (just image-diff math, not ML) | No | `MediaProjection` screen-capture consent (recurring) | Free, but real battery/UX cost | 🟡 Optional, opt-in, later |
| B — Video detection (Option 4, cloud vision AI) | Yes | **Yes** | `INTERNET` | Free tier: ~1,500 req/day (Gemini Flash); paid: pay-per-token via Cloud Billing, *not* covered by a personal Google AI Pro subscription | ❌ Not recommended — conflicts with offline-first architecture |

**Direct answer to "agar Google AI Pro le lein to kya fayda":** koi seedha fayda nahi is app ke
liye — Google AI Pro (consumer subscription) sirf Gemini app/AI Studio/Antigravity ki apni
interactive usage limits badhata hai, **app ke andar embed ki gayi Gemini Developer API calls ka
quota alag hai** aur wo Cloud Billing (pay-per-token) se control hota hai, na ke personal
subscription se. Aur chunke recommended solution (Option 1/2) ko AI ki zaroorat hi nahi, ye
sawal is feature ke liye practically irrelevant ho jata hai — paisa bachao, MediaSession use
karo.

---

## 4. Suggested Build Order

1. **Feature A (Session Fatigue Timer)** — smallest, safest, no new permissions, ships fastest.
2. **Feature B, Option 1 (MediaSession detection)** — the real fix for the video-scroll problem,
   still free and on-device, one new special permission with a clear explanation screen.
3. **Feature B, Option 2 (Accessibility heuristic fallback)** — incremental improvement, reuses
   existing permission.
4. Revisit Option 3 only if real usage data shows Options 1+2 aren't catching enough cases —
   and even then, ship it opt-in with full disclosure, never as a silent default.
5. Do not build Option 4 unless a future, separate product decision explicitly chooses to break
   the offline-first architecture for a good enough reason — that's a bigger call than this
   feature pair justifies on its own.

---
*Prepared for Qaswar Sarfraz — Auto Clicker (Flutter, Android + iOS). Cross-referenced against
`PROJECT_COMPLETE.md`'s NFR-07 (zero internet permission) and the `/auto-clicker-project`
skill. Gemini API and Google AI Pro figures reflect research current as of August 2026 —
Google revises pricing/limits often enough that these numbers should be re-verified against
Google's live pricing page before final implementation.*
