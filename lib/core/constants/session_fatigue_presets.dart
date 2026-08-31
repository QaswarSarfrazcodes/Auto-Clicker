/// Session Fatigue Timer presets and constants.
///
/// Feature A — "Auto-Pause & Ask to Continue" system.
/// Default is [SessionFatiguePreset.oneHour] per user requirement
/// (not opt-in "off" as in the design doc — user wants 1h out of the box).
library;

/// Session Limit presets shown in the Running screen sidebar.
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
        SessionFatiguePreset.custom => null, // resolved from stored custom value
      };

  String get label => switch (this) {
        SessionFatiguePreset.off => 'Off',
        SessionFatiguePreset.thirtyMinutes => '30 min',
        SessionFatiguePreset.fortyFiveMinutes => '45 min',
        SessionFatiguePreset.oneHour => '1 hr',
        SessionFatiguePreset.twoHours => '2 hr',
        SessionFatiguePreset.custom => 'Custom',
      };

  String get fullLabel => switch (this) {
        SessionFatiguePreset.off => 'Off',
        SessionFatiguePreset.thirtyMinutes => '30 minutes',
        SessionFatiguePreset.fortyFiveMinutes => '45 minutes',
        SessionFatiguePreset.oneHour => '1 hour',
        SessionFatiguePreset.twoHours => '2 hours',
        SessionFatiguePreset.custom => 'Custom',
      };
}

/// Default preset — 1 hour per user requirement.
const SessionFatiguePreset kDefaultFatiguePreset = SessionFatiguePreset.oneHour;

/// Grace window: how long the "Continue?" prompt waits before auto-stopping (FR-A6).
const Duration kDefaultFatigueGraceWindow = Duration(minutes: 5);

/// Engine tick size the guard is driven at — matches existing ExecuteScriptUseCase 1s tick.
const Duration kFatigueGuardTickSize = Duration(seconds: 1);
