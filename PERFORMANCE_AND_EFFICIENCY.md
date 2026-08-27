# Auto Clicker — Performance, Stability & Efficiency Playbook

> Companion doc to the `auto-clicker-project` skill (§5 Security, §6 Performance). That skill
> defines the *architecture*; this doc defines the *engineering discipline* that keeps the app
> fast, stable, and light on every device class — from a 3-year-old budget Android phone to the
> latest iPhone. Read this before writing performance-sensitive code, and re-check the
> **Pre-Release Checklist** (bottom) before every store submission.

**Target bar, stated as numbers, not adjectives:**

| Metric | Target |
|---|---|
| Cold start → first interactive frame | < 1.5s on a mid-range device (e.g. Pixel 6a / iPhone 12) |
| Dropped frames during any screen transition | 0 (locked 60fps; 120fps on ProMotion/high-refresh Android where available) |
| Steady-state idle CPU (script not running) | < 1% |
| Steady-state CPU while a script is actively running | < 8% (dispatchGesture is cheap; the danger is UI rebuilding every tick) |
| Steady-state RAM | < 90MB on Android, < 100MB on iOS |
| Installed size per architecture | 15–20MB (already a target in §6 of the skill) |
| Battery drain over 1hr continuous run | < 5% on a device with >3000mAh battery |
| Crash-free sessions | > 99.5% |
| ANR-free sessions (Android) | > 99.8% |

Everything below is in service of hitting that table.

---

## 1. Guiding Principles (priority order, same as skill §1)

1. **Correctness & Security first** — a fast app that corrupts a script or leaks a key is worse
   than a slightly slower one that doesn't. Never sacrifice `HiveAesCipher` encryption or
   `ScriptValidator` bounds-checking for a speed win.
2. **Perceived smoothness over raw benchmark numbers** — a 58fps scroll with zero jank *feels*
   faster than a 60fps scroll with one dropped frame every 2 seconds. Optimize for frame
   **consistency**, not just frame **rate**.
3. **Battery and thermals are a UX feature, not an afterthought** — this app's entire premise is
   running unattended for long periods. A battery-draining auto-clicker gets uninstalled and
   1-starred within a day.
4. **Lightweight by default, not by cleanup pass** — every dependency, asset, and abstraction is
   justified at the moment it's added (§6 "Dependency discipline"), not trimmed later.
5. **Fail loud in debug, fail safe in release** — asserts and `flutter_lints` catch problems
   before they ship; `Result<Failure, T>` and defensive fallbacks make sure a release build never
   shows a blank screen or a crash dialog to the user.

---

## 2. Rendering & UI Performance

### 2.1 `const` everywhere it's structurally possible

Every widget subtree that doesn't depend on runtime state should be `const`. This is the single
highest-leverage, lowest-effort win in the whole app — it means Flutter skips rebuilding (and in
many cases skips re-layout/re-paint of) that subtree entirely.

```dart
// ❌ Rebuilt every time the parent rebuilds, even though nothing changed
Widget build(BuildContext context) {
  return Column(
    children: [
      Icon(Icons.touch_app, color: AppColors.primaryBlue),
      SizedBox(height: 12),
      Text('Tap to begin', style: AppTextStyles.subtext),
    ],
  );
}

// ✅ Flutter caches and skips this subtree on rebuild
Widget build(BuildContext context) {
  return const Column(
    children: [
      Icon(Icons.touch_app, color: AppColors.primaryBlue),
      SizedBox(height: 12),
      Text('Tap to begin', style: AppTextStyles.subtext),
    ],
  );
}
```

Enforce this automatically rather than relying on memory — add to `analysis_options.yaml`:

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_constructors_in_immutables: true
    prefer_const_literals_to_create_immutables: true
    prefer_const_declarations: true
    avoid_unnecessary_containers: true
    sized_box_for_whitespace: true
```

Run `dart fix --apply` periodically — it auto-inserts missing `const` keywords.

### 2.2 `RepaintBoundary` around anything that repaints independently

Screen 9's click-point overlay is the canonical case (already called out in skill §6): dragging
one marker must not repaint the whole canvas.

```dart
// lib/presentation/widgets/overlay/click_point_marker.dart
class ClickPointMarker extends StatelessWidget {
  const ClickPointMarker({super.key, required this.point, required this.onDrag});

  final ClickPoint point;
  final ValueChanged<Offset> onDrag;

  @override
  Widget build(BuildContext context) {
    // Isolates this marker's repaints from every sibling marker and from
    // the static dot-grid background painted beneath it.
    return RepaintBoundary(
      child: Positioned(
        left: point.x,
        top: point.y,
        child: GestureDetector(
          onPanUpdate: (details) => onDrag(details.localPosition),
          child: const _MarkerGlyph(),
        ),
      ),
    );
  }
}
```

The same pattern applies to the Running screen's pulsing status dot
(`RunningStatusIndicator`, already wrapped in its own `AnimationController`) — its
`FadeTransition` must never force the surrounding stat cards to repaint. Verify with the Flutter
DevTools **"Highlight repaints"** overlay during development; any widget that flashes on every
tick but shouldn't needs a `RepaintBoundary`.

### 2.3 Riverpod `select()` — rebuild the minimum, not the screen

This is the single biggest CPU win *while a script is running*, because the Running screen's
click counter ticks every gesture (potentially several times a second).

```dart
// ❌ Rebuilds the ENTIRE Running screen every time any field in
// RunSessionState changes — including the Pause/Stop buttons, which never
// need to redraw on a click-count tick.
final session = ref.watch(runSessionControllerProvider);
Text('${session.clicks}');

// ✅ Only the Text widget wrapped by Consumer rebuilds; Pause/Stop, the
// script-name field, and the Speed row are untouched.
Consumer(
  builder: (context, ref, _) {
    final clicks = ref.watch(
      runSessionControllerProvider.select((s) => s.clicks),
    );
    return Text(_formatClicks(clicks));
  },
)
```

Apply `select()` at **every** call site that reads a multi-field state object for a single
field — the Running screen's stat cards, the Saved Scripts filter count, and the Settings
toggles should each only rebuild on their own field.

### 2.4 Lists: always `ListView.builder`, never `Column` + `map()`

```dart
// ❌ Builds every SavedScriptTile eagerly, even off-screen ones — fine for
// 4 placeholder scripts, a real problem once a power user has 200 saved.
Column(children: scripts.map((s) => SavedScriptTile(script: s)).toList())

// ✅ Lazily builds only what's visible (+ a small cache extent)
ListView.builder(
  itemCount: scripts.length,
  itemExtent: AppDimensionsX.scriptTileHeight + AppDimensionsX.scriptTileGap,
  itemBuilder: (context, index) => SavedScriptTile(script: scripts[index]),
)
```

Setting `itemExtent` (all tiles are the same fixed height per the Figma spec) lets Flutter skip
a full layout pass per item and jump straight to the right scroll offset — meaningfully cheaper
than letting `ListView.builder` measure every child.

### 2.5 Keys where list order can change

Saved Scripts supports rename/delete/reorder eventually — every `SavedScriptTile` needs a
`ValueKey` tied to the script's stable `id`, not its list index, or Flutter will misattribute
animation/dismiss state across items after a delete.

```dart
SavedScriptTile(key: ValueKey(script.id), script: script)
```

---

## 3. State Management Discipline

### 3.1 One thin `Notifier` per screen, not one god-provider

```dart
// lib/presentation/controllers/running_session_controller.dart
@riverpod
class RunningSessionController extends _$RunningSessionController {
  StreamSubscription<RunEvent>? _sub;

  @override
  RunSessionState build(String scriptId) {
    // Subscribe to the domain-layer use case's event stream instead of a
    // local Timer (see §4.2) — cancel it automatically when this provider
    // is disposed (screen popped / minimized-and-stopped).
    final useCase = ref.watch(runScriptUseCaseProvider);
    _sub = useCase.watch(scriptId).listen(_onEvent);
    ref.onDispose(() => _sub?.cancel());
    return RunSessionState.initial(scriptId);
  }

  void _onEvent(RunEvent event) {
    state = state.copyWith(
      clicks: event.totalClicks,
      runtime: event.elapsed,
      isPaused: event.isPaused,
    );
  }

  Future<void> togglePause() async {
    final useCase = ref.read(runScriptUseCaseProvider);
    state.isPaused ? await useCase.resume(state.scriptId)
                    : await useCase.pause(state.scriptId);
  }
}
```

Why this matters for performance specifically: a single global `AppController` that holds
*every* screen's state means **any** state change anywhere in the app invalidates every widget
watching that provider, even ones on a completely different screen that happens to still be in
the widget tree (e.g. kept alive by an `IndexedStack`). Scoped, screen-local controllers bound
the blast radius of every `state =` assignment.

### 3.2 `AsyncValue` + `.guard()` for every async op — never a raw `try/catch` that swallows state

```dart
Future<void> deleteScript(String id) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(() => ref.read(scriptRepositoryProvider).delete(id));
}
```

This isn't just correctness — it's a performance/stability overlap: `AsyncValue`'s built-in
loading/error states mean the UI never has to poll a `isLoading` bool or guess whether a
previous request is still in flight, which is a common source of duplicate network/disk calls in
hand-rolled state.

---

## 4. Automation Engine Efficiency

### 4.1 Event-driven, zero polling (Android)

The Accessibility Service's `dispatchGesture()` callback already tells us exactly when a gesture
completes — build the entire click loop around that callback, never a `Timer.periodic` that
*guesses* when the previous tap finished.

```kotlin
// android/app/src/main/kotlin/.../AutoClickAccessibilityService.kt
class AutoClickAccessibilityService : AccessibilityService() {

    private val callback = object : GestureResultCallback() {
        override fun onCompleted(gestureDescription: GestureDescription?) {
            // Only schedule the NEXT tap once this one is confirmed done —
            // this is what makes the loop event-driven instead of polling.
            scheduleNextTap()
        }
        override fun onCancelled(gestureDescription: GestureDescription?) {
            // Back off and retry once instead of silently dropping the tap —
            // stability over raw throughput.
            retryWithBackoff()
        }
    }

    private fun dispatchTap(x: Float, y: Float) {
        val path = Path().apply { moveTo(x, y) }
        val stroke = GestureDescription.StrokeDescription(path, 0, 50)
        val gesture = GestureDescription.Builder().addStroke(stroke).build()
        dispatchGesture(gesture, callback, null)
    }
}
```

### 4.2 Never poll the click counter from the UI layer

The Running screen currently ships with a placeholder `Timer.periodic` (see the
`INTEGRATION_README.md` TODOs) driving the Clicks/Runtime counters. That's fine for a UI demo,
but it's the wrong shape for production for two reasons: it drifts from the real gesture count
under load, and it fires UI rebuilds on a fixed clock instead of on real events (wasted work
when nothing changed, e.g. mid-pause).

```dart
// Domain-layer contract the platform engine implements — presentation
// only ever consumes this Stream, never a Timer.
abstract class AutomationEngine {
  Stream<RunEvent> run(Script script);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
}

// data/engines/android_accessibility_engine.dart
class AndroidAccessibilityEngine implements AutomationEngine {
  final _controller = StreamController<RunEvent>.broadcast();
  static const _channel = MethodChannel('auto_clicker/accessibility');

  @override
  Stream<RunEvent> run(Script script) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onTapDispatched') {
        _controller.add(RunEvent.fromPlatform(call.arguments));
      }
    });
    _channel.invokeMethod('start', script.toPlatformMap());
    return _controller.stream;
  }
  // pause/resume/stop call the corresponding platform methods...
}
```

This also directly serves battery life: a `Timer.periodic` keeps firing (and keeps the Dart
isolate scheduler warm) even during a pause; an event stream is silent — zero cost — whenever
nothing is actually happening.

### 4.3 Heavy work off the UI thread via `compute()`

Already specified in skill §6 for import/export — extend the same rule to `ScriptValidator`
(security §5) since bounds-checking a large imported script is real CPU work:

```dart
// domain/usecases/import_script_usecase.dart
class ImportScriptUseCase {
  Future<Result<Failure, Script>> call(String rawJson) async {
    // compute() spins up a background Isolate so a large/malicious 5MB
    // script file can't jank the UI thread while it's being parsed and
    // validated — directly serves both stability (§5) and smoothness (§6).
    final result = await compute(_parseAndValidate, rawJson);
    return result;
  }
}

// Top-level function required by compute() — must not close over Flutter
// or `this`, since it runs in a separate Isolate with its own memory.
Result<Failure, Script> _parseAndValidate(String rawJson) {
  final map = jsonDecode(rawJson) as Map<String, dynamic>;
  final script = ScriptModel.fromJson(map).toEntity();
  return ScriptValidator().validate(script);
}
```

---

## 5. Storage & Data Layer

### 5.1 Hive box strategy — lazy boxes for large/rarely-read data

```dart
// core/di/storage_setup.dart
Future<void> setupHive() async {
  final key = await _getOrCreateEncryptionKey(); // flutter_secure_storage, §5 skill

  // Scripts are read on nearly every screen — keep this box fully in
  // memory (Hive.openBox) for instant access.
  await Hive.openBox<ScriptModel>(
    'scripts',
    encryptionCipher: HiveAesCipher(key),
  );

  // Run-history/analytics-adjacent data (if ever added) is read rarely —
  // openLazyBox keeps it on disk until a specific key is requested,
  // trading a small read latency for meaningfully lower steady-state RAM.
  await Hive.openLazyBox<RunLogEntry>(
    'run_logs',
    encryptionCipher: HiveAesCipher(key),
  );
}
```

### 5.2 Batch writes, don't write per-field

```dart
// ❌ Three separate encrypted disk writes for one logical update
await scriptsBox.put('name', script.name);
await scriptsBox.put('interval', script.intervalValue);
await scriptsBox.put('repeatCount', script.repeatCount);

// ✅ One write — the whole immutable Script (via freezed copyWith) goes in
// as a single encrypted record
await scriptsBox.put(script.id, ScriptModel.fromEntity(script));
```

### 5.3 Repository-level caching for read-heavy, write-light data

`AppSettings` (Settings screen) is read on nearly every screen (theme, language) but written
rarely (a user flips a toggle occasionally). Cache it in memory inside the repository
implementation instead of hitting Hive on every read:

```dart
// data/repositories_impl/settings_repository_impl.dart
class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._box);
  final Box<AppSettingsModel> _box;
  AppSettings? _cache;

  @override
  AppSettings getSettings() {
    return _cache ??= (_box.get('settings')?.toEntity() ?? AppSettings.defaults());
  }

  @override
  Future<void> update(AppSettings settings) async {
    _cache = settings; // update cache first — synchronous UI reads see it immediately
    await _box.put('settings', AppSettingsModel.fromEntity(settings));
  }
}
```

---

## 6. Memory Management & Leak Prevention

### 6.1 Always dispose — controllers, timers, streams, animation controllers

This is the #1 source of slow memory creep in long-running apps like this one (Running screen
may stay mounted for hours).

```dart
@override
void dispose() {
  _ticker?.cancel();                 // Timer
  _scriptNameController.dispose();   // TextEditingController
  _speedController.dispose();
  _animationController.dispose();    // AnimationController
  _runEventSub?.cancel();            // StreamSubscription
  super.dispose();
}
```

Catch regressions automatically rather than relying on code review: add the
`leak_tracker`/`memory_leak` checks that `flutter test --enable-experiment` supports, and run a
DevTools **Memory** snapshot before/after navigating Running → Saved Scripts → Running ten times
in a row during manual QA — RSS should return to baseline, not ratchet upward.

### 6.2 Image cache ceiling

Vector assets (§6 skill: `flutter_svg` preferred) sidestep most of this, but any raster asset
still goes through Flutter's image cache — cap it explicitly so a user with dozens of custom
per-script icons (future feature) can't balloon memory:

```dart
// main.dart, before runApp()
PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50MB ceiling
```

### 6.3 Avoid capturing `BuildContext` / `this` in long-lived callbacks

```dart
// ❌ The MethodChannel handler closure captures `this` (the State object)
// forever — if the screen is popped while a script is still running in
// the background, the old State (and its whole widget subtree) can't be
// garbage collected.
_channel.setMethodCallHandler((call) async {
  setState(() => _clicks++);
});

// ✅ Route through the Riverpod controller (see §3.1), which is scoped to
// the provider's own lifecycle via ref.onDispose — not to a widget's.
```

---

## 7. Battery & Background Efficiency

### 7.1 Foreground service notification — minimal, not chatty

Android requires a persistent notification for `FOREGROUND_SERVICE`; keep its update frequency
low (once per state change — start/pause/resume/stop — never once per tap) since each
`NotificationManager.notify()` call has real system overhead:

```kotlin
// Update on state transitions only
fun onScriptStateChanged(newState: RunState) {
    val notification = buildNotification(newState) // "Running: Auto Scroll" / "Paused"
    notificationManager.notify(FOREGROUND_NOTIF_ID, notification)
}
// Do NOT call this from the per-tap dispatchGesture callback.
```

### 7.2 Disable non-essential animations while minimized

The pulsing `RunningStatusIndicator` dot (§2.2) is pure UI polish — pause its
`AnimationController` when the app is backgrounded, since an invisible animation still costs a
Ticker callback every frame:

```dart
class _RunningStatusIndicatorState extends State<RunningStatusIndicator>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.repeat(reverse: true);
    }
  }
}
```

### 7.3 Debug logging must be a no-op in release builds

```dart
// core/util/logger.dart
void logDebug(String message) {
  assert(() {
    // ignore: avoid_print
    debugPrint('[AutoClicker] $message');
    return true;
  }());
}
```
Wrapping in `assert()` means the entire call — including string interpolation — is tree-shaken
out of release builds by the Dart compiler. A surprising number of "why is battery drain higher
than expected" bugs trace back to verbose logging left in a release build.

---

## 8. Startup Time & App Size

### 8.1 Keep `main()` synchronous-fast; defer anything non-critical

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Only what the FIRST frame needs, synchronously:
  await setupHive();          // §5.1 — needed for splash → home-vs-onboarding decision
  await setupSecureStorage(); // encryption key, needed by Hive above

  runApp(const ProviderScope(child: AutoClickerApp()));

  // Everything else can happen after the first frame is already on screen:
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _warmUpNonCriticalServices(); // e.g. billing SDK init, update checker
  });
}
```

### 8.2 Build flags — exactly as specified in skill §6, kept here as copy-pasteable commands

```bash
# Android — separate small APKs per ABI instead of one bloated universal APK
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=./debug-symbols

# Android App Bundle for Play Store (preferred over APK for store upload —
# Play does the per-device splitting server-side)
flutter build appbundle --release --obfuscate --split-debug-info=./debug-symbols

# iOS — App Thinning/bitcode-equivalent slicing happens automatically via
# Xcode archive; strip symbols explicitly for the release configuration
flutter build ipa --release --obfuscate --split-debug-info=./debug-symbols
```

```gradle
// android/app/build.gradle
android {
    buildTypes {
        release {
            minifyEnabled true      // R8 code shrinking
            shrinkResources true    // strips unused resources too
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 8.3 Asset discipline

```yaml
# pubspec.yaml — only declare what's actually used; flutter_svg for
# icons/illustrations per skill §6, raster only where SVG can't represent
# the asset (e.g. photographic content, which this app shouldn't have any of)
flutter:
  assets:
    - assets/icons/
    - assets/images/
  fonts:
    - family: Roboto  # placeholder per skill §13 — swap once font is confirmed
      fonts:
        - asset: assets/fonts/Roboto-Regular.ttf
        - asset: assets/fonts/Roboto-Bold.ttf
          weight: 700
```

Run `flutter build apk --analyze-size` before each release and diff against the previous
release's size report — catches an accidentally-committed large asset before it ships.

---

## 9. Stability & Error Handling

### 9.1 `Result<Failure, T>` at every domain boundary — no raw exceptions crossing layers

```dart
// core/error/failure.dart
@freezed
sealed class Failure with _$Failure {
  const factory Failure.storage(String message) = StorageFailure;
  const factory Failure.validation(String message) = ValidationFailure;
  const factory Failure.permissionDenied() = PermissionDeniedFailure;
  const factory Failure.platformUnsupported(String reason) = PlatformUnsupportedFailure;
}

// Every use case returns this instead of throwing:
Future<Result<Failure, Script>> call(CreateScriptParams params) async {
  final validation = ScriptValidator().validate(params.toEntity());
  if (validation.isInvalid) {
    return Result.failure(Failure.validation(validation.reason));
  }
  try {
    final saved = await _repository.save(params.toEntity());
    return Result.success(saved);
  } on HiveError catch (e) {
    return Result.failure(Failure.storage(e.message));
  }
}
```

Every call site is then **forced** by the type system to handle both branches — no silent
`catch (e) {}` swallowing errors, and no unhandled exception reaching the framework's default
red-screen-of-death in release mode (which on some OEM Android skins can look like a full crash
to the user even when it isn't one).

### 9.2 Global error handlers as the last line of defense

```dart
// main.dart
Future<void> main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      // TODO(qaswar): route to opt-in crash reporting once added (§5 skill —
      // "if crash reporting is added later, it must be opt-in and disclosed")
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      // Catches errors outside the Flutter framework (e.g. in a platform
      // channel callback) that FlutterError.onError won't see.
      return true; // handled — don't crash the whole app
    };
    await setupHive();
    runApp(const ProviderScope(child: AutoClickerApp()));
  }, (error, stack) {
    // Catches anything that escapes even the above — the true last resort.
  });
}
```

### 9.3 Never let a missing asset crash a screen

Already a convention in skill §14 ("Missing assets never crash") — the concrete implementation:

```dart
// presentation/widgets/common/app_asset_image.dart
class AppAssetImage extends StatelessWidget {
  const AppAssetImage(this.assetPath, {super.key, this.width, this.height, this.fallbackIcon = Icons.image_not_supported_outlined});

  final String assetPath;
  final double? width;
  final double? height;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: AppColors.borderGray.withValues(alpha: 0.3),
        child: Icon(fallbackIcon, color: AppColors.textSecondary),
      ),
    );
  }
}
```

### 9.4 Defensive bounds-checking on every imported/user-editable value

Directly extends `ScriptValidator` (§5 skill) — never trust a coordinate, delay, or repeat count
from an imported file, even after schema validation passes:

```dart
class ScriptValidator {
  static const _maxClickPoints = 200;
  static const _maxDelayMs = 60000;
  static const _minDelayMs = 0;

  Result<Failure, Unit> validate(Script script) {
    if (script.clickPoints.length > _maxClickPoints) {
      return Result.failure(Failure.validation('Too many click points'));
    }
    for (final p in script.clickPoints) {
      if (p.delayMs < _minDelayMs || p.delayMs > _maxDelayMs) {
        return Result.failure(Failure.validation('Delay out of bounds'));
      }
      if (p.x.isNaN || p.y.isNaN || p.x < 0 || p.y < 0) {
        return Result.failure(Failure.validation('Invalid coordinate'));
      }
    }
    return const Result.success(unit);
  }
}
```

---

## 10. Cross-Device Consistency (low-end → high-end)

### 10.1 `DesignScaleContext` is already the mechanism — use it without exception

Every screen already routes pixel values through `context.scaleW()`/`scaleH()`/`scaleUniform()`
(skill §14 convention). The performance angle: this same mechanism is what prevents *layout
overflow exceptions* on small/low-end devices, which are a top cause of "app looks broken" bug
reports that have nothing to do with raw speed but everything to do with perceived stability.

```dart
// Never do this:
Container(width: 120, height: 40, ...)

// Always this — scales proportionally instead of clipping/overflowing on
// a 5" 720p device while looking correct on a 6.7" 1440p device:
Container(
  width: context.scaleW(120),
  height: context.scaleH(40),
  ...
)
```

### 10.2 Test matrix — minimum device classes before every release

| Class | Example | What to verify |
|---|---|---|
| Low-end Android | 2GB RAM, Android 10, e.g. Galaxy A03 | No jank on Running screen tick, no OOM, cold start < 2.5s |
| Mid-range Android | Pixel 6a / Galaxy A54 | Meets the target table at the top of this doc exactly |
| High-refresh Android | 120Hz OnePlus/Samsung | Verify animations run at 120fps, not capped at 60 |
| Small iPhone | iPhone SE (3rd gen) | No layout overflow, Switch Control deep-link works |
| Modern iPhone | iPhone 15 | Baseline reference |
| Tablet (if supported) | Android tablet / iPad | Verify `DesignScaleContext` doesn't over-scale UI absurdly large |

### 10.3 `flutter run --profile` is the only mode that matters for perf judgment

Debug builds are intentionally slower (assertions, no tree-shaking, JIT). Never judge jank,
startup time, or frame rate from a debug build — always `--profile` (or `--release` for final
numbers) with DevTools attached.

```bash
flutter run --profile --trace-skia
```

---

## 11. Testing, Profiling & Monitoring Strategy

### 11.1 Performance regression tests via `integration_test`

```dart
// integration_test/running_screen_perf_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Running screen sustains 60fps during a simulated 100-click run',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AutoClickerApp()));
    await tester.pumpAndSettle();

    final timeline = await tester.binding.traceAction(() async {
      for (var i = 0; i < 100; i++) {
        // simulate incoming RunEvent ticks
        await tester.pump(const Duration(milliseconds: 16));
      }
    });

    final summary = TimelineSummary.summarize(timeline);
    expect(summary.computeAverageFrameBuildTimeMillis(), lessThan(8));
    summary.writeTimelineToFile('running_screen_perf', pretty: true);
  });
}
```

Run this in CI on every PR touching `presentation/screens/running/` — catches a `select()`
regression (§2.3) before it ships, not after a user reports jank.

### 11.2 DevTools checklist during manual QA

- **Performance tab** → record a session covering Splash → Onboarding → Dashboard → Create
  Script → Running, confirm no red (jank) frames.
- **Memory tab** → snapshot before/after 10x navigation loop (§6.1), confirm RSS returns to
  baseline.
- **CPU Profiler** → while a script is "running" (simulated), confirm CPU sits near-idle between
  ticks — a flat-line-then-spike pattern is healthy; a sawtooth that never returns to baseline
  means something is polling.
- **Network tab** → should show **zero** entries, ever (skill §5 — no `INTERNET` permission
  declared at all; if anything appears here, something is wrong).

### 11.3 Golden tests for layout stability

```dart
testWidgets('SettingsScreen matches golden on small + large screens', (tester) async {
  await tester.binding.setSurfaceSize(const Size(360, 640)); // small device
  await tester.pumpWidget(const ProviderScope(child: SettingsScreen()));
  await expectLater(find.byType(SettingsScreen), matchesGoldenFile('settings_small.png'));

  await tester.binding.setSurfaceSize(const Size(430, 932)); // large device
  await tester.pumpWidget(const ProviderScope(child: SettingsScreen()));
  await expectLater(find.byType(SettingsScreen), matchesGoldenFile('settings_large.png'));
});
```

---

## 12. Implementation Roadmap

A phased plan to take the app from "all 13 screens coded" (current state per the skill) to
meeting every target in the table at the top of this doc.

### Phase 1 — Foundation correctness (blocks everything else)
- [ ] Wire `AutomationEngine` interface + both platform implementations (§4.1–4.2)
- [ ] Replace every screen's local `Timer`/hardcoded-list placeholder with the real
      Riverpod controllers + repository calls (tracked as `TODO(qaswar)` across screens 7, 9,
      10, 11, 12, 13 per the skill's "Known gaps" list)
- [ ] Implement `Result<Failure, T>` + `ScriptValidator` (§9.1, §9.4) before any real user data
      can flow through the app
- [ ] Global error handlers in `main()` (§9.2)

### Phase 2 — Rendering & state discipline
- [ ] Add the lint rules in §2.1 to `analysis_options.yaml`; run `dart fix --apply`
- [ ] Audit every screen for missing `RepaintBoundary` (§2.2) using the DevTools repaint overlay
- [ ] Convert every multi-field `ref.watch()` to `select()` (§2.3) — start with Running screen,
      it has the highest tick frequency
- [ ] Convert any remaining `Column` + `.map()` lists to `ListView.builder` (§2.4)

### Phase 3 — Storage & memory
- [ ] Implement the Hive box strategy (§5.1–5.3)
- [ ] Add `dispose()` audits (§6.1) as a PR-template checklist item
- [ ] Set the image cache ceiling (§6.2)

### Phase 4 — Battery & background
- [ ] Foreground service notification throttling (§7.1)
- [ ] Lifecycle-aware animation pausing (§7.2) on every `AnimationController` in the app
- [ ] Strip/assert-wrap all debug logging (§7.3)

### Phase 5 — Size & startup
- [ ] Apply the release build flags (§8.2) to the CI release pipeline
- [ ] Run `--analyze-size` and record a baseline (§8.3)
- [ ] Defer non-critical `main()` work (§8.1)

### Phase 6 — Verification
- [ ] Run the full device test matrix (§10.2) on real hardware, not just emulators/simulators
- [ ] Add the `integration_test` perf test (§11.1) to CI
- [ ] Add golden tests (§11.3) for every screen at 2+ screen sizes
- [ ] Manual DevTools pass (§11.2) on the release build before store submission

---

## 13. Pre-Release Checklist

Run through this immediately before every store submission — it's the fast version of everything
above:

- [ ] `flutter analyze` — zero warnings
- [ ] `flutter build apk --analyze-size` — no unexplained size jump vs. last release
- [ ] DevTools Performance tab — zero red frames across the full navigation flow
- [ ] DevTools Memory tab — RSS returns to baseline after a 10x navigation loop
- [ ] DevTools Network tab — zero entries
- [ ] Battery test — < 5% drain over 1hr continuous run on a physical device
- [ ] Low-end device smoke test (§10.2 table) — no jank, no OOM, no layout overflow
- [ ] All `dispose()` methods present and complete (§6.1) — grep for every
      `TextEditingController`/`AnimationController`/`Timer`/`StreamSubscription` field and
      confirm a matching disposal
- [ ] No `debugPrint`/`print` outside an `assert()` wrapper (§7.3)
- [ ] `--obfuscate --split-debug-info` used for the release build (§5 skill, §8.2 here)
- [ ] Crash-free / ANR-free session rate from the previous release's store console reviewed —
      any regression investigated before shipping the next one
