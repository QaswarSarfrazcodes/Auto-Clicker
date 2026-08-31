import '../../core/constants/session_fatigue_presets.dart';

/// Immutable configuration for the Session Fatigue Timer.
/// Global (Settings) or per-script override (FR-A2).
class SessionFatigueConfig {
  const SessionFatigueConfig({
    this.preset = kDefaultFatiguePreset,
    this.customLimit,
    this.graceWindow = kDefaultFatigueGraceWindow,
  });

  final SessionFatiguePreset preset;
  final Duration? customLimit;
  final Duration graceWindow;

  /// Effective session limit; null means feature is off.
  Duration? get effectiveLimit =>
      preset == SessionFatiguePreset.custom ? customLimit : preset.duration;

  bool get isEnabled => effectiveLimit != null && effectiveLimit! > Duration.zero;

  static const SessionFatigueConfig disabled = SessionFatigueConfig(
    preset: SessionFatiguePreset.off,
  );

  static const SessionFatigueConfig defaultConfig = SessionFatigueConfig();

  SessionFatigueConfig copyWith({
    SessionFatiguePreset? preset,
    Duration? customLimit,
    Duration? graceWindow,
    bool clearCustomLimit = false,
  }) {
    return SessionFatigueConfig(
      preset: preset ?? this.preset,
      customLimit: clearCustomLimit ? null : (customLimit ?? this.customLimit),
      graceWindow: graceWindow ?? this.graceWindow,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionFatigueConfig &&
          other.preset == preset &&
          other.customLimit == customLimit &&
          other.graceWindow == graceWindow;

  @override
  int get hashCode => Object.hash(preset, customLimit, graceWindow);
}
