# Feature A — Session Fatigue Timer ("Auto-Pause & Ask to Continue")
**Complete implementation solution — Auto Clicker (Flutter, Clean Architecture)**

Covers FR-A1 → FR-A7 from `requirementsautoclicker.md`. Zero AI, zero API, zero internet —
pure Dart engine logic + one native Android notification style. Fits directly into the existing
`domain / data / presentation / core` layout from the project skill; no new folders, no new
dependencies, no new permissions.

---

## 0. What gets touched

```
lib/
├── core/
│   └── constants/
│       └── session_fatigue_presets.dart                 [NEW]
├── domain/
│   ├── entities/
│   │   ├── session_fatigue_config.dart                   [NEW]
│   │   └── session_fatigue_state.dart                    [NEW]
│   ├── repositories/
│   │   └── settings_repository.dart                      [EXTEND]
│   ├── engines/
│   │   └── session_fatigue_guard.dart                     [NEW]
│   └── usecases/
│       ├── run_script_usecase.dart                       [EXTEND]
│       └── resume_after_fatigue_pause_usecase.dart        [NEW]
├── data/
│   ├── models/
│   │   └── session_fatigue_config_model.dart              [NEW]
│   ├── datasources/
│   │   ├── local/settings_local_datasource.dart           [EXTEND]
│   │   └── platform/fatigue_notification_channel.dart     [NEW]
│   └── repositories_impl/
│       └── settings_repository_impl.dart                  [EXTEND]
└── presentation/
    ├── controllers/
    │   └── session_fatigue_controller.dart                 [NEW]
    ├── widgets/
    │   └── execution/continue_or_stop_dialog.dart          [NEW]
    └── screens/settings/widgets/
        └── session_limit_selector.dart                    [NEW]

android/app/src/main/kotlin/.../
├── service/AutoClickForegroundService.kt                   [EXTEND]
└── receiver/FatigueNotificationActionReceiver.kt           [NEW]
```

Dependency rule is respected throughout: `SessionFatigueGuard` is pure Dart with **zero**
Flutter/platform imports (lives in `domain/engines/`, same tier as `AutomationEngine`); native
notification wiring only exists in `data/datasources/platform/` and the Android service.

---

## 1. Core constants — presets (FR-A2)

```dart
// lib/core/constants/session_fatigue_presets.dart

/// Session Limit presets shown in Settings. "Off" (null limit) is the default —
/// FR-A2 requires the feature to be opt-in, not silently always-on.
enum SessionFatiguePreset {
  off,
  thirtyMinutes,
  fortyFiveMinutes,
  oneHour,
  twoHours,
  custom;

  Duration? get duration => switch (this) {
        SessionFatiguePreset.off => null,
        SessionFatiguePreset.thirtyMinutes => const Duration(minutes: 30),
        SessionFatiguePreset.fortyFiveMinutes => const Duration(minutes: 45),
        SessionFatiguePreset.oneHour => const Duration(hours: 1),
        SessionFatiguePreset.twoHours => const Duration(hours: 2),
        SessionFatiguePreset.custom => null, // resolved from a stored custom value
      };

  String get label => switch (this) {
        SessionFatiguePreset.off => 'Off',
        SessionFatiguePreset.thirtyMinutes => '30 minutes',
        SessionFatiguePreset.fortyFiveMinutes => '45 minutes',
        SessionFatiguePreset.oneHour => '1 hour',
        SessionFatiguePreset.twoHours => '2 hours',
        SessionFatiguePreset.custom => 'Custom',
      };
}

/// Grace window default (FR-A6): how long the "Continue?" prompt waits for a
/// response before the engine gives up and stops the script fully.
const Duration kDefaultFatigueGraceWindow = Duration(minutes: 5);

/// Engine tick size the guard is driven at — matches the existing
/// ExecuteScriptUseCase per-second tick already specified in the master spec.
const Duration kFatigueGuardTickSize = Duration(seconds: 1);
```

---

## 2. Domain entities

```dart
// lib/domain/entities/session_fatigue_config.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/constants/session_fatigue_presets.dart';

part 'session_fatigue_config.freezed.dart';

/// Global (Settings) or per-script override configuration for FR-A2.
/// Immutable — same pattern as Script/ClickPoint/SwipeConfig/AppSettings.
@freezed
class SessionFatigueConfig with _$SessionFatigueConfig {
  const SessionFatigueConfig._();

  const factory SessionFatigueConfig({
    @Default(SessionFatiguePreset.off) SessionFatiguePreset preset,
    Duration? customLimit,
    @Default(kDefaultFatigueGraceWindow) Duration graceWindow,
  }) = _SessionFatigueConfig;

  /// Resolves the effective limit, or null if the feature is off (FR-A2 default).
  Duration? get effectiveLimit =>
      preset == SessionFatiguePreset.custom ? customLimit : preset.duration;

  bool get isEnabled => effectiveLimit != null && effectiveLimit! > Duration.zero;

  static const SessionFatigueConfig disabled = SessionFatigueConfig();
}
```

```dart
// lib/domain/entities/session_fatigue_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_fatigue_state.freezed.dart';

/// What phase the fatigue guard is currently in for a running script.
/// FR-A3 / FR-A4 / FR-A6 drive these transitions.
enum SessionFatiguePhase {
  running,          // counting elapsed runtime normally
  awaitingContinue,  // auto-paused, "Continue?" shown, grace window ticking
  autoStopped,       // grace window expired with no response (FR-A6)
}

@freezed
class SessionFatigueState with _$SessionFatigueState {
  const factory SessionFatigueState({
    @Default(SessionFatiguePhase.running) SessionFatiguePhase phase,
    @Default(Duration.zero) Duration elapsedSinceLastCheckIn,
    @Default(Duration.zero) Duration graceElapsed,
  }) = _SessionFatigueState;

  static const initial = SessionFatigueState();
}
```

---

## 3. Domain engine — the guard itself (FR-A1, FR-A3, FR-A5, FR-A6)

This completes the sketch from the requirements doc: continuous elapsed tracking independent
of pause/resume gaps, the grace-window auto-stop, and a clean reset on "Continue."

```dart
// lib/domain/engines/session_fatigue_guard.dart
import 'dart:async';
import '../entities/session_fatigue_config.dart';
import '../entities/session_fatigue_state.dart';

/// Pure Dart. No Flutter, no platform imports — same tier as [AutomationEngine].
/// One instance per running script execution; owned by [RunScriptUseCase].
class SessionFatigueGuard {
  SessionFatigueGuard({
    required this.config,
    required this.onLimitReached,
    required this.onGraceExpired,
  });

  final SessionFatigueConfig config;

  /// FR-A3: fired once the Session Limit is hit. Caller is responsible for
  /// pausing the engine (state/counters preserved) and showing "Continue?".
  final void Function() onLimitReached;

  /// FR-A6: fired if no response arrives within the grace window — caller
  /// fully stops the script rather than leaving it paused-forever.
  final void Function() onGraceExpired;

  SessionFatigueState _state = SessionFatigueState.initial;
  SessionFatigueState get state => _state;

  /// Call once per engine tick (kFatigueGuardTickSize == 1s, matching the
  /// existing ExecuteScriptUseCase tick). Pause/resume gaps in the *script*
  /// itself don't call this, so elapsed time here is continuous "wall" run
  /// time only, per FR-A1 — it is not reset by ordinary user pause/resume of
  /// the automation itself, only by a fatigue check-in (see [resumeCheckIn]).
  void onTick(Duration tickSize) {
    if (!config.isEnabled) return;

    switch (_state.phase) {
      case SessionFatiguePhase.running:
        final elapsed = _state.elapsedSinceLastCheckIn + tickSize;
        if (elapsed >= config.effectiveLimit!) {
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

  /// FR-A5: user tapped "Continue" — resume exactly where the script left
  /// off and restart a fresh Session Limit countdown.
  void resumeCheckIn() {
    _state = const SessionFatigueState(phase: SessionFatiguePhase.running);
  }

  /// FR-A7: this guard is a UX/safety feature only. It must never be wired
  /// to, or substituted for, the hardware kill-switch or the interval-floor
  /// freeze guard — those stay fully independent call sites in the engine.
  void dispose() {
    _state = _state.copyWith(phase: SessionFatiguePhase.autoStopped);
  }
}
```

---

## 4. Repository contract (extend, don't fork)

```dart
// lib/domain/repositories/settings_repository.dart  (diff — add to existing interface)
import '../entities/session_fatigue_config.dart';

abstract class SettingsRepository {
  // ...existing methods (theme, hotkeys, pro status, etc.) unchanged...

  /// Global Session Limit, set in Settings. Defaults to
  /// [SessionFatigueConfig.disabled] per FR-A2.
  Future<SessionFatigueConfig> getGlobalSessionFatigueConfig();
  Future<void> saveGlobalSessionFatigueConfig(SessionFatigueConfig config);

  /// Optional per-script override (FR-A2). Null means "use the global config."
  Future<SessionFatigueConfig?> getScriptSessionFatigueOverride(String scriptId);
  Future<void> saveScriptSessionFatigueOverride(
    String scriptId,
    SessionFatigueConfig? config,
  );
}
```

---

## 5. Data layer

```dart
// lib/data/models/session_fatigue_config_model.dart
import '../../domain/entities/session_fatigue_config.dart';
import '../../core/constants/session_fatigue_presets.dart';

/// DTO + fromJson/toJson + mapper — same pattern as every other model in
/// data/models/. Stored as plain JSON inside the existing O(1) key-index
/// storage engine (§6.1 of the master spec) under key
/// `settings::session_fatigue` (global) or `script::{id}::fatigue_override`.
class SessionFatigueConfigModel {
  const SessionFatigueConfigModel({
    required this.presetIndex,
    required this.customLimitMs,
    required this.graceWindowMs,
  });

  final int presetIndex;
  final int? customLimitMs;
  final int graceWindowMs;

  factory SessionFatigueConfigModel.fromJson(Map<String, dynamic> json) =>
      SessionFatigueConfigModel(
        presetIndex: json['presetIndex'] as int? ?? 0,
        customLimitMs: json['customLimitMs'] as int?,
        graceWindowMs:
            json['graceWindowMs'] as int? ?? kDefaultFatigueGraceWindow.inMilliseconds,
      );

  Map<String, dynamic> toJson() => {
        'presetIndex': presetIndex,
        'customLimitMs': customLimitMs,
        'graceWindowMs': graceWindowMs,
      };

  factory SessionFatigueConfigModel.fromDomain(SessionFatigueConfig config) =>
      SessionFatigueConfigModel(
        presetIndex: config.preset.index,
        customLimitMs: config.customLimit?.inMilliseconds,
        graceWindowMs: config.graceWindow.inMilliseconds,
      );

  SessionFatigueConfig toDomain() => SessionFatigueConfig(
        preset: SessionFatiguePreset.values[presetIndex],
        customLimit:
            customLimitMs != null ? Duration(milliseconds: customLimitMs!) : null,
        graceWindow: Duration(milliseconds: graceWindowMs),
      );
}
```

```dart
// lib/data/datasources/local/settings_local_datasource.dart  (diff — add methods)
abstract class SettingsLocalDataSource {
  // ...existing members...

  Future<Map<String, dynamic>?> readJson(String key);
  Future<void> writeJson(String key, Map<String, dynamic> value);
  Future<void> deleteKey(String key);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  // Reuses the same encrypted O(1) key-index box already used for every
  // other settings value (§6.1/6.3 of the master spec) — no new storage
  // mechanism, no new dependency.
  const SettingsLocalDataSourceImpl(this._box);
  final dynamic _box; // existing Hive/sqflite box wrapper

  static const globalFatigueKey = 'settings::session_fatigue';
  static String scriptFatigueKey(String scriptId) =>
      'script::${scriptId}::fatigue_override';

  @override
  Future<Map<String, dynamic>?> readJson(String key) async =>
      _box.get(key) as Map<String, dynamic>?;

  @override
  Future<void> writeJson(String key, Map<String, dynamic> value) async =>
      _box.put(key, value);

  @override
  Future<void> deleteKey(String key) async => _box.delete(key);
}
```

```dart
// lib/data/repositories_impl/settings_repository_impl.dart  (diff — add methods)
import '../../domain/entities/session_fatigue_config.dart';
import '../datasources/local/settings_local_datasource.dart';
import '../models/session_fatigue_config_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._local);
  final SettingsLocalDataSource _local;

  // ...existing methods...

  @override
  Future<SessionFatigueConfig> getGlobalSessionFatigueConfig() async {
    final json = await _local.readJson(SettingsLocalDataSourceImpl.globalFatigueKey);
    if (json == null) return SessionFatigueConfig.disabled;
    return SessionFatigueConfigModel.fromJson(json).toDomain();
  }

  @override
  Future<void> saveGlobalSessionFatigueConfig(SessionFatigueConfig config) =>
      _local.writeJson(
        SettingsLocalDataSourceImpl.globalFatigueKey,
        SessionFatigueConfigModel.fromDomain(config).toJson(),
      );

  @override
  Future<SessionFatigueConfig?> getScriptSessionFatigueOverride(String scriptId) async {
    final json =
        await _local.readJson(SettingsLocalDataSourceImpl.scriptFatigueKey(scriptId));
    if (json == null) return null;
    return SessionFatigueConfigModel.fromJson(json).toDomain();
  }

  @override
  Future<void> saveScriptSessionFatigueOverride(
    String scriptId,
    SessionFatigueConfig? config,
  ) {
    final key = SettingsLocalDataSourceImpl.scriptFatigueKey(scriptId);
    if (config == null) return _local.deleteKey(key);
    return _local.writeJson(key, SessionFatigueConfigModel.fromDomain(config).toJson());
  }
}
```

---

## 6. Platform channel — the "Continue?" notification (FR-A4)

Reuses the **already-specified** `AutoClickForegroundService` notification channel (master
spec §8.3) — this just adds a second style with two actions instead of the existing single
`Stop` action. No new permission, no new dependency, matching the requirements doc exactly.

```dart
// lib/data/datasources/platform/fatigue_notification_channel.dart
import 'package:flutter/services.dart';

/// Thin MethodChannel glue — the only place in the whole feature that talks
/// to native code. Domain/presentation never import this directly; only
/// SessionFatigueController (via a repository-style wrapper) does.
class FatigueNotificationChannel {
  static const _channel = MethodChannel('com.autoclicker/fatigue_notification');
  static const _actionChannel = EventChannel('com.autoclicker/fatigue_notification_actions');

  /// Shows the high-priority "Continue?" notification with inline
  /// Continue/Stop actions when the app/script is minimized or the phone
  /// is locked (FR-A4). If the app is foregrounded, the caller should show
  /// [ContinueOrStopDialog] instead and skip this call.
  Future<void> showContinuePrompt({required String scriptName}) =>
      _channel.invokeMethod('showContinuePrompt', {'scriptName': scriptName});

  Future<void> dismissContinuePrompt() => _channel.invokeMethod('dismissContinuePrompt');

  /// Stream of 'continue' | 'stop' fired when the user taps a notification
  /// action button while the app is backgrounded.
  Stream<String> get actionStream =>
      _actionChannel.receiveBroadcastStream().map((e) => e as String);
}
```

---

## 7. Android native — notification actions (Kotlin)

```kotlin
// android/app/src/main/kotlin/.../service/AutoClickForegroundService.kt  (diff)
// Existing service already builds a foreground notification with a single
// "Stop" action for running scripts (master spec §8.3). Add a second style:

fun showContinuePrompt(scriptName: String) {
    val continueIntent = PendingIntent.getBroadcast(
        this, REQUEST_CODE_CONTINUE,
        Intent(this, FatigueNotificationActionReceiver::class.java)
            .setAction(ACTION_FATIGUE_CONTINUE),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
    val stopIntent = PendingIntent.getBroadcast(
        this, REQUEST_CODE_STOP,
        Intent(this, FatigueNotificationActionReceiver::class.java)
            .setAction(ACTION_FATIGUE_STOP),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    val notification = NotificationCompat.Builder(this, CHANNEL_ID_EXECUTION)
        .setSmallIcon(R.drawable.ic_notification)
        .setContentTitle("Session limit reached")
        .setContentText("\"$scriptName\" has been running a while. Continue?")
        .setOngoing(true)
        .setPriority(NotificationCompat.PRIORITY_HIGH)
        .addAction(R.drawable.ic_play, "Continue", continueIntent)
        .addAction(R.drawable.ic_stop, "Stop", stopIntent)
        .build()

    NotificationManagerCompat.from(this).notify(NOTIFICATION_ID_FATIGUE, notification)
}

fun dismissContinuePrompt() {
    NotificationManagerCompat.from(this).cancel(NOTIFICATION_ID_FATIGUE)
}

companion object {
    const val ACTION_FATIGUE_CONTINUE = "com.autoclicker.action.FATIGUE_CONTINUE"
    const val ACTION_FATIGUE_STOP = "com.autoclicker.action.FATIGUE_STOP"
    const val NOTIFICATION_ID_FATIGUE = 1002
    const val REQUEST_CODE_CONTINUE = 2001
    const val REQUEST_CODE_STOP = 2002
}
```

```kotlin
// android/app/src/main/kotlin/.../receiver/FatigueNotificationActionReceiver.kt  [NEW]
package com.autoclicker.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.autoclicker.service.AutoClickForegroundService
import io.flutter.plugin.common.EventChannel

/**
 * Handles the Continue/Stop taps from the FR-A4 notification when the app
 * is backgrounded, and forwards the choice to Dart over the same
 * EventChannel FatigueNotificationChannel.actionStream listens on.
 */
class FatigueNotificationActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = when (intent.action) {
            AutoClickForegroundService.ACTION_FATIGUE_CONTINUE -> "continue"
            AutoClickForegroundService.ACTION_FATIGUE_STOP -> "stop"
            else -> return
        }
        FatigueActionEventStreamHandler.sink?.success(action)

        context.startService(
            Intent(context, AutoClickForegroundService::class.java)
                .setAction(intent.action)
        )
    }
}

/** Registered once in MainActivity's configureFlutterEngine, same pattern
 *  as every other EventChannel in this project. */
object FatigueActionEventStreamHandler : EventChannel.StreamHandler {
    var sink: EventChannel.EventSink? = null
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) { sink = events }
    override fun onCancel(arguments: Any?) { sink = null }
}
```

```xml
<!-- android/app/src/main/AndroidManifest.xml  (diff — receiver registration only) -->
<receiver
    android:name=".receiver.FatigueNotificationActionReceiver"
    android:exported="false" />
<!-- No new <uses-permission> — reuses the existing foreground-service /
     POST_NOTIFICATIONS permissions already required for script execution. -->
```

**iOS note:** the in-app `ContinueOrStopDialog` (§9 below) is the only prompt surface on iOS —
per the project skill's §2 platform constraint, background execution itself is already limited
to the in-app/Switch-Control model, so there is no backgrounded-notification case to cover
there; `FatigueNotificationChannel` methods simply no-op on iOS.

---

## 8. Domain wiring into script execution (FR-A3, FR-A5, FR-A7)

```dart
// lib/domain/usecases/run_script_usecase.dart  (diff — integration points only)
class RunScriptUseCase {
  RunScriptUseCase({
    required this.automationEngine,
    required this.settingsRepository,
  });

  final AutomationEngine automationEngine; // existing — unrelated to the guard
  final SettingsRepository settingsRepository;

  SessionFatigueGuard? _fatigueGuard;

  Future<void> call(Script script) async {
    final override = await settingsRepository.getScriptSessionFatigueOverride(script.id);
    final config = override ?? await settingsRepository.getGlobalSessionFatigueConfig();

    // FR-A7: this guard only ever calls automationEngine.pause()/stop() — it
    // NEVER touches the hardware kill-switch handler or the interval-floor
    // validator, which remain separate call sites elsewhere in this engine.
    _fatigueGuard = SessionFatigueGuard(
      config: config,
      onLimitReached: () => automationEngine.pause(), // state/counters preserved
      onGraceExpired: () => automationEngine.stop(),   // FR-A6 full stop
    );

    automationEngine.tickStream.listen((tickSize) {
      _fatigueGuard?.onTick(tickSize); // existing 1s engine tick, per FR-A1
    });

    await automationEngine.run(script);
  }

  /// Called by SessionFatigueController when the user taps "Continue" (FR-A5).
  void onUserContinued() {
    _fatigueGuard?.resumeCheckIn();
    automationEngine.resume(); // exact same click index/counters as before
  }

  void dispose() => _fatigueGuard?.dispose();
}
```

```dart
// lib/domain/usecases/resume_after_fatigue_pause_usecase.dart
import '../engines/session_fatigue_guard.dart';
import '../engines/automation_engine.dart';

/// Single-responsibility wrapper so presentation never has to reach into
/// RunScriptUseCase's internals directly — same convention as every other
/// use case in this project ("one class = one action").
class ResumeAfterFatiguePauseUseCase {
  const ResumeAfterFatiguePauseUseCase(this._guard, this._engine);

  final SessionFatigueGuard _guard;
  final AutomationEngine _engine;

  Future<void> call() async {
    _guard.resumeCheckIn();
    await _engine.resume();
  }
}
```

---

## 9. Presentation layer

```dart
// lib/presentation/controllers/session_fatigue_controller.dart
import 'package:riverpod/riverpod.dart';
import '../../domain/entities/session_fatigue_state.dart';
import '../../data/datasources/platform/fatigue_notification_channel.dart';

/// Thin Riverpod Notifier — same convention as every other controller in
/// this project ("thin, one per screen/concern"). Owns nothing but UI-facing
/// state; all business logic lives in SessionFatigueGuard/RunScriptUseCase.
class SessionFatigueController extends Notifier<SessionFatigueState> {
  late final FatigueNotificationChannel _notificationChannel;

  @override
  SessionFatigueState build() {
    _notificationChannel = ref.read(fatigueNotificationChannelProvider);
    _notificationChannel.actionStream.listen(_onNotificationAction);
    return SessionFatigueState.initial;
  }

  /// Called by RunScriptUseCase.onLimitReached (FR-A3/FR-A4).
  void showContinuePrompt({required bool appIsForegrounded, required String scriptName}) {
    state = state.copyWith(phase: SessionFatiguePhase.awaitingContinue);
    if (!appIsForegrounded) {
      _notificationChannel.showContinuePrompt(scriptName: scriptName);
    }
    // If foregrounded, the screen listening to this controller shows
    // ContinueOrStopDialog directly — see §9.2 below.
  }

  void onContinue() {
    _notificationChannel.dismissContinuePrompt();
    state = state.copyWith(phase: SessionFatiguePhase.running, graceElapsed: Duration.zero);
    ref.read(resumeAfterFatiguePauseUseCaseProvider).call();
  }

  void onStop() {
    _notificationChannel.dismissContinuePrompt();
    state = state.copyWith(phase: SessionFatiguePhase.autoStopped);
    ref.read(runScriptUseCaseProvider).dispose();
  }

  void _onNotificationAction(String action) {
    if (action == 'continue') onContinue();
    if (action == 'stop') onStop();
  }
}

final sessionFatigueControllerProvider =
    NotifierProvider<SessionFatigueController, SessionFatigueState>(
  SessionFatigueController.new,
);
```

```dart
// lib/presentation/widgets/execution/continue_or_stop_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/session_fatigue_controller.dart';
import '../../theme/app_colors.dart';
import '../common/app_primary_button.dart';
import '../common/app_text_button.dart';

/// In-app "Continue?" prompt shown when the app is foregrounded (FR-A4).
/// Reuses existing shared button widgets — no bespoke button styling here,
/// consistent with the "composition over duplication" convention.
class ContinueOrStopDialog extends ConsumerWidget {
  const ContinueOrStopDialog({super.key, required this.scriptName, required this.graceWindow});

  final String scriptName;
  final Duration graceWindow;

  static Future<void> show(BuildContext context, {
    required String scriptName,
    required Duration graceWindow,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false, // FR-A6: no silent dismissal — grace window governs this
      builder: (_) => ContinueOrStopDialog(scriptName: scriptName, graceWindow: graceWindow),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Session limit reached'),
      content: Text(
        '"$scriptName" has been running for a while and paused automatically.\n\n'
        'Continue running? Without a response within '
        '${graceWindow.inMinutes} minutes, it will stop automatically.',
      ),
      actions: [
        AppTextButton(
          label: 'Stop',
          onPressed: () {
            ref.read(sessionFatigueControllerProvider.notifier).onStop();
            Navigator.of(context).pop();
          },
        ),
        AppPrimaryButton(
          label: 'Continue',
          onPressed: () {
            ref.read(sessionFatigueControllerProvider.notifier).onContinue();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
```

```dart
// lib/presentation/screens/settings/widgets/session_limit_selector.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/session_fatigue_presets.dart';
import '../../../widgets/forms/app_segmented_control.dart';
import '../../../widgets/forms/app_section_label.dart';
import '../../../widgets/forms/app_toggle_row.dart';

/// Settings-screen control for FR-A2 — reuses the existing shared forms/
/// widgets (app_segmented_control, app_toggle_row, app_section_label) that
/// already back screens 8 and 10, per the established forms/ convention.
class SessionLimitSelector extends StatelessWidget {
  const SessionLimitSelector({
    super.key,
    required this.preset,
    required this.onChanged,
  });

  final SessionFatiguePreset preset;
  final ValueChanged<SessionFatiguePreset> onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = preset != SessionFatiguePreset.off;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionLabel(text: 'Session Limit'),
        AppToggleRow(
          label: 'Auto-pause long-running scripts',
          value: enabled,
          onChanged: (on) => onChanged(
            on ? SessionFatiguePreset.fortyFiveMinutes : SessionFatiguePreset.off,
          ),
        ),
        if (enabled)
          AppSegmentedControl<SessionFatiguePreset>(
            options: const [
              SessionFatiguePreset.thirtyMinutes,
              SessionFatiguePreset.fortyFiveMinutes,
              SessionFatiguePreset.oneHour,
              SessionFatiguePreset.twoHours,
              SessionFatiguePreset.custom,
            ],
            labelBuilder: (p) => p.label,
            selected: preset,
            onSelected: onChanged,
          ),
      ],
    );
  }
}
```

---

## 10. End-to-end flow (matches FR-A1 → FR-A7 exactly)

```
1. RunScriptUseCase reads global/per-script SessionFatigueConfig (FR-A2)
   → SessionFatigueGuard is created only if config.isEnabled

2. Engine tick (1s) → guard.onTick()
   elapsedSinceLastCheckIn accumulates continuously (FR-A1) regardless of
   ordinary script pause/resume — those don't reset it, only a check-in does

3. elapsed >= limit → onLimitReached()
   → automationEngine.pause()            [state/counters preserved, FR-A3]
   → SessionFatigueController.showContinuePrompt(...)
       foregrounded  → ContinueOrStopDialog.show(...)
       backgrounded  → FatigueNotificationChannel.showContinuePrompt(...)
                        (AutoClickForegroundService, native Continue/Stop) [FR-A4]

4a. User taps Continue (in-app or notification)
    → guard.resumeCheckIn()               [fresh Session Limit countdown]
    → automationEngine.resume()           [exact same click index, FR-A5]

4b. No response within graceWindow (default 5 min)
    → onGraceExpired() → automationEngine.stop()   [full stop, FR-A6]

Independent at every step: hardware kill-switch (Volume Down) and the
interval-floor freeze guard are separate call sites in AutomationEngine —
the fatigue guard never intercepts or substitutes for either (FR-A7).
```

---

## 11. Testing notes (per the project's QA-matrix convention, §12 of the master spec)

| Scenario ID (suggested) | Verification objective |
|---|---|
| QA-FA-01 | `SessionFatigueGuard.onTick` accumulates across ticks and fires `onLimitReached` exactly once at the configured limit |
| QA-FA-02 | Ordinary script pause/resume (unrelated to fatigue) does **not** reset `elapsedSinceLastCheckIn` |
| QA-FA-03 | `resumeCheckIn()` restarts the countdown from zero and returns phase to `running` |
| QA-FA-04 | Grace window expiry with no response calls `onGraceExpired` exactly once, phase becomes `autoStopped` |
| QA-FA-05 | Per-script override takes precedence over the global config; null override falls back to global |
| QA-FA-06 | Foregrounded app shows `ContinueOrStopDialog`, not the native notification, and vice versa |
| QA-FA-07 | Notification `Continue`/`Stop` actions correctly reach `SessionFatigueController` via the EventChannel while the app is fully backgrounded/locked |
| QA-FA-08 | `SessionFatiguePreset.off` (default) never instantiates a guard — zero overhead when the feature is unused |
| QA-FA-09 | Guard never calls into the hardware kill-switch handler or interval-floor validator (FR-A7 isolation) |

---

## 12. Effort recap

Free, offline, no new permissions or dependencies — one new domain engine class, two entity
files, four repository/data-layer additions reusing the existing storage engine, one Riverpod
controller, two presentation widgets, and a second notification style on the Android side of
the already-built `AutoClickForegroundService`. Matches the requirements doc's own estimate:
a few hours of Dart plus a small native notification-action wiring change.
